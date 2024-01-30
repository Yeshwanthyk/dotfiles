local mark = require("harpoon.mark")
local ui = require("harpoon.ui")

vim.keymap.set("n", "<leader>jj", ui.toggle_quick_menu)
vim.keymap.set("n", "<leader>ja", mark.add_file)
