-- Brook Story Explorer Plugin
-- Iteration 3: Real code structure tree

local M = {}

-- Global state for the sidebar
local sidebar_bufnr = nil
local sidebar_winid = nil
local main_bufnr = nil  -- Store the main buffer we're analyzing
local current_state = 'structure'
local current_line = 1

-- Create or toggle the story explorer sidebar
function M.toggle_sidebar()
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    -- Close existing sidebar
    vim.api.nvim_win_close(sidebar_winid, true)
    sidebar_winid = nil
    sidebar_bufnr = nil
    main_bufnr = nil
  else
    -- Store current buffer before creating sidebar
    main_bufnr = vim.api.nvim_get_current_buf()
    -- Create new sidebar
    M.create_sidebar()
  end
end

-- Create the sidebar window and buffer
function M.create_sidebar()
  -- Create a new buffer
  sidebar_bufnr = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'filetype', 'story-explorer')
  
  -- Get current window width
  local width = vim.api.nvim_get_option('columns')
  local sidebar_width = math.floor(width * 0.25)  -- 25% of screen width
  
  -- Create the window
  sidebar_winid = vim.api.nvim_open_win(sidebar_bufnr, true, {
    relative = 'editor',
    width = sidebar_width,
    height = vim.api.nvim_get_option('lines') - 2, -- Full height minus statusline
    row = 0,
    col = width - sidebar_width,  -- Right side of screen
    style = 'minimal',
    border = 'single',
    title = ' Story Explorer ',
    title_pos = 'center'
  })
  
  -- Set window options
  vim.api.nvim_win_set_option(sidebar_winid, 'wrap', false)
  vim.api.nvim_win_set_option(sidebar_winid, 'cursorline', true)
  
  -- Set initial content (code structure)
  M.show_code_structure()
  
  -- Set up buffer-specific keymaps
  local opts = { noremap = true, silent = true, buffer = sidebar_bufnr }
  vim.keymap.set('n', 'q', '<cmd>lua require("custom.story-explorer").toggle_sidebar()<CR>', opts)
  vim.keymap.set('n', '<Esc>', '<cmd>lua require("custom.story-explorer").toggle_sidebar()<CR>', opts)
  vim.keymap.set('n', 'j', '<cmd>lua require("custom.story-explorer").move_down()<CR>', opts)
  vim.keymap.set('n', 'k', '<cmd>lua require("custom.story-explorer").move_up()<CR>', opts)
  vim.keymap.set('n', '<CR>', '<cmd>lua require("custom.story-explorer").select_item()<CR>', opts)
  vim.keymap.set('n', '<Down>', '<cmd>lua require("custom.story-explorer").move_down()<CR>', opts)
  vim.keymap.set('n', '<Up>', '<cmd>lua require("custom.story-explorer").move_up()<CR>', opts)
end

-- Parse JavaScript/TypeScript file structure
function M.parse_js_file(content, filename)
  local structure = {
    module = filename,
    classes = {},
    functions = {}
  }
  
  local lines = vim.split(content, '\n')
  local current_class = nil
  
  for i, line in ipairs(lines) do
    -- Match class declarations
    local class_match = line:match('^%s*export%s+class%s+(%w+)') or line:match('^%s*class%s+(%w+)')
    if class_match then
      current_class = {
        name = class_match,
        line = i,
        methods = {}
      }
      table.insert(structure.classes, current_class)
    end
    
    -- Match function/method declarations
    local func_match = line:match('^%s*async%s+function%s+(%w+)%s*%(') or
                      line:match('^%s*function%s+(%w+)%s*%(') or
                      line:match('^%s*(%w+)%s*%(.*%)%s*{') or
                      line:match('^%s*(%w+)%s*=%s*async%s+function') or
                      line:match('^%s*(%w+)%s*=%s*function') or
                      line:match('^%s*(%w+)%s*=%s*%(.*%)%s*=>')
    
    if func_match and func_match ~= 'if' and func_match ~= 'for' and func_match ~= 'while' and func_match ~= 'switch' then
      local func_info = {
        name = func_match,
        line = i
      }
      
      if current_class then
        table.insert(current_class.methods, func_info)
      else
        table.insert(structure.functions, func_info)
      end
    end
  end
  
  return structure
end

-- Show code structure of current file
function M.show_code_structure()
  current_state = 'structure'
  
  -- Use the stored main buffer
  if not main_bufnr or not vim.api.nvim_buf_is_valid(main_bufnr) then
    main_bufnr = vim.api.nvim_get_current_buf()
  end
  
  local filename = vim.api.nvim_buf_get_name(main_bufnr)
  local content = table.concat(vim.api.nvim_buf_get_lines(main_bufnr, 0, -1, false), '\n')
  
  -- Parse based on file extension
  local display_lines = {}
  
  if filename == '' then
    table.insert(display_lines, "No file open")
  else
    local basename = vim.fn.fnamemodify(filename, ':t')
    local extension = vim.fn.fnamemodify(filename, ':e')
    
    if extension == 'js' or extension == 'ts' or extension == 'jsx' or extension == 'tsx' then
      local structure = M.parse_js_file(content, basename)
      
      -- Display module
      table.insert(display_lines, "📁 " .. structure.module)
      
      -- Display classes
      for _, class in ipairs(structure.classes) do
        table.insert(display_lines, "  📦 " .. class.name .. " (L" .. class.line .. ")")
        for _, method in ipairs(class.methods) do
          table.insert(display_lines, "    ⚙️  " .. method.name .. " (L" .. method.line .. ")")
        end
      end
      
      -- Display standalone functions
      if #structure.functions > 0 then
        table.insert(display_lines, "  📋 Functions:")
        for _, func in ipairs(structure.functions) do
          table.insert(display_lines, "    ⚙️  " .. func.name .. " (L" .. func.line .. ")")
        end
      end
      
    else
      table.insert(display_lines, "📁 " .. basename)
      table.insert(display_lines, "  (Unsupported file type)")
    end
  end
  
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, display_lines)
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', false)
  
  -- Position cursor on first line
  if vim.api.nvim_win_is_valid(sidebar_winid) then
    vim.api.nvim_win_set_cursor(sidebar_winid, {1, 0})
  end
end

-- Move cursor down
function M.move_down()
  if current_state == 'structure' then
    local line_count = vim.api.nvim_buf_line_count(sidebar_bufnr)
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local new_line = math.min(current_pos[1] + 1, line_count)
    vim.api.nvim_win_set_cursor(sidebar_winid, {new_line, 0})
  end
end

-- Move cursor up  
function M.move_up()
  if current_state == 'structure' then
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local new_line = math.max(current_pos[1] - 1, 1)
    vim.api.nvim_win_set_cursor(sidebar_winid, {new_line, 0})
  end
end

-- Jump to line in main buffer (if line number found)
function M.select_item()
  if current_state == 'structure' then
    local current_pos = vim.api.nvim_win_get_cursor(sidebar_winid)
    local line = vim.api.nvim_buf_get_lines(sidebar_bufnr, current_pos[1] - 1, current_pos[1], false)[1]
    
    -- Extract line number from "(L123)" format
    local line_num = line:match('%(L(%d+)%)')
    if line_num and main_bufnr then
      -- Find window containing the main buffer
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == main_bufnr then
          vim.api.nvim_set_current_win(win)
          vim.api.nvim_win_set_cursor(win, {tonumber(line_num), 0})
          vim.cmd('normal! zz')  -- Center the line
          break
        end
      end
    end
  end
end

-- Setup function to be called from init
function M.setup()
  -- Create the main keybinding
  vim.keymap.set('n', '<leader>\\', '<cmd>lua require("custom.story-explorer").toggle_sidebar()<CR>', 
    { noremap = true, silent = true, desc = 'Toggle Story Explorer' })
end

return M