local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flags = require(ReplicatedStorage.Lib.Flags)

return function()
	describe("Flags", function()
		it("builds the ByName lookup", function()
			for _, stage in Flags.Stages do
				expect(Flags.ByName[stage]).never.to.equal(nil)
			end
		end)

		it("computes an empty mask", function()
			local mask = Flags.computeMask({})

			expect(mask).to.equal(0)
		end)

		it("computes a mask for implemented callbacks", function()
			local mask = Flags.computeMask({
				Init = function() end,
				Start = function() end,
				PlayerAdded = function() end,
			})

			expect(Flags.has(mask, Flags.Init)).to.equal(true)
			expect(Flags.has(mask, Flags.Start)).to.equal(true)
			expect(Flags.has(mask, Flags.PlayerAdded)).to.equal(true)

			expect(Flags.has(mask, Flags.PreInit)).to.equal(false)
			expect(Flags.has(mask, Flags.Shutdown)).to.equal(false)
		end)

		it("ignores non-function values", function()
			local mask = Flags.computeMask({
				Init = true,
				Start = "abc",
				Shutdown = 123,
			})

			expect(mask).to.equal(0)
		end)

		it("contains every flag in Flags.All", function()
			for _, bit in Flags.ByName do
				expect(Flags.has(Flags.All, bit)).to.equal(true)
			end
		end)

		it("returns false for bits that are not present", function()
			local mask = Flags.computeMask({
				Start = function() end,
			})

			expect(Flags.has(mask, Flags.Start)).to.equal(true)
			expect(Flags.has(mask, Flags.Init)).to.equal(false)
			expect(Flags.has(mask, Flags.PlayerAdded)).to.equal(false)
		end)

		it("assigns unique values to every flag", function()
			local seen = {}

			for name, bit in Flags.ByName do
				expect(seen[bit]).to.equal(nil)
				seen[bit] = name
			end
		end)

		it("has the same number of stages as named flags", function()
			local count = 0

			for _ in Flags.ByName do
				count += 1
			end

			expect(count).to.equal(#Flags.Stages)
		end)
	end)
end
