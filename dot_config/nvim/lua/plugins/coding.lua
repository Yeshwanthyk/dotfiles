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
        require("luasnip.loaders.from_vscode").lazy_load({ paths = { "~/.config/nvim/snippets" } })
        require("luasnip").filetype_extend("typescript", { "javascript" })
        require("luasnip").filetype_extend("typescriptreact", { "javascriptreact" })
      end,
    },
  },

  {
    "chrisgrieser/nvim-scissors",
    dependencies = {
      "rcarriga/nvim-notify",
    },
    opts = {
      jsonFormatter = "jq",
    },
    -- stylua: ignore
    keys = {
      { "<leader>cS", function() require("scissors").editSnippet() end, desc = "Edit Snippets" },
      { "<leader>cs", function() require("scissors").addNewSnippet() end, desc = "Add Snippets" },
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

  -- fugitive: Git blame and open in GitHub
  {
    "tpope/vim-fugitive",
    lazy = true,
    cmd = "Git",
    keys = {
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
    },
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
