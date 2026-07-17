--!strict
--[[
	Layout metrics — rail flexes to N buttons, stats sit ABOVE bottom dock
	(never under Roblox topbar).
]]

local Layout = {}

export type Metrics = {
	scale: number,
	vpX: number,
	vpY: number,
	pad: number,
	gap: number,
	railCount: number,
	railW: number,
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

--- railCount must match Hud.RAIL length
function Layout.Compute(vp: Vector2?, railCount: number?): Metrics
	local n = math.max(1, railCount or 8)
	local x = (vp and vp.X) or 1366
	local y = (vp and vp.Y) or 768
	local s = math.clamp(math.min(x / 1366, y / 720), 0.8, 1.2)

	local pad = snap(12 * s, 2)
	local gap = snap(8 * s, 2)

	local btnH = snap(50 * s, 2)
	local actionH = btnH + pad * 2
	local actionW = snap(math.clamp(x * 0.4, 360, 460), 2)
	local actionGap = gap
	local inner = actionW - pad * 2 - actionGap * 2
	local unit = inner / (1 + 1.35 + 1)
	local btnAutoW = snap(unit, 2)
	local btnClickW = snap(unit * 1.35, 2)
	local btnRebW = math.max(70, inner - btnAutoW - btnClickW)

	local chipH = snap(42 * s, 2)
	local statsH = chipH + pad
	-- space above action for stats strip
	local bottomBlock = actionH + statsH + pad * 2 + 10

	-- Rail: full left column, buttons EQUAL share of height
	local railPad = snap(8 * s, 2)
	local railGap = snap(6 * s, 2)
	local railTop = pad -- small top margin only (safe area already inset)
	local availH = math.max(240, y - railTop - bottomBlock - pad)
	local railBtn = math.floor((availH - railPad * 2 - railGap * (n - 1)) / n)
	railBtn = math.clamp(snap(railBtn, 2), 32, 56)
	local railW = railBtn + railPad * 2

	local chipW = snap(math.clamp((x - railW - pad * 3) / 7.2, 92, 120), 2)

	return {
		scale = s,
		vpX = x,
		vpY = y,
		pad = pad,
		gap = gap,
		railCount = n,
		railW = railW,
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
		windowW = 0.5,
		windowH = 0.62,
		fontSm = math.max(11, math.floor(11 * s + 0.5)),
		fontMd = math.max(13, math.floor(14 * s + 0.5)),
		fontLg = math.max(15, math.floor(16 * s + 0.5)),
		fontXl = math.max(18, math.floor(20 * s + 0.5)),
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
