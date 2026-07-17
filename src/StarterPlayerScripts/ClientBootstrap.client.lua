--!strict
--[[
	Only entry for client UI. Rojo → StarterPlayerScripts.Client
	Never put ScreenGui GameUI in StarterGui.
]]

local ok, err = pcall(function()
	local App = require(script.Parent.App)
	App.Start()
end)

if not ok then
	warn("[GameUI] bootstrap failed:", err)
end
