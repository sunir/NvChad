require "nvchad.options"

local o = vim.o
local opt = vim.opt
local g = vim.g

-- Disable search highlight
vim.cmd "set nohls"

-- Global default: nowrap (softwrap float handles long lines in markdown)
opt.wrap = false

-- Tab settings (2 spaces)
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = false
g.python_recommended_style = 0

-- Code folding with Treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false
opt.foldlevel = 99

-- Cursor settings (blink in insert mode)
opt.guicursor = {
  "n-v-c-sm:block-Cursor",
  "i-ci:ver25-Cursor/lCursor-blinkwait300-blinkon200-blinkoff200",
  "r-cr:hor20-Cursor/lCursor-blinkwait300-blinkon200-blinkoff200",
  "o:hor50-Cursor/lCursor-blinkwait0-blinkon10-blinkoff10",
}

-- Python 3 provider
g.loaded_python3_provider = nil
g.python3_host_prog = "~/.venvs/nvim/bin/python3"

-- Inlay hints (Neovim 0.10+) - show type hints inline
-- Toggle with <leader>ih or :lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.supports_method("textDocument/inlayHint") then
      -- Disabled by default, toggle with <leader>ih
      vim.lsp.inlay_hint.enable(false, { bufnr = args.buf })
    end
  end,
})
