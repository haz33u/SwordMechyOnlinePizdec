--!strict
--[[ Client entry — GameUI (brief + OnyxUI/Fusion stack). ]]

local success, err = pcall(function()
	local App = require(script.Parent.App)
	App.Start()
end)

if not success then
	warn("[GameUI] bootstrap failed:", err)
end
