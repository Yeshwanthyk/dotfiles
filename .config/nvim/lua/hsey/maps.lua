local keymap = vim.keymap

-- New tab
keymap.set('n', 'te', ':tabedit')

-- Move window
keymap.set('n', '<Space>', '<C-w>w')

-- New tab
keymap.set('n', 'te', ':tabedit')

-- Split window
keymap.set('n', 'ss', ':split<Return><C-w>w')
keymap.set('n', 'sv', ':vsplit<Return><C-w>w')

-- undotree
keymap.set('n', '<Leader>u', ':UndotreeShow<CR>', { noremap = true, silent = true })
