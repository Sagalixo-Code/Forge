--!strict
local Flags = require(script.Parent.Flags)

type Kind = "service" | "controller"

local FLAG_SIZE = 2
local INITIAL_CAPACITY = 32

local function newFlagBuffer(entries: number): buffer
	return buffer.create(entries * FLAG_SIZE)
end

local function ensureCapacity(buf: buffer, neededBytes: number): buffer
	local len = buffer.len(buf)
	if neededBytes <= len then
		return buf
	end
	local newLen = len
	repeat
		newLen *= 2
	until newLen >= neededBytes
	local newBuf = buffer.create(newLen)
	buffer.copy(newBuf, 0, buf, 0, len)
	return newBuf
end

local Registry = {
	_names = { service = {}, controller = {} },
	_nameToId = { service = {}, controller = {} },
	_objects = { service = {}, controller = {} },
	_count = { service = 0, controller = 0 },
	_flagBuffers = {
		service = newFlagBuffer(INITIAL_CAPACITY),
		controller = newFlagBuffer(INITIAL_CAPACITY),
	},

	_stageCallbacks = {} :: { [string]: { (...any) -> () } },
}

for _, stage in Flags.Stages do
	Registry._stageCallbacks[stage] = {}
end

local function register(kind: Kind, name: string, object: { [string]: any }): number
	assert(typeof(name) == "string" and name ~= "", "Name must be a non-empty string.")
	assert(typeof(object) == "table", "The service/controller must be a table.")
	assert(not Registry._nameToId[kind][name], `'{name}' has been registered at {kind}`)

	local id = Registry._count[kind] + 1
	Registry._count[kind] = id

	Registry._objects[kind][id] = object
	Registry._names[kind][id] = name
	Registry._nameToId[kind][name] = id

	local mask = Flags.computeMask(object)

	local buf = Registry._flagBuffers[kind]
	local offset = (id - 1) * FLAG_SIZE
	buf = ensureCapacity(buf, offset + FLAG_SIZE)
	Registry._flagBuffers[kind] = buf
	buffer.writeu16(buf, offset, mask)

	for _, stage in Flags.Stages do
		local bit = Flags.ByName[stage]
		if Flags.has(mask, bit) then
			local list = Registry._stageCallbacks[stage]
			list[#list + 1] = object[stage]
		end
	end

	return id
end

function Registry:registerService(serviceName: string, service: { [string]: any })
	if not serviceName or not service then
		error("Service name and service must be provided")
	end
	return register("service", serviceName, service)
end

function Registry:registerController(controllerName: string, controller: { [string]: any })
	if not controllerName or not controller then
		error("Controller name and controller must be provided")
	end
	return register("controller", controllerName, controller)
end

function Registry:getService(name: string): any
	local id = self._nameToId.service[name]
	return id and self._objects.service[id] or nil
end

function Registry:getController(name: string): any
	local id = self._nameToId.controller[name]
	return id and self._objects.controller[id] or nil
end

function Registry:getFlags(kind: Kind, id: number): number
	local buf = self._flagBuffers[kind]
	local offset = (id - 1) * FLAG_SIZE
	if offset + FLAG_SIZE > buffer.len(buf) then
		return 0
	end
	return buffer.readu16(buf, offset)
end

function Registry:getStageCallbacks(stage: string): { (...any) -> () }
	return self._stageCallbacks[stage]
end

function Registry:countImplementing(kind: Kind, bit: number): number
	local buf = self._flagBuffers[kind]
	local total = self._count[kind]
	local n = 0
	for i = 1, total do
		local offset = (i - 1) * FLAG_SIZE
		local mask = buffer.readu16(buf, offset)
		if Flags.has(mask, bit) then
			n += 1
		end
	end
	return n
end

function Registry:reset()
	self._names = {
		service = {},
		controller = {},
	}

	self._nameToId = {
		service = {},
		controller = {},
	}

	self._objects = {
		service = {},
		controller = {},
	}

	self._count = {
		service = 0,
		controller = 0,
	}

	self._flagBuffers = {
		service = newFlagBuffer(INITIAL_CAPACITY),
		controller = newFlagBuffer(INITIAL_CAPACITY),
	}

	self._stageCallbacks = {}

	for _, stage in Flags.Stages do
		self._stageCallbacks[stage] = {}
	end
end

return Registry
