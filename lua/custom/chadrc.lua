---@type ChadrcConfig
local M = {}

-- Path to overriding theme and highlights files
local highlights = require "custom.highlights"

M.ui = {
  theme = "ayu_dark",
  theme_toggle = { "ayu_dark", "ayu_dark_light" },

  hl_override = highlights.override,
  hl_add = highlights.add,
}

M.plugins = "custom.plugins"

function M.polish()
  -- Enable Python 3 provider
  vim.g.loaded_python3_provider = nil
  vim.g.python3_host_prog = "~/.venvs/nvim/bin/python3"
end

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

vim.api.nvim_set_hl(0, "Comment", { fg = "#AAAAAA"})
vim.api.nvim_set_hl(0, "@comment", { link = "Comment"})

-- Copilot suggestion colors (dark red)
vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#A05555", italic = true })
vim.api.nvim_set_hl(0, "CopilotAnnotation", { fg = "#A05555" })

return M
