return {
  'folke/twilight.nvim',
  {
    'folke/zen-mode.nvim',
    cmd = 'ZenMode',
    opts = {
      plugins = {
        gitsigns = true,
        tmux = true,
        kitty = { enabled = false, font = '+2' },
      },
    },
    keys = { { '<leader>z', '<cmd>ZenMode<cr>', desc = 'Zen Mode' } },
  },
  {
    'shortcuts/no-neck-pain.nvim',
    version = '*',
    keys = {
      { '<Leader>cn', ':NoNeckPain<CR>', desc = 'NoNeckPain' },
    },
  },
}
