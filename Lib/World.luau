--!strict
--!optimize 2

local Entity = require(script.Parent.Entity)
local Signature = require(script.Parent.Signature)
local Archetype = require(script.Parent.Archetype)
local CommandBuffer = require(script.Parent.CommandBuffer)
local QueryResult = require(script.Parent.QueryResult)
local Scheduler = require(script.Parent.Scheduler)

local World = {}
World.__index = World

export type EntityId = Archetype.EntityId
export type ComponentId = Archetype.ComponentId
export type ArchetypeClass = Archetype.Archetype

type Location = { archetype: ArchetypeClass, row: number }

export type Scheduler = typeof(Scheduler.new())

function World.new()
	return setmetatable({
		_archetypes = {} :: { [string]: ArchetypeClass },
		_componentToArchetypes = {} :: { [ComponentId]: { [ArchetypeClass]: true } },

		_generations = {} :: { [Entity.Index]: Entity.Generation },
		_locations = {} :: { [Entity.Index]: Location },

		_nextIndex = 1 :: Entity.Index,
		_freeIndices = {} :: { Entity.Index },

		_commandBuffer = CommandBuffer.new(),

		_changedListeners = {} :: { [ComponentId]: { (EntityId, any) -> () } },

		_scheduler = Scheduler.new() :: Scheduler,
	}, World)
end

export type World = typeof(World.new())

--// Private

function World:_allocateIndex(): Entity.Index
	local free = self._freeIndices

	if #free > 0 then
		return table.remove(free) :: Entity.Index
	end

	local index = self._nextIndex
	self._nextIndex += 1

	return index
end

function World:exists(entity: EntityId): boolean
	local index = Entity.index(entity)
	local location = self._locations[index]

	if not location then
		return false
	end

	return (self._generations[index] or 0) == Entity.generation(entity)
end

function World:_requireEntity(entity: EntityId)
	assert(self:exists(entity), ("Entity '%d' não existe (ou já foi despawnada)."):format(entity))
end

function World:_getLocation(entity: EntityId): Location
	self:_requireEntity(entity)
	return self._locations[Entity.index(entity)] :: Location
end

function World:_registerArchetype(archetype: ArchetypeClass)
	for _, componentId in archetype.componentIds do
		local set = self._componentToArchetypes[componentId]

		if not set then
			set = {}
			self._componentToArchetypes[componentId] = set
		end

		set[archetype] = true
	end
end

function World:_getOrCreateArchetype(signature: Signature.Signature): ArchetypeClass
	local key = Signature.key(signature)
	local archetype = self._archetypes[key]

	if archetype then
		return archetype
	end

	local componentIds = Signature.toList(signature)
	archetype = Archetype.new(signature, componentIds)
	self._archetypes[key] = archetype
	self:_registerArchetype(archetype)

	return archetype
end

function World:_migrate(entity: EntityId, oldLocation: Location?, nextArchetype: ArchetypeClass): number
	local nextRow = nextArchetype:addEntity(entity)

	if oldLocation then
		local oldArchetype = oldLocation.archetype

		for _, componentId in oldArchetype.componentIds do
			if nextArchetype:hasComponent(componentId) then
				nextArchetype:setRow(componentId, nextRow, oldArchetype:getRow(componentId, oldLocation.row))
			end
		end

		local movedEntity = oldArchetype:removeRow(oldLocation.row)

		if movedEntity then
			self._locations[Entity.index(movedEntity)] = { archetype = oldArchetype, row = oldLocation.row }
		end
	end

	self._locations[Entity.index(entity)] = { archetype = nextArchetype, row = nextRow }

	return nextRow
end

function World:_setComponentImmediate(entity: EntityId, componentId: ComponentId, value: any)
	local location = self:_getLocation(entity)
	local archetype = location.archetype

	if not archetype:hasComponent(componentId) then
		local nextSignature = Signature.clone(archetype.signature)
		Signature.set(nextSignature, componentId)

		local nextArchetype = self:_getOrCreateArchetype(nextSignature)
		local nextRow = self:_migrate(entity, location, nextArchetype)

		nextArchetype:setRow(componentId, nextRow, value)
		self:_notifyChanged(componentId, entity, value)
		return
	end

	archetype:setRow(componentId, location.row, value)
	self:_notifyChanged(componentId, entity, value)
end

function World:_removeComponentImmediate(entity: EntityId, componentId: ComponentId)
	local location = self:_getLocation(entity)
	local archetype = location.archetype

	if not archetype:hasComponent(componentId) then
		return
	end

	local nextSignature = Signature.clone(archetype.signature)
	Signature.unset(nextSignature, componentId)

	local nextArchetype = self:_getOrCreateArchetype(nextSignature)
	self:_migrate(entity, location, nextArchetype)
end

function World:_despawnImmediate(entity: EntityId)
	local location = self:_getLocation(entity)
	local index = Entity.index(entity)

	local movedEntity = location.archetype:removeRow(location.row)

	if movedEntity then
		self._locations[Entity.index(movedEntity)] = { archetype = location.archetype, row = location.row }
	end

	self._locations[index] = nil
	self._generations[index] = (self._generations[index] or 0) + 1
	table.insert(self._freeIndices, index)
end

function World:_notifyChanged(componentId: ComponentId, entity: EntityId, value: any)
	local listeners = self._changedListeners[componentId]

	if not listeners then
		return
	end

	for _, listener in listeners do
		listener(entity, value)
	end
end

--// Public

function World:spawn(): EntityId
	local index = self:_allocateIndex()
	local generation = self._generations[index] or 0
	local entity = Entity.pack(index, generation)

	local emptyArchetype = self:_getOrCreateArchetype(Signature.new())
	self:_migrate(entity, nil, emptyArchetype)

	return entity
end

function World:despawn(entity: EntityId)
	self._commandBuffer:queueDespawn(entity)
	self._commandBuffer:flush(self)
end

function World:remove(entity: EntityId, component: ComponentId)
	self._commandBuffer:queueRemove(entity, component)
	self._commandBuffer:flush(self)
end

function World:set(entity: EntityId, component: ComponentId, value: any)
	self._commandBuffer:queueSet(entity, component, value)
	self._commandBuffer:flush(self)
end

function World:get(entity: EntityId, componentId: ComponentId): any
	local location = self:_getLocation(entity)
	return location.archetype:getRow(componentId, location.row)
end

function World:has(entity: EntityId, componentId: ComponentId): boolean
	local location = self:_getLocation(entity)
	return location.archetype:hasComponent(componentId)
end

function World:query(...: ComponentId): QueryResult.QueryResult
	local componentIds = { ... }
	local candidateSet: { [ArchetypeClass]: true }? = nil

	if #componentIds == 0 then
		return QueryResult.new({}, {})
	end

	for _, componentId in componentIds do
		local archetypesWithComponent = self._componentToArchetypes[componentId]

		if not archetypesWithComponent then
			return QueryResult.new({}, componentIds)
		end

		if candidateSet == nil then
			candidateSet = {}

			for archetype in archetypesWithComponent do
				candidateSet[archetype] = true
			end
		else
			for archetype in candidateSet do
				if not archetypesWithComponent[archetype] then
					candidateSet[archetype] = nil
				end
			end
		end
	end

	local matched = {}

	if candidateSet then
		for archetype in candidateSet do
			table.insert(matched, archetype)
		end
	else
		for _, archetype in self._archetypes do
			if #archetype.componentIds > 0 then
				table.insert(matched, archetype)
			end
		end
	end

	return QueryResult.new(matched, componentIds)
end

function World:onChange(componentId: ComponentId, callback: (EntityId, any) -> ())
	local listeners = self._changedListeners[componentId]

	if not listeners then
		listeners = {}
		self._changedListeners[componentId] = listeners
	end

	table.insert(listeners, callback)
end

function World:flush()
	self._commandBuffer:flush(self)
end

function World:setDeferred(enabled: boolean)
	self._commandBuffer.deferring = enabled
end

function World:addSystem(system: Scheduler.System)
	self._scheduler:scheduleSystem(system)
end

function World:addSystems(systems: { Scheduler.System })
	self._scheduler:scheduleSystems(systems)
end

function World:startSystems()
	self._scheduler:initialize(self)
end

function World:update(dt: number)
	self._scheduler:update(self, dt)
end

return World
