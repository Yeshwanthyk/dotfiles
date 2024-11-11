return {
  {
    "junegunn/vim-easy-align",
  },
  -- {
  --   "L3MON4D3/LuaSnip", -- snippets
  --   event = "InsertEnter",
  --   dependencies = {
  --     "psto/friendly-snippets",
  --     config = function()
  --       -- specify the path so that friendly-snippets are not duplicated
  --       require("luasnip.loaders.from_vscode").lazy_load({ paths = { "~/.config/nvim/snippets" } })
  --       require("luasnip").filetype_extend("typescript", { "javascript" })
  --       require("luasnip").filetype_extend("typescriptreact", { "javascriptreact" })
  --     end,
  --   },
  -- },

  -- {
  --   "chrisgrieser/nvim-scissors",
  --   dependencies = {
  --     "rcarriga/nvim-notify",
  --   },
  --   opts = {
  --     jsonFormatter = "jq",
  --   },
  --     -- stylua: ignore
  --     keys = {
  --       { "<leader>cS", function() require("scissors").editSnippet() end, desc = "Edit Snippets" },
  --       { "<leader>cs", function() require("scissors").addNewSnippet() end, desc = "Add Snippets" },
  --     },
  -- },

  -- better diffing
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    opts = {},
    keys = { { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "DiffView" } },
  },

  { "akinsho/git-conflict.nvim", version = "*", config = true },

  -- fugitive: Git blame and open in GitHub
  {
    "tpope/vim-fugitive",
  },

  {
    "tpope/vim-rhubarb",
  },

  -- Git PRs
  {
    "daliusd/ghlite.nvim",
    config = function()
      require("ghlite").setup({
        debug = false, -- if set to true debugging information is written to ~/.ghlite.log file
        view_split = "vsplit", -- set to empty string '' to open in active buffer
        diff_split = "vsplit", -- set to empty string '' to open in active buffer
        comment_split = "split", -- set to empty string '' to open in active buffer
        open_command = "open", -- open command to use, e.g. on Linux you might want to use xdg-open
        keymaps = { -- override default keymaps with the ones you prefer
          diff = {
            open_file = "gf",
            open_file_tab = "gt",
            open_file_split = "gs",
            open_file_vsplit = "gv",
            approve = "<C-A>",
          },
          comment = {
            send_comment = "<C-CR>",
          },
          pr = {
            approve = "<C-A>",
          },
        },
      })
    end,
    keys = {
      { "<leader>gus", ":GHLitePRSelect<cr>", desc = "PR Select", silent = true },
      { "<leader>guo", ":GHLitePRCheckout<cr>", desc = "PR Checkout", silent = true },
      { "<leader>guv", ":GHLitePRView<cr>", desc = "PR View", silent = true },
      { "<leader>guu", ":GHLitePRLoadComments<cr>", desc = "PR Load Comments", silent = true },
      { "<leader>gup", ":GHLitePRDiff<cr>", desc = "PR Diff", silent = true },
      { "<leader>gul", ":GHLitePRDiffview<cr>", desc = "PR Diff View", silent = true },
      { "<leader>gua", ":GHLitePRAddComment<cr>", desc = "PR Add Comment", silent = true },
      { "<leader>guc", ":GHLitePRUpdateComment<cr>", desc = "PR Update Comment", silent = true },
      { "<leader>gud", ":GHLitePRDeleteComment<cr>", desc = "PR Delete Comment", silent = true },
      { "<leader>gug", ":GHLitePROpenComment<cr>", desc = "PR Open Comment", silent = true },
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
