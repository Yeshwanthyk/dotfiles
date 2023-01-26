local status, nvimtree = pcall(require, "nvim-tree")
if (not status) then return end

nvimtree.setup({
	sort_by = "case_sensitive",
	view = {
	  adaptive_size = true,
	  mappings = {
	    list = {
	      { key = "u", action = "dir_up" },
	    },
	  },
	},
	renderer = {
	  group_empty = true,
	},
	filters = {
	  dotfiles = true,
	},
})

vim.keymap.set('n', '<Leader>e', '<cmd>NvimTreeFindFileToggle<cr>', { silent = true })
