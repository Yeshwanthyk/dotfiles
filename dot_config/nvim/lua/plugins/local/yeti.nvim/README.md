# yeti.nvim

A Neovim plugin that sends all buffer files to an LLM gateway and streams responses back to the current file, with the ability to apply structured edits across files.

## Features

- Send all loaded buffer contents to an LLM Gateway
- Stream responses back to the cursor position in the current file
- Parse and apply structured code edits across multiple files
- Configurable prompt template for specialized refactoring tasks
- Cancel ongoing requests with Escape key

## Requirements

- Neovim >= 0.5.0
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "local/yeti.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("yeti").setup({
      -- Optional configuration
    })
  end,
}
```

## Configuration

```lua
require("yeti").setup({
  gateway_url = "http://localhost:3000", -- URL of your LLM gateway
  default_session_id = "neovim-session", -- Session ID for the gateway
  keymaps = {
    send_buffers = "<leader>ys", -- Keymap to send all buffers to LLM
    cancel = "<Esc>", -- Cancel ongoing LLM request
  },
  prompt_template = [[
You are an expert programming assistant specialized in refactoring code via structured text blocks.
The context includes the *latest version* of the files listed below.
Your task is to propose specific edits based on the user's request, using the strict format provided.

## MANDATORY Edit Format
- You MUST ONLY output blocks in the specified format below.
- DO NOT include any conversational text, explanations, apologies, code comments, or text outside this strict format.
- Start your response *directly* with the first `... /path/to/filename.ext` line.
- Each file's changes MUST start with `...` followed by the full, absolute file path.
- Use *search-and-replace* sections ONLY for modifications:
  - Begin a section with a line containing only `<<<< SEARCH`.
  - Followed by the *exact* lines to find (preserving indentation and syntax).
  - Separate the search and replace blocks with a line containing only `=====`.
  - Followed by a line containing only `>>>> REPLACE`.
  - Followed by the new lines that will replace the SEARCH block.
- If a file needs no changes, DO NOT include a block for it.
- If the request cannot be fulfilled or requires clarification, output nothing.

### Context Files
%s

### Task Instructions
Based *only* on the context files provided above and the user's request below, generate the necessary edits in the specified MANDATORY format. Ensure SEARCH blocks match the file content *exactly*.

### User Request
%s
]],
})
```

## Usage

### Commands

- `:YetiSendBuffers` - Prompts for a request and sends all buffer contents to the LLM
- `:YetiSelectModel` - Interactively select an LLM model
- `:YetiRefreshModels` - Refresh the list of available models from the gateway

### Default Keymaps

- `<leader>ys` - Send all buffers to LLM (same as `:YetiSendBuffers`)
- `<Esc>` - Cancel an ongoing LLM request (temporary keymap active only during requests)

## Response Format

The plugin expects the LLM to respond in a specific format for file edits:

```
... /path/to/file.ext
<<<< SEARCH
lines to find
=====
>>>> REPLACE
lines to replace with
```

The plugin will parse this format and apply the edits to the corresponding files in your buffers.

## License

MIT
