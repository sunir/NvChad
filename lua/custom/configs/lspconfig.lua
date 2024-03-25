local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- if you just want default config for the servers then put them in a table
local servers = { "html", "cssls", "tsserver", "clangd" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    capabilities = capabilities,
  }
end

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>K', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {desc="next error (LSP)"})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {desc="previous error (LSP)"})
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- 
-- lspconfig.pyright.setup { blabla}
