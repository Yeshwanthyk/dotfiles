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

-- export_buffers_xml.lua
local function build_tree(paths)
  local root = { children = {} }
  local cwd = vim.loop.cwd()
  for _, path in ipairs(paths) do
    local rel = path
    if path:sub(1, #cwd) == cwd then
      rel = path:sub(#cwd + 2)
    end
    local parts = vim.split(rel, "/")
    local node = root
    for _, part in ipairs(parts) do
      node.children[part] = node.children[part] or { children = {} }
      node = node.children[part]
    end
  end
  return root.children
end

local function gen_tree(nodes, prefix, lines)
  local keys = {}
  for name in pairs(nodes) do
    table.insert(keys, name)
  end
  table.sort(keys)
  for i, name in ipairs(keys) do
    local is_last = (i == #keys)
    local connector = is_last and "└── " or "├── "
    local line = prefix .. connector .. name
    table.insert(lines, line)
    local child = nodes[name]
    if child and child.children and next(child.children) then
      local new_prefix = prefix .. (is_last and "    " or "│   ")
      gen_tree(child.children, new_prefix, lines)
    end
  end
end

vim.api.nvim_create_user_command("ExportBuffersXml", function()
  local persona = vim.g.prompt_persona or "{persona}"
  local instruction = vim.g.prompt_instruction or "{instruction}"
  local formatting_instructions = vim.g.prompt_formatting_instructions or "{formatting_instructions}"

  -- collect buffer paths
  local buf_paths = {}
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.api.nvim_buf_get_option(b, "buflisted") then
      local path = vim.api.nvim_buf_get_name(b)
      if path and path ~= "" then
        table.insert(buf_paths, path)
      end
    end
  end

  -- build tree lines
  local tree_nodes = build_tree(buf_paths)
  local tree_lines = {}
  gen_tree(tree_nodes, "", tree_lines)

  -- build XML
  local xml = {}
  table.insert(xml, "<prompt>")
  table.insert(xml, "  <persona>" .. persona .. "</persona>")
  table.insert(xml, "  <instruction>" .. instruction .. "</instruction>")
  table.insert(xml, "  <file_tree>")
  for _, line in ipairs(tree_lines) do
    table.insert(xml, "    " .. line)
  end
  table.insert(xml, "  </file_tree>")
  table.insert(xml, "  <files>")
  for _, path in ipairs(buf_paths) do
    for _, b in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_get_name(b) == path then
        local lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
        table.insert(xml, '    <file path="' .. path .. '">')
        for _, l in ipairs(lines) do
          table.insert(xml, l)
        end
        table.insert(xml, "      ]]>")
        table.insert(xml, "    </file>")
        break
      end
    end
  end
  table.insert(xml, "  </files>")
  table.insert(xml, "  <xml_formatting_instructions>")
  table.insert(xml, "    " .. formatting_instructions)
  table.insert(xml, "  </xml_formatting_instructions>")
  table.insert(xml, "</prompt>")

  -- open vertical split and write
  vim.cmd("vsplit")
  vim.cmd("enew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "xml")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, xml)
end, { desc = "Export open buffers as XML with ascii tree" })
