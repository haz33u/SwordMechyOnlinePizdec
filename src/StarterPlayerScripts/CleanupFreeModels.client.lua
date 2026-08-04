--!strict
-- Destroy free-model / malicious UI scripts and popups that leak into PlayerGui.
-- Mirrors the server-side cleanup in ServerScriptService/Main.server.lua.

local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local PlayerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local BAD_SCRIPT_NAMES = {
	Constant = true,
	cTextureManager = true,
	CoreTextureSystem = true,
	HttpEnabled = true,
	AntiIpLogger = true,
	IpLogger = true,
	Credits = true,
	Error501 = true,
}

local BAD_GUI_NAMES = {
	Credits = true,
	Error501 = true,
	Error = true,
}

local function isBadScript(inst: Instance): boolean
	return inst:IsA("LuaSourceContainer") and BAD_SCRIPT_NAMES[inst.Name] == true
end

local function isBadGui(inst: Instance): boolean
	return (inst:IsA("ScreenGui") or inst:IsA("BillboardGui") or inst:IsA("SurfaceGui")) and BAD_GUI_NAMES[inst.Name] == true
end

local function kill(inst: Instance)
	if isBadScript(inst) then
		if inst:IsA("BaseScript") then
			(inst :: BaseScript).Disabled = true
		end
		inst:Destroy()
	elseif isBadGui(inst) then
		inst:Destroy()
	end
end

for _, desc in PlayerGui:GetDescendants() do
	kill(desc)
end

PlayerGui.DescendantAdded:Connect(kill)
