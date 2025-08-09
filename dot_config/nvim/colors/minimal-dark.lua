-- minimal-dark.lua
-- A minimal dark colorscheme with carefully chosen accent colors
-- Designed for maximum readability with pure black background

-- Clear existing highlights and reset syntax
vim.cmd('highlight clear')
if vim.g.syntax_on == 1 then
  vim.cmd('syntax reset')
end

vim.o.background = 'dark'
vim.g.colors_name = 'minimal-dark'

-- Better line spacing for readability
vim.o.linespace = 2

local colors = {
  -- Base colors (pure black for eye strain reduction)
  bg = '#000000',
  bg_alt = '#1a1a1a',
  bg_highlight = '#2a2a2a',
  bg_float = '#0a0a0a',
  
  -- Foreground colors
  fg = '#ffffff',            -- Pure white for maximum contrast
  fg_dim = '#cccccc',        -- Dimmed white for comments/secondary text
  
  -- Semantic colors (named by purpose, not appearance)
  string_color = '#c8a2c8',  -- Lavender for strings
  number_color = '#88d5ff',  -- Light blue for numbers
  keyword_color = '#ffffff', -- White for keywords (def, class, etc.)
  method_color = '#7dd3c0',  -- Brighter teal for method calls
  class_color = '#d4af37',   -- Dulled gold for class names
  variable_color = '#e8e8e8', -- Light gray for variables
  decorator_color = '#cc6600', -- Dark orange for decorators
  
  -- Traditional accent colors (for UI elements)
  red = '#ff8899',
  yellow = '#ffdd77',
  cyan = '#4ec9b0',
  
  -- UI specific
  border = '#777777',
  selection = '#333333',
}

-- Helper function to set highlights
local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Terminal colors (using semantic names for consistency)
vim.g.terminal_color_0 = colors.bg
vim.g.terminal_color_1 = colors.red
vim.g.terminal_color_2 = colors.string_color
vim.g.terminal_color_3 = colors.yellow
vim.g.terminal_color_4 = colors.number_color
vim.g.terminal_color_5 = colors.keyword_color
vim.g.terminal_color_6 = colors.cyan
vim.g.terminal_color_7 = colors.fg
vim.g.terminal_color_8 = colors.fg_dim
vim.g.terminal_color_9 = colors.red
vim.g.terminal_color_10 = colors.string_color
vim.g.terminal_color_11 = colors.yellow
vim.g.terminal_color_12 = colors.number_color
vim.g.terminal_color_13 = colors.keyword_color
vim.g.terminal_color_14 = colors.cyan
vim.g.terminal_color_15 = colors.fg

-- BASIC SYNTAX HIGHLIGHTING
hl('Normal', { bg = colors.bg, fg = colors.fg })
hl('Comment', { fg = colors.fg_dim })

-- Literals
hl('String', { fg = colors.string_color })
hl('Character', { fg = colors.string_color })
hl('Number', { fg = colors.number_color })
hl('Boolean', { fg = colors.fg })
hl('Float', { fg = colors.number_color })
hl('Constant', { fg = colors.fg })

-- Identifiers and functions
hl('Identifier', { fg = colors.variable_color })
hl('Function', { fg = colors.fg, bold = true })

-- Keywords and statements
hl('Statement', { fg = colors.keyword_color })
hl('Conditional', { fg = colors.keyword_color })
hl('Repeat', { fg = colors.keyword_color })
hl('Label', { fg = colors.keyword_color })
hl('Keyword', { fg = colors.keyword_color })
hl('Exception', { fg = colors.keyword_color })
hl('Operator', { fg = colors.fg })

-- Preprocessor
hl('PreProc', { fg = colors.fg })
hl('Include', { fg = colors.fg, bold = true })
hl('Define', { fg = colors.fg })
hl('Macro', { fg = colors.decorator_color })
hl('PreCondit', { fg = colors.decorator_color })

-- Types
hl('Type', { fg = colors.class_color, bold = true })
hl('StorageClass', { fg = colors.keyword_color })
hl('Structure', { fg = colors.class_color })
hl('Typedef', { fg = colors.keyword_color })

-- Special elements
hl('Special', { fg = colors.fg })
hl('SpecialChar', { fg = colors.decorator_color })
hl('Tag', { fg = colors.fg })
hl('Delimiter', { fg = colors.fg })
hl('SpecialComment', { fg = colors.fg_dim, bold = true })
hl('Debug', { fg = colors.red })

-- UI ELEMENTS
hl('Error', { fg = colors.red, bold = true })
hl('ErrorMsg', { fg = colors.red, bold = true })
hl('WarningMsg', { fg = colors.yellow, bold = true })
hl('MoreMsg', { fg = colors.fg })
hl('ModeMsg', { fg = colors.fg, bold = true })
hl('Question', { fg = colors.fg })

-- Cursor
hl('Cursor', { bg = colors.fg, fg = colors.bg })
hl('iCursor', { bg = colors.yellow, fg = colors.bg })
hl('rCursor', { bg = colors.red, fg = colors.bg })
hl('CursorLine', { bg = colors.bg_highlight })
hl('CursorLineNr', { fg = colors.fg, bold = true })
hl('CursorColumn', { bg = colors.bg_highlight })
hl('ColorColumn', { bg = colors.bg_highlight })

-- Line numbers and signs
hl('LineNr', { fg = colors.fg_dim })
hl('SignColumn', { bg = colors.bg })
hl('FoldColumn', { fg = colors.fg_dim, bg = colors.bg })
hl('Folded', { fg = colors.fg_dim })

-- Selection and search
hl('Visual', { bg = colors.selection })
hl('Search', { bg = colors.yellow, fg = colors.bg })
hl('IncSearch', { bg = colors.decorator_color, fg = colors.bg })
hl('CurSearch', { bg = colors.decorator_color, fg = colors.bg })

-- Misc UI
hl('MatchParen', { bold = true })
hl('NonText', { fg = colors.fg_dim })
hl('SpecialKey', { fg = colors.number_color })
hl('Title', { fg = colors.fg, bold = true })
hl('Directory', { fg = colors.keyword_color })

-- WINDOW/SPLIT ELEMENTS
hl('VertSplit', { fg = colors.border })
hl('WinSeparator', { fg = colors.border })
hl('StatusLine', { fg = colors.fg, bg = colors.bg })
hl('StatusLineNC', { fg = colors.fg, bg = colors.bg_alt })
hl('WinBar', { fg = colors.fg, bold = true })
hl('WinBarNC', { fg = colors.fg, bold = true })

-- POPUP MENU
hl('Pmenu', { fg = colors.fg, bg = colors.bg_alt })
hl('PmenuSel', { bg = colors.selection, bold = true })
hl('PmenuSbar', { bg = colors.bg_alt })
hl('PmenuThumb', { bg = colors.selection })
hl('PmenuMatch', { fg = colors.yellow, bold = true })

-- FLOATING WINDOWS
hl('NormalFloat', { fg = colors.fg, bg = colors.bg_float })
hl('FloatBorder', { fg = colors.border })
hl('FloatTitle', { fg = colors.fg, bold = true })

-- TABS
hl('TabLine', { fg = colors.fg, bg = colors.bg_alt })
hl('TabLineFill', { fg = colors.fg, bg = colors.bg_alt })
hl('TabLineSel', { fg = colors.fg, bg = colors.bg, bold = true })

-- DIFF
hl('DiffAdd', { bg = '#1e3a1e' })
hl('DiffChange', { bg = '#3a3a1e' })
hl('DiffDelete', { fg = colors.red })
hl('DiffText', { bg = colors.yellow, fg = colors.bg })

-- SPELL CHECKING
hl('SpellBad', { sp = colors.red, underline = true })
hl('SpellCap', { sp = colors.yellow, underline = true })
hl('SpellLocal', { sp = colors.number_color, underline = true })
hl('SpellRare', { sp = colors.keyword_color, underline = true })

-- LSP DIAGNOSTICS
hl('DiagnosticError', { fg = colors.red, bold = true })
hl('DiagnosticWarn', { fg = colors.yellow, bold = true })
hl('DiagnosticInfo', { fg = colors.number_color, bold = true })
hl('DiagnosticHint', { fg = colors.fg_dim, bold = true })

hl('DiagnosticUnderlineError', { sp = colors.red, underline = true })
hl('DiagnosticUnderlineWarn', { sp = colors.yellow, underline = true })
hl('DiagnosticUnderlineInfo', { sp = colors.number_color, underline = true })
hl('DiagnosticUnderlineHint', { sp = colors.fg_dim, underline = true })

-- LSP REFERENCES
hl('LspReferenceText', { bg = colors.bg_highlight })
hl('LspReferenceRead', { bg = colors.bg_highlight })
hl('LspReferenceWrite', { bg = colors.bg_highlight })

-- TREESITTER HIGHLIGHTING
-- Variables
hl('@variable', { fg = colors.variable_color })
hl('@variable.builtin', { fg = colors.variable_color, bold = true })
hl('@variable.parameter', { fg = colors.variable_color })
hl('@variable.member', { fg = colors.method_color })

-- Constants
hl('@constant', { fg = colors.fg })
hl('@constant.builtin', { fg = colors.fg, bold = true })
hl('@constant.macro', { fg = colors.decorator_color })

-- Literals
hl('@string', { fg = colors.string_color })
hl('@string.regexp', { fg = colors.decorator_color })
hl('@character', { fg = colors.string_color })
hl('@number', { fg = colors.number_color })
hl('@boolean', { fg = colors.fg })
hl('@float', { fg = colors.number_color })

-- Functions and methods
hl('@function', { fg = colors.fg, bold = true })
hl('@function.builtin', { fg = colors.fg, bold = true })
hl('@function.macro', { fg = colors.decorator_color })
hl('@method', { fg = colors.method_color, bold = true })
hl('@constructor', { fg = colors.class_color, bold = true })

-- Keywords
hl('@keyword', { fg = colors.keyword_color })
hl('@keyword.function', { fg = colors.keyword_color })
hl('@keyword.operator', { fg = colors.keyword_color })
hl('@keyword.return', { fg = colors.keyword_color, bold = true })

-- Operators and punctuation
hl('@operator', { fg = colors.fg })
hl('@punctuation', { fg = colors.fg })
hl('@punctuation.delimiter', { fg = colors.fg })
hl('@punctuation.bracket', { fg = colors.fg })

-- Types
hl('@type', { fg = colors.class_color, bold = true })
hl('@type.builtin', { fg = colors.cyan })
hl('@property', { fg = colors.fg })
hl('@field', { fg = colors.fg })

-- Tags (HTML/XML)
hl('@tag', { fg = colors.fg, bold = true })
hl('@tag.attribute', { fg = colors.fg })
hl('@tag.delimiter', { fg = colors.fg })

-- Comments
hl('@comment', { fg = colors.fg_dim })
hl('@comment.documentation', { fg = colors.fg_dim })

-- DECORATORS AND SPECIAL SYNTAX
hl('@function.decorator', { fg = colors.decorator_color })
hl('@decorator', { fg = colors.decorator_color })
hl('@attribute', { fg = colors.decorator_color })
hl('@function.decorator.python', { fg = colors.decorator_color })
hl('@decorator.python', { fg = colors.decorator_color })
hl('@attribute.python', { fg = colors.decorator_color })
hl('pythonDecorator', { fg = colors.decorator_color })
hl('Decorator', { fg = colors.decorator_color })

-- SPECIAL EMPHASIS
hl('Bold', { fg = colors.fg, bold = true })
hl('Italic', { fg = colors.fg, italic = true })
hl('Underlined', { underline = true })
hl('Todo', { fg = colors.fg_dim, bold = true })

-- CUSTOM ACCENT GROUPS (for plugins and statuslines)
hl('OrangeAccent', { fg = colors.decorator_color, bold = true })
hl('BlueAccent', { fg = colors.number_color, bold = true })
hl('LavenderAccent', { fg = colors.string_color, bold = true })
hl('RedAccent', { fg = colors.red, bold = true })