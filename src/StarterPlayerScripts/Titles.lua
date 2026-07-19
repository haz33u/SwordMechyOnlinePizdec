--!strict
--[[
	Player titles (placeholder until full title system ships).
	Display: "Title | Nick" with gold title + cyan separator.
]]

local Titles = {}

Titles.DEFAULT = "Rookie"

-- Cool palette for identity line
Titles.TitleColor = Color3.fromRGB(255, 196, 72)
Titles.SepColor = Color3.fromRGB(80, 230, 220)
Titles.NickColor = Color3.fromRGB(235, 245, 255)
Titles.Font = Enum.Font.GothamBlack

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

--- RichText for TextLabel (TextLabel.RichText = true)
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

return Titles
