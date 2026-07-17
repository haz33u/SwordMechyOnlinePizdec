--!strict
--[[
	Floating +N click icons rising from the bottom action bar (manual + auto).
]]

local TweenService = game:GetService("TweenService")
local Format = require(script.Parent.Format)
local T = require(script.Parent.Theme)

local ClickPop = {}

export type Api = {
	SetAnchor: (self: Api, guiObject: GuiObject) -> (),
	Burst: (self: Api, amount: number?, crit: boolean?, source: string?) -> (),
}

function ClickPop.Mount(hostGui: ScreenGui): Api
	local layer = Instance.new("Frame")
	layer.Name = "ClickPopLayer"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 80
	layer.ClipsDescendants = false
	layer.Parent = hostGui

	local anchor: GuiObject? = nil

	local api = {} :: Api

	function api:SetAnchor(guiObject: GuiObject)
		anchor = guiObject
	end

	function api:Burst(amount: number?, crit: boolean?, source: string?)
		local n = amount or 1
		local isCrit = crit == true
		local isAuto = source == "auto"

		local baseX = 0.5
		local baseY = 0.82
		if anchor and anchor.AbsoluteSize.X > 0 then
			local parent = hostGui
			local abs = anchor.AbsolutePosition
			local size = anchor.AbsoluteSize
			local pg = parent.AbsoluteSize
			if pg.X > 0 and pg.Y > 0 then
				baseX = (abs.X + size.X * 0.5) / pg.X
				baseY = (abs.Y + size.Y * 0.15) / pg.Y
			end
		end

		local jitterX = (math.random() - 0.5) * 0.12
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Size = UDim2.fromOffset(isCrit and 140 or 110, isCrit and 40 or 32)
		label.Position = UDim2.fromScale(baseX + jitterX, baseY)
		label.Font = Enum.Font.GothamBlack
		label.TextSize = isCrit and 26 or 20
		label.TextStrokeTransparency = 0.25
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.ZIndex = 85
		if isCrit then
			label.TextColor3 = T.Pop.Crit
			label.Text = "CRIT +" .. Format.Num(n)
		elseif isAuto then
			label.TextColor3 = T.Pop.Auto
			label.Text = "+" .. Format.Num(n)
		else
			label.TextColor3 = T.Pop.Normal
			label.Text = "+" .. Format.Num(n)
		end
		label.Parent = layer

		local rise = 50 + math.random(0, 30)
		local drift = (math.random() - 0.5) * 40
		local goal = label.Position + UDim2.fromOffset(drift, -rise)

		local tw = TweenService:Create(
			label,
			TweenInfo.new(0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				Position = goal,
				TextTransparency = 1,
				TextStrokeTransparency = 1,
			}
		)
		-- soft scale pop
		local sc = Instance.new("UIScale")
		sc.Scale = 0.6
		sc.Parent = label
		TweenService:Create(sc, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = isCrit and 1.25 or 1.05,
		}):Play()

		tw:Play()
		tw.Completed:Connect(function()
			label:Destroy()
		end)
	end

	return api
end

return ClickPop
