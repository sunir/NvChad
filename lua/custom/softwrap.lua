local M = {}

function M.setup()
  local ns = vim.api.nvim_create_namespace("softwrap_hint")
  local float_win = nil

  local bg = "#0d1a2e"
  vim.api.nvim_set_hl(0, "SoftwrapFloat",  { bg = bg })
  vim.api.nvim_set_hl(0, "SoftwrapHint",   { fg = "#7f849c", bg = bg })
  vim.api.nvim_set_hl(0, "SoftwrapCursor", { fg = "#cdd6f4", bg = bg, bold = true })
  vim.api.nvim_set_hl(0, "SoftwrapSel",    { fg = "#cdd6f4", bg = "#313244" })
  vim.api.nvim_set_hl(0, "SoftwrapHeader", { fg = "#8B2020", bg = bg, bold = true })

  -- Scan upward from lnum (0-indexed) for the |---| separator, return header cells.
  local function find_table_headers(bufnr, lnum)
    for row = lnum - 1, 0, -1 do
      local l = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
      if l:match("^%s*|[-: |]+|%s*$") then
        if row > 0 then
          local hdr = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
          if hdr:match("^%s*|") then
            local cells = {}
            for cell in hdr:gmatch("|([^|]*)") do
              local t = cell:match("^%s*(.-)%s*$")
              if t ~= "" then table.insert(cells, t) end
            end
            return cells
          end
        end
        break
      elseif not l:match("^%s*|") then
        break
      end
    end
    return {}
  end

  -- Word-wrap a string to max_w, returning a list of sub-strings.
  local function wordwrap(s, max_w)
    local parts = {}
    while #s > 0 do
      if #s <= max_w then table.insert(parts, s); break end
      local at = max_w
      for i = max_w, 1, -1 do
        if s:sub(i, i):match("[ \t%-]") then at = i; break end
      end
      table.insert(parts, s:sub(1, at))
      s = s:sub(at + 1)
    end
    return parts
  end

  local function close_float()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
      pcall(vim.api.nvim_win_close, float_win, true)
    end
    float_win = nil
  end

  local function update_float()
    -- In markdown, auto-toggle wrap: table rows get nowrap, everything else wraps.
    if vim.bo.filetype == "markdown" then
      vim.wo.wrap = not vim.api.nvim_get_current_line():match("^%s*|")
    end

    close_float()
    if vim.wo.wrap then return end
    local line = vim.api.nvim_get_current_line()
    local win_w = vim.api.nvim_win_get_width(0)
    if #line <= win_w then return end

    local chunks       = {}  -- display lines for the float buffer
    local chunk_hdr    = {}  -- virt_text label (padded header or blanks)
    local chunk_col    = {}  -- 0-indexed col in original line where this chunk's content starts
    local chunk_len    = {}  -- byte length of cell content in this chunk

    local is_table = line:match("^%s*|") ~= nil

    if is_table then
      local bufnr   = vim.api.nvim_get_current_buf()
      local lnum    = vim.api.nvim_win_get_cursor(0)[1] - 1
      local headers = find_table_headers(bufnr, lnum)
      local max_hdr_w = 0
      for _, h in ipairs(headers) do max_hdr_w = math.max(max_hdr_w, #h) end
      local blank = string.rep(" ", max_hdr_w)
      -- Available content width: win_w minus "padded_header  | "
      local content_w = math.max(win_w - max_hdr_w - 4, 10)

      local cell_idx = 0
      local scan_pos = 0  -- tracks search position in original line (1-indexed)
      for cell in line:gmatch("|([^|]*)") do
        local trimmed = cell:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
          cell_idx = cell_idx + 1
          local hdr    = headers[cell_idx] or ""
          local padded = hdr .. string.rep(" ", max_hdr_w - #hdr)

          -- Find where trimmed content starts in the original line (1-indexed)
          local cell_start_1 = line:find(trimmed, scan_pos + 1, true)
          local cell_col0    = cell_start_1 and (cell_start_1 - 1) or scan_pos

          local parts = wordwrap(trimmed, content_w)
          local off   = 0
          for pi, part in ipairs(parts) do
            table.insert(chunks,    "| " .. part)
            table.insert(chunk_hdr, pi == 1 and padded or blank)
            table.insert(chunk_col, cell_col0 + off)
            table.insert(chunk_len, #part)
            off = off + #part
          end

          scan_pos = cell_start_1 and (cell_start_1 - 1 + #trimmed) or scan_pos
        end
      end

      if #chunks <= 1 then is_table = false end
    end

    -- Fallback: plain word-boundary wrap of the whole line
    if not is_table then
      chunks    = {}
      chunk_hdr = {}
      chunk_col = {}
      chunk_len = {}
      local s   = line
      local off = 0
      while #s > 0 do
        if #s <= win_w then
          table.insert(chunks, s); table.insert(chunk_col, off); table.insert(chunk_len, #s); break
        end
        local at = win_w
        for i = win_w, 1, -1 do
          if s:sub(i, i):match("[ \t%-/|]") then at = i; break end
        end
        table.insert(chunks, s:sub(1, at)); table.insert(chunk_col, off); table.insert(chunk_len, at)
        off = off + at
        s   = s:sub(at + 1)
      end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].filetype = ""   -- prevent filetype-based syntax
    vim.bo[buf].syntax   = ""
    pcall(vim.treesitter.stop, buf)  -- stop treesitter if it auto-attached
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, chunks)

    -- Dim all text; priority 200 beats treesitter (100) in case it fires anyway
    for i = 0, #chunks - 1 do
      vim.api.nvim_buf_set_extmark(buf, ns, i, 0, {
        end_row  = i,
        end_col  = #chunks[i + 1],
        hl_group = "SoftwrapHint",
        priority = 200,
      })
    end

    -- Inline header labels (table mode only)
    if is_table then
      for i, label in ipairs(chunk_hdr) do
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
          virt_text     = { { label .. "  ", "SoftwrapHeader" } },
          virt_text_pos = "inline",
        })
      end
    end

    -- Map a 0-indexed column in the original line to (chunk_idx_0, display_offset).
    local function col_to_chunk(col)
      if not is_table then
        return math.floor(col / win_w), col % win_w
      end
      for ci = 1, #chunks do
        local cs  = chunk_col[ci]
        local ce  = cs + chunk_len[ci] - 1
        if col >= cs and col <= ce then
          return ci - 1, 2 + col - cs  -- +2 for "| " prefix
        end
      end
      -- On a | separator: count pipes up to and including col
      local pipe_count = 0
      for i = 1, col + 1 do
        if line:sub(i, i) == "|" then pipe_count = pipe_count + 1 end
      end
      return math.min(math.max(pipe_count - 1, 0), #chunks - 1), 0
    end

    -- Cursor highlight
    local cur_col = vim.api.nvim_win_get_cursor(0)[2]
    local cur_chunk, cur_off = col_to_chunk(cur_col)
    if cur_chunk < #chunks then
      vim.api.nvim_buf_add_highlight(buf, ns, "SoftwrapCursor", cur_chunk, cur_off, cur_off + 1)
    end

    -- Visual selection highlight (current line only)
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" then
      local v_col = vim.fn.col("v") - 1
      local sel_s = math.min(v_col, cur_col)
      local sel_e = math.max(v_col, cur_col)
      for col = sel_s, sel_e do
        local fl, fc = col_to_chunk(col)
        if fl < #chunks then
          vim.api.nvim_buf_add_highlight(buf, ns, "SoftwrapSel", fl, fc, fc + 1)
        end
      end
    end

    -- Open float below cursor
    local screen_row = vim.fn.winline()
    local avail      = vim.api.nvim_win_get_height(0) - screen_row
    local height     = math.min(#chunks, math.max(avail, 1))

    float_win = vim.api.nvim_open_win(buf, false, {
      relative  = "win",
      row       = screen_row,
      col       = 0,
      width     = win_w,
      height    = height,
      style     = "minimal",
      border    = "none",
      focusable = false,
      zindex    = 50,
    })
    vim.wo[float_win].winhl = "Normal:SoftwrapFloat"
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "ModeChanged" }, {
    callback = update_float,
  })
  vim.api.nvim_create_autocmd({ "CursorMovedI", "InsertEnter", "BufLeave", "WinLeave" }, {
    callback = close_float,
  })

  -- Restore wrap when leaving a markdown buffer (in case we left on a table row)
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    callback = function()
      if vim.bo.filetype == "markdown" then
        vim.wo.wrap = true
      end
    end,
  })
end

return M
