local M = {}
local Job = require("plenary.job")
local curl = require("plenary.curl")

-- Plugin configuration with defaults
M.config = {
  gateway_url = "http://localhost:3009",
  -- default_model removed as it will be fetched from gateway
  default_session_id = "neovim-session",
  system_prompt = [[You are a precise text replacement assistant. Your task is to modify the selected text according to the user's instruction.

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
Output: "### 2. gateway-new (Currently Active)"]],
  keymaps = {
    replace = "<leader>ar", -- Replace selected text with LLM response
    append = "<leader>aa", -- Append LLM response after cursor
    cancel = "<Esc>", -- Cancel ongoing LLM request
  },
}

M.active_job = nil
M.stream_progress = 0 -- Counter for showing streaming progress

-- Spinner frames for progress indication
local spinner_frames = {
  "(๑• ◡• )",
  "(づ｡◕‿‿◕｡)づ",
  "✩°｡⋆⸜(｡•ω•｡)",
  "(๑• ◡• )",
  "(づ｡◕‿‿◕｡)づ",
  "✩°｡⋆⸜(｡•ω•｡)",
  "[^_^]",
  "(>^_^)>",
  "<(o.o<)",
  "(*_*)",
  "(>_<)",
  "(^_^)v",
  "（＾_＾）",
  "(•_•)",
  "◉_◉",
  "✦✧",
}

local current_spinner_frame = 1

-- Write string at cursor position
function M.write_string_at_cursor(str)
  vim.schedule(function()
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row, col = cursor_position[1], cursor_position[2]

    local lines = vim.split(str, "\n")

    vim.cmd("undojoin")
    vim.api.nvim_put(lines, "c", true, true)

    local num_lines = #lines
    local last_line_length = #lines[num_lines]
    vim.api.nvim_win_set_cursor(current_window, { row + num_lines - 1, col + last_line_length })
  end)
end

-- Get visual selection
function M.get_visual_selection()
  -- Get visual selection marks
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  -- Check if we have valid visual marks
  if start_pos[2] == 0 or end_pos[2] == 0 then
    return nil
  end
  
  local srow, scol = start_pos[2], start_pos[3]
  local erow, ecol = end_pos[2], end_pos[3]
  
  -- Get the visual mode type from the last visual selection
  local visual_mode = vim.fn.visualmode()
  
  if visual_mode == "V" then
    -- Line-wise visual selection
    return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
  elseif visual_mode == "v" then
    -- Character-wise visual selection
    if srow == erow then
      -- Same line selection
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      -- Multi-line selection
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    end
  elseif visual_mode == "\22" then
    -- Visual block mode
    local lines = {}
    for i = srow, erow do
      local line_text = vim.api.nvim_buf_get_text(0, i - 1, scol - 1, i - 1, ecol, {})
      table.insert(lines, line_text[1] or "")
    end
    return lines
  end
  
  return nil
end

-- Get content of current file
function M.get_current_file_content()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(lines, "\n")
end

-- Get current buffer file type
function M.get_filetype()
  return vim.bo.filetype
end


-- Handle streaming response
function M.handle_stream_response(data)
  if not data or data == "" then
    return
  end

  -- Handle data: prefix in server-sent events
  local text_data = data
  if data:match("^data:") then
    text_data = data:gsub("^data:%s*", "")
  end

  -- Try to parse as JSON
  local success, parsed = pcall(vim.json.decode, text_data)

  if success and parsed and parsed.text then
    M.write_string_at_cursor(parsed.text)
  else
    -- Fallback: if not valid JSON with text field, write as is
    M.write_string_at_cursor(text_data)
  end
end

-- Main function to invoke LLM
function M.invoke_llm(replace)
  -- Get visual selection
  local visual_lines = M.get_visual_selection()
  local prompt = ""

  if visual_lines then
    prompt = table.concat(visual_lines, "\n")

    if replace then
      -- Delete the selected text using the visual marks
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      local srow, scol = start_pos[2], start_pos[3]
      local erow, ecol = end_pos[2], end_pos[3]
      
      -- Position cursor at start of selection
      vim.api.nvim_win_set_cursor(0, {srow, scol - 1})
      
      -- Delete the selected text based on visual mode
      local visual_mode = vim.fn.visualmode()
      if visual_mode == "V" then
        -- Line-wise: delete entire lines
        vim.api.nvim_buf_set_lines(0, srow - 1, erow, false, {})
      elseif visual_mode == "v" then
        -- Character-wise: delete selected text
        if srow == erow then
          -- Same line
          vim.api.nvim_buf_set_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
        else
          -- Multi-line
          vim.api.nvim_buf_set_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
        end
      elseif visual_mode == "\22" then
        -- Visual block mode: delete block
        for i = erow, srow, -1 do
          vim.api.nvim_buf_set_text(0, i - 1, scol - 1, i - 1, ecol, {})
        end
      end
    else
      -- Just clear visual selection for append mode
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", false, true, true), "nx", false)
    end
  else
    print("No text selected")
    return
  end

  -- Reset progress and spinner
  M.stream_progress = 0
  current_spinner_frame = 1

  -- Prepare request
  local request_data = {
    prompt = prompt,
    sessionId = M.config.default_session_id,
    stream = true,
    systemPrompt = M.config.system_prompt,
  }

  -- Set up temporary keymap for cancellation
  vim.keymap.set("n", M.config.keymaps.cancel, function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LLM_Gateway_Cancel" })
  end, { noremap = true, silent = true })

  -- Start the streaming job
  M.active_job = Job:new({
    command = "curl",
    args = {
      "-s",
      "-N",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "--no-buffer",
      "-d",
      vim.json.encode(request_data),
      M.config.gateway_url .. "/call",
    },
    on_stdout = function(_, data)
      -- Process streamed response using the handler
      M.handle_stream_response(data)
      -- Update progress indicator
      M.stream_progress = M.stream_progress + 1
      vim.schedule(function()
        if M.stream_progress % 5 == 0 then -- Every 5 chunks
          vim.cmd("redraw")
          -- Update spinner animation
          current_spinner_frame = (current_spinner_frame % #spinner_frames) + 1
          local frame = spinner_frames[current_spinner_frame]
          vim.cmd("echo 'Ding requesting... " .. frame .. "'")
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and data ~= "" then
        print("LLM Gateway error: " .. data)
      end
    end,
    on_exit = function()
      M.active_job = nil
      -- Clear progress indicator
      vim.schedule(function()
        vim.cmd("echo ''")
      end)
      -- Restore default Esc behavior
      vim.schedule(function()
        vim.keymap.del("n", M.config.keymaps.cancel)
      end)
    end,
  })

  M.active_job:start()
  print("Sending request to LLM Gateway...")
end

-- Append at cursor function for normal mode
function M.append_at_cursor()
  -- Get current file content as context
  local file_content = M.get_current_file_content()
  local filetype = M.get_filetype()

  -- Reset progress and spinner
  M.stream_progress = 0
  current_spinner_frame = 1

  -- Prepare request with specific system prompt for append operations
  local append_system_prompt = [[You are a helpful programming assistant. Generate appropriate code or text to append at the cursor position based on the context provided. Be concise and relevant to the file content and cursor position.]]
  
  local request_data = {
    prompt = "Here is the "
      .. filetype
      .. " file content:\n\n"
      .. file_content
      .. "\n\nPlease provide code or text to append at the current cursor position.",
    sessionId = M.config.default_session_id,
    stream = true,
    systemPrompt = append_system_prompt,
  }

  -- Set up temporary keymap for cancellation
  vim.keymap.set("n", M.config.keymaps.cancel, function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LLM_Gateway_Cancel" })
  end, { noremap = true, silent = true })

  -- Start the streaming job
  M.active_job = Job:new({
    command = "curl",
    args = {
      "-s",
      "-N",
      "-X",
      "POST",
      "-H",
      "Content-Type: application/json",
      "--no-buffer",
      "-d",
      vim.json.encode(request_data),
      M.config.gateway_url .. "/call",
    },
    on_stdout = function(_, data)
      -- Process streamed response using the handler
      M.handle_stream_response(data)
      -- Update progress indicator
      M.stream_progress = M.stream_progress + 1
      vim.schedule(function()
        if M.stream_progress % 5 == 0 then -- Every 5 chunks
          vim.cmd("redraw")
          -- Update spinner animation
          current_spinner_frame = (current_spinner_frame % #spinner_frames) + 1
          local frame = spinner_frames[current_spinner_frame]
          vim.cmd("echo 'Ding requesting... " .. frame .. "'")
        end
      end)
    end,
    on_stderr = function(_, data)
      if data and data ~= "" then
        print("LLM Gateway error: " .. data)
      end
    end,
    on_exit = function()
      M.active_job = nil
      -- Clear progress indicator
      vim.schedule(function()
        vim.cmd("echo ''")
      end)
      -- Restore default Esc behavior
      vim.schedule(function()
        vim.keymap.del("n", M.config.keymaps.cancel)
      end)
    end,
  })

  M.active_job:start()
  print("Sending request to LLM Gateway...")
end


-- Create plugin commands
function M.create_commands()
  -- Add direct commands for replace and append
  vim.api.nvim_create_user_command("DingReplace", function()
    M.invoke_llm(true)
  end, { range = true, desc = "Replace selection with LLM response" })

  vim.api.nvim_create_user_command("DingAppend", function()
    -- Check if we have a visual selection by checking the marks
    local start_pos = vim.fn.getpos("'<")
    local end_pos = vim.fn.getpos("'>")
    
    if start_pos[2] == 0 or end_pos[2] == 0 then
      -- No visual selection, use normal append
      M.append_at_cursor()
    else
      -- Visual selection exists, use text replacement logic
      M.invoke_llm(false)
    end
  end, { range = true, desc = "Append LLM response" })
end

-- Initialize the plugin
function M.setup(opts)
  -- Merge config with provided options
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create augroup for the plugin
  M.augroup = vim.api.nvim_create_augroup("LLM_Gateway", { clear = true })

  -- Set up cancel autocmd
  vim.api.nvim_create_autocmd("User", {
    group = M.augroup,
    pattern = "LLM_Gateway_Cancel",
    callback = function()
      if M.active_job then
        M.active_job:shutdown()
        vim.cmd("echo ''") -- Clear spinner on cancel
        print("LLM request cancelled")
        M.active_job = nil
      end
    end,
  })

  -- Create commands
  M.create_commands()

  -- Set up direct keymaps
  if M.config.keymaps then
    -- Replace in visual mode
    if M.config.keymaps.replace then
      vim.api.nvim_set_keymap(
        "v",
        M.config.keymaps.replace,
        ":'<,'>DingReplace<CR>",
        { noremap = true, silent = true, desc = "Replace with LLM response" }
      )
    end

    -- Append in normal mode
    if M.config.keymaps.append then
      vim.api.nvim_set_keymap(
        "n",
        M.config.keymaps.append,
        ":DingAppend<CR>",
        { noremap = true, silent = true, desc = "Append LLM response at cursor" }
      )

      -- Append in visual mode
      vim.api.nvim_set_keymap(
        "v",
        M.config.keymaps.append,
        ":'<,'>DingAppend<CR>",
        { noremap = true, silent = true, desc = "Append LLM response after selection" }
      )
    end
  end

end

return M
