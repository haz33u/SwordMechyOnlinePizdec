--!strict
--[[
	In-game settings panel. Toggle groups: Visual, VFX, SFX, Music.
	Mounts into the shared modal/screen system.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local Settings = require(script.Parent.Settings)
local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)

local SettingsUI = {}

local GROUPS: { { title: string, keys: { Settings.SettingKey } } } = {
	{
		title = "Visual",
		keys = { "visualPets", "visualAuras", "visualWeapons" },
	},
	{
		title = "VFX",
		keys = { "vfxCombat", "vfxLoot", "vfxWorld" },
	},
	{
		title = "SFX",
		keys = { "sfxUi", "sfxCombat", "sfxWorld" },
	},
	{
		title = "Music",
		keys = { "musicAmbient", "musicDungeon" },
	},
}

local KEY_LABELS: { [Settings.SettingKey]: string } = {
	visualPets = "Show Pets",
	visualAuras = "Show Auras",
	visualWeapons = "Show Weapon FX",
	vfxCombat = "Combat VFX",
	vfxLoot = "Loot VFX",
	vfxWorld = "World VFX",
	sfxUi = "UI Sounds",
	sfxCombat = "Combat Sounds",
	sfxWorld = "World Sounds",
	musicAmbient = "Ambient Music",
	musicDungeon = "Dungeon Music",
}

local function makeToggle(parent: Instance, key: Settings.SettingKey, scope: any)
	local enabled = scope:Value(Settings.Get(key))

	Settings.OnChange(key, function(v)
		enabled:set(v)
	end)

	local row = Instance.new("Frame")
	row.Name = "Row_" .. key
	row.Size = UDim2.new(1, 0, 0, 38)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -70, 1, 0)
	label.Position = UDim2.fromOffset(0, 0)
	label.BackgroundTransparency = 1
	label.Text = KEY_LABELS[key] or key
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 14
	label.TextColor3 = T.Text
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local btn = Instance.new("TextButton")
	btn.Name = "Toggle"
	btn.Size = UDim2.fromOffset(54, 26)
	btn.Position = UDim2.new(1, -54, 0.5, -13)
	btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
	btn.Text = ""
	btn.AutoButtonColor = false
	btn.Parent = row

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 13)
	corner.Parent = btn

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.Size = UDim2.fromOffset(20, 20)
	knob.Position = UDim2.fromOffset(3, 3)
	knob.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
	knob.Parent = btn

	local kc = Instance.new("UICorner")
	kc.CornerRadius = UDim.new(1, 0)
	kc.Parent = knob

	local function refresh(v: boolean)
		if v then
			btn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
			knob.Position = UDim2.fromOffset(31, 3)
		else
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
			knob.Position = UDim2.fromOffset(3, 3)
		end
	end

	scope:Observer(enabled):onChange(function()
		refresh(Fusion.peek(enabled))
	end)
	refresh(Settings.Get(key))

	btn.Activated:Connect(function()
		local v = Settings.Toggle(key)
		refresh(v)
	end)

	return row
end

function SettingsUI.Mount(parent: Instance, store: any): any
	local scope = Fusion.scoped(Fusion)

	local root = Instance.new("Frame")
	root.Name = "SettingsPanel"
	root.Size = UDim2.fromOffset(360, 460)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.BackgroundColor3 = T.Glass
	root.BorderSizePixel = 0
	root.Parent = parent

	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0, 14)
	rc.Parent = root

	local stroke = Instance.new("UIStroke")
	stroke.Color = T.Stroke
	stroke.Thickness = 1
	stroke.Parent = root

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 46)
	title.BackgroundTransparency = 1
	title.Text = "Settings"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 20
	title.TextColor3 = T.Text
	title.Parent = root

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.Size = UDim2.fromOffset(30, 30)
	close.Position = UDim2.new(1, -36, 0, 8)
	close.BackgroundTransparency = 1
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = T.TextPrimary
	close.Parent = root

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1, -24, 1, -70)
	scroll.Position = UDim2.fromOffset(12, 56)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(120, 120, 130)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.Parent = root

	local list = Instance.new("UIListLayout")
	list.Padding = UDim.new(0, 10)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = scroll

	for _, group in ipairs(GROUPS) do
		local gf = Instance.new("Frame")
		gf.Name = "Group_" .. group.title
		gf.Size = UDim2.new(1, 0, 0, 0)
		gf.BackgroundTransparency = 1
		gf.AutomaticSize = Enum.AutomaticSize.Y
		gf.Parent = scroll

		local gt = Instance.new("TextLabel")
		gt.Name = "GroupTitle"
		gt.Size = UDim2.new(1, 0, 0, 24)
		gt.BackgroundTransparency = 1
		gt.Text = group.title
		gt.Font = Enum.Font.GothamBold
		gt.TextSize = 15
		gt.TextColor3 = T.Accent
		gt.TextXAlignment = Enum.TextXAlignment.Left
		gt.Parent = gf

		local rows = Instance.new("Frame")
		rows.Name = "Rows"
		rows.Size = UDim2.new(1, 0, 0, 0)
		rows.Position = UDim2.fromOffset(0, 28)
		rows.BackgroundTransparency = 1
		rows.AutomaticSize = Enum.AutomaticSize.Y
		rows.Parent = gf

		local rlist = Instance.new("UIListLayout")
		rlist.Padding = UDim.new(0, 6)
		rlist.SortOrder = Enum.SortOrder.LayoutOrder
		rlist.Parent = rows

		for _, key in ipairs(group.keys) do
			makeToggle(rows, key, scope)
		end
	end

	close.Activated:Connect(function()
		store:CloseModal()
	end)

	local api = {
		Frame = root,
		Show = function()
			root.Visible = true
		end,
		Hide = function()
			root.Visible = false
		end,
	}
	return api
end

return SettingsUI
