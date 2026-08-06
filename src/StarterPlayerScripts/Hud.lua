--!strict
--[[
	Main HUD — SCREEENS "главный интерфейс пользователя":
	- top-left: active boosts
	- bottom-center: coins + power, Q=rebirth, E=inventory
	- left rail: menus
	CPS/DPS/Clicks live in character/profile panel, not here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local T = require(script.Parent.Theme)
local UIKit = require(script.Parent.UIKit)
local Format = require(script.Parent.Format)
local Net = require(script.Parent.Net)
local Layout = require(script.Parent.Layout)

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local SideMenuConfig = require(Shared.Config.SideMenuConfig)
local IA = require(Shared.Config.InventoryAssetConfig)
local RainbowGradient = require(script.Parent.RainbowGradient)

local Hud = {}

-- Full Backup of all original Side Rail Buttons (preserved for future reference):
--[[
local ALL_SIDE_ITEMS_BACKUP = {
	{ id = "locations", title = "Teleport", icon = "🧭", glowColor = Color3.fromRGB(0, 230, 77), border1 = Color3.fromRGB(102, 255, 140), border2 = Color3.fromRGB(0, 153, 51), rainbow = true },
	{ id = "shop", title = "Store", icon = "🛒", glowColor = Color3.fromRGB(255, 0, 127), border1 = Color3.fromRGB(255, 0, 127), border2 = Color3.fromRGB(127, 0, 255), rainbow = true },
	{ id = "pets", title = "Pets", icon = "⭐", glowColor = Color3.fromRGB(255, 170, 0), border1 = Color3.fromRGB(255, 238, 85), border2 = Color3.fromRGB(255, 170, 0), rainbow = false },
	{ id = "weapons", title = "Weapons", icon = "⚔️", glowColor = Color3.fromRGB(0, 191, 255), border1 = Color3.fromRGB(112, 226, 255), border2 = Color3.fromRGB(0, 136, 255), rainbow = false },
	{ id = "quests", title = "Quests", icon = "📜", glowColor = Color3.fromRGB(255, 85, 0), border1 = Color3.fromRGB(255, 153, 51), border2 = Color3.fromRGB(230, 57, 0), alert = true, rainbow = false },
	{ id = "cases", title = "Summon", icon = "💎", glowColor = Color3.fromRGB(170, 0, 255), border1 = Color3.fromRGB(224, 102, 255), border2 = Color3.fromRGB(136, 0, 204), rainbow = false },
	{ id = "character", title = "Skill Tree", icon = "🌳", glowColor = Color3.fromRGB(0, 229, 204), border1 = Color3.fromRGB(102, 255, 240), border2 = Color3.fromRGB(0, 153, 136), rainbow = false },
}
--]]

-- Currently active top-left buttons (Teleport, Skill Tree, Daily)
local SIDE_ITEMS = {
	{ id = "locations", title = "Teleport", icon = "🧭", glowColor = Color3.fromRGB(0, 230, 77), border1 = Color3.fromRGB(102, 255, 140), border2 = Color3.fromRGB(0, 153, 51), rainbow = true },
	{ id = "character", title = "Skill Tree", icon = "🌳", glowColor = Color3.fromRGB(0, 229, 204), border1 = Color3.fromRGB(102, 255, 240), border2 = Color3.fromRGB(0, 153, 136), rainbow = false },
	{ id = "daily", title = "Daily", icon = "🔥", glowColor = Color3.fromRGB(255, 140, 60), border1 = Color3.fromRGB(255, 200, 80), border2 = Color3.fromRGB(255, 80, 80), rainbow = true },
}

local LOC = {
	[1] = "Dark Forest",
	[2] = "Pirate Shore",
	[3] = "Shinobi Lands",
	[4] = "Polar Tundra",
}

-- Boost row style (top-left). Data from profile.boosts when present.
local BOOST_META = {
	{ key = "money", icon = "🪙", color = Color3.fromRGB(200, 130, 40), name = "Coins" },
	{ key = "power", icon = "💪", color = Color3.fromRGB(200, 55, 70), name = "Power" },
	{ key = "damage", icon = "⚡", color = Color3.fromRGB(120, 60, 200), name = "Damage" },
	{ key = "luck", icon = "🍀", color = Color3.fromRGB(50, 160, 70), name = "Luck" },
}

function Hud.Mount(
	gui: ScreenGui,
	store: any,
	openModal: (string, any?) -> (),
	onManualClick: (() -> ())?,
	onOpenTree: (() -> ())?
)
	local root = Instance.new("Folder")
	root.Name = "HUD"
	root.Parent = gui
	-- Rebirth moved off the HUD (another menu opens it); Q still works via App binds.
	local _ = openModal

	---------------------------------------------------------------- SIDE RAIL MENU (Modern Glowing Pills)
	local rail = Instance.new("Frame")
	rail.Name = "SideMenuContainer"
	rail.Size = UDim2.fromOffset(165, 100)
	rail.Position = UDim2.fromOffset(14, 14)
	rail.BackgroundTransparency = 1
	rail.ZIndex = 10
	rail.Parent = root

	local railList = Instance.new("UIListLayout")
	railList.Padding = UDim.new(0, 8)
	railList.SortOrder = Enum.SortOrder.LayoutOrder
	railList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	railList.VerticalAlignment = Enum.VerticalAlignment.Top
	railList.Parent = rail

	local railBtns: { [string]: Frame } = {}

	for i, item in ipairs(SIDE_ITEMS) do
		-- Outer pill container frame
		local pill = Instance.new("Frame")
		pill.Name = item.id .. "Button"
		pill.Size = UDim2.fromOffset(155, 42)
		pill.LayoutOrder = i
		pill.BackgroundColor3 = Color3.fromRGB(14, 24, 18)
		pill.BackgroundTransparency = 0.15
		pill.ZIndex = 12
		pill.Parent = rail

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(0, 14)
		pillCorner.Parent = pill

		-- Dark gradient fill inside pill
		local pillGrad = Instance.new("UIGradient")
		pillGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, item.glowColor:Lerp(Color3.fromRGB(10, 15, 20), 0.75)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 12, 16)),
		})
		pillGrad.Rotation = 90
		pillGrad.Parent = pill

		-- Outer Glow Shadow Frame
		local glow = Instance.new("Frame")
		glow.Name = "NeonGlow"
		glow.Size = UDim2.new(1, 6, 1, 6)
		glow.Position = UDim2.fromScale(0.5, 0.5)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundColor3 = item.glowColor
		glow.BackgroundTransparency = 0.65
		glow.ZIndex = 11
		glow.Parent = pill

		local glowCorner = Instance.new("UICorner")
		glowCorner.CornerRadius = UDim.new(0, 16)
		glowCorner.Parent = glow

		-- Border UIStroke with Neon Gradient
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.2
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = item.border1
		stroke.Parent = pill

		local strokeGrad = Instance.new("UIGradient")
		strokeGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, item.border1),
			ColorSequenceKeypoint.new(0.5, item.glowColor),
			ColorSequenceKeypoint.new(1, item.border2),
		})
		strokeGrad.Parent = stroke

		-- Left Icon Circle
		local iconBg = Instance.new("Frame")
		iconBg.Size = UDim2.fromOffset(28, 28)
		iconBg.Position = UDim2.fromOffset(8, 7)
		iconBg.BackgroundColor3 = item.glowColor
		iconBg.BackgroundTransparency = 0.75
		iconBg.ZIndex = 13
		iconBg.Parent = pill

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(1, 0)
		iconCorner.Parent = iconBg

		local iconLbl = Instance.new("TextLabel")
		iconLbl.Size = UDim2.fromScale(1, 1)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text = item.icon
		iconLbl.TextSize = 16
		iconLbl.ZIndex = 14
		iconLbl.Parent = iconBg

		-- Right Title Label
		local titleLbl = Instance.new("TextLabel")
		titleLbl.Size = UDim2.new(1, -48, 1, 0)
		titleLbl.Position = UDim2.fromOffset(42, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Text = item.title
		titleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.TextSize = 15
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.ZIndex = 13
		titleLbl.Parent = pill

		-- Invisible Click Button overlay
		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.fromScale(1, 1)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.ZIndex = 20
		clickBtn.Parent = pill

		-- Click Handler
		clickBtn.MouseButton1Click:Connect(function()
			if item.id == "character" then
				store:OpenPanel("character")
			elseif item.id == "settings" then
				openModal("settings", nil)
			elseif item.id == "weapons" or item.id == "pets" then
				local s = store :: any
				s._invTab = item.id
				store:OpenPanel("weapons")
			elseif item.id == "daily" then
				local SharedRemotes = ReplicatedStorage:FindFirstChild("Remotes")
				if SharedRemotes then
					local ev = SharedRemotes:FindFirstChild("ClaimDaily")
					if ev and ev:IsA("RemoteEvent") then
						ev:FireServer()
					end
				end
			else
				store:OpenPanel(item.id)
			end
		end)

		-- Apply Shimmer Animation if enabled
		if item.rainbow then
			if item.id == "daily" then
				RainbowGradient.ApplyShimmer(pill, "fire", 0.5, 120)
			else
				RainbowGradient.ApplyShimmer(pill, "emerald", 0.5, 120)
			end
		end

		railBtns[item.id] = pill
	end
	-- Inventory shell tabs (INVETAR): open weapons panel with tab
	-- "character" / UP = dedicated Character Upgrade window (not inventory profile)
	local INV_TABS = {
		weapons = true,
		pets = true,
		auras = true,
		relics = true,
		cases = true,
		shop = true,
	}

	-- Legacy UIKit rail stub (preserves old code paths; real rail uses SIDE_ITEMS above)
	local RAIL: { any } = {}
	local railPad = Instance.new("UIPadding")
	railPad.Parent = rail

	local railBtns: { [string]: TextButton } = {}
	for i, item in ipairs(RAIL) do
		local b = UIKit.IconBtn({
			Name = item.id,
			Parent = rail,
			Glyph = item.glyph,
			Order = i,
			OnClick = function()
				if item.id == "character" then
					-- Debug / primary: Character Upgrade panel (Figma track start)
					store:OpenPanel("character")
				elseif INV_TABS[item.id] then
					local s = store :: any
					s._invTab = item.id
					store:OpenPanel("weapons")
				else
					store:OpenPanel(item.id)
				end
			end,
		})
		railBtns[item.id] = b
	end

	---------------------------------------------------------------- EMERALD RAINBOW TELEPORT BUTTON GLOW
	local tpBtn = railBtns.locations
	if tpBtn then
		tpBtn.Name = "TeleportSideButton"

		-- Outer neon glow backdrop
		local glow = Instance.new("Frame")
		glow.Name = "EmeraldGlow"
		glow.Size = UDim2.new(1, 8, 1, 8)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundColor3 = Color3.fromRGB(0, 230, 77)
		glow.BackgroundTransparency = 0.55
		glow.ZIndex = math.max(1, tpBtn.ZIndex - 1)
		glow.Parent = tpBtn
		UIKit.Corner(glow, T.R.sm)

		-- Animated gradient stroke border
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2.5
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Color3.fromRGB(102, 255, 140)
		stroke.Parent = tpBtn

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(102, 255, 140)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 230, 77)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 153, 51)),
		})
		grad.Parent = stroke

		local RainbowGradient = require(script.Parent.RainbowGradient)
		RainbowGradient.ApplyShimmer(tpBtn, "emerald", 0.5, 180)
	end

	local questBadge = Instance.new("TextLabel")
	questBadge.Name = "QuestBadge"
	questBadge.Size = UDim2.fromOffset(18, 18)
	questBadge.Position = UDim2.new(1, -2, 0, -2)
	questBadge.AnchorPoint = Vector2.new(1, 0)
	questBadge.BackgroundColor3 = T.Danger
	questBadge.BackgroundTransparency = 0
	questBadge.Text = ""
	questBadge.TextColor3 = T.Text
	questBadge.TextSize = 11
	questBadge.Font = Enum.Font.GothamBold
	questBadge.TextXAlignment = Enum.TextXAlignment.Center
	questBadge.ZIndex = 20
	questBadge.Visible = false
	local qCorner = Instance.new("UICorner")
	qCorner.CornerRadius = UDim.new(1, 0)
	qCorner.Parent = questBadge
	questBadge.Parent = rail

	---------------------------------------------------------------- BOTTOM-LEFT BOOSTS & ANOMALY PILL
	local boosts = Instance.new("Frame")
	boosts.Name = "Boosts"
	boosts.BackgroundTransparency = 1
	boosts.Size = UDim2.fromOffset(180, 140)
	boosts.Position = UDim2.new(0, 16, 1, -75)
	boosts.AnchorPoint = Vector2.new(0, 1)
	boosts.ZIndex = 11
	boosts.Parent = root
	local boostList = Instance.new("UIListLayout")
	boostList.Padding = UDim.new(0, 6)
	boostList.SortOrder = Enum.SortOrder.LayoutOrder
	boostList.VerticalAlignment = Enum.VerticalAlignment.Bottom
	boostList.Parent = boosts
	local boostRows: { [string]: Frame } = {}

	local function makeBoostRow(meta: any): Frame
		local row = Instance.new("Frame")
		row.Name = meta.key
		row.BackgroundColor3 = Color3.fromRGB(14, 24, 18)
		row.BackgroundTransparency = 0.15
		row.BorderSizePixel = 0
		row.Size = UDim2.fromOffset(210, 32)
		row.ZIndex = 12
		row.Visible = false
		row.Parent = boosts

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 10)
		rowCorner.Parent = row

		local rowStroke = Instance.new("UIStroke")
		rowStroke.Thickness = 1.8
		rowStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		rowStroke.Color = meta.color
		rowStroke.Parent = row

		local iconLab = Instance.new("TextLabel")
		iconLab.Name = "Icon"
		iconLab.Size = UDim2.fromOffset(26, 32)
		iconLab.Position = UDim2.fromOffset(6, 0)
		iconLab.BackgroundTransparency = 1
		iconLab.Text = meta.icon
		iconLab.TextSize = 16
		iconLab.ZIndex = 13
		iconLab.Parent = row

		local infoLab = Instance.new("TextLabel")
		infoLab.Name = "Info"
		infoLab.Size = UDim2.new(1, -36, 1, 0)
		infoLab.Position = UDim2.fromOffset(32, 0)
		infoLab.BackgroundTransparency = 1
		infoLab.Text = ""
		infoLab.Font = T.Font.Title
		infoLab.TextSize = 12
		infoLab.TextColor3 = Color3.fromRGB(240, 240, 250)
		infoLab.TextXAlignment = Enum.TextXAlignment.Left
		infoLab.ZIndex = 13
		infoLab.Parent = row

		return row
	end

	for _, meta in ipairs(BOOST_META) do
		boostRows[meta.key] = makeBoostRow(meta)
	end

	-- Active anomaly banner (glowing bottom-left pill matching top-left style)
	local anomBanner = Instance.new("Frame")
	anomBanner.Name = "AnomalyBanner"
	anomBanner.BackgroundColor3 = Color3.fromRGB(20, 12, 32)
	anomBanner.BackgroundTransparency = 0.15
	anomBanner.BorderSizePixel = 0
	anomBanner.Size = UDim2.fromOffset(210, 44)
	anomBanner.Position = UDim2.new(0, 16, 1, -20)
	anomBanner.AnchorPoint = Vector2.new(0, 1)
	anomBanner.ZIndex = 15
	anomBanner.Visible = false
	anomBanner.Parent = root

	local anomCorner = Instance.new("UICorner")
	anomCorner.CornerRadius = UDim.new(0, 14)
	anomCorner.Parent = anomBanner

	local anomGlow = Instance.new("Frame")
	anomGlow.Name = "NeonGlow"
	anomGlow.Size = UDim2.new(1, 6, 1, 6)
	anomGlow.Position = UDim2.fromScale(0.5, 0.5)
	anomGlow.AnchorPoint = Vector2.new(0.5, 0.5)
	anomGlow.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	anomGlow.BackgroundTransparency = 0.6
	anomGlow.ZIndex = 14
	anomGlow.Parent = anomBanner
	local anomGlowCorner = Instance.new("UICorner")
	anomGlowCorner.CornerRadius = UDim.new(0, 16)
	anomGlowCorner.Parent = anomGlow

	local anomStroke = Instance.new("UIStroke")
	anomStroke.Thickness = 2.2
	anomStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	anomStroke.Color = Color3.fromRGB(255, 180, 40)
	anomStroke.Parent = anomBanner

	local anomStrokeGrad = Instance.new("UIGradient")
	anomStrokeGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 0)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 0)),
	})
	anomStrokeGrad.Parent = anomStroke

	local anomIcon = Instance.new("TextLabel")
	anomIcon.Size = UDim2.fromOffset(30, 30)
	anomIcon.Position = UDim2.fromOffset(8, 7)
	anomIcon.BackgroundTransparency = 1
	anomIcon.Text = "⚡"
	anomIcon.TextSize = 20
	anomIcon.ZIndex = 16
	anomIcon.Parent = anomBanner

	local anomTxt = Instance.new("TextLabel")
	anomTxt.Name = "Text"
	anomTxt.Size = UDim2.new(1, -44, 1, 0)
	anomTxt.Position = UDim2.fromOffset(40, 0)
	anomTxt.BackgroundTransparency = 1
	anomTxt.Text = ""
	anomTxt.TextColor3 = Color3.fromRGB(255, 240, 190)
	anomTxt.Font = Enum.Font.FredokaOne
	anomTxt.TextSize = 13
	anomTxt.TextXAlignment = Enum.TextXAlignment.Left
	anomTxt.ZIndex = 16
	anomTxt.Parent = anomBanner

	RainbowGradient.ApplyShimmer(anomBanner, "fire", 0.5, 140)

	---------------------------------------------------------------- BOTTOM-CENTER: MechyForge HUD block
	-- Layout traced 1:1 from the MechyForge brief on a 1920x1080 canvas.
	-- Block box = the two art buttons: x 503..1392, y 851..1080 (flush with the
	-- screen bottom). The AUTO plate sits above y=851, i.e. at a negative scale
	-- offset inside this frame — intentional, the frame does not clip.
	local BLOCK_W, BLOCK_H = 889, 229
	local function relPos(x: number, y: number): UDim2
		return UDim2.fromScale((x - 503) / BLOCK_W, (y - 851) / BLOCK_H)
	end
	local function relSize(w: number, h: number): UDim2
		return UDim2.fromScale(w / BLOCK_W, h / BLOCK_H)
	end

	local HOVER_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local PRESS_INFO = TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Soft hover for the two art buttons. Scale only — never UIStroke thickness (MASTER_PLAN §10.12).
	local function bindBtnHover(btn: ImageButton, peak: number?)
		local p, s = btn.Position, btn.Size
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.Position = UDim2.fromScale(p.X.Scale + s.X.Scale * 0.5, p.Y.Scale + s.Y.Scale * 0.5)
		local sc = UIKit.Scale(btn, 1)
		local top = peak or 1.07
		btn.MouseEnter:Connect(function()
			TweenService:Create(sc, HOVER_INFO, { Scale = top }):Play()
		end)
		btn.MouseLeave:Connect(function()
			TweenService:Create(sc, HOVER_INFO, { Scale = 1 }):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(sc, PRESS_INFO, { Scale = top * 0.93 }):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(sc, HOVER_INFO, { Scale = top }):Play()
		end)
	end

	local bal = Instance.new("Frame")
	bal.Name = "BalanceBar"
	bal.BackgroundTransparency = 1
	bal.BorderSizePixel = 0
	bal.Size = UDim2.fromOffset(BLOCK_W, BLOCK_H)
	bal.Position = UDim2.new(0.5, 0, 1, -8)
	bal.AnchorPoint = Vector2.new(0.5, 1)
	-- Above dungeon banners / floating HUD junk so the backpack stays clickable
	bal.ZIndex = 40
	bal.Visible = true
	bal.Parent = root
	local balScale = UIKit.Scale(bal, 1)

	--- Counter plate: art card + icon on the left + candy number to its right.
	local function valuePlate(name: string, plateY: number, iconKey: string, iconY: number, gradient: string): TextLabel
		local plate = Instance.new("ImageLabel")
		plate.Name = name .. "Plate"
		plate.BackgroundTransparency = 1
		plate.BorderSizePixel = 0
		plate.Image = IA.Get("MAINVALUEcard")
		plate.ScaleType = Enum.ScaleType.Stretch
		plate.Position = relPos(686, plateY)
		plate.Size = relSize(520, 110)
		plate.ZIndex = 41
		plate.Parent = bal

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel = 0
		icon.Image = IA.Get(iconKey)
		icon.ScaleType = Enum.ScaleType.Fit
		-- icon coords are canvas-absolute; re-base them onto the plate box
		icon.Position = UDim2.fromScale((730 - 686) / 520, (iconY - plateY) / 110)
		icon.Size = UDim2.fromScale(75 / 520, 75 / 110)
		icon.ZIndex = 43
		icon.Parent = plate

		local lab = Instance.new("TextLabel")
		lab.Name = "Value"
		lab.BackgroundTransparency = 1
		lab.Position = UDim2.fromScale(0.245, 0.18)
		lab.Size = UDim2.fromScale(0.72, 0.62)
		lab.Text = "0"
		lab.TextXAlignment = Enum.TextXAlignment.Left
		lab.TextYAlignment = Enum.TextYAlignment.Center
		lab.ZIndex = 43
		lab.Parent = plate
		UIKit.StyleText(lab, gradient, 3)
		UIKit.TextConstraint(lab, 14, 46)
		return lab
	end

	local powerLab = valuePlate("Power", 851, "KATANAicon", 864, "red")
	local coinLab = valuePlate("Coins", 962, "COINicon_1coin", 981, "gold")

	local upgradeBtn = Instance.new("ImageButton")
	upgradeBtn.Name = "UpgradeTreeBtn"
	upgradeBtn.BackgroundTransparency = 1
	upgradeBtn.BorderSizePixel = 0
	upgradeBtn.Image = IA.Get("UPRGADEicon")
	-- Fit, not Slice: the brief's SliceCenter insets (101+101) are wider than the
	-- 190px render box, which makes Roblox mangle/drop the art. Icons are not 9-slice.
	upgradeBtn.ScaleType = Enum.ScaleType.Fit
	upgradeBtn.AutoButtonColor = false
	upgradeBtn.Position = relPos(503, 853)
	upgradeBtn.Size = relSize(190, 220)
	upgradeBtn.ZIndex = 42
	upgradeBtn.Parent = bal
	bindBtnHover(upgradeBtn)
	upgradeBtn.MouseButton1Click:Connect(function()
		if onOpenTree then
			onOpenTree()
		else
			store:OpenPanel("character")
		end
	end)

	local eBtn = Instance.new("ImageButton")
	eBtn.Name = "InvE"
	eBtn.BackgroundTransparency = 1
	eBtn.BorderSizePixel = 0
	eBtn.Image = IA.Get("BACKpackICON")
	eBtn.ScaleType = Enum.ScaleType.Fit -- see UpgradeTreeBtn: Slice insets exceed the render box
	eBtn.AutoButtonColor = false
	eBtn.Position = relPos(1202, 860)
	eBtn.Size = relSize(190, 220)
	eBtn.ZIndex = 42
	eBtn.Parent = bal
	bindBtnHover(eBtn)
	eBtn.MouseButton1Click:Connect(function()
		local s = store :: any
		s._invTab = "weapons"
		store:OpenPanel("weapons")
	end)

	-- AUTO toggle: one plate whose art swaps between the green (ON) and red (OFF) uploads.
	local autoChip = Instance.new("ImageButton")
	autoChip.Name = "AutoChip"
	autoChip.BackgroundTransparency = 1
	autoChip.BorderSizePixel = 0
	autoChip.Image = IA.Get("BTN_Red_1")
	autoChip.ScaleType = Enum.ScaleType.Stretch
	autoChip.AutoButtonColor = false
	autoChip.Position = relPos(800, 758)
	autoChip.Size = relSize(270, 90)
	autoChip.ZIndex = 42
	autoChip.Parent = bal
	bindBtnHover(autoChip, 1.05)
	autoChip.MouseButton1Click:Connect(function()
		Net.ToggleAuto()
	end)

	local autoIcon = Instance.new("ImageLabel")
	autoIcon.Name = "Icon"
	autoIcon.BackgroundTransparency = 1
	autoIcon.BorderSizePixel = 0
	autoIcon.Image = IA.Get("AUTOCLICKERicon_1")
	autoIcon.ScaleType = Enum.ScaleType.Fit
	autoIcon.Position = UDim2.fromScale((815 - 800) / 270, (771 - 758) / 90)
	autoIcon.Size = UDim2.fromScale(58 / 270, 62 / 90)
	autoIcon.ZIndex = 44
	autoIcon.Parent = autoChip

	local autoStateLab = Instance.new("TextLabel")
	autoStateLab.Name = "State"
	autoStateLab.BackgroundTransparency = 1
	autoStateLab.Position = UDim2.fromScale(0.31, 0.12)
	autoStateLab.Size = UDim2.fromScale(0.63, 0.44)
	autoStateLab.Text = "AUTO OFF"
	autoStateLab.TextXAlignment = Enum.TextXAlignment.Left
	autoStateLab.ZIndex = 44
	autoStateLab.Parent = autoChip
	UIKit.StyleText(autoStateLab, "gray", 2.5)
	UIKit.TextConstraint(autoStateLab, 10, 26)

	local autoCpsLab = Instance.new("TextLabel")
	autoCpsLab.Name = "Cps"
	autoCpsLab.BackgroundTransparency = 1
	autoCpsLab.Position = UDim2.fromScale(0.31, 0.56)
	autoCpsLab.Size = UDim2.fromScale(0.63, 0.32)
	autoCpsLab.Text = "0 CPS"
	autoCpsLab.TextXAlignment = Enum.TextXAlignment.Left
	autoCpsLab.ZIndex = 44
	autoCpsLab.Parent = autoChip
	UIKit.StyleText(autoCpsLab, "gray", 2)
	UIKit.TextConstraint(autoCpsLab, 9, 18)

	-- Rebirth progress: not in the brief, kept as a thin rail above the AUTO plate (Q still rebirths).
	local RB_H = 10
	local rbHost = Instance.new("Frame")
	rbHost.Name = "RebirthProg"
	rbHost.BackgroundTransparency = 1
	rbHost.Size = relSize(270, RB_H)
	rbHost.Position = relPos(800, 758 - RB_H - 8)
	rbHost.ZIndex = 41
	rbHost.Parent = bal
	local _rbTrack, rbFill = UIKit.Bar(rbHost, 0, T.Accent, RB_H)

	local clickAnchor = Instance.new("Frame")
	clickAnchor.Name = "ClickAnchor"
	clickAnchor.BackgroundTransparency = 1
	clickAnchor.Size = UDim2.fromOffset(1, 1)
	clickAnchor.Position = UDim2.new(0.5, 0, 0.55, 0)
	clickAnchor.AnchorPoint = Vector2.new(0.5, 0.5)
	clickAnchor.ZIndex = 1
	clickAnchor.Parent = root
	local _ = onManualClick

	local function applyMetrics(m: Layout.Metrics)
		rail.Size = UDim2.fromOffset(m.railW, m.railH)
		rail.Position = UDim2.fromOffset(m.pad, m.pad)
		railPad.PaddingTop = UDim.new(0, m.railPad)
		railPad.PaddingBottom = UDim.new(0, m.railPad)
		railPad.PaddingLeft = UDim.new(0, m.railPad)
		railPad.PaddingRight = UDim.new(0, m.railPad)
		railList.Padding = UDim.new(0, m.railGap)

		for _, b in railBtns do
			if b:IsA("TextButton") then
				b.Size = UDim2.fromOffset(m.railBtn, m.railBtn)
				b.TextSize = math.clamp(math.floor(m.railBtn * 0.34), 12, 18)
				b.TextColor3 = T.Text
			end
		end

		local invOpen = store:PeekPanel() == "weapons"
		bal.Visible = not invOpen
		bal.Position = UDim2.new(0.5, 0, 1, -math.floor(m.pad * 0.6))
		bal.AnchorPoint = Vector2.new(0.5, 1)
		bal.ZIndex = 40
		eBtn.Active = not invOpen

		-- The whole block is one art composition: shrink it as a unit on narrow
		-- viewports instead of re-flowing the plates.
		local avail = (m.vpX / m.uiScale) - m.railW - m.pad * 3
		balScale.Scale = math.clamp(avail / BLOCK_W, 0.62, 1)

		if rail and rail:IsA("GuiObject") then
			rail.Visible = not invOpen
		end
	end

	pcall(function()
		Layout.Bind(applyMetrics, nRail)
	end)

	local api: any = {}

	function api.Refresh()
		local st = store:PeekStats()
		local profile = store:PeekProfile()
		if not st then
			return
		end

		-- Candy plates own their color (StyleText gradient) — only the text changes here.
		coinLab.Text = Format.Num(st.coins)
		powerLab.Text = Format.Num(st.damagePerClick or st.totalPower)

		-- rebirth progress (damage toward next R)
		local pct = st.rebirthProgress
		if type(pct) ~= "number" then
			local cost = st.nextRebirthCost or 1
			local dmg = st.lifetimeDamage or 0
			pct = cost > 0 and math.clamp(dmg / cost, 0, 1) or 1
		end
		rbFill.Size = UDim2.new(math.clamp(pct :: number, 0, 1), 0, 1, 0)

		-- Live CPS, same source the Profile tab uses (Formulas.Snapshot -> stats.cps).
		-- st.maxCps is only the cap; showing it here made the readout look stale.
		local liveCps = st.cps or 0
		autoCpsLab.Text = string.format("%.1f CPS", liveCps)
		if st.autoClicker then
			autoChip.Image = IA.Get("BTN_Green_4")
			autoStateLab.Text = "AUTO ON"
		else
			autoChip.Image = IA.Get("BTN_Red_1")
			autoStateLab.Text = "AUTO OFF"
		end

		-- boosts: profile.boosts (local potions later) + global anomaly hud
		local boostsData = (profile and profile.boosts) or {}
		local anom = Formulas.GetActiveAnomaly()
		local anomHud = (anom and anom.hud) or {}
		for _, meta in ipairs(BOOST_META) do
			local row = boostRows[meta.key]
			local b = boostsData[meta.key]
			local localPct = if type(b) == "table" and type(b.pct) == "number" then b.pct else 0
			local globalPct = anomHud[meta.key] or 0
			local totalPct = localPct + globalPct
			if totalPct ~= 0 then
				row.Visible = true
				local infoLab = row:FindFirstChild("Info")
				if infoLab and infoLab:IsA("TextLabel") then
					local sign = if totalPct >= 0 then "+" else ""
					local pctStr = string.format("%s%d%%", sign, math.floor(totalPct * 100 + (if totalPct >= 0 then 0.5 else -0.5)))
					local scopeStr = "Global"
					if globalPct ~= 0 and localPct ~= 0 then
						scopeStr = "Both"
					elseif globalPct ~= 0 then
						scopeStr = "Global"
					else
						local sc = tostring((type(b) == "table" and b.scope) or "local")
						scopeStr = (sc == "global" or sc == "Global") and "Global" or "Local"
					end
					infoLab.Text = string.format("%s %s (%s)", pctStr, meta.name, scopeStr)
				end
			else
				row.Visible = false
			end
		end

		if anom then
			local left = math.max(0, anom.endsAt - os.time())
			local m = math.floor(left / 60)
			local s = left % 60
			anomBanner.Visible = true
			local txtLab = anomBanner:FindFirstChild("Text")
			if txtLab and txtLab:IsA("TextLabel") then
				txtLab.Text = string.format("%s  %d:%02d", anom.name, m, s)
			end
		else
			anomBanner.Visible = false
		end

		local ready = 0
		if profile and profile.quests then
			for _, q in pairs(profile.quests) do
				if q.completed and not q.claimed then
					ready += 1
				end
			end
		end
		questBadge.Visible = ready > 0
		if ready > 0 then
			questBadge.Text = tostring(ready)
		end

		local panel = store:PeekPanel()
		-- Inventory open: hide left rail + bottom HUD so Figma inventory owns the screen
		local invOpen = panel == "weapons"
		if rail and rail:IsA("GuiObject") then
			rail.Visible = not invOpen
		end
		if bal and bal:IsA("GuiObject") then
			bal.Visible = not invOpen
		end
		if boosts and boosts:IsA("GuiObject") then
			boosts.Visible = not invOpen
		end
		if anomBanner and anomBanner:IsA("GuiObject") and invOpen then
			anomBanner.Visible = false
		end

		if not invOpen then
			for id, b in railBtns do
				if b:IsA("TextButton") then
					local active = id == panel
					local g = b:FindFirstChildOfClass("UIGradient")
					if g then
						if active then
							g.Color = ColorSequence.new(T.Accent, T.AccentDeep)
						else
							g.Color = ColorSequence.new(T.Surface3, T.Surface2)
						end
					end
					b.TextColor3 = T.Text
				end
			end
		end

		-- keep LOC for future top bar if needed
		local _loc = LOC[st.location or 1]
		local _ = _loc
	end

	function api.GetClickButton(): GuiObject
		return clickAnchor
	end

	return api
end

return Hud
