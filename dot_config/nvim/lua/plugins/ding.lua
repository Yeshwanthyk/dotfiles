return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/ding.nvim",
    name = "ding.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local system_prompt = [[
      You are a senior software engineer. When suggesting code, deeply consider its maintainability, striving for concise and efficient solutions with fewer lines of code.
      Do not summarize changes or invent modifications beyond explicit requests.
      Always verify information before presenting. If speculation is necessary, clearly flag it. Value well‑reasoned arguments over authority or source.
      Use descriptive, explicit variable names to enhance readability. Adhere to the existing project code style, prioritizing consistency, readability, and performance.
      ]]

      require("ding").setup({
        gateway_url = "http://localhost:3000",
        default_session_id = "neovim-session",
        system_prompt = system_prompt,
        keymaps = {
          replace = "<leader>ar",
          append = "<leader>aa",
          cancel = "<Esc>",
        },
      })
    end,
    keys = {
      { "<leader>as", ":DingSelect<CR>", desc = "Switch LLM model" },
      { "<leader>ac", ":DingClearSession<CR>", desc = "Clear LLM session" },
      { "<leader>af", ":DingRefreshModels<CR>", desc = "Refresh LLM models" },
      { "<leader>ar", ":'<,'>DingReplace<CR>", mode = "v", desc = "Replace with LLM response" },
      { "<leader>aa", ":DingAppend<CR>", mode = "n", desc = "Append LLM response at cursor" },
      { "<leader>aa", ":'<,'>DingAppend<CR>", mode = "v", desc = "Append LLM response after selection" },
    },
    cmd = { "DingSelect", "DingClearSession", "DingRefreshModels", "DingReplace", "DingAppend" },
  },
  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/yeti.nvim",
    name = "yeti.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("yeti").setup({
        gateway_url = "http://localhost:3000",
        default_session_id = "neovim-session",
        keymaps = {
          send_buffers = "<leader>ab",
          cancel = "<Esc>",
        },
      })
    end,
    keys = {
      { "<leader>ab", ":YetiSendBuffers<CR>", desc = "Send all buffers to LLM" },
      { "<leader>ay", ":YetiSelectModel<CR>", desc = "Select LLM model for Yeti" },
      { "<leader>am", ":YetiRefreshModels<CR>", desc = "Refresh LLM models for Yeti" },
    },
    cmd = { "YetiSendBuffers", "YetiSelectModel", "YetiRefreshModels" },
  },
}

