local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.signal)

local EventBus = {}
EventBus._events = {}

local function getEvent(eventName: string)
	local events = EventBus._events

	local event = events[eventName]
	if not event then
		event = Signal.new()
		events[eventName] = event
	end

	return event
end

local function assertValid(eventName, callback)
	assert(typeof(eventName) == "string", "eventName must be a string")
	assert(typeof(callback) == "function", "callback must be a function")
end

function EventBus:Subscribe(eventName: string, callback)
	assertValid(eventName, callback)
	return getEvent(eventName):Connect(callback)
end

function EventBus:Once(eventName: string, callback)
	assertValid(eventName, callback)
	return getEvent(eventName):Once(callback)
end

function EventBus:Publish(eventName: string, ...)
	local event = self._events[eventName]
	if not event then
		return
	end

	event:Fire(...)
end

function EventBus:UnsubscribeAll(eventName: string)
	local event = self._events[eventName]
	if not event then
		return
	end

	event:Destroy()
	self._events[eventName] = nil
end

function EventBus:Clear()
	for name, event in pairs(self._events) do
		event:Destroy()
		self._events[name] = nil
	end
end

function EventBus:Has(eventName: string): boolean
	return self._events[eventName] ~= nil
end

return EventBus
