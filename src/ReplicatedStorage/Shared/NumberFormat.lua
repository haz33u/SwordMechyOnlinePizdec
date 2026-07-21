--!strict
--[[
	compact number compact numbers for Loc2 Billions → Loc25 Qdt and beyond.

	Thresholds: every 1e3 steps a new suffix.
	Named ladder (index i → 10^(3*i)):
	  1 K, 2 M, 3 B, 4 T, 5 Qa, 6 Qi, 7 Sx, 8 Sp, 9 Oc, 10 No,
	  11 Dc, 12 Ud, 13 Dd, 14 Td, 15 Qd, 16 Qdt, 17 Qn, 18 Sxd, 19 Spd, 20 Ocd,
	  21 Nod, 22 Vg, … then two-letter aa, ab, ac… (unlimited until double ~1e308).

	Shared: client HUD + server mob HP labels.
]]

local NumberFormat = {}

-- index 1 = 10^3, index 2 = 10^6, …
local NAMED: { string } = {
	"K", -- 1e3
	"M", -- 1e6
	"B", -- 1e9   Loc2 coins / HP already here
	"T", -- 1e12
	"Qa", -- 1e15
	"Qi", -- 1e18
	"Sx", -- 1e21
	"Sp", -- 1e24
	"Oc", -- 1e27
	"No", -- 1e30
	"Dc", -- 1e33
	"Ud", -- 1e36
	"Dd", -- 1e39
	"Td", -- 1e42
	"Qd", -- 1e45
	"Qdt", -- 1e48  ← late Loc25 band
	"Qn", -- 1e51
	"Sxd", -- 1e54
	"Spd", -- 1e57
	"Ocd", -- 1e60
	"Nod", -- 1e63
	"Vg", -- 1e66
	"UVg", -- 1e69
	"DVg", -- 1e72
	"TVg", -- 1e75
	"QaVg", -- 1e78
	"QiVg", -- 1e81
	"SxVg", -- 1e84
	"SpVg", -- 1e87
	"OcVg", -- 1e90
	"NoVg", -- 1e93
	"Ct", -- 1e96
	"UCt", -- 1e99
	"DCt", -- 1e102
	"TCt", -- 1e105
	"QaCt", -- 1e108
	"QiCt", -- 1e111
	"SxCt", -- 1e114
	"SpCt", -- 1e117
	"OcCt", -- 1e120
	"NoCt", -- 1e123
	"Inf", -- 1e126  (name only — not math.huge)
	"UInf", -- 1e129
	"DInf", -- 1e132
	"TInf", -- 1e135
	"QaInf", -- 1e138
	"QiInf", -- 1e141
	"SxInf", -- 1e144
	"SpInf", -- 1e147
	"OcInf", -- 1e150
	"NoInf", -- 1e153
	"Tg", -- 1e156
	"UTg", -- 1e159
	"DTg", -- 1e162
	"TTg", -- 1e165
	"QaTg", -- 1e168
	"QiTg", -- 1e171
	"SxTg", -- 1e174
	"SpTg", -- 1e177
	"OcTg", -- 1e180
	"NoTg", -- 1e183
	"Qag", -- 1e186
	"UQag", -- 1e189
	"DQag", -- 1e192
	"TQag", -- 1e195
	"QaQag", -- 1e198
	"QiQag", -- 1e201
	"SxQag", -- 1e204
	"SpQag", -- 1e207
	"OcQag", -- 1e210
	"NoQag", -- 1e213
	"Qig", -- 1e216
	"UQig", -- 1e219
	"DQig", -- 1e222
	"TQig", -- 1e225
	"QaQig", -- 1e228
	"QiQig", -- 1e231
	"SxQig", -- 1e234
	"SpQig", -- 1e237
	"OcQig", -- 1e240
	"NoQig", -- 1e243
	"Sxg", -- 1e246
	"USxg", -- 1e249
	"DSxg", -- 1e252
	"TSxg", -- 1e255
	"QaSxg", -- 1e258
	"QiSxg", -- 1e261
	"SxSxg", -- 1e264
	"SpSxg", -- 1e267
	"OcSxg", -- 1e270
	"NoSxg", -- 1e273
	"Spg", -- 1e276
	"USpg", -- 1e279
	"DSpg", -- 1e282
	"TSpg", -- 1e285
	"QaSpg", -- 1e288
	"QiSpg", -- 1e291
	"SxSpg", -- 1e294
	"SpSpg", -- 1e297
	"OcSpg", -- 1e300
	"NoSpg", -- 1e303
	-- 1e306 still named zone; beyond → aa letter chain / ∞
}

local MAX_SAFE = 1e308

local function letterPair(index0: number): string
	-- 0 → aa, 1 → ab, … 25 → az, 26 → ba
	local n = math.max(0, math.floor(index0))
	local lo = n % 26
	local hi = math.floor(n / 26) % 26
	return string.char(97 + hi) .. string.char(97 + lo)
end

function NumberFormat.SuffixForTier(tier: number): string
	if tier < 1 then
		return ""
	end
	if tier <= #NAMED then
		return NAMED[tier]
	end
	return letterPair(tier - #NAMED - 1)
end

--- Raw threshold for tier (tier 1 = 1e3).
function NumberFormat.Threshold(tier: number): number
	if tier < 1 then
		return 1
	end
	-- 10^(3*tier); clamp for overflow
	local exp = 3 * tier
	if exp >= 308 then
		return MAX_SAFE
	end
	return 10 ^ exp
end

local function formatMantissa(val: number, absOriginal: number): string
	local a = math.abs(val)
	if absOriginal < 1e6 then
		-- K range: one decimal
		return string.format("%.1f", val)
	end
	if a >= 100 then
		return string.format("%.1f", val)
	elseif a >= 10 then
		return string.format("%.2f", val)
	else
		return string.format("%.2f", val)
	end
end

local function stripTrailingZeros(s: string): string
	-- "1.20B" → "1.2B", "1.00B" → "1B"
	local num, suf = string.match(s, "^([%-]?%d+%.%d+)(%a.*)$")
	if not num then
		return s
	end
	num = string.gsub(num, "(%..-)0+$", "%1")
	num = string.gsub(num, "%.$", "")
	return num .. (suf or "")
end

function NumberFormat.Num(n: number?): string
	if n == nil or n ~= n then
		return "0"
	end
	if n == math.huge then
		return "∞"
	end
	if n == -math.huge then
		return "-∞"
	end

	local abs = math.abs(n)
	if abs < 1000 then
		if n >= 0 then
			return tostring(math.floor(n + 0.5))
		end
		return tostring(math.ceil(n - 0.5))
	end

	if abs >= MAX_SAFE then
		return if n < 0 then "-∞" else "∞"
	end

	-- tier = floor(log10(abs) / 3), at least 1 for abs>=1000
	local log10 = math.log10(abs)
	local tier = math.floor(log10 / 3)
	if tier < 1 then
		tier = 1
	end
	-- Cap tier so mantissa stays in [1, 1000)
	local maxTier = math.floor(307 / 3) -- ~102
	if tier > maxTier then
		tier = maxTier
	end

	local div = 10 ^ (3 * tier)
	local mant = n / div
	-- If rounding pushed to 1000, bump tier
	if math.abs(mant) >= 1000 and tier < maxTier then
		tier += 1
		div = 10 ^ (3 * tier)
		mant = n / div
	end

	local suf = NumberFormat.SuffixForTier(tier)
	local body = formatMantissa(mant, abs) .. suf
	return stripTrailingZeros(body)
end

--- Full ladder for docs / debug (tier → suffix @ 10^(3*tier))
function NumberFormat.DescribeLadder(maxTier: number?): { string }
	local maxT = maxTier or 30
	local lines = {}
	for t = 1, maxT do
		table.insert(lines, string.format("10^%d  %s", 3 * t, NumberFormat.SuffixForTier(t)))
	end
	return lines
end

return NumberFormat
