local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.Shared.CoreFlex.Registry)
local ReplicatorTypes = require(ReplicatedStorage.Shared.Utils.Types.Replicator)

local CoinsUI = require(script.Parent.Parent.UI.Coins)

local CoinsController = {}

function CoinsController:Init()
	local Replicator = Registry:GetController("Replicator") :: ReplicatorTypes.ClientReplicatorType<any>

	Replicator:Observe({ "Currencies", "Coins" }, function(Coins)
		CoinsUI:Update(Coins)
	end)
end

return CoinsController
