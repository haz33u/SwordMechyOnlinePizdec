--!strict
--[[
	SINGLE source of truth for UI: this repo (Rojo → StarterPlayerScripts).
	Do NOT put GameUI in StarterGui — it stacks with this and doubles the HUD.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

local Store = require(script.Parent.Store)
local Net = require(script.Parent.Net)
local Hud = require(script.Parent.Hud)
local Windows = require(script.Parent.Windows)
local Modals = require(script.Parent.Modals)
local Toast = require(script.Parent.Toast)
local FloatingDamage = require(script.Parent.FloatingDamage)
local T = require(script.Parent.Theme)

local App = {}
local started = false

local function isOurGui(sg: ScreenGui): boolean
	if sg:GetAttribute("IsPreview") == true then
		return true
	end
	local n = sg.Name
	return n == "GameUI"
		or n == "GameUI_EditPreview"
		or n == "SwordMastersHUD"
		or n == "CombatFxGui"
		or string.find(n, "EditPreview", 1, true) ~= nil
		or string.find(n, "GameUI", 1, true) ~= nil
end

local function wipeForeignHud(playerGui: PlayerGui)
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") and isOurGui(child) then
			child:Destroy()
		end
	end
end

local function mockSnapshot()
	return {
		profile = {
			coins = 0,
			totalClicks = 0,
			rebirthLevel = 0,
			rebirthMult = 1,
			autoClicker = false,
			upgradeLevels = {},
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
			totalPower = 1,
			damagePerClick = 1,
			cps = 1,
			dps = 1,
			coins = 0,
			totalClicks = 0,
			crit = 0,
			luck = 0,
			rebirthLevel = 0,
			rebirthMult = 1,
			nextRebirthCost = 1000,
			lifetimeDamage = 0,
			autoClicker = false,
			location = 1,
			swingCd = 1,
		},
	}
end

function App.Start()
	if started then
		warn("[GameUI] App.Start already ran — skip (prevent double mount)")
		return
	end
	started = true

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- ONE UI only: nuke every leftover / StarterGui clone of our HUD
	wipeForeignHud(playerGui)

	local scope = Fusion.scoped(Fusion)
	local store = Store.Create(scope)

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 25
	gui:SetAttribute("SwordMastersUI", true)
	gui.Parent = playerGui

	-- if something re-injects preview mid-session, kill it
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and child ~= gui and isOurGui(child) then
			task.defer(function()
				if child.Parent and child ~= gui then
					child:Destroy()
				end
			end)
		end
	end)

	local toastApi
	local windowsApi
	local modalsApi
	local hudApi

	local function openModal(kind: string, payload: any?)
		store:OpenModal(kind, payload)
		if modalsApi then
			modalsApi.Refresh()
		end
	end

	toastApi = Toast.Mount(gui)
	hudApi = Hud.Mount(gui, store, openModal)
	windowsApi = Windows.Mount(gui, store, openModal)
	modalsApi = Modals.Mount(gui, store)
	local onCombatFx = FloatingDamage.Mount()

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

	-- show mock immediately so layout is visible even before remotes
	do
		local m = mockSnapshot()
		store:SetData(m.profile, m.stats)
		refreshAll()
	end

	task.spawn(function()
		local ok, data = pcall(function()
			return Net.GetProfile()
		end)
		if ok and typeof(data) == "table" and data.stats then
			store:SetData(data.profile, data.stats)
			refreshAll()
		else
			toastApi.Show("Сервер не ответил — mock HUD", "red")
		end
	end)

	Net.Event("ProfileUpdate").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then
			store:SetData(payload.profile, payload.stats)
			refreshAll()
		end
	end)

	Net.Event("Notify").OnClientEvent:Connect(function(payload)
		if typeof(payload) == "table" then
			toastApi.Show(tostring(payload.text or ""), payload.color)
		elseif typeof(payload) == "string" then
			toastApi.Show(payload)
		end
	end)

	Net.Event("CombatFx").OnClientEvent:Connect(function(payload)
		onCombatFx(payload)
	end)

	local lastPanel = "none"
	local lastModal = nil
	RunService.Heartbeat:Connect(function()
		local p = store:PeekPanel()
		if p ~= lastPanel then
			lastPanel = p
			refreshAll()
		end
		local m = store:PeekModal()
		if m ~= lastModal then
			lastModal = m
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
		local cd = stats.swingCd or (1 / math.max(stats.cps or 1, 0.1))
		accum += dt
		if accum >= cd then
			accum = 0
			Net.Swing("auto")
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
			Net.Swing("manual")
		elseif input.KeyCode == Enum.KeyCode.T then
			Net.ToggleAuto()
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

	print("[GameUI] single-source HUD from REPO only (no StarterGui UI)")
end

return App
