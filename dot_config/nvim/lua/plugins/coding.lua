return {
  {
    "junegunn/vim-easy-align",
  },

  -- better diffing
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    opts = {},
    keys = { { "<leader>dv", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
  },

  { "akinsho/git-conflict.nvim", version = "*", config = true },

  -- fugitive: Git blame and open in GitHub
  {
    "tpope/vim-fugitive",
  },

  {
    "tpope/vim-rhubarb",
  },

  -- Create annotations with one keybind, and jump your cursor in the inserted annotation
  {
    "danymat/neogen",
    keys = {
      {
        "<leader>cc",
        function()
          require("neogen").generate({})
        end,
        desc = "Neogen Comment",
      },
    },
    opts = { snippet_engine = "luasnip" },
  },
}
