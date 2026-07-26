--!strict
--[[
	Rainbow Gradient animation helper for UI text labels, buttons, and frames.
	Smoothly rotates a 60 FPS HSL rainbow gradient around the UI element.
]]

local RunService = game:GetService("RunService")

local RainbowGradient = {}

export type RainbowController = {
	Stop: () -> (),
}

--- Apply animated rainbow gradient to any TextLabel, TextButton, Frame, or ImageLabel.
function RainbowGradient.Apply(target: Instance, speed: number?, hueSpread: number?, rotSpeed: number?): RainbowController?
	if not target or not (target:IsA("TextLabel") or target:IsA("TextButton") or target:IsA("Frame") or target:IsA("ImageLabel")) then
		return nil
	end

	local spd = speed or 0.35 -- hue cycle speed (cycles per second)
	local spread = hueSpread or 0.35 -- rainbow color difference across text
	local rotSpd = rotSpeed or 90 -- degrees rotation per second

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

return RainbowGradient
