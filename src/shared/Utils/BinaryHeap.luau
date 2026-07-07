local BinaryHeap = {}

function BinaryHeap:Up(elements, index)
	local parentIndex = math.floor(index / 2)

	while index > 1 and elements[index].priority < elements[parentIndex].priority do
		elements[index], elements[parentIndex] = elements[parentIndex], elements[index]
		index = parentIndex
		parentIndex = math.floor(index / 2)
	end
end

function BinaryHeap:Down(elements, index)
	local size = #elements

	while true do
		local smallest = index

		local leftChildIndex = 2 * index
		local rightChildIndex = 2 * index + 1

		if leftChildIndex <= size and elements[leftChildIndex].priority < elements[smallest].priority then
			smallest = leftChildIndex
		end

		if rightChildIndex <= size and elements[rightChildIndex].priority < elements[smallest].priority then
			smallest = rightChildIndex
		end

		if smallest == index then
			break
		end

		elements[index], elements[smallest] = elements[smallest], elements[index]
		index = smallest
	end
end

return BinaryHeap
