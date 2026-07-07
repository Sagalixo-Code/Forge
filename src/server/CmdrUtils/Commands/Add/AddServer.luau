local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Type = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Types"):WaitForChild("DataService")
)
return function(Context, Player, Currencie, Amount)
	local Registry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreFlex"):WaitForChild("Registry"))
	local DataService = Registry:GetService("DataService") :: Type.DataService<any>

	local Path = { "Currencies", tostring(Currencie) }
	local CurrencieSnapshot = tonumber(DataService:Get(Player, Path))

	print("Before: ", CurrencieSnapshot)

	DataService:Set(Player, Path, CurrencieSnapshot + tonumber(Amount))

	print("After: ", DataService:Get(Player, Path))
end
