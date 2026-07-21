--!strict
--[[
	Player titles + rebirth rank paint (gradient / stroke).
	Plain "Title | Nick" — two separate TextLabels preferred (no RichText on nick line).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local RebirthConfig = require(Shared.Config.RebirthConfig)

local Titles = {}

Titles.DEFAULT = "Rookie"
Titles.TitleColor = Color3.fromRGB(255, 196, 72)
Titles.SepColor = Color3.fromRGB(80, 230, 220)
Titles.NickColor = Color3.fromRGB(235, 245, 255)
Titles.Font = Enum.Font.GothamBlack

Titles.HudTextSize = 16
Titles.PlateTextSize = 22

function Titles.Of(profile: any?): string
	if type(profile) == "table" and type(profile.title) == "string" then
		local t = (profile.title :: string):match("^%s*(.-)%s*$")
		if t and t ~= "" then
			return t
		end
	end
	return Titles.DEFAULT
end

--- Prestige rank string from rebirth level (does not replace custom title).
function Titles.RankOf(profile: any?): string
	local lv = 0
	if type(profile) == "table" then
		lv = math.floor(profile.rebirthLevel or 0)
	end
	return RebirthConfig.GetRankName(lv)
end

--- Apply band color / stroke / optional gradient to a rank label.
function Titles.PaintRank(label: TextLabel, rebirthLevel: number?)
	local lv = math.floor(rebirthLevel or 0)
	local style = RebirthConfig.GetRankStyle(lv)
	label.Text = RebirthConfig.GetRankName(lv)
	label.TextColor3 = style.color
	label.Font = Titles.Font
	label.TextScaled = false
	label.RichText = false

	local stroke = label:FindFirstChildOfClass("UIStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Parent = label
	end
	stroke.Color = style.stroke
	stroke.Thickness = style.strokeThickness
	stroke.Transparency = 0.15

	local grad = label:FindFirstChildOfClass("UIGradient")
	if style.gradientFrom and style.gradientTo then
		if not grad then
			grad = Instance.new("UIGradient")
			grad.Parent = label
		end
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, style.gradientFrom),
			ColorSequenceKeypoint.new(1, style.gradientTo),
		})
		grad.Rotation = 15
	elseif grad then
		grad:Destroy()
	end
end

--- Fill three plain labels: title | nick (fixed TextSize, no RichText)
function Titles.PaintLine(titleLab: TextLabel, sepLab: TextLabel?, nickLab: TextLabel, profile: any?, nick: string)
	local title = Titles.Of(profile)
	titleLab.Text = title
	titleLab.TextColor3 = Titles.TitleColor
	titleLab.Font = Titles.Font
	titleLab.TextScaled = false
	titleLab.RichText = false

	if sepLab then
		sepLab.Text = "|"
		sepLab.TextColor3 = Titles.SepColor
		sepLab.Font = Titles.Font
		sepLab.TextScaled = false
		sepLab.RichText = false
	end

	nickLab.Text = nick
	nickLab.TextColor3 = Titles.NickColor
	nickLab.Font = Titles.Font
	nickLab.TextScaled = false
	nickLab.RichText = false
end

return Titles
