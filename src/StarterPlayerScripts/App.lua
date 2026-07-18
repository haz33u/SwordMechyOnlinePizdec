--!strict
--[[
	SINGLE source of truth for UI: this repo (Rojo).
	Do NOT put GameUI in StarterGui.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages", 30)
if not Packages then
	error("[GameUI] ReplicatedStorage.Packages missing — run wally install + rojo")
end

local Fusion = require(Packages:WaitForChild("Fusion"))

local Store = require(script.Parent.Store)
local Net = require(script.Parent.Net)
local Hud = require(script.Parent.Hud)
local Windows = require(script.Parent.Windows)
local Modals = require(script.Parent.Modals)
local Toast = require(script.Parent.Toast)
local FloatingDamage = require(script.Parent.FloatingDamage)
local ClickPop = require(script.Parent.ClickPop)
local T = require(script.Parent.Theme)

local App = {}
local started = false

local function isDuplicateHud(sg: ScreenGui, keep: ScreenGui?): boolean
	if keep and sg == keep then
		return false
	end
	if sg:GetAttribute("IsPreview") == true then
		return true
	end
	local n = sg.Name
	-- only wipe known dupes / previews — NOT CombatFx or random CoreGui clones
	return n == "GameUI_EditPreview"
		or n == "SwordMastersHUD"
		or n == "GameUI" and (not keep or sg ~= keep)
		or string.find(n, "EditPreview", 1, true) ~= nil
end

local function wipeDupes(playerGui: PlayerGui, keep: ScreenGui?)
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and isDuplicateHud(child, keep) then
			child:Destroy()
		end
	end
end

local function mockSnapshot()
	return {
		profile = {
			coins = 100,
			totalClicks = 0,
			rebirthLevel = 0,
			rebirthMult = 1,
			autoClicker = false,
			upgradeLevels = {
				RunSpeed = 0,
				Backpack = 0,
				Power = 0,
				ClickSpeed = 0,
				CritChance = 0,
				Luck = 0,
			},
			weapons = {},
			equippedMain = nil,
			equippedOffhand = nil,
			pets = {},
			petTeam = {},
			petSlots = 1,
			auras = {},
			equippedAura = nil,
			relics = {},
			locationsUnlocked = { 1 },
			currentLocation = 1,
			quests = {},
			dungeonStage = { easy = 0, medium = 0, hard = 0 },
		},
		stats = {
			totalPower = 10,
			damagePerClick = 10,
			cps = 1,
			dps = 10,
			coins = 100,
			totalClicks = 0,
			crit = 0.05,
			luck = 0,
			rebirthLevel = 0,
			rebirthMult = 1,
			nextRebirthCost = 1000,
			nextRebirthCoinCost = 5000,
			rebirthProgress = 0,
			lifetimeDamage = 0,
			autoClicker = false,
			location = 1,
			swingCd = 1,
		},
	}
end

function App.Start()
	if started then
		warn("[GameUI] already started — skip")
		return
	end
	started = true

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	wipeDupes(playerGui, nil)

	local scope = Fusion.scoped(Fusion)
	local store = Store.Create(scope)

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 50
	gui.Enabled = true
	gui:SetAttribute("SwordMastersUI", true)
	gui.Parent = playerGui

	-- Root responsive scale: clamp(viewportY / 1080, 0.7, 2.0)
	local Layout = require(script.Parent.Layout)
	local rootScale = Instance.new("UIScale")
	rootScale.Name = "RootUIScale"
	rootScale.Scale = 1
	rootScale.Parent = gui
	Layout.Bind(function(m)
		rootScale.Scale = m.uiScale
	end)

	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child ~= gui and isDuplicateHud(child, gui) then
			task.defer(function()
				if child.Parent and child ~= gui then
					child:Destroy()
				end
			end)
		end
	end)

	local toastApi, windowsApi, modalsApi, hudApi
	local clickPop: any = nil
	local onCombatFx: any = nil

	local function openModal(kind: string, payload: any?)
		store:OpenModal(kind, payload)
		if modalsApi then
			modalsApi.Refresh()
		end
	end

	local function refreshAll()
		if hudApi then
			hudApi.Refresh()
		end
		if windowsApi then
			windowsApi.RefreshAll()
		end
		if modalsApi then
			modalsApi.Refresh()
		end
	end

	local function burstClick(amount: number?, crit: boolean?, source: string?)
		if clickPop then
			clickPop:Burst(amount, crit, source)
		end
	end

	-- Mount UI (each step pcall so one fail doesn't kill all)
	local function step(name: string, fn: () -> ())
		local ok, err = pcall(fn)
		if not ok then
			warn("[GameUI] step failed:", name, err)
		end
		return ok
	end

	step("Toast", function()
		toastApi = Toast.Mount(gui)
	end)
	step("ClickPop", function()
		clickPop = ClickPop.Mount(gui)
	end)
	step("Hud", function()
		hudApi = Hud.Mount(gui, store, openModal, function()
			-- optimistic local pop on manual press (server will also send CombatFx)
			local st = store:PeekStats()
			burstClick(st and (st.damagePerClick or st.totalPower) or 1, false, "manual")
		end)
		if clickPop and hudApi and hudApi.GetClickButton then
			clickPop:SetAnchor(hudApi.GetClickButton())
		end
	end)
	step("Windows", function()
		windowsApi = Windows.Mount(gui, store, openModal)
	end)
	step("Modals", function()
		modalsApi = Modals.Mount(gui, store)
	end)
	step("CombatFx", function()
		onCombatFx = FloatingDamage.Mount()
	end)

	local m = mockSnapshot()
	store:SetData(m.profile, m.stats)
	refreshAll()

	if toastApi then
		toastApi.Show("HUD online", "green")
	end

	task.spawn(function()
		local ok, data = pcall(function()
			return Net.GetProfile()
		end)
		if ok and typeof(data) == "table" and data.stats then
			store:SetData(data.profile, data.stats)
			refreshAll()
		elseif toastApi then
			toastApi.Show("Mock HUD (no server profile)", "gold")
		end
	end)

	pcall(function()
		Net.Event("ProfileUpdate").OnClientEvent:Connect(function(payload)
			if typeof(payload) == "table" then
				store:SetData(payload.profile, payload.stats)
				refreshAll()
			end
		end)
	end)

	pcall(function()
		Net.Event("Notify").OnClientEvent:Connect(function(payload)
			if not toastApi then
				return
			end
			if typeof(payload) == "table" then
				toastApi.Show(tostring(payload.text or ""), payload.color)
			elseif typeof(payload) == "string" then
				toastApi.Show(payload)
			end
		end)
	end)

	pcall(function()
		Net.Event("CombatFx").OnClientEvent:Connect(function(payload)
			if typeof(payload) ~= "table" then
				return
			end
			local amount = payload.damage or payload.amount or payload.n
			local crit = payload.crit == true
			local source = payload.source
			-- pops from click bar
			burstClick(amount, crit, source)
			-- world-style float (center) kept as secondary
			if onCombatFx then
				onCombatFx(payload)
			end
		end)
	end)

	local lastPanel = "none"
	local lastModal = nil
	RunService.Heartbeat:Connect(function()
		local p = store:PeekPanel()
		if p ~= lastPanel then
			lastPanel = p
			refreshAll()
		end
		local md = store:PeekModal()
		if md ~= lastModal then
			lastModal = md
			if modalsApi then
				modalsApi.Refresh()
			end
		end
	end)

	local accum = 0
	RunService.Heartbeat:Connect(function(dt)
		local stats = store:PeekStats()
		if not stats or not stats.autoClicker then
			return
		end
		local cd = stats.swingCd or 1
		accum += dt
		if accum >= cd then
			accum = 0
			pcall(function()
				Net.Swing("auto")
			end)
			-- local auto pop (server CombatFx may also fire)
			local dmg = stats.damagePerClick or stats.totalPower or 1
			burstClick(dmg, false, "auto")
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
			pcall(function()
				Net.Swing("manual")
			end)
		elseif input.KeyCode == Enum.KeyCode.T then
			pcall(function()
				Net.ToggleAuto()
			end)
		elseif input.KeyCode == Enum.KeyCode.R then
			openModal("rebirth", nil)
		elseif input.KeyCode == Enum.KeyCode.I then
			store:OpenPanel("weapons")
		elseif input.KeyCode == Enum.KeyCode.P then
			store:OpenPanel("pets")
		elseif input.KeyCode == Enum.KeyCode.J then
			store:OpenPanel("quests")
		elseif input.KeyCode == Enum.KeyCode.M then
			store:OpenPanel("locations")
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if store:PeekModal() then
				store:CloseModal()
			else
				store:ClosePanel()
			end
			refreshAll()
		end
	end)

	print("[GameUI] mounted ScreenGui.GameUI | children=", #gui:GetChildren())
end

return App
