--!strict
--!optimize 2

local RunService = game:GetService("RunService")
local Registry = require(script.Parent.Registry)
local Runtime = require(script.Parent.Runtime)
local SystemRunner = require(script.Parent.SystemRunner)

local Forge = {}
Forge.__index = Forge

export type Component = {
	[string]: any,
}

export type ServiceAndController = {
	["PreInit"]: (Component) -> ()?,
	["Init"]: (Component) -> ()?,
	["PostInit"]: (Component) -> ()?,
	["PreStart"]: (Component) -> ()?,
	["Start"]: (Component) -> ()?,
	["PostStart"]: (Component) -> ()?,
	["Shutdown"]: (Component) -> ()?,
	["PlayerAdded"]: (Player, Component) -> ()?,
	["PlayerRemoving"]: (Player, Component) -> ()?,
	["CharacterAdded"]: (Player, Model, Component) -> ()?,
	["CharacterRemoving"]: (Player, Model, Component) -> ()?,
}

export type systems = {
	["Start"]: (Component) -> ()?,
	["Update"]: (dt: number, Component) -> ()?,
}

export type ModuleLoadFailure = {
	name: string,
	path: string,
	error: string,
}

export type ModuleLoadResult = {
	loaded: number,
	failed: { ModuleLoadFailure },
}

local IsServer = RunService:IsServer()

local _callbacksReceived = {
	["PreInit"] = {},
	["Init"] = {},
	["PostInit"] = {},
	["PreStart"] = {},
	["Start"] = {},
	["PostStart"] = {},
	["Shutdown"] = {},
	["PlayerAdded"] = {},
	["PlayerRemoving"] = {},
	["CharacterAdded"] = {},
	["CharacterRemoving"] = {},
}

function Forge.new()
	local self = setmetatable({
		_components = {
			client = {},
			server = {},
		},

		_registry = Registry,
		_runtime = nil,
	}, Forge)

	return self
end

export type Forge = typeof(Forge.new())

-- // Public

function Forge:getComponents(): Component
	if IsServer then
		return self._components.server
	else
		return self._components.client
	end
end

function Forge:setService(serviceName: string, service: ServiceAndController)
	self._registry:registerService(serviceName, service)
end

function Forge:setController(controllerName: string, controller: ServiceAndController)
	self._registry:registerController(controllerName, controller)
end

function Forge:loadModules(container: Folder): ModuleLoadResult
	local result: ModuleLoadResult = {
		loaded = 0,
		failed = {},
	}

	for _, moduleScript: Instance in ipairs(container:GetDescendants()) do
		if moduleScript.Parent and moduleScript:IsA("ModuleScript") and moduleScript.Parent.Name ~= "Internal" then
			local ok, factoryOrErr = pcall(require, moduleScript)

			if ok then
				local factory: ServiceAndController = factoryOrErr

				if IsServer then
					self:setService(moduleScript.Name, factory)
				else
					self:setController(moduleScript.Name, factory)
				end

				result.loaded += 1
			else
				table.insert(result.failed, {
					name = moduleScript.Name,
					path = moduleScript:GetFullName(),
					error = tostring(factoryOrErr),
				})
			end
		end
	end

	return result
end

function Forge:bootstrap(container: Folder, components: Component)
	if IsServer then
		self._components.server = components
	else
		self._components.client = components
	end

	local loadResult = self:loadModules(container)

	if #loadResult.failed > 0 then
		for _, failure in ipairs(loadResult.failed) do
			warn(
				string.format("[Forge] Failed to load module '%s' (%s): %s", failure.name, failure.path, failure.error)
			)
		end
	end

	self._runtime = Runtime.new(self._registry, self:getComponents())
end

function Forge:run(systems: Folder?)
	assert(self._runtime, "Forge must be bootstrapped before running.")

	local initResult = self._runtime:init()

	if initResult:isErr() then
		error(table.concat(initResult:unwrapOr({}), "\n"))
	end

	local startResult = self._runtime:start()

	if startResult:isErr() then
		error(table.concat(startResult:unwrapOr({}), "\n"))
	end

	if IsServer then
		self._runtime:bindPlayerLifecycle()
	end

	SystemRunner.new(systems, self:getComponents()):start():update()
end

return Forge
