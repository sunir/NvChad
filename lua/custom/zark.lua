--[[
zark.lua — Party buffer for Zark (ZANY AGENT RUNTIME KIT)

<leader>z  open or focus the Zark party panel
Inside the panel:
  i          enter insert mode → type message → <Enter> sends
  +          invite agent (autocomplete from available agents)
  -          remove agent (pick from party list)
  m          switch to dungeon map view
  <BS>       dungeon: go back
  q / <Esc>  close panel
  r          refresh messages
--]]

local M = {}

local ZARK_DIR  = vim.fn.expand("~/.config/zark")
local ZARK_BIN  = "zark"  -- on PATH after deploy

-- ── State ─────────────────────────────────────────────────────────────────────

local state = {
  buf     = nil,
  win     = nil,
  context = nil,   -- inferred context string
  mode    = "view",  -- "view" | "insert"
  watcher = nil,   -- uv fs_event handle for log file
}

-- ── Highlights ────────────────────────────────────────────────────────────────

local function setup_highlights()
  vim.api.nvim_set_hl(0, "ZarkHeader",  { bold = true,   fg = "#cba6f7" })
  vim.api.nvim_set_hl(0, "ZarkParty",   { fg = "#a6e3a1", bold = true })
  vim.api.nvim_set_hl(0, "ZarkMsg",     { fg = "#cdd6f4" })
  vim.api.nvim_set_hl(0, "ZarkMsgMe",   { fg = "#89b4fa" })
  vim.api.nvim_set_hl(0, "ZarkMuted",   { fg = "#6c7086" })
  vim.api.nvim_set_hl(0, "ZarkStale",   { fg = "#f38ba8", italic = true })
  vim.api.nvim_set_hl(0, "ZarkPrompt",  { fg = "#f9e2af", bold = true })
  vim.api.nvim_set_hl(0, "ZarkButton",  { fg = "#1e1e2e", bg = "#cba6f7", bold = true })
end

-- ── Context inference ─────────────────────────────────────────────────────────

local function infer_context()
  -- Try git remote → repo:owner/name
  local remote = vim.fn.system("git remote get-url origin 2>/dev/null"):gsub("\n", "")
  if remote ~= "" then
    local name  = remote:gsub("%.git$", ""):match("[^/]+$") or ""
    local owner = remote:gsub("%.git$", ""):match("([^/:]+)/[^/]+$") or ""
    if owner ~= "" and name ~= "" then
      return "repo:" .. owner .. "/" .. name
    end
  end
  -- Fallback: repo:{dirname}
  local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if root ~= "" then
    return "repo:" .. vim.fn.fnamemodify(root, ":t")
  end
  return "default"
end

local function sanitize(context)
  return context:gsub("/", "-"):gsub(":", "-")
end

-- ── Filesystem reads ──────────────────────────────────────────────────────────

local function read_json(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  local ok, data = pcall(vim.json.decode, s)
  return ok and data or nil
end

local function available_agents()
  local agents = {}
  local pattern = ZARK_DIR .. "/agents/*/agent"
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
    local data = read_json(path)
    if data and data.agent then
      local plugin = data.plugin_path or ""
      local stale  = plugin ~= "" and vim.fn.filereadable(plugin) == 0
      table.insert(agents, { name = data.agent, stale = stale })
    end
  end
  return agents
end

local function party_members(context)
  local members = {}
  local san     = sanitize(context)
  local pattern = ZARK_DIR .. "/agents/*/" .. san .. "/context"
  for _, path in ipairs(vim.fn.glob(pattern, false, true)) do
    local data = read_json(path)
    if data and data.agent then
      table.insert(members, data.agent)
    end
  end
  return members
end

local function recent_messages(context, limit)
  limit = limit or 30
  local san      = sanitize(context)
  -- Check context log path
  local ctx_file = ZARK_DIR .. "/contexts/" .. san .. "/context"
  local ctx_data = read_json(ctx_file)
  local log_path = ctx_data and ctx_data.log_path

  if not log_path or vim.fn.filereadable(log_path) == 0 then
    -- Fallback: presence dir channels/
    log_path = ZARK_DIR .. "/channels/" .. san .. ".jsonl"
  end

  if not log_path or vim.fn.filereadable(log_path) == 0 then
    return {}
  end

  local msgs = {}
  local f = io.open(log_path, "r")
  if not f then return {} end
  for line in f:lines() do
    local ok, msg = pcall(vim.json.decode, line)
    if ok and msg then table.insert(msgs, msg) end
  end
  f:close()

  -- Return last N
  local start = math.max(1, #msgs - limit + 1)
  local result = {}
  for i = start, #msgs do result[#result + 1] = msgs[i] end
  return result
end

-- ── Render ────────────────────────────────────────────────────────────────────

local function render(context)
  local lines = {}
  local hls   = {}

  local function push(text, hl)
    table.insert(lines, text)
    if hl then
      table.insert(hls, { lnum = #lines - 1, cs = 0, ce = -1, group = hl })
    end
  end

  -- Header
  push("╔══ ZARK ══════════════════════════════════════════════╗", "ZarkHeader")
  push("  " .. context, "ZarkHeader")

  -- Party members
  local members = party_members(context)
  if #members > 0 then
    push("  Party: " .. table.concat(members, ", "), "ZarkParty")
  else
    push("  Party: (empty — use + to invite)", "ZarkMuted")
  end
  push("╠══════════════════════════════════════════════════════╣", "ZarkHeader")

  -- Messages
  local msgs = recent_messages(context)
  if #msgs == 0 then
    push("  (no messages yet)", "ZarkMuted")
  else
    for _, msg in ipairs(msgs) do
      local role = msg.role or "?"
      local text = msg.text or msg.message or ""
      local ts   = (msg.ts or ""):sub(12, 19)  -- HH:MM:SS
      local who  = role == "user" and "you" or (role == "assistant" and "claude" or role)
      local hl   = role == "user" and "ZarkMsgMe" or "ZarkMsg"
      -- Wrap long lines simply
      local prefix = string.format("  [%s] %s: ", ts, who)
      push(prefix .. text, hl)
    end
  end

  push("╠══════════════════════════════════════════════════════╣", "ZarkHeader")
  push("  i=chat  +=invite  -=remove  m=map  <BS>=back  q=quit", "ZarkMuted")
  push("╚══════════════════════════════════════════════════════╝", "ZarkHeader")

  return lines, hls
end

local function apply_highlights(buf, hls)
  vim.api.nvim_buf_clear_namespace(buf, -1, 0, -1)
  local ns = vim.api.nvim_create_namespace("zark")
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, buf, ns, h.group, h.lnum, h.cs, h.ce)
  end
end

local function redraw()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then return end
  local ctx = state.context or infer_context()
  local lines, hls = render(ctx)
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
  apply_highlights(state.buf, hls)
  -- Scroll to bottom
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    local lc = vim.api.nvim_buf_line_count(state.buf)
    vim.api.nvim_win_set_cursor(state.win, { lc, 0 })
  end
end

-- ── Log file watcher ─────────────────────────────────────────────────────────

local function log_path_for(context)
  local san      = sanitize(context)
  local ctx_file = ZARK_DIR .. "/contexts/" .. san .. "/context"
  local ctx_data = read_json(ctx_file)
  if ctx_data and ctx_data.log_path then return ctx_data.log_path end
  return ZARK_DIR .. "/channels/" .. san .. ".jsonl"
end

local function stop_watcher()
  if state.watcher then
    state.watcher:stop()
    state.watcher:close()
    state.watcher = nil
  end
end

local function start_watcher(context)
  stop_watcher()
  local path = log_path_for(context)
  if not path then return end

  local handle = vim.uv.new_fs_event()
  if not handle then return end

  local debounce_timer = nil
  handle:start(path, {}, function(err, _, _)
    if err then return end
    -- debounce: coalesce rapid writes into one redraw
    if debounce_timer then debounce_timer:stop() end
    debounce_timer = vim.defer_fn(function()
      debounce_timer = nil
      vim.schedule(redraw)
    end, 150)
  end)
  state.watcher = handle
end

-- ── Window management ─────────────────────────────────────────────────────────

local function open_window()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype   = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype  = "zark"

  -- Right vertical split, 60 cols
  local width = math.min(60, math.floor(vim.o.columns * 0.35))
  vim.cmd("botright " .. width .. "vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.wo[win].number     = false
  vim.wo[win].signcolumn = "no"
  vim.wo[win].wrap       = true
  vim.wo[win].cursorline = true

  state.buf = buf
  state.win = win

  -- ── Keymaps inside the Zark buffer ──

  local function map(key, fn, desc)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, desc = desc })
  end

  -- q / Esc: close
  map("q", function()
    stop_watcher()
    if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
  end, "Zark: close")

  -- r: refresh
  map("r", function() redraw() end, "Zark: refresh")

  -- i: send a message
  map("i", function()
    local ctx = state.context
    vim.ui.input({ prompt = "→ " }, function(text)
      if not text or text == "" then return end
      vim.fn.jobstart({ ZARK_BIN, ctx, "send", text }, {
        on_exit = function() redraw() end,
      })
    end)
  end, "Zark: send message")

  -- +: invite agent
  map("+", function()
    local ctx    = state.context
    local agents = available_agents()
    if #agents == 0 then
      vim.notify("No agents logged in (run: zark login)", vim.log.levels.WARN)
      return
    end
    local names = vim.tbl_map(function(a)
      return a.stale and (a.name .. " [STALE]") or a.name
    end, agents)
    vim.ui.select(names, { prompt = "Invite agent:" }, function(choice)
      if not choice then return end
      -- Strip [STALE] suffix if present
      local agent = choice:match("^(.-)%s*%[") or choice
      vim.fn.jobstart({ ZARK_BIN, "context", ctx, "invite", agent }, {
        on_exit = function(_, code)
          if code == 0 then
            vim.notify("Invited " .. agent .. " to " .. ctx)
            redraw()
          else
            vim.notify("Failed to invite " .. agent, vim.log.levels.ERROR)
          end
        end,
      })
    end)
  end, "Zark: invite agent")

  -- -: remove agent
  map("-", function()
    local ctx     = state.context
    local members = party_members(ctx)
    if #members == 0 then
      vim.notify("No agents in this context", vim.log.levels.INFO)
      return
    end
    vim.ui.select(members, { prompt = "Remove agent:" }, function(choice)
      if not choice then return end
      vim.fn.jobstart({ ZARK_BIN, "context", ctx, "remove", choice }, {
        on_exit = function(_, code)
          if code == 0 then
            vim.notify("Removed " .. choice .. " from " .. ctx)
            redraw()
          else
            vim.notify("Failed to remove " .. choice, vim.log.levels.ERROR)
          end
        end,
      })
    end)
  end, "Zark: remove agent")

  -- m: dungeon map
  map("m", function()
    local ok, dungeon = pcall(require, "dungeon")
    if ok then dungeon.map()
    else vim.notify("Dungeon not loaded", vim.log.levels.WARN) end
  end, "Zark: dungeon map")

  -- <BS>: dungeon back
  map("<BS>", function()
    local ok, dungeon = pcall(require, "dungeon")
    if ok then dungeon.back()
    else vim.notify("Dungeon not loaded", vim.log.levels.WARN) end
  end, "Zark: dungeon back")
end

-- ── Public API ────────────────────────────────────────────────────────────────

function M.toggle()
  -- If window is valid and focused, close it
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    if vim.api.nvim_get_current_win() == state.win then
      vim.api.nvim_win_close(state.win, true)
      state.win = nil
      state.buf = nil
      return
    end
    -- Already open but not focused — move focus to it
    vim.api.nvim_set_current_win(state.win)
    return
  end
  -- Open fresh
  state.context = infer_context()
  open_window()
  redraw()
  start_watcher(state.context)
end

function M.setup(opts)
  opts = opts or {}
  if opts.zark_bin then ZARK_BIN = opts.zark_bin end

  setup_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = setup_highlights,
    desc = "Zark: reapply highlights",
  })

  -- Clean up state refs when buffer is wiped
  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(ev)
      if ev.buf == state.buf then
        stop_watcher()
        state.buf = nil
        state.win = nil
      end
    end,
    desc = "Zark: clean up state on wipe",
  })

  vim.keymap.set("n", "<leader>z", M.toggle, { desc = "Zark: open/focus party buffer" })
end

return M
