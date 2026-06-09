--[[
zork.lua — Shared chat sidebar

<leader>z   open sidebar / focus staging (never closes)
<leader>zq  close sidebar
<leader>z>  anchor comment: pre-fills staging with [file:line] prefix

Layout: two stacked panes in a right sidebar
  ┌─ repo:owner/name ────────────┐
  │ [10:01] you: hey             │  ← log (readonly, auto-refreshes)
  │ [10:02] claude: hi           │
  ├──────────────────────────────┤
  │ type here...                 │  ← staging (writable scratchpad)
  │                              │
  └──────────────────────────────┘

Staging keymaps:
  <C-CR>  send staged text to channel, clear scratchpad
  q       (normal mode, staging empty) close sidebar

Log keymaps:
  q / r   close / refresh
--]]

local M = {}

local ZORK_BIN   = "zork"
local ZORK_DIR   = vim.fn.expand("~/.config/zork")
local STAGE_HEIGHT = 5

local state = {
  win_log   = nil,
  buf_log   = nil,
  win_stage = nil,
  buf_stage = nil,
  context   = nil,
  watcher   = nil,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function infer_context()
  local remote = vim.fn.system("git remote get-url origin 2>/dev/null"):gsub("\n", "")
  if remote ~= "" then
    local name  = remote:gsub("%.git$", ""):match("[^/]+$") or ""
    local owner = remote:gsub("%.git$", ""):match("([^/:]+)/[^/]+$") or ""
    if owner ~= "" and name ~= "" then return "repo:" .. owner .. "/" .. name end
  end
  local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if root ~= "" then return "repo:" .. vim.fn.fnamemodify(root, ":t") end
  return "default"
end

local function log_path_for(ctx)
  local san = ctx:gsub("/", "-")
  local ctx_file = ZORK_DIR .. "/contexts/" .. san .. "/context"
  local f = io.open(ctx_file, "r")
  if f then
    local s = f:read("*a"); f:close()
    local ok, data = pcall(vim.json.decode, s)
    if ok and data and data.log_path then return data.log_path end
  end
  return ZORK_DIR .. "/channels/" .. san .. ".jsonl"
end

local function read_messages(ctx, limit)
  limit = limit or 60
  local path = log_path_for(ctx)
  local f = io.open(path, "r")
  if not f then return {} end
  local all = {}
  for line in f:lines() do
    local ok, msg = pcall(vim.json.decode, line)
    if ok and msg then all[#all + 1] = msg end
  end
  f:close()
  local result = {}
  for i = math.max(1, #all - limit + 1), #all do result[#result + 1] = all[i] end
  return result
end

-- ── Name colors and emoji ─────────────────────────────────────────────────────

local ZORK_NS = vim.api.nvim_create_namespace("zork")

local PALETTE = {
  "#89b4fa", "#a6e3a1", "#f38ba8", "#fab387",
  "#f9e2af", "#cba6f7", "#89dceb", "#74c7ec",
}
-- Per-name emoji overrides; extend via M.setup opts.name_emoji
-- zork's emoji is read from core/emoji in the repo at startup
local function _read_zork_emoji()
  local repo = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  if repo ~= "" then
    local f = io.open(repo .. "/core/emoji", "r")
    if f then
      local e = f:read("*a"):gsub("%s+$", ""); f:close()
      if #e > 0 then return e end
    end
  end
  return "𝒵"
end
local NAME_EMOJI = { zork = _read_zork_emoji() }

local HL_CACHE = {}

local function name_color(name)
  local h = 0
  for i = 1, #name do h = (h + string.byte(name, i)) % #PALETTE end
  return PALETTE[h + 1]
end

local function name_emoji(name)
  return NAME_EMOJI[name] or "🤖"
end

local function ensure_hl(name)
  if HL_CACHE[name] then return HL_CACHE[name] end
  local group = "ZorkName_" .. name:gsub("[^%w]", "_")
  vim.api.nvim_set_hl(0, group, { fg = name_color(name), bold = true })
  HL_CACHE[name] = group
  return group
end

-- ── Log rendering ─────────────────────────────────────────────────────────────

-- Inline time: "[HH:MM] " = 8 bytes (ASCII-safe)
local TIME_INLINE_LEN = 8

-- Pad s on the left so its display width == target (right-aligns within column)
local function rpad_display(s, target)
  local dw = vim.fn.strdisplaywidth(s)
  if dw >= target then return s end
  return string.rep(" ", target - dw) .. s
end

-- Word-wrap text to max_w display columns, respecting explicit \n paragraph breaks.
-- Returns a list of physical lines.
local function word_wrap(text, max_w)
  if max_w < 4 then return { text } end
  local result = {}
  for _, para in ipairs(vim.split(text, "\n", { plain = true })) do
    if para == "" then
      result[#result + 1] = ""
    else
      local line = ""
      for word in (para .. " "):gmatch("([^ ]*) ") do
        if word == "" then goto continue end
        local candidate = line == "" and word or (line .. " " .. word)
        if vim.fn.strdisplaywidth(candidate) <= max_w then
          line = candidate
        else
          if line ~= "" then result[#result + 1] = line end
          line = word
        end
        ::continue::
      end
      if line ~= "" then result[#result + 1] = line end
    end
  end
  return #result > 0 and result or { "" }
end

-- Returns lines[] and hls[] = {line_idx (0-based), col_s, col_e, hl_group}
local function render_log(ctx, win_w)
  win_w = win_w or 80
  local lines = { " " .. ctx, string.rep("─", 58) }
  local hls   = {}
  local msgs  = read_messages(ctx)
  if #msgs == 0 then
    lines[#lines + 1] = "  (no messages yet)"
    return lines, hls
  end

  -- First pass: compute name column width from actual names in log
  local name_w = 8
  for _, msg in ipairs(msgs) do
    local role = msg.role or "?"
    local who  = msg.npc_name or (role == "user" and "you" or (role == "assistant" and "claude" or role))
    local dw   = vim.fn.strdisplaywidth(name_emoji(who) .. " " .. who .. ":")
    if dw > name_w then name_w = dw end
  end

  -- Layout: <name_w cols: label> <space> <[HH:MM] > <message>
  -- Continuation lines indent to just past the name column
  local indent = string.rep(" ", name_w + 1)
  local msg_w  = math.max(10, win_w - name_w - 1 - TIME_INLINE_LEN)

  for _, msg in ipairs(msgs) do
    local role    = msg.role or "?"
    local text    = msg.text or msg.message or ""
    local ts      = string.format("[%s] ", (msg.ts or ""):sub(12, 16))  -- "[HH:MM] " = 8 chars
    local who     = msg.npc_name or (role == "user" and "you" or (role == "assistant" and "claude" or role))
    local label   = rpad_display(name_emoji(who) .. " " .. who .. ":", name_w)
    local prefix  = label .. " " .. ts  -- name + space + dim time

    local wrapped = word_wrap(text, msg_w)
    for i, part in ipairs(wrapped) do
      local line_idx = #lines
      lines[#lines + 1] = (i == 1 and prefix or indent) .. part
      if i == 1 then
        -- name highlight: 0 .. #label bytes
        hls[#hls + 1] = { line_idx, 0, #label, ensure_hl(who) }
        -- time highlight: after label + space
        local ts_start = #label + 1
        hls[#hls + 1] = { line_idx, ts_start, ts_start + #ts, "ZorkTime" }
      end
    end
  end
  return lines, hls
end

local function redraw_log()
  if not state.buf_log or not vim.api.nvim_buf_is_valid(state.buf_log) then return end
  local ctx = state.context
  if not ctx then return end
  local win_w = (state.win_log and vim.api.nvim_win_is_valid(state.win_log))
                and vim.api.nvim_win_get_width(state.win_log) or 80
  local lines, hls = render_log(ctx, win_w)
  vim.bo[state.buf_log].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf_log, 0, -1, false, lines)
  vim.bo[state.buf_log].modifiable = false
  -- Clear old highlights then apply new ones
  vim.api.nvim_buf_clear_namespace(state.buf_log, ZORK_NS, 0, -1)
  for _, h in ipairs(hls) do
    pcall(vim.api.nvim_buf_add_highlight, state.buf_log, ZORK_NS, h[4], h[1], h[2], h[3])
  end
  if state.win_log and vim.api.nvim_win_is_valid(state.win_log) then
    local lc = vim.api.nvim_buf_line_count(state.buf_log)
    vim.api.nvim_win_set_cursor(state.win_log, { lc, 0 })
    -- zb: scroll so last line sits at bottom of window (not just "visible")
    vim.api.nvim_win_call(state.win_log, function() vim.cmd("normal! zb") end)
  end
end

-- ── Watcher ───────────────────────────────────────────────────────────────────

local function stop_watcher()
  if state.watcher then
    state.watcher:stop()
    state.watcher:close()
    state.watcher = nil
  end
end

local function start_watcher(ctx)
  stop_watcher()
  local path = log_path_for(ctx)
  local handle = vim.uv.new_fs_event()
  if not handle then return end
  local debounce = nil
  handle:start(path, {}, function(err)
    if err then return end
    if debounce then debounce:stop() end
    debounce = vim.defer_fn(function()
      debounce = nil
      vim.schedule(redraw_log)
    end, 150)
  end)
  state.watcher = handle
end

-- ── Send ──────────────────────────────────────────────────────────────────────

local function send_staged()
  if not state.buf_stage or not vim.api.nvim_buf_is_valid(state.buf_stage) then return end
  local lines = vim.api.nvim_buf_get_lines(state.buf_stage, 0, -1, false)
  while #lines > 0 and lines[#lines]:match("^%s*$") do lines[#lines] = nil end
  if #lines == 0 then return end
  local text = table.concat(lines, "\n")
  vim.api.nvim_buf_set_lines(state.buf_stage, 0, -1, false, { "" })
  local user = vim.fn.system("whoami"):gsub("%s+$", "")
  local cmd = state.context
    and { ZORK_BIN, "send", state.context, text }
    or  { ZORK_BIN, "send", text }
  vim.fn.jobstart(cmd, {
    env = { ZORK_USER = user },
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then vim.notify("zork send failed", vim.log.levels.ERROR) end
      end)
    end,
  })
end

-- ── Close ─────────────────────────────────────────────────────────────────────

local function close()
  stop_watcher()
  local ctx = state.context
  for _, win in ipairs({ state.win_log, state.win_stage }) do
    if win and vim.api.nvim_win_is_valid(win) then
      -- E444: can't close the last window; skip silently
      if #vim.api.nvim_list_wins() > 1 then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
  state.win_log   = nil
  state.buf_log   = nil
  state.win_stage = nil
  state.buf_stage = nil
  state.context   = nil
  if ctx then
    vim.fn.jobstart({ ZORK_BIN, "leave", ctx }, { detach = false })
  end
end

-- ── Open ──────────────────────────────────────────────────────────────────────

local function open_sidebar(ctx)
  local width = math.min(62, math.floor(vim.o.columns * 0.38))

  -- Right sidebar: log buffer fills the top
  vim.cmd("botright " .. width .. "vsplit")
  local buf_log = vim.api.nvim_create_buf(false, true)
  local win_log = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_log, buf_log)
  vim.bo[buf_log].buftype   = "nofile"
  vim.bo[buf_log].bufhidden = "wipe"
  vim.wo[win_log].number     = false
  vim.wo[win_log].signcolumn = "no"
  vim.wo[win_log].wrap       = false  -- manual word-wrap in render_log; no visual wrap needed
  vim.wo[win_log].cursorline = false

  -- Staging area below
  vim.cmd("belowright " .. STAGE_HEIGHT .. "split")
  local buf_stage = vim.api.nvim_create_buf(false, true)
  local win_stage = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win_stage, buf_stage)
  vim.bo[buf_stage].buftype   = "nofile"
  vim.bo[buf_stage].bufhidden = "wipe"
  vim.wo[win_stage].number      = false
  vim.wo[win_stage].signcolumn  = "no"
  vim.wo[win_stage].wrap        = true
  vim.wo[win_stage].linebreak   = true
  vim.wo[win_stage].breakindent = false
  vim.wo[win_stage].statusline  = "  <C-CR> send  q close"

  state.buf_log   = buf_log
  state.win_log   = win_log
  state.buf_stage = buf_stage
  state.win_stage = win_stage

  -- Guard against plugins (e.g. tabufline) loading foreign buffers into sidebar windows.
  -- winfixbuf causes hard errors in NvChad; BufEnter revert is gentler.
  local guard_id = vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local function restore(w, b)
        if w and vim.api.nvim_win_is_valid(w) and b and vim.api.nvim_buf_is_valid(b)
           and win == w and vim.api.nvim_get_current_buf() ~= b then
          vim.api.nvim_win_set_buf(w, b)
        end
      end
      restore(state.win_log,   state.buf_log)
      restore(state.win_stage, state.buf_stage)
    end,
  })

  -- Log keymaps
  local function ml(key, fn, desc)
    vim.keymap.set("n", key, fn, { buffer = buf_log, nowait = true, desc = desc })
  end
  ml("q",     close,      "Zork: close")
  ml("<Esc>", close,      "Zork: close")
  ml("r",     redraw_log, "Zork: refresh")

  -- Staging keymaps
  local function ms(modes, key, fn, desc)
    vim.keymap.set(modes, key, fn, { buffer = buf_stage, nowait = true, desc = desc })
  end
  ms({ "n", "i" }, "<C-CR>", function()
    vim.cmd("stopinsert")
    send_staged()
  end, "Zork: send")
  ms("n", "q", function()
    local lines = vim.api.nvim_buf_get_lines(buf_stage, 0, -1, false)
    for _, l in ipairs(lines) do if l:match("%S") then return end end
    close()
  end, "Zork: close if empty")

  -- Sentinel auto-send: typing !! at end of last line sends without leaving insert mode
  vim.api.nvim_create_autocmd("TextChangedI", {
    buffer = buf_stage,
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(buf_stage, 0, -1, false)
      local last  = lines[#lines] or ""
      if last:match("!!%s*$") then
        lines[#lines] = last:gsub("!!%s*$", "")
        while #lines > 0 and lines[#lines]:match("^%s*$") do lines[#lines] = nil end
        if #lines > 0 then
          vim.api.nvim_buf_set_lines(buf_stage, 0, -1, false, lines)
          vim.cmd("stopinsert")
          send_staged()
        end
      end
    end,
  })

  -- Rerender when terminal or window dimensions change.
  -- VimResized fires on terminal resize; WinResized fires when split dimensions change.
  -- defer_fn gives Neovim time to update window dimensions before we query them.
  local function on_resize() vim.defer_fn(redraw_log, 30) end
  local resize_ids = {
    vim.api.nvim_create_autocmd("VimResized", { callback = on_resize }),
    vim.api.nvim_create_autocmd("WinResized",  { callback = on_resize }),
  }

  -- Cleanup on wipe (covers :bdelete, force-close, etc.)
  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf_stage, once = true,
    callback = function()
      for _, id in ipairs(resize_ids) do pcall(vim.api.nvim_del_autocmd, id) end
      pcall(vim.api.nvim_del_autocmd, guard_id)
      stop_watcher()
      local c = state.context
      state.win_stage = nil
      state.buf_stage = nil
      state.win_log   = nil
      state.buf_log   = nil
      state.context   = nil
      if c then vim.fn.jobstart({ ZORK_BIN, "leave", c }, { detach = false }) end
    end,
  })

  -- Focus staging, ready to type
  vim.api.nvim_set_current_win(win_stage)
  vim.cmd("startinsert")
end

-- ── Agent comment tracking ────────────────────────────────────────────────────

-- Per-buffer baseline: comment texts known at last read/write (dedup on save)
local buf_comment_baseline = {}  -- [bufnr] -> {text -> true}

-- Scan a buffer for agent comment annotations: lines like #>, //>, --> etc.
local function scan_agent_comments(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local found = {}
  for i, line in ipairs(lines) do
    local text = line:match("^%s*[#/%-!<][^>]*>%s*(.-)%s*$")
    if text and #text > 0 then
      found[#found + 1] = { lnum = i, text = text }
    end
  end
  return found
end

local function init_comment_baseline(bufnr)
  local baseline = {}
  for _, c in ipairs(scan_agent_comments(bufnr)) do baseline[c.text] = true end
  buf_comment_baseline[bufnr] = baseline
end

-- Clear baseline for the current buffer so all #> comments fire on next :w.
-- Useful for testing or re-sending existing annotations.
function M._reset_baseline(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  buf_comment_baseline[bufnr] = nil
  vim.notify("zork: baseline cleared for buffer " .. bufnr, vim.log.levels.INFO)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function M.toggle()
  local log_open   = state.win_log   and vim.api.nvim_win_is_valid(state.win_log)
  local stage_open = state.win_stage and vim.api.nvim_win_is_valid(state.win_stage)

  if log_open or stage_open then
    -- Always focus staging; never close from <leader>z (use q or <leader>zq)
    if vim.api.nvim_get_current_win() ~= state.win_stage then
      vim.api.nvim_set_current_win(state.win_stage)
    end
    return
  end

  state.context = infer_context()
  vim.fn.jobstart({ ZORK_BIN, "join", state.context }, { detach = true })
  open_sidebar(state.context)
  vim.defer_fn(function()
    redraw_log()
    start_watcher(state.context)
  end, 400)
end

-- Derive the `#>` / `// >` comment prefix for the current buffer's filetype
local function agent_comment_prefix()
  local cs = vim.bo.commentstring or "# %s"
  -- commentstring is like "# %s" or "// %s" or "-- %s" or "<!-- %s -->"
  local pre = cs:match("^(.-)%s*%%s") or "#"
  pre = pre:gsub("%s+$", "")
  return pre .. " >"
end

-- Insert an inline agent comment at cursor and ping the channel with file:line
function M.anchor()
  local src_win  = vim.api.nvim_get_current_win()
  local src_buf  = vim.api.nvim_get_current_buf()
  local file     = vim.fn.expand("%:~:.")
  local lnum     = vim.fn.line(".")
  local indent   = vim.fn.getline(lnum):match("^(%s*)") or ""
  local cprefix  = agent_comment_prefix()

  -- Insert the comment line below cursor in the source buffer
  if #file > 0 then
    local comment_line = indent .. cprefix .. " "
    vim.api.nvim_buf_set_lines(src_buf, lnum, lnum, false, { comment_line })
    -- Move cursor to end of inserted line for immediate typing
    vim.api.nvim_win_set_cursor(src_win, { lnum + 1, #comment_line })
    vim.cmd("startinsert!")
    -- After user leaves insert mode, send file:line ping to channel
    vim.api.nvim_create_autocmd("InsertLeave", {
      buffer = src_buf,
      once   = true,
      callback = function()
        local annotation = vim.fn.getline(lnum + 1):gsub("^%s*" .. vim.pesc(cprefix) .. "%s*", "")
        annotation = annotation:gsub("^%s+", ""):gsub("%s+$", "")
        local msg = "[" .. file .. ":" .. (lnum + 1) .. "]"
        if #annotation > 0 then msg = msg .. " " .. annotation end
        M.toggle()  -- open sidebar if not open
        vim.defer_fn(function()
          if state.buf_stage and vim.api.nvim_buf_is_valid(state.buf_stage) then
            local cur = vim.api.nvim_buf_get_lines(state.buf_stage, 0, -1, false)
            local empty = #cur == 0 or (#cur == 1 and cur[1] == "")
            if empty then
              vim.api.nvim_buf_set_lines(state.buf_stage, 0, -1, false, { msg })
            end
            -- Auto-send the ping
            send_staged()
          end
        end, 100)
      end,
    })
  else
    -- No file context — just open/focus sidebar
    M.toggle()
  end
end

-- Apply file content from a tmp file to an open buffer (avoids W12 conflicts).
-- filepath: absolute or relative path matching the buffer name.
-- tmpfile:  file containing the new buffer content (one entry per line).
-- Returns true if a buffer was found and updated; false if file not open.
function M.apply_edit(filepath, tmpfile)
  local resolved = vim.fn.resolve(vim.fn.fnamemodify(filepath, ":p"))
  local bufnr = -1
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) then
      local name = vim.fn.resolve(vim.api.nvim_buf_get_name(b))
      if name == resolved then bufnr = b; break end
    end
  end
  if bufnr == -1 then return false end
  local lines = vim.fn.readfile(tmpfile)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return true
end

function M.setup(opts)
  opts = opts or {}
  if opts.zork_bin   then ZORK_BIN = opts.zork_bin end
  if opts.zork_dir   then ZORK_DIR = opts.zork_dir end
  if opts.name_emoji then
    for k, v in pairs(opts.name_emoji) do NAME_EMOJI[k] = v end
  end

  -- Write the primary server address so external tools can find the socket.
  -- Deferred to VimEnter: vim.v.servername is empty during early plugin init.
  local function write_server_file()
    local _srv = vim.v.servername or ""
    if #_srv == 0 and #vim.fn.serverlist() > 0 then _srv = vim.fn.serverlist()[1] end
    if #_srv > 0 then
      local _f = io.open(ZORK_DIR .. "/nvim-server", "w")
      if _f then _f:write(_srv); _f:close() end
    end
  end
  write_server_file()
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = write_server_file })

  local function _setup_hls()
    vim.api.nvim_set_hl(0, "ZorkMuted", { fg = "#6c7086", italic = true })
    vim.api.nvim_set_hl(0, "ZorkTime",  { fg = "#585b70" })
  end
  _setup_hls()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      HL_CACHE = {}
      _setup_hls()
    end,
  })

  vim.keymap.set("n", "<leader>z",  M.toggle, { desc = "Zork: open / focus sidebar" })
  vim.keymap.set("n", "<leader>Zq", close,    { desc = "Zork: close sidebar" })
  vim.keymap.set("n", "<leader>Z>", M.anchor, { desc = "Zork: anchor comment at file:line" })
  vim.keymap.set("n", "<leader>ZR", function()
    package.loaded["zork"] = nil
    require("zork").setup()
    vim.notify("zork reloaded", vim.log.levels.INFO)
  end, { desc = "Zork: hot-reload plugin" })
  vim.api.nvim_create_user_command("ZorkToggle", M.toggle, { desc = "Zork: open / focus sidebar" })
  vim.api.nvim_create_user_command("ZorkAnchor", M.anchor, { desc = "Zork: anchor comment at file:line" })
  vim.api.nvim_create_user_command("ZorkSwitch", function(cmd_opts)
    local new_ctx = vim.trim(cmd_opts.args)
    if new_ctx == "" then
      vim.notify("Usage: ZorkSwitch <channel>", vim.log.levels.ERROR)
      return
    end
    local old_ctx = state.context
    if old_ctx == new_ctx then
      vim.notify("Already on " .. new_ctx, vim.log.levels.INFO)
      return
    end
    if old_ctx then vim.fn.jobstart({ ZORK_BIN, "leave", old_ctx }, { detach = false }) end
    state.context = new_ctx
    vim.fn.jobstart({ ZORK_BIN, "join", new_ctx }, { detach = true })
    start_watcher(new_ctx)
    vim.defer_fn(redraw_log, 400)
    vim.notify("Switched to " .. new_ctx, vim.log.levels.INFO)
  end, { nargs = 1, desc = "Zork: switch to a different channel" })

  -- Debug logging: set ZORK_DEBUG=1 in env or ':let g:zork_debug=1' to enable
  local function zdbg(fmt, ...)
    if vim.g.zork_debug ~= 1 then return end
    local msg = string.format("[zork] " .. fmt, ...)
    vim.notify(msg, vim.log.levels.DEBUG)
    -- Also append to ~/.config/zork/zork-debug.log
    local f = io.open(ZORK_DIR .. "/zork-debug.log", "a")
    if f then f:write(msg .. "\n"); f:close() end
  end

  -- Agent comment auto-send: when you save a file, any #> comment lines that
  -- weren't in the file when it was opened are sent to the channel.
  -- Baseline is captured on open so pre-existing comments are never re-sent.
  -- Augroup cleared on each M.setup() so :source doesn't pile up duplicates.
  local ag = vim.api.nvim_create_augroup("ZorkComments", { clear = true })

  -- BufEnter handles session-restored buffers that never fire BufReadPost.
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufEnter" }, {
    group = ag,
    callback = function(ev)
      if vim.bo[ev.buf].buftype ~= "" then return end
      if buf_comment_baseline[ev.buf] then return end  -- already baselined
      init_comment_baseline(ev.buf)
      local n = 0; for _ in pairs(buf_comment_baseline[ev.buf] or {}) do n = n + 1 end
      zdbg("baseline init buf=%d name=%s comments=%d", ev.buf,
           vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":t"), n)
    end,
  })

  -- Baseline all currently-open file buffers immediately.
  -- BufEnter/BufReadPost only fire for future buffer visits; buffers already
  -- open when M.setup() runs (or when :source reloads the plugin) are missed.
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr)
       and vim.bo[bufnr].buftype == ""
       and not buf_comment_baseline[bufnr] then
      init_comment_baseline(bufnr)
      zdbg("startup baseline buf=%d name=%s", bufnr,
           vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t"))
    end
  end

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = ag,
    callback = function(ev)
      local bufnr = ev.buf
      zdbg("BufWritePost buf=%d buftype=%q", bufnr, vim.bo[bufnr].buftype)
      if vim.bo[bufnr].buftype ~= "" then return end
      if bufnr == state.buf_stage then zdbg("skipping staging buf"); return end
      -- If no baseline yet, initialize now and skip sending (can't diff without baseline)
      if not buf_comment_baseline[bufnr] then
        zdbg("no baseline — initializing, skipping send")
        init_comment_baseline(bufnr)
        return
      end
      local baseline = buf_comment_baseline[bufnr]
      local current  = scan_agent_comments(bufnr)
      zdbg("scan found %d comments, baseline has %d",
           #current, (function() local n=0; for _ in pairs(baseline) do n=n+1 end; return n end)())
      -- Find newly added comments (text not seen before)
      local new_comments = {}
      for _, c in ipairs(current) do
        if not baseline[c.text] then
          zdbg("NEW comment lnum=%d: %s", c.lnum, c.text:sub(1,60))
          new_comments[#new_comments + 1] = c
        end
      end
      -- Update baseline to current state
      local new_baseline = {}
      for _, c in ipairs(current) do new_baseline[c.text] = true end
      buf_comment_baseline[bufnr] = new_baseline
      -- Send new comments to channel
      if #new_comments > 0 then
        local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~:.")
        local user = vim.fn.system("whoami"):gsub("%s+$", "")
        for _, c in ipairs(new_comments) do
          local msg = (#file > 0) and ("[" .. file .. ":" .. c.lnum .. "] " .. c.text) or c.text
          zdbg("sending: %s", msg:sub(1,80))
          local send_cmd = state.context
            and { ZORK_BIN, "send", state.context, msg }
            or  { ZORK_BIN, "send", msg }
          vim.fn.jobstart(send_cmd, { env = { ZORK_USER = user } })
        end
      else
        zdbg("no new comments to send")
      end
    end,
  })
end

return M
