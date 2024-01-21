local wezterm = require("wezterm")

return {
	-- Smart tab bar [distraction-free mode]
	hide_tab_bar_if_only_one_tab = true,

	-- Color scheme
	-- https://wezfurlong.org/wezterm/config/appearance.html

	window_background_opacity = 1,
	initial_cols = 150,
	initial_rows = 40,

	-- Font configuration
	-- https://wezfurlong.org/wezterm/config/fonts.html
	font = wezterm.font("JetBrains Mono"),
	font_size = 12.0,

	-- Disable ligatures
	-- https://wezfurlong.org/wezterm/config/font-shaping.html
	harfbuzz_features = { "calt=0", "clig=0", "liga=0" },

	leader = { key = "a", mods = "CMD", timeout_milliseconds = 1000 },
	keys = {
		{
			key = "|",
			mods = "LEADER|SHIFT",
			action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
		},
		{
			key = "-",
			mods = "LEADER",
			action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
		},
	},
}
