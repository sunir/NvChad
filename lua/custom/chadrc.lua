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

-- check core.mappings for table structure
M.mappings = require "custom.mappings"

vim.api.nvim_set_hl(0, "Comment", { fg = "#888888"})
vim.api.nvim_set_hl(0, "@comment", { link = "Comment"})

return M