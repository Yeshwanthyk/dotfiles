-- ~/.config/nvim/lua/mana/init.lua

local Job = require("plenary.job")

local M = {}

-- Default Configuration (Simplified)
M.config = {
    gateway_url = "http://localhost:3009", -- <<< Changed Default URL
    session_id = "neovim-session",         -- Default session ID for context
    window = {
        width = 80,
        position = "topleft vsplit",
        winfixwidth = true,
        number = false,
        relativenumber = false,
        wrap = true,
        linebreak = true,
        winbar = true, -- Show generic winbar
    },
    keymaps = {
        toggle = "<leader>at", -- Keymap to toggle Mana window
    },
}

-- Internal Plugin State
local state = {
    gateway_url = nil,
    session_id = nil,
    bufnr = nil,
    winid = nil,
    active_chat_job = nil,
    stream_progress = 0,
    spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
    current_spinner_frame = 1,
    cancellation_keymap_set = false,
}

-- =============================================================================
-- Utility Functions (Log, Echo, Spinner)
-- =============================================================================
local function log(level, msg)
    vim.notify("[Mana] " .. msg, level)
end
local function echo_info(msg)
    vim.cmd("echo '[Mana] " .. msg .. "'")
end
local function clear_echo()
    vim.schedule(function()
        vim.api.nvim_echo({}, true, {})
    end)
end

local function echo_spinner()
    state.current_spinner_frame = (state.current_spinner_frame % #state.spinner_frames) + 1
    local frame = state.spinner_frames[state.current_spinner_frame]
    vim.api.nvim_echo({ { "Mana thinking... " .. frame, "ModeMsg" } }, true, {})
end

-- =============================================================================
-- Buffer Management (Get, Append, Parse)
-- =============================================================================

local function buffer_get()
    if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
        vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
        return state.bufnr
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf):match("[/\\]mana%.md$") then
            state.bufnr = buf
            vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
            return state.bufnr
        end
    end
    state.bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(state.bufnr, "mana.md")
    vim.api.nvim_set_option_value("bufhidden", "hide", { buf = state.bufnr })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = state.bufnr })
    vim.api.nvim_set_option_value("swapfile", false, { buf = state.bufnr })
    vim.api.nvim_set_option_value("modifiable", true, { buf = state.bufnr })
    vim.api.nvim_set_option_value("tabstop", 2, { buf = state.bufnr })
    vim.api.nvim_set_option_value("shiftwidth", 2, { buf = state.bufnr })
    vim.api.nvim_set_option_value("expandtab", true, { buf = state.bufnr })
    vim.api.nvim_set_option_value("filetype", "markdown", { buf = state.bufnr })
    vim.api.nvim_buf_set_keymap(state.bufnr, "n", "q", "<cmd>ManaChat close<CR>", { noremap = true, silent = true })
    vim.defer_fn(function()
        pcall(vim.lsp.stop_client, vim.lsp.get_clients({ bufnr = state.bufnr }), true)
    end, 100)
    log(vim.log.levels.INFO, "Created Mana buffer.")
    return state.bufnr
end


local function handle_stream_response(content_to_append, bufnr)
    -- Append text to buffer if content exists
    if content_to_append and content_to_append ~= "" then
        -- Schedule the buffer update to avoid issues with async callbacks
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then
                log(vim.log.levels.ERROR, "Buffer became invalid before scheduled update")
                return
            end

            -- Group buffer modifications for undo history (like ding.lua)
            vim.cmd("undojoin")

            vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

            -- Get current end of buffer to append text
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            -- Handle potentially empty buffer
            local last_line_len = 0
            if line_count > 0 then
                last_line_len = #vim.api.nvim_buf_get_lines(bufnr, line_count - 1, line_count, false)[1]
            else
                line_count = 1 -- If buffer is empty, we insert at line 1 (0-indexed 0)
            end

            -- Use nvim_buf_set_text to insert content at the end of the last line
            -- This mimics characterwise insertion more closely than set_lines
            vim.api.nvim_buf_set_text(
                bufnr,
                line_count - 1, -- start_row (0-indexed)
                last_line_len, -- start_col
                line_count - 1, -- end_row
                last_line_len, -- end_col
                vim.split(content_to_append, "\n") -- replacement text (needs list of strings)
            )
        end)
    end

    -- Spinner update logic is removed from here
end

-- =============================================================================
-- Gateway Interaction & Streaming (Simplified)
-- =============================================================================

-- Reworked stdout callback factory
local function mk_gateway_stdout_callback(bufnr)
    return function(_, data)
        if not data or type(data) ~= "string" or data == "" then
            return
        end

        -- Process the data chunk directly (handle potential multiple lines/events within)
        -- NOTE: This assumes SSE events are typically line-separated in the chunks
        for line in data:gmatch("[^\r\n]+") do
            local text_data = line:match("^data:%s*(.*)") or line -- Handle SSE prefix

            -- Handle [DONE] marker
            if text_data == "[DONE]" then
                vim.schedule(function()
                    if vim.api.nvim_buf_is_valid(bufnr) then
                        -- Append final assistant closing tag
                        handle_stream_response("\n</assistant>\n", bufnr)
                        clear_echo()
                        remove_cancellation_keymap()
                    end
                end)
                goto continue_line_loop -- Skip further processing for this line
            end

            -- Try to parse JSON and extract content
            local success, parsed = pcall(vim.json.decode, text_data)
            local content_to_append = nil
            if success and type(parsed) == "table" then
                if parsed.choices and parsed.choices[1] and parsed.choices[1].delta and parsed.choices[1].delta.content then
                    content_to_append = parsed.choices[1].delta.content
                elseif parsed.text then
                    content_to_append = parsed.text
                end
            else
                -- Fallback for non-JSON or unexpected format (ignore keep-alive etc.)
                if not text_data:match("^:") and not text_data:match('^{"model":') then
                    content_to_append = text_data
                end
            end

            -- Call the handler to schedule buffer update
            if content_to_append and content_to_append ~= "" then
                handle_stream_response(content_to_append, bufnr)
            end

            ::continue_line_loop::
        end

        -- Increment progress and schedule spinner update *after* processing the chunk
        state.stream_progress = state.stream_progress + 1
        if state.stream_progress % 3 == 0 then
            vim.schedule(echo_spinner)
        end
    end
end

local function set_cancellation_keymap()
    if state.cancellation_keymap_set then
        return
    end
    vim.keymap.set("n", "<Esc>", function()
        if state.active_chat_job then
            log(vim.log.levels.WARN, "Cancelling Mana request...")
            state.active_chat_job:shutdown()
            state.active_chat_job = nil
            clear_echo()
            handle_stream_response("\n<assistant>\n[Request Cancelled]\n</assistant>\n", state.bufnr)
            vim.schedule(function()
                pcall(vim.keymap.del, "n", "<Esc>")
                state.cancellation_keymap_set = false
            end)
        else
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
        end
    end, { noremap = true, silent = true, desc = "Cancel Mana request" })
    state.cancellation_keymap_set = true
end

local function remove_cancellation_keymap()
    if not state.cancellation_keymap_set then
        return
    end
    vim.schedule(function()
        pcall(vim.keymap.del, "n", "<Esc>")
        state.cancellation_keymap_set = false
    end)
end

-- Modify call_gateway_stream to use the new handler:
local function call_gateway_stream(messages, bufnr)
    if state.active_chat_job then
        log(vim.log.levels.WARN, "Request already active.")
        return
    end

    state.stream_progress = 0
    state.current_spinner_frame = 1
    echo_spinner()
    set_cancellation_keymap()

    local request_data = {
        prompt = messages,
        sessionId = state.session_id,
        stream = true,
    }

    local stdout_handler = mk_gateway_stdout_callback(bufnr)

    state.active_chat_job = Job:new({
        command = "curl",
        args = {
            "-sS",
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
            state.gateway_url .. "/call",
        },
        on_stdout = stdout_handler,
        on_stderr = function(_, data)
            if data and data ~= "" then
                vim.schedule(function()
                    handle_stream_response("\n<assistant>\n[GATEWAY ERROR]:\n" .. data .. "\n</assistant>\n", bufnr)
                    log(vim.log.levels.ERROR, "Gateway Error: " .. data)
                    clear_echo()
                    remove_cancellation_keymap()
                end)
            end
        end,
        on_exit = function(_, code)
            local job_was_active = state.active_chat_job ~= nil
            state.active_chat_job = nil
            if job_was_active and state.cancellation_keymap_set then
                remove_cancellation_keymap()
                clear_echo()
            end
            if code ~= 0 and code ~= 130 then
                vim.schedule(function()
                    handle_stream_response("\n<assistant>\n[REQUEST FAILED - Code: " .. code .. "]\n</assistant>\n",
                        bufnr)
                    log(vim.log.levels.WARN, "Request failed: " .. code)
                end)
            end
        end,
    })
    state.active_chat_job:start()
    log(vim.log.levels.INFO, "Request sent to gateway...")
end

---@class Mana.ContentItem
---@field type "text"
---@field text string

---@class Mana.Message
---@field role "user" | "assistant" | "system"
---@field content string -- Sending string content for simplicity/compatibility

---@alias Mana.Messages Mana.Message[]

local function buffer_parse(bufnr)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local messages = {} ---@type Mana.Messages
    local current_role = "user" ---@type "user" | "assistant" | "system"
    local current_text_lines = {}

    local function add_message()
        if #current_text_lines > 0 then
            local text_content = table.concat(current_text_lines, "\n")
            table.insert(messages, { role = current_role, content = text_content })
            current_text_lines = {}
        end
    end

    for _, line in ipairs(lines) do
        local trimmed_line = vim.trim(line)
        if trimmed_line == "<assistant>" then
            add_message()
            current_role = "assistant"
        elseif trimmed_line == "</assistant>" then
            add_message()
            current_role = "user"
        elseif trimmed_line == "<system>" then
            add_message()
            current_role = "system"
        elseif trimmed_line == "</system>" then
            add_message()
            current_role = "user"
        else
            if line ~= "" then
                table.insert(current_text_lines, line)
            end
        end
    end
    add_message()
    if #messages > 0 and messages[#messages].role == "assistant" and vim.trim(messages[#messages].content) == "" then
        table.remove(messages)
    end
    return messages
end

-- =============================================================================
-- Window Management (Configure, Open, Close, Toggle)
-- =============================================================================

local function configure_window(winid, bufnr)
    local cfg = M.config.window
    vim.api.nvim_win_set_buf(winid, bufnr)
    vim.api.nvim_win_set_width(winid, cfg.width)
    vim.api.nvim_set_option_value("number", cfg.number, { win = winid })
    vim.api.nvim_set_option_value("relativenumber", cfg.relativenumber, { win = winid })
    vim.api.nvim_set_option_value("wrap", cfg.wrap, { win = winid })
    vim.api.nvim_set_option_value("linebreak", cfg.linebreak, { win = winid })
    vim.api.nvim_set_option_value("colorcolumn", "", { win = winid })
    vim.api.nvim_set_option_value("winfixwidth", cfg.winfixwidth, { win = winid })
    if cfg.winbar then
        vim.api.nvim_set_option_value("winbar", "%= Mana Chat %=", { win = winid })
    else
        vim.api.nvim_set_option_value("winbar", "", { win = winid })
    end
end

local function open_window()
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        vim.api.nvim_set_current_win(state.winid)
        return
    end
    local bufnr = buffer_get()
    vim.cmd(M.config.window.position)
    state.winid = vim.api.nvim_get_current_win()
    configure_window(state.winid, bufnr)
    vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            vim.api.nvim_win_set_cursor(state.winid, { line_count, 0 })
            vim.cmd("startinsert")
        end
    end)
end

local function close_window()
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        vim.api.nvim_win_close(state.winid, true)
        state.winid = nil
    end
end

local function toggle_window()
    if state.winid and vim.api.nvim_win_is_valid(state.winid) then
        close_window()
    else
        open_window()
    end
end

-- =============================================================================
-- Feature Functions (Yank, Add Buffers)
-- =============================================================================

local function yank_code_block(bufnr)
    if
        not state.winid
        or not vim.api.nvim_win_is_valid(state.winid)
        or vim.api.nvim_win_get_buf(state.winid) ~= bufnr
    then
        log(vim.log.levels.WARN, "Yank command must be run from the Mana window.")
        return
    end
    local line_num = vim.api.nvim_win_get_cursor(state.winid)[1]
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local start_block, end_block = -1, -1
    for i = line_num, 1, -1 do
        if lines[i]:match("^```") then
            start_block = i
            break
        end
    end
    if start_block ~= -1 then
        for i = start_block + 1, #lines do
            if lines[i]:match("^```") then
                end_block = i
                break
            end
        end
    end
    if start_block == -1 or end_block == -1 or line_num > end_block then
        if lines[line_num + 1] and lines[line_num + 1]:match("^```") then
            start_block = line_num + 1
            for i = start_block + 1, #lines do
                if lines[i]:match("^```") then
                    end_block = i
                    break
                end
            end
        end
    end
    if start_block == -1 or end_block == -1 or start_block >= end_block then
        log(vim.log.levels.WARN, "Cursor not inside or adjacent to a valid code block (```...```).")
        return
    end
    local code_lines = {}
    for i = start_block + 1, end_block - 1 do
        table.insert(code_lines, lines[i])
    end
    vim.fn.setreg('"', table.concat(code_lines, "\n"))
    log(vim.log.levels.INFO, 'Code block yanked to register ".')
end

local function send_buffers_to_chat(bufnr)
    local buffers_to_add = {}
    -- Filter relevant buffers
    for _, bufh in ipairs(vim.api.nvim_list_bufs()) do
        if
            bufh ~= bufnr
            and vim.api.nvim_buf_is_loaded(bufh)
            and vim.api.nvim_buf_get_name(bufh) ~= ""
            and vim.api.nvim_buf_get_option(bufh, "buftype") == ""
        then
            table.insert(buffers_to_add, bufh)
        end
    end

    if #buffers_to_add == 0 then
        log(vim.log.levels.INFO, "No suitable buffers found to add context from.")
        handle_stream_response("\n---\nNo suitable buffers found to add context from.\n---\n", bufnr)
        return
    end

    log(vim.log.levels.INFO, "Adding context from " .. #buffers_to_add .. " buffer(s)...")

    local tree = { "# File Tree" }
    local seen_dirs = {}
    local file_map = {} -- Store buf handle -> relative path for tree

    -- Build tree structure and file map
    local cwd = vim.fn.getcwd() .. "/"
    for _, bufh in ipairs(buffers_to_add) do
        local full_path = vim.api.nvim_buf_get_name(bufh)
        -- Use vim.fn.fnamemodify for better path manipulation
        local rel_path = vim.fn.fnamemodify(full_path, ":.")          -- Path relative to cwd
        file_map[bufh] = rel_path                                     -- Store relative path

        local parts = vim.split(rel_path, "[/\\]", { plain = false }) -- Split by / or \
        local current_dir_path = ""
        for i = 1, #parts - 1 do
            local part = parts[i]
            current_dir_path = current_dir_path .. part .. "/"
            if not seen_dirs[current_dir_path] then
                table.insert(tree, string.rep("│  ", i - 1) .. "├── " .. part)
                seen_dirs[current_dir_path] = true
            end
        end
        -- Add the file entry
        if #parts > 0 then
            table.insert(tree, string.rep("│  ", #parts - 1) .. "└── " .. parts[#parts])
        end
    end

    -- Prepare buffer contents section
    local buffer_contents_section = { "\n# File Contents" }
    for _, bufh in ipairs(buffers_to_add) do
        local rel_path = file_map[bufh] or
            vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufh), ":t") -- Fallback to filename
        local ft = vim.api.nvim_buf_get_option(bufh, "filetype") or ""
        local lines = vim.api.nvim_buf_get_lines(bufh, 0, -1, false)
        local content = table.concat(lines, "\n")
        -- Add file path and content in markdown code block
        table.insert(buffer_contents_section, string.format("\n## File: %s\n\n```%s\n%s\n```", rel_path, ft, content))
    end

    -- Combine tree and contents
    local final_context = "\n---\n"
        .. table.concat(tree, "\n")
        .. "\n"
        .. table.concat(buffer_contents_section, "\n")
        .. "\n---\n\n"

    -- Append to mana buffer
    handle_stream_response(final_context, bufnr)

    -- Ensure window is open and focus cursor
    open_window() -- Will open if not already open
    vim.schedule(function()
        if state.winid and vim.api.nvim_win_is_valid(state.winid) then
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            vim.api.nvim_win_set_cursor(state.winid, { line_count, 0 })
            vim.cmd("startinsert") -- Go to insert mode ready for query
        end
    end)
end

-- =============================================================================
-- Keymaps & Commands Setup
-- =============================================================================

local function keymap_set_chat(bufnr)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<CR>", "", {
        callback = function()
            if state.active_chat_job then
                log(vim.log.levels.WARN, "Wait for completion.")
                return
            end
            local messages = buffer_parse(bufnr)
            if #messages == 0 then
                echo_info("Buffer empty.")
                return
            end
            handle_stream_response("\n\n<assistant>\n", bufnr)
            call_gateway_stream(messages, bufnr) -- Simplified call
        end,
        noremap = true,
        silent = true,
        desc = "Send chat buffer to LLM",
    })
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<leader>ay", "", {
        callback = function()
            yank_code_block(bufnr)
        end,
        noremap = true,
        silent = true,
        desc = "Yank code block",
    })
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "q",
        "<cmd>ManaChat close<CR>",
        { noremap = true, silent = true, desc = "Close Mana window" }
    )
end

local function create_commands()
    vim.api.nvim_create_user_command("ManaChat", function(cmd_opts)
        local args = vim.split(cmd_opts.args, "%s+")
        local cmd = args[1] or "toggle"

        if cmd == "toggle" then
            toggle_window()
        elseif cmd == "open" then
            open_window()
        elseif cmd == "close" then
            close_window()
        elseif cmd == "clear" then
            if state.active_chat_job then
                state.active_chat_job:shutdown()
                state.active_chat_job = nil
            end
            clear_echo()
            remove_cancellation_keymap()
            vim.api.nvim_buf_set_lines(state.bufnr, 0, -1, false, {})
            log(vim.log.levels.INFO, "Chat buffer cleared.")
            if state.winid and vim.api.nvim_win_is_valid(state.winid) then
                vim.cmd("startinsert")
            end
        elseif cmd == "buffers" then
            send_buffers_to_chat(state.bufnr)
        else
            log(vim.log.levels.ERROR, "Unknown command: " .. cmd)
        end
    end, {
        nargs = "?",
        complete = function()
            return { "toggle", "open", "close", "clear", "buffers" }
        end, -- Updated completion
        desc = "Manage Mana Chat (toggle, open, close, clear, buffers)",
    })
end

local function setup_global_keymaps()
    if M.config.keymaps.toggle then
        vim.keymap.set(
            "n",
            M.config.keymaps.toggle,
            "<cmd>ManaChat toggle<CR>",
            { noremap = true, silent = true, desc = "Toggle Mana Chat" }
        )
    end
end

-- =============================================================================
-- Public Setup Function
-- =============================================================================

M.setup = function(user_opts)
    M.config = vim.tbl_deep_extend("force", M.config, user_opts or {})
    state.gateway_url = M.config.gateway_url
    state.session_id = M.config.session_id

    -- No model loading needed here anymore

    state.bufnr = buffer_get()
    if not state.bufnr then
        log(vim.log.levels.ERROR, "Failed to init Mana buffer.")
        return
    end

    keymap_set_chat(state.bufnr)
    create_commands()
    setup_global_keymaps()

    log(vim.log.levels.INFO, "Setup complete. Ready to chat with gateway default model.")
end

return M
