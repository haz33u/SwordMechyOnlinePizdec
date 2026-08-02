--!strict
--[[
	Client-side settings store. Persisted only in memory for the session
	(no server sync). Other modules read these flags to enable/disable
	visual/audio features.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local Settings = {}

export type SettingKey =
	"visualPets"
	| "visualAuras"
	| "visualWeapons"
	| "vfxCombat"
	| "vfxLoot"
	| "vfxWorld"
	| "sfxUi"
	| "sfxCombat"
	| "sfxWorld"
	| "musicAmbient"
	| "musicDungeon"

local DEFAULTS: { [SettingKey]: boolean } = {
	visualPets = true,
	visualAuras = true,
	visualWeapons = true,
	vfxCombat = true,
	vfxLoot = true,
	vfxWorld = true,
	sfxUi = true,
	sfxCombat = true,
	sfxWorld = true,
	musicAmbient = true,
	musicDungeon = true,
}

local values: { [SettingKey]: boolean } = {}
local listeners: { [SettingKey]: { (boolean) -> () } } = {}

local function getKey(key: string): SettingKey?
	return (DEFAULTS :: any)[key] ~= nil and key :: SettingKey or nil
end

function Settings.Get(key: SettingKey): boolean
	if values[key] == nil then
		values[key] = DEFAULTS[key]
	end
	return values[key] :: boolean
end

function Settings.Set(key: SettingKey, enabled: boolean)
	local old = Settings.Get(key)
	values[key] = enabled
	if old ~= enabled then
		local list = listeners[key]
		if list then
			for _, cb in ipairs(list) do
				pcall(cb, enabled)
			end
		end
	end
	Settings.ApplyAudio()
end

function Settings.Toggle(key: SettingKey): boolean
	local next = not Settings.Get(key)
	Settings.Set(key, next)
	return next
end

function Settings.OnChange(key: SettingKey, callback: (boolean) -> ()): () -> ()
	if not listeners[key] then
		listeners[key] = {}
	end
	table.insert(listeners[key], callback)
	return function()
		local list = listeners[key]
		if list then
			for i, cb in ipairs(list) do
				if cb == callback then
					table.remove(list, i)
					return
				end
			end
		end
	end
end

function Settings.ApplyAudio()
	local music = Settings.Get("musicAmbient") or Settings.Get("musicDungeon")
	local sfx = Settings.Get("sfxUi") or Settings.Get("sfxCombat") or Settings.Get("sfxWorld")
	pcall(function()
		SoundService.MusicVolume = music and 0.7 or 0
		SoundService.SoundGroups.Master.Volume = sfx and 1 or 0
	end)
end

function Settings.CanPlaySound(category: "ui" | "combat" | "world"): boolean
	if category == "ui" then
		return Settings.Get("sfxUi")
	elseif category == "combat" then
		return Settings.Get("sfxCombat")
	else
		return Settings.Get("sfxWorld")
	end
end

function Settings.ShouldShowVisual(category: "pets" | "auras" | "weapons" | "combat" | "loot" | "world"): boolean
	if category == "pets" then
		return Settings.Get("visualPets")
	elseif category == "auras" then
		return Settings.Get("visualAuras")
	elseif category == "weapons" then
		return Settings.Get("visualWeapons")
	elseif category == "combat" then
		return Settings.Get("vfxCombat")
	elseif category == "loot" then
		return Settings.Get("vfxLoot")
	else
		return Settings.Get("vfxWorld")
	end
end

function Settings.ResetAll()
	for key, default in pairs(DEFAULTS) do
		Settings.Set(key :: SettingKey, default)
	end
end

-- Initialize to defaults
for key, default in pairs(DEFAULTS) do
	values[key :: SettingKey] = default
end

return Settings
