--!strict
--[[ Compact K/M/B formatting for Cristalix-style numbers. ]]

local Format = {}

function Format.Num(n: number?): string
	if n == nil or n ~= n then
		return "0"
	end
	n = math.floor(n + 0.5)
	local abs = math.abs(n)
	if abs >= 1e15 then
		return string.format("%.2fQ", n / 1e15)
	elseif abs >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif abs >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif abs >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif abs >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

function Format.Pct(frac: number?): string
	return string.format("%.0f%%", (frac or 0) * 100)
end

function Format.Mult(m: number?): string
	return string.format("×%.2f", m or 1)
end

--- Compact duration: 0s | 12s | 24m 7s | 1h 5m
function Format.Duration(seconds: number?): string
	if seconds == nil or seconds ~= seconds then
		return "—"
	end
	if seconds <= 0 then
		return "0s"
	end
	if seconds == math.huge or seconds > 1e12 then
		return "∞"
	end
	local s = math.floor(seconds + 0.5)
	local h = math.floor(s / 3600)
	local m = math.floor((s % 3600) / 60)
	local sec = s % 60
	if h > 0 then
		return string.format("%dh %dm", h, m)
	end
	if m > 0 then
		return string.format("%dm %ds", m, sec)
	end
	return string.format("%ds", sec)
end

return Format
