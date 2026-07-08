--!strict
--!optimize 2

local RunService = game:GetService("RunService")
local Registry = require(script.Parent.Registry)
local Runtime = require(script.Parent.Runtime)
local SystemRunner = require(script.Parent.SystemRunner)

local Forge = {}
Forge.__index = Forge
Forge.__mode = "k"

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
	["LateUpdate"]: (dt: number, Component) -> ()?,
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

-- // Private

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

function Forge:bootstrap(container: Folder, components: Component)
	if IsServer then
		self._components.server = components
	else
		self._components.client = components
	end

	for _, moduleScript: Instance in ipairs(container:GetDescendants()) do
		if moduleScript.Parent and moduleScript:IsA("ModuleScript") and moduleScript.Parent.Name ~= "Internal" then
			local ok, factory = pcall(require, moduleScript)

			if ok and typeof(factory) == "function" then
				local object = factory()

				if IsServer then
					self:setService(moduleScript.Name, object)
				else
					self:setController(moduleScript.Name, object)
				end
			end
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
