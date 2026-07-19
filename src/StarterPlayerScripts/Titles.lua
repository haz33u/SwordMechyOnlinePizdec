--!strict
--[[
	Player titles (placeholder until full title system ships).
	Display: "Title | Nick" — FIXED pixel sizes (no TextScaled / no mushy auto).
]]

local Titles = {}

Titles.DEFAULT = "Rookie"

-- Cool palette for identity line
Titles.TitleColor = Color3.fromRGB(255, 196, 72)
Titles.SepColor = Color3.fromRGB(80, 230, 220)
Titles.NickColor = Color3.fromRGB(235, 245, 255)
Titles.Font = Enum.Font.GothamBlack

-- Fixed sizes (everyone sees nameplate — keep bold & crisp)
Titles.HudTextSize = 18 -- inventory header chip
Titles.HudChipH = 40
Titles.HudIdentityMinW = 220
Titles.HudIdentityMaxW = 360
Titles.PlateTextSize = 32 -- world overhead
Titles.PlateW = 480
Titles.PlateH = 72
Titles.PlateStudsY = 3.1
Titles.PlateMaxDistance = 120

local function hex(c: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.clamp(math.floor(c.R * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.G * 255 + 0.5), 0, 255),
		math.clamp(math.floor(c.B * 255 + 0.5), 0, 255)
	)
end

local function escapeRich(s: string): string
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

--- Resolve title string from profile (future: profile.title)
function Titles.Of(profile: any?): string
	if type(profile) == "table" then
		local t = profile.title
		if type(t) == "string" then
			local trimmed = (t :: string):match("^%s*(.-)%s*$")
			if trimmed and trimmed ~= "" then
				return trimmed
			end
		end
	end
	return Titles.DEFAULT
end

function Titles.Plain(title: string, nick: string): string
	return string.format("%s | %s", title, nick)
end

--- RichText for TextLabel (set TextSize on the label; do NOT use TextScaled)
function Titles.Rich(title: string, nick: string): string
	return string.format(
		'<font color="%s">%s</font> <font color="%s">|</font> <font color="%s">%s</font>',
		hex(Titles.TitleColor),
		escapeRich(title),
		hex(Titles.SepColor),
		hex(Titles.NickColor),
		escapeRich(nick)
	)
end

--- Apply fixed crisp label style (call once on create)
function Titles.StyleLabel(lab: TextLabel, textSize: number)
	lab.Font = Titles.Font
	lab.TextSize = textSize
	lab.TextScaled = false -- critical: scaled text looks blurry
	lab.TextWrapped = false
	lab.RichText = true
	lab.TextColor3 = Titles.NickColor
	lab.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lab.TextStrokeTransparency = 0.28
	lab.TextXAlignment = Enum.TextXAlignment.Center
	lab.TextYAlignment = Enum.TextYAlignment.Center
	lab.BackgroundTransparency = 1
	lab.BorderSizePixel = 0
end

return Titles
