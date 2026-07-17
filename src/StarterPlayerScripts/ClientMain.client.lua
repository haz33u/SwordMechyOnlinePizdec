--!strict
--[[
	Client bootstrap: HUD + auto-swing + simple input
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local GameConfig = require(Shared.Config.GameConfig)

local profile: any = nil
local stats: any = nil
local mobs: { any } = {}
local lastSwing = 0

local function formatNum(n: number): string
	n = math.floor(n + 0.5)
	if n >= 1e12 then
		return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3 then
		return string.format("%.1fK", n / 1e3)
	end
	return tostring(n)
end

-- ensure remotes exist (server creates; wait)
local function ev(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name) :: RemoteEvent
end
local function fn(name: string): RemoteFunction
	local folder = ReplicatedStorage:WaitForChild("Remotes")
	return folder:WaitForChild(name) :: RemoteFunction
end

----------------------------------------------------------------
-- HUD
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SwordMastersHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function panel(name: string, pos: UDim2, size: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0
	f.Position = pos
	f.Size = size
	f.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = f
	return f
end

local top = panel("Top", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.50, 0.18))
local statsLabel = Instance.new("TextLabel")
statsLabel.BackgroundTransparency = 1
statsLabel.Size = UDim2.fromScale(1, 1)
statsLabel.Font = Enum.Font.GothamBold
statsLabel.TextSize = 15
statsLabel.TextColor3 = Color3.new(1, 1, 1)
statsLabel.TextXAlignment = Enum.TextXAlignment.Left
statsLabel.TextYAlignment = Enum.TextYAlignment.Top
statsLabel.Text = "Loading..."
statsLabel.Parent = top
local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 8)
pad.Parent = statsLabel

-- Big CLICK button (core UX)
local clickBtn = Instance.new("TextButton")
clickBtn.Name = "BigClick"
clickBtn.Size = UDim2.fromScale(0.18, 0.12)
clickBtn.Position = UDim2.fromScale(0.41, 0.82)
clickBtn.BackgroundColor3 = Color3.fromRGB(220, 80, 60)
clickBtn.TextColor3 = Color3.new(1, 1, 1)
clickBtn.Font = Enum.Font.GothamBlack
clickBtn.TextSize = 28
clickBtn.Text = "КЛИК"
clickBtn.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 16)
	c.Parent = clickBtn
end
clickBtn.MouseButton1Click:Connect(function()
	ev("Swing"):FireServer(nil, "manual")
end)

local notifyLabel = Instance.new("TextLabel")
notifyLabel.BackgroundTransparency = 1
notifyLabel.Position = UDim2.fromScale(0.25, 0.18)
notifyLabel.Size = UDim2.fromScale(0.5, 0.06)
notifyLabel.Font = Enum.Font.GothamBold
notifyLabel.TextSize = 20
notifyLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
notifyLabel.Text = ""
notifyLabel.Parent = gui

local buttons = panel("Buttons", UDim2.fromScale(0.02, 0.18), UDim2.fromScale(0.22, 0.55))
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.Parent = buttons
local bpad = Instance.new("UIPadding")
bpad.PaddingTop = UDim.new(0, 8)
bpad.PaddingLeft = UDim.new(0, 8)
bpad.PaddingRight = UDim.new(0, 8)
bpad.Parent = buttons

local function mkButton(text: string, order: number, cb: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, -4, 0, 36)
	b.BackgroundColor3 = Color3.fromRGB(45, 90, 200)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Text = text
	b.LayoutOrder = order
	b.Parent = buttons
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	b.MouseButton1Click:Connect(cb)
	return b
end

local function notify(text: string, color: string?)
	notifyLabel.Text = text
	if color == "red" then
		notifyLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	elseif color == "green" then
		notifyLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
	elseif color == "purple" then
		notifyLabel.TextColor3 = Color3.fromRGB(200, 140, 255)
	elseif color == "gold" then
		notifyLabel.TextColor3 = Color3.fromRGB(255, 210, 80)
	elseif color == "cyan" then
		notifyLabel.TextColor3 = Color3.fromRGB(120, 230, 255)
	elseif color == "pink" then
		notifyLabel.TextColor3 = Color3.fromRGB(255, 140, 200)
	else
		notifyLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
	end
	task.delay(2.5, function()
		if notifyLabel.Text == text then
			notifyLabel.Text = ""
		end
	end)
end

local autoBtn: TextButton? = nil

local function refreshStats()
	if not stats or not profile then
		return
	end
	local nextCost = stats.nextRebirthCost or 0
	local dmg = stats.lifetimeDamage or 0
	local pct = nextCost > 0 and math.clamp(dmg / nextCost * 100, 0, 100) or 0
	local autoStr = (stats.autoClicker and "ВКЛ" or "ВЫКЛ")
	statsLabel.Text = string.format(
		"%s v%s\nСила/клик: %s | CPS: %.1f | DPS: %s\nКлики: %s | Монеты: %s | Авто: %s\nRebirth %d (x%.2f) | %.0f%% до след.\nКрит: %.0f%% | Атк.скорость: %+.0f%% | Лок %d | Петы %d/%d\nУрон ∑: %s / %s",
		GameConfig.DISPLAY_NAME,
		GameConfig.VERSION,
		formatNum(stats.damagePerClick or stats.totalPower),
		stats.cps or 0,
		formatNum(stats.dps or 0),
		formatNum(stats.totalClicks or 0),
		formatNum(stats.coins),
		autoStr,
		stats.rebirthLevel or 0,
		stats.rebirthMult or 1,
		pct,
		(stats.crit or 0) * 100,
		stats.attackSpeedPct or 0,
		stats.location or 1,
		#(profile.petTeam or {}),
		profile.petSlots or 1,
		formatNum(dmg),
		formatNum(nextCost)
	)
	if autoBtn then
		autoBtn.Text = stats.autoClicker and "🤖 Авто: ВКЛ" or "🤖 Авто: ВЫКЛ"
		autoBtn.BackgroundColor3 = stats.autoClicker and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(90, 50, 50)
	end
end

----------------------------------------------------------------
-- Buttons
----------------------------------------------------------------
mkButton("⚔ Клик (ручной)", 1, function()
	ev("Swing"):FireServer(nil, "manual")
end)

autoBtn = mkButton("🤖 Автокликер", 2, function()
	ev("ToggleAutoClicker"):FireServer()
end)

mkButton("♻ Перерождение", 3, function()
	ev("RequestRebirth"):FireServer()
end)

mkButton("⬆ Сила (ап)", 4, function()
	ev("BuyUpgrade"):FireServer("Power")
end)

mkButton("💨 Скорость бега", 5, function()
	ev("BuyUpgrade"):FireServer("RunSpeed")
end)

mkButton("🎒 Рюкзак", 6, function()
	ev("BuyUpgrade"):FireServer("Backpack")
end)

mkButton("⚡ Скорость удара = CPS", 7, function()
	ev("BuyUpgrade"):FireServer("ClickSpeed")
end)

mkButton("✨ Зачаровать main", 8, function()
	if profile and profile.equippedMain then
		ev("EnchantWeapon"):FireServer(profile.equippedMain)
	end
end)

mkButton("🐾 Кейс питомца", 9, function()
	ev("OpenPetCase"):FireServer()
end)

mkButton("🌀 Кейс ауры", 10, function()
	ev("OpenAuraCase"):FireServer()
end)

mkButton("🏛 Лёгкий данж", 11, function()
	ev("StartDungeon"):FireServer("easy")
end)

mkButton("🏛 Средний данж", 12, function()
	ev("StartDungeon"):FireServer("medium")
end)

mkButton("🗺 Loc1 Лес", 13, function()
	ev("SetLocation"):FireServer(1)
end)
mkButton("🗺 Loc2 Пираты", 14, function()
	ev("SetLocation"):FireServer(2)
end)
mkButton("🗺 Loc3 Шиноби", 15, function()
	ev("SetLocation"):FireServer(3)
end)
mkButton("🗺 Loc4 Тундра", 16, function()
	ev("SetLocation"):FireServer(4)
end)
mkButton("🗺 След. локация", 17, function()
	if profile then
		local n = math.min(4, (profile.currentLocation or 1) + 1)
		ev("SetLocation"):FireServer(n)
	end
end)

mkButton("✅ Сдать квесты", 18, function()
	if not profile then
		return
	end
	for id, q in profile.quests do
		if q.completed and not q.claimed then
			ev("ClaimQuest"):FireServer(id)
		end
	end
end)

----------------------------------------------------------------
-- Network
----------------------------------------------------------------
ev("ProfileUpdate").OnClientEvent:Connect(function(payload)
	profile = payload.profile
	stats = payload.stats
	refreshStats()
end)

ev("Notify").OnClientEvent:Connect(function(payload)
	notify(payload.text or "", payload.color)
end)

ev("CombatFx").OnClientEvent:Connect(function(payload)
	if payload.type == "hit" then
		-- lightweight feedback
		if payload.crit then
			notify("CRIT " .. tostring(payload.damage), "gold")
		end
	end
end)

-- initial pull
task.spawn(function()
	task.wait(1)
	local data = fn("GetProfile"):InvokeServer()
	if data then
		profile = data.profile
		stats = data.stats
		mobs = data.mobs or {}
		refreshStats()
	end
end)

----------------------------------------------------------------
-- AUTOCLICKER loop (core farm)
-- Client requests at CPS; server enforces real rate limit.
----------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if not profile or not stats then
		return
	end
	if not profile.autoClicker or not stats.autoClickerUnlocked then
		return
	end
	local cd = stats.swingCd or (1 / math.max(stats.cps or 2, 1))
	local now = os.clock()
	if now - lastSwing >= cd then
		lastSwing = now
		ev("Swing"):FireServer(nil, "auto")
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	-- Space / E = manual click (LMB reserved for camera when not on GUI)
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
		ev("Swing"):FireServer(nil, "manual")
	elseif input.KeyCode == Enum.KeyCode.R then
		ev("RequestRebirth"):FireServer()
	elseif input.KeyCode == Enum.KeyCode.T then
		ev("ToggleAutoClicker"):FireServer()
	end
end)

print("[SwordMasters] client ready — clicks + autoclicker CORE")
