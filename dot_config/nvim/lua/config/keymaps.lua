-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Move window
vim.keymap.set("n", "<Space>", "<C-w>w")

-- https://github.com/dustinblackman/oatmeal.nvim/issues/8#issuecomment-1913923693
vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Oil
vim.keymap.set("n", "<leader>r", "<cmd>lua require('oil').toggle_float()<CR>", { desc = "Oil" })

-- Twilight
vim.keymap.set("n", "<leader>tt", "<cmd>Twilight<CR>", { desc = "Toggle Twilight" })

-- Move selected lines with shift+j or shift+k
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Join line while keeping the cursor in the same position
vim.keymap.set("n", "J", "mzJ`z")

-- Keep cursor centred while scrolling up and down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Next and previous instance of the highlighted letter
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Better paste (prevents new paste buffer)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete to void register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- . repeat or execute macro on all visually selected lines
vim.keymap.set("x", ".", ":norm .<CR>", nosilent)
vim.keymap.set("x", "@", ":norm @q<CR>", nosilent)

-- jump back to original place
vim.keymap.set("n", "<BS>", "<C-o>")

-- jk,kj to go to normal mode
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

-- hitting W or Q will also run :w :q
vim.api.nvim_create_user_command("W", "w", { nargs = 0 })
vim.api.nvim_create_user_command("Q", "q", { nargs = 0 })

vim.keymap.set("n", "zr", "zrzz", { desc = "open fold and then center the cursorline" })
vim.keymap.set("n", "zR", "zRzz", { desc = "open all folds and then center the cursorline" })
vim.keymap.set("n", "zc", "zczz", { desc = "close fold and then center the cursorline" })
vim.keymap.set("n", "zm", "zmzz", { desc = "close fold and then center the cursorline" })
vim.keymap.set("n", "zM", "zMzz", { desc = "close all folds and then center the cursorline" })

vim.keymap.set("n", "<leader>of", "<Cmd>ObsidianQuickSwitch<CR>")
vim.keymap.set("n", "<leader>os", "<Cmd>ObsidianSearch<CR>")
vim.keymap.set("n", "<leader>od", "<Cmd>ObsidianToday<CR>")
vim.keymap.set("n", "<leader>ob", "<Cmd>ObsidianBacklinks<CR>")
vim.keymap.set("n", "<leader>ol", "<Cmd>ObsidianFollowLink<CR>")
