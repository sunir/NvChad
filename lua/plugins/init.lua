return {
  -- Blink.cmp - faster completion (optional, testing)
  { import = "nvchad.blink.lazyspec" },

  -- Zark: writes cursor position to editor-state file on InsertLeave
  -- so Claude Code hooks can inject editor context into prompts.
  {
    dir = "/Users/sunir/source/colony/zork/neovim",
    name = "zark",
    lazy = false,
    config = function()
      -- lazy adds {dir}/lua/ to path; zark.lua lives in {dir}/ directly
      local zark_dir = "/Users/sunir/source/colony/zork/neovim"
      package.path = zark_dir .. "/?.lua;" .. package.path
      require("zark").setup()
    end,
  },

  -- Dungeon: Zork-style code navigator. <leader>z* keymaps defined in mappings.lua.
  -- dungeon.lua is the canonical version (standalone, no morph dep).
  {
    dir = vim.fn.stdpath("config") .. "/lua/custom",
    name = "dungeon",
    lazy = false,
    config = function()
      vim.g.dungeon_no_keymaps = true
      local custom_dir = vim.fn.stdpath("config") .. "/lua/custom"
      package.path = custom_dir .. "/?.lua;" .. package.path
      require("dungeon").setup()
    end,
  },

  -- Override nvim-lspconfig to use our custom config
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Override treesitter with custom parsers
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "c",
        "markdown",
        "markdown_inline",
        "python",
        "json",
        "yaml",
        "bash",
        "jsdoc",
        "comment",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
            return true
          end
        end,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = "<nop>",
          node_decremental = "<bs>",
        },
      },
    },
  },

  -- Treesitter text objects - vaf (select function), vic (select class), etc.
  -- Uses main branch API (nvim-treesitter 1.0+ dropped the configs module)
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = "nvim-treesitter/nvim-treesitter",
    event = "VeryLazy",
    config = function()
      local ts_textobjects = require("nvim-treesitter-textobjects")
      local select = require("nvim-treesitter-textobjects.select")
      local move = require("nvim-treesitter-textobjects.move")
      local swap = require("nvim-treesitter-textobjects.swap")

      -- Setup with new API
      ts_textobjects.setup {
        select = { lookahead = true },
        move = { set_jumps = true },
      }

      -- Select keymaps (visual and operator-pending modes)
      local select_maps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
        ["aa"] = "@parameter.outer",
        ["ia"] = "@parameter.inner",
        ["ai"] = "@conditional.outer",
        ["ii"] = "@conditional.inner",
        ["al"] = "@loop.outer",
        ["il"] = "@loop.inner",
      }
      for key, query in pairs(select_maps) do
        vim.keymap.set({ "x", "o" }, key, function()
          select.select_textobject(query, "textobjects")
        end, { desc = "Select " .. query })
      end

      -- Move keymaps (next/previous)
      local move_maps = {
        ["]f"] = { query = "@function.outer", func = move.goto_next_start },
        ["]c"] = { query = "@class.outer", func = move.goto_next_start },
        ["]a"] = { query = "@parameter.inner", func = move.goto_next_start },
        ["]F"] = { query = "@function.outer", func = move.goto_next_end },
        ["]C"] = { query = "@class.outer", func = move.goto_next_end },
        ["[f"] = { query = "@function.outer", func = move.goto_previous_start },
        ["[c"] = { query = "@class.outer", func = move.goto_previous_start },
        ["[a"] = { query = "@parameter.inner", func = move.goto_previous_start },
        ["[F"] = { query = "@function.outer", func = move.goto_previous_end },
        ["[C"] = { query = "@class.outer", func = move.goto_previous_end },
      }
      for key, mapping in pairs(move_maps) do
        vim.keymap.set({ "n", "x", "o" }, key, function()
          mapping.func(mapping.query, "textobjects")
        end, { desc = "Move to " .. mapping.query })
      end

      -- Swap keymaps
      vim.keymap.set("n", "<leader>a", function()
        swap.swap_next("@parameter.inner", "textobjects")
      end, { desc = "Swap with next argument" })
      vim.keymap.set("n", "<leader>A", function()
        swap.swap_previous("@parameter.inner", "textobjects")
      end, { desc = "Swap with previous argument" })
    end,
  },

  -- Override mason with ensure_installed
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "stylua",
        "css-lsp",
        "html-lsp",
        "typescript-language-server",
        "deno",
        "prettier",
        "clangd",
        "clang-format",
        "bash-language-server",
        "shellcheck",
        "shfmt",
        "pyright",
        "ruff",
        "json-lsp",
        "yaml-language-server",
        "marksman",
      },
    },
  },

  -- Override nvim-tree with git support
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      git = { enable = true },
      renderer = {
        highlight_git = true,
        icons = { show = { git = true } },
      },
      actions = {
        open_file = { window_picker = { enable = false } },
      },
    },
  },

  -- Better diagnostics UI
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Toggle Trouble" },
      { "<leader>xd", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
    },
    opts = {},
  },

  -- Multi-cursor editing
  {
    "mg979/vim-visual-multi",
    lazy = false,
  },

  -- Superior search/replace
  {
    "nvim-pack/nvim-spectre",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      {
        "<leader>S",
        function()
          require("spectre").open()
        end,
        desc = "Replace in files (Spectre)",
      },
    },
    opts = {},
  },

  -- Better escape from insert mode
  {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    opts = {},
  },

  -- Conform formatter with custom config
  {
    "stevearc/conform.nvim",
    opts = {
      lsp_fallback = true,
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        sh = { "shfmt" },
      },
    },
  },

  -- GitHub Copilot
  {
    "github/copilot.vim",
    lazy = false,
    config = function()
      vim.g.copilot_no_tab_map = true
      -- Enable for all filetypes
      vim.g.copilot_filetypes = { ["*"] = true }
      vim.keymap.set("i", "<C-i>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
      })
    end,
  },

  -- Auto session management
  {
    "rmagatti/auto-session",
    lazy = false,
    opts = {
      log_level = "error",
      auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
    },
  },

  -- Override gitsigns with custom signs
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      on_attach = function(bufnr)
        local gitsigns = require "gitsigns"
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        -- Navigation
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal { "]c", bang = true }
          else
            gitsigns.nav_hunk "next"
          end
        end, { desc = "Next git hunk" })
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal { "[c", bang = true }
          else
            gitsigns.nav_hunk "prev"
          end
        end, { desc = "Previous git hunk" })
      end,
    },
  },

  -- Flash.nvim - jump to any text with 2 chars
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function()
          require("flash").jump()
        end,
        desc = "Flash jump",
      },
      {
        "S",
        mode = { "n", "x", "o" },
        function()
          require("flash").treesitter()
        end,
        desc = "Flash Treesitter",
      },
      {
        "r",
        mode = "o",
        function()
          require("flash").remote()
        end,
        desc = "Remote Flash",
      },
      {
        "R",
        mode = { "o", "x" },
        function()
          require("flash").treesitter_search()
        end,
        desc = "Treesitter Search",
      },
      {
        "<c-s>",
        mode = { "c" },
        function()
          require("flash").toggle()
        end,
        desc = "Toggle Flash Search",
      },
    },
  },

  -- Precognition: shows motion hints (w, b, e, ^, $, {, }) as virtual text
  -- Toggle with :Precognition toggle or <leader>zp
  {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    opts = {
      startVisible = false,  -- off by default, toggle with :Precognition toggle
    },
  },

}
