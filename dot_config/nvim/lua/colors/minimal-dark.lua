-- minimal-dark.lua
-- A minimal dark colorscheme inspired by Grey theme
-- Enhanced with subtle color accents while maintaining minimalism

local M = {}

-- Color Palette - Dark minimal with selective accents
local colors = {
  -- Base colors
  bg = '#1a1a1a',           -- Main background - darker than grey's light
  bg_alt = '#222222',       -- Slightly lighter background for contrasts
  bg_highlight = '#2a2a2a', -- For cursor line, visual selection
  bg_float = '#1e1e1e',     -- Floating windows
  
  -- Foreground colors
  fg = '#e6e6e6',           -- Main text - light grey
  fg_dim = '#999999',       -- Comments, line numbers - dimmed
  fg_bright = '#ffffff',    -- Bright accents
  
  -- Accent colors (minimal but present)
  orange = '#ff9e64',       -- Orange accent (inspired by your preference)
  blue = '#7aa2f7',         -- Soft blue for numbers, types
  green = '#9ece6a',        -- Green for strings
  red = '#f7768e',          -- Red for errors
  purple = '#bb9af7',       -- Purple for keywords
  yellow = '#e0af68',       -- Yellow for warnings
  cyan = '#73daca',         -- Cyan for constants
  
  -- UI specific
  border = '#3a3a3a',       -- Borders
  selection = '#404040',    -- Visual selection
}

-- Helper function to set highlights
local function hl(group, opts)
  local bg = opts.bg and 'guibg=' .. opts.bg or 'guibg=NONE'
  local fg = opts.fg and 'guifg=' .. opts.fg or 'guifg=NONE' 
  local sp = opts.sp and 'guisp=' .. opts.sp or ''
  local style = opts.style and 'gui=' .. opts.style or 'gui=NONE'
  
  vim.cmd('highlight ' .. group .. ' ' .. bg .. ' ' .. fg .. ' ' .. sp .. ' ' .. style)
end

function M.setup()
  -- Clear existing highlights and set background
  vim.cmd('highlight clear')
  if vim.g.syntax_on == 1 then
    vim.cmd('syntax reset')
  end
  vim.o.background = 'dark'
  vim.g.colors_name = 'minimal-dark'
  
  -- Terminal colors
  vim.g.terminal_color_0 = colors.bg
  vim.g.terminal_color_1 = colors.red
  vim.g.terminal_color_2 = colors.green  
  vim.g.terminal_color_3 = colors.yellow
  vim.g.terminal_color_4 = colors.blue
  vim.g.terminal_color_5 = colors.purple
  vim.g.terminal_color_6 = colors.cyan
  vim.g.terminal_color_7 = colors.fg
  vim.g.terminal_color_8 = colors.fg_dim
  vim.g.terminal_color_9 = colors.red
  vim.g.terminal_color_10 = colors.green
  vim.g.terminal_color_11 = colors.yellow
  vim.g.terminal_color_12 = colors.blue
  vim.g.terminal_color_13 = colors.purple
  vim.g.terminal_color_14 = colors.cyan
  vim.g.terminal_color_15 = colors.fg_bright
  
  -- Basic syntax highlighting
  hl('Normal', { bg = colors.bg, fg = colors.fg })
  hl('Comment', { fg = colors.fg_dim })
  hl('Constant', { fg = colors.fg })
  hl('String', { fg = colors.green })
  hl('Character', { fg = colors.green })
  hl('Number', { fg = colors.blue })
  hl('Boolean', { fg = colors.purple })
  hl('Float', { fg = colors.blue })
  
  hl('Identifier', { fg = colors.fg })
  hl('Function', { fg = colors.fg })
  hl('Statement', { fg = colors.purple })
  hl('Conditional', { fg = colors.purple })
  hl('Repeat', { fg = colors.purple })
  hl('Label', { fg = colors.purple })
  hl('Operator', { fg = colors.fg })
  hl('Keyword', { fg = colors.purple, style = 'bold' })
  hl('Exception', { fg = colors.purple })
  
  hl('PreProc', { fg = colors.fg })
  hl('Include', { fg = colors.fg, style = 'bold' })
  hl('Define', { fg = colors.fg })
  hl('Macro', { fg = colors.orange })
  hl('PreCondit', { fg = colors.orange })
  
  hl('Type', { fg = colors.fg })
  hl('StorageClass', { fg = colors.purple })
  hl('Structure', { fg = colors.purple })
  hl('Typedef', { fg = colors.purple })
  
  hl('Special', { fg = colors.fg })
  hl('SpecialChar', { fg = colors.orange })
  hl('Tag', { fg = colors.fg })
  hl('Delimiter', { fg = colors.fg })
  hl('SpecialComment', { fg = colors.fg_dim, style = 'bold' })
  hl('Debug', { fg = colors.red })
  
  -- UI Elements
  hl('Error', { fg = colors.red, style = 'bold' })
  hl('ErrorMsg', { fg = colors.red, style = 'bold' })
  hl('WarningMsg', { fg = colors.yellow, style = 'bold' })
  hl('MoreMsg', { fg = colors.fg })
  hl('ModeMsg', { fg = colors.fg, style = 'bold' })
  hl('Question', { fg = colors.fg })
  
  hl('Cursor', { bg = colors.fg })
  hl('CursorLine', { bg = colors.bg_highlight })
  hl('CursorLineNr', { fg = colors.fg, style = 'bold' })
  hl('CursorColumn', { bg = colors.bg_highlight })
  hl('ColorColumn', { bg = colors.bg_highlight })
  
  hl('LineNr', { fg = colors.fg_dim })
  hl('SignColumn', { bg = colors.bg })
  hl('FoldColumn', { fg = colors.fg_dim, bg = colors.bg })
  hl('Folded', { fg = colors.fg_dim })
  
  hl('Visual', { bg = colors.selection })
  hl('Search', { bg = colors.yellow, fg = colors.bg })
  hl('IncSearch', { bg = colors.orange, fg = colors.bg })
  hl('CurSearch', { bg = colors.orange, fg = colors.bg })
  
  hl('MatchParen', { style = 'bold' })
  hl('NonText', { fg = colors.fg_dim })
  hl('SpecialKey', { fg = colors.blue })
  hl('Title', { fg = colors.fg, style = 'bold' })
  hl('Directory', { fg = colors.purple })
  
  -- Window/split elements
  hl('VertSplit', { fg = colors.border })
  hl('WinSeparator', { fg = colors.border })
  hl('StatusLine', { fg = colors.fg, bg = colors.bg })
  hl('StatusLineNC', { fg = colors.fg, bg = colors.bg_alt })
  hl('WinBar', { fg = colors.fg, style = 'bold' })
  hl('WinBarNC', { fg = colors.fg, style = 'bold' })
  
  -- Popup menu
  hl('Pmenu', { fg = colors.fg, bg = colors.bg_alt })
  hl('PmenuSel', { bg = colors.selection, style = 'bold' })
  hl('PmenuSbar', { bg = colors.bg_alt })
  hl('PmenuThumb', { bg = colors.selection })
  hl('PmenuMatch', { fg = colors.yellow, style = 'bold' })
  
  -- Floating windows
  hl('NormalFloat', { fg = colors.fg, bg = colors.bg_float })
  hl('FloatBorder', { fg = colors.border })
  hl('FloatTitle', { fg = colors.fg, style = 'bold' })
  
  -- Tabs
  hl('TabLine', { fg = colors.fg, bg = colors.bg_alt })
  hl('TabLineFill', { fg = colors.fg, bg = colors.bg_alt })
  hl('TabLineSel', { fg = colors.fg, bg = colors.bg, style = 'bold' })
  
  -- Diff
  hl('DiffAdd', { bg = '#1e3a1e' })
  hl('DiffChange', { bg = '#3a3a1e' })
  hl('DiffDelete', { fg = colors.red })
  hl('DiffText', { bg = colors.yellow, fg = colors.bg })
  
  -- Spell checking
  hl('SpellBad', { sp = colors.red, style = 'underline' })
  hl('SpellCap', { sp = colors.yellow, style = 'underline' })
  hl('SpellLocal', { sp = colors.blue, style = 'underline' })
  hl('SpellRare', { sp = colors.purple, style = 'underline' })
  
  -- LSP Diagnostics
  hl('DiagnosticError', { fg = colors.red, style = 'bold' })
  hl('DiagnosticWarn', { fg = colors.yellow, style = 'bold' })
  hl('DiagnosticInfo', { fg = colors.blue, style = 'bold' })
  hl('DiagnosticHint', { fg = colors.fg_dim, style = 'bold' })
  
  hl('DiagnosticUnderlineError', { sp = colors.red, style = 'underline' })
  hl('DiagnosticUnderlineWarn', { sp = colors.yellow, style = 'underline' })
  hl('DiagnosticUnderlineInfo', { sp = colors.blue, style = 'underline' })
  hl('DiagnosticUnderlineHint', { sp = colors.fg_dim, style = 'underline' })
  
  -- LSP References
  hl('LspReferenceText', { bg = colors.bg_highlight })
  hl('LspReferenceRead', { bg = colors.bg_highlight })
  hl('LspReferenceWrite', { bg = colors.bg_highlight })
  
  -- Treesitter
  hl('@variable', { fg = colors.fg })
  hl('@variable.builtin', { fg = colors.fg, style = 'bold' })
  hl('@variable.parameter', { fg = colors.fg })
  hl('@variable.member', { fg = colors.purple })
  
  hl('@constant', { fg = colors.fg })
  hl('@constant.builtin', { fg = colors.purple })
  hl('@constant.macro', { fg = colors.orange })
  
  hl('@string', { fg = colors.green })
  hl('@string.regexp', { fg = colors.orange })
  hl('@character', { fg = colors.green })
  
  hl('@number', { fg = colors.blue })
  hl('@boolean', { fg = colors.purple })
  hl('@float', { fg = colors.blue })
  
  hl('@function', { fg = colors.fg })
  hl('@function.builtin', { fg = colors.fg })
  hl('@function.macro', { fg = colors.orange })
  hl('@method', { fg = colors.fg })
  hl('@constructor', { fg = colors.fg })
  
  hl('@keyword', { fg = colors.purple, style = 'bold' })
  hl('@keyword.function', { fg = colors.purple, style = 'bold' })
  hl('@keyword.operator', { fg = colors.purple })
  hl('@keyword.return', { fg = colors.purple, style = 'bold' })
  
  hl('@operator', { fg = colors.fg })
  hl('@punctuation', { fg = colors.fg })
  hl('@punctuation.delimiter', { fg = colors.fg })
  hl('@punctuation.bracket', { fg = colors.fg })
  
  hl('@type', { fg = colors.fg })
  hl('@type.builtin', { fg = colors.fg })
  hl('@property', { fg = colors.fg })
  hl('@field', { fg = colors.fg })
  
  hl('@tag', { fg = colors.fg, style = 'bold' })
  hl('@tag.attribute', { fg = colors.fg })
  hl('@tag.delimiter', { fg = colors.fg })
  
  hl('@comment', { fg = colors.fg_dim })
  hl('@comment.documentation', { fg = colors.fg_dim })
  
  -- Special highlight groups for emphasis
  hl('Bold', { fg = colors.fg, style = 'bold' })
  hl('Italic', { fg = colors.fg, style = 'italic' })
  hl('Underlined', { style = 'underline' })
  hl('Todo', { fg = colors.fg_dim, style = 'bold' })
  
  -- Custom groups for statuslines and plugins
  hl('OrangeAccent', { fg = colors.orange, style = 'bold' })
  hl('BlueAccent', { fg = colors.blue, style = 'bold' })
  hl('GreenAccent', { fg = colors.green, style = 'bold' })
  hl('RedAccent', { fg = colors.red, style = 'bold' })
end

return M