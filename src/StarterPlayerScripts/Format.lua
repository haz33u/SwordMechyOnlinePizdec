--!strict
--[[
	Client formatting helpers.
	Big numbers → Shared.NumberFormat (K…B…Qdt…∞).
]]

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local NumberFormat = require(Shared:WaitForChild("NumberFormat"))

local Format = {}

function Format.Num(n: number?): string
	return NumberFormat.Num(n)
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
	if seconds == math.huge or seconds > 1e15 then
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
