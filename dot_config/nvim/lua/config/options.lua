-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.g.mapleader = ","

vim.opt.mousescroll = "ver:2,hor:6"

-- Disabling option that makes '+y does not copy anything
vim.opt_local.clipboard = ""
