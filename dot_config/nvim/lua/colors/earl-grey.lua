-- earl-grey.lua
-- Earl Grey colorscheme for Neovim
-- Converted from the original lush.nvim implementation
-- Source: https://github.com/jacksonludwig/vim-earl-grey

-- Setup
local M = {}

-- Color Palette
local colors = {
  foreground = "#605A52",
  background = "#FCFBF9",
  background_alt = "#F7F3EE",
  purple = "#83577D",
  blue = "#556995",
  teal = "#477A7B",
  green = "#747B4D",
  red = "#8F5652",
  orange = "#886A44",
  comment = "#9C958B", -- foreground lightened 35%
  blue_light = "#6A7EA9", -- blue lightened 15%
  visual_bg = "#CBD2E1", -- blue lightened 70%
  pmenu_sel_bg = "#E0D0BD", -- background_alt darkened 15%
  float_bg = "#F2EBE3", -- background_alt darkened 3%
}

-- Helper function
local function highlight(group, opts)
  local bg = opts.bg and "guibg=" .. opts.bg or "guibg=NONE"
  local fg = opts.fg and "guifg=" .. opts.fg or "guifg=NONE"
  local sp = opts.sp and "guisp=" .. opts.sp or ""
  local gui = opts.gui and "gui=" .. opts.gui or "gui=NONE"

  vim.cmd("highlight " .. group .. " " .. bg .. " " .. fg .. " " .. sp .. " " .. gui)
end

-- Apply colorscheme
function M.setup()
  -- Neovim terminal colors
  vim.g.terminal_color_0 = colors.background
  vim.g.terminal_color_1 = colors.red
  vim.g.terminal_color_2 = colors.green
  vim.g.terminal_color_3 = colors.orange
  vim.g.terminal_color_4 = colors.blue
  vim.g.terminal_color_5 = colors.purple
  vim.g.terminal_color_6 = colors.teal
  vim.g.terminal_color_7 = colors.foreground
  vim.g.terminal_color_8 = colors.comment
  vim.g.terminal_color_9 = colors.red
  vim.g.terminal_color_10 = colors.green
  vim.g.terminal_color_11 = colors.orange
  vim.g.terminal_color_12 = colors.blue
  vim.g.terminal_color_13 = colors.purple
  vim.g.terminal_color_14 = colors.teal
  vim.g.terminal_color_15 = colors.foreground

  -- Clear existing highlights
  vim.cmd("highlight clear")

  -- Set background
  vim.o.background = "light"
  vim.g.colors_name = "earl-grey"

  -- Basic UI elements
  highlight("Normal", { bg = colors.background, fg = colors.foreground })
  highlight("Comment", { fg = colors.comment })
  highlight("EndOfBuffer", { fg = colors.comment })
  highlight("LineNr", { fg = colors.comment })
  highlight("Keyword", { fg = colors.purple })
  highlight("Identifier", { fg = colors.blue })
  highlight("Operator", { fg = colors.foreground })
  highlight("Delimiter", { fg = colors.blue })
  highlight("Special", { fg = colors.purple })
  highlight("Number", { fg = colors.teal })
  highlight("String", { fg = colors.green })
  highlight("Constant", { fg = colors.teal })
  highlight("Conditional", { fg = colors.purple })
  highlight("Repeat", { fg = colors.purple })
  highlight("Error", { fg = colors.red })
  highlight("ErrorMsg", { fg = colors.red })
  highlight("WarningMsg", { fg = colors.orange })
  highlight("Type", { fg = colors.foreground })
  highlight("Function", { fg = colors.foreground })
  highlight("PreProc", { fg = colors.orange })
  highlight("Statement", { fg = colors.purple })
  highlight("NormalFloat", { bg = colors.float_bg, fg = colors.foreground })
  highlight("DiffDelete", { fg = colors.red })
  highlight("DiffAdd", { fg = colors.green })
  highlight("DiffChange", { fg = colors.orange })
  highlight("VertSplit", { fg = colors.foreground })
  highlight("Visual", { bg = colors.visual_bg })
  highlight("Search", { bg = colors.purple, fg = colors.background })
  highlight("IncSearch", { bg = colors.blue, fg = colors.background })
  highlight("NonText", { fg = colors.blue_light })
  highlight("SpecialKey", { fg = colors.blue_light })
  highlight("Directory", { fg = colors.teal })

  -- Emphasized elements
  highlight("Title", { fg = colors.teal, gui = "bold" })
  highlight("htmlH2", { fg = colors.blue, gui = "bold" })
  highlight("NormalNB", { bg = colors.background_alt })

  -- Cursor and selection
  highlight("Cursor", { bg = colors.foreground, fg = colors.background })
  highlight("MatchParen", { bg = colors.visual_bg, gui = "underline" })

  -- Line highlighting
  highlight("CursorLine", { bg = colors.background_alt })
  highlight("ColorColumn", { bg = colors.background_alt })
  highlight("SignColumn", { bg = colors.background })
  highlight("CursorLineNr", { bg = colors.background_alt })

  -- Text formatting
  highlight("Bold", { gui = "bold" })
  highlight("Underlined", { gui = "underline" })
  highlight("Italic", { gui = "italic" })

  -- Popup menu
  highlight("Pmenu", { bg = colors.background_alt })
  highlight("PmenuSel", { bg = colors.pmenu_sel_bg })

  -- Todo and spell checking
  highlight("Todo", { bg = colors.float_bg, fg = colors.teal })
  highlight("SpellBad", { gui = "underline", fg = colors.red })
  highlight("SpellCap", { gui = "underline", fg = colors.blue })
  highlight("SpellRare", { gui = "underline", fg = colors.orange })
  highlight("SpellLocal", { gui = "underline", fg = colors.purple })

  -- LSP diagnostics
  highlight("DiagnosticError", { fg = colors.red })
  highlight("DiagnosticWarn", { fg = colors.orange })
  highlight("DiagnosticHint", { fg = colors.blue })
  highlight("DiagnosticInfo", { fg = colors.purple })
  highlight("DiagnosticUnderlineError", { gui = "underline", sp = colors.red })
  highlight("DiagnosticUnderlineWarn", { gui = "underline", sp = colors.orange })
  highlight("DiagnosticUnderlineHint", { gui = "underline", sp = colors.blue })
  highlight("DiagnosticUnderlineInfo", { gui = "underline", sp = colors.purple })

  -- LSP references
  highlight("LspReferenceText", { bg = colors.background_alt })
  highlight("LspReferenceRead", { bg = colors.background_alt })
  highlight("LspReferenceWrite", { bg = colors.background_alt })
end

return M
