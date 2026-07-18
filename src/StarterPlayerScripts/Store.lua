--!strict
--[[ Reactive client store (Fusion Values + peek). ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local Fusion = require(Packages.Fusion)

export type PanelId =
	"character"
	| "weapons"
	| "pets"
	| "auras"
	| "cases"
	| "relics"
	| "quests"
	| "locations"
	| "dungeons"
	| "none"

local Store = {}

function Store.Create(scope: any)
	local profile = scope:Value(nil :: any)
	local stats = scope:Value(nil :: any)
	local panel = scope:Value("none" :: any)
	local modal = scope:Value(nil :: any)

	local self = {
		profile = profile,
		stats = stats,
		panel = panel,
		modal = modal,
	}

	function self:PeekProfile(): any
		return Fusion.peek(profile)
	end

	function self:PeekStats(): any
		return Fusion.peek(stats)
	end

	function self:PeekPanel(): any
		return Fusion.peek(panel)
	end

	function self:PeekModal(): any
		return Fusion.peek(modal)
	end

	function self:SetData(p: any, s: any)
		profile:set(p)
		stats:set(s)
	end

	function self:OpenPanel(id: PanelId)
		if Fusion.peek(panel) == id then
			panel:set("none")
		else
			panel:set(id)
		end
	end

	function self:ClosePanel()
		panel:set("none")
	end

	function self:OpenModal(kind: string, payload: any?)
		modal:set({ kind = kind, payload = payload })
	end

	function self:CloseModal()
		modal:set(nil)
	end

	return self
end

return Store
