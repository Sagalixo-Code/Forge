local RunService = game:GetService("RunService")
local SystemRunner = {}
SystemRunner.__index = SystemRunner

function SystemRunner.new(systems, components)
	local systemsModule = {}

	for _, systemInstance in pairs(systems:GetChildren()) do
		if not systemInstance:IsA("ModuleScript") then
			continue
		end

		local system = require(systemInstance)
		systemsModule[#systemsModule + 1] = system
	end

	table.sort(systemsModule, function(a, b)
		return (a.Priority or 0) < (b.Priority or 0)
	end)

	local self = setmetatable({
		_systems = systemsModule,
		_updateSystems = {},
		_components = components,
	}, SystemRunner)

	return self
end

function SystemRunner:start()
	for _, system in pairs(self._systems) do
		if system.Start then
			system.Start(self._components)
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, system in pairs(self._updateSystems) do
			if system.Update then
				system.Update(dt, self._components)
			end
		end
	end)

	return self
end

function SystemRunner:stop()
	for _, system in pairs(self._systems) do
		if system.Stop then
			system.Stop(self._components)
		end
	end

	return self
end

function SystemRunner:update()
	for _, system in pairs(self._systems) do
		if system.Update then
			self._updateSystems[#self._updateSystems + 1] = system
		end
	end

	return self
end

return SystemRunner
