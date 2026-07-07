local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Registry = require(ReplicatedStorage.Shared.CoreFlex.Registry)
local ReplicatorType = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Types"):WaitForChild("Replicator")
)
local Interface = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Inventory"))

local Inventory = {}

function Inventory:Init()
	local Replicator = Registry:GetController("Replicator") :: ReplicatorType.ClientReplicatorType<any>

	Replicator:Observe({ "Inventory" }, function(inventoryData: { [string]: any }, Action: string?)
		if Action == "Set" or not Action then
			Interface:Create(inventoryData)
		else
			Interface:Remove(inventoryData)
		end
	end)

	UserInputService.InputBegan:Connect(function(Input: InputObject, gp: boolean)
		if gp then
			return
		end

		if Input.KeyCode == Enum.KeyCode.E then
			if Interface.isOpenned then
				Interface:Close()
			else
				Interface:Open()
			end
		end
	end)
end

return Inventory
