--!strict
--!optimize 2

export type StackFrame = {
	node: any,
	parent: StackFrame?,
	accessedKeys: {
		[any]: {
			[any]: true,
		},
	},
	hookIndex: number,
	depth: number,
}

local Runtime = {}
Runtime._stack = {} :: { StackFrame }

local function newStackFrame(node: any): StackFrame
	local parent = Runtime:current()

	node.hookStorage = node.hookStorage or {}

	return {
		node = node,
		parent = parent,
		accessedKeys = {},
		hookIndex = 0,
		depth = #Runtime._stack + 1,
	}
end

function Runtime:push(node: any): StackFrame
	local frame = newStackFrame(node)

	self._stack[#self._stack + 1] = frame

	return frame
end

function Runtime:pop(): StackFrame?
	local stack = self._stack
	local frame = stack[#stack]

	if frame then
		stack[#stack] = nil
	end

	return frame
end

function Runtime:current(): StackFrame?
	return self._stack[#self._stack]
end

function Runtime:isRunning(): boolean
	return #self._stack > 0
end

function Runtime:depth(): number
	return #self._stack
end

function Runtime:nextHookIndex(): number
	local frame = self:current()

	assert(frame, "No active runtime.")

	frame.hookIndex += 1

	return frame.hookIndex
end

function Runtime:markAccess(baseKey: any, key: any)
	local frame = self:current()

	if not frame then
		return
	end

	local accessed = frame.accessedKeys[baseKey]

	if not accessed then
		accessed = {}
		frame.accessedKeys[baseKey] = accessed
	end

	accessed[key] = true
end

function Runtime:cleanup(frame: StackFrame)
	local hookStorage = frame.node.hookStorage

	for baseKey, state in pairs(hookStorage) do
		local accessed = frame.accessedKeys[baseKey]

		for key, value in pairs(state.storage) do
			if accessed and accessed[key] then
				continue
			end

			local cleanupCallback = state.cleanupCallback

			if cleanupCallback and cleanupCallback(value) then
				continue
			end

			state.storage[key] = nil
		end
	end
end

function Runtime:start(node: string?, callback: () -> ...any)
	local frame = self:push(node)

	local ok, result = xpcall(callback, debug.traceback)

	self:cleanup(frame)
	self:pop()

	if not ok then
		error(result, 0)
	end

	return frame
end

return Runtime
