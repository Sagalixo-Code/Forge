const ProfileType = require(script.Parent:WaitForChild("Profile"))
const DataTypes = {}

export type DataService<T> = {
	ProfileManager: ProfileType.ProfileManager<T>,
	Init: (self: DataService<T>, Storage: { [string]: T }) -> nil,
	PlayerAdded: (self: DataService<T>, Player: Player) -> nil,
	PlayerRemoving: (self: DataService<T>, Player: Player) -> nil,
	GetProfile: (self: DataService<T>, Player: Player) -> { [string]: T },
	Get: (self: DataService<T>, Player: Player, Path: { string }) -> T?,
	Set: (self: DataService<T>, Player: Player, Path: { string }, Value: string | number) -> nil,
	Remove: (self: DataService<T>, Player: Player, Path: { string }) -> nil,
	Observe: (Player: Player, Path: { string }, Callback: (T) -> ()) -> { Disconnect: (nil) -> nil },
	Fire: (Player: Player, Path: { string }, ...{ [string]: T }) -> nil,
}

return DataTypes