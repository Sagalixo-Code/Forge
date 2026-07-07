--!strict
--!optimize 2

local Archetype = require(script.Parent.Archetype)
local Signature = require(script.Parent.Signature)

local QueryResult = {}
QueryResult.__index = QueryResult

export type QueryResult = typeof(setmetatable(
	{} :: {
		_archetypes: { Archetype.Archetype },
		_componentIds: { Archetype.ComponentId },
		_withoutSignature: Signature.Signature,
		_archetypeIndex: number,
		_row: number,
	},
	{} :: typeof(QueryResult)
))

function QueryResult.new(archetypes: { Archetype.Archetype }, componentIds: { Archetype.ComponentId }): QueryResult
	return setmetatable({
		_archetypes = archetypes,
		_componentIds = componentIds,
		_withoutSignature = Signature.new(),
		_archetypeIndex = 1,
		_row = 0,
	}, QueryResult) :: any
end

function QueryResult:without(...: Archetype.ComponentId): QueryResult
	local withoutSignature = Signature.new()

	for _, componentId in { ... } do
		Signature.set(withoutSignature, componentId)
	end

	self._withoutSignature = withoutSignature
	return self
end

function QueryResult:_next(): (Archetype.EntityId?, ...any)
	local archetypes = self._archetypes
	local componentIds = self._componentIds
	local withoutSignature = self._withoutSignature

	while self._archetypeIndex <= #archetypes do
		local archetype = archetypes[self._archetypeIndex] :: any

		if Signature.intersects(archetype.signature, withoutSignature) then
			self._archetypeIndex += 1
			self._row = 0
			continue
		end

		self._row += 1

		local row = self._row
		local entity = archetype.entities[row]

		if entity == nil then
			self._archetypeIndex += 1
			self._row = 0
			continue
		end

		if #componentIds == 0 then
			return entity
		end

		local values = table.create(#componentIds)

		for i, componentId in componentIds do
			values[i] = archetype:getRow(componentId, row)
		end

		return entity, table.unpack(values)
	end

	return nil
end

QueryResult.__call = function(self: QueryResult)
	return self:_next()
end

return QueryResult
