--!strict
--[[
	Sword Masters GameUI
	Visual: Mixmaxed polish (Corner/Stroke/Gradient/Pad/Scale) + Cristalix compact HUD
	Stack kept: Fusion packages present; chrome is custom glass UIKit (less "AI kit" look)
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

function App.Start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Kill Edit previews cloned from StarterGui (was causing DOUBLE HUD)
	for _, child in playerGui:GetChildren() do
		if child:IsA("ScreenGui") then
			if child:GetAttribute("IsPreview") == true or child.Name == "GameUI_EditPreview" then
				child:Destroy()
			end
		end
	end
	-- also strip any leftover duplicate GameUI
	local old = playerGui:FindFirstChild("GameUI")
	if old then
		old:Destroy()
	end

	local scope = Fusion.scoped(Fusion)
	local store = Store.Create(scope)

	local gui = Instance.new("ScreenGui")
	gui.Name = "GameUI"
	gui.ResetOnSpawn = false
	-- false = stay clear of Roblox topbar / menu (no overlap with CoreGui)
	gui.IgnoreGuiInset = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 20
	gui.Parent = playerGui

	-- No extra UIScale — it was fighting Layout metrics and clipping the rail

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

	task.spawn(function()
		local ok, data = pcall(function()
			return Net.GetProfile()
		end)
		if ok and data then
			store:SetData(data.profile, data.stats)
			refreshAll()
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

	print("[GameUI] polished HUD ready · accent", T.Accent)
end

return App
