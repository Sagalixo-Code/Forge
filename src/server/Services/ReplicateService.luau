const ReplicatedStorage = game:GetService("ReplicatedStorage")
const Networking = ReplicatedStorage:WaitForChild("Networking")
const DataType = require(ReplicatedStorage.Shared.Utils.Types.DataService)

const registry = require(ReplicatedStorage.Shared.CoreFlex.Registry)
const logger = require(ReplicatedStorage.Shared.Utils.Logger)

const replicateLogger = logger.new("Replicate")
replicateLogger:SetLevel(logger.Levels.DEBUG)

const ReplicatorRemote = Networking:WaitForChild("Replicator") :: RemoteEvent

const Replicate = {}
const PacketType = table.freeze({
	Sync = "Sync",
	Patch = "Patch",
})

function Replicate:Patch<T>(Player: Player, Path: { string }, Value: { [string]: T })
	const PacketPayload = table.freeze({
		Path = Path,
		Type = PacketType.Patch,
		Data = Value,
	})
	ReplicatorRemote:FireClient(Player, PacketPayload)
end

function Replicate:Sync<T>(Player: Player, ProfileData: { [string]: T })
	const PacketPayload = table.freeze({
		Data = ProfileData,
		Type = PacketType.Sync,
	})

	ReplicatorRemote:FireClient(Player, PacketPayload)
end

function Replicate:PlayerAdded<T>(Player: Player)
	const DataService = registry:GetService("DataService") :: DataType.DataService<any>

	task.spawn(function()
		local profile
		local timeout = 0.5
		local timeoutBreak = false

		repeat
			profile = DataService:GetProfile(Player)
			if timeout >= 5 then
				timeoutBreak = true
				replicateLogger:Fatal("Player Profile Not Found")
				break
			end
			task.wait(0.5)
			timeout += 0.5
		until profile

		if timeoutBreak then
			Player:Kick("Rejoin")
			return
		end

		self:Sync(Player, profile.Data)
	end)
end

return Replicate
