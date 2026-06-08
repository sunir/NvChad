require "nvchad.mappings"

local map = vim.keymap.set

-- Basic mappings
map("n", ";", ":", { desc = "CMD enter command mode", nowait = true })
map("i", "jk", "<ESC>")

-- Format with conform
map("n", "<leader>fm", function()
  require("conform").format()
end, { desc = "Format file" })

-- Code actions
map("n", "<leader>C", function()
  vim.lsp.buf.code_action()
end, { desc = "Code actions" })

-- Toggle inlay hints (type hints inline)
map("n", "<leader>ih", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle inlay hints" })

-- Select all
map("n", "<C-a>", "ggVG", { desc = "Select all text" })

-- TODO.md management
function _G.open_todo()
  local todo_path = "TODO.md"
  local f = io.open(todo_path, "r")
  if f ~= nil then
    io.close(f)
    local width = math.min(60, math.floor(vim.o.columns * 2.33))
    vim.cmd("vsplit " .. todo_path)
    vim.cmd("vertical resize " .. width)
  else
    print "TODO.md not found in the current directory."
  end
end
map("n", "<leader>T", "<cmd>lua open_todo()<CR>", { desc = "Open TODO.md" })

-- Buffer navigation (override NvChad defaults)
vim.keymap.del("n", "<tab>")
vim.keymap.del("n", "<S-tab>")

-- Tabufline functions (v2.5 API uses next/prev instead of tabuflineNext/Prev)
local tabufline = require "nvchad.tabufline"
function _G.custom_tabufline_next()
  tabufline.next()
end
function _G.custom_tabufline_prev()
  tabufline.prev()
end
function _G.custom_tabufline_move_next()
  tabufline.move_buf(1)
end
function _G.custom_tabufline_move_prev()
  tabufline.move_buf(-1)
end
function _G.custom_tabufline_close_all()
  tabufline.closeAllBufs()
end

map("n", "<C-l>", "<cmd>lua custom_tabufline_next()<CR>", { desc = "Next buffer" })
map("n", "<C-h>", "<cmd>lua custom_tabufline_prev()<CR>", { desc = "Previous buffer" })
map("n", "<C-j>", "<cmd>lua custom_tabufline_move_next()<CR>", { desc = "Move buffer right" })
map("n", "<C-k>", "<cmd>lua custom_tabufline_move_prev()<CR>", { desc = "Move buffer left" })
map("n", "<leader>X", "<cmd>lua custom_tabufline_close_all()<CR>", { desc = "Close all buffers" })

-- Find file in tree
map("n", "<leader>e", "<cmd>NvimTreeFindFile<CR>", { desc = "Find file in tree" })

-- ThePrimeagen mappings
map("n", "J", "mzJ`z", { desc = "Join lines keeping cursor position" })
map("n", "<C-d>", "<C-d>zz", { desc = "Page down and center" })
map("n", "<C-u>", "<C-u>zz", { desc = "Page up and center" })
map("n", "n", "nzzzv", { desc = "Next search result centered" })
map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

-- Delete without yanking
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

-- Zork chat sidebar
map("n", "<leader>z", function() require("zork").toggle() end, { desc = "Zork: toggle chat sidebar" })

-- Paste over visual selection without yanking
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking deleted text" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Better indenting
map("v", ">", ">gv", { desc = "Indent and reselect" })

-- Clipboard operations
map("v", "<C-c>", '"+yi', { desc = "Copy to system clipboard" })
map("v", "<C-x>", '"+c', { desc = "Cut to system clipboard" })
map("v", "<C-v>", 'c<ESC>"+p', { desc = "Paste from system clipboard" })
map("i", "<C-v>", '<ESC>"+pa', { desc = "Paste from system clipboard" })

-- Shift arrows to select
map("n", "<S-Down>", "vj", { desc = "Select down" })
map("n", "<S-Up>", "vk", { desc = "Select up" })
map("n", "<S-Right>", "vl", { desc = "Select right" })
map("n", "<S-Left>", "vh", { desc = "Select left" })
map("v", "<S-Down>", "j", { desc = "Extend selection down" })
map("v", "<S-Up>", "k", { desc = "Extend selection up" })
map("v", "<S-Right>", "l", { desc = "Extend selection right" })
map("v", "<S-Left>", "h", { desc = "Extend selection left" })
map("i", "<S-Down>", "<ESC>lvj", { desc = "Start selection down" })
map("i", "<S-Up>", "<ESC>vk", { desc = "Start selection up" })
map("i", "<S-Right>", "<ESC>vl", { desc = "Start selection right" })
map("i", "<S-Left>", "<ESC>vh", { desc = "Start selection left" })
