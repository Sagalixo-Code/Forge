--!strict
--!optimize 2

export type RuntimeState = "Booting" | "PreInit" | "Init" | "Start" | "Running" | "Stopping" | "Stopped"

export type Runtime = {
	SetState: (self: Runtime, State: RuntimeState) -> (),
	GetState: (self: Runtime) -> RuntimeState,

	IsBooting: (self: Runtime) -> boolean,
	IsPreInit: (self: Runtime) -> boolean,
	IsInit: (self: Runtime) -> boolean,
	IsStart: (self: Runtime) -> boolean,
	IsRunning: (self: Runtime) -> boolean,
	IsStopping: (self: Runtime) -> boolean,
	IsStopped: (self: Runtime) -> boolean,

	SetFlag: (self: Runtime, Name: string, Value: any) -> (),
	GetFlag: (self: Runtime, Name: string) -> any,
	HasFlag: (self: Runtime, Name: string) -> boolean,
	RemoveFlag: (self: Runtime, Name: string) -> (),

	GetUptime: (self: Runtime) -> number,
}

const Runtime = {}
Runtime.__index = Runtime

function Runtime.new(): Runtime
	local self = setmetatable({}, Runtime)

	self._state = "Booting" :: RuntimeState
	self._startedAt = os.clock()

	self._flags = {} :: { [string]: any }

	return self
end

function Runtime:SetState(State: RuntimeState)
	self._state = State
end

function Runtime:GetState(): RuntimeState
	return self._state
end

function Runtime:IsBooting(): boolean
	return self._state == "Booting"
end

function Runtime:IsPreInit(): boolean
	return self._state == "PreInit"
end

function Runtime:IsInit(): boolean
	return self._state == "Init"
end

function Runtime:IsStart(): boolean
	return self._state == "Start"
end

function Runtime:IsRunning(): boolean
	return self._state == "Running"
end

function Runtime:IsStopping(): boolean
	return self._state == "Stopping"
end

function Runtime:IsStopped(): boolean
	return self._state == "Stopped"
end

function Runtime:SetFlag(Name: string, Value: any)
	self._flags[Name] = Value
end

function Runtime:GetFlag(Name: string): any
	return self._flags[Name]
end

function Runtime:HasFlag(Name: string): boolean
	return self._flags[Name] ~= nil
end

function Runtime:RemoveFlag(Name: string)
	self._flags[Name] = nil
end

function Runtime:GetUptime(): number
	return os.clock() - self._startedAt
end

return Runtime.new()
