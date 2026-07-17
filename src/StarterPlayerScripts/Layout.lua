--!strict
--[[
	Resolution-aware metrics. Everything HUD/window sizes off this.
	Base design: 1366×768. Scales with min(vp/base), clamped.
]]

local Layout = {}

export type Metrics = {
	scale: number,
	vpX: number,
	vpY: number,
	pad: number,
	topH: number,
	railW: number,
	railBtn: number,
	railGap: number,
	actionH: number,
	actionW: number,
	actionGap: number,
	btnAutoW: number,
	btnClickW: number,
	btnRebW: number,
	btnH: number,
	clickH: number,
	chipH: number,
	chipGap: number,
	windowW: number,
	windowH: number,
	fontSm: number,
	fontMd: number,
	fontLg: number,
	fontXl: number,
}

function Layout.Compute(vp: Vector2?): Metrics
	local x = (vp and vp.X) or 1366
	local y = (vp and vp.Y) or 768
	-- Prefer width for desktop, height for short screens
	local s = math.clamp(math.min(x / 1366, y / 768), 0.72, 1.35)

	local pad = math.floor(12 * s + 0.5)
	local railW = math.floor(72 * s + 0.5)
	local railBtn = math.floor(56 * s + 0.5)
	local actionH = math.floor(92 * s + 0.5)
	local btnH = math.floor(52 * s + 0.5)
	local clickH = math.floor(58 * s + 0.5)

	-- Action bar width: ~42% of screen, min/max
	local actionW = math.clamp(math.floor(x * 0.42), math.floor(340 * s), math.floor(520 * s))

	return {
		scale = s,
		vpX = x,
		vpY = y,
		pad = pad,
		topH = math.floor(58 * s + 0.5),
		railW = railW,
		railBtn = railBtn,
		railGap = math.floor(8 * s + 0.5),
		actionH = actionH,
		actionW = actionW,
		actionGap = math.floor(12 * s + 0.5),
		btnAutoW = math.floor(actionW * 0.26),
		btnClickW = math.floor(actionW * 0.38),
		btnRebW = math.floor(actionW * 0.22),
		btnH = btnH,
		clickH = clickH,
		chipH = math.floor(44 * s + 0.5),
		chipGap = math.floor(8 * s + 0.5),
		windowW = math.clamp(0.48 + (s - 1) * 0.04, 0.42, 0.56),
		windowH = math.clamp(0.58 + (s - 1) * 0.04, 0.52, 0.68),
		fontSm = math.floor(11 * s + 0.5),
		fontMd = math.floor(14 * s + 0.5),
		fontLg = math.floor(17 * s + 0.5),
		fontXl = math.floor(22 * s + 0.5),
	}
end

function Layout.Bind(callback: (Metrics) -> ())
	local cam = workspace.CurrentCamera
	local function fire()
		local c = workspace.CurrentCamera
		callback(Layout.Compute(c and c.ViewportSize or nil))
	end
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(fire)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local c = workspace.CurrentCamera
		if c then
			c:GetPropertyChangedSignal("ViewportSize"):Connect(fire)
			fire()
		end
	end)
	fire()
end

return Layout
