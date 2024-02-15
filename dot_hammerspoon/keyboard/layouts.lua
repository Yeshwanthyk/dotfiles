-- https://github.com/mheap/dotfiles/blob/main/dot_hammerspoon/Layouts.lua
function defineLayout(name, key, layout)
	hs.hotkey.bind({ "cmd", "alt", "ctrl", "shift" }, tostring(key), function()
		hs.alert.show("Layout: " .. name)
		for i, app in ipairs(layout) do
			adjustWindowsOfApp(app[1], app[2])
			if app[3] then
				focusIfLaunched(app[1])
			end
		end
	end)
end

defineLayout("Work", 1, {
	{ "Things", "0,0 2x2" },
	{ "Spotify", "2,0 4x2", true },
	{ "Slack", "6,0 2x2" },
})

defineLayout("Code", 2, {
	{ "WezTerm", "0,0 6x2" },
	{ "Google Chrome", "6,0 2x2", true },
})

defineLayout("Writing", 3, {
	{ "WezTerm", "0,0 4x2" },
	{ "Obsidian", "4,0 4x2", true },
})
defineLayout("Lc", 4, {
	{ "WezTerm", "0,0 6x2" },
	{ "Orion", "6,0 2x2", true },
})

-- defineLayout("Planning", 4, {
-- 	{'Sunsama', '0,0 4x2'},
-- 	{'Slack', '4,0 4x2', true}
-- });
--
-- defineLayout("Music", 5, {
-- 	{'Spotify', '2,0 4x2', true},
-- });

-- defineLayout("Terminal", 6, {
-- 	{'iTerm2', '2,0 4x2', true},
-- });

function fullscreenAllWindows()
	for i, win in ipairs(hs.window:allWindows()) do
		hs.grid.set(win, "0,0 6x4")
	end
end

function adjustWindowsOfApp(appName, gridSettings)
	local app = hs.application.get(appName)
	local wins
	if app then
		wins = app:allWindows()
	end
	if wins then
		for i, win in ipairs(wins) do
			hs.grid.set(win, gridSettings)
		end
		focusIfLaunched(appName)
	end
end

function focusIfLaunched(appName)
	local app = hs.application.get(appName)
	if app then
		app:activate()
	end
end
