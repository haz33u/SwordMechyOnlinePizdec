--!strict
--[[
	Rainbow & Accent Shimmer Gradient animation helper for UI text labels, buttons, frames.
	Provides:
	  1) Full RGB Rainbow rotation
	  2) Accent Color Shimmers (Green/Emerald, Gold/Yellow, Fire/Orange, Void/Purple, Cyan/Ice)
]]

local RunService = game:GetService("RunService")

local RainbowGradient = {}

export type RainbowController = {
	Stop: () -> (),
}

export type ShimmerPreset = {
	minHue: number,
	maxHue: number,
	sat: number?,
	val: number?,
}

local PRESETS: { [string]: ShimmerPreset } = {
	green = { minHue = 0.25, maxHue = 0.42, sat = 1, val = 1 }, -- Lime → Emerald
	emerald = { minHue = 0.28, maxHue = 0.40, sat = 1, val = 1 },
	gold = { minHue = 0.07, maxHue = 0.16, sat = 1, val = 1 }, -- Gold → Sun Yellow
	yellow = { minHue = 0.11, maxHue = 0.18, sat = 1, val = 1 },
	fire = { minHue = 0.00, maxHue = 0.11, sat = 1, val = 1 }, -- Crimson → Fire Orange
	orange = { minHue = 0.04, maxHue = 0.13, sat = 1, val = 1 },
	purple = { minHue = 0.70, maxHue = 0.85, sat = 0.95, val = 1 }, -- Deep Violet → Neon Purple
	void = { minHue = 0.73, maxHue = 0.88, sat = 0.95, val = 1 },
	cyan = { minHue = 0.47, maxHue = 0.58, sat = 1, val = 1 }, -- Turquoise → Ice Blue
	ice = { minHue = 0.50, maxHue = 0.60, sat = 0.85, val = 1 },
	silver = { minHue = 0.00, maxHue = 1.00, sat = 0.05, val = 0.95 }, -- Platinum Silver
}

--- Apply full RGB Rainbow gradient.
function RainbowGradient.Apply(target: Instance, speed: number?, hueSpread: number?, rotSpeed: number?): RainbowController?
	if not target or not (target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("Frame") or target:IsA("ImageLabel")) then
		return nil
	end

	local spd = speed or 0.35
	local spread = hueSpread or 0.35
	local rotSpd = rotSpeed or 90

	if target:IsA("TextLabel") or target:IsA("TextButton") then
		(target :: any).TextColor3 = Color3.new(1, 1, 1);
		(target :: any).RichText = true
	end

	local gradient = target:FindFirstChildWhichIsA("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "RainbowGradient"
		gradient.Parent = target
	end

	local running = true
	local hue = 0

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not running or not target.Parent or not gradient.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end

		hue = (hue + dt * spd) % 1
		local hueEnd = (hue + spread) % 1

		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(hue, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(hueEnd, 1, 1)),
		})
		gradient.Rotation = (gradient.Rotation + dt * rotSpd) % 360
	end)

	return {
		Stop = function()
			running = false
			if conn then
				conn:Disconnect()
			end
		end,
	}
end

--- Apply accent color shimmer (e.g. "green", "gold", "fire", "purple", "cyan").
function RainbowGradient.ApplyShimmer(target: Instance, presetNameOrConfig: (string | ShimmerPreset)?, speed: number?, rotSpeed: number?): RainbowController?
	if not target or not (target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("Frame") or target:IsA("ImageLabel")) then
		return nil
	end

	local preset: ShimmerPreset = PRESETS.green
	if type(presetNameOrConfig) == "string" then
		preset = PRESETS[string.lower(presetNameOrConfig)] or PRESETS.green
	elseif type(presetNameOrConfig) == "table" then
		preset = presetNameOrConfig :: ShimmerPreset
	end

	local spd = speed or 1.2
	local rotSpd = rotSpeed or 45

	if target:IsA("TextLabel") or target:IsA("TextButton") then
		(target :: any).TextColor3 = Color3.new(1, 1, 1);
		(target :: any).RichText = true
	end

	local gradient = target:FindFirstChildWhichIsA("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Name = "AccentGradient"
		gradient.Parent = target
	end

	local running = true
	local elapsed = 0

	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not running or not target.Parent or not gradient.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end

		elapsed += dt
		local wave = (math.sin(elapsed * spd * math.pi) + 1) * 0.5
		local minH = preset.minHue
		local maxH = preset.maxHue
		local sat = preset.sat or 1
		local val = preset.val or 1

		local h1 = minH + (maxH - minH) * wave
		local h2 = minH + (maxH - minH) * (1 - wave)

		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHSV(h1, sat, val)),
			ColorSequenceKeypoint.new(1, Color3.fromHSV(h2, sat, val)),
		})
		gradient.Rotation = (gradient.Rotation + dt * rotSpd) % 360
	end)

	return {
		Stop = function()
			running = false
			if conn then
				conn:Disconnect()
			end
		end,
	}
end

return RainbowGradient
