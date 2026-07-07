const ReplicatedStorage = game:GetService("ReplicatedStorage")
const RunService = game:GetService("RunService")
const logger = require(ReplicatedStorage.Shared.Utils.Logger)

if RunService:IsServer() then
	const ServerLog = logger.new("SERVER - CoreFlex")
	ServerLog:Info("Sucess to load server")

	return require(script.Parent.Core.ServerCore)
else
	const ClientLog = logger.new("CLIENT - CoreFlex")
	ClientLog:Info("Sucess to load client")

	return require(script.Parent.Core.ClientCore)
end
