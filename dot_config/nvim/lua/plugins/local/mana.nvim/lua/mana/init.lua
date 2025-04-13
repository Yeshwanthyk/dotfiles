local Job = require("plenary.job")

local M = {}

local current_model_cfg
local model_cfgs
local endpoint_cfgs

---@class Mana.EndpointConfig
---@field url string
---@field api_key string

---@alias Mana.EndpointConfigs table<string, Mana.EndpointConfig>

---@class Mana.ModelConfig
---@field endpoint string
---@field name string
---@field system_prompt string
---@field temperature number
---@field top_p number
---@field fetcher Mana.Fetcher
---@field display_name? string

---@alias Mana.ModelConfigs table<string, Mana.ModelConfig>

---@class Mana.ContentItem
---@field type "text"
---@field text string

---@class Mana.Message
---@field role "user" | "assistant" | "system"
---@field content Mana.ContentItem[]

---@alias Mana.Messages Mana.Message[]

---@alias Mana.Prefetcher fun(model_name: string, endpoint_cfg: Mana.EndpointConfig): Mana.Fetcher
---@alias Mana.Fetcher fun(messages: Mana.Messages)

local function buffer_cursor_down(bufnr)
  local line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.api.nvim_command("startinsert")
end

local function yank_code_block(bufnr)
  local line_num = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local start_block = line_num
  while start_block > 1 do
    if lines[start_block]:match("^```") then
      break
    end
    start_block = start_block - 1
  end
  local end_block = line_num
  while end_block < #lines do
    if lines[end_block]:match("^```") then
      break
    end
    end_block = end_block + 1
  end
  if not lines[start_block]:match("^```") or not lines[end_block]:match("^```") then
    vim.notify("Not inside a code block", vim.log.levels.WARN)
    return
  end
  local code_lines = {}
  for i = start_block + 1, end_block - 1 do
    table.insert(code_lines, lines[i])
  end
  local code_content = table.concat(code_lines, "\n")
  vim.fn.setreg('"', code_content)
  vim.notify("Code block yanked to clipboard", vim.log.levels.INFO)
end

local function buffer_get()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(buf):match("mana$") then
      vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
      return buf
    end
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(bufnr, "mana")
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("tabstop", 2, { buf = bufnr })
  vim.api.nvim_set_option_value("shiftwidth", 2, { buf = bufnr })
  vim.api.nvim_set_option_value("expandtab", true, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
  vim.lsp.stop_client(vim.lsp.get_clients({ bufnr = bufnr }))
  return bufnr
end

local function buffer_append(chunk, bufnr)
  local last_line = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1] or ""
  local lines = vim.split(last_line .. chunk, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, lines)
end

local function buffer_parse(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local messages = {}
  local current_role = "user"
  local current_text = {}

  local function add_message()
    if #current_text > 0 then
      table.insert(messages, {
        role = current_role,
        content = { { type = "text", text = table.concat(current_text, "\n") } },
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
  add_message()
  return messages
end

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
  local seen = {}
  local files = {}
  for _, buf in ipairs(buffers) do
    local path = vim.api.nvim_buf_get_name(buf)
    local parts = vim.split(vim.fn.fnamemodify(path, ":~:."), "/", { plain = true })
    local current = ""
    for i, part in ipairs(parts) do
      current = current .. "/" .. part
      if i < #parts then
        if not seen[current] then
          table.insert(tree, string.rep("│   ", i - 1) .. "├── " .. part)
          seen[current] = true
        end
      else
        table.insert(tree, string.rep("│   ", #parts - 1) .. "└── " .. part)
        files[buf] = parts[#parts]
      end
    end
  end
  local buffer_contents = { "\n" .. table.concat(tree, "\n") .. "\n" }
  for _, buf in ipairs(buffers) do
    local filename = files[buf] or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
    local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
    table.insert(buffer_contents, string.format("\nFile: %s\n```\n%s\n```\n", filename, content))
  end
  if #buffers > 0 then
    buffer_append("\n" .. table.concat(buffer_contents, "\n") .. "\n\n", bufnr)
  else
    buffer_append("\nNo valid buffer files found.\n\n", bufnr)
  end
end

local function keymap_set_chat(model_cfg, bufnr)
  vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
    callback = function()
      local messages = buffer_parse(bufnr)
      if #messages == 0 then
        print("empty input")
        return
      end
      if model_cfg.system_prompt and model_cfg.system_prompt ~= "" then
        table.insert(messages, 1, { role = "system", content = { { type = "text", text = model_cfg.system_prompt } } })
      end
      buffer_append("\n\n<assistant>\n\n", bufnr)
      model_cfg.fetcher(messages)
    end,
    noremap = true,
    silent = true,
  })
end

local function model_switch(model_cfgs)
  return function(winid, bufnr)
    local opts, map = {}, {}
    for _, cfg in pairs(model_cfgs) do
      local disp = cfg.display_name or string.format("%s@%s", cfg.endpoint, cfg.name)
      map[disp] = cfg
      table.insert(opts, disp)
    end
    vim.ui.select(opts, { prompt = "Mana switch model" }, function(choice)
      if not choice then
        return
      end
      current_model_cfg = map[choice]
      keymap_set_chat(current_model_cfg, bufnr)
      vim.api.nvim_set_option_value(
        "winbar",
        "%=" .. (current_model_cfg.display_name or (current_model_cfg.endpoint .. "@" .. current_model_cfg.name)),
        { win = winid }
      )
    end)
  end
end

local function mk_prefetcher(cb)
  return function(model_name, endpoint_cfg)
    return function(messages)
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
          vim.json.encode({ model = model_name, messages = messages, stream = true }),
        },
        on_stdout = cb,
      }):start()
    end
  end
end

local function create_fetcher(model_cfg, endpoint_cfgs, cb)
  local endpoint_cfg = endpoint_cfgs[model_cfg.endpoint]
  return function(messages)
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
        vim.json.encode({ model = model_cfg.name, messages = messages, stream = true }),
      },
      on_stdout = cb,
    }):start()
  end
end

local function mk_insert_callback(bufnr, winid)
  local row, col = unpack(vim.api.nvim_win_get_cursor(winid))
  row = row - 1
  return function(_, data)
    for line in data:gmatch("[^\r\n]+") do
      if line:match("^data: ") then
        if not line:match("data: %[DONE%]") then
          local ok, decoded = pcall(vim.json.decode, line:sub(7))
          if ok and decoded and decoded.choices then
            for _, choice in ipairs(decoded.choices) do
              if choice.delta and choice.delta.content then
                local content = choice.delta.content
                vim.schedule(function()
                  local lines = vim.split(content, "\n", { plain = true })
                  if #lines == 1 then
                    vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { lines[1] })
                    col = col + #lines[1]
                  else
                    vim.api.nvim_buf_set_text(bufnr, row, col, row, col, { lines[1] })
                    for i = 2, #lines - 1 do
                      vim.api.nvim_buf_set_lines(bufnr, row + i - 1, row + i - 1, false, { lines[i] })
                    end
                    vim.api.nvim_buf_set_lines(bufnr, row + #lines - 1, row + #lines - 1, false, { lines[#lines] })
                    row = row + #lines - 1
                    col = #lines[#lines]
                  end
                  vim.api.nvim_win_set_cursor(winid, { row + 1, col })
                end)
              end
            end
          end
        end
      end
    end
  end
end

local function mk_stdout_callback(bufnr)
  return function(_, data)
    for line in data:gmatch("[^\r\n]+") do
      if line:match("^data: ") then
        if line:match("data: %[DONE%]") then
          vim.schedule(function()
            buffer_append("\n</assistant>\n", bufnr)
          end)
        else
          local ok, decoded = pcall(vim.json.decode, line:sub(7))
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
      elseif data ~= ": OPENROUTER PROCESSING" then
        vim.schedule(function()
          buffer_append(data, bufnr)
        end)
      end
    end
  end
end

local function command_set(model_switch_fn, winbar, winid, bufnr)
  vim.api.nvim_create_user_command("Mana", function(opts)
    local args = vim.split(opts.args, "%s+")
    local cmd = args[1]

    if cmd == "complete" then
      local current_buf = vim.api.nvim_get_current_buf()
      local current_win = vim.api.nvim_get_current_win()
      local cursor = vim.api.nvim_win_get_cursor(current_win)
      local row, col = cursor[1], cursor[2]
      local lines = vim.api.nvim_buf_get_lines(current_buf, 0, row - 1, false)
      local curr_line = vim.api.nvim_buf_get_lines(current_buf, row - 1, row, false)[1] or ""
      local prompt = table.concat(lines, "\n") .. (lines[1] and "\n" or "") .. curr_line:sub(1, col)
      local messages = { { role = "user", content = { { type = "text", text = prompt } } } }
      local model_cfg_override = (model_cfgs["Code Editor"] or current_model_cfg)
      if model_cfg_override.system_prompt then
        table.insert(
          messages,
          1,
          { role = "system", content = { { type = "text", text = model_cfg_override.system_prompt } } }
        )
      end
      local fetcher = create_fetcher(model_cfg_override, endpoint_cfgs, mk_insert_callback(current_buf, current_win))
      fetcher(messages)
    elseif cmd == "replace" then
      if opts.range == 2 and opts.line1 and opts.line2 and opts.line2 >= opts.line1 then
        local bufnr_target = vim.api.nvim_get_current_buf()
        local buf_line_count = vim.api.nvim_buf_line_count(bufnr_target)
        local start_row = math.max(0, math.min(opts.line1 - 1, buf_line_count - 1))
        local end_row = math.max(start_row, math.min(opts.line2, buf_line_count))
        local selected_lines = vim.api.nvim_buf_get_lines(bufnr_target, start_row, end_row, false)
        if #selected_lines == 0 then
          vim.notify("Mana replace: no lines in selection", vim.log.levels.WARN)
          return
        end
        local prompt = table.concat(selected_lines, "\n")
        -- Delete selection before inserting
        vim.api.nvim_buf_set_lines(bufnr_target, start_row, end_row, false, {})
        -- Cursor to start of deletion
        local line_count_after = vim.api.nvim_buf_line_count(bufnr_target)
        local new_cursor_row = math.min(start_row, line_count_after)
        vim.api.nvim_win_set_cursor(0, { new_cursor_row + 1, 0 })
        local messages = {
          { role = "user", content = { { type = "text", text = prompt } } },
        }
        local model_cfg_override = model_cfgs["Code Rewriter"] or current_model_cfg
        if model_cfg_override.system_prompt then
          table.insert(messages, 1, {
            role = "system",
            content = { { type = "text", text = model_cfg_override.system_prompt } },
          })
        end
        -- Buffer response chunks and insert whole result at once after [DONE]
        local function replace_callback_factory(bufnr, insert_row)
          local output_chunks = {}
          return function(_, data)
            for line in data:gmatch("[^\r\n]+") do
              if line:match("^data: ") then
                if line:match("data: %[DONE%]") then
                  vim.schedule(function()
                    local text = table.concat(output_chunks)
                    local lines = vim.split(text, "\n", { plain = true })
                    vim.api.nvim_buf_set_lines(bufnr, insert_row, insert_row, false, lines)
                    vim.api.nvim_win_set_cursor(0, { insert_row + #lines, 0 })
                  end)
                else
                  local ok, decoded = pcall(vim.json.decode, line:sub(7))
                  if ok and decoded and decoded.choices then
                    for _, choice in ipairs(decoded.choices) do
                      if choice.delta and choice.delta.content then
                        table.insert(output_chunks, choice.delta.content)
                      end
                    end
                  end
                end
              end
            end
          end
        end
        local replace_callback = replace_callback_factory(bufnr_target, new_cursor_row)
        local fetcher = create_fetcher(model_cfg_override, endpoint_cfgs, replace_callback)
        fetcher(messages)
      else
        vim.notify("Mana replace requires a valid visual selection", vim.log.levels.WARN)
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
      local s = vim.fn.getpos("'<")[2]
      local e = vim.fn.getpos("'>")[2]
      local buf = vim.api.nvim_get_current_buf()
      local lines = vim.api.nvim_buf_get_lines(buf, s - 1, e, false)
      buffer_append("\n" .. table.concat(lines, "\n") .. "\n\n", bufnr)
      if not winid or not vim.api.nvim_win_is_valid(winid) then
        winid = window_create(bufnr)
        buffer_cursor_down(bufnr)
        vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
      end
    elseif cmd == "switch" then
      if winid and vim.api.nvim_win_is_valid(winid) then
        model_switch_fn(winid, bufnr)
      else
        winid = window_create(bufnr)
        model_switch_fn(winid, bufnr)
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

  vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>y", "", {
    callback = function()
      yank_code_block(bufnr)
    end,
    noremap = true,
    silent = true,
  })
end

local function parse_opts_models(endpoint_cfgs, prefetcher, raw)
  if type(raw) ~= "table" then
    return nil, "models must be a table"
  end
  local parsed = {}
  for model_name, cfg in pairs(raw) do
    if type(cfg.endpoint) ~= "string" then
      return nil, model_name .. ": endpoint must be string"
    end
    if type(cfg.name) ~= "string" then
      return nil, model_name .. ": name must be string"
    end
    if type(cfg.system_prompt) ~= "string" then
      return nil, model_name .. ": system_prompt must be string"
    end
    if type(cfg.temperature) ~= "number" then
      return nil, model_name .. ": temperature must be number"
    end
    if type(cfg.top_p) ~= "number" then
      return nil, model_name .. ": top_p must be number"
    end
    local ep_cfg = endpoint_cfgs[cfg.endpoint]
    parsed[model_name] = {
      endpoint = cfg.endpoint,
      name = cfg.name,
      display_name = cfg.display_name,
      system_prompt = cfg.system_prompt,
      temperature = cfg.temperature,
      top_p = cfg.top_p,
      fetcher = prefetcher(cfg.name, ep_cfg),
    }
  end
  return parsed
end

local function parse_opts_envs(raw)
  if type(raw) ~= "table" then
    return nil, "envs must be table"
  end
  local urls = {
    aistudio = "https://generativelanguage.googleapis.com/v1beta/chat/completions",
    openrouter = "https://openrouter.ai/api/v1/chat/completions",
    deepseek = "https://api.deepseek.com/v1/chat/completions",
    groq = "https://api.groq.com/v1/chat/completions",
    openai = "https://api.openai.com/v1/chat/completions",
  }
  local parsed = {}
  for ep, env in pairs(raw) do
    if not urls[ep] then
      return nil, "invalid endpoint: " .. ep
    end
    if type(env) ~= "string" then
      return nil, "env for " .. ep .. " must be string"
    end
    local key = os.getenv(env)
    if not key then
      return nil, string.format("endpoint %s: API key not found in var %s", ep, env)
    end
    parsed[ep] = { url = urls[ep], api_key = key }
  end
  return parsed
end

local function parse_opts_default_model(cfgs, raw)
  if type(raw) ~= "string" then
    return nil, "default_model must be a string"
  end
  if not cfgs[raw] then
    return nil, "default_model not found: " .. raw
  end
  return cfgs[raw]
end

M.setup = function(opts)
  local bufnr = buffer_get()
  local winid = nil
  local stdout_cb = mk_stdout_callback(bufnr)
  local prefetcher = mk_prefetcher(stdout_cb)

  local envs_err
  endpoint_cfgs, envs_err = parse_opts_envs(opts.envs)
  if not endpoint_cfgs then
    vim.notify("Mana.nvim error: " .. envs_err, vim.log.levels.ERROR)
    return
  end

  local models_err
  model_cfgs, models_err = parse_opts_models(endpoint_cfgs, prefetcher, opts.models)
  if not model_cfgs then
    vim.notify("Mana.nvim error: " .. models_err, vim.log.levels.ERROR)
    return
  end

  local dm_err
  current_model_cfg, dm_err = parse_opts_default_model(model_cfgs, opts.default_model)
  if not current_model_cfg then
    vim.notify("Mana.nvim error: " .. dm_err, vim.log.levels.ERROR)
    return
  end

  local model_switch_fn = model_switch(model_cfgs)
  local winbar = "%=" .. current_model_cfg.endpoint .. "@" .. current_model_cfg.name

  keymap_set_chat(current_model_cfg, bufnr)
  command_set(model_switch_fn, winbar, winid, bufnr)
end

return M
