--!strict
--!optimize 2

local RunService = game:GetService("RunService")
local Validate = require(script.Parent.Validate)

local pcall = pcall
local warn = warn
local tostring = tostring

export type Component = { [string]: any }
export type SystemModule = {
	Priority: number?,
	Start: ((Component) -> ())?,
	Stop: ((Component) -> ())?,
	Update: ((dt: number, Component) -> ())?,
	LateUpdate: ((dt: number, Component) -> ())?,
}

export type SystemEntry = { Name: string, Priority: number, Module: SystemModule }
export type SystemLoadFailure = { name: string, error: string }

type PluginManager = { dispatch: (self: PluginManager, hookName: string, ...any) -> () }

local FLAG_SIZE = 1
local SystemFlag = { Start = 0x1, Update = 0x2, LateUpdate = 0x4, Stop = 0x8 }

local function computeFlags(system: SystemModule): number
	local mask = 0
	if typeof(system.Start) == "function" then
		mask = bit32.bor(mask, SystemFlag.Start)
	end
	if typeof(system.Update) == "function" then
		mask = bit32.bor(mask, SystemFlag.Update)
	end
	if typeof(system.LateUpdate) == "function" then
		mask = bit32.bor(mask, SystemFlag.LateUpdate)
	end
	if typeof(system.Stop) == "function" then
		mask = bit32.bor(mask, SystemFlag.Stop)
	end
	return mask
end

local function safeCall<T>(name: string, stageName: string, fn: (...T) -> T, ...: T)
	local ok, err = pcall(fn, ...)
	if not ok then
		warn(string.format("[Forge] Error in %s of '%s': %s", stageName, name, tostring(err)))
	end
end

local function loadSystems(systems: Folder, plugins: PluginManager?): ({ SystemEntry }, { SystemLoadFailure })
	local entries: { SystemEntry } = {}
	local failed: { SystemLoadFailure } = {}
	for _, systemInstance in systems:GetChildren() do
		if not systemInstance:IsA("ModuleScript") then
			continue
		end

		local ok, moduleOrErr = pcall(require, systemInstance)
		if not ok then
			failed[#failed + 1] = { name = systemInstance.Name, error = tostring(moduleOrErr) }
			if plugins then
				plugins:dispatch("onError", systemInstance:GetFullName(), tostring(moduleOrErr))
			end
			continue
		end

		local validation = Validate.system(systemInstance.Name, moduleOrErr)

		if not validation.ok then
			failed[#failed + 1] = { name = systemInstance.Name, error = table.concat(validation.errors, "; ") }
			if plugins then
				plugins:dispatch(
					"onModuleRejected",
					{ kind = "system", name = systemInstance.Name, path = systemInstance:GetFullName() },
					validation.errors
				)
			end
			continue
		end

		local module: SystemModule = moduleOrErr

		entries[#entries + 1] = { Name = systemInstance.Name, Priority = module.Priority or 0, Module = module }
		if plugins then
			plugins:dispatch("onRegister", "system", systemInstance.Name, module)
		end
	end

	table.sort(entries, function(a, b)
		return a.Priority < b.Priority
	end)

	return entries, failed
end

local SystemRunner = {}
SystemRunner.__index = SystemRunner
SystemRunner.Flag = SystemFlag

export type SystemRunner = typeof(setmetatable(
	{} :: {
		_systems: { SystemEntry },
		_updateSystems: { SystemEntry },
		_lateUpdateSystems: { SystemEntry },
		_nameToIndex: { [string]: number },
		_flags: buffer,
		_components: Component,
		_plugins: PluginManager?,
		_heartbeatConnection: RBXScriptConnection?,
		_failed: { SystemLoadFailure },
	},
	SystemRunner
))

function SystemRunner.new(systems: Folder, components: Component, plugins: PluginManager?): SystemRunner
	local entries, failed = loadSystems(systems, plugins)
	local total = #entries
	local flags = buffer.create(math.max(total, 1) * FLAG_SIZE)
	local updateSystems: { SystemEntry } = {}
	local lateUpdateSystems: { SystemEntry } = {}
	local nameToIndex: { [string]: number } = {}

	for i, entry in entries do
		local mask = computeFlags(entry.Module)
		buffer.writeu8(flags, i - 1, mask)
		nameToIndex[entry.Name] = i
		if bit32.band(mask, SystemFlag.Update) ~= 0 then
			updateSystems[#updateSystems + 1] = entry
		end
		if bit32.band(mask, SystemFlag.LateUpdate) ~= 0 then
			lateUpdateSystems[#lateUpdateSystems + 1] = entry
		end
	end

	if #failed > 0 then
		for _, failure in failed do
			warn(string.format("[Forge] Failed to load system '%s': %s", failure.name, failure.error))
		end
	end

	return setmetatable({
		_systems = entries,
		_updateSystems = updateSystems,
		_lateUpdateSystems = lateUpdateSystems,
		_nameToIndex = nameToIndex,
		_flags = flags,
		_components = components,
		_plugins = plugins,
		_heartbeatConnection = nil,
		_failed = failed,
	}, SystemRunner) :: any
end

function SystemRunner:start(): SystemRunner
	for _, entry in self._systems do
		local start = entry.Module.Start
		if start then
			safeCall(entry.Name, "Start", start, self._components)
		end
	end

	self._heartbeatConnection = RunService.Heartbeat:Connect(function(dt: number)
		for i = 1, #self._updateSystems do
			local entry = self._updateSystems[i]
			local update = entry.Module.Update
			if update then
				safeCall(entry.Name, "Update", update, dt, self._components)
			end
		end
		for i = 1, #self._lateUpdateSystems do
			local entry = self._lateUpdateSystems[i]
			local lateUpdate = entry.Module.LateUpdate
			if lateUpdate then
				safeCall(entry.Name, "LateUpdate", lateUpdate, dt, self._components)
			end
		end
	end)

	return self
end

function SystemRunner:stop(): SystemRunner
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end

	for _, entry in self._systems do
		local stop = entry.Module.Stop
		if stop then
			safeCall(entry.Name, "Stop", stop, self._components)
		end
	end

	return self
end

function SystemRunner:update(): SystemRunner
	table.clear(self._updateSystems)
	table.clear(self._lateUpdateSystems)

	for _, entry in self._systems do
		local index = self._nameToIndex[entry.Name]
		local mask = buffer.readu8(self._flags, index - 1)
		if bit32.band(mask, SystemFlag.Update) ~= 0 then
			self._updateSystems[#self._updateSystems + 1] = entry
		end
		if bit32.band(mask, SystemFlag.LateUpdate) ~= 0 then
			self._lateUpdateSystems[#self._lateUpdateSystems + 1] = entry
		end
	end

	return self
end

function SystemRunner:getSystem(name: string): SystemModule?
	local index = self._nameToIndex[name]
	if not index then
		return nil
	end
	return self._systems[index].Module
end

function SystemRunner:countImplementing(bit: number): number
	local total = #self._systems
	local n = 0

	for i = 1, total do
		local mask = buffer.readu8(self._flags, i - 1)
		if bit32.band(mask, bit) ~= 0 then
			n += 1
		end
	end

	return n
end

function SystemRunner:getFailures(): { SystemLoadFailure }
	return self._failed
end

return SystemRunner
