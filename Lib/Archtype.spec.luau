local Archetype = require(script.Parent.Archetype)
local Signature = require(script.Parent.Signature)

return function()
	describe("Archetype", function()
		local signature

		beforeEach(function()
			signature = Signature.new()
			Signature.set(signature, 1)
			Signature.set(signature, 2)
		end)

		it("creates an archetype", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			expect(archetype.signature).to.equal(signature)
			expect(#archetype.componentIds).to.equal(2)
			expect(#archetype.entities).to.equal(0)
		end)

		it("knows which components it contains", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			expect(archetype:hasComponent(1)).to.equal(true)
			expect(archetype:hasComponent(2)).to.equal(true)
			expect(archetype:hasComponent(3)).to.equal(false)
		end)

		it("adds entities and returns their row", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			expect(archetype:addEntity(10)).to.equal(1)
			expect(archetype:addEntity(20)).to.equal(2)
			expect(archetype:addEntity(30)).to.equal(3)

			expect(archetype.entities[1]).to.equal(10)
			expect(archetype.entities[2]).to.equal(20)
			expect(archetype.entities[3]).to.equal(30)
		end)

		it("stores and retrieves component values", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			local row = archetype:addEntity(1)

			archetype:setRow(1, row, "Health")
			archetype:setRow(2, row, "Mana")

			expect(archetype:getRow(1, row)).to.equal("Health")
			expect(archetype:getRow(2, row)).to.equal("Mana")
		end)

		it("returns nil for missing component columns", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			expect(archetype:getRow(999, 1)).to.equal(nil)
		end)

		it("removes the last row", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			local row = archetype:addEntity(50)

			archetype:setRow(1, row, "A")
			archetype:setRow(2, row, "B")

			local moved = archetype:removeRow(row)

			expect(moved).to.equal(nil)
			expect(#archetype.entities).to.equal(0)
			expect(archetype:getRow(1, row)).to.equal(nil)
			expect(archetype:getRow(2, row)).to.equal(nil)
		end)

		it("swap-removes entities correctly", function()
			local archetype = Archetype.new(signature, { 1, 2 })

			local row1 = archetype:addEntity(10)
			local row2 = archetype:addEntity(20)
			local row3 = archetype:addEntity(30)

			archetype:setRow(1, row1, "A")
			archetype:setRow(1, row2, "B")
			archetype:setRow(1, row3, "C")

			archetype:setRow(2, row1, 1)
			archetype:setRow(2, row2, 2)
			archetype:setRow(2, row3, 3)

			local moved = archetype:removeRow(2)

			expect(moved).to.equal(30)

			expect(#archetype.entities).to.equal(2)

			expect(archetype.entities[1]).to.equal(10)
			expect(archetype.entities[2]).to.equal(30)

			expect(archetype:getRow(1, 2)).to.equal("C")
			expect(archetype:getRow(2, 2)).to.equal(3)
		end)

		it("clears component values when removing the last row", function()
			local archetype = Archetype.new(signature, { 1 })

			local row = archetype:addEntity(1)

			archetype:setRow(1, row, "Value")

			archetype:removeRow(row)

			expect(archetype.columns[1][1]).to.equal(nil)
		end)
	end)
end
