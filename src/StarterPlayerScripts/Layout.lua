--!strict
--[[
	Compact layout: rail packs to N buttons (no full-height stretch).
	Slight global upscale for readability.
]]

local Layout = {}

export type Metrics = {
	scale: number,
	uiScale: number,
	vpX: number,
	vpY: number,
	pad: number,
	gap: number,
	railCount: number,
	railW: number,
	railH: number,
	railBtn: number,
	railGap: number,
	railPad: number,
	actionH: number,
	actionW: number,
	actionGap: number,
	btnAutoW: number,
	btnClickW: number,
	btnRebW: number,
	btnH: number,
	statsH: number,
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

local function snap(n: number, g: number?): number
	local grid = g or 2
	return math.floor(n / grid + 0.5) * grid
end

function Layout.Compute(vp: Vector2?, railCount: number?): Metrics
	local n = math.max(1, railCount or 8)
	local x = (vp and vp.X) or 1366
	local y = (vp and vp.Y) or 768
	-- base scale + intentional upscale (~12%)
	local s = math.clamp(math.min(x / 1366, y / 720), 0.82, 1.25) * 1.12

	local pad = snap(12 * s, 2)
	local gap = snap(10 * s, 2)

	-- Bottom action cluster (juicy)
	local btnH = snap(56 * s, 2)
	local actionH = btnH + pad * 2 + 4
	local actionW = snap(math.clamp(x * 0.42, 380 * s, 500 * s), 2)
	local actionGap = gap
	local inner = actionW - pad * 2 - actionGap * 2
	local unit = inner / (1 + 1.4 + 1)
	local btnAutoW = snap(unit, 2)
	local btnClickW = snap(unit * 1.4, 2)
	local btnRebW = math.max(snap(80 * s, 2), inner - btnAutoW - btnClickW)

	local chipH = snap(48 * s, 2)
	local statsH = chipH + 6

	-- Rail: FIXED button size, height = N*btn + gaps (compact pack, NOT stretched)
	local railPad = snap(10 * s, 2)
	local railGap = snap(8 * s, 2)
	local railBtn = snap(math.clamp(52 * s, 44, 60), 2)
	local railH = railPad * 2 + n * railBtn + (n - 1) * railGap
	local railW = railBtn + railPad * 2

	-- If rail taller than free space, shrink buttons to fit (still equal)
	local bottomBlock = actionH + statsH + pad * 3 + 16
	local maxRailH = math.max(200, y - pad * 2 - bottomBlock)
	if railH > maxRailH then
		railBtn = math.floor((maxRailH - railPad * 2 - railGap * (n - 1)) / n)
		railBtn = math.clamp(snap(railBtn, 2), 36, 60)
		railH = railPad * 2 + n * railBtn + (n - 1) * railGap
		railW = railBtn + railPad * 2
	end

	local chipW = snap(math.clamp((x - railW - pad * 4) / 7.0, 100 * s, 130 * s), 2)

	return {
		scale = s,
		uiScale = s,
		vpX = x,
		vpY = y,
		pad = pad,
		gap = gap,
		railCount = n,
		railW = railW,
		railH = railH,
		railBtn = railBtn,
		railGap = railGap,
		railPad = railPad,
		actionH = actionH,
		actionW = actionW,
		actionGap = actionGap,
		btnAutoW = btnAutoW,
		btnClickW = btnClickW,
		btnRebW = btnRebW,
		btnH = btnH,
		statsH = statsH,
		chipH = chipH,
		chipW = chipW,
		chipGap = gap,
		windowW = 0.52,
		windowH = 0.64,
		fontSm = math.max(12, math.floor(12 * s + 0.5)),
		fontMd = math.max(14, math.floor(15 * s + 0.5)),
		fontLg = math.max(16, math.floor(18 * s + 0.5)),
		fontXl = math.max(20, math.floor(22 * s + 0.5)),
	}
end

function Layout.Bind(callback: (Metrics) -> (), railCount: number?)
	local function fire()
		local c = workspace.CurrentCamera
		callback(Layout.Compute(c and c.ViewportSize or nil, railCount))
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
