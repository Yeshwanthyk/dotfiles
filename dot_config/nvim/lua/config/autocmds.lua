-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here'

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc", "markdown" },
  callback = function()
    vim.opt.conceallevel = 1
  end,
})

local function apply_codeblock_patch()
	-- 1) grab buffer & all lines
	local diff_buf = vim.api.nvim_get_current_buf()
	local lines    = vim.api.nvim_buf_get_lines(diff_buf, 0, -1, false)

	-- 2) find the first two code-fence lines: ```
	local fences = {}
	for i, ln in ipairs(lines) do
	  if ln:match('^```') then
	    fences[#fences+1] = i
	    if #fences == 2 then break end
	  end
	end
	if #fences < 2 then
	  vim.notify("No code blocks found", vim.log.levels.ERROR)
	  return
	end

	-- 3) extract the diff lines inside the fences
	local start_cb, end_cb = fences[1], fences[2]
	local diff_lines = vim.list_slice(lines, start_cb+1, end_cb-1)

	-- 4) pull out filepath
	local filepath
	for _, ln in ipairs(diff_lines) do
	  local p = ln:match('^%.%.%.%s*(.+)$')
	  if p then filepath = p; break end
	end
	if not filepath then
	  vim.notify("No '... /path/to/file' line in code block", vim.log.levels.ERROR)
	  return
	end

	-- 5) collect old/new hunks
	local old_hunk, new_hunk = {}, {}
	local mode
	for _, ln in ipairs(diff_lines) do
	  if ln:match('^<<<<<< SEARCH') then
	    mode = 'old'
	  elseif ln:match('^======') then
	    mode = nil
	  elseif ln:match('^>>>>>> REPLACE') then
	    mode = 'new'
	  elseif mode == 'old' then
	    table.insert(old_hunk, ln)
	  elseif mode == 'new' then
	    table.insert(new_hunk, ln)
	  end
	end
	if #old_hunk == 0 then
	  vim.notify("No old hunk between SEARCH/======", vim.log.levels.ERROR)
	  return
	elseif #new_hunk == 0 then
	  vim.notify("No new hunk after >>>>>> REPLACE", vim.log.levels.ERROR)
	  return
	end

	-- 6) open the real file
	local orig = diff_buf
	vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
	local buf    = vim.api.nvim_get_current_buf()
	local target = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- 7) find and replace the exact old sequence
	local start_i, end_i
	for i = 1, #target - #old_hunk + 1 do
	  local ok = true
	  for j = 1, #old_hunk do
	    if target[i+j-1] ~= old_hunk[j] then ok = false; break end
	  end
	  if ok then
	    start_i = i-1
	    end_i   = i-1 + #old_hunk
	    break
	  end
	end

	if not start_i then
	  vim.notify("Couldn't locate the old hunk in file", vim.log.levels.ERROR)
	else
	  vim.api.nvim_buf_set_lines(buf, start_i, end_i, false, new_hunk)
	  vim.cmd('write')
	end

	-- 8) jump back to your diff buffer
	vim.api.nvim_set_current_buf(orig)
      end

      -- map <leader>r to do it:
      vim.keymap.set('n', '<leader>ax', apply_codeblock_patch, { silent = true })