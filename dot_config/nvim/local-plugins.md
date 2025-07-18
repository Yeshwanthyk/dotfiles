# Local Plugins Documentation

This document analyzes and maps out the local plugins configured in `lua/plugins/local.lua` for better understanding and redesign planning.

## Overview

All plugins interface with an LLM Gateway running on `http://localhost:3009` and use the session ID `neovim-session`.

## Plugin Analysis

### 1. ding.nvim (Currently Active)

**Purpose**: Direct text manipulation with LLM responses
- Replace selected text with LLM response
- Append LLM response at cursor or after selection

**Key Features**:
- Streaming responses with progress indicators
- Visual selection handling (character, line, block modes)
- Core LLM integration without gateway management

**Keymaps**:
- `<leader>ar` - Replace selection with LLM response (normal/visual mode)
- `<leader>aa` - Append LLM response at cursor (normal mode)
- `<leader>aa` - Append LLM response after selection (visual mode)

**Commands**:
- `:DingReplace` - Replace command
- `:DingAppend` - Append command

**System Prompt**: Senior software engineer focused on maintainability and concise solutions

---

### 2. llm-gateway (Currently Active)

**Purpose**: Gateway management and model operations
- Model selection and switching
- Session management
- Gateway communication

**Key Features**:
- Model selection interface
- Session clearing
- Gateway default model management
- Cancel request functionality

**Keymaps**:
- `<leader>as` - Switch LLM model
- `<leader>af` - Refresh LLM models
- `<Esc>` - Cancel ongoing requests

**Commands**:
- `:DingSelect` - Model selection
- `:DingClearSession` - Clear session
- `:DingRefreshModels` - Refresh models

---

### 3. yeti.nvim (Currently Commented)

**Purpose**: Bulk buffer management for LLM context
- Send all open buffers to LLM for context

**Key Features**:
- Buffer aggregation and sending
- Session management

**Keymaps**:
- `<leader>ab` - Send all buffers to LLM

**Commands**:
- `:YetiSendBuffers` - Send all buffers

---

### 4. mana.nvim (Currently Commented)

**Purpose**: Interactive chat interface with LLM
- Toggle chat window
- Interactive conversation management
- Buffer context sending
- Code extraction from responses

**Key Features**:
- Chat window toggle
- Chat history management
- Buffer context integration
- Code block extraction/yanking

**Keymaps**:
- `<leader>at` - Toggle Mana chat
- `<leader>ac` - Clear Mana chat
- `<leader>au` - Open Mana chat
- `<leader>ay` - Yank code block from chat
- `<leader>am` - Send buffers to Mana chat

**Commands**:
- `:Mana` - Main command
- `:ManaChat` - Chat subcommands

**System Prompt**: Generic helpful programming assistant

---

## Current Keymap Analysis

### Active Keymaps (ding.nvim + llm-gateway)
```
<leader>a* namespace:
├── ar - Replace with LLM (normal/visual)
├── aa - Append LLM (normal/visual)  
├── as - Switch model
└── af - Refresh models
```

### Potential Conflicts (if all plugins enabled)
```
<leader>a* namespace conflicts:
├── aa - ding.nvim (append)
├── ab - yeti.nvim (send buffers)
├── ac - mana.nvim (clear chat)
├── af - ding.nvim (refresh models)
├── am - mana.nvim (send buffers to chat)
├── ar - ding.nvim (replace)
├── as - ding.nvim (switch model)
├── at - mana.nvim (toggle chat)
├── au - mana.nvim (open chat)
└── ay - mana.nvim (yank code)
```

## Functional Overlap Analysis

### Buffer Management
- **yeti.nvim**: Sends buffers directly to LLM
- **mana.nvim**: Sends buffers to chat interface
- **Overlap**: Both handle buffer context, but different UX approaches

### LLM Interaction
- **ding.nvim**: Direct text manipulation (replace/append)
- **mana.nvim**: Chat-based interaction
- **Complementary**: Different interaction paradigms

### Model Management
- **llm-gateway**: Model selection and refresh
- **ding.nvim**: Uses gateway default
- **yeti.nvim**: Uses gateway default
- **mana.nvim**: Uses gateway default
- **Centralized**: Only llm-gateway handles model switching

## Recommendations for Redesign

### 1. Keymap Reorganization
Consider restructuring the `<leader>a*` namespace:

```
<leader>a* - AI/LLM namespace
├── <leader>ai - Inline operations
│   ├── <leader>air - Replace selection
│   ├── <leader>aia - Append at cursor
│   └── <leader>aie - Explain selection
├── <leader>ac - Chat operations  
│   ├── <leader>act - Toggle chat
│   ├── <leader>acc - Clear chat
│   ├── <leader>aco - Open chat
│   └── <leader>acy - Yank code from chat
├── <leader>ab - Buffer operations
│   ├── <leader>abs - Send current buffer
│   ├── <leader>aba - Send all buffers
│   └── <leader>abf - Send file tree
└── <leader>am - Model management
    ├── <leader>ams - Switch model
    ├── <leader>amr - Refresh models
    └── <leader>aml - List models
```

### 2. Plugin Consolidation Options

**Option A: Unified Plugin**
- Combine all functionality into a single plugin
- Unified configuration and keymap management
- Reduced complexity

**Option B: Complementary Plugins**
- Keep plugins separate but with clear boundaries
- ding.nvim: Direct text manipulation
- mana.nvim: Chat interface
- yeti.nvim: Buffer/context management

**Option C: Modular Architecture**
- Core plugin with optional modules
- Enable/disable features as needed
- Shared configuration and utilities

### 3. Feature Suggestions

**Enhanced Context Management**:
- File tree context sending
- Project-aware context
- Selective buffer inclusion

**Improved UX**:
- Visual feedback for operations
- Better error handling
- Undo/redo support for LLM operations

**Integration Features**:
- Git diff context
- Language-specific prompts
- Template system for common operations

## Current Status
- **Active**: ding.nvim, llm-gateway
- **Commented**: yeti.nvim, mana.nvim
- **Gateway**: Running on localhost:3009
- **Session**: neovim-session

## Architecture Changes

### Plugin Separation
The gateway-related functionality has been extracted from ding.nvim into a separate llm-gateway plugin:

- **ding.nvim**: Now focuses purely on core LLM integration (replace/append operations)
- **llm-gateway**: Handles all gateway management (model selection, session clearing, etc.)

This separation provides:
- Cleaner architecture with single responsibilities
- Easier maintenance and debugging
- Modular design allowing independent updates