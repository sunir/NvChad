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

-- " Select all
vim.keymap.set('n', '<C-a>', 'ggVG')

vim.cmd('set nohls')

-- Function to open TODO.md in a vertical split
function _G.open_todo()
    -- Path to the TODO.md file
    local todo_path = "TODO.md"
  
    -- Check if TODO.md exists in the current directory
    local f = io.open(todo_path, "r")
    if f ~= nil then
        io.close(f)
        -- Calculate the width for the new split
        local width = math.min(60, math.floor(vim.o.columns * 2.33))
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
  vim.keymap.del('n', '<C-j>')
  vim.keymap.del('n', '<C-k>')
  vim.keymap.del('n', '<C-h>')
  vim.keymap.del('n', '<C-l>')

  function _G.custom_tabufline_next()
    require("nvchad.tabufline").tabuflineNext()
  end
  vim.api.nvim_set_keymap('n', '<C-l>', '<cmd>lua custom_tabufline_next()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_prev()
    require("nvchad.tabufline").tabuflinePrev()
  end
  vim.api.nvim_set_keymap('n', '<C-h>', '<cmd>lua custom_tabufline_prev()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_move_next()
    require("nvchad.tabufline").move_buf(-1)
  end
  vim.api.nvim_set_keymap('n', '<C-j>', '<cmd>lua custom_tabufline_move_next()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_move_prev()
    require("nvchad.tabufline").move_buf(1)
  end
  vim.api.nvim_set_keymap('n', '<C-k>', '<cmd>lua custom_tabufline_move_prev()<CR>', {noremap = true, silent = true})

  function _G.custom_tabufline_close_all()
    require("nvchad.tabufline").closeAllBufs()
  end
  vim.api.nvim_set_keymap('n', '<leader>X', '<cmd>lua custom_tabufline_close_all()<CR>', {noremap = true, silent = true})

  vim.keymap.del('n', '<leader>e')
  vim.api.nvim_set_keymap('n', '<leader>e', '<cmd> NvimTreeFindFile <CR>', {noremap = true, silent = true})

  -- ThePrimeagen mappings
  -- Move selected line / block of text in visual mode
  vim.keymap.set("v", "J", ":m '>+3<CR>gv=gv")
  vim.keymap.set("v", "K", ":m '<0<CR>gv=gv")
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

  -- Set tab width to 2 spaces
  vim.opt.tabstop = 2        -- Number of spaces that a <Tab> in the file counts for
  vim.opt.shiftwidth = 2     -- Size of an indent
  vim.opt.softtabstop = 2    -- Number of spaces a tab counts for while performing editing operations
  vim.opt.expandtab = true   -- Use spaces instead of tabs
  vim.opt.smartindent = false -- Make indenting smarter again
  vim.g.python_recommended_style = 0
  
  -- Code folding with Treesitter
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.opt.foldenable = false  -- Start with folds open
  vim.opt.foldlevel = 99      -- Don't fold by default
end)

require('nvim-tree').setup({ actions = { open_file = { window_picker = { enable = false } } } })

-- Change the background color when entering insert mode
vim.cmd [[ hi Normal guibg=#0a0e15]]
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
	callback = function()
    vim.cmd [[ hi Normal guibg=#2b1a2e]]
	end
})
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
	callback = function()
    vim.cmd [[ hi Normal guibg=#0a0e15]]
	end
})
vim.opt.guicursor = {
  'n-v-c-sm:block-Cursor',
  'i-ci:ver25-Cursor/lCursor-blinkwait300-blinkon200-blinkoff200',
  'r-cr:hor20-Cursor/lCursor-blinkwait300-blinkon200-blinkoff200',
  'o:hor50-Cursor/lCursor-blinkwait0-blinkon10-blinkoff10'
}

require('gitsigns').setup{
  on_attach = function(bufnr)
    local gitsigns = require('gitsigns')

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal({']c', bang = true})
      else
        gitsigns.nav_hunk('next')
      end
    end)

    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal({'[c', bang = true})
      else
        gitsigns.nav_hunk('prev')
      end
    end)

    -- Actions
    -- map('n', '<leader>hs', gitsigns.stage_hunk)
    -- map('n', '<leader>hr', gitsigns.reset_hunk)
    -- map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    -- map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end)
    -- map('n', '<leader>hS', gitsigns.stage_buffer)
    -- map('n', '<leader>hu', gitsigns.undo_stage_hunk)
    -- map('n', '<leader>hR', gitsigns.reset_buffer)
    -- map('n', '<leader>hp', gitsigns.preview_hunk)
    -- map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end)
    -- map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
    -- map('n', '<leader>hd', gitsigns.diffthis)
    -- map('n', '<leader>hD', function() gitsigns.diffthis('~') end)
    -- map('n', '<leader>td', gitsigns.toggle_deleted)
    --
    -- -- Text object
    -- map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  end
}

-- Initialize Story Explorer plugin
require('custom.story-explorer').setup()
