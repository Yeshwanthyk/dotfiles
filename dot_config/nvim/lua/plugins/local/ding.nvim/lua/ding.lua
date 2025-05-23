local M = {}
local Job = require("plenary.job")
local curl = require("plenary.curl")

-- Plugin configuration with defaults
M.config = {
  gateway_url = "http://localhost:3009",
  -- default_model removed as it will be fetched from gateway
  default_session_id = "neovim-session",
  system_prompt = "You are a helpful programming assistant.",
  keymaps = {
    replace = "<leader>ar", -- Replace selected text with LLM response
    append = "<leader>aa", -- Append LLM response after cursor
    cancel = "<Esc>", -- Cancel ongoing LLM request
  },
}

-- Store available models
M.models = {}
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
  local _, srow, scol = unpack(vim.fn.getpos("v"))
  local _, erow, ecol = unpack(vim.fn.getpos("."))

  if vim.fn.mode() == "V" then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  end

  if vim.fn.mode() == "v" then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  end

  if vim.fn.mode() == "\22" then -- Visual block mode
    local lines = {}
    if srow > erow then
      srow, erow = erow, srow
    end
    if scol > ecol then
      scol, ecol = ecol, scol
    end
    for i = srow, erow do
      table.insert(
        lines,
        vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1]
      )
    end
    return lines
  end
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

-- Fetch models from the gateway
function M.fetch_models()
  curl.get({
    url = M.config.gateway_url .. "/models",
    headers = {
      ["Content-Type"] = "application/json",
    },
    callback = function(response)
      if response.status == 200 and response.body then
        local data = vim.json.decode(response.body)
        M.models = data.models
        print("LLM Gateway: Loaded " .. #M.models .. " models (gateway default: " .. (data.default or "N/A") .. ")")
      else
        print("LLM Gateway: Failed to fetch models")
      end
    end,
  })
end

-- Select model interactively
function M.select_model()
  if #M.models == 0 then
    print("No models available. Fetching models...")
    M.fetch_models()
    return
  end

  vim.ui.select(M.models, {
    prompt = "Select LLM model (will set gateway default):",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      -- Update the model on the gateway server
      curl.post({
        url = M.config.gateway_url .. "/set-default-model",
        headers = {
          ["Content-Type"] = "application/json",
        },
        body = vim.json.encode({
          model = choice,
          sessionId = M.config.default_session_id,
        }),
        callback = function(response)
          if response.status == 200 and response.body then
            local data = vim.json.decode(response.body)
            if data.success and data.defaultModel then
              print("Gateway default model set to: " .. data.defaultModel)
            else
              print("Failed to set default model")
            end
          else
            print("LLM Gateway: Failed to set default model")
          end
        end,
      })
    end
  end)
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
      vim.api.nvim_command("normal! d")
    else
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

  -- Prepare request
  local request_data = {
    prompt = "Here is the "
      .. filetype
      .. " file content:\n\n"
      .. file_content
      .. "\n\nPlease provide code or text to append at the current cursor position.",
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

-- Command to clear session
function M.clear_session()
  curl.post({
    url = M.config.gateway_url .. "/clear",
    query = {
      id = M.config.default_session_id,
    },
    callback = function(response)
      if response.status == 200 then
        print("LLM Gateway: Session cleared")
      else
        print("LLM Gateway: Failed to clear session")
      end
    end,
  })
end

-- Function to set default model for the gateway
function M.set_default_model(model)
  if not model then
    -- If no model provided, let the user select
    M.select_model()
    return
  end

  -- Validate model exists
  local model_valid = false
  for _, m in ipairs(M.models) do
    if m == model then
      model_valid = true
      break
    end
  end

  if not model_valid then
    print("Model '" .. model .. "' not found in available models")
    return
  end

  -- Update the model on the gateway server
  curl.post({
    url = M.config.gateway_url .. "/set-default-model",
    headers = {
      ["Content-Type"] = "application/json",
    },
    body = vim.json.encode({
      model = model,
      sessionId = M.config.default_session_id,
    }),
    callback = function(response)
      if response.status == 200 and response.body then
        local data = vim.json.decode(response.body)
        if data.success and data.defaultModel then
          print("Gateway default model set to: " .. data.defaultModel)
        else
          print("Failed to set default model")
        end
      else
        print("LLM Gateway: Failed to set default model")
      end
    end,
  })
end

-- Create plugin commands
function M.create_commands()
  vim.api.nvim_create_user_command("DingSelect", function()
    M.select_model()
  end, { desc = "Select LLM model" })

  vim.api.nvim_create_user_command("DingClearSession", function()
    M.clear_session()
  end, { desc = "Clear LLM session" })

  vim.api.nvim_create_user_command("DingRefreshModels", function()
    M.fetch_models()
  end, { desc = "Refresh available LLM models" })

  -- Add command to set default model for gateway
  vim.api.nvim_create_user_command("DingSetDefault", function(opts)
    if opts.args and opts.args ~= "" then
      M.set_default_model(opts.args)
    else
      M.select_model() -- If no args, open model selection
    end
  end, { nargs = "?", desc = "Set default LLM model for the gateway" })

  -- Add direct commands for replace and append
  vim.api.nvim_create_user_command("DingReplace", function()
    M.invoke_llm(true)
  end, { range = true, desc = "Replace selection with LLM response" })

  vim.api.nvim_create_user_command("DingAppend", function()
    if vim.fn.mode() == "n" then
      M.append_at_cursor()
    else
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

  -- Fetch available models on startup
  M.fetch_models()
end

return M
