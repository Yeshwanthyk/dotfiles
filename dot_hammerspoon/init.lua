require("keyboard.layouts")
hyper = { "cmd", "alt", "ctrl", "shift" }

-- bind reload at start in case of error later in config
-- hs.hotkey.bind(hyper, "R", hs.reload)
-- hs.hotkey.bind(hyper, "Y", hs.toggleConsole)

-- hs.loadSpoon("MoveWindows"):start():bindHotKeys({ toggle = { hyper, "m" } })

local HyperShortcuts = {
	{ "A", "iTerm" },
	{ "T", "Things3" },
	{ "L", "Logseq" },
	{ "O", "Obsidian" },
	{ "Q", "Spotify" },
	{ "S", "Arc" },
	{ "W", "Slack" },
	{ "Y", "FreeTube" },
}

-- Resize 50%
-- https://github.com/jakubdyszkiewicz/dotfishy/blob/master/hammerspoon/init.lua
hs.hotkey.bind(hyper, "[", function()
	hs.grid.set(hs.window.focusedWindow(), "0,0 4x4")
end)
hs.hotkey.bind(hyper, "]", function()
	hs.grid.set(hs.window.focusedWindow(), "4,0 4x4")
end)
hs.hotkey.bind(hyper, ";", function()
	hs.grid.set(hs.window.focusedWindow(), "0,0 4x1")
end)
hs.hotkey.bind(hyper, "'", function()
	hs.grid.set(hs.window.focusedWindow(), "0,2 4x1")
end)
hs.hotkey.bind(hyper, "\\", hs.grid.maximizeWindow)

for _, shortcut in ipairs(HyperShortcuts) do
	hs.hotkey.bind(hyper, shortcut[1], function()
		hs.application.launchOrFocus(shortcut[2])
	end)
end

function reframeFocusedWindow()
	local win = hs.window.focusedWindow()
	local maximizedFrame = win:screen():frame()
	maximizedFrame.x = maximizedFrame.x + 15
	maximizedFrame.y = maximizedFrame.y + 15
	maximizedFrame.w = maximizedFrame.w - 30
	maximizedFrame.h = maximizedFrame.h - 30

	local leftFrame = win:screen():frame()
	leftFrame.x = leftFrame.x + 15
	leftFrame.y = leftFrame.y + 15
	leftFrame.w = leftFrame.w / 2 - 15
	leftFrame.h = leftFrame.h - 30

	local rightFrame = win:screen():frame()
	rightFrame.x = rightFrame.w / 2
	rightFrame.y = rightFrame.y + 15
	rightFrame.w = rightFrame.w / 2 - 15
	rightFrame.h = rightFrame.h - 30

	if win:frame() == maximizedFrame then
		win:setFrame(leftFrame)
		return
	end

	if win:frame() == leftFrame then
		win:setFrame(rightFrame)
		return
	end

	win:setFrame(maximizedFrame)
end

-- almost maximize
-- hs.hotkey.bind(hyper, "\\", reframeFocusedWindow)

-- Grid
local padding = 15
hs.grid.setMargins(hs.geometry.size(padding, padding))
hs.grid.setGrid("8x2")

-- hs.hotkey.bind(hyper, "g", function()
-- 	hs.grid.show()
-- end)

-- require("keyboard.yabai")
