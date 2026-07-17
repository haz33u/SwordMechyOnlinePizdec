--!strict
--[[
	8px grid. Rail buttons size to FIT viewport so all 8 stay visible.
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
	local g = grid or 2
	return math.floor(n / g + 0.5) * g
end

function Layout.Compute(vp: Vector2?): Metrics
	local x = (vp and vp.X) or 1366
	local y = (vp and vp.Y) or 768
	-- GuiInset already applied when IgnoreGuiInset=false; use safe area height
	local s = math.clamp(math.min(x / 1366, y / 720), 0.78, 1.25)

	local pad = snap(10 * s, 2)
	local gap = snap(8 * s, 2)
	local chipH = snap(40 * s, 2)
	local topH = chipH + 4
	local btnH = snap(48 * s, 2)
	local actionH = btnH + pad * 2
	local actionW = snap(math.clamp(x * 0.38, 340, 440), 2)
	local actionGap = gap
	local inner = actionW - pad * 2 - actionGap * 2
	local unit = inner / (1 + 1.3 + 1)
	local btnAutoW = snap(unit, 2)
	local btnClickW = snap(unit * 1.3, 2)
	local btnRebW = math.max(64, inner - btnAutoW - btnClickW)

	-- Rail: fit 8 equal buttons into available height
	local railTop = pad + topH + gap
	local railBottom = actionH + pad * 2 + 16
	local availRail = math.max(200, y - railTop - railBottom)
	local railGap = 6
	local railBtn = math.floor((availRail - pad * 2 - railGap * 7) / 8)
	railBtn = math.clamp(snap(railBtn, 2), 34, 52)
	local railW = railBtn + pad * 2

	-- Chips: fewer px so row fits; location wider
	local chipW = snap(math.clamp((x - railW - pad * 4) / 7.4, 88, 112), 2)

	return {
		scale = s,
		vpX = x,
		vpY = y,
		pad = pad,
		gap = gap,
		topH = topH,
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
		clickH = btnH,
		chipH = chipH,
		chipW = chipW,
		chipGap = gap,
		windowW = 0.5,
		windowH = 0.62,
		fontSm = math.max(11, math.floor(11 * s + 0.5)),
		fontMd = math.max(13, math.floor(13 * s + 0.5)),
		fontLg = math.max(15, math.floor(16 * s + 0.5)),
		fontXl = math.max(18, math.floor(19 * s + 0.5)),
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
