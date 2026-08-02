--!strict
--[[
	Server-wide anomaly scheduler + global events.
	Writes ReplicatedStorage.WorldState attributes for client HUD + Formulas.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AnomalyConfig = require(Shared.Config.AnomalyConfig)
local GameConfig = require(Shared.Config.GameConfig)
local Remotes = require(Shared.Remotes)

local AnomalyService = {}
AnomalyService._activeId = nil :: string?
AnomalyService._endsAt = 0
AnomalyService._thread = nil :: thread?
AnomalyService._history = {} :: { { id: string, name: string, started: number, ended: number } }

local function worldFolder(): Folder
	local f = ReplicatedStorage:FindFirstChild(AnomalyConfig.WORLD_FOLDER)
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	local n = Instance.new("Folder")
	n.Name = AnomalyConfig.WORLD_FOLDER
	n.Parent = ReplicatedStorage
	return n
end

local function clearAttrs()
	local f = worldFolder()
	f:SetAttribute(AnomalyConfig.ATTR_ID, "")
	f:SetAttribute(AnomalyConfig.ATTR_NAME, "")
	f:SetAttribute(AnomalyConfig.ATTR_ENDS, 0)
	f:SetAttribute(AnomalyConfig.ATTR_STARTS, 0)
	f:SetAttribute("AnomalyType", "")
	f:SetAttribute("AnomalyNextAt", 0)
end

local function writeAttrs(def: any, startsAt: number, endsAt: number, nextAt: number, typeLabel: string)
	local f = worldFolder()
	f:SetAttribute(AnomalyConfig.ATTR_ID, def.id)
	f:SetAttribute(AnomalyConfig.ATTR_NAME, def.name)
	f:SetAttribute(AnomalyConfig.ATTR_STARTS, startsAt)
	f:SetAttribute(AnomalyConfig.ATTR_ENDS, endsAt)
	f:SetAttribute("AnomalyType", typeLabel)
	f:SetAttribute("AnomalyNextAt", nextAt)
end

local function announce(text: string, color: string?)
	for _, p in Players:GetPlayers() do
		Remotes.Event("Notify"):FireClient(p, { text = text, color = color or "gold" })
	end
end

function AnomalyService.GetActiveId(): string?
	if AnomalyService._activeId and os.time() < AnomalyService._endsAt then
		return AnomalyService._activeId
	end
	return nil
end

function AnomalyService.GetActiveDef(): any?
	local id = AnomalyService.GetActiveId()
	if not id then
		return nil
	end
	return AnomalyConfig.Get(id)
end

function AnomalyService.GetHistory(): { { id: string, name: string, started: number, ended: number } }
	return table.clone(AnomalyService._history)
end

function AnomalyService.End(silent: boolean?)
	if AnomalyService._activeId and not silent then
		local def = AnomalyConfig.Get(AnomalyService._activeId)
		announce(
			string.format("Anomaly ended: %s", def and def.name or AnomalyService._activeId),
			"yellow"
		)
	end
	if AnomalyService._activeId then
		table.insert(AnomalyService._history, 1, {
			id = AnomalyService._activeId,
			name = (AnomalyConfig.Get(AnomalyService._activeId) or {}).name or AnomalyService._activeId,
			started = worldFolder():GetAttribute(AnomalyConfig.ATTR_STARTS) or 0,
			ended = os.time(),
		})
		if #AnomalyService._history > 20 then
			table.remove(AnomalyService._history)
		end
	end
	AnomalyService._activeId = nil
	AnomalyService._endsAt = 0
	clearAttrs()
end

function AnomalyService.Start(def: any, durationOverride: number?, typeLabel: string?): boolean
	if type(def) ~= "table" or type(def.id) ~= "string" then
		return false
	end
	local dur = durationOverride
		or def.durationSeconds
		or AnomalyConfig.DEFAULT_DURATION
	local now = os.time()
	local interval = if GameConfig.DEBUG then AnomalyConfig.DEBUG_INTERVAL_SECONDS else AnomalyConfig.INTERVAL_SECONDS
	local nextAt = now + math.max(30, interval)
	AnomalyService._activeId = def.id
	AnomalyService._endsAt = now + math.max(15, math.floor(dur))
	writeAttrs(def, now, AnomalyService._endsAt, nextAt, typeLabel or "")
	announce(
		string.format("ANOMALY: %s — %s (%dm)", def.name, def.blurb or "", math.floor(dur / 60 + 0.5)),
		def.color or "gold"
	)
	print(string.format("[Anomaly] START %s until %d", def.id, AnomalyService._endsAt))
	return true
end

function AnomalyService.Force(id: string?, durationSeconds: number?): boolean
	AnomalyService.End(true)
	local def = if id and id ~= "" then AnomalyConfig.Get(id) else AnomalyConfig.Roll()
	if not def then
		return false
	end
	local dur = durationSeconds
		or (if GameConfig.DEBUG then AnomalyConfig.DEBUG_DURATION else AnomalyConfig.DEFAULT_DURATION)
	return AnomalyService.Start(def, dur)
end

function AnomalyService.Init()
	clearAttrs()

	AnomalyService._thread = task.spawn(function()
		local first = true
		while true do
			local interval = AnomalyConfig.INTERVAL_SECONDS
			local duration = AnomalyConfig.DEFAULT_DURATION
			if GameConfig.DEBUG == true then
				interval = AnomalyConfig.DEBUG_INTERVAL_SECONDS
				duration = AnomalyConfig.DEBUG_DURATION
			end

			if first then
				first = false
				local delaySec = if GameConfig.DEBUG then AnomalyConfig.DEBUG_FIRST_DELAY else 90
				task.wait(delaySec)
			else
				local quiet = math.max(30, interval - duration)
				task.wait(quiet)
			end

			local roll = math.random()
			if roll <= AnomalyConfig.EVENT_CHANCE then
				local def = AnomalyConfig.RollEvent()
				AnomalyService.Start(def, def.durationSeconds, "event")
			else
				local def = AnomalyConfig.Roll()
				AnomalyService.Start(def, duration, "anomaly")
			end

			while AnomalyService._activeId and os.time() < AnomalyService._endsAt do
				task.wait(1)
			end
			if AnomalyService._activeId then
				AnomalyService.End(false)
			end
		end
	end)
end

return AnomalyService
