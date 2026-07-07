--!strict
--!optimize 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CmdrUtils = ServerScriptService.Server:WaitForChild("CmdrUtils")

local CmdrServer = {}

function CmdrServer:Init()
	task.wait(1)

	local Cmdr = require(ReplicatedStorage.Packages.cmdr)

	Cmdr:RegisterDefaultCommands()

	Cmdr:RegisterHooksIn(CmdrUtils.Hooks)
	Cmdr:RegisterTypesIn(CmdrUtils.Types)
	Cmdr:RegisterCommandsIn(CmdrUtils.Commands)
end

return CmdrServer
