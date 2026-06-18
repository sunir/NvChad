--[[
zork.lua — Shared chat sidebar

<leader>z   open sidebar / focus staging / hide if already in sidebar
<leader>z>  anchor comment: pre-fills staging with [file:line] prefix

Layout: two stacked panes in a right sidebar
  ┌─ repo:zork ───────────────────┐
  │ [10:01] you: hey             │  ← log (readonly, auto-refreshes)
  │ [10:02] claude: hi           │
  ├──────────────────────────────┤
  │ type here...                 │  ← staging (writable scratchpad)
  │                              │
  └──────────────────────────────┘

Staging keymaps:
  <C-CR>  send staged text to channel, clear scratchpad

Log keymaps:
  r       refresh
  ] / [   next / prev patch
  <CR>    open diff view for patch at cursor
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
  agent     = nil,  -- e.g. "zork:nvim:12345"
  watcher   = nil,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function infer_context()
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

local ZORK_NS    = vim.api.nvim_create_namespace("zork")
local ZORK_AI_NS = vim.api.nvim_create_namespace("zork_ai_change")

-- Highlight group for AI-changed lines (defined once; cleared on BufWritePost)
vim.api.nvim_set_hl(0, "ZorkAIChange",     { bg = "#1e3a5f", default = true })
vim.api.nvim_set_hl(0, "ZorkAIChangeSign", { fg = "#89b4fa", bold = true, default = true })

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

-- patch_lines[ctx] = list of {log_line_idx (0-based), msg} for patch entries.
-- Rebuilt on every render_log call; used by patch navigator.
local patch_lines = {}   -- ctx → [{line, msg}, ...]
local patch_sel   = {}   -- ctx → currently selected patch index (1-based)

-- Returns lines[] and hls[] = {line_idx (0-based), col_s, col_e, hl_group}
local function render_log(ctx, win_w)
  win_w = win_w or 80
  local lines = { " " .. ctx, string.rep("─", 58) }
  local hls   = {}
  local msgs  = read_messages(ctx)
  patch_lines[ctx] = {}
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
  local indent = string.rep(" ", name_w + 1)
  local msg_w  = math.max(10, win_w - name_w - 1 - TIME_INLINE_LEN)

  local sel_idx = patch_sel[ctx] or 0

  for _, msg in ipairs(msgs) do
    local role    = msg.role or "?"
    local text    = msg.text or msg.message or ""
    local ts      = string.format("[%s] ", (msg.ts or ""):sub(12, 16))
    local who     = msg.npc_name or (role == "user" and "you" or (role == "assistant" and "claude" or role))

    -- Patch messages: render as a compact file entry with diff stats
    if role == "patch" then
      local ctx2   = msg.context or {}
      local file   = ctx2.file or text
      local diff   = ctx2.diff or ""
      local adds   = select(2, diff:gsub("\n%+[^+]", ""))
      local dels   = select(2, diff:gsub("\n%-[^-]", ""))
      local stat   = string.format("+%d/-%d", adds, dels)
      local pidx   = #patch_lines[ctx] + 1
      local is_sel = (pidx == sel_idx)
      local marker = is_sel and "▶ 📄" or "  📄"
      local entry  = string.format("%s %-40s %s  [%s]", marker, file, stat, ts:gsub("%[(.-)%].*", "%1"))
      local line_idx = #lines
      lines[#lines + 1] = entry
      patch_lines[ctx][#patch_lines[ctx] + 1] = { line = line_idx, msg = msg }
      -- Highlight: file name in blue, stats in green/red
      hls[#hls + 1] = { line_idx, #marker + 1, #marker + 1 + #file, "ZorkAIChangeSign" }
      if is_sel then
        hls[#hls + 1] = { line_idx, 0, #entry, "CursorLine" }
      end
    else
      local label   = rpad_display(name_emoji(who) .. " " .. who .. ":", name_w)
      local prefix  = label .. " " .. ts

      local wrapped = word_wrap(text, msg_w)
      for i, part in ipairs(wrapped) do
        local line_idx = #lines
        lines[#lines + 1] = (i == 1 and prefix or indent) .. part
        if i == 1 then
          hls[#hls + 1] = { line_idx, 0, #label, ensure_hl(who) }
          local ts_start = #label + 1
          hls[#hls + 1] = { line_idx, ts_start, ts_start + #ts, "ZorkTime" }
        end
      end
    end
  end
  return lines, hls
end

-- Open a scratch buffer showing the unified diff for a patch message.
-- The buffer uses filetype=diff for syntax highlighting.
-- Press q to close.
local function open_diff_view(msg)
  local ctx = msg.context or {}
  local file = ctx.file or "(unknown)"
  local diff = ctx.diff or ""
  local content = ctx.content
  local base_content = ctx.base_content

  -- Prefer showing full file diff: base vs agent content side-by-side in diff mode
  if content and base_content then
    local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
    local abs_path = (root ~= "" and (root .. "/" .. file) or file)

    -- Left pane: base (sync_commit state)
    vim.cmd("vsplit")
    local base_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, base_buf)
    vim.bo[base_buf].buftype   = "nofile"
    vim.bo[base_buf].bufhidden = "wipe"
    vim.bo[base_buf].swapfile  = false
    vim.api.nvim_buf_set_name(base_buf, "[zork base] " .. file)
    local base_lines = vim.split(base_content, "\n", { plain = true })
    if base_lines[#base_lines] == "" then table.remove(base_lines) end
    vim.api.nvim_buf_set_lines(base_buf, 0, -1, false, base_lines)
    -- infer filetype from extension
    local ext = file:match("%.(%w+)$")
    if ext then pcall(function() vim.bo[base_buf].filetype = ext end) end
    vim.cmd("diffthis")
    vim.keymap.set("n", "q", function()
      vim.cmd("diffoff!")
      vim.api.nvim_buf_delete(base_buf, { force = true })
    end, { buffer = base_buf, nowait = true, desc = "Zork: close diff" })

    -- Right pane: agent content
    vim.cmd("vsplit")
    local agent_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, agent_buf)
    vim.bo[agent_buf].buftype   = "nofile"
    vim.bo[agent_buf].bufhidden = "wipe"
    vim.bo[agent_buf].swapfile  = false
    vim.api.nvim_buf_set_name(agent_buf, "[zork patch] " .. file)
    local agent_lines = vim.split(content, "\n", { plain = true })
    if agent_lines[#agent_lines] == "" then table.remove(agent_lines) end
    vim.api.nvim_buf_set_lines(agent_buf, 0, -1, false, agent_lines)
    if ext then pcall(function() vim.bo[agent_buf].filetype = ext end) end
    vim.cmd("diffthis")
    vim.keymap.set("n", "q", function()
      vim.cmd("diffoff!")
      pcall(vim.api.nvim_buf_delete, base_buf, { force = true })
      vim.api.nvim_buf_delete(agent_buf, { force = true })
    end, { buffer = agent_buf, nowait = true, desc = "Zork: close diff" })
    return
  end

  -- Fallback: show raw unified diff in a scratch buffer
  local diff_buf = vim.api.nvim_create_buf(false, true)
  vim.cmd("vsplit")
  vim.api.nvim_win_set_buf(0, diff_buf)
  vim.bo[diff_buf].buftype   = "nofile"
  vim.bo[diff_buf].bufhidden = "wipe"
  vim.bo[diff_buf].filetype  = "diff"
  vim.api.nvim_buf_set_name(diff_buf, "[zork diff] " .. file)
  local diff_lines = vim.split(diff ~= "" and diff or "(no diff)", "\n", { plain = true })
  vim.api.nvim_buf_set_lines(diff_buf, 0, -1, false, diff_lines)
  vim.keymap.set("n", "q", function()
    vim.api.nvim_buf_delete(diff_buf, { force = true })
  end, { buffer = diff_buf, nowait = true, desc = "Zork: close diff" })
end

local redraw_log  -- forward declaration; defined below

-- Navigate to the Nth patch in the log and scroll to it.
local function nav_patch(ctx, delta)
  local pl = patch_lines[ctx]
  if not pl or #pl == 0 then
    vim.notify("zork: no patches in log", vim.log.levels.INFO)
    return
  end
  local cur = patch_sel[ctx] or 0
  local next = math.max(1, math.min(#pl, cur + delta))
  patch_sel[ctx] = next
  redraw_log()  -- re-render with new selection highlight
  -- Scroll log window to the selected patch line
  if state.win_log and vim.api.nvim_win_is_valid(state.win_log) then
    local target_line = pl[next] and (pl[next].line + 1) or 1
    pcall(vim.api.nvim_win_set_cursor, state.win_log, { target_line, 0 })
  end
end

local function open_patch_at_cursor()
  local ctx = state.context
  if not ctx then return end
  local pl = patch_lines[ctx]
  if not pl or #pl == 0 then return end
  local cursor_line = vim.api.nvim_win_get_cursor(state.win_log)[1] - 1  -- 0-based
  -- Find which patch the cursor is on (or nearest)
  local best = nil
  for i, entry in ipairs(pl) do
    if entry.line == cursor_line then best = i; break end
    if entry.line <= cursor_line then best = i end
  end
  if not best then best = patch_sel[ctx] or 1 end
  patch_sel[ctx] = best
  redraw_log()
  if pl[best] then open_diff_view(pl[best].msg) end
end

redraw_log = function()
  if not state.buf_log or not vim.api.nvim_buf_is_valid(state.buf_log) then return end
  local ctx = state.context
  if not ctx then return end
  local win_w = (state.win_log and vim.api.nvim_win_is_valid(state.win_log))
                and vim.api.nvim_win_get_width(state.win_log) or 80
  local lines, hls = render_log(ctx, win_w)
  vim.api.nvim_buf_set_lines(state.buf_log, 0, -1, false, lines)
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

-- ── Patch stream (W8) ────────────────────────────────────────────────────────

-- Track the last line of the log we've processed for patches (avoids re-applying).
local patch_cursor = {}  -- ctx → line count already processed

local function parse_hunks(diff)
  -- Parse a unified diff string into a list of hunks.
  -- Each hunk: { start (1-based), old_lines, new_lines }
  local hunks = {}
  local hunk = nil
  for line in (diff .. "\n"):gmatch("([^\n]*)\n") do
    local a, b = line:match("^@@ %-(%d+),?%d* %+(%d+),?%d* @@")
    if a then
      if hunk then hunks[#hunks + 1] = hunk end
      hunk = { start = tonumber(a), old_lines = {}, new_lines = {} }
    elseif hunk then
      local c = line:sub(1, 1)
      if c == "-" then
        hunk.old_lines[#hunk.old_lines + 1] = line:sub(2)
      elseif c == "+" then
        hunk.new_lines[#hunk.new_lines + 1] = line:sub(2)
      elseif c == " " then
        hunk.old_lines[#hunk.old_lines + 1] = line:sub(2)
        hunk.new_lines[#hunk.new_lines + 1] = line:sub(2)
      end
    end
  end
  if hunk then hunks[#hunks + 1] = hunk end
  return hunks
end

local function lines_match(actual, expected)
  if #actual ~= #expected then return false end
  for i, v in ipairs(expected) do
    if actual[i] ~= v then return false end
  end
  return true
end

-- Mark lines changed by AI: gutter sign + line highlight + virtual text via extmarks.
-- old_lines / new_lines are 0-indexed line arrays (from nvim_buf_get_lines).
local function mark_ai_changes(bufnr, old_lines, new_lines)
  vim.api.nvim_buf_clear_namespace(bufnr, ZORK_AI_NS, 0, -1)
  local buf_len = vim.api.nvim_buf_line_count(bufnr)
  local n = math.max(#old_lines, #new_lines)
  for i = 0, n - 1 do
    local old = old_lines[i + 1]
    local new = new_lines[i + 1]
    if old ~= new and i < buf_len then
      vim.api.nvim_buf_set_extmark(bufnr, ZORK_AI_NS, i, 0, {
        sign_text      = "🤖",
        sign_hl_group  = "ZorkAIChangeSign",
        line_hl_group  = "ZorkAIChange",
        priority       = 150,
        virt_text      = { { " 🤖", "ZorkAIChangeSign" } },
        virt_text_pos  = "eol",
      })
    end
  end
  -- Clear marks when the user saves (accepting the AI changes)
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = bufnr,
    once   = true,
    callback = function()
      vim.api.nvim_buf_clear_namespace(bufnr, ZORK_AI_NS, 0, -1)
    end,
  })
end

-- 3-way merge via git merge-file. Writes three temp files, runs merge-file,
-- reads result. Returns {lines, had_conflicts} where lines is the merged content
-- and had_conflicts is true if conflict markers are present.
local function three_way_merge(base_content, ours_lines, theirs_content)
  local tmp = vim.fn.tempname
  local base_f   = tmp() .. ".base"
  local ours_f   = tmp() .. ".ours"
  local theirs_f = tmp() .. ".theirs"

  -- Write base (sync_commit state)
  local fb = io.open(base_f, "w"); if fb then fb:write(base_content); fb:close() end
  -- Write ours (current buffer)
  local fo = io.open(ours_f, "w")
  if fo then fo:write(table.concat(ours_lines, "\n") .. "\n"); fo:close() end
  -- Write theirs (agent content)
  local ft = io.open(theirs_f, "w"); if ft then ft:write(theirs_content); ft:close() end

  -- git merge-file -p writes merged output to stdout; exit 0=clean, 1=conflicts, >1=error
  local result = vim.fn.system({
    "git", "merge-file", "-p",
    "--marker-size=7",
    ours_f, base_f, theirs_f,
  })
  local exit_code = vim.v.shell_error

  -- Clean up temp files
  vim.fn.delete(base_f); vim.fn.delete(ours_f); vim.fn.delete(theirs_f)

  if exit_code > 1 then return nil, false end  -- error; caller falls back
  local lines = vim.split(result, "\n", { plain = true })
  if lines[#lines] == "" then table.remove(lines) end
  local had_conflicts = exit_code == 1
  return lines, had_conflicts
end

local function apply_patch_msg(msg)
  -- Apply a role:"patch" message to the matching open buffer.
  -- If buffer is clean: whole-buffer replace (agent content wins, undoable).
  -- If buffer is dirty and base_content present: 3-way merge via git merge-file.
  --   Clean result → apply. Conflicts → report to agent, leave buffer untouched.
  -- Falls back to hunk-by-hunk apply if no content provided.
  -- NEVER writes to disk — only modifies the Neovim buffer.
  local ctx = msg.context or {}
  local file = ctx.file
  local diff = ctx.diff
  local content = ctx.content
  local base_content = ctx.base_content
  if not file or (not content and (not diff or diff == "")) then return {} end

  -- Find the buffer for this file (repo-relative path)
  local root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("\n", "")
  local abs_path = (root ~= "" and (root .. "/" .. file) or file)
  local bufnr = vim.fn.bufnr(abs_path)
  if bufnr == -1 then
    -- File not open in Neovim — skip. Never write to disk from the patch applicator.
    return {}
  end
  if not vim.bo[bufnr].modifiable then
    -- Buffer is protected (readonly/nomodifiable) — leave it untouched.
    return {}
  end

  if content then
    local is_dirty = vim.bo[bufnr].modified
    -- 3-way merge when buffer has unsaved edits and we have the common ancestor
    if is_dirty and base_content then
      local ours_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local merged_lines, had_conflicts = three_way_merge(base_content, ours_lines, content)
      if merged_lines and not had_conflicts then
        -- Clean merge: apply without touching human's cursor position
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, merged_lines)
        mark_ai_changes(bufnr, ours_lines, merged_lines)
        return {}
      elseif merged_lines and had_conflicts then
        -- Conflicts: leave buffer untouched, report back to agent
        local task_id = ctx.task_id
        return {{ file = file, hunk = 0,
                  user_has = ours_lines,
                  agent_wanted = { old = {}, new = vim.split(content, "\n", { plain = true }) },
                  conflict_type = "merge_conflict" }}
      end
      -- merge-file error: fall through to whole-buffer replace
    end

    -- Clean buffer (or merge unavailable): whole-buffer replace
    local lines = vim.split(content, "\n", { plain = true })
    if lines[#lines] == "" then table.remove(lines) end
    local old_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    mark_ai_changes(bufnr, old_lines, lines)
    return {}
  end

  -- Fallback: hunk-by-hunk apply
  local hunks = parse_hunks(diff)
  local conflicts = {}
  -- Apply in reverse order so line numbers stay valid
  for i = #hunks, 1, -1 do
    local h = hunks[i]
    local s = h.start - 1  -- 0-based
    local e = s + #h.old_lines
    local actual = vim.api.nvim_buf_get_lines(bufnr, s, e, false)
    if lines_match(actual, h.old_lines) then
      vim.api.nvim_buf_set_lines(bufnr, s, e, false, h.new_lines)
    else
      conflicts[#conflicts + 1] = {
        file = file, hunk = i,
        user_has = actual,
        agent_wanted = { old = h.old_lines, new = h.new_lines },
      }
    end
  end
  return conflicts
end

local function send_patch_conflicts(conflicts, task_id, channel)
  if #conflicts == 0 then return end
  for _, c in ipairs(conflicts) do
    local ctx_json = vim.json.encode({
      task_id      = task_id,
      file         = c.file,
      hunk         = c.hunk,
      user_has     = c.user_has,
      agent_wanted = c.agent_wanted,
    })
    -- zork patch conflict <channel> <ctx_json>: sends role:patch_conflict message
    local cmd = channel
      and { ZORK_BIN, "patch", "conflict", channel, ctx_json }
      or  { ZORK_BIN, "patch", "conflict", ctx_json }
    vim.fn.jobstart(cmd, { detach = true })
    vim.notify("zork: patch conflict in " .. c.file .. " hunk " .. c.hunk
               .. " — sent to agent", vim.log.levels.WARN)
  end
end

local function process_new_patches(ctx)
  -- Check log for new patch messages since patch_cursor[ctx].
  local path = log_path_for(ctx)
  local f = io.open(path, "r")
  if not f then return end
  local all = {}
  for line in f:lines() do
    local ok, msg = pcall(vim.json.decode, line)
    if ok and msg then all[#all + 1] = msg end
  end
  f:close()
  local seen = patch_cursor[ctx] or 0
  if #all <= seen then return end
  for i = seen + 1, #all do
    local msg = all[i]
    if msg.role == "patch" then
      local conflicts = apply_patch_msg(msg)
      local task_id = (msg.context or {}).task_id
      send_patch_conflicts(conflicts, task_id, ctx)
    end
  end
  patch_cursor[ctx] = #all
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
      vim.schedule(function()
        redraw_log()
        process_new_patches(ctx)
      end)
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
  local agent = state.agent
  state.win_log   = nil
  state.buf_log   = nil
  state.win_stage = nil
  state.buf_stage = nil
  state.context   = nil
  state.agent     = nil
  -- Only leave if we know the nvim agent identity; without it we'd
  -- accidentally remove the Claude agent's subscription (cwd default).
  if ctx and agent then
    vim.fn.jobstart({ ZORK_BIN, "leave", ctx }, { detach = false, env = { ZORK_AGENT = agent } })
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
  vim.wo[win_stage].statusline  = "  Ctrl-Enter: send"

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
  ml("<Esc>", close,      "Zork: close")
  ml("r",     redraw_log, "Zork: refresh")
  ml("]",  function() nav_patch(state.context, 1)  end, "Zork: next patch")
  ml("[",  function() nav_patch(state.context, -1) end, "Zork: prev patch")
  ml("<CR>", open_patch_at_cursor, "Zork: open patch diff")
  -- Block insert-mode entry so users can't accidentally edit the log.
  -- The buffer is intentionally kept modifiable (no nomodifiable flag) so
  -- programmatic writes from redraw_log never cause E21.
  for _, k in ipairs({"i","I","a","A","o","O","s","S","c","C","d","D","x","X","p","P","u","R"}) do
    ml(k, "<Nop>", "Zork: read-only log")
  end

  -- Staging keymaps
  local function ms(modes, key, fn, desc)
    vim.keymap.set(modes, key, fn, { buffer = buf_stage, nowait = true, desc = desc })
  end
  ms({ "n", "i" }, "<C-CR>", function()
    vim.cmd("stopinsert")
    send_staged()
  end, "Zork: send")

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
      local ag = state.agent
      state.win_stage = nil
      state.buf_stage = nil
      state.win_log   = nil
      state.buf_log   = nil
      state.context   = nil
      state.agent     = nil
      -- Only leave if we know the nvim agent identity; without it we'd
      -- accidentally remove the Claude agent's subscription (cwd default).
      if c and ag then
        vim.fn.jobstart({ ZORK_BIN, "leave", c }, { detach = false, env = { ZORK_AGENT = ag } })
      end
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
    local cur = vim.api.nvim_get_current_win()
    if cur == state.win_stage or cur == state.win_log then
      -- Already in sidebar — toggle means close
      close()
    else
      -- Not in sidebar — focus staging
      if stage_open then vim.api.nvim_set_current_win(state.win_stage) end
    end
    return
  end

  state.context = infer_context()
  state.agent   = vim.fn.fnamemodify(vim.fn.getcwd(), ":t") .. ":nvim:" .. vim.fn.getpid()
  -- Set patch_cursor to current log length so only patches arriving AFTER this
  -- join are applied to buffers. Re-applying old patches is a no-op for content
  -- but erases marks (mark_ai_changes sees old==new and sets nothing).
  do
    local _path = log_path_for(state.context)
    local _f = io.open(_path, "r")
    local _n = 0
    if _f then for _ in _f:lines() do _n = _n + 1 end; _f:close() end
    patch_cursor[state.context] = _n
  end
  vim.fn.jobstart({ ZORK_BIN, "join", state.context }, {
    detach = true,
    env = { ZORK_AGENT = state.agent },
  })
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

  vim.keymap.set("n", "<leader>Z>", M.anchor, { desc = "Zork: anchor comment at file:line" })
  vim.keymap.set("n", "<leader>ZR", function()
    package.loaded["zork"] = nil
    require("zork").setup()
    vim.notify("zork reloaded", vim.log.levels.INFO)
  end, { desc = "Zork: hot-reload plugin" })
  vim.api.nvim_create_user_command("ZorkToggle", M.toggle, { desc = "Zork: open / focus sidebar" })
  vim.api.nvim_create_user_command("ZorkAnchor", M.anchor, { desc = "Zork: anchor comment at file:line" })
  vim.api.nvim_create_user_command("ZorkDebugMarks", function()
    local bufnr = vim.api.nvim_get_current_buf()
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, ZORK_AI_NS, 0, -1, { details = true })
    local ctx   = state.context or "(none)"
    local pc    = patch_cursor[ctx] or 0
    local pl    = patch_lines[ctx] or {}
    local lines = {
      "=== ZorkDebugMarks ===",
      ("buf=%d  ctx=%s  patch_cursor=%d  patch_log_entries=%d"):format(bufnr, ctx, pc, #pl),
      ("AI extmarks on this buffer: %d"):format(#marks),
    }
    for i, m in ipairs(marks) do
      lines[#lines + 1] = ("  [%d] line=%d col=%d"):format(i, m[2], m[3])
    end
    local log_path = log_path_for(ctx)
    local f = io.open(log_path, "r")
    local patch_count = 0
    if f then
      for line in f:lines() do
        local ok, msg = pcall(vim.json.decode, line)
        if ok and msg and msg.role == "patch" then patch_count = patch_count + 1 end
      end
      f:close()
    end
    lines[#lines + 1] = ("patch messages in log: %d  log=%s"):format(patch_count, log_path)
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, { desc = "Zork: show AI change mark state for current buffer" })
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
    if old_ctx and state.agent then
      vim.fn.jobstart({ ZORK_BIN, "leave", old_ctx }, { detach = false, env = { ZORK_AGENT = state.agent } })
    end
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
