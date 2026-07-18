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
		Size = UDim2.fromOffset(px(440), px(260)),
		Position = UDim2.fromScale(0.5, 0.5),
		Anchor = Vector2.new(0.5, 0.5),
		Radius = T.R.lg,
		Z = 51,
		Deep = true,
		AccentBar = true,
	})
	card.Visible = false
	UIKit.Stroke(card, T.Gold, 1.6, 0.4)
	UIKit.Pad(card, px(22))

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
		Size = UDim2.new(1, 0, 0, px(84)),
		Position = UDim2.fromOffset(0, px(42)),
		SizePx = px(15),
		Color = T.TextSoft,
		X = Enum.TextXAlignment.Center,
		Y = Enum.TextYAlignment.Top,
		Wrap = true,
		Z = 52,
	})

	local barHost = Instance.new("Frame")
	barHost.BackgroundTransparency = 1
	barHost.Size = UDim2.new(1, 0, 0, px(12))
	barHost.Position = UDim2.fromOffset(0, px(140))
	barHost.ZIndex = 52
	barHost.Visible = false
	barHost.Parent = card
	local _, fill = UIKit.Bar(barHost, 0, T.Accent, px(10))

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
		Text = "Отмена",
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
		if primaryConn then
			primaryConn:Disconnect()
			primaryConn = nil
		end

		if m.kind == "rebirth" then
			local stats = store:PeekStats() or {}
			local dmg = stats.lifetimeDamage or 0
			local cost = stats.nextRebirthCost or 1
			local pct = cost > 0 and math.clamp(dmg / cost, 0, 1) or 0
			title.Text = "Перерождение"
			body.Text = string.format(
				"Урон %s / %s\nСейчас R%d %s\nМечи и петы остаются.",
				Format.Num(dmg),
				Format.Num(cost),
				stats.rebirthLevel or 0,
				Format.Mult(stats.rebirthMult)
			)
			barHost.Visible = true
			fill.Size = UDim2.new(pct, 0, 1, 0)
			primary.Text = "Переродиться"
			primaryConn = primary.MouseButton1Click:Connect(function()
				Net.Rebirth()
				store:CloseModal()
			end)
		elseif m.kind == "sell" then
			local w = m.payload
			title.Text = "Продать меч?"
			body.Text = string.format("%s\nUID %s", tostring(w and w.id), tostring(w and w.uid))
			primary.Text = "Продать"
			primaryConn = primary.MouseButton1Click:Connect(function()
				if w and w.uid then
					Net.SellWeapon(w.uid)
				end
				store:CloseModal()
			end)
		elseif m.kind == "enchant" then
			title.Text = "Зачарование"
			body.Text = "Ролл ушёл на сервер.\nСмотри toast / инвентарь."
			primary.Text = "Ок"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		elseif m.kind == "case" then
			local kind = (m.payload and m.payload.kind) or "pet"
			title.Text = kind == "aura" and "Кейс ауры" or "Кейс питомца"
			body.Text = "Открываем…"
			primary.Text = "Ок"
			task.delay(1.0, function()
				local cur = store:PeekModal()
				if cur and cur.kind == "case" then
					body.Text = "Готово — смотри список."
				end
			end)
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		else
			title.Text = "Окно"
			body.Text = tostring(m.kind)
			primary.Text = "Ок"
			primaryConn = primary.MouseButton1Click:Connect(function()
				store:CloseModal()
			end)
		end
	end

	return api
end

return Modals
