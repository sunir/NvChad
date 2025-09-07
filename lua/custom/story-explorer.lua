-- Brook Story Explorer Plugin
-- Iteration 1: Basic sidebar with "Hello, world"

local M = {}

-- Global state for the sidebar
local sidebar_bufnr = nil
local sidebar_winid = nil
local current_state = 'menu'  -- 'menu' or 'content'
local current_line = 1

-- Create or toggle the story explorer sidebar
function M.toggle_sidebar()
  if sidebar_winid and vim.api.nvim_win_is_valid(sidebar_winid) then
    -- Close existing sidebar
    vim.api.nvim_win_close(sidebar_winid, true)
    sidebar_winid = nil
    sidebar_bufnr = nil
  else
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
  
  -- Set initial content (menu state)
  M.show_menu()
  
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

-- Show the menu items
function M.show_menu()
  current_state = 'menu'
  current_line = 1
  
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, {
    "1. Hello?",
    "2. Goodbye?"
  })
  vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', false)
  
  -- Position cursor on first line
  vim.api.nvim_win_set_cursor(sidebar_winid, {1, 0})
end

-- Move cursor down
function M.move_down()
  if current_state == 'menu' then
    current_line = math.min(current_line + 1, 2)  -- 2 menu items
    vim.api.nvim_win_set_cursor(sidebar_winid, {current_line, 0})
  end
end

-- Move cursor up  
function M.move_up()
  if current_state == 'menu' then
    current_line = math.max(current_line - 1, 1)
    vim.api.nvim_win_set_cursor(sidebar_winid, {current_line, 0})
  end
end

-- Select current menu item
function M.select_item()
  if current_state == 'menu' then
    current_state = 'content'
    
    vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', true)
    
    if current_line == 1 then
      -- Hello option selected
      vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, {
        "Hello, world!"
      })
    elseif current_line == 2 then
      -- Goodbye option selected  
      vim.api.nvim_buf_set_lines(sidebar_bufnr, 0, -1, false, {
        "So long and thanks for all the fish"
      })
    end
    
    vim.api.nvim_buf_set_option(sidebar_bufnr, 'modifiable', false)
    vim.api.nvim_win_set_cursor(sidebar_winid, {1, 0})
  end
end

-- Setup function to be called from init
function M.setup()
  -- Create the main keybinding
  vim.keymap.set('n', '<leader>\\', '<cmd>lua require("custom.story-explorer").toggle_sidebar()<CR>', 
    { noremap = true, silent = true, desc = 'Toggle Story Explorer' })
end

return M