-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move window
vim.keymap.set("n", "<Space>", "<C-w>w")

-- Faster way to save a file
vim.keymap.set("n", "<leader><leader>", ":w<CR>", { noremap = true, silent = true })
