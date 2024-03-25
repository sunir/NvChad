-- local autocmd = vim.api.nvim_create_autocmd

-- Auto resize panes when resizing nvim window
-- autocmd("VimResized", {
--   pattern = "*",
--   command = "tabdo wincmd =",
-- })
--

-- " Ctrl-C, Ctrl-V option for copy/paste
vim.keymap.set('v', '<C-c>', '"+yi')
vim.keymap.set('v', '<C-x>', '"+c')
vim.keymap.set('v', '<C-v>', 'c<ESC>"+p')
vim.keymap.set('i', '<C-v>', '<ESC>"+pa')

-- " Shift arrows to select
vim.keymap.set('i', '<S-Down>', '<ESC>lvj')
vim.keymap.set('v', '<S-Down>', 'j')
vim.keymap.set('n', '<S-Down>', 'vj')

vim.keymap.set('i', '<S-Up>', '<ESC>vk')
vim.keymap.set('v', '<S-Up>', 'k')
vim.keymap.set('n', '<S-Up>', 'vk')

vim.keymap.set('i', '<S-Right>', '<ESC>vl')
vim.keymap.set('v', '<S-Right>', 'l')
vim.keymap.set('n', '<S-Right>', 'vl')

vim.keymap.set('i', '<S-Left>', '<ESC>vh')
vim.keymap.set('v', '<S-Left>', 'h')
vim.keymap.set('n', '<S-Left>', 'vh')

vim.cmd('set nohls')
vim.g.python_recommended_style = 0

-- Function to open TODO.md in a vertical split
function _G.open_todo()
    -- Path to the TODO.md file
    local todo_path = "TODO.md"
  
    -- Check if TODO.md exists in the current directory
    local f = io.open(todo_path, "r")
    if f ~= nil then
        io.close(f)
        -- Calculate the width for the new split
        local width = math.floor(vim.o.columns * 0.33)
        -- Command to open TODO.md in a vertical split to the right
        vim.cmd("vsplit " .. todo_path)
        -- Set the width of the new split
        vim.cmd("vertical resize " .. width)
    else
        print("TODO.md not found in the current directory.")
    end
end

vim.schedule(function()
  -- Map <leader>T to open TODO.md in a vertical split
  vim.api.nvim_set_keymap('n', '<leader>T', '<cmd>lua open_todo()<CR>', {noremap = true, silent = true})

  vim.keymap.del('n', '<tab>')
  vim.keymap.del('n', '<S-tab>')

  function _G.custom_tabufline_next()
    require("nvchad.tabufline").tabuflineNext()
  end
  vim.api.nvim_set_keymap('n', '<C-A-l>', '<cmd>lua custom_tabufline_next()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_prev()
    require("nvchad.tabufline").tabuflinePrev()
  end
  vim.api.nvim_set_keymap('n', '<C-A-h>', '<cmd>lua custom_tabufline_prev()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_move_next()
    require("nvchad.tabufline").move_buf(1)
  end
  vim.api.nvim_set_keymap('n', '<C-A-j>', '<cmd>lua custom_tabufline_move_next()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_move_prev()
    require("nvchad.tabufline").move_buf(-1)
  end
  vim.api.nvim_set_keymap('n', '<C-A-k>', '<cmd>lua custom_tabufline_move_prev()<CR>', {noremap = true, silent = true})

  vim.keymap.del('n', '<leader>e')
  vim.api.nvim_set_keymap('n', '<leader>e', '<cmd> NvimTreeFindFile <CR>', {noremap = true, silent = true})

  -- ThePrimeagen mappings
  -- Move selected line / block of text in visual mode
  vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
  vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
  -- When joining lines, keep cursor at the start of the joined line
  vim.keymap.set("n", "J", "mzJ`z")
  -- Centre screen when paging, or moving between search results
  vim.keymap.set("n", "<C-d>", "<C-d>zz")
  vim.keymap.set("n", "<C-u>", "<C-u>zz")
  vim.keymap.set("n", "n", "nzzzv")
  vim.keymap.set("n", "N", "Nzzzv")

  -- Paste over visual selection 
  vim.keymap.set("x", "<leader>p", [["_dP]])
  vim.keymap.set({"n", "v"}, "<leader>d", [["_d]])

  -- Search and replace word under cursor
  vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

end)

require('nvim-tree').setup({ actions = { open_file = { window_picker = { enable = false } } } })

