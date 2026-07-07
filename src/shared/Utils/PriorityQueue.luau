local BinaryHeap = require(script.Parent.BinaryHeap)
local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

function PriorityQueue.new()
	local self = setmetatable({}, PriorityQueue)
	self._elements = {}
	return self
end

function PriorityQueue:Push(element, priority)
	table.insert(self._elements, { element = element, priority = priority })

	BinaryHeap:Up(self._elements, #self._elements)
end

function PriorityQueue:Pop()
	if #self._elements == 0 then
		return nil
	end

	local item = self._elements[1]

	self._elements[1] = self._elements[#self._elements]
	table.remove(self._elements, #self._elements)

	if #self._elements > 0 then
		BinaryHeap:Down(self._elements, 1)
	end

	return item.element, item.priority
end

function PriorityQueue:IsEmpty()
	return #self._elements == 0
end

return PriorityQueue
