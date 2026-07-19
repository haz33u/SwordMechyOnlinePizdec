--!strict

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)

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
			local dmg = stats.lifetimeDamage or 0
			local costDmg = stats.nextRebirthCost or 1
			local pct = stats.rebirthProgress
			if type(pct) ~= "number" then
				pct = costDmg > 0 and math.clamp(dmg / costDmg, 0, 1) or 1
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
				"Rebirth increases your power booster.\n\n%s ×%.0f  →  %s ×%.0f\n\nProgress  %s / %s\n\n⚠ After rebirth, damage progress and balance are lost!\nSwords and pets stay.",
				fromName,
				fromMult,
				toName,
				toMult,
				Format.Num(dmg),
				Format.Num(costDmg)
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
			local kind = (m.payload and m.payload.kind) or "pet"
			title.Text = kind == "aura" and "Aura Case" or "Pet Case"
			body.Text = "Opening…"
			primary.Text = "OK"
			task.delay(1.0, function()
				local cur = store:PeekModal()
				if cur and cur.kind == "case" then
					body.Text = "Done — check your list."
				end
			end)
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
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
