--!strict
--!optimize 2

export type EntityId = number
export type Index = number
export type Generation = number

local Entity = {}

local INDEX_BITS = 24
local INDEX_LIMIT = 2 ^ INDEX_BITS -- 16_777_216
local INDEX_MASK = INDEX_LIMIT - 1

function Entity.pack(index: Index, generation: Generation): EntityId
	assert(index >= 0 and index <= INDEX_MASK, "Entity index fora do range (24 bits).")
	return generation * INDEX_LIMIT + index
end

function Entity.index(entity: EntityId): Index
	return entity % INDEX_LIMIT
end

function Entity.generation(entity: EntityId): Generation
	return math.floor(entity / INDEX_LIMIT)
end

return Entity
