local M = {}

-- Braille dot bit positions for each row in left and right columns
local LEFT_BITS  = { 0x01, 0x02, 0x04, 0x40 }  -- rows 0-3, left column
local RIGHT_BITS = { 0x08, 0x10, 0x20, 0x80 }  -- rows 0-3, right column

-- Max braille chars to emit (each char = 2 cols × 4 rows = covers 4 lines)
local MAX_BRAILLE_CHARS = 20

local function is_blank(line)
  return line:match("^%s*$") ~= nil
end

-- Extract a human-readable label from the first meaningful line of the fold.
-- Tries to grab function/class/section names.
local function extract_label(line)
  if not line then return "" end
  -- Strip leading whitespace
  local s = line:match("^%s*(.-)%s*$")
  -- Lua function
  local label = s:match("^local%s+function%s+([%w_%.]+)")
    or s:match("^function%s+([%w_%.]+)")
    -- JS/TS function / arrow
    or s:match("^[a-zA-Z_$][%w_$]*%s*[:=]%s*function")
    and s:match("^([a-zA-Z_$][%w_$]*)")
    -- class / def / fn / sub
    or s:match("^class%s+([%w_]+)")
    or s:match("^def%s+([%w_]+)")
    or s:match("^fn%s+([%w_]+)")
    or s:match("^sub%s+([%w_]+)")
    -- Markdown heading
    or s:match("^#+%s+(.+)")
  if label then return label end
  -- Fall back: first 30 chars of the stripped line
  if #s > 30 then
    return s:sub(1, 30) .. "…"
  end
  return s
end

-- Build the braille minimap string for the given lines.
-- Each braille character represents 4 consecutive lines × 2 columns.
-- Left column: line is non-blank → dot on. Right column: same rule for next batch column.
-- We treat the lines array in pairs-of-columns: for char i, lines [4i..4i+3] go left,
-- lines [4i+4..4i+7] go right — BUT that would require 8 lines per char.
-- Instead we use the simpler model: each char covers 4 consecutive lines;
-- left column = "content present" heuristic, right column = indentation depth heuristic.
local function build_minimap(lines, max_chars)
  local chars = {}
  local n = #lines
  -- Each braille char represents 4 lines
  local groups = math.min(max_chars, math.ceil(n / 4))

  for g = 0, groups - 1 do
    local bits = 0
    for row = 0, 3 do
      local li = g * 4 + row + 1  -- 1-indexed into lines
      if li <= n then
        local line = lines[li]
        -- Left dot: any non-whitespace content
        if not is_blank(line) then
          bits = bits + LEFT_BITS[row + 1]
        end
        -- Right dot: indentation >= 2 spaces (signals nested/indented content)
        if line:match("^  ") then
          bits = bits + RIGHT_BITS[row + 1]
        end
      end
    end
    chars[#chars + 1] = vim.fn.nr2char(0x2800 + bits)
  end

  return table.concat(chars)
end

function M.foldtext()
  local fstart = vim.v.foldstart
  local fend   = vim.v.foldend
  local nlines = fend - fstart + 1

  -- Fetch up to MAX_BRAILLE_CHARS * 4 lines for the minimap
  local fetch_count = math.min(nlines, MAX_BRAILLE_CHARS * 4)
  local ok, lines = pcall(
    vim.api.nvim_buf_get_lines,
    0, fstart - 1, fstart - 1 + fetch_count, false
  )
  if not ok or #lines == 0 then
    return ("+-- %d lines "):format(nlines)
  end

  local strip = build_minimap(lines, MAX_BRAILLE_CHARS)
  local label = extract_label(lines[1])
  local count_str = ("  (%d lines)"):format(nlines)

  return strip .. "  " .. label .. count_str
end

-- Maps the cursor column within the braille strip to a proportional line in the fold,
-- opens the fold, and jumps to that line.
local function open_fold_at_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  -- Check if line is actually folded
  if vim.fn.foldclosed(row) == -1 then
    -- Not folded; pass through a normal <CR>
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false)
    return
  end

  local fstart = vim.fn.foldclosed(row)
  local fend   = vim.fn.foldclosedend(row)
  local nlines = fend - fstart + 1

  -- Each braille char is 1 display column wide; strip starts at col 0.
  -- Map col position to a line fraction (clamp to valid range).
  local strip_len = math.min(MAX_BRAILLE_CHARS, math.ceil(nlines / 4))
  local fraction  = strip_len > 0 and (col / strip_len) or 0
  fraction = math.max(0, math.min(1, fraction))

  local target_line = fstart + math.floor(fraction * (nlines - 1))

  vim.cmd("normal! zO")
  vim.api.nvim_win_set_cursor(0, { target_line, 0 })
  vim.cmd("normal! zz")
end

function M.setup()
  -- Set global foldtext; use a v:lua expression that calls back into this module.
  vim.o.foldtext = "v:lua.require('custom.braillefold').foldtext()"

  -- <CR> on a folded line opens at proportional position; elsewhere acts normally.
  vim.keymap.set("n", "<CR>", function()
    open_fold_at_cursor()
  end, { desc = "Open fold at cursor-proportional line", silent = true })
end

return M
