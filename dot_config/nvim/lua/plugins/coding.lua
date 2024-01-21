return {
  {
    "Wansmer/treesj",
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
  },

  {
    "cshuaimin/ssr.nvim",
    keys = {
      {
        "<leader>sR",
        function()
          require("ssr").open()
        end,
        mode = { "n", "x" },
        desc = "Structural Replace",
      },
    },
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
}
