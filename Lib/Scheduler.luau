--!strict
--!optimize 2

local Runtime = require(script.Parent.Runtime)

local Scheduler = {}
Scheduler.__index = Scheduler

export type System = ((world: any, dt: number) -> ()) | {
	callbacks: { (world: any, dt: number) -> () },
}

type ExecutionNode = {
	system: System,
	hookStorage: {},
}

local function getName(fn)
	return debug.info(fn, "n") or "<anonymous>"
end

function Scheduler.new()
	return setmetatable({
		_systems = {},
		_systemNames = {},
		_systemState = {},
	}, Scheduler)
end

export type Scheduler = typeof(Scheduler.new())

function Scheduler:scheduleSystems(systems: { System })
	for _, system in ipairs(systems) do
		if table.find(self._systems, system) then
			continue
		end

		table.insert(self._systems, system)

		self._systemNames[system] = typeof(system) == "function" and getName(system)

		self._systemState[system] = {
			system = system,

			name = self._systemNames[system],

			hookStorage = {},

			executionCount = 0,

			lastExecution = 0,

			enabled = true,
		}
	end
end

function Scheduler:scheduleSystem(system: System)
	self:scheduleSystems({ system })
end

function Scheduler:disable(system)
	if not self._systemState[system] then
		return
	end

	self._systemState[system].enabled = false
end

function Scheduler:enable(system)
	local state = self._systemState[system]

	if not state then
		return
	end

	state.enabled = true
end

local function invoke(system: System, ...)
	if typeof(system) == "function" then
		system(...)
		return
	end

	for _, callback in ipairs(system.callbacks) do
		callback(...)
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

			invoke(system, world, dt)
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
