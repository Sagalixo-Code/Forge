--!strict
--!optimize 2

export type Service = {}
export type Controller = any
export type System = any

export type Registry = {
	RegisterService: (self: Registry, Name: string, Object: Service) -> (),
	RegisterController: (self: Registry, Name: string, Object: Controller) -> (),
	RegisterSystem: (self: Registry, Name: string, Object: System) -> (),

	GetService: (self: Registry, Name: string) -> Service,
	GetController: (self: Registry, Name: string) -> Controller,
	GetSystem: (self: Registry, Name: string) -> System,

	HasService: (self: Registry, Name: string) -> boolean,
	HasController: (self: Registry, Name: string) -> boolean,
	HasSystem: (self: Registry, Name: string) -> boolean,

	RemoveService: (self: Registry, Name: string) -> (),
	RemoveController: (self: Registry, Name: string) -> (),
	RemoveSystem: (self: Registry, Name: string) -> (),

	GetServices: (self: Registry) -> { [string]: Service },
	GetControllers: (self: Registry) -> { [string]: Controller },
	GetSystems: (self: Registry) -> { [string]: System },

	Clear: (self: Registry) -> (),
}

const Registry = {}
Registry.__index = Registry

function Registry.new(): Registry
	local self = setmetatable({}, Registry)

	self._services = {} :: { [string]: Service }
	self._controllers = {} :: { [string]: Controller }
	self._systems = {} :: { [string]: System }

	return self
end

function Registry:RegisterService(ModuleScript)
	self._services[ModuleScript.Name] = require(ModuleScript)
end

function Registry:RegisterController(ModuleScript)
	self._controllers[ModuleScript.Name] = require(ModuleScript)
end

function Registry:RegisterSystem(Name: string, Object: System)
	assert(not self._systems[Name], `System "{Name}" already exists`)

	self._systems[Name] = Object
end

function Registry:GetService(Name: string): Service
	local Service = self._services[Name]

	assert(Service, `Service "{Name}" does not exist`)

	return Service
end

function Registry:GetController(Name: string): Controller
	local Controller = self._controllers[Name]

	assert(Controller, `Controller "{Name}" does not exist`)

	return Controller
end

function Registry:GetSystem(Name: string): System
	local System = self._systems[Name]

	assert(System, `System "{Name}" does not exist`)

	return System
end

function Registry:HasService(Name: string): boolean
	return self._services[Name] ~= nil
end

function Registry:HasController(Name: string): boolean
	return self._controllers[Name] ~= nil
end

function Registry:HasSystem(Name: string): boolean
	return self._systems[Name] ~= nil
end

function Registry:RemoveService(Name: string)
	self._services[Name] = nil
end

function Registry:RemoveController(Name: string)
	self._controllers[Name] = nil
end

function Registry:RemoveSystem(Name: string)
	self._systems[Name] = nil
end

function Registry:GetServices(): { [string]: Service }
	return table.clone(self._services)
end

function Registry:GetControllers(): { [string]: Controller }
	return table.clone(self._controllers)
end

function Registry:GetSystems(): { [string]: System }
	return table.clone(self._systems)
end

function Registry:Clear()
	table.clear(self._services)
	table.clear(self._controllers)
	table.clear(self._systems)
end

return Registry.new()
