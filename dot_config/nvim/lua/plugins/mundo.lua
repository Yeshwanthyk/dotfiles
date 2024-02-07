return {
  "simnalamburt/vim-mundo",
  cmd = "MundoToggle",
  init = function()
    local map = vim.api.nvim_set_keymap
    map("n", "<Leader>uu", "<CMD>MundoToggle<CR>", {})
  end,
  config = function()
    vim.g.mundo_preview_bottom = true
    vim.g.mundo_width = 30
    vim.g.mundo_right = true
  end,
}
