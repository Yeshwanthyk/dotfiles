return {
  {
    "junegunn/vim-easy-align",
  },

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

  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for Job and HTTP requests
    },
    -- cmd = "MCPHub", -- lazily start the hub when `MCPHub` is called
    build = "npm install -g mcp-hub@latest", -- Installs required mcp-hub npm module
    config = function()
      require("mcphub").setup({
        -- Required options
        port = 5001, -- Port for MCP Hub server
        config = vim.fn.expand("~/mcpservers.json"), -- Absolute path to config file

        -- Optional options
        on_ready = function(hub)
          -- Called when hub is ready
        end,
        on_error = function(err)
          -- Called on errors
        end,
        shutdown_delay = 0, -- Wait 0ms before shutting down server after last client exits
        log = {
          level = vim.log.levels.WARN,
          to_file = false,
          file_path = nil,
          prefix = "MCPHub",
        },
      })
    end,
  },

  -- {
  --   "pixqc/mana.nvim",
  --   main = "mana",
  --   opts = {
  --     default_model = "deepseekv3",
  --     models = {
  --       deepseekv3 = {
  --         endpoint = "openrouter",
  --         name = "deepseek/deepseek-chat-v3-0324:free",
  --         system_prompt = "",
  --         temperature = 0.7,
  --         top_p = 0.9,
  --       },
  --     },
  --     envs = {
  --       openrouter = "OPENROUTER_API_KEY",
  --     },
  --   },
  -- },
  --
  -- {
  --   "yetone/avante.nvim",
  --   event = "VeryLazy",
  --   version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
  --   opts = {
  --     -- add any opts here
  --     -- for example
  --     provider = "openai",
  --     system_prompt = function()
  --       local hub = require("mcphub").get_hub_instance()
  --       return hub:get_active_servers_prompt()
  --     end,
  --     custom_tools = function()
  --       return {
  --         require("mcphub.extensions.avante").mcp_tool(),
  --       }
  --     end,
  --     openai = {
  --       endpoint = "https://api.openai.com/v1",
  --       model = "gpt-4o-mini", -- your desired model (or use gpt-4o, etc.)
  --       timeout = 30000, -- timeout in milliseconds
  --       temperature = 0, -- adjust if needed
  --       max_tokens = 4096,
  --       -- reasoning_effort = "high" -- only supported for reasoning models (o1, etc.)
  --       disable_tools = true,
  --     },
  --     ollama = {
  --       model = "qwen2.5-coder:latest",
  --       disable_tools = true,
  --     },
  --     openrouter = {
  --       __inherited_from = "openai",
  --       endpoint = "https://openrouter.ai/api/v1",
  --       api_key_name = "OPENROUTER_API_KEY",
  --       model = "deepseek/deepseek-chat:free",
  --       disable_tools = true,
  --     },
  --   },
  --   -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
  --   build = "make",
  --   -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --     --- The below dependencies are optional,
  --     "echasnovski/mini.pick", -- for file_selector provider mini.pick
  --     "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
  --     "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
  --     "ibhagwan/fzf-lua", -- for file_selector provider fzf
  --     "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
  --     "zbirenbaum/copilot.lua", -- for providers='copilot'
  --     {
  --       -- support for image pasting
  --       "HakonHarnes/img-clip.nvim",
  --       event = "VeryLazy",
  --       opts = {
  --         -- recommended settings
  --         default = {
  --           embed_image_as_base64 = false,
  --           prompt_for_file_name = false,
  --           drag_and_drop = {
  --             insert_mode = true,
  --           },
  --           -- required for Windows users
  --           use_absolute_path = true,
  --         },
  --       },
  --     },
  --     {
  --       -- Make sure to set this up properly if you have lazy=true
  --       "MeanderingProgrammer/render-markdown.nvim",
  --       opts = {
  --         file_types = { "markdown", "Avante" },
  --       },
  --       ft = { "markdown", "Avante" },
  --     },
  --   },
  -- },
  --
  -- {
  --   dir = "/Users/yesh/Documents/personal/lobster-nvim",
  --   name = "lobsternvim",
  --   dependencies = {
  --     "nvim-telescope/telescope.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "sindrets/diffview.nvim",
  --   },
  --   config = function()
  --     require("lobster").setup({
  --       -- Optional configuration
  --       ignore_patterns = { ".git", "node_modules" },
  --       diff_command = "diffview", -- or "vimdiff"
  --     })
  --   end,
  --   keys = {
  --     { "<leader>lb", "<cmd>LobsterSelectFiles<CR>", desc = "Lobster Select Files" },
  --     { "<leader>ls", "<cmd>LobsterShowSelected<CR>", desc = "Lobster Show Selected Files" },
  --     { "<leader>lp", "<cmd>LobsterGeneratePrompt<CR>", desc = "Lobster Generate Prompt" },
  --     { "<leader>lx", "<cmd>LobsterGeneratePrompt xml<CR>", desc = "Lobster Generate XML" },
  --     { "<leader>lt", "<cmd>LobsterGeneratePrompt text<CR>", desc = "Lobster Generate Text" },
  --     { "<leader>la", "<cmd>LobsterApplyChanges<CR>", desc = "Lobster Apply Changes" },
  --   },
  -- },
  --
}
