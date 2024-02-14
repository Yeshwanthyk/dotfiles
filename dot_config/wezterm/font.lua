local wezterm = require("wezterm")

local font_size = 18
local bold = false
local font_family = ({
	"BerkeleyMono Nerd Font Mono Plus Font Awesome Plus Font Awesome Extension Plus Octicons Plus Power Symbols Plus Codicons Plus Pomicons Plus Font Logos Plus Material Design Icons Plus Weather Icons", -- [1]
	"DankMono Nerd Font Mono Plus Font Awesome Plus Font Awesome Extension Plus Octicons Plus Power Symbols Plus Codicons Plus Pomicons Plus Font Logos Plus Material Design Icons Plus Weather Icons", -- [2]
	"JetBrainsMono Nerd Font", -- [3]
	"FiraCode Nerd Font Mono", -- [4]
})[1]

local options = {}
if bold then
	options["weight"] = "Bold"
end

local font = wezterm.font(font_family, options)

return {
	font = font,
	font_size = font_size,
}
