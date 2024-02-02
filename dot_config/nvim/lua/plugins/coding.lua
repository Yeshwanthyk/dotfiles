return {
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("refactoring").setup()
    end,
  },
  {
    "junegunn/vim-easy-align",
  },
  {
    "L3MON4D3/LuaSnip", -- snippets
    event = "InsertEnter",
    dependencies = {
      "psto/friendly-snippets",
      config = function()
        -- specify the path so that friendly-snippets are not duplicated
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip").filetype_extend("typescript", { "javascript" })
        require("luasnip").filetype_extend("typescriptreact", { "javascriptreact" })
      end,
    },
  },
  -- Incremental rename
  {
    "smjonas/inc-rename.nvim",
    cmd = "IncRename",
    config = true,
  },

  -- better diffing
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    opts = {},
    keys = { { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
  },
}
