local World = require(script.Parent.World)

return function()
	describe("World", function()
		it("spawns a valid entity", function()
			local world = World.new()

			local entity = world:spawn()

			expect(entity).never.to.equal(nil)
			expect(world:exists(entity)).to.equal(true)
		end)

		it("creates unique entities", function()
			local world = World.new()

			local a = world:spawn()
			local b = world:spawn()

			expect(a).never.to.equal(b)
		end)

		it("sets and gets components", function()
			local world = World.new()

			local entity = world:spawn()

			world:set(entity, 1, 123)

			expect(world:get(entity, 1)).to.equal(123)
		end)

		it("has returns true after setting a component", function()
			local world = World.new()

			local entity = world:spawn()

			world:set(entity, 5, "hello")

			expect(world:has(entity, 5)).to.equal(true)
		end)

		it("has returns false for missing component", function()
			local world = World.new()

			local entity = world:spawn()

			expect(world:has(entity, 100)).to.equal(false)
		end)

		it("remove deletes a component", function()
			local world = World.new()

			local entity = world:spawn()

			world:set(entity, 2, true)
			world:remove(entity, 2)

			expect(world:has(entity, 2)).to.equal(false)
			expect(world:get(entity, 2)).to.equal(nil)
		end)

		it("despawn removes an entity", function()
			local world = World.new()

			local entity = world:spawn()

			world:despawn(entity)

			expect(world:exists(entity)).to.equal(false)
		end)

		it("recycles entity indices using generations", function()
			local world = World.new()

			local a = world:spawn()

			world:despawn(a)

			local b = world:spawn()

			expect(a).never.to.equal(b)
			expect(world:exists(a)).to.equal(false)
			expect(world:exists(b)).to.equal(true)
		end)

		it("query returns matching entities", function()
			local world = World.new()

			local a = world:spawn()
			local b = world:spawn()

			world:set(a, 1, "A")
			world:set(a, 2, "B")

			world:set(b, 1, "C")

			local query = world:query(1, 2)

			local entity, x, y = query()

			expect(entity).to.equal(a)
			expect(x).to.equal("A")
			expect(y).to.equal("B")

			expect(query()).to.equal(nil)
		end)

		it("query without excludes archetypes", function()
			local world = World.new()

			local a = world:spawn()
			local b = world:spawn()

			world:set(a, 1, true)
			world:set(a, 2, true)

			world:set(b, 1, true)

			local query = world:query(1):without(2)

			local entity = query()

			expect(entity).to.equal(b)
		end)

		it("onChange fires when component changes", function()
			local world = World.new()

			local entity = world:spawn()

			local fired = false

			world:onChange(10, function(e, value)
				fired = true

				expect(e).to.equal(entity)
				expect(value).to.equal(999)
			end)

			world:set(entity, 10, 999)

			expect(fired).to.equal(true)
		end)

		it("deferred commands do not execute immediately", function()
			local world = World.new()

			local entity = world:spawn()

			world:setDeferred(true)

			world:set(entity, 1, 50)

			expect(world:has(entity, 1)).to.equal(false)

			world:flush()

			expect(world:get(entity, 1)).to.equal(50)
		end)

		it("multiple deferred commands flush correctly", function()
			local world = World.new()

			local entity = world:spawn()

			world:setDeferred(true)

			world:set(entity, 1, 10)
			world:set(entity, 2, 20)
			world:set(entity, 3, 30)

			world:flush()

			expect(world:get(entity, 1)).to.equal(10)
			expect(world:get(entity, 2)).to.equal(20)
			expect(world:get(entity, 3)).to.equal(30)
		end)
	end)
end
