require "core"

require("core.utils").load_mappings()

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

-- bootstrap lazy.nvim!
if not vim.loop.fs_stat(lazypath) then
  require("core.bootstrap").gen_chadrc_template()
  require("core.bootstrap").lazy(lazypath)
end

dofile(vim.g.base46_cache .. "defaults")
vim.opt.rtp:prepend(lazypath)
require "plugins"

local custom_init_path = vim.api.nvim_get_runtime_file("lua/custom/init.lua", false)[1]

if custom_init_path then
  dofile(custom_init_path)
end

-- Set Python 3 host program for Neovim in the shell with the following commands:
-- python3 -m venv ~/.venvs/nvim
-- source ~/.venvs/nvim/bin/activate
-- pip install pynvim
vim.g.python3_host_prog = "~/.venvs/nvim/bin/python3"
vim.g.loaded_python3_provider = nil
