local M = {}
local Job = require("plenary.job")
local curl = require("plenary.curl")

-- Plugin configuration with defaults
M.config = {
  gateway_url = "http://localhost:3000",
  default_model = nil, -- Will be fetched from gateway
  default_session_id = "neovim-session",
  debug = true, -- Set to true to enable debug logging (temporary change for troubleshooting)
  keymaps = {
    send_buffers = "<leader>ab", -- Send all buffers to LLM
    cancel = "<Esc>", -- Cancel ongoing LLM request
    apply_edits = "<leader>ax", -- Apply edits from LLM response
  },
  prompt_template = [[
You are an expert programming helper.

The context will include the *latest version* of the files throughout the session. The person you are speaking to is incredibly skilled. He knows what he is doing.
When you want to edit files; you **must** show the change in the following special format.

## The special code editing format
- Uses **file blocks**
- Starts with "... ", and then the filename
- Ends with "..."
- Uses **search and replace** blocks
  - Uses "<<<<<< SEARCH" to find the original lines to replace
  - Continues to "======",
  - Immediately follows to contain what to replace the code with
  - Finally, ends with ">>>>>> REPLACE"
- For each file edited, there can be multiple search and replace commands
- The lines must match **exactly**. This means, all indentation should be preserved.
- **IMPORTANT**: Copy the exact indentation from the original file.
- Do not make things up when adding something to the SEARCH block.
- Do not show SEARCH/REPLACE blocks for files that do not exist.

## Example 1: Modifying a function (preserving indentation)
```
... /path/to/file.py
<<<<<< SEARCH
def old_function(x):
    return x + 1
======
>>>>>> REPLACE
def improved_function(x):
    # Better implementation
    return x * 2
...
```

## Example 2: Removing code
```
... /path/to/file.py
<<<<<< SEARCH
    # This is old code we want to remove
    print("debug statement")
======
>>>>>> REPLACE
...
```

## Example 3: Adding code to an empty file or creating a new file
```
... /path/to/new_file.py
<<<<<< SEARCH
======
>>>>>> REPLACE
def new_function():
    print("This is a new file")
    return True
...
```

## Example 4: Multiple changes to the same file
```
... /path/to/file.py
<<<<<< SEARCH
def function_one():
    return False
======
>>>>>> REPLACE
def function_one():
    return True
...

... /path/to/file.py
<<<<<< SEARCH
x = 10
======
>>>>>> REPLACE
x = 20
...
```

- If a file needs no changes, DO NOT include a block for it.
- If the request cannot be fulfilled or requires clarification, output nothing.
- DO NOT include any conversational text, explanations, or text outside this strict format.

### Context Files
%s

### User Request
%s
]],
}

-- Store available models
M.models = {}
M.active_job = nil
M.current_model = nil
M.current_response = ""
M.data_buffer = "" -- Buffer for incomplete SSE data chunks
M.stream_progress = 0 -- Counter for showing streaming progress
M.stream_buffer = nil -- Buffer to display streaming content
M.stream_window = nil -- Window to display streaming content

-- Get all loaded buffers
function M.get_all_buffers()
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
      local filename = vim.api.nvim_buf_get_name(buf)
      if filename ~= "" then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        table.insert(buffers, {
          filename = filename,
          content = table.concat(lines, "\n")
        })
      end
    end
  end
  return buffers
end

-- Format context files for prompt
function M.format_context_files(buffers)
  local context = ""
  for _, buf in ipairs(buffers) do
    local filename = buf.filename
    local file_ext = filename:match("%.([^%.]+)$") or ""
    local language = file_ext

    -- Add syntax highlighting hints based on common file extensions
    if file_ext == "py" then
      language = "python"
    elseif file_ext == "js" then
      language = "javascript"
    elseif file_ext == "ts" then
      language = "typescript"
    elseif file_ext == "jsx" or file_ext == "tsx" then
      language = "tsx"
    elseif file_ext == "rb" then
      language = "ruby"
    elseif file_ext == "go" then
      language = "go"
    elseif file_ext == "java" then
      language = "java"
    elseif file_ext == "c" or file_ext == "h" then
      language = "c"
    elseif file_ext == "cpp" or file_ext == "hpp" or file_ext == "cc" then
      language = "cpp"
    elseif file_ext == "rs" then
      language = "rust"
    elseif file_ext == "lua" then
      language = "lua"
    elseif file_ext == "php" then
      language = "php"
    elseif file_ext == "sh" then
      language = "bash"
    elseif file_ext == "html" then
      language = "html"
    elseif file_ext == "css" then
      language = "css"
    elseif file_ext == "json" then
      language = "json"
    elseif file_ext == "md" then
      language = "markdown"
    end

    context = context .. "```" .. language .. " " .. filename .. "\n" .. buf.content .. "\n```\n\n"
  end
  return context
end

-- Create or get the stream buffer
function M.get_stream_buffer()
  if M.stream_buffer and vim.api.nvim_buf_is_valid(M.stream_buffer) then
    vim.api.nvim_buf_set_lines(M.stream_buffer, 0, -1, false, {})
  else
    M.stream_buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(M.stream_buffer, "LLM Streaming Response")
    vim.api.nvim_buf_set_option(M.stream_buffer, "filetype", "markdown")
    vim.api.nvim_buf_set_option(M.stream_buffer, "modifiable", true)
  end
  return M.stream_buffer
end

-- Show the stream buffer in a split window
function M.show_stream_buffer(buf, prompt)
  -- Create split window
  vim.cmd("botright split")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_height(win, 15) -- Set reasonable height

  -- Set initial content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Request: " .. prompt,
    "",
    "# Response:",
    "Waiting for response..."
  })

  -- Set buffer local keymaps for convenience
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':q<CR>',
    { noremap = true, silent = true, desc = "Close response window" })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', ':q<CR>',
    { noremap = true, silent = true, desc = "Close response window" })

  -- Add a header with instructions
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 1, "Press 'q' to close this window.")
  table.insert(lines, 2, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Store window reference
  M.stream_window = win

  -- Return to previous window
  vim.cmd("wincmd p")

  return win
end

-- Update stream buffer with content
function M.update_stream_buffer(buf, content)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local lines = vim.split(content, "\n")

    -- Keep the request line at the top
    local request_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    local all_lines = {request_line, "", "# Response:"}

    -- Add the response lines
    for _, line in ipairs(lines) do
      table.insert(all_lines, line)
    end

    -- Update the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)

    -- Auto-scroll to the bottom if window exists
    if M.stream_window and vim.api.nvim_win_is_valid(M.stream_window) then
      vim.api.nvim_win_set_cursor(M.stream_window, {#all_lines, 0})
    end
  end
end

-- Write streamed response to current buffer
function M.handle_stream_response(data)
  if not data or data == "" then
    return
  end

  -- Handle "data:" prefix in server-sent events
  local text_data = data
  if data:match("^data:") then
    text_data = data:gsub("^data:%s*", "")
  end

  -- Skip "keep-alive" messages and [DONE] markers
  if text_data == "" or text_data == "[DONE]" then
    return
  end

  -- Try to parse as JSON
  local success, parsed = pcall(vim.json.decode, text_data)

  if success and parsed and parsed.text then
    -- Add to current accumulated response
    M.current_response = M.current_response .. parsed.text

    -- Update progress indicator
    M.stream_progress = M.stream_progress + 1

    -- Update the stream buffer with new content
    vim.schedule(function()
      if M.stream_buffer and vim.api.nvim_buf_is_valid(M.stream_buffer) then
        M.update_stream_buffer(M.stream_buffer, M.current_response)
      end

      if M.stream_progress % 5 == 0 then -- Every 5 chunks
        vim.cmd("redraw")
        print("Receiving LLM response... " .. string.rep(".", M.stream_progress / 5 % 10))
      end
    end)
  else
    -- Handle non-JSON data or parsing errors by printing debug info
    vim.schedule(function()
      if M.config.debug then
        print("Failed to parse chunk: " .. text_data)
      end
    end)
  end
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
        M.current_model = data.default
        print("LLM Gateway: Loaded " .. #M.models .. " models")
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
    prompt = "Select LLM model:",
    format_item = function(item)
      if item == M.current_model then
        return item .. " (current)"
      else
        return item
      end
    end,
  }, function(choice)
    if choice then
      M.current_model = choice
      print("Selected model: " .. choice)
    end
  end)
end

-- Main function to send all buffers to LLM
function M.send_buffers()
  if not M.current_model then
    print("No model selected. Fetching models...")
    M.fetch_models()
    return
  end

  -- Get prompt from user
  vim.ui.input({ prompt = "Enter your request: " }, function(input)
    if not input or input == "" then
      print("Request cancelled")
      return
    end

    -- Reset current response and progress counter
    M.current_response = ""
    M.stream_progress = 0

    -- Create and show the stream buffer
    local buf = M.get_stream_buffer()
    M.show_stream_buffer(buf, input)

    -- Get all buffers
    local buffers = M.get_all_buffers()
    if #buffers == 0 then
      print("No valid buffers found")
      return
    end

    -- Format context files
    local context_files = M.format_context_files(buffers)

    -- Format prompt with template
    local formatted_prompt = string.format(
      M.config.prompt_template,
      context_files,
      input
    )

    -- Prepare request
    local request_data = {
      model = M.current_model,
      prompt = formatted_prompt,
      sessionId = M.config.default_session_id,
      stream = true,
    }

    -- Set up temporary keymap for cancellation
    vim.keymap.set("n", M.config.keymaps.cancel, function()
      vim.api.nvim_exec_autocmds("User", { pattern = "Yeti_Cancel" })
    end, { noremap = true, silent = true })

    -- Start the streaming job
    M.active_job = Job:new({
      command = "curl",
      args = {
        "-N",
        "-X",
        "POST",
        "-H",
        "Content-Type: application/json",
        "-H",
        "Accept: text/event-stream",
        "--no-buffer",
        "-d",
        vim.json.encode(request_data),
        M.config.gateway_url .. "/call",
      },
      on_stdout = function(_, data)
        M.handle_stream_response(data)
      end,
      on_stderr = function(_, data)
        if data and data ~= "" then
          print("LLM Gateway error: " .. data)
        end
      end,
      on_exit = function()
        -- On completion, update the stream buffer
        vim.schedule(function()
          if M.current_response and M.current_response ~= "" then
            -- Clear progress indicator
            vim.cmd("echo ''")
            print("Response received")

            -- Add a final update to the stream buffer
            if M.stream_buffer and vim.api.nvim_buf_is_valid(M.stream_buffer) then
              M.update_stream_buffer(M.stream_buffer, M.current_response)

              -- Add completion message
              local lines = vim.api.nvim_buf_get_lines(M.stream_buffer, 0, -1, false)
              table.insert(lines, "")
              table.insert(lines, "# Processing Complete")
              table.insert(lines, "Response complete. You can now manually apply any changes.")
              vim.api.nvim_buf_set_lines(M.stream_buffer, 0, -1, false, lines)

              -- Scroll to the bottom
              if M.stream_window and vim.api.nvim_win_is_valid(M.stream_window) then
                vim.api.nvim_win_set_cursor(M.stream_window, {#lines, 0})
              end
            end
          end

          M.active_job = nil
          -- Restore default Esc behavior
          vim.keymap.del("n", M.config.keymaps.cancel)
          print("LLM request completed")
        end)
      end,
    })

    M.active_job:start()
    print("Sending request to LLM Gateway...")
  end)
end

-- Debug logging function
function M.log_debug(message)
  if M.config.debug then
    print("[YETI DEBUG] " .. message)
  end
end

-- Log table contents for debugging
function M.log_table(tbl, indent)
  if not M.config.debug then
    return
  end

  indent = indent or ""
  print(indent .. "{")
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      print(indent .. "  " .. tostring(k) .. " = ")
      M.log_table(v, indent .. "  ")
    else
      print(indent .. "  " .. tostring(k) .. " = " .. tostring(v))
    end
  end
  print(indent .. "}")
end

-- Function to save debug info to a file
function M.save_debug_info(response)
  if not M.config.debug then
    return
  end

  local timestamp = os.date("%Y%m%d-%H%M%S")
  local debug_dir = vim.fn.stdpath("cache") .. "/yeti"

  -- Create debug directory if it doesn't exist
  vim.fn.mkdir(debug_dir, "p")

  -- Save response to debug file
  local debug_file = debug_dir .. "/response-" .. timestamp .. ".txt"
  local file = io.open(debug_file, "w")
  if file then
    file:write("=== ORIGINAL RESPONSE ===\n")
    file:write(response .. "\n\n")
    file:close()
    print("[YETI DEBUG] Saved debug info to: " .. debug_file)
  else
    print("[YETI DEBUG] Failed to save debug info")
  end
end

-- Create plugin commands
function M.create_commands()
  vim.api.nvim_create_user_command("YetiSelectModel", function()
    M.select_model()
  end, { desc = "Select LLM model for Yeti" })

  vim.api.nvim_create_user_command("YetiSendBuffers", function()
    M.send_buffers()
  end, { desc = "Send all buffers to LLM Gateway" })

  vim.api.nvim_create_user_command("YetiRefreshModels", function()
    M.fetch_models()
  end, { desc = "Refresh available LLM models for Yeti" })
end

-- Initialize the plugin
function M.setup(opts)
  -- Merge config with provided options
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  -- Create augroup for the plugin
  M.augroup = vim.api.nvim_create_augroup("Yeti", { clear = true })

  -- Set up cancel autocmd
  vim.api.nvim_create_autocmd("User", {
    group = M.augroup,
    pattern = "Yeti_Cancel",
    callback = function()
      if M.active_job then
        M.active_job:shutdown()
        print("LLM request cancelled")
        M.active_job = nil
      end
    end,
  })

  -- Create commands
  M.create_commands()

  -- Set up keymaps
  if M.config.keymaps and M.config.keymaps.send_buffers then
    vim.api.nvim_set_keymap("n", M.config.keymaps.send_buffers, ":YetiSendBuffers<CR>",
      { noremap = true, silent = true, desc = "Send all buffers to LLM" })
  end

  -- Fetch available models on startup
  M.fetch_models()
end

return M