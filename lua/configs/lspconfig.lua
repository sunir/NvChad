-- Custom LSP server configurations
-- First load nvchad defaults (sets up capabilities, on_init, on_attach, lua_ls)
require("nvchad.configs.lspconfig").defaults()

-- Enable additional servers (they auto-start when relevant filetype is opened)
-- vim.lsp.enable uses filetype detection automatically
local servers = { "html", "cssls", "ts_ls", "clangd", "pyright", "ruff", "jsonls", "yamlls", "marksman", "bashls" }
vim.lsp.enable(servers)

-- Additional diagnostic keymaps (nvchad handles gd, gD, etc.)
vim.keymap.set("n", "<space>K", vim.diagnostic.open_float, { desc = "LSP diagnostic float" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<space>q", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })
