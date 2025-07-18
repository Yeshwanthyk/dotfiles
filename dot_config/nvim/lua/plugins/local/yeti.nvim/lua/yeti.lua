local M = {}
local Job = require("plenary.job")
local curl = require("plenary.curl")

-- Plugin configuration with defaults
M.config = {
  gateway_url = "http://localhost:3009",
  default_session_id = "neovim-session",
  debug = true, -- Set to true to enable debug logging (temporary change for troubleshooting)
  keymaps = {
    send_buffers = "<leader>ab", -- Send all buffers to LLM
    cancel = "<Esc>", -- Cancel ongoing LLM request
  },
  prompt_template = [[
You are an expert programming helper.

The context will include the *latest version* of the files throughout the session. The person you are speaking to is incredibly skilled. He knows what he is doing.
When you want to edit files; you **must** show the change in the following special format.

## The special code editing format
- Uses **file blocks**
- Each distinct block should be returned in a code block
- Starts with "... ", and then the filename
- Ends with "..."
- Uses **search and replace** blocks
  - Uses "<<<<<< SEARCH" to find the original lines to replace
  - Continues to "======",
  - Immediately follows to contain what to replace the code with
  - Finally, ends with ">>>>>> REPLACE"
- For each file edited, there can be multiple search and replace commands
- The `<<<<<< SEARCH` block must contain the *exact, verbatim* lines from the original file that you want to replace, including all indentation and any intermediate blank lines.
- Do not guess or abbreviate the content for the `SEARCH` block; copy it precisely from the provided context.
- Do not show SEARCH/REPLACE blocks for files that do not exist.
- Ensure the `<<<<<<< SEARCH` line uses **exactly 6 `<` characters** (no more, no less).
- The `======` separator must be on a line by itself.
- The `>>>>>>> REPLACE` line must use **exactly 6 `>` characters**.

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

-- Spinner frames for progress indication
local spinner_frames = { "(๑• ◡• )", "(づ｡◕‿‿◕｡)づ", "✩°｡⋆⸜(｡•ω•｡)" }
local current_spinner_frame = 1

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
          content = table.concat(lines, "\n"),
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
  vim.cmd("botright vsplit")

  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  --   vim.api.nvim_win_set_width(win, 80) -- Set width for vertical split
  --   vim.api.nvim_win_set_height(win, 20) -- Increased height to show more content

  -- Set initial content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    "# Request: " .. prompt,
    "",
    "# Response:",
    "Waiting for response...",
  })

  -- Set buffer local keymaps for convenience
  -- Removed 'q' and '<Esc>' keymaps as requested

  -- Add a keybinding for applying ALL parsed patches from the buffer
  vim.api.nvim_buf_set_keymap(
    buf,
    "n",
    "<leader>aA", -- Apply All
    ":lua require('yeti').apply_all_patches()<CR>",
    { noremap = true, silent = true, desc = "Apply all patches from buffer" }
  )

  -- Add a header with instructions
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, 1, "Press <leader>aA to apply all detected patches.")
  table.insert(lines, 2, "")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Store window reference
  M.stream_window = win

  -- Return to previous window
  -- vim.cmd("wincmd p") -- Removed to keep focus on the new split

  return win
end

-- Update stream buffer with content
function M.update_stream_buffer(buf, content)
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local lines = vim.split(content, "\n")

    -- Keep the request line at the top
    local request_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    local all_lines = { request_line, "", "# Response:" }

    -- Process each line to ensure proper code block formatting
    for _, line in ipairs(lines) do
      -- Handle special code block markers if needed
      table.insert(all_lines, line)
    end

    -- Update the buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_lines)

    -- Auto-scroll to the bottom if window exists
    if M.stream_window and vim.api.nvim_win_is_valid(M.stream_window) then
      vim.api.nvim_win_set_cursor(M.stream_window, { #all_lines, 0 })
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
        -- Update spinner animation
        current_spinner_frame = (current_spinner_frame % #spinner_frames) + 1
        local frame = spinner_frames[current_spinner_frame]
        vim.cmd("echo 'Yeti generating... " .. frame .. "'")
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
        print("LLM Gateway: Fetched available models. Default: " .. (data.default or "N/A"))
      else
        print("LLM Gateway: Failed to fetch models")
      end
    end,
  })
end

-- Main function to send all buffers to LLM
function M.send_buffers()
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
    local formatted_prompt = string.format(M.config.prompt_template, context_files, input)

    -- Prepare request - use the cached model (will be updated by fetch_models at startup)
    local request_data = {
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
        "-s", -- Add silent flag
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
              table.insert(lines, "Response complete. Review the changes above.")
              table.insert(lines, "You can edit the response buffer directly.")
              table.insert(lines, "Press <leader>aA to apply all detected patches.")
              vim.api.nvim_buf_set_lines(M.stream_buffer, 0, -1, false, lines)

              -- Scroll to the bottom
              if M.stream_window and vim.api.nvim_win_is_valid(M.stream_window) then
                vim.api.nvim_win_set_cursor(M.stream_window, { #lines, 0 })
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

-- Robust replacer functions for flexible matching
local function simple_replacer(content_lines, find_lines)
  local results = {}
  local content_str = table.concat(content_lines, "\n")
  local find_str = table.concat(find_lines, "\n")
  
  if content_str:find(find_str, 1, true) then
    table.insert(results, {start_line = 1, end_line = #content_lines, match_lines = find_lines})
  end
  
  return results
end

local function line_trimmed_replacer(content_lines, find_lines)
  local results = {}
  
  -- Remove empty lines at the end of find_lines
  while #find_lines > 0 and find_lines[#find_lines] == "" do
    table.remove(find_lines)
  end
  
  if #find_lines == 0 then
    return results
  end
  
  for i = 1, #content_lines - #find_lines + 1 do
    local matches = true
    
    for j = 1, #find_lines do
      local content_trimmed = content_lines[i + j - 1]:match("^%s*(.-)%s*$")
      local find_trimmed = find_lines[j]:match("^%s*(.-)%s*$")
      
      if content_trimmed ~= find_trimmed then
        matches = false
        break
      end
    end
    
    if matches then
      table.insert(results, {
        start_line = i,
        end_line = i + #find_lines - 1,
        match_lines = {}
      })
      -- Copy the actual lines from content
      for j = 1, #find_lines do
        table.insert(results[#results].match_lines, content_lines[i + j - 1])
      end
    end
  end
  
  return results
end

local function block_anchor_replacer(content_lines, find_lines)
  local results = {}
  
  if #find_lines < 3 then
    return results
  end
  
  -- Remove empty lines at the end
  while #find_lines > 0 and find_lines[#find_lines] == "" do
    table.remove(find_lines)
  end
  
  if #find_lines < 3 then
    return results
  end
  
  local first_line_find = find_lines[1]:match("^%s*(.-)%s*$")
  local last_line_find = find_lines[#find_lines]:match("^%s*(.-)%s*$")
  
  -- Find blocks where first line matches
  for i = 1, #content_lines do
    if content_lines[i]:match("^%s*(.-)%s*$") == first_line_find then
      -- Look for matching last line
      for j = i + 2, #content_lines do
        if content_lines[j]:match("^%s*(.-)%s*$") == last_line_find then
          table.insert(results, {
            start_line = i,
            end_line = j,
            match_lines = {}
          })
          -- Copy the actual lines from content
          for k = i, j do
            table.insert(results[#results].match_lines, content_lines[k])
          end
          break
        end
      end
    end
  end
  
  return results
end

local function whitespace_normalized_replacer(content_lines, find_lines)
  local results = {}
  
  local function normalize_whitespace(text)
    return text:gsub("%s+", " "):match("^%s*(.-)%s*$")
  end
  
  local normalized_find = {}
  for _, line in ipairs(find_lines) do
    table.insert(normalized_find, normalize_whitespace(line))
  end
  
  -- Handle single line matches
  if #find_lines == 1 then
    local normalized_find_line = normalized_find[1]
    for i, line in ipairs(content_lines) do
      if normalize_whitespace(line) == normalized_find_line then
        table.insert(results, {
          start_line = i,
          end_line = i,
          match_lines = {line}
        })
      end
    end
  else
    -- Handle multi-line matches
    for i = 1, #content_lines - #find_lines + 1 do
      local matches = true
      
      for j = 1, #find_lines do
        if normalize_whitespace(content_lines[i + j - 1]) ~= normalized_find[j] then
          matches = false
          break
        end
      end
      
      if matches then
        table.insert(results, {
          start_line = i,
          end_line = i + #find_lines - 1,
          match_lines = {}
        })
        -- Copy the actual lines from content
        for j = 1, #find_lines do
          table.insert(results[#results].match_lines, content_lines[i + j - 1])
        end
      end
    end
  end
  
  return results
end

local function indentation_flexible_replacer(content_lines, find_lines)
  local results = {}
  
  local function remove_common_indentation(lines)
    local non_empty_lines = {}
    for _, line in ipairs(lines) do
      if line:match("^%s*$") == nil then
        table.insert(non_empty_lines, line)
      end
    end
    
    if #non_empty_lines == 0 then
      return lines
    end
    
    -- Find minimum indentation
    local min_indent = math.huge
    for _, line in ipairs(non_empty_lines) do
      local indent = line:match("^(%s*)"):len()
      min_indent = math.min(min_indent, indent)
    end
    
    if min_indent == math.huge or min_indent == 0 then
      return lines
    end
    
    -- Remove common indentation
    local result = {}
    for _, line in ipairs(lines) do
      if line:match("^%s*$") then
        table.insert(result, line)
      else
        table.insert(result, line:sub(min_indent + 1))
      end
    end
    
    return result
  end
  
  local normalized_find = remove_common_indentation(find_lines)
  
  for i = 1, #content_lines - #find_lines + 1 do
    local block = {}
    for j = 1, #find_lines do
      table.insert(block, content_lines[i + j - 1])
    end
    
    local normalized_block = remove_common_indentation(block)
    
    -- Compare normalized versions
    local matches = true
    if #normalized_block == #normalized_find then
      for j = 1, #normalized_find do
        if normalized_block[j] ~= normalized_find[j] then
          matches = false
          break
        end
      end
    else
      matches = false
    end
    
    if matches then
      table.insert(results, {
        start_line = i,
        end_line = i + #find_lines - 1,
        match_lines = block
      })
    end
  end
  
  return results
end

-- Try multiple replacer strategies to find a match
local function find_match_with_replacers(content_lines, find_lines)
  local replacers = {
    simple_replacer,
    line_trimmed_replacer,
    block_anchor_replacer,
    whitespace_normalized_replacer,
    indentation_flexible_replacer,
  }
  
  for _, replacer in ipairs(replacers) do
    local results = replacer(content_lines, find_lines)
    if #results > 0 then
      -- Return the first match found
      return results[1]
    end
  end
  
  return nil
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

-- Parse LLM response text to extract structured patches
-- Revised parser to correctly handle multiple patches per file block
function M.parse_llm_response(response_content)
  M.log_debug("Starting to parse LLM response for patches (Revised Logic).")
  local patches = {}
  local lines

  if type(response_content) == "string" then
    lines = vim.split(response_content, "\\n")
  elseif type(response_content) == "table" then
    lines = response_content
  else
    M.log_debug("Invalid response_content type: " .. type(response_content))
    return patches -- Return empty list if input is invalid
  end

  local current_filepath = nil
  local current_old_hunk = nil
  local current_new_hunk = nil
  -- States: idle, in_file, in_search, in_replace
  local state = "idle"

  for i, line in ipairs(lines) do
    M.log_debug(string.format("Parse Line %d [%s]: %s", i, state, line))

    if state == "idle" then
      local filepath_match = line:match("^%.%.%.%s*(.+)$")
      if filepath_match then
        current_filepath = filepath_match:match("^%s*(.-)%s*$") -- Trim whitespace
        state = "in_file"
        M.log_debug("Found file start: '" .. current_filepath .. "'")
      end
    elseif state == "in_file" then
      if line:match("^<<<<<< SEARCH") then
        current_old_hunk = {}
        state = "in_search"
        M.log_debug("Found SEARCH start")
      elseif line:match("^%.%.%.$") then -- End of file block
        M.log_debug("Found end of file block for: '" .. (current_filepath or "nil") .. "'")
        current_filepath = nil
        state = "idle"
      end
      -- Ignore other lines when just in file block (e.g., blank lines between patches)
    elseif state == "in_search" then
      if line:match("^======") then
        current_new_hunk = {}
        state = "in_replace"
        M.log_debug("Found separator (======)")
      else
        table.insert(current_old_hunk, line)
      end
    elseif state == "in_replace" then
      -- Check for the end-of-patch marker "..." FIRST
      if line:match("^%.%.%.$") then
        -- Finalize the current patch
        if current_filepath and current_old_hunk and current_new_hunk then
          table.insert(patches, {
            filepath = current_filepath,
            old_hunk = current_old_hunk,
            new_hunk = current_new_hunk,
          })
          M.log_debug(
            string.format(
              "Stored patch for %s: %d old lines, %d new lines. State -> in_file",
              current_filepath,
              #current_old_hunk,
              #current_new_hunk
            )
          )
        else
          M.log_debug("Tried to finalize patch but some data was missing. State -> in_file")
        end
        -- Reset hunks and go back to in_file state, ready for next SEARCH or file end
        current_old_hunk = nil
        current_new_hunk = nil
        state = "in_file"
      -- Check for start of replace content marker >>>>>> REPLACE
      -- This marker *should* technically only appear once right after ====== according to format
      -- but we capture content *after* it until the '...' line.
      elseif line:match("^>>>>>> REPLACE") then
        -- This line itself isn't content, just marks the start. Do nothing here.
        M.log_debug("Found REPLACE marker")
      else
        -- This line is part of the replacement content
        if current_new_hunk ~= nil then
          table.insert(current_new_hunk, line)
        else
          -- This case should not happen if the format is strictly followed (====== then >>>>>> REPLACE)
          M.log_debug("Warning: Adding line to new_hunk in 'in_replace' state, but saw no >>>>>> REPLACE yet: " .. line)
          current_new_hunk = { line } -- Initialize defensively
        end
      end
    end
  end

  -- End of loop checks (e.g., if file ends mid-patch)
  if state ~= "idle" and state ~= "in_file" then
    M.log_debug(
      "Warning: Response ended unexpectedly in state: " .. state .. " for file " .. (current_filepath or "nil")
    )
    -- Decide if we should store a potentially incomplete patch? For now, no.
  end

  M.log_debug("Finished parsing. Found " .. #patches .. " total patches.")
  if M.config.debug and #patches > 0 then
    for i, patch in ipairs(patches) do
      print(
        string.format(
          "[YETI DEBUG] Parsed Patch %d: %s (%d old, %d new)",
          i,
          patch.filepath,
          #patch.old_hunk,
          #patch.new_hunk
        )
      )
    end
  end
  return patches
end

-- Apply all patches parsed from the stream buffer
function M.apply_all_patches()
  M.log_debug("Starting apply_all_patches")

  if not M.stream_buffer or not vim.api.nvim_buf_is_valid(M.stream_buffer) then
    vim.notify("Stream buffer is not available or invalid.", vim.log.levels.ERROR)
    return
  end

  -- Get content from the stream buffer (user might have edited it)
  local stream_lines = vim.api.nvim_buf_get_lines(M.stream_buffer, 0, -1, false)
  M.log_debug("Got " .. #stream_lines .. " lines from stream buffer.")

  -- Parse the patches from the buffer content
  local all_patches = M.parse_llm_response(stream_lines)

  if #all_patches == 0 then
    vim.notify("No patches found in the stream buffer to apply.", vim.log.levels.WARN)
    return
  end

  -- Group patches by filepath
  local patches_by_file = {}
  for _, patch in ipairs(all_patches) do
    local path = vim.fn.expand(patch.filepath) -- Expand path relative to CWD
    patches_by_file[path] = patches_by_file[path] or {}
    table.insert(patches_by_file[path], patch)
  end

  local applied_count = 0
  local failed_count = 0
  local errors = {}
  local original_buf = vim.api.nvim_get_current_buf()
  local modified_buffers = {}

  for filepath, file_patches in pairs(patches_by_file) do
    M.log_debug(string.format("Processing %d patches for file: %s", #file_patches, filepath))

    -- Load the buffer for the file
    local buf = vim.fn.bufadd(filepath)
    local previous_buf = vim.api.nvim_get_current_buf()
    local file_opened_successfully = false
    if not vim.api.nvim_buf_is_loaded(buf) then
      vim.cmd("silent! edit " .. vim.fn.fnameescape(filepath))
      buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_get_name(buf) == filepath then
        file_opened_successfully = true
      end
    else
      -- Switch to the buffer if it was already loaded but not current
      if buf ~= previous_buf then
        vim.api.nvim_set_current_buf(buf)
      end
      file_opened_successfully = true
    end

    if not file_opened_successfully then
      M.log_debug(string.format("Failed to load or create buffer for %s", filepath))
      table.insert(errors, string.format("Failed to load/create buffer for %s", filepath))
      failed_count = failed_count + #file_patches -- Count all patches for this file as failed
      -- Switch back if we changed buffer
      if previous_buf ~= buf and vim.api.nvim_buf_is_valid(previous_buf) then
        vim.api.nvim_set_current_buf(previous_buf)
      end
      goto continue_file_loop -- Skip to the next file
    end

    local target_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local patches_with_locations = {}
    local file_had_errors = false

    -- 1. Find original locations for all patches in this file
    for i, patch in ipairs(file_patches) do
      local start_i, end_i
      local is_creation = (#patch.old_hunk == 0)

      if is_creation then
        start_i = 0 -- Apply creations/insertions at the beginning
        M.log_debug(string.format("Patch %d: Marked as creation/insertion at line 0", i))
      else
        -- Use robust replacer strategies to find the match
        local match_result = find_match_with_replacers(target_lines, patch.old_hunk)
        if match_result then
          start_i = match_result.start_line - 1 -- Convert to 0-indexed
          M.log_debug(string.format("Patch %d: Found original hunk at line %d (0-indexed) using robust matching", i, start_i))
        else
          M.log_debug(string.format("Patch %d: Old hunk not found in original content of %s", i, filepath))
          table.insert(errors, string.format("Patch %d: Old hunk not found in %s", i, filepath))
          failed_count = failed_count + 1
          file_had_errors = true
          goto continue_patch_loop -- Skip this patch
        end
      end
      patch.original_start_line = start_i -- Store the found location
      table.insert(patches_with_locations, patch)
      ::continue_patch_loop::
    end

    -- 2. Sort patches by original location descending (bottom-up)
    table.sort(patches_with_locations, function(a, b)
      return a.original_start_line > b.original_start_line
    end)

    -- 3. Apply sorted patches to the buffer
    local buffer_modified = false
    for i, patch in ipairs(patches_with_locations) do
      local start_line = patch.original_start_line
      local end_line = start_line + #patch.old_hunk
      M.log_debug(string.format("Applying patch %d (originally line %d) to %s", i, start_line, filepath))

      local success, err = pcall(vim.api.nvim_buf_set_lines, buf, start_line, end_line, false, patch.new_hunk)
      if success then
        M.log_debug("Applied patch successfully to buffer.")
        applied_count = applied_count + 1
        buffer_modified = true
      else
        M.log_debug("Failed to apply patch: " .. tostring(err))
        table.insert(
          errors,
          string.format("Failed applying patch originally at line %d to %s: %s", start_line, filepath, tostring(err))
        )
        failed_count = failed_count + 1
        file_had_errors = true
      end
    end

    -- 4. Save the buffer if it was modified and had no errors during application
    if buffer_modified then
      modified_buffers[buf] = filepath -- Mark buffer for saving
    end

    -- Switch back to the previous buffer if we changed
    if previous_buf ~= buf and vim.api.nvim_buf_is_valid(previous_buf) then
      vim.api.nvim_set_current_buf(previous_buf)
    end

    ::continue_file_loop:: -- Label for file loop goto
  end

  -- Save all modified buffers
  for buf, filepath in pairs(modified_buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      local current_buf_before_save = vim.api.nvim_get_current_buf()
      vim.api.nvim_set_current_buf(buf) -- Switch to buffer to save it
      local write_success, write_err = pcall(vim.cmd, "write")
      if write_success then
        M.log_debug("Saved buffer " .. filepath)
      else
        M.log_debug("Failed to save buffer " .. filepath .. ": " .. tostring(write_err))
        table.insert(errors, string.format("Failed to save %s: %s", filepath, tostring(write_err)))
        -- If save failed, maybe increment failed_count? Depends if patches were counted already.
        -- Let's not double-count for now.
      end
      -- Switch back
      if vim.api.nvim_buf_is_valid(current_buf_before_save) then
        vim.api.nvim_set_current_buf(current_buf_before_save)
      end
    else
      M.log_debug("Buffer for " .. filepath .. " became invalid before saving.")
      table.insert(errors, string.format("Buffer for %s became invalid before saving", filepath))
    end
  end

  -- Restore original buffer if it's still valid
  if vim.api.nvim_buf_is_valid(original_buf) and vim.api.nvim_get_current_buf() ~= original_buf then
    vim.api.nvim_set_current_buf(original_buf)
  end

  -- Report results
  local final_message =
    string.format("Attempted %d patches. Applied: %d, Failed: %d.", #all_patches, applied_count, failed_count)
  if failed_count > 0 then
    vim.notify(final_message .. " Errors:\n" .. table.concat(errors, "\n"), vim.log.levels.ERROR)
  elseif applied_count > 0 then
    vim.notify(final_message, vim.log.levels.INFO)
  else
    -- No patches applied and no failures probably means old hunks weren't found or other pre-apply errors
    if #errors > 0 then
      vim.notify(final_message .. " Errors:\n" .. table.concat(errors, "\n"), vim.log.levels.WARN)
    else
      vim.notify("No patches were applied.", vim.log.levels.WARN) -- Should not happen if patches were parsed
    end
  end
  M.log_debug("Finished apply_all_patches.")
end

-- Create plugin commands
function M.create_commands()
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
    vim.api.nvim_set_keymap(
      "n",
      M.config.keymaps.send_buffers,
      ":YetiSendBuffers<CR>",
      { noremap = true, silent = true, desc = "Send all buffers to LLM" }
    )
  end

  -- Fetch available models on startup
  M.fetch_models()
end

return M
