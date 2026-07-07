local Signature = require(script.Parent.Signature)

return function()
	describe("Signature", function()
		it("creates an empty signature", function()
			local signature = Signature.new()

			expect(#signature).to.equal(0)
		end)

		it("sets a component", function()
			local signature = Signature.new()

			Signature.set(signature, 5)

			expect(Signature.has(signature, 5)).to.equal(true)
		end)

		it("sets multiple components", function()
			local signature = Signature.new()

			Signature.set(signature, 1)
			Signature.set(signature, 8)
			Signature.set(signature, 32)
			Signature.set(signature, 120)

			expect(Signature.has(signature, 1)).to.equal(true)
			expect(Signature.has(signature, 8)).to.equal(true)
			expect(Signature.has(signature, 32)).to.equal(true)
			expect(Signature.has(signature, 120)).to.equal(true)
		end)

		it("returns false for missing components", function()
			local signature = Signature.new()

			Signature.set(signature, 3)

			expect(Signature.has(signature, 2)).to.equal(false)
			expect(Signature.has(signature, 4)).to.equal(false)
		end)

		it("unsets a component", function()
			local signature = Signature.new()

			Signature.set(signature, 15)
			Signature.unset(signature, 15)

			expect(Signature.has(signature, 15)).to.equal(false)
		end)

		it("can unset without affecting other components", function()
			local signature = Signature.new()

			Signature.set(signature, 1)
			Signature.set(signature, 2)
			Signature.set(signature, 3)

			Signature.unset(signature, 2)

			expect(Signature.has(signature, 1)).to.equal(true)
			expect(Signature.has(signature, 2)).to.equal(false)
			expect(Signature.has(signature, 3)).to.equal(true)
		end)

		it("contains all components from another signature", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 1)
			Signature.set(a, 2)
			Signature.set(a, 3)

			Signature.set(b, 1)
			Signature.set(b, 3)

			expect(Signature.containsAll(a, b)).to.equal(true)
		end)

		it("does not contain all components", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 1)

			Signature.set(b, 1)
			Signature.set(b, 2)

			expect(Signature.containsAll(a, b)).to.equal(false)
		end)

		it("detects intersections", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 5)
			Signature.set(a, 7)

			Signature.set(b, 7)

			expect(Signature.intersects(a, b)).to.equal(true)
		end)

		it("returns false when signatures do not intersect", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 1)
			Signature.set(b, 2)

			expect(Signature.intersects(a, b)).to.equal(false)
		end)

		it("clones signatures", function()
			local a = Signature.new()

			Signature.set(a, 1)
			Signature.set(a, 50)

			local b = Signature.clone(a)

			expect(Signature.has(b, 1)).to.equal(true)
			expect(Signature.has(b, 50)).to.equal(true)

			Signature.set(b, 100)

			expect(Signature.has(a, 100)).to.equal(false)
			expect(Signature.has(b, 100)).to.equal(true)
		end)

		it("generates identical keys for identical signatures", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 2)
			Signature.set(a, 100)

			Signature.set(b, 2)
			Signature.set(b, 100)

			expect(Signature.key(a)).to.equal(Signature.key(b))
		end)

		it("generates different keys for different signatures", function()
			local a = Signature.new()
			local b = Signature.new()

			Signature.set(a, 2)
			Signature.set(b, 3)

			expect(Signature.key(a)).never.to.equal(Signature.key(b))
		end)

		it("converts a signature to a sorted component list", function()
			local signature = Signature.new()

			Signature.set(signature, 5)
			Signature.set(signature, 1)
			Signature.set(signature, 100)

			local list = Signature.toList(signature)

			expect(#list).to.equal(3)
			expect(list[1]).to.equal(1)
			expect(list[2]).to.equal(5)
			expect(list[3]).to.equal(100)
		end)

		it("supports components across multiple words", function()
			local signature = Signature.new()

			for i = 0, 150 do
				if i % 7 == 0 then
					Signature.set(signature, i)
				end
			end

			for i = 0, 150 do
				expect(Signature.has(signature, i)).to.equal(i % 7 == 0)
			end
		end)

		it("shrinks after removing highest components", function()
			local signature = Signature.new()

			Signature.set(signature, 95)

			expect(#signature).to.be.ok()

			Signature.unset(signature, 95)

			expect(#signature).to.equal(0)
		end)
	end)
end
