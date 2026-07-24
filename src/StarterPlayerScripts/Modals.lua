local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetConfig = require(Shared.Config.PetConfig)
local AuraConfig = require(Shared.Config.AuraConfig)
local CaseConfig = require(Shared.Config.CaseConfig)
local ProgressConfig = require(Shared.Config.ProgressConfig)
local GamePassConfig = require(Shared.Config.GamePassConfig)
local Rarity = require(script.Parent.Rarity)

local Modals = {}

-- Same interior scale as left-rail windows (HUD bottom/balance untouched)
local S = 1.42
local function px(n: number): number
	return math.floor(n * S + 0.5)
end

function Modals.Mount(gui: ScreenGui, store: any)
	local layer = Instance.new("Folder")
	layer.Name = "Modals"
	layer.Parent = gui

	local dim = Instance.new("TextButton")
	dim.Name = "Dim"
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.5
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.ZIndex = 50
	dim.Parent = layer
	dim.MouseButton1Click:Connect(function()
		store:CloseModal()
	end)

	local card = UIKit.Glass({
		Name = "ModalCard",
		Parent = layer,
		Size = UDim2.fromOffset(px(460), px(340)),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.md,
		Z = 51,
		Deep = true,
	})
	card.Visible = false
	UIKit.Stroke(card, T.StrokeLight, 1.2, 0.3)
	UIKit.Pad(card, px(18))

	local title = UIKit.Label({
		Parent = card,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(30)),
		SizePx = px(20),
		Font = T.Font.Title,
		X = Enum.TextXAlignment.Center,
		Z = 52,
	})
	local body = UIKit.Label({
		Parent = card,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(120)),
		Position = UDim2.fromOffset(0, px(36)),
		SizePx = px(14),
		Color = T.TextSoft,
		X = Enum.TextXAlignment.Center,
		Y = Enum.TextYAlignment.Top,
		Wrap = true,
		Z = 52,
	})

	local barHost = Instance.new("Frame")
	barHost.BackgroundTransparency = 1
	barHost.Size = UDim2.new(1, 0, 0, px(14))
	barHost.Position = UDim2.fromOffset(0, px(168))
	barHost.ZIndex = 52
	barHost.Visible = false
	barHost.Parent = card
	local _, fill = UIKit.Bar(barHost, 0, T.Accent, px(12))

	local etaLabel = UIKit.Label({
		Parent = card,
		Text = "",
		Size = UDim2.new(1, 0, 0, px(22)),
		Position = UDim2.fromOffset(0, px(188)),
		SizePx = px(14),
		Font = T.Font.Title,
		Color = Color3.fromRGB(100, 230, 140),
		X = Enum.TextXAlignment.Center,
		Z = 52,
	})
	etaLabel.Visible = false

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, px(46))
	row.Position = UDim2.new(0, 0, 1, -px(56))
	row.ZIndex = 52
	row.Parent = card
	UIKit.List(row, px(12), true, Enum.HorizontalAlignment.Center)

	local primary = UIKit.Button({
		Parent = row,
		Text = "OK",
		Size = UDim2.new(0.48, 0, 1, 0),
		Color = T.Success,
		Color2 = T.Colors and T.Colors.SuccessDeep or Color3.fromRGB(28, 140, 80),
		Primary = true,
		SizePx = px(17),
		Z = 53,
	})
	local cancel = UIKit.Button({
		Parent = row,
		Text = "Cancel",
		Size = UDim2.new(0.48, 0, 1, 0),
		Color = T.Surface3,
		Color2 = T.Surface2,
		SizePx = px(17),
		Z = 53,
	})
	cancel.MouseButton1Click:Connect(function()
		store:CloseModal()
	end)

	local primaryConn: RBXScriptConnection? = nil

	local api = {}
	function api.Refresh()
		local m = store:PeekModal()
		if not m then
			dim.Visible = false
			card.Visible = false
			return
		end
		dim.Visible = true
		card.Visible = true
		barHost.Visible = false
		etaLabel.Visible = false
		if primaryConn then
			primaryConn:Disconnect()
			primaryConn = nil
		end

		if m.kind == "rebirth" then
			local stats = store:PeekStats() or {}
			local powerProg = stats.totalPower or stats.lifetimeDamage or 0
			local costPower = stats.nextRebirthCost or 1
			local pct = stats.rebirthProgress
			if type(pct) ~= "number" then
				pct = costPower > 0 and math.clamp(powerProg / costPower, 0, 1) or 1
			end
			local fromName = stats.rebirthRankName or ("R" .. tostring(stats.rebirthLevel or 0))
			local toName = stats.nextRebirthRankName or ("R" .. tostring((stats.rebirthLevel or 0) + 1))
			local fromMult = stats.rebirthMult or 1
			local toMult = stats.nextRebirthMult or fromMult
			local etaSec = stats.rebirthEtaSeconds
			if type(etaSec) ~= "number" then
				etaSec = 0
			end

			title.Text = "Rebirth"
			body.Text = string.format(
				"Rebirth raises your power multiplier.\n\n%s  %s\n→  %s  %s\n\nProgress  %s / %s\n\n⚠ After rebirth, power progress and coin balance reset.\nSwords, pets, auras, and relics stay.",
				fromName,
				Format.Mult(fromMult),
				toName,
				Format.Mult(toMult),
				Format.Num(powerProg),
				Format.Num(costPower)
			)
			barHost.Visible = true
			fill.Size = UDim2.new(math.clamp(pct :: number, 0, 1), 0, 1, 0)

			-- Ideal ETA with current swords/pets/gear if always clicking
			etaLabel.Visible = true
			if pct >= 1 or etaSec <= 0 then
				etaLabel.Text = "Time to rebirth  ·  ~0s  (ready)"
				etaLabel.TextColor3 = Color3.fromRGB(100, 230, 140)
			else
				etaLabel.Text = string.format(
					"Time to rebirth  ·  ~%s  (ideal click, current gear)",
					Format.Duration(etaSec)
				)
				etaLabel.TextColor3 = Color3.fromRGB(100, 230, 140)
			end

			primary.Text = "Rebirth"
			primaryConn = primary.MouseButton1Click:Connect(function()
				Net.Rebirth()
				store:CloseModal()
			end)
		elseif m.kind == "sell" then
			local w = m.payload
			title.Text = "Sell weapon?"
			body.Text = string.format("%s\nUID %s", tostring(w and w.id), tostring(w and w.uid))
			primary.Text = "Sell"
			primaryConn = primary.MouseButton1Click:Connect(function()
				if w and w.uid then
					Net.SellWeapon(w.uid)
				end
				store:CloseModal()
			end)
		elseif m.kind == "enchant" then
			title.Text = "Enchant"
			body.Text = "Roll sent to server.\nCheck toast / inventory."
			primary.Text = "OK"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		elseif m.kind == "case" then
			local p = m.payload or {}
			local kind = p.kind or "pet"
			local poolId = p.poolId or "loc1_500"

			title.Text = if kind == "aura" then "✨ Aura Case Preview" else ("🐾 Pet Case (" .. tostring(poolId) .. ")")
			body.Text = "Drop Chances & Multi-Open Options:"

			local profile = store:PeekProfile()
			local unlocks = profile and profile.unlocks or {}
			local debugFree = ProgressConfig.DEBUG_FREE_PAID == true
			local hasChest3 = debugFree or (unlocks.openChest3 == true)
			local hasChest5 = debugFree or (unlocks.openChest5 == true)

			-- Build Items List & Drop Chances
			local dropItems = {}
			local totalWeight = 0

			if kind == "pet" then
				for id, pet in PetConfig.Pets do
					if pet.casePool == poolId or (not pet.casePool and pet.location == 1) then
						local w = pet.caseWeight or 10
						totalWeight += w
						table.insert(dropItems, {
							id = id,
							name = pet.name,
							rarity = pet.rarity or "Common",
							weight = w,
							sub = string.format("Power x%.1f", pet.powerMult or 1),
						})
					end
				end
			else
				for id, aura in AuraConfig.Auras do
					local w = aura.dropWeight or 10
					totalWeight += w
					table.insert(dropItems, {
						id = id,
						name = aura.name,
						rarity = aura.rarity or "Common",
						weight = w,
						sub = string.format("+%.0f%% P  +%.0f%% D", aura.powerPct or 0, aura.damagePct or 0),
					})
				end
			end

			-- Sort items by rarity/chance
			table.sort(dropItems, function(a, b)
				return a.weight > b.weight
			end)

			-- Action Bar
			primary.Text = "Open 1x"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
				store:OpenModal("caseOpen", { kind = kind, poolId = poolId, count = 1 })
			end)

			secondary.Text = if hasChest3 then "Open 3x" else "Open 3x 🔒"
			secondary.Visible = true
			secondaryConn = secondary.MouseButton1Click:Connect(function()
				if hasChest3 then
					store:CloseModal()
					store:OpenModal("caseOpen", { kind = kind, poolId = poolId, count = 3 })
				else
					local pass = GamePassConfig.Get("openChest3")
					if pass then Net.PromptGamePass(pass.gamePassId) end
				end
			end)
		elseif m.kind == "stub" then
			local p = m.payload or {}
			title.Text = tostring(p.title or "Soon")
			body.Text = tostring(p.text or "Feature in development.")
			primary.Text = "OK"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		else
			title.Text = "Window"
			body.Text = tostring(m.kind)
			primary.Text = "OK"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		end
	end

	return api
end

return Modals
