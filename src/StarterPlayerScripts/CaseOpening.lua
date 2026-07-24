--!strict
--[[
	Case opening: spin strip(s) + centered result card (no dark fullscreen dim).
	Supports 1x, 3x, and 5x multi-case opening with multiple simultaneous reels
	and multi-item result display.
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

local function petPool(casePoolId: string?, locationId: number): { SpinItem }
	local out: { SpinItem } = {}
	local poolId = casePoolId
	if type(poolId) ~= "string" or not PetConfig.IsValidPool(poolId) then
		poolId = PetConfig.GetDefaultPoolId(locationId)
	end
	for _, def in PetConfig.GetPool(poolId) do
		table.insert(out, {
			id = def.id,
			name = def.name,
			rarity = def.rarity,
			icon = "🐾",
			sub = string.format("power x%.2f", PetConfig.GetPowerMult(def)),
		})
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

function CaseOpening.Mount(gui: ScreenGui, store: any, toastApi: any?)
	local layer = Instance.new("Folder")
	layer.Name = "CaseOpening"
	layer.Parent = gui

	-- Fully transparent hit catcher
	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundTransparency = 1
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
		Size = UDim2.new(0.9, 0, 0, px(32)),
		Position = UDim2.new(0.5, 0, 0, px(16)),
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
		Size = UDim2.new(0.9, 0, 0, px(20)),
		Position = UDim2.new(0.5, 0, 0, px(52)),
		Anchor = Vector2.new(0.5, 0),
		SizePx = px(15),
		Color = T.TextMuted,
		X = Enum.TextXAlignment.Center,
		Z = 82,
	})

	-- Container for 1, 3, or 5 spin tracks
	local tracksHost = Instance.new("Frame")
	tracksHost.Name = "TracksHost"
	tracksHost.BackgroundTransparency = 1
	tracksHost.Position = UDim2.new(0.5, 0, 0.44, 0)
	tracksHost.AnchorPoint = Vector2.new(0.5, 0.5)
	tracksHost.ZIndex = 82
	tracksHost.Parent = root

	local tracksLayout = Instance.new("UIListLayout")
	tracksLayout.FillDirection = Enum.FillDirection.Vertical
	tracksLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tracksLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tracksLayout.Padding = UDim.new(0, px(8))
	tracksLayout.Parent = tracksHost

	-- Result card overlay
	local result = UIKit.Glass({
		Name = "Result",
		Parent = root,
		Size = UDim2.fromScale(0.40, 0.35),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.md,
		Z = 250,
		Deep = true,
	})
	result.Visible = false
	local rsc = Instance.new("UISizeConstraint")
	rsc.MinSize = Vector2.new(300, 200)
	rsc.MaxSize = Vector2.new(900, 420)
	rsc.Parent = result
	UIKit.Stroke(result, T.StrokeLight, 1.5, 0.2)
	UIKit.Pad(result, px(14))
	result.ZIndex = 250

	local resultTitle = UIKit.Label({
		Parent = result,
		Text = "You got!",
		Size = UDim2.new(1, 0, 0, px(26)),
		SizePx = px(18),
		Font = T.Font.Title,
		Color = T.Text,
		X = Enum.TextXAlignment.Center,
		Z = 251,
	})

	local resultGridHost = Instance.new("Frame")
	resultGridHost.Name = "ResultGridHost"
	resultGridHost.BackgroundTransparency = 1
	resultGridHost.Size = UDim2.new(1, 0, 1, -px(65))
	resultGridHost.Position = UDim2.fromOffset(0, px(30))
	resultGridHost.ZIndex = 251
	resultGridHost.Parent = result

	local gridLayout = Instance.new("UIListLayout")
	gridLayout.FillDirection = Enum.FillDirection.Horizontal
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	gridLayout.Padding = UDim.new(0, px(10))
	gridLayout.Parent = resultGridHost

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
		Z = 260,
	})

	local okBtn = UIKit.Button({
		Parent = result,
		Text = "Claim",
		Size = UDim2.new(0.40, 0, 0, px(38)),
		Position = UDim2.new(0.5, 0, 1, -px(4)),
		Anchor = Vector2.new(0.5, 1),
		Primary = true,
		SizePx = px(15),
		Z = 255,
	})

	local busy = false
	local gen = 0

	local function hideAll()
		dim.Visible = false
		root.Visible = false
		result.Visible = false
		busy = false
	end

	closeBtn.MouseButton1Click:Connect(hideAll)
	okBtn.MouseButton1Click:Connect(hideAll)
	dim.MouseButton1Click:Connect(function()
		if not busy then
			hideAll()
		end
	end)

	local api = {}

	function api.IsOpen(): boolean
		return root.Visible
	end

	function api.Close()
		gen += 1
		hideAll()
	end

	local function makeCell(strip: Frame, item: SpinItem, order: number, cellW: number, cellH: number): Frame
		local col = Rarity.Of(item.rarity)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(1, 1, 1)
		f.BorderSizePixel = 0
		f.Size = UDim2.fromOffset(cellW, cellH)
		f.LayoutOrder = order
		f.ZIndex = 84
		f.ClipsDescendants = true
		f.Parent = strip
		UIKit.Corner(f, T.R.sm)
		UIKit.Stroke(f, col, 1.8, 0.25)
		UIKit.Gradient(f, T.Surface2, T.Surface, 120)

		local iconSize = math.floor(cellH * 0.38)
		UIKit.Label({
			Parent = f,
			Text = item.icon,
			Size = UDim2.new(1, 0, 0, iconSize),
			SizePx = math.floor(iconSize * 0.75),
			X = Enum.TextXAlignment.Center,
			Z = 85,
		})
		UIKit.Label({
			Parent = f,
			Text = item.name,
			Size = UDim2.new(1, -4, 0, math.floor(cellH * 0.30)),
			Position = UDim2.fromOffset(2, iconSize),
			SizePx = math.clamp(math.floor(cellH * 0.14), 10, 14),
			Font = T.Font.Title,
			Color = T.Text,
			X = Enum.TextXAlignment.Center,
			Y = Enum.TextYAlignment.Top,
			Wrap = true,
			Z = 85,
		})
		local badgeH = math.floor(cellH * 0.22)
		local badge = Instance.new("Frame")
		badge.BackgroundColor3 = col
		badge.BorderSizePixel = 0
		badge.Size = UDim2.new(1, 0, 0, badgeH)
		badge.Position = UDim2.new(0, 0, 1, -badgeH)
		badge.ZIndex = 85
		badge.Parent = f
		UIKit.Corner(badge, T.R.sm)
		UIKit.Label({
			Parent = badge,
			Text = string.upper(item.rarity),
			Size = UDim2.fromScale(1, 1),
			SizePx = math.clamp(math.floor(badgeH * 0.65), 9, 12),
			Font = T.Font.Title,
			Color = Color3.new(1, 1, 1),
			X = Enum.TextXAlignment.Center,
			Z = 86,
		})
		return f
	end

	function api.Begin(payload: any?)
		if busy then
			return false, "busy", 0
		end
		local kind = (payload and payload.kind) or "pet"
		if kind ~= "pet" and kind ~= "aura" then
			kind = "pet"
		end
		local openCount = math.clamp(math.floor(tonumber(payload and payload.count) or 1), 1, 5)
		if openCount ~= 1 and openCount ~= 3 and openCount ~= 5 then
			openCount = 1
		end
		local petPoolId: string? = if payload and type(payload.poolId) == "string" then payload.poolId else nil

		local profile = store:PeekProfile()
		local stats = store:PeekStats()
		local loc = (profile and profile.currentLocation) or 1
		local keys = if kind == "aura"
			then ((stats and stats.auraKeys) or (profile and profile.auraKeys) or 0)
			else ((stats and stats.petKeys) or (profile and profile.petKeys) or 0)
		local singleKeyCost = 0
		local singleCoinCost = 0
		if kind == "aura" then
			singleKeyCost = CaseConfig.AURA_KEY_COST or 1
			singleCoinCost = CaseConfig.AURA_COIN_COST or 0
		else
			local pid = petPoolId or PetConfig.GetDefaultPoolId(loc)
			singleCoinCost, singleKeyCost = PetConfig.GetCaseCosts(pid)
			petPoolId = pid
		end

		local keyCost = singleKeyCost * openCount
		local coinCost = singleCoinCost * openCount
		local coins = (stats and stats.coins) or (profile and profile.coins) or 0

		if keyCost > 0 and keys < keyCost then
			return false, "need_keys", keyCost
		end
		if coinCost > 0 and coins < coinCost then
			return false, "need_coins", coinCost
		end

		local pool = if kind == "aura" then auraPool() else petPool(petPoolId, loc)
		local caseName = if kind == "aura"
			then string.format("Aura Case (x%d)", openCount)
			else string.format("Pet Case x%d (%s)", openCount, tostring(petPoolId or "loc1_500"))
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

		-- Clean previous tracks
		for _, c in tracksHost:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		for _, c in resultGridHost:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end

		-- Track dimensions based on openCount
		local trackH = px(180)
		local cellW = px(140)
		local cellH = px(160)
		local hostH = px(200)
		local gap = px(12)

		if openCount == 3 then
			trackH = px(105)
			cellW = px(90)
			cellH = px(92)
			hostH = px(340)
			gap = px(8)
		elseif openCount == 5 then
			trackH = px(74)
			cellW = px(64)
			cellH = px(64)
			hostH = px(410)
			gap = px(6)
		end

		tracksHost.Size = UDim2.new(if openCount >= 5 then 0.94 else 0.88, 0, 0, hostH)

		-- Create tracks & strips
		type TrackData = {
			track: Frame,
			strip: Frame,
		}
		local tracks: { TrackData } = {}
		local COUNT = 48
		local WIN = 36

		for tIdx = 1, openCount do
			local track = Instance.new("Frame")
			track.Name = "Track_" .. tIdx
			track.BackgroundColor3 = Color3.new(1, 1, 1)
			track.BorderSizePixel = 0
			track.Size = UDim2.new(1, 0, 0, trackH)
			track.ClipsDescendants = true
			track.ZIndex = 82
			track.Parent = tracksHost
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
			list.Padding = UDim.new(0, gap)
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.Parent = strip

			-- Center marker line & arrow
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
				Size = UDim2.fromOffset(px(24), px(18)),
				Position = UDim2.fromOffset(-px(12), -px(18)),
				SizePx = px(14),
				Color = T.Accent,
				X = Enum.TextXAlignment.Center,
				Z = 91,
			})
			arrowLab.TextStrokeTransparency = 0.3

			-- Fill track with dummy cells initially
			for i = 1, COUNT do
				makeCell(strip, pick(pool), i, cellW, cellH)
			end
			local totalW = COUNT * cellW + (COUNT - 1) * gap
			strip.Size = UDim2.fromOffset(totalW, trackH)
			strip.Position = UDim2.fromOffset(0, 0)

			table.insert(tracks, { track = track, strip = strip })
		end

		-- Listen for CaseResult from server
		task.spawn(function()
			local pending = { done = false, items = nil :: { SpinItem }?, err = nil :: string? }
			local conn = Net.Event("CaseResult").OnClientEvent:Connect(function(payload)
				if type(payload) ~= "table" or payload.kind ~= kind then
					return
				end
				pending.done = true
				if payload.success == false then
					pending.err = payload.reason or "failed"
					return
				end

				local itemsList: { SpinItem } = {}
				if type(payload.items) == "table" and #payload.items > 0 then
					for _, it in ipairs(payload.items) do
						local icon = if kind == "aura" then "✨" else "🐾"
						local sub: string? = nil
						if kind == "pet" then
							local mult = it.powerMult or (1 + (it.powerPct or 0) / 100)
							sub = string.format("power x%.2f", mult)
						else
							sub = string.format("+%d%% power", math.floor(it.powerPct or 0))
						end
						table.insert(itemsList, {
							id = it.id or "?",
							name = it.name or "???",
							rarity = it.rarity or "Common",
							icon = icon,
							sub = sub,
						})
					end
				else
					local icon = if kind == "aura" then "✨" else "🐾"
					local sub: string? = nil
					if kind == "pet" then
						local mult = 1 + (payload.powerPct or 0) / 100
						sub = string.format("power x%.2f", mult)
					else
						sub = string.format("+%d%% power", math.floor(payload.powerPct or 0))
					end
					table.insert(itemsList, {
						id = payload.id or "?",
						name = payload.name or "???",
						rarity = payload.rarity or "Common",
						icon = icon,
						sub = sub,
					})
				end

				pending.items = itemsList
			end)

			if kind == "aura" then
				Net.OpenAuraCase(openCount)
			else
				Net.OpenPetCase(petPoolId, openCount)
			end

			local t0 = os.clock()
			local wonList: { SpinItem } = {}
			local failReason: string? = nil

			while os.clock() - t0 < 4.0 do
				if pending.done then
					wonList = pending.items or {}
					failReason = pending.err
					break
				end
				-- Profile fallback
				local p = store:PeekProfile()
				if p then
					local newlyAdded = {}
					if kind == "pet" then
						for _, pet in ipairs(p.pets or {}) do
							local uid = pet.uid
							if type(uid) == "string" and not before[uid] then
								local def = PetConfig.Get(pet.id)
								table.insert(newlyAdded, {
									id = pet.id or uid,
									name = (def and def.name) or tostring(pet.id),
									rarity = (def and def.rarity) or "Common",
									icon = "🐾",
									sub = def and string.format("power x%.2f", PetConfig.GetPowerMult(def)) or nil,
								})
							end
						end
					else
						for _, a in ipairs(p.auras or {}) do
							local uid = a.uid
							if type(uid) == "string" and not before[uid] then
								local def = AuraConfig.Get(a.id)
								table.insert(newlyAdded, {
									id = a.id or uid,
									name = (def and def.name) or tostring(a.id),
									rarity = (def and def.rarity) or "Common",
									icon = "✨",
									sub = def and string.format("+%d%% power", math.floor(def.powerPct)) or nil,
								})
							end
						end
					end
					if #newlyAdded >= openCount then
						wonList = newlyAdded
						break
					end
				end
				task.wait(0.05)
			end
			conn:Disconnect()

			if myGen ~= gen or #wonList == 0 or failReason then
				busy = false
				hideAll()
				return
			end

			subtitle.Text = "Drop received!"

			-- Rebuild strips with target won item at WIN=36 for each track
			local tweens: { Tween } = {}
			for tIdx = 1, openCount do
				local tData = tracks[tIdx]
				if not tData then continue end
				local strip = tData.strip
				local track = tData.track

				-- Clear dummy items
				for _, c in strip:GetChildren() do
					if not c:IsA("UIListLayout") then
						c:Destroy()
					end
				end

				local wonItem = wonList[tIdx] or wonList[1] or pick(pool)
				for i = 1, COUNT do
					local item = if i == WIN then wonItem else pick(pool)
					makeCell(strip, item, i, cellW, cellH)
				end

				local totalW = COUNT * cellW + (COUNT - 1) * gap
				strip.Size = UDim2.fromOffset(totalW, trackH)

				local trackW = track.AbsoluteSize.X
				if trackW < 10 then trackW = 800 end
				local cellCenter = (WIN - 1) * (cellW + gap) + cellW * 0.5
				local targetX = -(cellCenter - trackW * 0.5) + math.random(-px(8), px(8))

				strip.Position = UDim2.fromOffset(math.floor(trackW * 0.25), 0)

				local spinDuration = 2.4 + (tIdx - 1) * 0.25
				local tw = TweenService:Create(
					strip,
					TweenInfo.new(spinDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Position = UDim2.fromOffset(math.floor(targetX), 0) }
				)
				table.insert(tweens, tw)
				tw:Play()
			end

			-- Wait for all reels to complete spinning
			if #tweens > 0 then
				tweens[#tweens].Completed:Wait()
			end

			if myGen ~= gen then
				return
			end

			-- Populate Result card overlay
			result.Visible = true
			result.ZIndex = 250

			if openCount == 1 then
				result.Size = UDim2.fromScale(0.38, 0.34)
				local won = wonList[1]
				local card = Instance.new("Frame")
				card.BackgroundTransparency = 1
				card.Size = UDim2.fromScale(1, 1)
				card.ZIndex = 252
				card.Parent = resultGridHost

				local rIcon = UIKit.Label({
					Parent = card,
					Text = won.icon,
					Size = UDim2.new(1, 0, 0, px(60)),
					Position = UDim2.fromOffset(0, px(10)),
					SizePx = px(44),
					X = Enum.TextXAlignment.Center,
					Z = 253,
				})
				local rName = UIKit.Label({
					Parent = card,
					Text = won.name,
					Size = UDim2.new(1, 0, 0, px(26)),
					Position = UDim2.fromOffset(0, px(74)),
					SizePx = px(18),
					Font = T.Font.Title,
					Color = T.Text,
					X = Enum.TextXAlignment.Center,
					Z = 253,
				})
				local rRarity = UIKit.Label({
					Parent = card,
					Text = string.upper(won.rarity),
					Size = UDim2.new(1, 0, 0, px(22)),
					Position = UDim2.fromOffset(0, px(102)),
					SizePx = px(14),
					Color = Rarity.Of(won.rarity),
					X = Enum.TextXAlignment.Center,
					Z = 253,
				})
				local rSub = UIKit.Label({
					Parent = card,
					Text = won.sub or "",
					Size = UDim2.new(1, 0, 0, px(20)),
					Position = UDim2.fromOffset(0, px(126)),
					SizePx = px(13),
					Color = T.TextSoft,
					X = Enum.TextXAlignment.Center,
					Z = 253,
				})
				UIKit.Stroke(result, Rarity.Of(won.rarity), 2.2, 0.15)
			else
				-- Multi-item grid display (3x or 5x)
				result.Size = UDim2.fromScale(if openCount == 3 then 0.65 else 0.85, 0.38)
				resultTitle.Text = string.format("You got %d items!", #wonList)
				UIKit.Stroke(result, T.StrokeLight, 1.8, 0.2)

				local itemCardW = math.floor((600 / openCount))
				for _, won in ipairs(wonList) do
					local col = Rarity.Of(won.rarity)
					local cFrame = Instance.new("Frame")
					cFrame.BackgroundColor3 = Color3.new(1, 1, 1)
					cFrame.BorderSizePixel = 0
					cFrame.Size = UDim2.fromOffset(px(itemCardW), px(140))
					cFrame.ZIndex = 252
					cFrame.Parent = resultGridHost
					UIKit.Corner(cFrame, T.R.sm)
					UIKit.Stroke(cFrame, col, 1.8, 0.2)
					UIKit.Gradient(cFrame, T.Surface2, T.Surface, 100)
					UIKit.Pad(cFrame, px(6))

					UIKit.Label({
						Parent = cFrame,
						Text = won.icon,
						Size = UDim2.new(1, 0, 0, px(42)),
						SizePx = px(30),
						X = Enum.TextXAlignment.Center,
						Z = 253,
					})
					UIKit.Label({
						Parent = cFrame,
						Text = won.name,
						Size = UDim2.new(1, 0, 0, px(24)),
						Position = UDim2.fromOffset(0, px(44)),
						SizePx = px(13),
						Font = T.Font.Title,
						Color = T.Text,
						X = Enum.TextXAlignment.Center,
						Wrap = true,
						Z = 253,
					})
					local badge = Instance.new("Frame")
					badge.BackgroundColor3 = col
					badge.BorderSizePixel = 0
					badge.Size = UDim2.new(1, 0, 0, px(18))
					badge.Position = UDim2.fromOffset(0, px(72))
					badge.ZIndex = 253
					badge.Parent = cFrame
					UIKit.Corner(badge, T.R.sm)
					UIKit.Label({
						Parent = badge,
						Text = string.upper(won.rarity),
						Size = UDim2.fromScale(1, 1),
						SizePx = px(10),
						Font = T.Font.Title,
						Color = Color3.new(1, 1, 1),
						X = Enum.TextXAlignment.Center,
						Z = 254,
					})
					UIKit.Label({
						Parent = cFrame,
						Text = won.sub or "",
						Size = UDim2.new(1, 0, 0, px(18)),
						Position = UDim2.fromOffset(0, px(94)),
						SizePx = px(11),
						Color = T.TextSoft,
						X = Enum.TextXAlignment.Center,
						Z = 253,
					})
				end
			end

			-- Pop scale effect
			local rScale = result:FindFirstChildOfClass("UIScale")
			if not rScale then
				rScale = Instance.new("UIScale")
				rScale.Parent = result
			end
			rScale.Scale = 0.85
			TweenService:Create(rScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Scale = 1,
			}):Play()

			if toastApi and type(toastApi.Show) == "function" then
				toastApi.Show(
					string.format("Opened %d case(s) successfully!", #wonList),
					"gold"
				)
			end

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
