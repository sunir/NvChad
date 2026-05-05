--[[
Dungeon Crawl: Zork-style code navigator for Neovim

Each file is a room. Imports are exits. Press Enter on anything to interact.

Architecture: thin Lua shell around python/room.py JSON output.
The Python layer owns all analysis; Lua owns navigation and display.

Interaction model:
  Every line in the dungeon buffer has an action in line_actions[].
  <CR> dispatches the action for the current line.
  No commands needed — just move cursor and press Enter.
--]]

local M = {}

M.config = {
  room_analyzer    = vim.fn.expand("~/source/colony/Brook/projects/dungeon-crawl/python/room.py"),
  session_manager  = vim.fn.expand("~/source/colony/Brook/projects/dungeon-crawl/python/session.py"),
  python           = "python3",
  window_height    = 22,
}

local state = {
  history    = {},   -- stack of previously visited rooms
  current    = nil,  -- current Room (JSON from Python)
  map        = {},   -- path → room
  session    = nil,  -- DungeonSession JSON
}

-- Per-buffer line → action dispatch table.
-- Rebuilt every time the buffer is redrawn.
local line_actions = {}

-- ── Highlight groups ──────────────────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, "DungeonHeader",    { bold = true, fg = "#89b4fa" })
  vim.api.nvim_set_hl(0, "DungeonSmell",     { fg = "#f38ba8", italic = true })
  vim.api.nvim_set_hl(0, "DungeonExit",      { fg = "#a6e3a1", bold = true })
  vim.api.nvim_set_hl(0, "DungeonExitDim",   { fg = "#6c7086" })
  vim.api.nvim_set_hl(0, "DungeonInhabitant",{ fg = "#cba6f7" })
  vim.api.nvim_set_hl(0, "DungeonNote",      { fg = "#f9e2af", italic = true })
  vim.api.nvim_set_hl(0, "DungeonButton",    { fg = "#1e1e2e", bg = "#89b4fa", bold = true })
  vim.api.nvim_set_hl(0, "DungeonButtonBack",{ fg = "#1e1e2e", bg = "#f38ba8", bold = true })
  vim.api.nvim_set_hl(0, "DungeonCursorLine",{ bg = "#313244" })
end


-- ── Python bridge ─────────────────────────────────────────────────────────────

local function call_session(cmd, path, ...)
  local mgr    = M.config.session_manager
  local python = M.config.python
  local extra  = table.concat(
    vim.tbl_map(function(a) return vim.fn.shellescape(a) end, {...}), " ")
  local full = string.format("%s %s %s %s %s 2>/dev/null",
    python, vim.fn.shellescape(mgr), cmd, vim.fn.shellescape(path), extra)
  local output = vim.fn.system(full)
  if cmd == "visit" or cmd == "load" then
    local ok, data = pcall(vim.json.decode, output)
    return ok and data or nil
  end
  return output:match("^ok")
end

local function analyze_file(path)
  local analyzer = M.config.room_analyzer
  local python   = M.config.python
  local cmd = string.format("%s %s %s json 2>/dev/null",
    python, vim.fn.shellescape(analyzer), vim.fn.shellescape(path))
  local output = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 or output == "" then
    return nil, "Room analyzer failed for: " .. path
  end
  local ok, room = pcall(vim.json.decode, output)
  if not ok then
    return nil, "Failed to parse room JSON"
  end
  return room, nil
end


-- ── Buffer / window ───────────────────────────────────────────────────────────

local dungeon_buf = nil
local dungeon_win = nil
local editor_win  = nil   -- the non-dungeon window to open files in

local function get_or_create_dungeon_window()
  if dungeon_win and vim.api.nvim_win_is_valid(dungeon_win) then
    return dungeon_win, dungeon_buf
  end

  -- Remember the current (editor) window before opening the split
  editor_win = vim.api.nvim_get_current_win()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype   = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype  = "dungeon"

  vim.cmd(string.format("botright %dsplit", M.config.window_height))
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].cursorline   = true
  vim.wo[win].number       = false
  vim.wo[win].signcolumn   = "no"
  vim.wo[win].wrap         = false
  vim.wo[win].winhighlight = "CursorLine:DungeonCursorLine"

  -- Enter = dispatch action on current line.
  -- Use current_win() here, not the captured win, because the keymap
  -- fires while the dungeon window IS current.
  vim.keymap.set("n", "<CR>", function()
    local lnum = vim.api.nvim_win_get_cursor(
      vim.api.nvim_get_current_win())[1]
    local action = line_actions[lnum]
    if action then action() end
  end, { buffer = buf, nowait = true, desc = "Dungeon: activate" })

  -- q closes
  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, { buffer = buf, desc = "Dungeon: close" })

  -- Stay in the dungeon window — don't wincmd p
  dungeon_buf = buf
  dungeon_win = win
  return win, buf
end

-- Open a file in the editor window (not the dungeon window)
local function open_in_editor(path)
  if path == "" then return end
  local target = editor_win
  -- If editor_win is gone or is the dungeon, find another normal window
  if not target or not vim.api.nvim_win_is_valid(target)
      or target == dungeon_win then
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= dungeon_win then target = w; break end
    end
  end
  if target and vim.api.nvim_win_is_valid(target) then
    vim.api.nvim_win_call(target, function()
      vim.cmd("edit " .. vim.fn.fnameescape(path))
    end)
    editor_win = target
  end
end


-- ── Render ────────────────────────────────────────────────────────────────────
--
-- render_room returns:
--   lines   []string       — text for each line
--   actions []function|nil — action for <CR> on that line (1-indexed)
--   hls     []             — highlight specs {line, col_start, col_end, hl_group}

local function render_room(room)
  local lines   = {}
  local actions = {}
  local hls     = {}

  local function push(text, action, hl)
    table.insert(lines, text)
    table.insert(actions, action)  -- nil = no action (inert line)
    local lnum = #lines
    if hl then
      table.insert(hls, { lnum = lnum - 1, cs = 0, ce = -1, group = hl })
    end
    return lnum
  end

  local function hl_range(lnum, cs, ce, group)
    table.insert(hls, { lnum = lnum - 1, cs = cs, ce = ce, group = group })
  end

  -- ── Header ──
  local sep = "═" .. string.rep("═", 57)
  push(sep, nil, "DungeonHeader")
  local name_line = push("  " .. room.name:upper(), nil, "DungeonHeader")
  push("  " .. room.path, nil, "DungeonExitDim")
  push(sep, nil, "DungeonHeader")
  push("", nil)
  push(room.description, nil)
  push("", nil)

  -- ── Smells ──
  if room.smells and #room.smells > 0 then
    push("⚠  You sense something wrong here:", nil, "DungeonSmell")
    for _, smell in ipairs(room.smells) do
      push("   " .. smell, nil, "DungeonSmell")
    end
    push("", nil)
  end

  -- ── Inhabitants — clickable: jump to line in editor ──
  if room.inhabitants and #room.inhabitants > 0 then
    push("Inhabitants:", nil, "DungeonInhabitant")
    for _, inh in ipairs(room.inhabitants) do
      local smell = inh.smell ~= "" and ("  ⚠ " .. inh.smell) or ""
      local doc   = inh.docstring ~= "" and (" — " .. inh.docstring) or ""
      local text  = string.format("  [ %s ]  %s  (:%d)%s%s",
        inh.kind, inh.name, inh.line, doc, smell)
      local inh_line = inh.line
      local action = function()
        open_in_editor(room.path)
        -- Move cursor in editor window to the definition
        if editor_win and vim.api.nvim_win_is_valid(editor_win) then
          vim.api.nvim_win_set_cursor(editor_win, { inh_line, 0 })
          vim.api.nvim_win_call(editor_win, function()
            vim.cmd("normal! zz")
          end)
        end
      end
      local lnum = push(text, action, "DungeonInhabitant")
      -- Highlight the [ kind ] button part
      hl_range(lnum, 2, 2 + #inh.kind + 4, "DungeonButton")
    end
    push("", nil)
  end

  -- ── Local exits — clickable: enter room ──
  local local_exits = {}
  local ext_exits   = {}
  for _, ex in ipairs(room.exits or {}) do
    if ex.resolved then table.insert(local_exits, ex)
    else               table.insert(ext_exits, ex)
    end
  end

  if #local_exits > 0 then
    push("Exits:", nil, "DungeonExit")
    for _, ex in ipairs(local_exits) do
      local sym  = ex.symbol ~= "" and (" (" .. ex.symbol .. ")") or ""
      local stem = vim.fn.fnamemodify(ex.target, ":t:r")
      local text = string.format("  [ → %s ]  %s%s", stem, ex.direction, sym)
      local target = ex.target
      local action = function()
        require("dungeon")._enter_room(target)
        open_in_editor(target)
      end
      local lnum = push(text, action, "DungeonExit")
      hl_range(lnum, 2, 2 + #stem + 6, "DungeonButton")
    end
    push("", nil)
  end

  if #ext_exits > 0 then
    push("External:", nil, "DungeonExitDim")
    local shown = math.min(#ext_exits, 5)
    for i = 1, shown do
      push("  · " .. ext_exits[i].direction, nil, "DungeonExitDim")
    end
    if #ext_exits > 5 then
      push(string.format("  · … and %d more", #ext_exits - 5), nil, "DungeonExitDim")
    end
    push("", nil)
  end

  -- ── Annotations ──
  if room._annotations and #room._annotations > 0 then
    push("Notes:", nil, "DungeonNote")
    for _, ann in ipairs(room._annotations) do
      local who = ann.author == "human" and "You" or "Claude"
      local tgt = ann.target ~= "" and (" [" .. ann.target .. "]") or ""
      push(string.format("  📝 %s%s: %s", who, tgt, ann.text), nil, "DungeonNote")
    end
    push("", nil)
  end

  -- ── Button bar ──
  push("", nil)
  local bar_parts = {
    { "[ ← Back ]",    function() require("dungeon").back() end,    "DungeonButtonBack" },
    { "[ 🗺 Map ]",    function() require("dungeon").map() end,     "DungeonButton" },
    { "[ 📝 Note ]",   function()
        vim.ui.input({ prompt = "Note: " }, function(text)
          if text and text ~= "" then require("dungeon").note(text) end
        end)
      end, "DungeonButton" },
    { "[ ↻ Reload ]",  function() require("dungeon").reload() end,  "DungeonButton" },
  }
  local bar_text = "  "
  local col = 2
  local bar_actions = {}  -- {col_start, col_end, fn}
  for _, part in ipairs(bar_parts) do
    table.insert(bar_actions, { col, col + #part[1] - 1, part[2], part[3] })
    bar_text = bar_text .. part[1] .. "  "
    col = col + #part[1] + 2
  end

  local bar_lnum = push(bar_text, nil)
  -- Override action for bar line: dispatch by column
  actions[bar_lnum] = function()
    local cursor_col = vim.api.nvim_win_get_cursor(dungeon_win)[2]
    for _, b in ipairs(bar_actions) do
      if cursor_col >= b[1] and cursor_col <= b[2] then
        b[3]()
        return
      end
    end
    -- Fallback: if cursor isn't on a button, trigger Back
    bar_actions[1][3]()
  end
  -- Highlight each button on the bar
  for _, b in ipairs(bar_actions) do
    hl_range(bar_lnum, b[1], b[2] + 1, b[4])
  end

  return lines, actions, hls
end


-- ── Apply highlights ──────────────────────────────────────────────────────────

local function apply_highlights(buf, hls)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  local ns = vim.api.nvim_create_namespace("dungeon")
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, h.group, h.lnum, h.cs, h.ce)
  end
end


-- ── Display ───────────────────────────────────────────────────────────────────

local function display_room(room)
  local _, buf = get_or_create_dungeon_window()
  local lines, actions, hls = render_room(room)

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  -- Rebuild the global line_actions table
  line_actions = actions

  apply_highlights(buf, hls)
end


-- ── Navigation (internal) ────────────────────────────────────────────────────

local function enter_room(path)
  local room, err = analyze_file(path)
  if err then
    vim.notify("Dungeon: " .. err, vim.log.levels.ERROR)
    return
  end

  if state.current then
    table.insert(state.history, state.current)
  end

  state.current  = room
  state.map[path] = room

  -- Autosave + merge annotations
  local session_data = call_session("visit", path)
  if session_data then
    state.session = session_data
    local visited = session_data.visited and session_data.visited[path]
    if visited and visited.annotations and #visited.annotations > 0 then
      room._annotations = visited.annotations
    end
  end

  display_room(room)
end

-- Expose for button closures that call require("dungeon")._enter_room
M._enter_room = enter_room


-- ── Public API ────────────────────────────────────────────────────────────────

function M.dungeon()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    vim.notify("Dungeon: no file in current buffer", vim.log.levels.WARN)
    return
  end
  enter_room(path)
end

function M.go(n)
  if not state.current then
    vim.notify("Dungeon: run :Dungeon first", vim.log.levels.WARN)
    return
  end
  local local_exits = vim.tbl_filter(
    function(e) return e.resolved end, state.current.exits or {})
  local idx = tonumber(n)
  if not idx or idx < 1 or idx > #local_exits then
    vim.notify(string.format("Dungeon: exit %s out of range (1-%d)", n, #local_exits),
      vim.log.levels.WARN)
    return
  end
  local exit = local_exits[idx]
  enter_room(exit.target)
  open_in_editor(exit.target)
end

function M.back()
  if #state.history == 0 then
    vim.notify("Dungeon: already at the start.", vim.log.levels.INFO)
    return
  end
  local prev = table.remove(state.history)
  state.current = prev
  display_room(prev)
  open_in_editor(prev.path)
end

function M.reload()
  if not state.current then return end
  enter_room(state.current.path)
end

function M.map()
  local lines   = {}
  local actions = {}
  local hls     = {}

  local function push(text, action, hl)
    table.insert(lines, text)
    table.insert(actions, action)
    if hl then
      table.insert(hls, { lnum = #lines - 1, cs = 0, ce = -1, group = hl })
    end
  end

  push("╔══ DUNGEON MAP ══╗", nil, "DungeonHeader")
  push("  Enter on a room to jump to it.", nil, "DungeonExitDim")
  push("", nil)

  if vim.tbl_isempty(state.map) then
    push("  [no rooms visited yet]", nil, "DungeonExitDim")
  else
    for path, room in pairs(state.map) do
      local is_current = state.current and path == state.current.path
      local marker = is_current and "► " or "  "
      local text   = marker .. "[ " .. room.name .. " ]"
      local hl     = is_current and "DungeonExit" or "DungeonInhabitant"
      local target = path
      push(text, function()
        enter_room(target)
        open_in_editor(target)
      end, hl)
      for _, ex in ipairs(room.exits or {}) do
        if ex.resolved and state.map[ex.target] then
          push("    └─→ " .. vim.fn.fnamemodify(ex.target, ":t:r"), nil, "DungeonExitDim")
        end
      end
    end
  end

  push("", nil)
  push("╚══════════════════╝", nil, "DungeonHeader")
  push("", nil)
  push("  [ ← Back to room ]", function()
    if state.current then display_room(state.current) end
  end, "DungeonButtonBack")

  local _, buf = get_or_create_dungeon_window()
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  line_actions = actions
  apply_highlights(buf, hls)
end

function M.note(text)
  if not state.current then
    vim.notify("Dungeon: run :Dungeon first", vim.log.levels.WARN)
    return
  end
  if not text or text == "" then return end
  local path = state.current.path
  local ok   = call_session("note", path, text)
  if ok then
    local ann = { author = "human", text = text, target = "", timestamp = "" }
    state.current._annotations = state.current._annotations or {}
    table.insert(state.current._annotations, ann)
    display_room(state.current)
    vim.notify("📝 Note saved.", vim.log.levels.INFO)
  else
    vim.notify("Dungeon: failed to save note.", vim.log.levels.WARN)
  end
end

function M.examine()
  if not state.current then return end
  local word  = vim.fn.expand("<cword>")
  local found = nil
  for _, inh in ipairs(state.current.inhabitants or {}) do
    if inh.name == word then found = inh; break end
  end
  if not found then
    vim.notify(string.format("'%s' not found in this room.", word), vim.log.levels.INFO)
    return
  end
  vim.notify(string.format("[%s] %s  line %d\n%s%s",
    found.kind, found.name, found.line,
    found.docstring ~= "" and (found.docstring .. "\n") or "",
    found.smell ~= "" and ("⚠ " .. found.smell) or ""), vim.log.levels.INFO)
end


-- ── Setup ─────────────────────────────────────────────────────────────────────

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  setup_highlights()

  -- Re-apply highlights on colorscheme change
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = setup_highlights,
    desc = "Dungeon: reapply highlights",
  })

  vim.api.nvim_create_user_command("Dungeon",        function()      M.dungeon()        end, { desc = "Enter dungeon at current file" })
  vim.api.nvim_create_user_command("DungeonGo",      function(a)     M.go(a.args)       end, { nargs = 1, desc = "Follow exit N" })
  vim.api.nvim_create_user_command("DungeonBack",    function()      M.back()           end, { desc = "Go back" })
  vim.api.nvim_create_user_command("DungeonMap",     function()      M.map()            end, { desc = "Show dungeon map" })
  vim.api.nvim_create_user_command("DungeonExamine", function()      M.examine()        end, { desc = "Examine symbol under cursor" })
  vim.api.nvim_create_user_command("DungeonReload",  function()      M.reload()         end, { desc = "Re-analyze current room" })
  vim.api.nvim_create_user_command("DungeonNote",    function(a)     M.note(a.args)     end, { nargs = "+", desc = "Add note to room" })

  if not vim.g.dungeon_no_keymaps then
    local map = vim.keymap.set
    map("n", "<leader>de", M.dungeon,  { desc = "Dungeon: enter" })
    map("n", "<leader>dm", M.map,      { desc = "Dungeon: map" })
    map("n", "<leader>db", M.back,     { desc = "Dungeon: back" })
    map("n", "<leader>dx", M.examine,  { desc = "Dungeon: examine" })
    map("n", "<leader>dr", M.reload,   { desc = "Dungeon: reload room" })
    map("n", "<leader>dn", function()
      vim.ui.input({ prompt = "📝 Note: " }, function(text)
        if text and text ~= "" then M.note(text) end
      end)
    end, { desc = "Dungeon: add note" })
  end
end

return M
