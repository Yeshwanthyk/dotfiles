return {

  -- fugitive: Git blame and open in GitHub
  {
    'tpope/vim-fugitive',
    lazy = true,
    cmd = 'Git',
    keys = {
      { '<leader>cb', '<cmd>Git blame<cr>', desc = 'Git Blame' },
    },
  },
}
