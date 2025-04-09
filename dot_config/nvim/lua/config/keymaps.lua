-- Move window
vim.keymap.set("n", "<Space>", "<C-w>w")

-- Move selected lines with shift+j or shift+k
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "6j")
vim.keymap.set("n", "K", "6k")

-- Join line while keeping the cursor in the same position
vim.keymap.set("n", "J", "mzJ`z")

-- -- Keep cursor centred while scrolling up and down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Next and previous instance of the highlighted letter
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Better paste (prevents new paste buffer)
vim.keymap.set("x", "<leader>p", [["_dP]])

-- Copy to system clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

-- Delete to void register
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- . repeat or execute macro on all visually selected lines
vim.keymap.set("x", ".", ":norm .<CR>", nosilent)
vim.keymap.set("x", "@", ":norm @q<CR>", nosilent)

-- jump back to original place
vim.keymap.set("n", "<BS>", "<C-o>")

-- jk,kj to go to normal mode
vim.keymap.set("i", "jk", "<Esc>")
vim.keymap.set("i", "kj", "<Esc>")

vim.keymap.set("n", "<C-c>", "ciw")

vim.keymap.set("n", "<leader>aq", function()
  vim.ui.input({
    prompt = "Enter -i globs/files (space-separated, e.g. *.js notes/file.md): ",
    completion = "file",
  }, function(input_string)
    if not input_string or input_string == "" then
      vim.notify("No globs or files provided.", vim.log.levels.WARN)
      return
    end

    local project_root_dir = vim.fn.getcwd()
    local include_args = {}

    for input_token in string.gmatch(input_string, "%S+") do
      table.insert(include_args, string.format('-i "%s"', input_token))
    end

    local bundle_cmd =
      string.format('codebundle -f output.md %s "%s"', table.concat(include_args, " "), project_root_dir)

    vim.cmd("silent !" .. bundle_cmd)
    vim.notify("Code bundle created.", vim.log.levels.INFO)
  end)
end, { desc = "Code Bundle: Input globs/files & generate" })

-- Apply the existing code bundle back to project
vim.keymap.set("n", "<leader>aw", function()
  local project_root = vim.fn.getcwd()
  local apply_command = string.format('codebundle -s "%s" output.md', project_root)
  vim.cmd("silent !" .. apply_command)
  print("Code bundle applied from output.md")
end, { desc = "Code Bundle: Apply" })

vim.keymap.set("n", "<leader>az", function()
  local git_relative_path = vim.fn.system('git ls-files --full-name -- "' .. vim.fn.expand("%:p") .. '"')
  git_relative_path = string.gsub(git_relative_path, "\n$", "") -- remove trailing newline, if any
  vim.fn.setreg("+", git_relative_path)
  vim.notify("Copied path: " .. git_relative_path, vim.log.levels.INFO)
end, { desc = "Copy git relative path to clipboard" })
