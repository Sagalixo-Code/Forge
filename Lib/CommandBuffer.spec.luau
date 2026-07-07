local CommandBuffer = require(script.Parent.CommandBuffer)

return function()
	describe("CommandBuffer", function()
		local world
		local buffer

		beforeEach(function()
			world = {
				setCalls = {},
				removeCalls = {},
				despawnCalls = {},

				_setComponentImmediate = function(self, entity, component, value)
					table.insert(self.setCalls, {
						entity = entity,
						component = component,
						value = value,
					})
				end,

				_removeComponentImmediate = function(self, entity, component)
					table.insert(self.removeCalls, {
						entity = entity,
						component = component,
					})
				end,

				_despawnImmediate = function(self, entity)
					table.insert(self.despawnCalls, entity)
				end,
			}

			buffer = CommandBuffer.new()
		end)

		it("queues and flushes set commands", function()
			buffer:queueSet(1, 5, "Hello")
			buffer:flush(world)

			expect(#world.setCalls).to.equal(1)

			local call = world.setCalls[1]

			expect(call.entity).to.equal(1)
			expect(call.component).to.equal(5)
			expect(call.value).to.equal("Hello")
		end)

		it("queues and flushes remove commands", function()
			buffer:queueRemove(10, 3)
			buffer:flush(world)

			expect(#world.removeCalls).to.equal(1)

			local call = world.removeCalls[1]

			expect(call.entity).to.equal(10)
			expect(call.component).to.equal(3)
		end)

		it("queues and flushes despawn commands", function()
			buffer:queueDespawn(99)
			buffer:flush(world)

			expect(#world.despawnCalls).to.equal(1)
			expect(world.despawnCalls[1]).to.equal(99)
		end)

		it("preserves command order", function()
			buffer:queueSet(1, 1, "A")
			buffer:queueRemove(2, 2)
			buffer:queueDespawn(3)

			buffer:flush(world)

			expect(#world.setCalls).to.equal(1)
			expect(#world.removeCalls).to.equal(1)
			expect(#world.despawnCalls).to.equal(1)
		end)

		it("clears the queue after flushing", function()
			buffer:queueSet(1, 1, true)

			buffer:flush(world)
			buffer:flush(world)

			expect(#world.setCalls).to.equal(1)
		end)

		it("does nothing when the queue is empty", function()
			expect(function()
				buffer:flush(world)
			end).never.to.throw()
		end)

		it("does not flush while deferring", function()
			buffer.deferring = true

			buffer:queueSet(1, 1, true)
			buffer:queueRemove(2, 2)
			buffer:queueDespawn(3)

			buffer:flush(world)

			expect(#world.setCalls).to.equal(0)
			expect(#world.removeCalls).to.equal(0)
			expect(#world.despawnCalls).to.equal(0)

			buffer.deferring = false
			buffer:flush(world)

			expect(#world.setCalls).to.equal(1)
			expect(#world.removeCalls).to.equal(1)
			expect(#world.despawnCalls).to.equal(1)
		end)

		it("supports multiple commands of the same type", function()
			buffer:queueSet(1, 1, "A")
			buffer:queueSet(2, 2, "B")
			buffer:queueSet(3, 3, "C")

			buffer:flush(world)

			expect(#world.setCalls).to.equal(3)

			expect(world.setCalls[1].entity).to.equal(1)
			expect(world.setCalls[2].entity).to.equal(2)
			expect(world.setCalls[3].entity).to.equal(3)
		end)
	end)
end
