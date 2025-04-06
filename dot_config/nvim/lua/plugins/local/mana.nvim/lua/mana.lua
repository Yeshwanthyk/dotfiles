local Job = require("plenary.job")
local M = {}

-- Module-level variables
local current_model_cfg
local model_cfgs
local endpoint_cfgs

---@class Mana.EndpointConfig
---@field url string
---@field api_key string

---@class Mana.EndpointConfigs
---@field [string] Mana.EndpointConfig

---@class Mana.MmodelConfig
---@field endpoint string
---@field name string
---@field system_prompt string
---@field temperature number
---@field top_p number
---@field fetcher Mana.Fetcher
---@field display_name? string  -- Add this line for the optional display name

---@alias Mana.Prefetcher fun(
--- model_name: string,
--- endpoint_cfg: Mana.EndpointConfig): Mana.Fetcher
---@alias Mana.Fetcher fun(messages: Mana.Messages)

---@class Mana.ModelConfigs
---@field [string] Mana.ModelConfig

---@class Mana.ContentItem
---@field type "text"
---@field text string

---@class Mana.Message
---@field role "user" | "assistant" | "system"
---@field content Mana.ContentItem[]

---@alias Mana.Messages Mana.Message[]

-- // WINDOW+BUFFER STUFFS --

---move cursor down to "textbox"
---@param bufnr integer
---@return nil
local function buffer_cursor_down(bufnr)
  local line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.api.nvim_command("startinsert")
end

---
---@param bufnr integer
---@return nil
local function yank_code_block(bufnr)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  -- Find the start of the code block
  local start_block = line_num
  while start_block > 1 do
    if lines[start_block]:match("^```") then
      break
    end
    start_block = start_block - 1
  end

  -- Find the end of the code block
  local end_block = line_num
  while end_block < #lines do
    if lines[end_block]:match("^```") then
      break
    end
    end_block = end_block + 1
  end

  -- Validate we found a complete code block
  if not lines[start_block]:match("^```") or not lines[end_block]:match("^```") then
    vim.notify("Not inside a code block", vim.log.levels.WARN)
    return
  end

  -- Extract the code content (excluding the ``` markers)
  local code_lines = {}
  for i = start_block + 1, end_block - 1 do
    table.insert(code_lines, lines[i])
  end

  -- Join lines and yank to register
  local code_content = table.concat(code_lines, "\n")
  vim.fn.setreg('"', code_content)
  vim.notify("Code block yanked to clipboard", vim.log.levels.INFO)
end

---gets existing buffer, if not exist create new one
---@return integer -- bufnr
local function buffer_get()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("mana$") then
      vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
      return buf -- existing bufnr
    end
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "mana")
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("tabstop", 2, { buf = bufnr })
  vim.api.nvim_set_option_value("shiftwidth", 2, { buf = bufnr })
  vim.api.nvim_set_option_value("expandtab", true, { buf = bufnr })
  vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = bufnr }))
  return bufnr -- create new buffer, return bufnr
end

---@param chunk string
---@param bufnr integer
---@return nil
local function buffer_append(chunk, bufnr)
  local last_line = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1] or ""
  local lines = vim.split(last_line .. chunk, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, lines)
end

---@param bufnr integer
---@return Mana.Messages
local function buffer_parse(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local messages = {}
  local current_role = "user"
  local current_text = {}

  local function add_message()
    if #current_text > 0 then
      local combined_text = table.concat(current_text, "\n")
      table.insert(messages, {
        role = current_role,
        content = {
          { type = "text", text = combined_text },
        },
      })
    end
  end

  for _, line in ipairs(lines) do
    if line == "<assistant>" then
      add_message()
      current_role = "assistant"
      current_text = {}
    elseif line == "</assistant>" then
      add_message()
      current_role = "user"
      current_text = {}
    elseif vim.trim(line) ~= "" then
      table.insert(current_text, vim.trim(line))
    end
  end
  add_message() -- add the last message
  return messages
end

---@param bufnr integer
---@return integer winid
local function window_create(bufnr)
  vim.cmd("topleft vsplit")
  local winid = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(winid, bufnr)
  vim.api.nvim_win_set_width(winid, 65)
  vim.api.nvim_set_option_value("number", true, { win = winid })
  vim.api.nvim_set_option_value("relativenumber", true, { win = winid })
  vim.api.nvim_set_option_value("winfixwidth", true, { win = winid })
  vim.api.nvim_set_option_value("wrap", true, { win = winid })
  vim.api.nvim_set_option_value("linebreak", true, { win = winid })
  vim.api.nvim_set_option_value("colorcolumn", "", { win = winid })
  vim.api.nvim_create_autocmd("WinResized", {
    callback = function()
      if vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_set_width(winid, 65)
      end
    end,
  })
  return winid
end

---@param bufnr integer
---@return nil
local function send_buffers_to_chat(bufnr)
  local buffers = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      buf ~= bufnr
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.api.nvim_buf_get_name(buf) ~= ""
      and vim.api.nvim_buf_get_option(buf, "buftype") == ""
    then
      table.insert(buffers, buf)
    end
  end

  local tree = { "# File Tree" }
  local seen_paths = {}
  local files = {}

  for _, buf in ipairs(buffers) do
    local path = vim.api.nvim_buf_get_name(buf)
    local parts = vim.split(vim.fn.fnamemodify(path, ":~:."), "/", { plain = true })

    local current_path = ""
    for i, part in ipairs(parts) do
      current_path = current_path .. "/" .. part
      if i < #parts then
        if not seen_paths[current_path] then
          local indent = string.rep("│   ", i - 1)
          table.insert(tree, indent .. "├── " .. part)
          seen_paths[current_path] = true
        end
      else
        local indent = string.rep("│   ", #parts - 1)
        table.insert(tree, indent .. "└── " .. part)
        files[buf] = parts[#parts]
      end
    end
  end

  local buffer_contents = { "\n" .. table.concat(tree, "\n") .. "\n" }
  for _, buf in ipairs(buffers) do
    local filename = files[buf] or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, "\n")
    table.insert(buffer_contents, string.format("\nFile: %s\n```\n%s\n```\n", filename, content))
  end

  if #buffers > 0 then
    buffer_append("\n" .. table.concat(buffer_contents, "\n") .. "\n\n", bufnr)
  else
    buffer_append("\nNo valid buffer files found.\n\n", bufnr)
  end
end

-- // CHAT STUFFS --

---@param model_cfg Mana.ModelConfig
---@param bufnr integer
---@return nil
local function keymap_set_chat(model_cfg, bufnr)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
    callback = function()
      local messages = buffer_parse(bufnr)
      if #messages == 0 then
        print("empty input")
        return
      end
      if messages then
        if model_cfg.system_prompt and model_cfg.system_prompt ~= "" then
          table.insert(messages, 1, {
            role = "system",
            content = { { type = "text", text = model_cfg.system_prompt } },
          })
        end
        buffer_append("\n\n<assistant>\n\n", bufnr)
        model_cfg.fetcher(messages)
      end
    end,
    noremap = true,
    silent = true,
  })
end

---@param model_cfgs Mana.ModelConfigs
---@return fun(winid:integer, bufnr:integer)
local function model_switch(model_cfgs)
  return function(winid, bufnr)
    local display_to_cfg = {}
    local displays = {}
    for _, cfg in pairs(model_cfgs) do
      local display = cfg.display_name or string.format("%s@%s", cfg.endpoint, cfg.name)
      display_to_cfg[display] = cfg
      table.insert(displays, display)
    end
    vim.ui.select(displays, {
      prompt = "Mana switch model",
    }, function(selected)
      if not selected then
        return
      end
      local cfg = display_to_cfg[selected]
      current_model_cfg = cfg -- Update current model
      local winbar = string.format("%%=" .. (cfg.display_name or string.format("%s@%s", cfg.endpoint, cfg.name)))
      keymap_set_chat(cfg, bufnr)
      vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
    end)
  end
end

---mk_prefetcher(callback)(configs)(messages)
---prefetcher = mk_prefetcher(callback)
---fetcher = prefetcher(configs)
---call fetcher(messages) to chat with llm
---@param stdout_callback function
---@return Mana.Prefetcher
local function mk_prefetcher(stdout_callback)
  return function(model_name, endpoint_cfg)
    return function(messages)
      local request_body = {
        model = model_name,
        messages = messages,
        stream = true,
      }

      ---@diagnostic disable: missing-fields
      Job:new({
        command = "curl",
        args = {
          "-s",
          endpoint_cfg.url,
          "-H",
          "Content-Type: application/json",
          "-H",
          "Authorization: Bearer " .. endpoint_cfg.api_key,
          "--no-buffer",
          "-d",
          vim.json.encode(request_body),
        },
        on_stdout = stdout_callback,
      }):start()
    end
  end
end

-- Function to create a fetcher with a custom stdout callback
local function create_fetcher(model_cfg, endpoint_cfgs, stdout_callback)
  local endpoint_cfg = endpoint_cfgs[model_cfg.endpoint]
  return function(messages)
    local request_body = {
      model = model_cfg.name,
      messages = messages,
      stream = true,
    }
    Job:new({
      command = "curl",
      args = {
        "-s",
        endpoint_cfg.url,
        "-H",
        "Content-Type: application/json",
        "-H",
        "Authorization: Bearer " .. endpoint_cfg.api_key,
        "--no-buffer",
        "-d",
        vim.json.encode(request_body),
      },
      on_stdout = stdout_callback,
    }):start()
  end
end

-- Function to create a callback for inserting streamed data into a specific buffer and window
local function mk_insert_callback(bufnr, winid)
  local insert_row, insert_col = vim.api.nvim_win_get_cursor(winid)[1] - 1, vim.api.nvim_win_get_cursor(winid)[2]
  return function(_, data)
    for line in data:gmatch("[^\r\n]+") do
      if line:match("^data: ") then
        if line:match("data: %[DONE%]") then
          -- Streaming complete
        else
          local json_str = line:sub(7)
          local ok, decoded = pcall(vim.json.decode, json_str)
          if ok and decoded and decoded.choices then
            for _, choice in ipairs(decoded.choices) do
              if choice.delta and choice.delta.content then
                local content = choice.delta.content
                vim.schedule(function()
                  local lines = vim.split(content, "\n", { plain = true })
                  if #lines == 1 then
                    vim.api.nvim_buf_set_text(bufnr, insert_row, insert_col, insert_row, insert_col, { lines[1] })
                    insert_col = insert_col + #lines[1]
                  else
                    vim.api.nvim_buf_set_text(bufnr, insert_row, insert_col, insert_row, insert_col, { lines[1] })
                    for i = 2, #lines - 1 do
                      vim.api.nvim_buf_set_lines(bufnr, insert_row + i - 1, insert_row + i - 1, false, { lines[i] })
                    end
                    if #lines > 1 then
                      vim.api.nvim_buf_set_lines(
                        bufnr,
                        insert_row + #lines - 1,
                        insert_row + #lines - 1,
                        false,
                        { lines[#lines] }
                      )
                    end
                    insert_row = insert_row + #lines - 1
                    insert_col = #lines[#lines]
                  end
                  vim.api.nvim_win_set_cursor(winid, { insert_row + 1, insert_col })
                end)
              end
            end
          end
        end
      end
    end
  end
end

---@param bufnr integer
---@return fun(_, data) -- callback, to be passed to curl
local function mk_stdout_callback(bufnr)
  return function(_, data)
    for line in data:gmatch("[^\r\n]+") do
      if line:match("^data: ") then
        if line:match("data: %[DONE%]") then
          vim.schedule(function()
            buffer_append("\n</assistant>\n", bufnr)
          end)
        else
          local json_str = line:sub(7)
          local ok, decoded = pcall(vim.json.decode, json_str)
          if ok and decoded and decoded.choices then
            for _, choice in ipairs(decoded.choices) do
              if choice.delta and choice.delta.content then
                vim.schedule(function()
                  buffer_append(choice.delta.content, bufnr)
                end)
              end
            end
          end
        end
      else
        if data ~= ": OPENROUTER PROCESSING" then
          vim.schedule(function()
            buffer_append(data, bufnr)
          end)
        end
      end
    end
  end
end

-- // UI STUFFS --

local function command_set(model_switch_, winbar, winid, bufnr)
  vim.api.nvim_create_user_command("Mana", function(opts)
    local args = vim.split(opts.args, "%s+")
    local cmd = args[1]
    if cmd == "complete" then
      local current_bufnr = vim.api.nvim_get_current_buf()
      local current_winid = vim.api.nvim_get_current_win()
      local cursor_pos = vim.api.nvim_win_get_cursor(current_winid)
      local row, col = cursor_pos[1], cursor_pos[2]
      -- Get lines up to the cursor
      local lines = vim.api.nvim_buf_get_lines(current_bufnr, 0, row - 1, false)
      local current_line = vim.api.nvim_buf_get_lines(current_bufnr, row - 1, row, false)[1] or ""
      local prompt = table.concat(lines, "\n") .. (lines[1] and "\n" or "") .. current_line:sub(1, col)
      local messages = { { role = "user", content = { { type = "text", text = prompt } } } }
      if current_model_cfg.system_prompt then
        table.insert(
          messages,
          1,
          { role = "system", content = { { type = "text", text = current_model_cfg.system_prompt } } }
        )
      end
      local fetcher = create_fetcher(current_model_cfg, endpoint_cfgs, mk_insert_callback(current_bufnr, current_winid))
      fetcher(messages)
    elseif cmd == "replace" then
      if opts.range == 2 then -- Visual mode
        local start_row = opts.line1 - 1
        local end_row = opts.line2
        local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row, false)
        local prompt = table.concat(lines, "\n")
        -- Delete the selection
        vim.api.nvim_buf_set_lines(0, start_row, end_row, false, {})
        vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
        local current_bufnr = vim.api.nvim_get_current_buf()
        local current_winid = vim.api.nvim_get_current_win()
        local messages = { { role = "user", content = { { type = "text", text = prompt } } } }
        if current_model_cfg.system_prompt then
          table.insert(
            messages,
            1,
            { role = "system", content = { { type = "text", text = current_model_cfg.system_prompt } } }
          )
        end
        local fetcher =
          create_fetcher(current_model_cfg, endpoint_cfgs, mk_insert_callback(current_bufnr, current_winid))
        fetcher(messages)
      else
        vim.notify("Mana replace must be called with a visual selection", vim.log.levels.WARN)
      end
    elseif cmd == "open" then
      if not (winid and vim.api.nvim_win_is_valid(winid)) then
        winid = window_create(bufnr)
        buffer_cursor_down(bufnr)
        vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
      end
    elseif cmd == "close" then
      if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
        winid = nil
      end
    elseif cmd == "toggle" then
      if winid and vim.api.nvim_win_is_valid(winid) then
        vim.api.nvim_win_close(winid, true)
        winid = nil
      else
        winid = window_create(bufnr)
        buffer_cursor_down(bufnr)
        vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
      end
    elseif cmd == "clear" then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
      if winid and vim.api.nvim_win_is_valid(winid) and vim.api.nvim_get_current_win() == winid then
        buffer_cursor_down(bufnr)
      end
    elseif cmd == "paste" then
      local start = vim.fn.getpos("'<")[2]
      local end_ = vim.fn.getpos("'>")[2]
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(buf, start - 1, end_, false)
      local text = table.concat(lines, "\n")
      buffer_append("\n" .. text .. "\n\n", bufnr)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        winid = window_create(bufnr)
        buffer_cursor_down(bufnr)
        vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
      end
    elseif cmd == "switch" then
      if winid and vim.api.nvim_win_is_valid(winid) then
        model_switch_(winid, bufnr)
      else
        winid = window_create(bufnr)
        model_switch_(winid, bufnr)
      end
    elseif cmd == "buffers" then
      send_buffers_to_chat(bufnr)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        winid = window_create(bufnr)
        buffer_cursor_down(bufnr)
        vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
      end
    elseif cmd == "yank" then
      yank_code_block(bufnr)
    end
  end, {
    nargs = 1,
    range = true,
    complete = function()
      return { "open", "close", "toggle", "clear", "paste", "switch", "buffers", "yank", "complete", "replace" }
    end,
  })

  -- Add a keymap for easier code block yanking
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>y", "", {
    callback = function()
      yank_code_block(bufnr)
    end,
    noremap = true,
    silent = true,
  })
end

-- // OPTS PARSERS --

---@param endpoint_cfgs Mana.EndpointConfigs
---@param prefetcher Mana.Prefetcher
---@param raw any
---@return Mana.ModelConfigs|nil, string?
local function parse_opts_models(endpoint_cfgs, prefetcher, raw)
  if type(raw) ~= "table" then
    return nil, "models must be a table"
  end
  local parsed = {}
  for model_name, model_cfg in pairs(raw) do
    if type(model_cfg.endpoint) ~= "string" then
      return nil, string.format("model %s: endpoint must be a string", model_name)
    end
    if type(model_cfg.name) ~= "string" then
      return nil, string.format("model %s: name must be a string", model_name)
    end
    if type(model_cfg.system_prompt) ~= "string" then
      return nil, string.format("model %s: system_prompt must be a string", model_name)
    end
    if type(model_cfg.temperature) ~= "number" then
      return nil, string.format("model %s: temperature must be a number", model_name)
    end
    if type(model_cfg.top_p) ~= "number" then
      return nil, string.format("model %s: top_p must be a number", model_name)
    end
    local endpoint_cfg = endpoint_cfgs[model_cfg.endpoint]
    parsed[model_name] = {
      endpoint = model_cfg.endpoint,
      name = model_cfg.name,
      display_name = model_cfg.display_name, -- Add this line
      system_prompt = model_cfg.system_prompt,
      temperature = model_cfg.temperature,
      top_p = model_cfg.top_p,
      fetcher = prefetcher(model_cfg.name, endpoint_cfg),
    }
  end
  return parsed
end
---@param raw any
---@return Mana.EndpointConfigs|nil, string?
local function parse_opts_envs(raw)
  if type(raw) ~= "table" then
    return nil, "envs must be a table"
  end

  local urls = {
    aistudio = "https://generativelanguage.googleapis.com/v1beta/chat/completions",
    openrouter = "https://openrouter.ai/api/v1/chat/completions",
    deepseek = "https://api.deepseek.com/v1/chat/completions",
  }

  local parsed = {}
  for endpoint, env in pairs(raw) do
    if not urls[endpoint] then
      return nil, string.format("endpoint %s: invalid endpoint", endpoint)
    end

    if type(env) ~= "string" then
      return nil, string.format("endpoint %s: env must be a string", endpoint)
    end

    local api_key = os.getenv(env)
    if not api_key then
      local tmp = "endpoint %s: API key not found in environment variable %s"
      return nil, string.format(tmp, endpoint, env)
    end

    parsed[endpoint] = {
      url = urls[endpoint],
      api_key = api_key,
    }
  end

  return parsed
end

---@param model_cfgs Mana.ModelConfigs
---@param raw any
---@return Mana.ModelConfig|nil, string?
local function parse_opts_default_model(model_cfgs, raw)
  if type(raw) ~= "string" then
    return nil, "default_model must be a string"
  end

  if not model_cfgs[raw] then
    local tmp = "default model '%s' not found in keys of models table"
    return nil, string.format(tmp, raw)
  end

  return model_cfgs[raw]
end

-- // SETUP --

M.setup = function(opts)
  local bufnr = buffer_get()
  local winid = nil

  local stdout_callback = mk_stdout_callback(bufnr)
  local prefetcher = mk_prefetcher(stdout_callback)

  endpoint_cfgs, e_err = parse_opts_envs(opts.envs)
  if not endpoint_cfgs then
    vim.notify("Mana.nvim error: " .. e_err, vim.log.levels.ERROR)
    return
  end

  model_cfgs, m_err = parse_opts_models(endpoint_cfgs, prefetcher, opts.models)
  if not model_cfgs then
    vim.notify("Mana.nvim error: " .. m_err, vim.log.levels.ERROR)
    return
  end

  current_model_cfg, dm_err = parse_opts_default_model(model_cfgs, opts.default_model)
  if not current_model_cfg then
    vim.notify("Mana.nvim error: " .. dm_err, vim.log.levels.ERROR)
    return
  end

  local model_switch_ = model_switch(model_cfgs)
  local winbar = "%=" .. current_model_cfg.endpoint .. "@" .. current_model_cfg.name
  keymap_set_chat(current_model_cfg, bufnr)
  command_set(model_switch_, winbar, winid, bufnr)
end

return M
