--!strict

local Flags = {}

Flags.PreInit = 0x001
Flags.Init = 0x002
Flags.PostInit = 0x004
Flags.PreStart = 0x008
Flags.Start = 0x010
Flags.PostStart = 0x020
Flags.Shutdown = 0x040
Flags.PlayerAdded = 0x080
Flags.PlayerRemoving = 0x100
Flags.CharacterAdded = 0x200
Flags.CharacterRemoving = 0x400

Flags.Stages = {
	"PreInit",
	"Init",
	"PostInit",
	"PreStart",
	"Start",
	"PostStart",
	"Shutdown",
	"PlayerAdded",
	"PlayerRemoving",
	"CharacterAdded",
	"CharacterRemoving",
}

Flags.ByName = {}
for _, name in Flags.Stages do
	Flags.ByName[name] = Flags[name]
end

local allMask = 0
for _, bit in Flags.ByName do
	allMask = bit32.bor(allMask, bit)
end
Flags.All = allMask

function Flags.computeMask(target: { [string]: any }): number
	local mask = 0
	for name, bit in Flags.ByName do
		if typeof(target[name]) == "function" then
			mask = bit32.bor(mask, bit)
		end
	end
	return mask
end

function Flags.has(mask: number, bit: number): boolean
	return bit32.band(mask, bit) ~= 0
end

return Flags
