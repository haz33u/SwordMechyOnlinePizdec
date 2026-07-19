--!strict
--[[
	Overhead "Title | Nick" above local player.
	Fixed large pixel billboard + fixed TextSize (no TextScaled blur).
]]

local Players = game:GetService("Players")

local Titles = require(script.Parent.Titles)

local PlayerNameplate = {}

local TAG = "SM_Nameplate"

local function clearOld(parent: Instance)
	local old = parent:FindFirstChild(TAG)
	if old then
		old:Destroy()
	end
end

local function paintLabel(lab: TextLabel, store: any)
	local profile = store:PeekProfile()
	local plr = Players.LocalPlayer
	local nick = (plr and (plr.DisplayName ~= "" and plr.DisplayName or plr.Name)) or "Player"
	lab.Text = Titles.Rich(Titles.Of(profile), nick)
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

	-- Large fixed pixel canvas → stays readable for other players
	local bb = Instance.new("BillboardGui")
	bb.Name = TAG
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(Titles.PlateW, Titles.PlateH)
	bb.StudsOffsetWorldSpace = Vector3.new(0, Titles.PlateStudsY, 0)
	bb.MaxDistance = Titles.PlateMaxDistance
	bb.ResetOnSpawn = false
	bb.ClipsDescendants = false
	bb.Parent = head

	-- Solid soft plate behind text so it doesn't melt into the world
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
	plate.BackgroundTransparency = 0.28
	plate.BorderSizePixel = 0
	plate.Size = UDim2.fromScale(1, 1)
	plate.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = plate
	local stroke = Instance.new("UIStroke")
	stroke.Color = Titles.TitleColor
	stroke.Thickness = 2
	stroke.Transparency = 0.35
	stroke.Parent = plate

	local lab = Instance.new("TextLabel")
	lab.Name = "Line"
	lab.Size = UDim2.new(1, -20, 1, -8)
	lab.Position = UDim2.fromOffset(10, 4)
	lab.Parent = plate
	Titles.StyleLabel(lab, Titles.PlateTextSize)
	lab.TextTruncate = Enum.TextTruncate.AtEnd

	paintLabel(lab, store)
	bb:SetAttribute("SM_Ready", true)
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
		if not char then
			return
		end
		local head = char:FindFirstChild("Head")
		if not head then
			return
		end
		local bb = head:FindFirstChild(TAG)
		if not bb then
			attach(char, store)
			return
		end
		local plate = bb:FindFirstChild("Plate")
		local lab = plate and plate:FindFirstChild("Line") or bb:FindFirstChild("Line")
		if lab and lab:IsA("TextLabel") then
			-- re-pin fixed size every refresh (nothing can force TextScaled back on)
			lab.TextScaled = false
			lab.TextSize = Titles.PlateTextSize
			paintLabel(lab, store)
		end
	end

	return api
end

return PlayerNameplate
