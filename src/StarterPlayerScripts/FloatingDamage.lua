--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Format = require(script.Parent.Format)

local FloatingDamage = {}

function FloatingDamage.Mount()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "SM_CombatFx" -- not wiped by App dupe filter
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Parent = player:WaitForChild("PlayerGui")

	return function(payload: any)
		if typeof(payload) ~= "table" then
			return
		end
		local amount = payload.damage or payload.amount or payload.n
		if not amount then
			return
		end
		local crit = payload.crit == true
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromOffset(120, 36)
		label.Position = UDim2.fromScale(0.5 + (math.random() - 0.5) * 0.15, 0.42)
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Font = Enum.Font.GothamBlack
		label.TextSize = crit and 28 or 20
		label.TextColor3 = crit and Color3.fromRGB(255, 210, 80) or Color3.fromRGB(255, 240, 240)
		label.TextStrokeTransparency = 0.4
		label.Text = (crit and "CRIT " or "") .. Format.Num(amount)
		label.ZIndex = 60
		label.Parent = gui

		local tween = TweenService:Create(label, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = label.Position - UDim2.fromOffset(0, 48),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			label:Destroy()
		end)
	end
end

return FloatingDamage
