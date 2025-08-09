-- Git tooling with unified keymaps
--
-- FUGITIVE KEYMAPS (Core git operations):
-- <leader>gG - Git status (fugitive buffer)
-- <leader>ga/gA - Add current file / Add all
-- <leader>gc/gC - Commit / Commit amend
-- <leader>gp/gP - Push / Pull
-- <leader>gb/gB - Git blame / Browse on GitHub
-- <leader>gl/gL/gS - Git log oneline / detailed / show
-- <leader>g<leader> - Git diff split
-- <leader>g2/g3 - Diff vs HEAD~1/HEAD~2
--
-- DIFFVIEW KEYMAPS (Visual diffs & file history):
-- <leader>gf - Current file vs HEAD
-- <leader>gh - File history (follows renames)
-- <leader>gv - Visual selection history
-- <leader>gw - Working directory vs HEAD
-- <leader>gs - Staged changes
-- <leader>gH - Repository history
-- <leader>gd - Toggle diff view
-- <leader>gm/gM - Diff vs main / origin/main
-- <leader>gF/go - Interactive file history / diff (with input)
--
-- GIT CONFLICT KEYMAPS:
-- <leader>gcb/o/t/B/n - Choose base/ours/theirs/both/none
-- <leader>gcl - List conflicts in quickfix

return {
  -- Fugitive: Core git commands
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "GRemove", "GRename" },
    keys = {
      -- Core git operations
      { "<leader>gG", "<cmd>Git<cr>", desc = "Git Status" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git Commit" },
      { "<leader>gC", "<cmd>Git commit --amend<cr>", desc = "Git Commit Amend" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Git Push" },
      { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git Pull" },
      
      -- Git blame and browse
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame" },
      { "<leader>gB", "<cmd>GBrowse<cr>", desc = "Git Browse" },
      
      -- Git log and show
      { "<leader>gl", "<cmd>Git log --oneline<cr>", desc = "Git Log" },
      { "<leader>gL", "<cmd>Git log<cr>", desc = "Git Log Detailed" },
      { "<leader>gS", "<cmd>Git show<cr>", desc = "Git Show" },
      
      -- Diff operations
      { "<leader>g<leader>", "<cmd>Gdiffsplit<cr>", desc = "Git Diff Split" },
    },
  },

  -- Diffview: Visual diff and file history
  {
    "sindrets/diffview.nvim",
    dependencies = "nvim-lua/plenary.nvim",
    cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      signs = {
        fold_closed = "",
        fold_open = "",
        done = "✓",
      },
      file_panel = {
        listing_style = "tree",
        tree_options = {
          flatten_dirs = true,
          folder_statuses = "only_folded",
        },
      },
      file_history_panel = {
        log_options = {
          git = {
            single_file = {
              follow = true,
              all = false,
              merges = false,
            },
            multi_file = {
              follow = false,
              all = false,
              merges = false,
            },
          },
        },
      },
    },
    config = function(_, opts)
      require("diffview").setup(opts)

      local function diffOpenWithInput()
        local user_input = vim.fn.input("Revision to Open: ")
        if user_input ~= "" then
          vim.cmd("DiffviewOpen " .. user_input)
        end
      end

      local function diffOpenFileHistory()
        local user_input = vim.fn.input("Files to Open: ")
        if user_input ~= "" then
          vim.cmd("DiffviewFileHistory " .. user_input)
        else
          vim.cmd("DiffviewFileHistory %")
        end
      end

      -- Interactive keymaps with which-key
      require("which-key").add({
        { "<leader>g", group = "Git" },
        { "<leader>gF", diffOpenFileHistory, desc = "File History (Interactive)" },
        { "<leader>go", diffOpenWithInput, desc = "Diff View (Interactive)" },
      })
    end,
    keys = {
      -- File-focused operations
      { "<leader>gf", "<cmd>DiffviewOpen HEAD -- %<cr>", desc = "File vs HEAD" },
      { "<leader>gh", "<cmd>DiffviewFileHistory --follow %<cr>", desc = "File History" },
      { "<leader>gv", ":'<,'>DiffviewFileHistory --follow<cr>", mode = "v", desc = "Selection History" },
      
      -- Repository-wide operations  
      { "<leader>gw", "<cmd>DiffviewOpen HEAD<cr>", desc = "Working vs HEAD" },
      { "<leader>gs", "<cmd>DiffviewOpen --cached<cr>", desc = "Staged Changes" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "Repo History" },
      
      -- Diff toggle
      {
        "<leader>gd",
        function()
          local view = require("diffview.lib").get_current_view()
          if view then
            vim.cmd("DiffviewClose")
          else
            vim.cmd("DiffviewOpen")
          end
        end,
        desc = "Diff Toggle",
      },

      -- Branch comparisons
      {
        "<leader>gm",
        function()
          local branch = vim.fn
            .system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'")
            :gsub("\n", "")
          if branch == "" then
            branch = vim.fn.system("git rev-parse --verify main 2>/dev/null"):gsub("\n", "") ~= "" and "main" or "master"
          end
          vim.cmd("DiffviewOpen " .. branch)
        end,
        desc = "Diff vs Main",
      },
      {
        "<leader>gM",
        function()
          local branch = vim.fn
            .system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'")
            :gsub("\n", "")
          if branch == "" then
            branch = vim.fn.system("git rev-parse --verify origin/main 2>/dev/null"):gsub("\n", "") ~= "" and "main"
              or "master"
          end
          vim.cmd("DiffviewOpen origin/" .. branch)
        end,
        desc = "Diff vs Origin/Main",
      },
    },
  },

  -- Git conflict resolution
  { 
    "akinsho/git-conflict.nvim", 
    version = "*", 
    config = true,
    keys = {
      { "<leader>gcb", "<cmd>GitConflictChooseBase<cr>", desc = "Choose Base" },
      { "<leader>gco", "<cmd>GitConflictChooseOurs<cr>", desc = "Choose Ours" },
      { "<leader>gct", "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose Theirs" },
      { "<leader>gcB", "<cmd>GitConflictChooseBoth<cr>", desc = "Choose Both" },
      { "<leader>gcn", "<cmd>GitConflictChooseNone<cr>", desc = "Choose None" },
      { "<leader>gcl", "<cmd>GitConflictListQf<cr>", desc = "List Conflicts" },
    },
  },
}