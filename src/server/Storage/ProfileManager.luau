local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tableUtils = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Utils"):WaitForChild("Table"))
local profilestore = require(ReplicatedStorage.Packages.profilestore)
local Store = profilestore.New("DataManager_LastTest", {
	Currencies = {
		Coins = 0,
	},
	Inventory = tableUtils.tableToString({ "ExampleItem1" }),
})

local ProfileManager = {}

local Profiles = {}

function ProfileManager:Load(Player)
	local Profile = Store:StartSessionAsync(tostring(Player.UserId))

	if not Profile then
		Player:Kick()
		return
	end

	Profiles[Player] = Profile

	return Profile
end

function ProfileManager:Get(Player)
	return Profiles[Player]
end

function ProfileManager:Release(Player)
	local Profile = Profiles[Player]

	if Profile then
		Profile:EndSession()
	end

	Profiles[Player] = nil
end

return ProfileManager
