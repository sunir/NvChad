local M = {}

-- Braille 2×4 grid: one dot per column at the row matching AST depth.
-- Dot row = depth level (0=top, 3=bottom), so dot vertical position reads as depth.
-- Left column (rows 0-3): right column (rows 0-3):
local LEFT  = { 0x01, 0x02, 0x04, 0x40 }
local RIGHT = { 0x08, 0x10, 0x20, 0x80 }

local MAX_CHARS = 30  -- max braille characters in strip

-- Map treesitter node type → highlight group.
-- Only declarations and literals; control-flow and statements fall through to grey.
local NODE_HL = {
  -- String literals and docstrings
  string                = "@string",
  comment               = "@comment",
  -- Function/method declarations (the def/fn line itself)
  function_definition   = "@function",
  function_declaration  = "@function",
  method_definition     = "@function",
  method_declaration    = "@function",
  arrow_function        = "@function",
  local_function        = "@function",
  -- Type/class declarations
  class_definition      = "@type",
  class_declaration     = "@type",
  struct_item           = "@type",
  enum_item             = "@type",
  interface_declaration = "@type",
  -- Markdown headings
  atx_heading           = "@markup.heading",
  setext_heading        = "@markup.heading",
  section               = "@markup.heading",
}

local function node_hl(node)
  if not node then return "Comment" end
  -- Check node itself (catches string, comment, class_definition, function_definition)
  local hl = NODE_HL[node:type()]
  if hl then return hl end
  -- Check direct parent only — the def/class name identifier lives one level up from
  -- the declaration node, but body statements must NOT inherit their enclosing scope's color.
  local p = node:parent()
  if p then
    hl = NODE_HL[p:type()]
    if hl then return hl end
  end
  return "Comment"
end

-- Returns {depth (0-3), hl_group} for a buffer line (0-indexed).
-- Uses treesitter if available; falls back to whitespace indent depth.
local function line_info(bufnr, lnum, line_text)
  -- Blank line
  if line_text:match("^%s*$") then
    return -1, "Comment"  -- -1 = no dot
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if ok and parser then
    local tree = parser:parse()[1]
    if tree then
      local node = tree:root():named_descendant_for_range(lnum, 0, lnum, #line_text)
      if node then
        -- Depth: count ancestors, clamp 0-3
        local depth = 0
        local p = node:parent()
        while p and p:parent() do
          depth = depth + 1
          if depth >= 3 then break end
          p = p:parent()
        end
        return depth, node_hl(node)
      end
    end
  end

  -- Fallback: whitespace indent depth, no semantic color
  local indent = #(line_text:match("^(%s*)"))
  local depth  = math.min(math.floor(indent / 2), 3)
  return depth, "Comment"
end

-- Build list of {char, hl} pairs from fold lines.
-- Each braille character represents 2 lines (left col = line N, right col = N+1).
-- When both lines share a color, one char + one hl. When colors differ, two half-chars.
local function build_strip(bufnr, fstart, lines, max_chars)
  local pairs_needed = math.min(math.ceil(#lines / 2), max_chars)
  local result = {}  -- list of {text, hl}
  local current_text = ""
  local current_hl   = nil

  local function flush()
    if current_text ~= "" and current_hl then
      table.insert(result, { current_text, current_hl })
      current_text = ""
      current_hl   = nil
    end
  end

  local function emit(ch, hl)
    if hl == current_hl then
      current_text = current_text .. ch
    else
      flush()
      current_text = ch
      current_hl   = hl
    end
  end

  local prev_depth = 0
  local prev_hl    = "Comment"

  for i = 0, pairs_needed - 1 do
    local li_a = i * 2 + 1
    local li_b = i * 2 + 2
    local lnum_a = (fstart - 1) + (li_a - 1)
    local lnum_b = (fstart - 1) + (li_b - 1)

    local depth_a, hl_a = line_info(bufnr, lnum_a, lines[li_a] or "")
    local depth_b, hl_b
    if li_b <= #lines then
      depth_b, hl_b = line_info(bufnr, lnum_b, lines[li_b] or "")
    else
      depth_b, hl_b = -1, "Comment"
    end

    -- Blank lines inherit the previous non-blank line's depth/color so the
    -- terrain stays solid rather than breaking into scattered single dots.
    if depth_a < 0 then depth_a, hl_a = prev_depth, prev_hl
    else prev_depth, prev_hl = depth_a, hl_a end
    if depth_b < 0 then depth_b, hl_b = depth_a, hl_a
    else prev_depth, prev_hl = depth_b, hl_b end

    local bit_a = LEFT[depth_a + 1]
    local bit_b = RIGHT[depth_b + 1]

    if hl_a == hl_b then
      -- Same color: one character
      emit(vim.fn.nr2char(0x2800 + bit_a + bit_b), hl_a)
    else
      -- Different colors: split into left-only and right-only half-chars
      emit(vim.fn.nr2char(0x2800 + bit_a), hl_a)
      emit(vim.fn.nr2char(0x2800 + bit_b), hl_b)
    end
  end

  flush()
  return result
end

-- Extract label from the first meaningful fold line.
local function extract_label(line)
  if not line then return "", "Normal" end
  local s = line:match("^%s*(.-)%s*$")

  local label = s:match("^#+%s+(.+)")
  if label then return label, "@markup.heading" end

  label = s:match("^local%s+function%s+([%w_%.]+)")
       or s:match("^function%s+([%w_%.]+)")
       or s:match("^def%s+([%w_]+)")
       or s:match("^async%s+def%s+([%w_]+)")
       or s:match("^fn%s+([%w_]+)")
  if label then return label, "@function" end

  label = s:match("^class%s+([%w_]+)")
       or s:match("^struct%s+([%w_]+)")
       or s:match("^enum%s+([%w_]+)")
       or s:match("^interface%s+([%w_]+)")
  if label then return label, "@type" end

  if #s > 30 then return s:sub(1, 30) .. "…", "Normal" end
  return s, "Normal"
end

function M.foldtext()
  local fstart = vim.v.foldstart
  local fend   = vim.v.foldend
  local nlines = fend - fstart + 1
  local bufnr  = vim.api.nvim_get_current_buf()

  local fetch  = math.min(nlines, MAX_CHARS * 2)
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, fstart - 1, fstart - 1 + fetch, false)
  if not ok or #lines == 0 then
    return ("+-- %d lines "):format(nlines)
  end

  local strip        = build_strip(bufnr, fstart, lines, MAX_CHARS)
  local label, lhl   = extract_label(lines[1])
  local count        = ("  (%d lines)"):format(nlines)

  -- Assemble: strip pieces + space + label + count
  local result = {}
  for _, pair in ipairs(strip) do
    table.insert(result, pair)
  end
  table.insert(result, { "  " .. label, lhl    })
  table.insert(result, { count,         "Comment" })
  return result
end

local function open_fold_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if vim.fn.foldclosed(row) == -1 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    return
  end
  local fstart = vim.fn.foldclosed(row)
  local fend   = vim.fn.foldclosedend(row)
  local nlines = fend - fstart + 1
  -- Each char = ~2 lines (may be split, so approximate)
  local fraction = math.max(0, math.min(1, col / math.max(MAX_CHARS, 1)))
  local target   = fstart + math.floor(fraction * (nlines - 1))
  vim.cmd("normal! zO")
  vim.api.nvim_win_set_cursor(0, { target, 0 })
  vim.cmd("normal! zz")
end

function M.setup()
  vim.o.foldtext = "v:lua.require('custom.braillefold').foldtext()"
  vim.keymap.set("n", "<CR>", open_fold_at_cursor,
    { desc = "Open fold at cursor-proportional line", silent = true })
end

return M
