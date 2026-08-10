--!strict
--[[
	Server-side sanity checks.

	- Swing rate hard cap (kick if sustained over maxCPS + buffer)
	- Teleport / speed hack detection
	- Distance validation on hits
	- Auto-clicker purchase validation
]]

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Formulas = require(Shared.Formulas)
local Remotes = require(Shared.Remotes)

local ProfileService = require(script.Parent.ProfileService)

local AntiCheatService = {}

local SWING_HISTORY_SECONDS = 3
local CPS_BUFFER = 2
local MAX_TELEPORT_STUDS_PER_SECOND = 120
local MAX_WALKSPEED_MULT = 1.5

local _swings = {} :: { [number]: { number } }
local _lastPositions = {} :: { [number]: Vector3 }

local function recordSwing(userId: number)
	local list = _swings[userId]
	if not list then
		list = {}
		_swings[userId] = list
	end
	local now = os.clock()
	table.insert(list, now)
	-- prune old
	local cutoff = now - SWING_HISTORY_SECONDS
	while #list > 0 and list[1] < cutoff do
		table.remove(list, 1)
	end
end

function AntiCheatService.RecordSwing(player: Player)
	recordSwing(player.UserId)
end

function AntiCheatService.ValidateSwingRate(player: Player): boolean
	local profile = ProfileService.Get(player)
	if not profile then
		return false
	end
	local maxCps = Formulas.GetMaxCPS(profile)
	local list = _swings[player.UserId]
	if not list or #list < 4 then
		return true
	end
	local recent = 0
	local now = os.clock()
	local window = 1
	for _, t in list do
		if now - t <= window then
			recent += 1
		end
	end
	if recent > maxCps + CPS_BUFFER then
		warn(string.format("[AntiCheat] %s exceeded CPS cap: %d/%d", player.Name, recent, maxCps))
		return false
	end
	return true
end

--- Melee reach check. `isAuto` swings come from the auto-clicker, which fires
--- while the player walks, so they get a slightly longer leash than manual hits.
function AntiCheatService.ValidateHitDistance(player: Player, mobPos: Vector3, isAuto: boolean?): boolean
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return false
	end
	local maxRange = if isAuto then 18 else 14
	maxRange += 2.5 -- epsilon for replication lag
	return (mobPos - hrp.Position).Magnitude <= maxRange
end

function AntiCheatService.ValidateAutoClickerPermission(player: Player, profile: any): boolean
	if not profile then
		return false
	end
	return Formulas.IsAutoClickerUnlocked(profile)
end

function AntiCheatService.SanitizeString(val: any, maxLen: number?): string?
	if type(val) ~= "string" then
		return nil
	end
	local limit = maxLen or 128
	if #val > limit then
		return string.sub(val, 1, limit)
	end
	return val
end

function AntiCheatService.CheckMovement(player: Player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local profile = ProfileService.Get(player)
	if not profile then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local maxSpeed = Formulas.GetWalkSpeed(profile) * MAX_WALKSPEED_MULT
		if hum.WalkSpeed > maxSpeed then
			warn(string.format("[AntiCheat] %s WalkSpeed too high: %.1f/%.1f", player.Name, hum.WalkSpeed, maxSpeed))
			hum.WalkSpeed = Formulas.GetWalkSpeed(profile)
		end
	end

	local now = os.clock()
	local last = _lastPositions[player.UserId]
	if last then
		local delta = (hrp.Position - last).Magnitude
		-- Approximate: the heartbeat is ~1s, so dt is hardcoded. Threshold is
		-- deliberately lenient — this only warns, it never acts on the player.
		local dt = 1
		local maxDist = MAX_TELEPORT_STUDS_PER_SECOND * dt
		if delta > maxDist then
			warn(string.format("[AntiCheat] %s teleported %.1f studs", player.Name, delta))
		end
	end
	_lastPositions[player.UserId] = hrp.Position
end

function AntiCheatService.Kick(player: Player, reason: string)
	warn(string.format("[AntiCheat] Kicking %s: %s", player.Name, reason))
	pcall(function()
		player:Kick("Anti-cheat: " .. reason)
	end)
end

function AntiCheatService.Init()
	-- heartbeat: movement checks
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				AntiCheatService.CheckMovement(player)
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		_swings[player.UserId] = nil
		_lastPositions[player.UserId] = nil
	end)

	print("[AntiCheatService] active")
end

return AntiCheatService