const ReplicatorType = {}

export type ClientReplicatorType<T> = {
	Data: { [string]: T },
	Observers: { [Player]: { [string]: { signal: any, connections: { [number]: any }, nextId: number } }, Action: string? },
	Init: (self: ClientReplicatorType<T>) -> nil,
	PlayerRemoving: (self: ClientReplicatorType<T>) -> nil,
	Get: (self: ClientReplicatorType<T>, Path: { string }) -> { T },
	Observe: (self: ClientReplicatorType<T>, Path: { string }, Callback: T) -> { Disconnect: nil },
	ClientSync: (self: ClientReplicatorType<T>, Packet: { [string]: T }) -> nil,
	ClientPatch: (self: ClientReplicatorType<T>, Packet: { [string]: T }) -> nil,
	Destroy: (self: ClientReplicatorType<T>) -> nil,
}

return ReplicatorType
