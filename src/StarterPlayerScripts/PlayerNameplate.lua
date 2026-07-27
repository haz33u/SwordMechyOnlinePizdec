--!strict
--[[
	Overhead Title | Nick — plain TextLabels, fixed TextSize.
	Billboard size pinned via DistanceLower/UpperLimit (doesn't scale with cam).
]]

local Players = game:GetService("Players")

local Titles = require(script.Parent.Titles)

local PlayerNameplate = {}

local TAG = "SM_Nameplate"
-- Screen-size pin distance (studs). Same lower+upper = constant on-screen size.
local PIN_DIST = 28

local function clearOld(parent: Instance)
	local old = parent:FindFirstChild(TAG)
	if old then
		old:Destroy()
	end
end

local function makePart(name: string, order: number, parent: Instance, textSize: number): TextLabel
	local lab = Instance.new("TextLabel")
	lab.Name = name
	lab.BackgroundTransparency = 1
	lab.BorderSizePixel = 0
	lab.Size = UDim2.fromOffset(0, textSize + 8)
	lab.AutomaticSize = Enum.AutomaticSize.X
	lab.LayoutOrder = order
	lab.Font = Titles.Font
	lab.TextSize = textSize
	lab.TextScaled = false
	lab.TextWrapped = false
	lab.RichText = false
	lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lab.TextStrokeTransparency = 0.4
	lab.TextXAlignment = Enum.TextXAlignment.Center
	lab.TextYAlignment = Enum.TextYAlignment.Center
	lab.Text = ""
	lab.Parent = parent
	return lab
end

local function paint(bb: BillboardGui, store: any)
	local plr = Players.LocalPlayer
	local nick = (plr and (plr.DisplayName ~= "" and plr.DisplayName or plr.Name)) or "Player"
	local row = bb:FindFirstChild("Row")
	if not row then
		return
	end
	local t = row:FindFirstChild("Title")
	local s = row:FindFirstChild("Sep")
	local n = row:FindFirstChild("Nick")
	if t and t:IsA("TextLabel") and n and n:IsA("TextLabel") then
		Titles.PaintLine(t, if s and s:IsA("TextLabel") then s else nil, n, store:PeekProfile(), nick)
		t.TextSize = Titles.PlateTextSize
		n.TextSize = Titles.PlateTextSize
		if s and s:IsA("TextLabel") then
			s.TextSize = Titles.PlateTextSize
		end
	end
end

local function attach(char: Model, store: any)
	local head = char:FindFirstChild("Head") :: BasePart?
	if not head then
		head = char:WaitForChild("Head", 8) :: BasePart?
	end
	if not head then
		return
	end

	clearOld(head)

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.NameDisplayDistance = 0
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = TAG
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(420, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0)
	bb.MaxDistance = 100
	-- pin on-screen size so it doesn't grow/shrink with camera (the actual fix)
	bb.DistanceLowerLimit = PIN_DIST
	bb.DistanceUpperLimit = PIN_DIST
	bb.ResetOnSpawn = false
	bb.Parent = head

	local row = Instance.new("Frame")
	row.Name = "Row"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = bb
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = row

	local ts = Titles.PlateTextSize
	makePart("Title", 1, row, ts)
	makePart("Sep", 2, row, ts)
	makePart("Nick", 3, row, ts)

	paint(bb, store)
end

function PlayerNameplate.Mount(store: any): { Refresh: (self: any) -> () }
	local lp = Players.LocalPlayer

	local function onChar(char: Model)
		task.defer(function()
			if char.Parent then
				attach(char, store)
			end
		end)
	end

	lp.CharacterAdded:Connect(onChar)
	if lp.Character then
		onChar(lp.Character)
	end

	local api = {}
	function api.Refresh()
		local char = lp.Character
		local head = char and char:FindFirstChild("Head")
		local bb = head and head:FindFirstChild(TAG)
		if bb and bb:IsA("BillboardGui") then
			bb.DistanceLowerLimit = PIN_DIST
			bb.DistanceUpperLimit = PIN_DIST
			paint(bb, store)
		elseif char then
			attach(char, store)
		end
	end
	return api
end

return PlayerNameplate
