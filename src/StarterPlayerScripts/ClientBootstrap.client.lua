--!strict
--[[ Only client UI entry. Rojo → StarterPlayerScripts.Client ]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local function showFatal(msg: string)
	warn("[GameUI]", msg)
	local sg = Instance.new("ScreenGui")
	sg.Name = "GameUI_Error"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 100
	sg.Parent = playerGui
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(0.8, 0, 0, 80)
	t.Position = UDim2.fromScale(0.1, 0.4)
	t.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	t.TextColor3 = Color3.fromRGB(255, 220, 220)
	t.TextWrapped = true
	t.Font = Enum.Font.GothamBold
	t.TextSize = 16
	t.Text = "GameUI error:\n" .. msg
	t.Parent = sg
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = t
end

local ok, err = pcall(function()
	local App = require(script.Parent.App)
	App.Start()
	local MobInspect = require(script.Parent.MobInspect)
	MobInspect.Init()
end)

if not ok then
	showFatal(tostring(err))
end
