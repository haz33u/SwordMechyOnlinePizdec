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

--[[
	Audio routing.

	SoundService has no MusicVolume / SoundGroups properties — the earlier
	implementation wrote both inside a pcall, so every audio toggle silently did
	nothing. Instead we own one real SoundGroup per audio key; callers tag their
	Sound with Settings.GetSoundGroup(category) and muting the group mutes them.
]]
local SFX_GROUPS: { [SettingKey]: SoundGroup } = {}
local AUDIO_KEYS: { SettingKey } = { "sfxUi", "sfxCombat", "sfxWorld", "musicAmbient", "musicDungeon" }
local MUSIC_VOLUME = 0.7

local function ensureGroup(key: SettingKey): SoundGroup
	local existing = SFX_GROUPS[key]
	if existing and existing.Parent then
		return existing
	end
	local name = "SM_" .. key
	local found = SoundService:FindFirstChild(name)
	local group: SoundGroup
	if found and found:IsA("SoundGroup") then
		group = found
	else
		group = Instance.new("SoundGroup")
		group.Name = name
		group.Parent = SoundService
	end
	SFX_GROUPS[key] = group
	return group
end

local function categoryKey(category: string): SettingKey
	if category == "ui" then
		return "sfxUi"
	elseif category == "combat" then
		return "sfxCombat"
	elseif category == "musicAmbient" then
		return "musicAmbient"
	elseif category == "musicDungeon" then
		return "musicDungeon"
	end
	return "sfxWorld"
end

--- Assign this to Sound.SoundGroup so the matching toggle can mute it.
function Settings.GetSoundGroup(category: string): SoundGroup
	return ensureGroup(categoryKey(category))
end

function Settings.ApplyAudio()
	for _, key in ipairs(AUDIO_KEYS) do
		local group = ensureGroup(key)
		local isMusic = key == "musicAmbient" or key == "musicDungeon"
		local on = Settings.Get(key)
		group.Volume = if on then (if isMusic then MUSIC_VOLUME else 1) else 0
	end
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
Settings.ApplyAudio()

return Settings
