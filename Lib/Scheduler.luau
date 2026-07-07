--!strict
--!optimize 2

local Runtime = require(script.Parent.Runtime)

local Scheduler = {}
Scheduler.__index = Scheduler

export type System = {
	PreInit: ((self: System, world: any) -> ())?,
	Init: ((self: System, world: any) -> ())?,
	Start: ((self: System, world: any) -> ())?,
	Update: ((self: System, world: any, dt: number) -> ())?,
}

type UpdateNode = {
	system: System,
	callback: (self: System, world: any, dt: number) -> (),
}

type ExecutionNode = {
	system: System,
	name: string,

	hookStorage: { [string]: any },

	executionCount: number,
	lastExecution: number,

	enabled: boolean,
}

function Scheduler.new()
	return setmetatable({

		_systems = {},

		_registered = {},

		_systemState = {},

		_updateSystems = {},
	}, Scheduler)
end

export type Scheduler = typeof(Scheduler.new())

function Scheduler:scheduleSystem(system: System)
	if self._registered[system] then
		return
	end

	self._registered[system] = true

	table.insert(self._systems, system)

	self._systemState[system] = {

		system = system,

		name = tostring(system),

		hookStorage = {},

		executionCount = 0,

		lastExecution = 0,

		enabled = true,
	}

	if system.Update then
		table.insert(self._updateSystems, {
			system = system,
			callback = system.Update,
		})
	end
end

function Scheduler:initialize(world: any)
	for _, system in self._systems do
		if system.PreInit then
			system:PreInit(world)
		end
	end

	for _, system in self._systems do
		if system.Init then
			system:Init(world)
		end
	end

	for _, system in self._systems do
		if system.Start then
			system:Start(world)
		end
	end
end

function Scheduler:update(world: any, dt: number)
	for _, node in self._updateSystems do
		local state = self._systemState[node.system]

		if not state.enabled then
			continue
		end

		state.executionCount += 1
		state.lastExecution = os.clock()

		Runtime:start(state, function()
			node.callback(node.system, world, dt)
		end)
	end
end

function Scheduler:disable(system: System)
	local state = self._systemState[system]

	if state then
		state.enabled = false
	end
end

function Scheduler:enable(system: System)
	local state = self._systemState[system]

	if state then
		state.enabled = true
	end
end

return Scheduler
