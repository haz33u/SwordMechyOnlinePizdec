--!strict
--[[
	Player titles (placeholder until full title system).
	Plain "Title | Nick" — two separate TextLabels preferred (no RichText).
]]

local Titles = {}

Titles.DEFAULT = "Rookie"
Titles.TitleColor = Color3.fromRGB(255, 196, 72)
Titles.SepColor = Color3.fromRGB(80, 230, 220)
Titles.NickColor = Color3.fromRGB(235, 245, 255)
Titles.Font = Enum.Font.GothamBlack

-- Fixed TextSize only (never TextScaled)
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
