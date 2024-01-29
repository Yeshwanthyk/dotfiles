-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move window
vim.keymap.set("n", "<Space>", "<C-w>w")

-- https://github.com/dustinblackman/oatmeal.nvim/issues/8#issuecomment-1913923693
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })
