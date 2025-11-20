local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities
local on_init = require("plugins.configs.lspconfig").on_init

-- Use new vim.lsp.config API (nvim 0.11+)
local servers = {
  html = { cmd = { 'vscode-html-language-server', '--stdio' } },
  cssls = { cmd = { 'vscode-css-language-server', '--stdio' } },
  ts_ls = { cmd = { 'typescript-language-server', '--stdio' } },
  clangd = { cmd = { 'clangd' } },
  pyright = { cmd = { 'pyright-langserver', '--stdio' } },
  jsonls = { cmd = { 'vscode-json-language-server', '--stdio' } },
  yamlls = { cmd = { 'yaml-language-server', '--stdio' } },
  marksman = { cmd = { 'marksman', 'server' } },
  bashls = { cmd = { 'bash-language-server', 'start' } },
}

for lsp_name, lsp_config in pairs(servers) do
  vim.lsp.config(lsp_name, vim.tbl_extend('force', {
    on_init = on_init,
    on_attach = on_attach,
    capabilities = capabilities,
  }, lsp_config))
end

-- Auto-enable LSP servers based on filetype
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'html', 'css', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact',
              'c', 'cpp', 'python', 'json', 'yaml', 'markdown', 'sh', 'bash' },
  callback = function(args)
    local ft_to_lsp = {
      html = 'html',
      css = 'cssls',
      javascript = 'ts_ls',
      typescript = 'ts_ls',
      javascriptreact = 'ts_ls',
      typescriptreact = 'ts_ls',
      c = 'clangd',
      cpp = 'clangd',
      python = 'pyright',
      json = 'jsonls',
      yaml = 'yamlls',
      markdown = 'marksman',
      sh = 'bashls',
      bash = 'bashls',
    }
    local lsp = ft_to_lsp[vim.bo[args.buf].filetype]
    if lsp then
      vim.lsp.enable(lsp)
    end
  end,
})

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>K', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {desc="next error (LSP)"})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {desc="previous error (LSP)"})
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- 
-- lspconfig.pyright.setup { blabla}
