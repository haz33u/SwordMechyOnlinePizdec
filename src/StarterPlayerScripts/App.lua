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
local CaseOpening = require(script.Parent.CaseOpening)
local Toast = require(script.Parent.Toast)
local FloatingDamage = require(script.Parent.FloatingDamage)
local ClickPop = require(script.Parent.ClickPop)
local WeaponVisual = require(script.Parent.WeaponVisual)
local PetVisual = require(script.Parent.PetVisual)
local AuraVisual = require(script.Parent.AuraVisual)
local PlayerNameplate = require(script.Parent.PlayerNameplate)
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
			petSlots = 3,
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

	local toastApi, windowsApi, modalsApi, hudApi, caseApi, talentTreeApi
	local nameplateApi: any = nil
	local clickPop: any = nil
	local onCombatFx: any = nil

	local function openModal(kind: string, payload: any?)
		if kind == "case" or kind == "caseOpen" then
			if caseApi then
				local ok, reason, cost = caseApi.Begin(payload)
				if ok == false and toastApi then
					if reason == "need_keys" then
						toastApi.Show("Need " .. tostring(cost) .. " key(s)", "red")
					elseif reason == "need_coins" then
						toastApi.Show("Need " .. tostring(cost) .. " coins", "red")
					elseif reason == "busy" then
						toastApi.Show("Case already opening…", "yellow")
					end
				end
			end
			return
		end
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
		if nameplateApi then
			nameplateApi.Refresh()
		end
		pcall(function()
			WeaponVisual.Refresh(store:PeekProfile())
		end)
		pcall(function()
			PetVisual.Refresh(store:PeekProfile())
		end)
		pcall(function()
			AuraVisual.Refresh(store:PeekProfile())
		end)
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
			-- optimistic local pop + slash on manual press
			pcall(function()
				WeaponVisual.PlayAttack()
			end)
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
	step("CaseOpening", function()
		caseApi = CaseOpening.Mount(gui, store, toastApi)
	end)
	step("TalentTreeUI", function()
		local TalentTreeUI = require(script.Parent.TalentTreeUI)
		talentTreeApi = TalentTreeUI.Mount(gui, store)
	end)
	step("CombatFx", function()
		onCombatFx = FloatingDamage.Mount()
	end)
	step("WeaponVisual", function()
		WeaponVisual.Init(function()
			return store:PeekProfile()
		end)
	end)
	step("PetVisual", function()
		PetVisual.Init()
	end)
	step("AuraVisual", function()
		AuraVisual.Init()
	end)
	step("DevTools", function()
		local DevTools = require(script.Parent.DevTools)
		DevTools.Mount(gui)
	end)
	step("PlayerNameplate", function()
		nameplateApi = PlayerNameplate.Mount(store)
	end)

	-- Ferryman NPC → open world travel panel
	pcall(function()
		Net.Event("OpenTravel").OnClientEvent:Connect(function()
			store:OpenPanel("locations")
			refreshAll()
		end)
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
			if typeof(payload) ~= "table" then
				return
			end
			store:SetData(payload.profile, payload.stats)
			-- Always update HUD + weapon visual; windows only if panel open
			-- (inventory full rebuild is throttled inside Windows.RefreshAll)
			if hudApi then
				hudApi.Refresh()
			end
			pcall(function()
				WeaponVisual.Refresh(store:PeekProfile())
			end)
			pcall(function()
				PetVisual.Refresh(store:PeekProfile())
			end)
			pcall(function()
				AuraVisual.Refresh(store:PeekProfile())
			end)
			local panel = store:PeekPanel()
			if panel and panel ~= "none" and windowsApi then
				windowsApi.RefreshAll()
			end
			if store:PeekModal() and modalsApi then
				modalsApi.Refresh()
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
			-- sword slash on successful hit (skip if AUTO already drives the same combo loop)
			pcall(function()
				if WeaponVisual.IsAutoAttack and WeaponVisual.IsAutoAttack() then
					return
				end
				WeaponVisual.PlayAttack()
			end)
		end)
	end)

	local lastPanel = "none"
	local lastModal = nil
	RunService.Heartbeat:Connect(function()
		local p = store:PeekPanel()
		if p ~= lastPanel then
			lastPanel = p
			if p == "character" and talentTreeApi then
				talentTreeApi.Show()
				store:ClosePanel()
			end
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

	-- AUTO: damage on swingCd; sword anims loop right→left via WeaponVisual.SetAutoAttack
	local accum = 0
	local lastAutoFlag = false
	RunService.Heartbeat:Connect(function(dt)
		local stats = store:PeekStats()
		local autoOn = stats ~= nil and stats.autoClicker == true
		if autoOn ~= lastAutoFlag then
			lastAutoFlag = autoOn
			pcall(function()
				WeaponVisual.SetAutoAttack(autoOn)
			end)
			if not autoOn then
				accum = 0
			end
		end
		if not autoOn then
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

	-- Attack: LMB / touch anywhere that is NOT already a Gui button (gp=false).
	-- No Space. Windows/modals (gp=true) don't attack.
	local function tryManualSwing()
		if store:PeekModal() then
			return
		end
		if caseApi and caseApi.IsOpen() then
			return
		end
		pcall(function()
			WeaponVisual.PlayAttack()
			Net.Swing("manual")
		end)
		local st = store:PeekStats()
		burstClick(st and (st.damagePerClick or st.totalPower) or 1, false, "manual")
	end

	UserInputService.InputBegan:Connect(function(input, gp)
		local uit = input.UserInputType
		if not gp and (uit == Enum.UserInputType.MouseButton1 or uit == Enum.UserInputType.Touch) then
			tryManualSwing()
			return
		end
		if gp then
			return
		end
		-- Binds: Q=rebirth, E=inventory (no Space attack)
		local invStore = store :: any
		local function openInvTab(tab: string)
			invStore._invTab = tab
			if store:PeekPanel() == "weapons" and windowsApi and windowsApi.ForceRefreshPanel then
				-- already open: switch tab without full HUD bounce / combat rebuild spam
				windowsApi.ForceRefreshPanel()
			else
				store:OpenPanel("weapons")
			end
		end
		if input.KeyCode == Enum.KeyCode.Q then
			openModal("rebirth", nil)
		elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.I then
			openInvTab("weapons")
		elseif input.KeyCode == Enum.KeyCode.T then
			pcall(function()
				Net.ToggleAuto()
			end)
		elseif input.KeyCode == Enum.KeyCode.R then
			openModal("rebirth", nil)
		elseif input.KeyCode == Enum.KeyCode.P then
			openInvTab("pets")
		elseif input.KeyCode == Enum.KeyCode.J then
			store:OpenPanel("quests")
		elseif input.KeyCode == Enum.KeyCode.L then
			store:OpenPanel("locations")
		elseif input.KeyCode == Enum.KeyCode.C then
			openInvTab("cases")
		elseif input.KeyCode == Enum.KeyCode.B then
			openInvTab("shop")
		elseif input.KeyCode == Enum.KeyCode.U or input.KeyCode == Enum.KeyCode.K then
			if talentTreeApi then
				talentTreeApi.Toggle()
			else
				store:OpenPanel("character")
			end
		elseif input.KeyCode == Enum.KeyCode.Escape then
			if caseApi and caseApi.IsOpen() then
				caseApi.Close()
			elseif store:PeekModal() then
				store:CloseModal()
			else
				store:ClosePanel()
			end
			-- only visibility/HUD — not a full inventory rebuild storm
			if hudApi then
				hudApi.Refresh()
			end
			if windowsApi then
				windowsApi.RefreshAll()
			end
		end
	end)

	print("[GameUI] mounted ScreenGui.GameUI | children=", #gui:GetChildren())
end

return App
