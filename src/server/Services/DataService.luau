--!strict
--!optimize 2

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local registry = require(ReplicatedStorage.Shared.CoreFlex.Registry)
local signal = require(ReplicatedStorage.Packages.signal)
local Logger = require(ReplicatedStorage.Shared.Utils.Logger)
local PathUtil = require(ReplicatedStorage.Shared.Utils.PathUtil)
local ProfileTypes = require(ReplicatedStorage.Shared.Utils.Types.Profile)

local Observers: {
	[Player]: {
		[string]: {
			signal: any,
			connections: { [number]: any },
			nextId: number,
		},
	},
} =
	{}

local DataService = {}
DataService.ProfileManager = nil :: ProfileTypes.ProfileManager<any>?

local DataServiceLogger = Logger.new("DataService")
DataServiceLogger:SetLevel(Logger.Levels.DEBUG)

local function PathKey(path: { string })
	return table.concat(path, ".")
end

local function EnsurePlayer(player: Player)
	if not Observers[player] then
		Observers[player] = {}
	end
end

function DataService:Init(Components)
	if not Components.ProfileManager then
		DataServiceLogger:Error(`ProfileManager not found.`)
		return
	end
	self.ProfileManager = Components.ProfileManager
end

function DataService:PlayerAdded(Player: Player)
	self.ProfileManager:Load(Player)
	EnsurePlayer(Player)
end

function DataService:PlayerRemoving(Player: Player)
	self.ProfileManager:Release(Player)

	local playerObservers = Observers[Player]
	if playerObservers then
		for _, obj in pairs(playerObservers) do
			for _, conn in pairs(obj.connections) do
				conn:Disconnect()
			end
			if obj.signal and typeof(obj.signal.Destroy) == "function" then
				obj.signal:Destroy()
			end
		end
	end

	Observers[Player] = nil
end

function DataService:GetProfile(Player: Player)
	return self.ProfileManager:Get(Player)
end

function DataService:Get<T>(Player: Player, Path: { string }): T?
	local data = self:GetProfile(Player).Data

	if not PathUtil.Exists(data, Path) then
		return
	end

	return PathUtil.Get(data, Path)
end

function DataService:Set(Player: Player, Path: { string }, Value: string | number)
	local data = self:GetProfile(Player).Data

	if not PathUtil.Exists(data, Path) then
		return
	end

	local lastValue = self:Get(Player, Path)
	PathUtil.Set(data, Path, Value)

	if lastValue ~= self:Get(Player, Path) then
		self:Fire(Player, Path, {
			Action = "Set",
			Value = Value,
		})
	end
end

function DataService:Remove(Player: Player, Path: { string })
	local data = self:GetProfile(Player).Data

	if not PathUtil.Exists(data, Path) then
		return
	end

	local lastValue = self:Get(Player, Path)
	PathUtil.Remove(data, Path)

	if lastValue ~= self:Get(Player, Path) then
		self:Fire(Player, Path, {
			Action = "Remove",
		})
	end
end

function DataService:Observe<T...>(Player: Player, Path: { string }, Callback: ({ string }) -> T...)
	EnsurePlayer(Player)

	local key = PathKey(Path)
	local playerObservers = Observers[Player]

	if not playerObservers[key] then
		playerObservers[key] = {
			signal = signal.new(),
			connections = {},
			nextId = 0,
		}
	end

	local obj = playerObservers[key]

	local id = obj.nextId + 1
	obj.nextId = id

	local conn = obj.signal:Connect(function()
		Callback(self:Get(Player, Path))
	end)

	obj.connections[id] = conn

	local initialValue: { string } = self:Get(Player, Path)
	Callback(initialValue)

	return {
		Disconnect = function()
			local connection = obj.connections[id]
			if connection then
				connection:Disconnect()
				obj.connections[id] = nil
			end

			if next(obj.connections) == nil then
				if obj.signal and typeof(obj.signal.Destroy) == "function" then
					obj.signal:Destroy()
				end
				playerObservers[key] = nil
			end
		end,
	}
end

function DataService:Fire<T>(Player: Player, Path: { string }, ...: { [string]: T })
	local playerObservers = Observers[Player]
	if not playerObservers then
		return
	end

	local replicateService = registry:GetService("ReplicateService") :: any
	local key = PathKey(Path)
	local obj = playerObservers[key]

	replicateService:Patch(Player, Path, ...)

	if obj then
		obj.signal:Fire()
	end
end

return DataService
