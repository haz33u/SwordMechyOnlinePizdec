--!strict
--[[
	Responsive scale: UIScale = clamp(viewportY / 1080, 0.7, 2.0)
	Rail packs to N buttons (height = content, not full stretch).
	Base design units at 1080p; UIScale handles resolution.
]]

local Layout = {}

export type Metrics = {
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

local BASE_Y = 1080
local MIN_SCALE = 0.7
local MAX_SCALE = 2.0

local function snap(n: number, g: number?): number
	local grid = g or 2
	return math.floor(n / grid + 0.5) * grid
end

function Layout.UiScaleFromViewport(vp: Vector2?): number
	local y = (vp and vp.Y) or BASE_Y
	return math.clamp(y / BASE_Y, MIN_SCALE, MAX_SCALE)
end

--- Design-space metrics (pre-UIScale). UIScale multiplies the whole ScreenGui.
function Layout.Compute(vp: Vector2?, railCount: number?): Metrics
	local n = math.max(1, railCount or 8)
	local x = (vp and vp.X) or 1920
	local y = (vp and vp.Y) or 1080
	local uiScale = Layout.UiScaleFromViewport(vp)

	-- design units at 1080p (UIScale does the rest)
	local pad = 14
	local gap = 10

	local btnH = 56
	local actionH = btnH + pad * 2
	-- action width as fraction of viewport, converted to design px
	local actionW = snap(math.clamp((x / uiScale) * 0.4, 380, 520), 2)
	local actionGap = gap
	local inner = actionW - pad * 2 - actionGap * 2
	local unit = inner / (1 + 1.45 + 1)
	local btnAutoW = snap(unit, 2)
	local btnClickW = snap(unit * 1.45, 2)
	local btnRebW = math.max(88, inner - btnAutoW - btnClickW)

	local chipH = 52
	local statsH = chipH + 8

	-- Rail: pack to N — equal button size, height = content
	local railPad = 10
	local railGap = 8
	local railBtn = 52
	local railH = railPad * 2 + n * railBtn + (n - 1) * railGap
	local railW = railBtn + railPad * 2

	-- Fit rail into available design height if needed
	local designH = y / uiScale
	local bottomBlock = actionH + statsH + pad * 3 + 20
	local maxRailH = math.max(220, designH - pad * 2 - bottomBlock)
	if railH > maxRailH then
		railBtn = math.floor((maxRailH - railPad * 2 - railGap * (n - 1)) / n)
		railBtn = math.clamp(snap(railBtn, 2), 36, 56)
		railH = railPad * 2 + n * railBtn + (n - 1) * railGap
		railW = railBtn + railPad * 2
	end

	local designW = x / uiScale
	local chipW = snap(math.clamp((designW - railW - pad * 4) / 7.0, 104, 136), 2)

	return {
		uiScale = uiScale,
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
		windowW = 0.5,
		windowH = 0.62,
		fontSm = 12,
		fontMd = 15,
		fontLg = 18,
		fontXl = 24,
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
