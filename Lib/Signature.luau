--!strict
--!optimize 2

export type ComponentId = number
export type Signature = { number }

local BITS_PER_WORD = 32

local Signature = {}

function Signature.new(): Signature
	return {}
end

local function wordAndBit(componentId: ComponentId): (number, number)
	local word = (componentId // BITS_PER_WORD) + 1
	local bit = componentId % BITS_PER_WORD
	return word, bit
end

function Signature.set(signature: Signature, componentId: ComponentId)
	local word, bit = wordAndBit(componentId)

	for i = #signature + 1, word do
		signature[i] = 0
	end

	signature[word] = bit32.bor(signature[word], bit32.lshift(1, bit))
end

function Signature.unset(signature: Signature, componentId: ComponentId)
	local word, bit = wordAndBit(componentId)

	if signature[word] == nil then
		return
	end

	signature[word] = bit32.band(signature[word], bit32.bnot(bit32.lshift(1, bit)))

	while #signature > 0 and signature[#signature] == 0 do
		signature[#signature] = nil
	end
end

function Signature.has(signature: Signature, componentId: ComponentId): boolean
	local word, bit = wordAndBit(componentId)
	local value = signature[word]

	if value == nil then
		return false
	end

	return bit32.band(value, bit32.lshift(1, bit)) ~= 0
end

function Signature.containsAll(signature: Signature, other: Signature): boolean
	for i, otherWord in other do
		local word = signature[i] or 0

		if bit32.band(word, otherWord) ~= otherWord then
			return false
		end
	end

	return true
end

function Signature.intersects(signature: Signature, other: Signature): boolean
	local length = math.max(#signature, #other)

	for i = 1, length do
		local a = signature[i] or 0
		local b = other[i] or 0

		if bit32.band(a, b) ~= 0 then
			return true
		end
	end

	return false
end

function Signature.clone(signature: Signature): Signature
	return table.clone(signature)
end

function Signature.key(signature: Signature): string
	return table.concat(signature, ",")
end

function Signature.toList(signature: Signature): { ComponentId }
	local ids = {}

	for wordIndex, word in signature do
		if word == 0 then
			continue
		end

		local base = (wordIndex - 1) * BITS_PER_WORD

		for bit = 0, BITS_PER_WORD - 1 do
			if bit32.band(word, bit32.lshift(1, bit)) ~= 0 then
				table.insert(ids, base + bit)
			end
		end
	end

	return ids
end

return Signature
