--!strict
--[[
	Overhead "Title | Nick" above local player.
	Hides default Humanoid name so we don't double-stack.
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
		-- hide default Roblox name (we render our own)
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		hum.NameDisplayDistance = 0
	end

	local bb = Instance.new("BillboardGui")
	bb.Name = TAG
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(280, 56)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bb.MaxDistance = 90
	bb.ResetOnSpawn = false
	bb.Parent = head

	local lab = Instance.new("TextLabel")
	lab.Name = "Line"
	lab.BackgroundTransparency = 1
	lab.Size = UDim2.fromScale(1, 1)
	lab.Font = Titles.Font
	lab.TextSize = 20
	lab.TextColor3 = Titles.NickColor
	lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lab.TextStrokeTransparency = 0.35
	lab.TextXAlignment = Enum.TextXAlignment.Center
	lab.TextYAlignment = Enum.TextYAlignment.Center
	lab.RichText = true
	lab.Text = ""
	lab.Parent = bb

	local function paint()
		local profile = store:PeekProfile()
		local plr = Players.LocalPlayer
		local nick = (plr and (plr.DisplayName ~= "" and plr.DisplayName or plr.Name)) or "Player"
		local title = Titles.Of(profile)
		lab.Text = Titles.Rich(title, nick)
	end

	paint()
	bb:SetAttribute("SM_Ready", true)
end

function PlayerNameplate.Mount(store: any): { Refresh: (self: any) -> () }
	local lp = Players.LocalPlayer
	local conns: { RBXScriptConnection } = {}

	local function onChar(char: Model)
		task.defer(function()
			if char.Parent then
				attach(char, store)
			end
		end)
	end

	table.insert(conns, lp.CharacterAdded:Connect(onChar))
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
		local lab = bb:FindFirstChild("Line")
		if lab and lab:IsA("TextLabel") then
			local nick = (lp.DisplayName ~= "" and lp.DisplayName or lp.Name)
			lab.Text = Titles.Rich(Titles.Of(store:PeekProfile()), nick)
		end
	end

	return api
end

return PlayerNameplate
