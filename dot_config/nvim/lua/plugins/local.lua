return {
  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/ding.nvim",
    name = "ding.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local system_prompt = [[
You are a precise text replacement assistant. Your task is to modify the selected text according to the user's instruction.

Rules:
1. Make ONLY the specific change requested in the prompt
2. Preserve all formatting, structure, indentation, and spacing exactly
3. Return ONLY the modified text - no explanations, summaries, or additional content
4. If the instruction is unclear, make the most logical interpretation
5. For rename/replace operations, substitute all instances of the target text with the new text
6. For "rename X" without specifying target, choose a concise, clear alternative name
7. Maintain the exact same text structure and length as much as possible

Examples:
Instruction: "rename llm-gateway to gateway-new"
Selected text: "### 2. llm-gateway (Currently Active)"
Output: "### 2. gateway-new (Currently Active)"

Instruction: "rename llm-gateway"
Selected text: "### 2. llm-gateway (Currently Active)"
Output: "### 2. gateway-new (Currently Active)"
]]

      require("ding").setup({
        gateway_url = "http://localhost:3009",
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
      { "<leader>ar", ":'<,'>DingReplace<CR>", mode = "v", desc = "Replace with LLM response" },
      { "<leader>ar", ":DingReplace<CR>", mode = "n", desc = "Replace with LLM response" },
      { "<leader>aa", ":DingAppend<CR>", mode = "n", desc = "Append LLM response at cursor" },
      { "<leader>aa", ":'<,'>DingAppend<CR>", mode = "v", desc = "Append LLM response after selection" },
    },
    cmd = { "DingReplace", "DingAppend" },
  },

  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/llm-gateway",
    name = "llm-gateway",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("llm-gateway").setup({
        gateway_url = "http://localhost:3009",
        default_session_id = "neovim-session",
      })
    end,
    keys = {
      { "<Esc>", nil, desc = "Cancel ongoing requests" },
      { "<leader>as", ":DingSelect<CR>", desc = "Switch LLM model" },
      { "<leader>af", ":DingRefreshModels<CR>", desc = "Refresh LLM models" },
    },
    cmd = { "DingSelect", "DingClearSession", "DingRefreshModels" },
  },

  -- {
  --   dir = vim.fn.stdpath("config") .. "/lua/plugins/local/yeti.nvim",
  --   name = "yeti.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim" },
  --   config = function()
  --     require("yeti").setup({
  --       gateway_url = "http://localhost:3009",
  --       default_session_id = "neovim-session",
  --       keymaps = {
  --         send_buffers = "<leader>ab",
  --         cancel = "<Esc>",
  --       },
  --     })
  --   end,
  --   keys = {
  --     { "<leader>ab", ":YetiSendBuffers<CR>", desc = "Send all buffers to LLM" },
  --   },
  --   cmd = { "YetiSendBuffers", "YetiRefreshModels" },
  -- },

  {
    dir = vim.fn.stdpath("config") .. "/lua/plugins/local/mana.nvim",
    name = "mana.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("mana").setup({
        gateway_url = "http://localhost:3009",
        session_id = "neovim-session",
        keymaps = {
          toggle = "<leader>at",
        },
      })
    end,
    keys = {
      { "<leader>at", ":ManaChat toggle<CR>", desc = "Toggle Mana chat" },
      { "<leader>ac", ":ManaChat clear<CR>", desc = "Clear Mana chat" },
      { "<leader>au", ":ManaChat open<CR>", desc = "Open Mana chat" },
      { ",am", ":ManaChat buffers<CR>", desc = "Send buffers to Mana chat" },
    },
    cmd = { "ManaChat" },
  },

  -- orc
  {
    dir = "/Users/yesh/Documents/personal/orc/neovim",
    name = "orc.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim",
    },
    config = function()
      require("orc").setup()
    end,
    keys = {
      { "<leader>os", ":OrcPicker<CR>", desc = "Open orc session picker" },
      { "<leader>oS", ":OrcStart<CR>", desc = "Start orc session" },
      { "<leader>oq", ":OrcStop<CR>", desc = "Stop orc session" },
    },
    cmd = { "OrcPicker", "OrcStart", "OrcStop" },
  },
}
