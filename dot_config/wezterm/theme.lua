local wezterm = require("wezterm")

local sync_with_system = false

local dark_theme = ({
	"astromouse (terminal.sexy)", -- [1],
	"Catppuccin Frappe", -- [2]
	"rose-pine", -- [3], not working yet
	"Rosé Pine (base16)", -- [4]
	"WildCherry", -- [5]
	"nord", -- [6]
	"Builtin Pastel Dark", -- [7]
	"Brogrammer (base16)", -- [8]
	"City Streets (terminal.sexy)", -- [9]
	"Catppuccin Mocha", -- [10]
	"Tokyo Night", -- [11]
})[11]

local light_theme = ({
	"Catppuccin Latte", -- [1]
})[1]

local function scheme_for_appearance(appearance)
	if appearance:find("Dark") then
		return dark_theme
	end

	return light_theme
end

if sync_with_system then
	wezterm.on("window-config-reloaded", function(window)
		local overrides = window:get_config_overrides() or {}
		local appearance = window:get_appearance()
		local scheme = scheme_for_appearance(appearance)
		if overrides.color_scheme ~= scheme then
			overrides.color_scheme = scheme
			window:set_config_overrides(overrides)
		end
	end)
end

return {
	color_scheme = dark_theme,
	-- mapping tmux keys to wezterm
	-- leader = { key = "a", mods = "CTRL" },
	-- keys = {
	-- 	{ key = "a", mods = "LEADER|CTRL", action = wezterm.action({ SendString = "\x01" }) },
	-- 	{ key = "-", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
	-- 	{
	-- 		key = "\\",
	-- 		mods = "LEADER",
	-- 		action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }),
	-- 	},
	-- 	{ key = "-", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
	-- 	{ key = "v", mods = "LEADER", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
	-- 	{ key = "o", mods = "LEADER", action = "TogglePaneZoomState" },
	-- 	{ key = "z", mods = "LEADER", action = "TogglePaneZoomState" },
	-- 	{ key = "c", mods = "LEADER", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
	-- 	{ key = "h", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Left" }) },
	-- 	{ key = "j", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Down" }) },
	-- 	{ key = "k", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Up" }) },
	-- 	{ key = "l", mods = "LEADER", action = wezterm.action({ ActivatePaneDirection = "Right" }) },
	-- 	{ key = "H", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Left", 5 } }) },
	-- 	{ key = "J", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Down", 5 } }) },
	-- 	{ key = "K", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Up", 5 } }) },
	-- 	{ key = "L", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Right", 5 } }) },
	-- 	{ key = "1", mods = "LEADER", action = wezterm.action({ ActivateTab = 0 }) },
	-- 	{ key = "2", mods = "LEADER", action = wezterm.action({ ActivateTab = 3 }) },
	-- 	{ key = "3", mods = "LEADER", action = wezterm.action({ ActivateTab = 2 }) },
	-- 	{ key = "4", mods = "LEADER", action = wezterm.action({ ActivateTab = 3 }) },
	-- 	{ key = "5", mods = "LEADER", action = wezterm.action({ ActivateTab = 4 }) },
	-- 	{ key = "6", mods = "LEADER", action = wezterm.action({ ActivateTab = 5 }) },
	-- 	{ key = "7", mods = "LEADER", action = wezterm.action({ ActivateTab = 6 }) },
	-- 	{ key = "8", mods = "LEADER", action = wezterm.action({ ActivateTab = 7 }) },
	-- 	{ key = "9", mods = "LEADER", action = wezterm.action({ ActivateTab = 8 }) },
	-- 	{ key = "&", mods = "LEADER|SHIFT", action = wezterm.action({ CloseCurrentTab = { confirm = true } }) },
	-- 	{ key = "d", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
	-- 	{ key = "x", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
	-- },
}
