require "nvchad.autocmds"

-- Hex bg/fg colors only work correctly with truecolor support.
-- On SSH sessions without COLORTERM=truecolor, skip them entirely to
-- avoid wrong color mapping (e.g. pinkish background from nearest 256-color).
if vim.o.termguicolors then
  -- Change background color in insert mode
  vim.cmd [[ hi Normal guibg=#0a0e15 ]]

  vim.api.nvim_create_autocmd({ "InsertEnter" }, {
    callback = function()
      vim.cmd [[ hi Normal guibg=#2b1a2e ]]
    end,
  })

  vim.api.nvim_create_autocmd({ "InsertLeave" }, {
    callback = function()
      vim.cmd [[ hi Normal guibg=#0a0e15 ]]
    end,
  })

  -- Comment highlight colors
  vim.api.nvim_set_hl(0, "Comment", { fg = "#AAAAAA" })
  vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })

  -- Copilot suggestion colors
  vim.api.nvim_set_hl(0, "CopilotSuggestion", { fg = "#A05555", italic = true })
  vim.api.nvim_set_hl(0, "CopilotAnnotation", { fg = "#A05555" })
end
