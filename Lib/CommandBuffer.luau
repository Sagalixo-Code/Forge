--!strict
--!optimize 2

local Archetype = require(script.Parent.Archetype)

local CommandBuffer = {}
CommandBuffer.__index = CommandBuffer

local CommandType = table.freeze({
	Set = 1,
	Remove = 2,
	Despawn = 3,
})

type CommandType = typeof(CommandType.Set) | typeof(CommandType.Remove) | typeof(CommandType.Despawn)

export type Command = {
	type: CommandType,
	entity: Archetype.EntityId,
	component: Archetype.ComponentId?,
	value: any,
}

local Handlers = {
	[CommandType.Set] = function(world, command: Command)
		world:_setComponentImmediate(command.entity, command.component :: number, command.value)
	end,

	[CommandType.Remove] = function(world, command: Command)
		world:_removeComponentImmediate(command.entity, command.component :: number)
	end,

	[CommandType.Despawn] = function(world, command: Command)
		world:_despawnImmediate(command.entity)
	end,
}

function CommandBuffer.new()
	return setmetatable({
		deferring = false,
		_commands = {} :: { Command },
	}, CommandBuffer)
end

function CommandBuffer:_add(command: Command)
	local commands = self._commands
	commands[#commands + 1] = command
end

function CommandBuffer:queueSet(entity: Archetype.EntityId, component: Archetype.ComponentId, value: any)
	self:_add({
		type = CommandType.Set,
		entity = entity,
		component = component,
		value = value,
	})
end

function CommandBuffer:queueRemove(entity: Archetype.EntityId, component: Archetype.ComponentId)
	self:_add({
		type = CommandType.Remove,
		entity = entity,
		component = component,
	})
end

function CommandBuffer:queueDespawn(entity: Archetype.EntityId)
	self:_add({
		type = CommandType.Despawn,
		entity = entity,
	})
end

function CommandBuffer:flush(world)
	if self.deferring then
		return
	end

	local commands = self._commands
	local count = #commands

	if count == 0 then
		return
	end

	for i = 1, count do
		local command = commands[i]
		local handler = Handlers[command.type]

		if handler then
			handler(world, command)
		end
	end

	table.clear(commands)
end

return CommandBuffer
