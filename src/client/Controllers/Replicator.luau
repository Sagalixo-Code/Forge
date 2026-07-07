--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = ReplicatedStorage:WaitForChild("Networking"):WaitForChild("Replicator") :: RemoteEvent

local signal = require(ReplicatedStorage.Packages.signal)
local PathUtil = require(ReplicatedStorage.Shared.Utils.PathUtil)
local logger = require(ReplicatedStorage.Shared.Utils.Logger)

local clientReplicatorLogger = logger.new("ClientReplicator")
clientReplicatorLogger:SetLevel(logger.Levels.DEBUG)

local ReplicatorModule = {}

ReplicatorModule.Data = {}
ReplicatorModule.Observers = {}

local function PathKey(Path: { string }): string
	return table.concat(Path, ".")
end

function ReplicatorModule:Init()
	Replicator.OnClientEvent:Connect(function(Packet)
		if Packet.Type == "Sync" then
			self:ClientSync(Packet)
		elseif Packet.Type == "Patch" then
			self:ClientPatch(Packet)
		end
	end)
end

function ReplicatorModule:PlayerRemoving()
	self:Destroy()
end

function ReplicatorModule:Get(Path: { string })
	return PathUtil.Get(self.Data, Path)
end

function ReplicatorModule:Observe<T>(Path: { string }, Callback: (T?, string?) -> ())
	local key = PathKey(Path)

	if not self.Observers[key] then
		self.Observers[key] = {
			signal = signal.new(),
			connections = {},
			nextId = 0,
		}
	end

	local obj = self.Observers[key]

	local id = obj.nextId + 1
	obj.nextId = id

	local conn = obj.signal:Connect(function(action)
		Callback(self:Get(Path), action)
	end)

	obj.connections[id] = conn

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

				self.Observers[key] = nil
			end
		end,
	}
end

function ReplicatorModule:ClientSync(Packet)
	self.Data = Packet.Data

	for _, obj in pairs(self.Observers) do
		obj.signal:Fire("Set")
	end
end

function ReplicatorModule:ClientPatch(Packet)
	clientReplicatorLogger:Debug("Packet Received Is: ", Packet)

	if Packet.Data.Action == "Set" then
		PathUtil.Set(self.Data, Packet.Path, Packet.Data.Value)
	elseif Packet.Data.Action == "Remove" then
		PathUtil.Remove(self.Data, Packet.Path)
	end

	local key = PathKey(Packet.Path)
	local obj = self.Observers[key]

	if obj then
		obj.signal:Fire(Packet.Data.Action)
	end
end

function ReplicatorModule:Destroy()
	for _, obj in pairs(self.Observers) do
		for _, connection in pairs(obj.connections) do
			connection:Disconnect()
		end

		if obj.signal and typeof(obj.signal.Destroy) == "function" then
			obj.signal:Destroy()
		end
	end

	table.clear(self.Observers)
	table.clear(self.Data)
end

return ReplicatorModule
