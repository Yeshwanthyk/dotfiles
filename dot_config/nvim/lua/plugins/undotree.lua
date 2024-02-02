vim.keymap.set("n", "<leader>uu", vim.cmd.UndotreeToggle)

return {
  {
    "mbbill/undotree",
    cmd = { "Undotree" },
    keys = {
      { "<leader>uu", mode = "n", desc = "UndotreeToggle" },
    },
  },
}
