local M = {}

function M.setup()
  local ns = vim.api.nvim_create_namespace("softwrap_hint")
  local float_win = nil

  vim.api.nvim_set_hl(0, "SoftwrapHint",   { fg = "#7f849c" })
  vim.api.nvim_set_hl(0, "SoftwrapCursor", { fg = "#cdd6f4", bold = true })
  vim.api.nvim_set_hl(0, "SoftwrapSel",    { fg = "#cdd6f4", bg = "#313244" })
  vim.api.nvim_set_hl(0, "SoftwrapHeader", { fg = "#8B2020", bold = true })

  -- Scan upward from lnum (0-indexed) for the |---| separator, then return
  -- the cells of the header row above it.
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

  local function close_float()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
      pcall(vim.api.nvim_win_close, float_win, true)
    end
    float_win = nil
  end

  local function update_float()
    -- In markdown, auto-toggle wrap: table rows get nowrap, everything else wraps
    if vim.bo.filetype == "markdown" then
      vim.wo.wrap = not vim.api.nvim_get_current_line():match("^%s*|")
    end

    close_float()
    if vim.wo.wrap then return end
    local line = vim.api.nvim_get_current_line()
    local win_w = vim.api.nvim_win_get_width(0)
    if #line <= win_w then return end

    -- Markdown table row: one cell per line
    local chunks = {}
    if line:match("^%s*|") then
      for cell in line:gmatch("|([^|]*)") do
        local trimmed = cell:match("^%s*(.-)%s*$")
        if trimmed ~= "" then
          table.insert(chunks, "| " .. trimmed)
        end
      end
    end
    -- Fallback: word-boundary wrapping (also used if table had only 1 cell)
    if #chunks <= 1 then
      chunks = {}
      local s = line
      while #s > 0 do
        if #s <= win_w then
          table.insert(chunks, s); break
        end
        local break_at = win_w
        for i = win_w, 1, -1 do
          if s:sub(i, i):match("[ \t%-/|]") then break_at = i; break end
        end
        table.insert(chunks, s:sub(1, break_at))
        s = s:sub(break_at + 1)
      end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, chunks)

    -- Dim everything
    for i = 0, #chunks - 1 do
      vim.api.nvim_buf_add_highlight(buf, ns, "SoftwrapHint", i, 0, -1)
    end

    local is_table = line:match("^%s*|") and #chunks > 1

    -- Prepend column heading as inline virtual text (dark red) for table rows
    if is_table then
      local bufnr = vim.api.nvim_get_current_buf()
      local lnum  = vim.api.nvim_win_get_cursor(0)[1] - 1
      local headers = find_table_headers(bufnr, lnum)
      for i, hdr in ipairs(headers) do
        if i <= #chunks then
          vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
            virt_text     = { { hdr .. "  ", "SoftwrapHeader" } },
            virt_text_pos = "inline",
          })
        end
      end
    end

    -- Map a raw column offset to (chunk_index, offset_within_chunk).
    -- For table rows, chunks don't align to win_w boundaries, so we track
    -- cumulative character positions by scanning the original line.
    local function col_to_chunk(col)
      if not is_table then
        return math.floor(col / win_w), col % win_w
      end
      local pos = 0
      for ci, chunk in ipairs(chunks) do
        local raw_cell = chunk:sub(3)  -- strip "| "
        local cell_start = line:find(raw_cell, pos + 1, true)
        if cell_start then
          local cell_end = cell_start + #raw_cell - 1
          if col >= cell_start - 1 and col <= cell_end then
            return ci - 1, col - (cell_start - 1)
          end
          pos = cell_end
        end
      end
      return #chunks - 1, 0
    end

    -- Mark cursor column
    local cur_col = vim.api.nvim_win_get_cursor(0)[2]
    local cur_chunk, cur_off = col_to_chunk(cur_col)
    if cur_chunk < #chunks then
      vim.api.nvim_buf_add_highlight(buf, ns, "SoftwrapCursor", cur_chunk, cur_off, cur_off + 1)
    end

    -- Reflect visual selection (current line only)
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" then
      local v_col = vim.fn.col("v") - 1  -- 0-indexed
      local sel_s = math.min(v_col, cur_col)
      local sel_e = math.max(v_col, cur_col)
      for col = sel_s, sel_e do
        local fl, fc = col_to_chunk(col)
        if fl < #chunks then
          vim.api.nvim_buf_add_highlight(buf, ns, "SoftwrapSel", fl, fc, fc + 1)
        end
      end
    end

    -- Position below current screen line, no border
    local screen_row = vim.fn.winline()  -- 1-based → 0-based row = one line below cursor
    local avail = vim.api.nvim_win_get_height(0) - screen_row
    local height = math.min(#chunks, math.max(avail, 1))

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
