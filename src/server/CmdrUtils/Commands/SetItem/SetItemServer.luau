local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Type = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Types"):WaitForChild("DataService")
)
local tableUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Table"))

return function(Context, Player, ItemName)
	local Registry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreFlex"):WaitForChild("Registry"))
	local DataService = Registry:GetService("DataService") :: Type.DataService<any>

	local Path = { "Inventory" }
	local Inventory = tableUtils.stringToTable(DataService:Get(Player, Path))

	Inventory[#Inventory + 1] = tostring(ItemName)

	DataService:Set(Player, Path, tableUtils.tableToString(Inventory))
end
