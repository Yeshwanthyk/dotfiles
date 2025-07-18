# VS Code LLM Gateway Integration - Technical Analysis & Implementation Guide

## Overview

This document provides a comprehensive technical analysis of the Neovim `ding.nvim` plugin and `llm-gateway` integration, with detailed guidance for implementing similar functionality in VS Code.

## Architecture Analysis

### 1. LLM Gateway Plugin (`llm-gateway.lua`)

**Purpose**: Core gateway management and model selection interface

**Key Components**:
- **Gateway URL**: `http://localhost:3009` (configurable)
- **Session Management**: Uses session IDs for conversation persistence
- **Model Management**: Dynamic model selection and configuration

**API Endpoints Used**:
```
GET  /models                    - Fetch available models
POST /set-default-model         - Set the default model for the gateway
GET  /models                    - Refresh model list
POST /clear?id={session_id}     - Clear conversation session
```

**Core Functions**:
1. `select_model()` - Interactive model selection via UI picker
2. `set_default_model(model)` - Configure gateway's default model
3. `refresh_models()` - Update available models list
4. `clear_session()` - Reset conversation history

### 2. Ding Plugin (`ding.lua`)

**Purpose**: Text manipulation and LLM interaction interface

**Key Features**:
- **Text Replacement**: Replace selected text with LLM response
- **Text Appending**: Add LLM-generated content at cursor position
- **Real-time Streaming**: Handle server-sent events for live updates
- **Visual Selection Support**: Works with all Vim visual modes
- **Progress Indication**: Animated spinner during requests
- **Cancellation**: Interrupt ongoing requests

## Detailed Technical Implementation

### LLM Gateway Communication Protocol

#### 1. Gateway Model Management

**Endpoint**: `GET /models`
```json
Response: {
  "models": ["model1", "model2", "model3"]
}
```

**Endpoint**: `POST /set-default-model`
```json
Request: {
  "model": "selected-model-name"
}
```

**Endpoint**: `POST /clear?id={sessionId}`
- Clears conversation history for the specified session

#### 2. Text Generation Request

**Endpoint**: `POST /call`
```json
Request: {
  "prompt": "user text or selection",
  "sessionId": "neovim-session",
  "stream": true,
  "systemPrompt": "detailed system instructions"
}
```

**Response**: Server-Sent Events (SSE) format
```
data: {"text": "partial response chunk"}
data: {"text": "next chunk"}
data: {"text": "final chunk"}
```

### System Prompts & Behavior Configuration

#### 1. Text Replacement System Prompt
```
You are a precise text replacement assistant. Your task is to modify the selected text according to the user's instruction.

Rules:
1. Make ONLY the specific change requested in the prompt
2. Preserve all formatting, structure, indentation, and spacing exactly
3. Return ONLY the modified text - no explanations, summaries, or additional content
4. If the instruction is unclear, make the most logical interpretation
5. For rename/replace operations, substitute all instances of the target text with the new text
6. For "rename X" without specifying target, choose a concise, clear alternative name
7. Maintain the exact same text structure and length as much as possible
```

#### 2. Append Mode System Prompt
```
You are a helpful programming assistant. Generate appropriate code or text to append at the cursor position based on the context provided. Be concise and relevant to the file content and cursor position.
```

### Text Processing & Editor Integration

#### 1. Visual Selection Handling
- **Line-wise (`V`)**: Full line selection
- **Character-wise (`v`)**: Precise character ranges
- **Block-wise (`Ctrl+V`)**: Rectangular selections

#### 2. Text Manipulation Functions
- `get_visual_selection()`: Extract selected text based on visual mode
- `write_string_at_cursor()`: Insert text at cursor with proper positioning
- `get_current_file_content()`: Retrieve entire buffer content for context

#### 3. Streaming Response Processing
- Parse SSE format: `data: {"text": "chunk"}`
- Handle JSON parsing with fallback to raw text
- Real-time text insertion during streaming

### Progress Indication & User Experience

#### 1. Animated Progress Spinner
```lua
local spinner_frames = {
  "(๑• ◡• )",
  "(づ｡◕‿‿◕｡)づ",
  "✩°｡⋆⸜(｡•ω•｡)",
  -- ... more frames
}
```

#### 2. Request Cancellation
- Temporary escape key binding during requests
- Job termination and cleanup
- Progress indicator clearing

## VS Code Implementation Strategy

### 1. Extension Architecture

**Core Components Needed**:
```typescript
// Gateway client for HTTP communication
class LLMGatewayClient {
  private baseUrl: string;
  private defaultSessionId: string;
  
  async getModels(): Promise<string[]>
  async setDefaultModel(model: string): Promise<void>
  async clearSession(sessionId?: string): Promise<void>
  async callLLM(request: LLMRequest): Promise<ReadableStream>
}

// Text manipulation and editor integration
class TextProcessor {
  replaceSelection(text: string): void
  appendAtCursor(text: string): void
  getSelection(): string | null
  getCurrentFileContent(): string
}

// Stream handling for real-time updates
class StreamHandler {
  processSSEResponse(stream: ReadableStream): AsyncGenerator<string>
  handleTextChunk(chunk: string): void
}
```

### 2. VS Code API Integration

#### Selection Management
```typescript
// Get active selection
const editor = vscode.window.activeTextEditor;
const selection = editor.selection;
const selectedText = editor.document.getText(selection);

// Replace selected text
await editor.edit(editBuilder => {
  editBuilder.replace(selection, newText);
});

// Insert at cursor
await editor.edit(editBuilder => {
  editBuilder.insert(editor.selection.active, newText);
});
```

#### Progress Indication
```typescript
// Use VS Code's progress API
vscode.window.withProgress({
  location: vscode.ProgressLocation.Notification,
  title: "LLM Processing...",
  cancellable: true
}, async (progress, token) => {
  // Handle streaming response with progress updates
  for await (const chunk of streamResponse) {
    if (token.isCancellationRequested) break;
    // Update progress and insert text
  }
});
```

#### Command Registration
```typescript
// Register commands
vscode.commands.registerCommand('ding.replaceSelection', async () => {
  const editor = vscode.window.activeTextEditor;
  if (!editor || editor.selection.isEmpty) return;
  
  const selectedText = editor.document.getText(editor.selection);
  await processLLMRequest(selectedText, true); // replace mode
});

vscode.commands.registerCommand('ding.appendAtCursor', async () => {
  const editor = vscode.window.activeTextEditor;
  if (!editor) return;
  
  const fileContent = editor.document.getText();
  await processLLMRequest(fileContent, false); // append mode
});
```

### 3. Configuration Management

#### Extension Settings (`package.json`)
```json
{
  "contributes": {
    "configuration": {
      "title": "Ding LLM",
      "properties": {
        "ding.gatewayUrl": {
          "type": "string",
          "default": "http://localhost:3009",
          "description": "LLM Gateway URL"
        },
        "ding.defaultSessionId": {
          "type": "string",
          "default": "vscode-session",
          "description": "Default session ID for conversations"
        },
        "ding.systemPrompt": {
          "type": "string",
          "description": "System prompt for text replacement operations"
        }
      }
    },
    "commands": [
      {
        "command": "ding.selectModel",
        "title": "Select LLM Model"
      },
      {
        "command": "ding.replaceSelection",
        "title": "Replace Selection with LLM"
      },
      {
        "command": "ding.appendAtCursor",
        "title": "Append LLM Response"
      }
    ],
    "keybindings": [
      {
        "command": "ding.replaceSelection",
        "key": "ctrl+alt+r",
        "when": "editorHasSelection"
      },
      {
        "command": "ding.appendAtCursor",
        "key": "ctrl+alt+a",
        "when": "editorTextFocus"
      }
    ]
  }
}
```

### 4. HTTP Client Implementation

#### Using Fetch API with Streaming
```typescript
class LLMGatewayClient {
  async callLLM(request: LLMRequest): Promise<ReadableStream> {
    const response = await fetch(`${this.baseUrl}/call`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request)
    });
    
    if (!response.body) throw new Error('No response body');
    return response.body;
  }
  
  async *processStream(stream: ReadableStream): AsyncGenerator<string> {
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    
    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        
        const chunk = decoder.decode(value, { stream: true });
        const lines = chunk.split('\n');
        
        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = line.substring(6);
            try {
              const parsed = JSON.parse(data);
              if (parsed.text) yield parsed.text;
            } catch {
              yield data; // Fallback to raw text
            }
          }
        }
      }
    } finally {
      reader.releaseLock();
    }
  }
}
```

### 5. Key Implementation Differences

#### Neovim vs VS Code Considerations

**Editor Integration**:
- **Neovim**: Direct buffer manipulation with `nvim_buf_set_text`
- **VS Code**: Edit builders and workspace edits for undo/redo support

**Selection Handling**:
- **Neovim**: Visual mode detection (`v`, `V`, `Ctrl+V`)
- **VS Code**: Selection object with anchor/active positions

**Progress Indication**:
- **Neovim**: Custom spinner in command line
- **VS Code**: Built-in progress API with notifications

**Cancellation**:
- **Neovim**: Temporary keymap binding
- **VS Code**: CancellationToken pattern

**Configuration**:
- **Neovim**: Lua table configuration
- **VS Code**: JSON schema with contribution points

### 6. Advanced Features to Consider

#### Enhanced Text Processing
```typescript
// Smart indentation preservation
class SmartTextProcessor {
  preserveIndentation(originalText: string, newText: string): string {
    const lines = originalText.split('\n');
    const indentation = lines[0].match(/^\s*/)?.[0] || '';
    
    return newText.split('\n').map((line, index) => 
      index === 0 ? line : indentation + line
    ).join('\n');
  }
  
  // Context-aware replacements based on file type
  getContextualSystemPrompt(fileType: string): string {
    const prompts = {
      'typescript': 'Focus on TypeScript best practices...',
      'python': 'Follow Python PEP guidelines...',
      'markdown': 'Maintain markdown formatting...'
    };
    return prompts[fileType] || this.defaultSystemPrompt;
  }
}
```

#### Session Management
```typescript
class SessionManager {
  private sessions = new Map<string, SessionContext>();
  
  async createSession(workspaceId: string): Promise<string> {
    const sessionId = `vscode-${workspaceId}-${Date.now()}`;
    this.sessions.set(sessionId, {
      workspaceId,
      createdAt: new Date(),
      lastUsed: new Date()
    });
    return sessionId;
  }
  
  async getOrCreateSession(): Promise<string> {
    const workspace = vscode.workspace.workspaceFolders?.[0];
    const workspaceId = workspace?.uri.fsPath || 'default';
    
    // Reuse existing session or create new one
    const existing = Array.from(this.sessions.entries())
      .find(([, context]) => context.workspaceId === workspaceId);
    
    return existing?.[0] || await this.createSession(workspaceId);
  }
}
```

## Implementation Checklist

### Core Functionality
- [ ] LLM Gateway HTTP client with streaming support
- [ ] Text selection and manipulation utilities
- [ ] Server-sent events parsing and handling
- [ ] Progress indication during requests
- [ ] Request cancellation mechanism
- [ ] Model selection interface
- [ ] Session management

### VS Code Integration
- [ ] Command registration and keybindings
- [ ] Configuration schema and settings
- [ ] Editor integration with proper undo/redo
- [ ] Status bar integration for progress
- [ ] Context-aware prompts based on file type
- [ ] Workspace-specific session handling

### Advanced Features
- [ ] Multiple selection support
- [ ] Diff preview before applying changes
- [ ] Custom system prompt templates
- [ ] Request history and replay
- [ ] Performance monitoring and analytics
- [ ] Error handling and retry logic

## Testing Strategy

### Unit Tests
- Gateway client HTTP methods
- Text processing utilities
- Stream parsing logic
- Session management

### Integration Tests
- End-to-end request flow
- Editor interaction scenarios
- Configuration loading and validation
- Error handling pathways

### Manual Testing
- Various selection types and sizes
- Different file types and languages
- Network interruption scenarios
- Gateway unavailability handling

This comprehensive analysis provides the foundation for building a robust VS Code extension that replicates and enhances the functionality of the Neovim ding plugin while leveraging VS Code's native capabilities and APIs.