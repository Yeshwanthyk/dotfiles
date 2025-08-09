-- minimal-dark-toronto.lua
-- Dark, high-contrast Neovim colorscheme built from user's palette

-- Clear existing highlights and reset syntax
vim.cmd('highlight clear')
if vim.g.syntax_on == 1 then
  vim.cmd('syntax reset')
end

vim.o.background = 'dark'
vim.g.colors_name = 'minimal-dark-toronto'

local defaults = {
  transparent = false,        -- don't set Normal bg
  bold_keywords = false,
  italic_comments = true,
  dim_inactive = false,       -- dim NormalNC
}

local palette = {
  bg            = "#000000",
  fg            = "#ffffff",
  dim           = "#cccccc",
  comment       = "#b0b0b0",  -- slightly cooler than dim to separate from UI text
  string        = "#c8a2c8",  -- lavender
  number        = "#88d5ff",  -- light blue
  keyword       = "#ffffff",  -- white for keywords (def, class, if, etc.)
  method        = "#87ceeb",  -- sky blue (for methods only)
  class         = "#5f9ea0",  -- cadet blue-green (for classes and other names)
  type_builtin  = "#4ec9b0",  -- cyan
  variable      = "#dcdcdc",  -- light gray (slightly dimmer than fg)
  decorator     = "#cc6600",  -- dark orange
  red           = "#ff8899",
  yellow        = "#b8860b",
  cyan          = "#4ec9b0",

  -- UI tints
  ui_bg         = "#0f0f0f",
  ui_bg_alt     = "#111111",
  cursorline    = "#2a2a2a",
  visual        = "#333333",
  border        = "#262626",
}

local function hi(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

-- Terminal colors
vim.g.terminal_color_0  = palette.bg
vim.g.terminal_color_1  = palette.red
vim.g.terminal_color_2  = palette.method
vim.g.terminal_color_3  = palette.yellow
vim.g.terminal_color_4  = palette.number
vim.g.terminal_color_5  = palette.string
vim.g.terminal_color_6  = palette.cyan
vim.g.terminal_color_7  = palette.fg
vim.g.terminal_color_8  = palette.border
vim.g.terminal_color_9  = palette.red
vim.g.terminal_color_10 = palette.method
vim.g.terminal_color_11 = palette.yellow
vim.g.terminal_color_12 = palette.number
vim.g.terminal_color_13 = palette.string
vim.g.terminal_color_14 = palette.cyan
vim.g.terminal_color_15 = palette.fg

local bg = defaults.transparent and "NONE" or palette.bg

-- Base UI
hi('Normal',        { fg = palette.fg, bg = bg })
hi('NormalNC',      { fg = defaults.dim_inactive and palette.dim or palette.fg, bg = bg })
hi('SignColumn',    { bg = bg })
hi('EndOfBuffer',   { fg = palette.border, bg = bg })
hi('NonText',       { fg = palette.border })
hi('WinSeparator',  { fg = palette.border, bg = bg })
hi('VertSplit',     { fg = palette.border, bg = bg })
hi('ColorColumn',   { bg = palette.ui_bg_alt })
hi('Conceal',       { fg = palette.border })

-- Cursor & selection
hi('Cursor',        { reverse = true })
hi('CursorLine',    { bg = palette.cursorline })
hi('CursorColumn',  { bg = palette.cursorline })
hi('Visual',        { bg = palette.visual })
hi('VisualNOS',     { bg = palette.visual })
hi('MatchParen',    { fg = palette.yellow, bold = true })

-- Line numbers & folds
hi('LineNr',        { fg = palette.dim })
hi('CursorLineNr',  { fg = palette.fg, bold = true })
hi('Folded',        { fg = palette.dim, bg = palette.ui_bg })
hi('FoldColumn',    { fg = palette.dim, bg = bg })

-- Search
hi('Search',        { fg = palette.bg, bg = palette.yellow })
hi('IncSearch',     { fg = palette.bg, bg = palette.number, bold = true })
hi('Substitute',    { fg = palette.bg, bg = palette.method, bold = true })

-- Menus & popups
hi('Pmenu',         { fg = palette.fg, bg = palette.ui_bg })
hi('PmenuSel',      { fg = palette.bg, bg = palette.method, bold = true })
hi('PmenuSbar',     { bg = palette.ui_bg_alt })
hi('PmenuThumb',    { bg = palette.border })

-- Statusline & tabs
hi('StatusLine',    { fg = palette.fg, bg = palette.ui_bg, bold = true })
hi('StatusLineNC',  { fg = palette.dim, bg = palette.ui_bg })
hi('TabLine',       { fg = palette.dim, bg = palette.ui_bg })
hi('TabLineSel',    { fg = palette.bg, bg = palette.method, bold = true })
hi('TabLineFill',   { fg = palette.dim, bg = palette.ui_bg })
hi('WinBar',        { fg = palette.dim, bg = bg })
hi('WinBarNC',      { fg = palette.border, bg = bg })

-- Diagnostics (LSP & general)
hi('Error',         { fg = palette.red, bold = true })
hi('ErrorMsg',      { fg = palette.red, bold = true })
hi('WarningMsg',    { fg = palette.yellow, bold = true })

hi('DiagnosticError', { fg = palette.red, bold = true })
hi('DiagnosticWarn',  { fg = palette.yellow, bold = true })
hi('DiagnosticInfo',  { fg = palette.number, bold = true })
hi('DiagnosticHint',  { fg = palette.dim, bold = true })

hi('DiagnosticVirtualTextError', { fg = palette.red, bg = palette.ui_bg_alt })
hi('DiagnosticVirtualTextWarn',  { fg = palette.yellow, bg = palette.ui_bg_alt })
hi('DiagnosticVirtualTextInfo',  { fg = palette.number, bg = palette.ui_bg_alt })
hi('DiagnosticVirtualTextHint',  { fg = palette.dim, bg = palette.ui_bg_alt })

hi('DiagnosticUnderlineError', { sp = palette.red, undercurl = true })
hi('DiagnosticUnderlineWarn',  { sp = palette.yellow, undercurl = true })
hi('DiagnosticUnderlineInfo',  { sp = palette.number, undercurl = true })
hi('DiagnosticUnderlineHint',  { sp = palette.dim, undercurl = true })

hi('LspReferenceText',  { bg = palette.ui_bg_alt })
hi('LspReferenceRead',  { bg = palette.ui_bg_alt })
hi('LspReferenceWrite', { bg = palette.ui_bg_alt })
hi('LspSignatureActiveParameter', { fg = palette.yellow, bold = true })
hi('LspInlayHint', { fg = palette.dim, bg = palette.ui_bg })

-- Basic syntax
hi('Comment',      { fg = palette.comment, italic = defaults.italic_comments })
hi('String',       { fg = palette.string })
hi('Character',    { fg = palette.string })
hi('Number',       { fg = palette.number })
hi('Float',        { fg = palette.number })
hi('Boolean',      { fg = palette.fg, bold = true })
hi('Constant',     { fg = palette.fg })
hi('Identifier',   { fg = palette.variable })
hi('Function',     { fg = palette.method, bold = true })

hi('Statement',    { fg = palette.keyword, bold = defaults.bold_keywords })
hi('Conditional',  { fg = palette.keyword, bold = defaults.bold_keywords })
hi('Repeat',       { fg = palette.keyword, bold = defaults.bold_keywords })
hi('Label',        { fg = palette.keyword })
hi('Operator',     { fg = palette.fg })
hi('Keyword',      { fg = palette.keyword, bold = defaults.bold_keywords })
hi('Exception',    { fg = palette.keyword })

hi('PreProc',      { fg = palette.fg })
hi('Define',       { fg = palette.fg })
hi('Include',      { fg = palette.fg, bold = true })
hi('Macro',        { fg = palette.decorator })
hi('PreCondit',    { fg = palette.decorator })

hi('Type',         { fg = palette.class, bold = true })
hi('StorageClass', { fg = palette.fg })
hi('Structure',    { fg = palette.class, bold = true })
hi('Typedef',      { fg = palette.fg })

hi('Special',      { fg = palette.method })
hi('SpecialChar',  { fg = palette.method })
hi('Tag',          { fg = palette.keyword })
hi('Delimiter',    { fg = palette.fg })
hi('SpecialComment', { fg = palette.comment, italic = true })
hi('Debug',        { fg = palette.red })

hi('Todo',         { fg = palette.bg, bg = palette.yellow, bold = true })

-- Treesitter (TS) groups
hi('@variable',            { fg = palette.variable })
hi('@variable.builtin',    { fg = palette.variable, bold = true })
hi('@variable.parameter',  { fg = palette.variable })
hi('@variable.member',     { fg = palette.method }) -- properties/fields teal

hi('@field',               { fg = palette.method })
hi('@property',            { fg = palette.method })
hi('@constant',            { fg = palette.fg })
hi('@constant.builtin',    { fg = palette.fg, bold = true })
hi('@constant.macro',      { fg = palette.decorator })

hi('@string',              { fg = palette.string })
hi('@string.regex',        { fg = palette.string })
hi('@string.escape',       { fg = palette.yellow })
hi('@character',           { fg = palette.string })
hi('@number',              { fg = palette.number })
hi('@boolean',             { fg = palette.fg, bold = true })
hi('@float',               { fg = palette.number })

hi('@function',            { fg = palette.method, bold = true })
hi('@function.builtin',    { fg = palette.method, bold = true })
hi('@method',              { fg = palette.method, bold = true })
hi('@constructor',         { fg = palette.class, bold = true })
hi('@parameter',           { fg = palette.variable })

hi('@keyword',             { fg = palette.keyword, bold = defaults.bold_keywords })
hi('@keyword.function',    { fg = palette.keyword, bold = defaults.bold_keywords })
hi('@keyword.operator',    { fg = palette.fg })
hi('@keyword.return',      { fg = palette.keyword, bold = defaults.bold_keywords })

hi('@type',                { fg = palette.class, bold = true })
hi('@type.builtin',        { fg = palette.type_builtin })
hi('@type.definition',     { fg = palette.class, bold = true })

hi('@namespace',           { fg = palette.class })
hi('@symbol',              { fg = palette.method })

hi('@punctuation',         { fg = palette.fg })
hi('@punctuation.bracket', { fg = palette.fg })
hi('@punctuation.delimiter', { fg = palette.fg })

-- Decorators / attributes
hi('@attribute',           { fg = palette.decorator })
hi('@decorator',           { fg = palette.decorator })
hi('pythonDecorator',      { fg = palette.decorator })

-- Diffs & VCS
hi('DiffAdd',    { fg = palette.method })
hi('DiffChange', { fg = palette.number })
hi('DiffDelete', { fg = palette.red })
hi('DiffText',   { fg = palette.number, bold = true })

hi('GitSignsAdd',    { fg = palette.method })
hi('GitSignsChange', { fg = palette.number })
hi('GitSignsDelete', { fg = palette.red })

-- Spell
hi('SpellBad',   { sp = palette.red, undercurl = true })
hi('SpellCap',   { sp = palette.number, undercurl = true })
hi('SpellLocal', { sp = palette.method, undercurl = true })
hi('SpellRare',  { sp = palette.string, undercurl = true })

-- Quickfix
hi('QuickFixLine', { bg = palette.ui_bg_alt, bold = true })
hi('SpecialKey',   { fg = palette.border })

-- Telescope (optional but nice)
hi('TelescopeBorder',       { fg = palette.border, bg = palette.ui_bg })
hi('TelescopeNormal',       { fg = palette.fg, bg = palette.ui_bg })
hi('TelescopeSelection',    { fg = palette.bg, bg = palette.method, bold = true })
hi('TelescopeSelectionCaret',{ fg = palette.bg, bg = palette.method })
hi('TelescopeMatching',     { fg = palette.number, bold = true })

-- File Explorer / Directory highlighting
hi('Directory', { fg = palette.method })

-- Netrw (built-in file explorer)
hi('netrwDir', { fg = palette.method })
hi('netrwClassify', { fg = palette.method })
hi('netrwLink', { fg = palette.number })
hi('netrwSymLink', { fg = palette.number })
hi('netrwExe', { fg = palette.string })
hi('netrwComment', { fg = palette.comment })
hi('netrwList', { fg = palette.fg })
hi('netrwHelpCmd', { fg = palette.keyword })
hi('netrwCmdSep', { fg = palette.dim })
hi('netrwVersion', { fg = palette.dim })

-- NvimTree / Neo-tree (generic links so either plugin benefits)
hi('NvimTreeNormal',   { fg = palette.fg, bg = palette.ui_bg })
hi('NvimTreeFolderName',{ fg = palette.method })
hi('NvimTreeRootFolder',{ fg = palette.keyword, bold = true })
hi('NvimTreeOpenedFile',{ fg = palette.method, bold = true })