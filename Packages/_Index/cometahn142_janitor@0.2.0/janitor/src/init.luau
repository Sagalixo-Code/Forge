--!strict
--!optimize 2
--!native

export type Cleanable = Instance | RBXScriptConnection | thread | () -> () | { [any]: any }

export type MethodName = string | boolean

export type PromiseLike<T> = {
	getStatus: (self: PromiseLike<T>) -> string,
	cancel: (self: PromiseLike<T>) -> (),
	finallyCall: (self: PromiseLike<T>, callback: (...any) -> ()) -> PromiseLike<T>,
}

export type PromiseExecutor<T> = (
	resolve: (...any) -> (),
	reject: (reason: any) -> (),
	onCancel: (callback: () -> ()) -> ()
) -> ()

type PromiseAPI = {
	new: <T>(executor: PromiseExecutor<T>) -> PromiseLike<T>,
	is: (value: any) -> boolean,
	Status: {
		Pending: string,
	},
}

local LinkToInstanceIndex = newproxy(false)

local METHOD_NOT_FOUND_ERROR = "[Janitor] Object '%s' does not have method '%s'."
local NOT_A_PROMISE = "[Janitor] Value passed to AddPromise is not a Promise."
local PROMISE_MODULE_NOT_FOUND = "[Janitor] Promise ModuleScript not found in ancestry."
local PROMISE_MODULE_INVALID =
	"[Janitor] Required Promise module must expose Promise.new, Promise.is, and Promise.Status.Pending."

local TypeDefaults = {
	["function"] = true,
	["thread"] = true,
	["RBXScriptConnection"] = "Disconnect",
}

local Janitor = {}
Janitor.ClassName = "Janitor"
Janitor.__index = Janitor

type JanitorFields = {
	CurrentlyCleaning: boolean,
	_tasks: { [any]: MethodName }?,
	_indices: { [any]: any }?,
}

export type Janitor = typeof(setmetatable({} :: JanitorFields, Janitor))

function Janitor.new(): Janitor
	return setmetatable({
		CurrentlyCleaning = false,
		_tasks = {},
		_indices = {},
	}, Janitor) :: any
end

function Janitor.Is(object: any): boolean
	return type(object) == "table" and getmetatable(object) == Janitor
end
Janitor.instanceof = Janitor.Is

local function getMethod(object: any, methodName: MethodName?): MethodName
	if methodName ~= nil then
		return methodName
	end

	local objectType = typeof(object)
	local default = TypeDefaults[objectType]
	if default ~= nil then
		return default
	end

	if objectType == "Instance" then
		return "Destroy"
	end

	if type(object) == "table" then
		if type(object.Destroy) == "function" then
			return "Destroy"
		elseif type(object.Disconnect) == "function" then
			return "Disconnect"
		end
	end

	return "Destroy"
end

local PromiseAPICache: PromiseAPI? = nil

local function getPromiseAPI(): PromiseAPI
	if PromiseAPICache ~= nil then
		return PromiseAPICache
	end

	local current: Instance? = script
	while current ~= nil do
		local candidate = current:FindFirstChild("Promise")
		if candidate ~= nil and candidate:IsA("ModuleScript") then
			local ok, required = pcall(require, candidate)
			if not ok then
				error(required, 2)
			end

			local PromiseAPI = required :: any
			if
				type(PromiseAPI) ~= "table"
				or type(PromiseAPI.new) ~= "function"
				or type(PromiseAPI.is) ~= "function"
				or type(PromiseAPI.Status) ~= "table"
				or type(PromiseAPI.Status.Pending) ~= "string"
			then
				error(PROMISE_MODULE_INVALID, 2)
			end

			local typedPromiseAPI = PromiseAPI :: PromiseAPI
			PromiseAPICache = typedPromiseAPI
			return typedPromiseAPI
		end
		current = current.Parent
	end

	error(PROMISE_MODULE_NOT_FOUND, 2)
end

local function isPromiseActive(PromiseAPI: PromiseAPI, status: string): boolean
	return status == PromiseAPI.Status.Pending or status == "Started"
end

function Janitor:Add<T>(object: T, methodName: MethodName?, index: any?): T
	local tasks = self._tasks
	if not tasks then
		tasks = {}
		self._tasks = tasks
	end

	local indices = self._indices
	if not indices then
		indices = {}
		self._indices = indices
	end

	if index ~= nil then
		self:Remove(index)
		indices[index] = object
	end

	tasks[object] = getMethod(object, methodName)
	return object
end

function Janitor:AddPromise<T>(promiseOrExecutor: PromiseLike<T> | PromiseExecutor<T>): PromiseLike<T>
	local PromiseAPI = getPromiseAPI()
	local promise: PromiseLike<T>
	if type(promiseOrExecutor) == "function" then
		promise = PromiseAPI.new(promiseOrExecutor :: PromiseExecutor<T>)
	else
		if not PromiseAPI.is(promiseOrExecutor) then
			error(NOT_A_PROMISE, 2)
		end
		promise = promiseOrExecutor :: PromiseLike<T>
	end

	local p = promise :: any
	if type(p) ~= "table" or type(p.getStatus) ~= "function" or type(p.cancel) ~= "function" then
		error(NOT_A_PROMISE, 2)
	end

	if isPromiseActive(PromiseAPI, p:getStatus()) then
		local id = newproxy(false)
		self:Add(function()
			p:cancel()
		end, true, id)

		p:finallyCall(function()
			if not self.CurrentlyCleaning then
				self:Remove(id)
			end
		end)
	end

	return promise
end

function Janitor:IndexOf(object: any): any?
	local indices = self._indices
	if not indices then
		return nil
	end
	for index, value in indices do
		if value == object then
			return index
		end
	end
	return nil
end

function Janitor:Get<T>(index: any): T?
	local indices = self._indices
	if not indices then
		return nil
	end
	return indices[index] :: T?
end

function Janitor:GetAll(): { [any]: any }
	local copy: { [any]: any } = {}
	local indices = self._indices
	if indices then
		for index, value in indices do
			copy[index] = value
		end
	end
	return copy
end

local function cleanupOne(object: any, methodName: MethodName)
	if methodName == true then
		local t = type(object)
		if t == "function" then
			object()
		elseif t == "thread" then
			if coroutine.running() ~= object and coroutine.status(object) ~= "dead" then
				pcall(task.cancel, object)
			end
		end
		return
	end

	local method = (object :: any)[methodName]
	if method then
		method(object)
	else
		warn(string.format(METHOD_NOT_FOUND_ERROR, tostring(object), tostring(methodName)))
	end
end

function Janitor:Remove(index: any): Janitor
	local indices = self._indices
	if not indices then
		return self
	end
	local object = indices[index]
	if object == nil then
		return self
	end

	local tasks = self._tasks
	if tasks then
		local methodName = tasks[object]
		if methodName ~= nil then
			tasks[object] = nil
			cleanupOne(object, methodName)
		end
	end

	indices[index] = nil
	return self
end

function Janitor:RemoveNoClean(index: any): Janitor
	local indices = self._indices
	if not indices then
		return self
	end
	local object = indices[index]
	if object ~= nil then
		local tasks = self._tasks
		if tasks then
			tasks[object] = nil
		end
		indices[index] = nil
	end
	return self
end

function Janitor:RemoveList(...: any): Janitor
	for i = 1, select("#", ...) do
		self:Remove(select(i, ...))
	end
	return self
end

function Janitor:RemoveListNoClean(...: any): Janitor
	for i = 1, select("#", ...) do
		self:RemoveNoClean(select(i, ...))
	end
	return self
end

function Janitor:Cleanup()
	if self.CurrentlyCleaning then
		return
	end
	self.CurrentlyCleaning = true

	local tasks = self._tasks
	local indices = self._indices

	if tasks then
		local count = 0
		for _ in tasks do
			count += 1
		end

		if count > 0 then
			local objects = table.create(count)
			local methods = table.create(count)
			local i = 0
			for object, methodName in tasks do
				i += 1
				objects[i] = object
				methods[i] = methodName
			end

			table.clear(tasks)
			if indices then
				table.clear(indices)
			end

			for j = 1, count do
				cleanupOne(objects[j], methods[j])
			end
		elseif indices then
			table.clear(indices)
		end
	elseif indices then
		table.clear(indices)
	end

	self.CurrentlyCleaning = false
end

function Janitor:Destroy()
	self:Cleanup()
	if self._tasks then
		table.clear(self._tasks)
		self._tasks = nil
	end
	if self._indices then
		table.clear(self._indices)
		self._indices = nil
	end
	table.clear(self :: any)
	setmetatable(self :: any, nil)
end

Janitor.__call = Janitor.Cleanup

function Janitor:LinkToInstance(object: Instance, allowMultiple: boolean?): RBXScriptConnection
	local connection: RBXScriptConnection
	local isNilParented = object.Parent == nil
	local isFirstCall = true

	local function changed(property: string)
		if property ~= "Parent" then
			return
		end

		local parent = object.Parent
		if isFirstCall then
			isFirstCall = false
			isNilParented = parent == nil
			return
		end

		if parent == nil and isNilParented then
			task.defer(function()
				if not connection.Connected then
					self:Cleanup()
				else
					isNilParented = true
				end
			end)
		else
			isNilParented = parent == nil
		end
	end

	connection = object.Destroying:Connect(function()
		self:Cleanup()
	end)

	local ancestryConnection = object.AncestryChanged:Connect(function(_, parent)
		changed("Parent")
		if parent == nil then
			isNilParented = true
		end
	end)

	local index = if allowMultiple then newproxy(false) else LinkToInstanceIndex
	self:Add(function()
		if connection.Connected then
			connection:Disconnect()
		end
		if ancestryConnection.Connected then
			ancestryConnection:Disconnect()
		end
	end, true, index)

	return connection
end

function Janitor:LinkToInstances(...: Instance): Janitor
	local sub = Janitor.new()
	for i = 1, select("#", ...) do
		local instance = select(i, ...)
		sub:Add(self:LinkToInstance(instance, true), "Disconnect")
	end
	self:Add(sub, "Destroy")
	return self
end

return Janitor
