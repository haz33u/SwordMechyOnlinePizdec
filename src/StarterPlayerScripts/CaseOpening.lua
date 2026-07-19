--!strict
--[[
	Case opening overlay adapted from "Reproduce case opening" design:
	dark dim, horizontal rarity spin strip, center marker, result card.
	Mechanics: pet / aura cases via existing Net remotes + profile resolve.
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Rarity = require(script.Parent.Rarity)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)

local CaseOpening = {}

local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

export type SpinItem = {
	id: string,
	name: string,
	rarity: string,
	icon: string,
	sub: string?,
}

local function petPool(locationId: number): { SpinItem }
	local out: { SpinItem } = {}
	for _, def in PetConfig.Pets do
		if def.location == locationId or locationId == 0 then
			table.insert(out, {
				id = def.id,
				name = def.name,
				rarity = def.rarity,
				icon = "🐾",
				sub = string.format("power x%.2f", PetConfig.GetPowerMult(def)),
			})
		end
	end
	if #out == 0 then
		for _, def in PetConfig.Pets do
			table.insert(out, {
				id = def.id,
				name = def.name,
				rarity = def.rarity,
				icon = "🐾",
				sub = string.format("power x%.2f", PetConfig.GetPowerMult(def)),
			})
		end
	end
	return out
end

local function auraPool(): { SpinItem }
	local out: { SpinItem } = {}
	for _, def in AuraConfig.Auras do
		table.insert(out, {
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			icon = "✨",
			sub = string.format("+%d%% power", math.floor(def.powerPct or 0)),
		})
	end
	return out
end

local function pick(pool: { SpinItem }): SpinItem
	if #pool == 0 then
		return { id = "?", name = "???", rarity = "Common", icon = "?", sub = nil }
	end
	return pool[math.random(1, #pool)]
end

local function uidSet(list: { any }?, key: string): { [string]: boolean }
	local s: { [string]: boolean } = {}
	for _, it in ipairs(list or {}) do
		local u = it[key] or it.uid
		if type(u) == "string" then
			s[u] = true
		end
	end
	return s
end

function CaseOpening.Mount(gui: ScreenGui, store: any)
	local layer = Instance.new("Folder")
	layer.Name = "CaseOpening"
	layer.Parent = gui

	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(8, 8, 10)
	dim.BackgroundTransparency = 0.25
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.ZIndex = 80
	dim.Parent = layer

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Visible = false
	root.ZIndex = 81
	root.Parent = layer

	local title = UIKit.Label({
		Parent = root,
		Text = "Case",
		Size = UDim2.new(0.9, 0, 0, px(36)),
		Position = UDim2.new(0.5, 0, 0, px(28)),
		Anchor = Vector2.new(0.5, 0),
		SizePx = px(24),
		Font = T.Font.Title,
		Color = T.Text,
		X = Enum.TextXAlignment.Center,
		Z = 82,
	})

	local subtitle = UIKit.Label({
		Parent = root,
		Text = "",
		Size = UDim2.new(0.9, 0, 0, px(24)),
		Position = UDim2.new(0.5, 0, 0, px(78)),
		Anchor = Vector2.new(0.5, 0),
		SizePx = px(16),
		Color = T.TextMuted,
		X = Enum.TextXAlignment.Center,
		Z = 82,
	})

	-- Spin track
	local trackH = px(200)
	local track = Instance.new("Frame")
	track.Name = "Track"
	track.BackgroundColor3 = Color3.new(1, 1, 1)
	track.BorderSizePixel = 0
	track.Size = UDim2.new(0.88, 0, 0, trackH)
	track.Position = UDim2.new(0.5, 0, 0.38, 0)
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.ClipsDescendants = true
	track.ZIndex = 82
	track.Parent = root
	UIKit.Corner(track, T.R.sm)
	UIKit.Stroke(track, T.StrokeLight, 1.2, 0.3)
	UIKit.Gradient(track, T.Surface2, T.Bg, 90)

	local strip = Instance.new("Frame")
	strip.Name = "Strip"
	strip.BackgroundTransparency = 1
	strip.Size = UDim2.fromOffset(0, trackH)
	strip.Position = UDim2.fromOffset(0, 0)
	strip.ZIndex = 83
	strip.Parent = track

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, px(14))
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = strip

	-- Center marker
	local marker = Instance.new("Frame")
	marker.Name = "Marker"
	marker.BackgroundColor3 = T.Accent
	marker.BorderSizePixel = 0
	marker.Size = UDim2.new(0, 3, 1, 0)
	marker.Position = UDim2.new(0.5, -1, 0, 0)
	marker.ZIndex = 90
	marker.Parent = track

	local arrow = Instance.new("Frame")
	arrow.Name = "Arrow"
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(0, 0)
	arrow.Position = UDim2.new(0.5, 0, 0, -2)
	arrow.AnchorPoint = Vector2.new(0.5, 1)
	arrow.ZIndex = 91
	arrow.Parent = track
	local arrowLab = UIKit.Label({
		Parent = arrow,
		Text = "▼",
		Size = UDim2.fromOffset(px(28), px(22)),
		Position = UDim2.fromOffset(-px(14), -px(22)),
		SizePx = px(18),
		Color = T.Accent,
		X = Enum.TextXAlignment.Center,
		Z = 91,
	})
	arrowLab.TextStrokeTransparency = 0.3

	-- Result card (flat panel)
	local result = UIKit.Glass({
		Name = "Result",
		Parent = root,
		Size = UDim2.fromOffset(px(400), px(260)),
		Position = UDim2.new(0.5, 0, 0.78, 0),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.md,
		Z = 85,
		Deep = true,
	})
	result.Visible = false
	UIKit.Stroke(result, T.StrokeLight, 1.2, 0.25)
	UIKit.Pad(result, px(16))

	local resultTitle = UIKit.Label({
		Parent = result,
		Text = "You got!",
		Size = UDim2.new(1, 0, 0, px(26)),
		SizePx = px(18),
		Font = T.Font.Title,
		Color = T.Text,
		X = Enum.TextXAlignment.Center,
		Z = 86,
	})
	local resultIcon = UIKit.Label({
		Parent = result,
		Text = "🐾",
		Size = UDim2.new(1, 0, 0, px(72)),
		Position = UDim2.fromOffset(0, px(40)),
		SizePx = px(52),
		X = Enum.TextXAlignment.Center,
		Z = 86,
	})
	local resultName = UIKit.Label({
		Parent = result,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(28)),
		Position = UDim2.fromOffset(0, px(118)),
		SizePx = px(20),
		Font = T.Font.Title,
		Color = T.Text,
		X = Enum.TextXAlignment.Center,
		Z = 86,
	})
	local resultRarity = UIKit.Label({
		Parent = result,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(24)),
		Position = UDim2.fromOffset(0, px(152)),
		SizePx = px(15),
		Color = T.TextMuted,
		X = Enum.TextXAlignment.Center,
		Z = 86,
	})
	local resultSub = UIKit.Label({
		Parent = result,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(22)),
		Position = UDim2.fromOffset(0, px(180)),
		SizePx = px(14),
		Color = T.TextSoft,
		X = Enum.TextXAlignment.Center,
		Z = 86,
	})

	local closeBtn = UIKit.Button({
		Name = "Close",
		Parent = root,
		Text = "✕",
		Size = UDim2.fromOffset(px(44), px(44)),
		Position = UDim2.new(1, -px(28), 0, px(28)),
		Anchor = Vector2.new(1, 0),
		Color = T.Danger,
		Color2 = T.Colors and T.Colors.DangerDeep or Color3.fromRGB(160, 40, 50),
		SizePx = px(18),
		Compact = true,
		Radius = T.R.sm,
		Z = 95,
	})

	local okBtn = UIKit.Button({
		Parent = result,
		Text = "Claim",
		Size = UDim2.new(0.75, 0, 0, px(40)),
		Position = UDim2.new(0.5, 0, 1, -px(8)),
		Anchor = Vector2.new(0.5, 1),
		Primary = true,
		SizePx = px(15),
		Z = 87,
	})

	local busy = false
	local gen = 0

	local function hideAll()
		dim.Visible = false
		root.Visible = false
		result.Visible = false
		busy = false
	end

	closeBtn.MouseButton1Click:Connect(function()
		if busy then
			-- allow cancel only after result or force
		end
		hideAll()
	end)
	okBtn.MouseButton1Click:Connect(hideAll)
	dim.MouseButton1Click:Connect(function()
		if not busy then
			hideAll()
		end
	end)

	local cellW = px(150)
	local cellH = px(170)
	local gap = px(14)

	local function clearStrip()
		for _, c in strip:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
	end

	local function makeCell(item: SpinItem, order: number): Frame
		local col = Rarity.Of(item.rarity)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.Size = UDim2.fromOffset(cellW, cellH)
		f.LayoutOrder = order
		f.ZIndex = 84
		f.ClipsDescendants = true
		f.Parent = strip
		UIKit.Corner(f, T.R.md)
		UIKit.Stroke(f, col, 2, 0.25)
		UIKit.Gradient(f, T.Surface2, T.Surface, 120)
		UIKit.Pad(f, px(8))

		UIKit.Label({
			Parent = f,
			Text = item.icon,
			Size = UDim2.new(1, 0, 0, px(56)),
			SizePx = px(40),
			X = Enum.TextXAlignment.Center,
			Z = 85,
		})
		UIKit.Label({
			Parent = f,
			Text = item.name,
			Size = UDim2.new(1, 0, 0, px(36)),
			Position = UDim2.fromOffset(0, px(58)),
			SizePx = px(13),
			Font = T.Font.Title,
			Color = T.Text,
			X = Enum.TextXAlignment.Center,
			Y = Enum.TextYAlignment.Top,
			Wrap = true,
			Z = 85,
		})
		local badge = Instance.new("Frame")
		badge.BackgroundColor3 = col
		badge.BorderSizePixel = 0
		badge.Size = UDim2.new(1, 0, 0, px(22))
		badge.Position = UDim2.new(0, 0, 1, -px(22))
		badge.ZIndex = 85
		badge.Parent = f
		UIKit.Corner(badge, T.R.sm)
		UIKit.Label({
			Parent = badge,
			Text = string.upper(item.rarity),
			Size = UDim2.fromScale(1, 1),
			SizePx = px(11),
			Font = T.Font.Title,
			Color = Color3.new(1, 1, 1),
			X = Enum.TextXAlignment.Center,
			Z = 86,
		})
		return f
	end

	local api = {}

	function api.IsOpen(): boolean
		return root.Visible
	end

	function api.Close()
		gen += 1
		hideAll()
	end

	function api.Begin(payload: any?)
		if busy then
			return false, "busy", 0
		end
		local kind = (payload and payload.kind) or "pet"
		if kind ~= "pet" and kind ~= "aura" then
			kind = "pet"
		end

		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local keys = if kind == "aura"
			then ((stats and stats.auraKeys) or (profile and profile.auraKeys) or 0)
			else ((stats and stats.petKeys) or (profile and profile.petKeys) or 0)
		local keyCost = if kind == "aura" then (CaseConfig.AURA_KEY_COST or 1) else (CaseConfig.PET_KEY_COST or 0)
		local coinCost = if kind == "aura"
			then (CaseConfig.AURA_COIN_COST or 0)
			else (CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0)
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0

		if keyCost > 0 and keys < keyCost then
			return false, "need_keys", keyCost
		end
		if coinCost > 0 and coins < coinCost then
			return false, "need_coins", coinCost
		end

		local loc = (profile and profile.currentLocation) or 1
		local pool = if kind == "aura" then auraPool() else petPool(loc)
		local caseName = if kind == "aura" then "Aura Case" else "Pet Case"
		local before = if kind == "aura"
			then uidSet(profile and profile.auras, "uid")
			else uidSet(profile and profile.pets, "uid")

		busy = true
		gen += 1
		local myGen = gen
		dim.Visible = true
		root.Visible = true
		result.Visible = false
		title.Text = caseName
		subtitle.Text = "Opening…"

		clearStrip()
		local COUNT = 48
		local WIN = 36
		local items: { SpinItem } = {}
		for i = 1, COUNT do
			items[i] = pick(pool)
			makeCell(items[i], i)
		end
		local totalW = COUNT * cellW + (COUNT - 1) * gap
		strip.Size = UDim2.fromOffset(totalW, trackH)
		strip.Position = UDim2.fromOffset(0, 0)

		-- Listen BEFORE FireServer so CaseResult cannot race past us.
		task.spawn(function()
			-- arm waiter first frame, then open
			local pending = { done = false, item = nil :: SpinItem?, err = nil :: string? }
			local conn = Net.Event("CaseResult").OnClientEvent:Connect(function(payload)
				if type(payload) ~= "table" or payload.kind ~= kind then
					return
				end
				pending.done = true
				if payload.success == false then
					pending.err = payload.reason or "failed"
					return
				end
				local icon = if kind == "aura" then "✨" else "🐾"
				local sub: string? = nil
				if kind == "pet" then
					local mult = 1 + (payload.powerPct or 0) / 100
					sub = string.format(
						"power x%.2f · +%d%% coins",
						mult,
						math.floor(payload.coinPct or 0)
					)
				else
					sub = string.format("+%d%% power", math.floor(payload.powerPct or 0))
				end
				pending.item = {
					id = payload.id or "?",
					name = payload.name or "???",
					rarity = payload.rarity or "Common",
					icon = icon,
					sub = sub,
				}
			end)

			if kind == "aura" then
				Net.OpenAuraCase()
			else
				Net.OpenPetCase()
			end

			local t0 = os.clock()
			local won: SpinItem? = nil
			local failReason: string? = nil
			while os.clock() - t0 < 4.0 do
				if pending.done then
					won = pending.item
					failReason = pending.err
					break
				end
				-- profile fallback
				local p = store:PeekProfile()
				if p then
					if kind == "pet" then
						for _, pet in ipairs(p.pets or {}) do
							local uid = pet.uid
							if type(uid) == "string" and not before[uid] then
								local def = PetConfig.Get(pet.id)
								won = {
									id = pet.id or uid,
									name = (def and def.name) or tostring(pet.id),
									rarity = (def and def.rarity) or "Common",
									icon = "🐾",
									sub = def and string.format(
										"power x%.2f · +%d%% coins",
										PetConfig.GetPowerMult(def),
										math.floor(def.coinPct or 0)
									) or nil,
								}
								break
							end
						end
					else
						for _, a in ipairs(p.auras or {}) do
							local uid = a.uid
							if type(uid) == "string" and not before[uid] then
								local def = AuraConfig.Get(a.id)
								won = {
									id = a.id or uid,
									name = (def and def.name) or tostring(a.id),
									rarity = (def and def.rarity) or "Common",
									icon = "✨",
									sub = def and string.format("+%d%% power", math.floor(def.powerPct)) or nil,
								}
								break
							end
						end
					end
					if won then
						break
					end
				end
				task.wait(0.05)
			end
			conn:Disconnect()

			if myGen ~= gen then
				return
			end
			if not won then
				busy = false
				hideAll()
				return
			end
			if failReason then
				busy = false
				hideAll()
				return
			end
			subtitle.Text = "Drop received!"

			-- rebuild last stretch with known win at WIN
			clearStrip()
			items = {}
			for i = 1, COUNT do
				if i == WIN then
					items[i] = won
				else
					items[i] = pick(pool)
				end
				makeCell(items[i], i)
			end
			strip.Size = UDim2.fromOffset(totalW, trackH)

			local trackW = track.AbsoluteSize.X
			if trackW < 10 then
				trackW = 800
			end
			local cellCenter = (WIN - 1) * (cellW + gap) + cellW * 0.5
			local targetX = -(cellCenter - trackW * 0.5)
			targetX += math.random(-px(12), px(12))

			strip.Position = UDim2.fromOffset(math.floor(trackW * 0.2), 0)
			local tw = TweenService:Create(
				strip,
				TweenInfo.new(4.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Position = UDim2.fromOffset(math.floor(targetX), 0) }
			)
			tw:Play()
			tw.Completed:Wait()
			if myGen ~= gen then
				return
			end

			result.Visible = true
			resultIcon.Text = won.icon
			resultName.Text = won.name
			resultRarity.Text = string.upper(won.rarity)
			resultRarity.TextColor3 = Rarity.Of(won.rarity)
			resultSub.Text = won.sub or ""
			UIKit.Stroke(result, Rarity.Of(won.rarity), 2.2, 0.25)

			busy = false
		end)

		return true
	end

	function api.CostLabel(kind: string): string
		local keyCost = if kind == "aura" then (CaseConfig.AURA_KEY_COST or 1) else (CaseConfig.PET_KEY_COST or 0)
		local coinCost = if kind == "aura"
			then (CaseConfig.AURA_COIN_COST or 0)
			else (CaseConfig.PET_COIN_COST or PetConfig.OPEN_COST or 0)
		local parts = {}
		if keyCost > 0 then
			table.insert(parts, string.format("%d %s", keyCost, if kind == "aura" then "aura key" else "pet key"))
		end
		if coinCost > 0 then
			table.insert(parts, Format.Num(coinCost) .. " coins")
		end
		if #parts == 0 then
			return "Free"
		end
		return table.concat(parts, " + ")
	end

	return api
end

return CaseOpening
