return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/mana.nvim",
    name = "mana.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("mana").setup({
        envs = {
          openrouter = "OPENROUTER_API_KEY",
          deepseek = "DEEPSEEK_API_KEY",
          aistudio = "AISTUDIO_API_KEY", -- Google AI Studio
        },
        models = {
          ["Deepseek Coder"] = {
            endpoint = "deepseek",
            name = "deepseek-chat",
            display_name = "Deepseek Coder",
            system_prompt = "You are an expert coding assistant specialized in Neovim/Lua development.",
            temperature = 0.5,
            top_p = 0.9,
          },
          ["Openrouter DS"] = {
            endpoint = "openrouter",
            name = "deepseek/deepseek-chat-v3-0324:free",
            display_name = "Openrouter DS",
            system_prompt = "You are a helpful coding assistant.",
            temperature = 0.5,
            top_p = 0.9,
          },
          ["AI Studio"] = {
            endpoint = "aistudio",
            name = "gemini-2.5-pro-exp-03-25", -- Google AI Studio model
            system_prompt = "You are a coding assistant.",
            display_name = "AI Gemini",
            temperature = 0.7,
            top_p = 1.0,
          },
          ["Code Rewriter"] = {
            endpoint = "openrouter",
            name = "deepseek/deepseek-chat-v3-0324:free",
            system_prompt = "You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks",
            display_name = "Code Rewriter",
            temperature = 0.3,
            top_p = 0.9,
          },
          ["Code Editor"] = {
            endpoint = "openrouter",
            name = "deepseek/deepseek-chat-v3-0324:free",
            display_name = "Code Editor",
            system_prompt = "You are a helpful assistant. What I have sent are my notes so far.",
            temperature = 0.7,
            top_p = 1.0,
          },
        },
        default_model = "Deepseek Coder", -- Must match one of the keys in models table
      })
    end,
    keys = {
      { "<leader>aa", ":Mana toggle<CR>", desc = "Toggle Mana chat" },
      { "<leader>ac", ":Mana clear<CR>", desc = "Clear Mana chat" },
      { "<leader>as", ":Mana switch<CR>", desc = "Switch Mana model" },
      { "<leader>ab", ":Mana buffers<CR>", desc = "Send buffers to Mana" },
      { "<leader>ay", ":Mana yank<CR>", desc = "Yank code block from chat" },
      -- { "<leader>ap", "<cmd>'<,'>Mana paste<CR>", desc = "Send selection to chat", mode = "v" },
      { "<leader>ae", ":Mana complete<CR>", desc = "Mana complete to cursor" },
      { "<leader>ar", "<cmd>'<,'>Mana replace<CR>", desc = "Mana replace selection", mode = "v" },
    },
    cmd = "Mana",
  },
}
