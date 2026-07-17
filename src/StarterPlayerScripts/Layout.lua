--!strict
--[[
	8px grid metrics — even spacing, aligned columns.
	Base: 1366×768. Everything snaps to grid.
]]

local Layout = {}

export type Metrics = {
	scale: number,
	vpX: number,
	vpY: number,
	pad: number,
	gap: number,
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
	chipW: number,
	chipGap: number,
	windowW: number,
	windowH: number,
	fontSm: number,
	fontMd: number,
	fontLg: number,
	fontXl: number,
}

local function snap(n: number, grid: number?): number
	local g = grid or 4
	return math.floor(n / g + 0.5) * g
end

function Layout.Compute(vp: Vector2?): Metrics
	local x = (vp and vp.X) or 1366
	local y = (vp and vp.Y) or 768
	local s = math.clamp(math.min(x / 1366, y / 768), 0.75, 1.3)

	local pad = snap(12 * s, 4)
	local gap = snap(10 * s, 2)
	local railBtn = snap(56 * s, 4)
	local railGap = snap(8 * s, 2)
	local railW = snap(railBtn + pad * 2, 4)
	local btnH = snap(52 * s, 4)
	-- same height for all action buttons (even row)
	local clickH = btnH
	local actionH = snap(btnH + pad * 2 + 4, 4)
	local actionW = snap(math.clamp(x * 0.4, 360 * s, 480 * s), 4)
	local actionGap = gap
	-- three columns: 1 : 1.35 : 1  of remaining width after gaps
	local inner = actionW - pad * 2 - actionGap * 2
	local unit = inner / (1 + 1.35 + 1)
	local btnAutoW = snap(unit * 1, 2)
	local btnClickW = snap(unit * 1.35, 2)
	local btnRebW = snap(inner - btnAutoW - btnClickW, 2)

	-- equal chip width so row looks even
	local chipH = snap(44 * s, 2)
	local chipGap = gap
	local chipW = snap(108 * s, 2)

	return {
		scale = s,
		vpX = x,
		vpY = y,
		pad = pad,
		gap = gap,
		topH = snap(chipH + pad, 2),
		railW = railW,
		railBtn = railBtn,
		railGap = railGap,
		actionH = actionH,
		actionW = actionW,
		actionGap = actionGap,
		btnAutoW = btnAutoW,
		btnClickW = btnClickW,
		btnRebW = btnRebW,
		btnH = btnH,
		clickH = clickH,
		chipH = chipH,
		chipW = chipW,
		chipGap = chipGap,
		windowW = math.clamp(0.46, 0.42, 0.54),
		windowH = math.clamp(0.58, 0.52, 0.66),
		fontSm = math.max(11, snap(11 * s, 1)),
		fontMd = math.max(13, snap(14 * s, 1)),
		fontLg = math.max(15, snap(17 * s, 1)),
		fontXl = math.max(18, snap(20 * s, 1)),
	}
end

function Layout.Bind(callback: (Metrics) -> ())
	local function fire()
		local c = workspace.CurrentCamera
		callback(Layout.Compute(c and c.ViewportSize or nil))
	end
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fire)
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		if workspace.CurrentCamera then
			workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fire)
			fire()
		end
	end)
	fire()
end

return Layout
