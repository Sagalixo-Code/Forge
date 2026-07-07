--!strict
--!optimize 2

local Entity = require(script.Parent.Entity)
local Signature = require(script.Parent.Signature)

export type EntityId = Entity.EntityId
export type ComponentId = Signature.ComponentId

export type Archetype = {
	signature: Signature.Signature,
	componentIds: { ComponentId },
	entities: { EntityId },
	columns: { [ComponentId]: { any } },
}

local Archetype = {}
Archetype.__index = Archetype

function Archetype.new(signature: Signature.Signature, componentIds: { ComponentId }): Archetype
	local columns: { [ComponentId]: { any } } = {}

	for _, id in componentIds do
		columns[id] = {}
	end

	return setmetatable({
		signature = signature,
		componentIds = componentIds,
		entities = {},
		columns = columns,
	}, Archetype) :: any
end

function Archetype:hasComponent(componentId: ComponentId): boolean
	return Signature.has(self.signature, componentId)
end

function Archetype:addEntity(entity: EntityId): number
	local entities = self.entities
	local row = #entities + 1
	entities[row] = entity
	return row
end

function Archetype:removeRow(row: number): EntityId?
	local entities = self.entities
	local lastRow = #entities

	if row == lastRow then
		entities[row] = nil

		for _, column in self.columns do
			column[row] = nil
		end

		return nil
	end

	local movedEntity = entities[lastRow]
	entities[row] = movedEntity
	entities[lastRow] = nil

	for _, column in self.columns do
		column[row] = column[lastRow]
		column[lastRow] = nil
	end

	return movedEntity
end

function Archetype:setRow(componentId: ComponentId, row: number, value: any)
	self.columns[componentId][row] = value
end

function Archetype:getRow(componentId: ComponentId, row: number): any
	local column = self.columns[componentId]

	if not column then
		return nil
	end

	return column[row]
end

return Archetype
