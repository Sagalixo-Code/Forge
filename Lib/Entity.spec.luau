local Entity = require(script.Parent.Entity)

return function()
	describe("Entity", function()
		it("packs and unpacks an entity id", function()
			local entity = Entity.pack(123, 5)

			expect(Entity.index(entity)).to.equal(123)
			expect(Entity.generation(entity)).to.equal(5)
		end)

		it("supports index zero", function()
			local entity = Entity.pack(0, 10)

			expect(Entity.index(entity)).to.equal(0)
			expect(Entity.generation(entity)).to.equal(10)
		end)

		it("supports the maximum valid index", function()
			local maxIndex = (2 ^ 24) - 1
			local entity = Entity.pack(maxIndex, 2)

			expect(Entity.index(entity)).to.equal(maxIndex)
			expect(Entity.generation(entity)).to.equal(2)
		end)

		it("supports generation zero", function()
			local entity = Entity.pack(42, 0)

			expect(Entity.index(entity)).to.equal(42)
			expect(Entity.generation(entity)).to.equal(0)
		end)

		it("throws when index is negative", function()
			expect(function()
				Entity.pack(-1, 0)
			end).to.throw()
		end)

		it("throws when index exceeds the maximum", function()
			local maxIndex = 2 ^ 24

			expect(function()
				Entity.pack(maxIndex, 0)
			end).to.throw()
		end)

		it("produces unique ids for different generations", function()
			local a = Entity.pack(100, 0)
			local b = Entity.pack(100, 1)

			expect(a).never.to.equal(b)
		end)

		it("produces unique ids for different indices", function()
			local a = Entity.pack(1, 5)
			local b = Entity.pack(2, 5)

			expect(a).never.to.equal(b)
		end)
	end)
end
