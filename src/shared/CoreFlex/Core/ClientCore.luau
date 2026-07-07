--!strict
--!optimize 2

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Utils = ReplicatedStorage.Shared.Utils

local tableManager = require(Utils.Table)

local Registry = require(script.Parent.Parent.Registry)
local Runtime = require(script.Parent.Parent.RunTime)

local CallbacksInfo = {
	"PreInit",
	"Init",
	"Start",
	"PlayerAdded",
	"PlayerRemoving",
	"CharacterAdded",
	"CharacterRemoving",
}

local logger = require(ReplicatedStorage.Shared.Utils.Logger)

local logs = logger.new("CLIENT CORE - CoreFlex")
logs:SetLevel(logger.Levels.DEBUG)

type ServiceModule<T> = {
	Init: (self: any, ...T) -> T,
}

type ServerCore = {
	[any]: (self: ServerCore, Services: { any }, Storage: { [any]: any }) -> (),

	__cache: {
		Sucess: { string },
		Error: { string },
	},
}

local Callbacks = {
	PreInit = {} :: { (...any) -> () },
	Init = {} :: { (...any) -> () },
	Start = {} :: { (...any) -> () },

	PlayerAdded = {} :: { (...any) -> () },
	PlayerRemoving = {} :: { (...any) -> () },

	CharacterAdded = {} :: { (...any) -> () },
	CharacterRemoving = {} :: { (...any) -> () },
}

local ServerCore = {}
ServerCore.__index = ServerCore

ServerCore.__cache = {
	Sucess = {},
	Error = {},
}

function ServerCore:Init(Controller: any, Storage: { [any]: any })
	Runtime:SetState("Booting")

	for _, sv: ModuleScript in Controller:GetChildren() do
		logs:Debug(string.format("%s is loading", sv.Name))

		local Success, Module = pcall(function()
			return require(sv)
		end)

		if not Success then
			table.insert(self.__cache.Error, sv.Name)

			logs:Warn(string.format("Failed to load controller: %s - Current Error: %s", sv.Name, tostring(Module)))

			continue
		end

		table.insert(self.__cache.Sucess, sv.Name)

		if not Registry:HasService(sv.Name) then
			Registry:RegisterController(sv)
		end

		for _, CallbackName in ipairs(CallbacksInfo) do
			local Callback = Module[CallbackName]

			if Callback then
				table.insert(Callbacks[CallbackName], {
					Module = Module,
					Callback = Callback,
				})
			end
		end

		logs:Info(string.format("Successfully loaded Controller: %s", sv.Name))
	end

	task.spawn(function()
		Runtime:SetState("PreInit")

		tableManager.forEach(Callbacks.PreInit, function(Data)
			Data.Callback(Data.Module, Storage)
		end)

		Runtime:SetState("Init")

		tableManager.forEach(Callbacks.Init, function(Data)
			Data.Callback(Data.Module, Storage)
		end)

		Runtime:SetState("Start")

		tableManager.forEach(Callbacks.Start, function(Data)
			Data.Callback(Data.Module, Storage)
		end)

		Runtime:SetState("Running")

		Players.PlayerAdded:Connect(function(Player)
			tableManager.forEach(Callbacks.PlayerAdded, function(Data)
				Data.Callback(Data.Module, Player, Storage)
			end)

			Player.CharacterAdded:Connect(function(Character)
				tableManager.forEach(Callbacks.CharacterAdded, function(Data)
					Data.Callback(Data.Module, Player, Character, Storage)
				end)
			end)

			Player.CharacterRemoving:Connect(function(Character)
				tableManager.forEach(Callbacks.CharacterRemoving, function(Data)
					Data.Callback(Data.Module, Player, Character, Storage)
				end)
			end)
		end)

		Players.PlayerRemoving:Connect(function(Player)
			tableManager.forEach(Callbacks.PlayerRemoving, function(Data)
				Data.Callback(Data.Module, Player, Storage)
			end)
		end)

		for _, Player in Players:GetPlayers() do
			tableManager.forEach(Callbacks.PlayerAdded, function(Data)
				Data.Callback(Data.Module, Player, Storage)
			end)

			if Player.Character then
				tableManager.forEach(Callbacks.CharacterAdded, function(Data)
					Data.Callback(Data.Module, Player, Player.Character, Storage)
				end)
			end
		end
	end)

	task.spawn(function()
		logs:Info(string.format("Runtime State: %s", Runtime:GetState()))

		if #self.__cache.Error ~= 0 then
			logs:Info(string.format("Registered Controllers: %d", #self.__cache.Sucess))
			logs:Info(string.format("Failed Controllers: %d", #self.__cache.Error))
		end

		logs:Info(string.format("Uptime: %.3f", Runtime:GetUptime()))
	end)
end

return setmetatable(ServerCore, ServerCore)
