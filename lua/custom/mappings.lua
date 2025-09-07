---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    -- Format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },
    
    ["<leader>C"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "Code actions",
    },

    -- Select all
    ["<C-a>"] = { "ggVG", "Select all text" },

    -- TODO.md management
    ["<leader>T"] = {
      function()
        _G.open_todo()
      end,
      "Open TODO.md in vertical split",
    },

    -- Buffer navigation
    ["<C-h>"] = {
      function()
        _G.custom_tabufline_prev()
      end,
      "Go to previous buffer",
    },
    ["<C-l>"] = {
      function()
        _G.custom_tabufline_next()
      end,
      "Go to next buffer",
    },
    ["<C-j>"] = {
      function()
        _G.custom_tabufline_move_next()
      end,
      "Move buffer to next position",
    },
    ["<C-k>"] = {
      function()
        _G.custom_tabufline_move_prev()
      end,
      "Move buffer to previous position",
    },

    -- Close all buffers
    ["<leader>X"] = {
      function()
        _G.custom_tabufline_close_all()
      end,
      "Close all buffers",
    },

    -- Find file in tree
    ["<leader>e"] = { "<cmd>NvimTreeFindFile<CR>", "Find file in tree" },

    -- ThePrimeagen mappings
    ["J"] = { "mzJ`z", "Join lines keeping cursor position" },
    ["<C-d>"] = { "<C-d>zz", "Page down and center" },
    ["<C-u>"] = { "<C-u>zz", "Page up and center" },
    ["n"] = { "nzzzv", "Next search result centered" },
    ["N"] = { "Nzzzv", "Previous search result centered" },

    -- Delete without yanking
    ["<leader>d"] = { [["_d]], "Delete without yanking" },

    -- Search and replace word under cursor
    ["<leader>s"] = { [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], "Search & replace word under cursor" },


    -- Shift arrows to select
    ["<S-Down>"] = { "vj", "Select down" },
    ["<S-Up>"] = { "vk", "Select up" },
    ["<S-Right>"] = { "vl", "Select right" },
    ["<S-Left>"] = { "vh", "Select left" },
  },

  v = {
    [">"] = { ">gv", "indent"},

    -- Clipboard operations
    ["<C-c>"] = { '"+yi', "Copy to system clipboard" },
    ["<C-x>"] = { '"+c', "Cut to system clipboard" },
    ["<C-v>"] = { 'c<ESC>"+p', "Paste from system clipboard" },

    -- ThePrimeagen visual mode mappings
    ["J"] = { ":m '>+1<CR>gv=gv", "Move selection down" },
    ["K"] = { ":m '<-2<CR>gv=gv", "Move selection up" },

    -- Delete without yanking
    ["<leader>d"] = { [["_d]], "Delete without yanking" },

    -- Shift arrows to extend selection
    ["<S-Down>"] = { "j", "Extend selection down" },
    ["<S-Up>"] = { "k", "Extend selection up" },
    ["<S-Right>"] = { "l", "Extend selection right" },
    ["<S-Left>"] = { "h", "Extend selection left" },
  },

  x = {
    -- Paste over visual selection without yanking
    ["<leader>p"] = { [["_dP]], "Paste without yanking deleted text" },
  },

  i = {
    -- Paste from system clipboard in insert mode
    ["<C-v>"] = { "<ESC>+pa", "Paste from system clipboard" },

    -- Shift arrows to start selection from insert mode
    ["<S-Down>"] = { "<ESC>lvj", "Start selection down" },
    ["<S-Up>"] = { "<ESC>vk", "Start selection up" },
    ["<S-Right>"] = { "<ESC>vl", "Start selection right" },
    ["<S-Left>"] = { "<ESC>vh", "Start selection left" },
  },
}

-- LSP mappings (these will be added by NvChad's LSP config but good to have as reference)
M.lspconfig = {
  n = {
    ["<Space>K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "LSP hover information",
    },
    ["]d"] = {
      function()
        vim.diagnostic.goto_next()
      end,
      "Go to next diagnostic",
    },
    ["[d"] = {
      function()
        vim.diagnostic.goto_prev()
      end,
      "Go to previous diagnostic",
    },
  },
}

-- Gitsigns navigation (kept here for cheatsheet visibility)
M.gitsigns = {
  n = {
    ["]c"] = {
      function()
        if vim.wo.diff then
          vim.cmd.normal({']c', bang = true})
        else
          require('gitsigns').nav_hunk('next')
        end
      end,
      "Next git hunk",
    },
    ["[c"] = {
      function()
        if vim.wo.diff then
          vim.cmd.normal({'[c', bang = true})
        else
          require('gitsigns').nav_hunk('prev')
        end
      end,
      "Previous git hunk",
    },
  },
}

return M