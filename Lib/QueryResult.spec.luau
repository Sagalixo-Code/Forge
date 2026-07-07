local QueryResult = require(script.Parent.QueryResult)
local Signature = require(script.Parent.Signature)

return function()
	describe("QueryResult", function()
		local function createArchetype(signature, entities, columns)
			return {
				signature = signature,
				componentIds = {},
				entities = entities,
				getRow = function(_, componentId, row)
					local column = columns[componentId]

					if not column then
						return nil
					end

					return column[row]
				end,
			}
		end

		it("iterates entities without components", function()
			local signature = Signature.new()

			local archetype = createArchetype(signature, { 10, 20, 30 }, {})

			local query = QueryResult.new({ archetype }, {})

			expect(({ query() })[1]).to.equal(10)
			expect(({ query() })[1]).to.equal(20)
			expect(({ query() })[1]).to.equal(30)
			expect(({ query() })[1]).to.equal(nil)
		end)

		it("returns component values", function()
			local signature = Signature.new()
			Signature.set(signature, 1)
			Signature.set(signature, 2)

			local archetype = createArchetype(signature, { 1, 2 }, {
				[1] = { "HealthA", "HealthB" },
				[2] = { "ManaA", "ManaB" },
			})

			local query = QueryResult.new({ archetype }, { 1, 2 })

			do
				local entity, health, mana = query()

				expect(entity).to.equal(1)
				expect(health).to.equal("HealthA")
				expect(mana).to.equal("ManaA")
			end

			do
				local entity, health, mana = query()

				expect(entity).to.equal(2)
				expect(health).to.equal("HealthB")
				expect(mana).to.equal("ManaB")
			end
		end)

		it("skips archetypes filtered by without()", function()
			local signatureA = Signature.new()
			Signature.set(signatureA, 1)

			local signatureB = Signature.new()
			Signature.set(signatureB, 1)
			Signature.set(signatureB, 2)

			local archetypeA = createArchetype(signatureA, { 1 }, {
				[1] = { "A" },
			})

			local archetypeB = createArchetype(signatureB, { 2 }, {
				[1] = { "B" },
				[2] = { "Extra" },
			})

			local query = QueryResult.new({ archetypeA, archetypeB }, { 1 }):without(2)

			local entity, value = query()

			expect(entity).to.equal(1)
			expect(value).to.equal("A")

			expect(({ query() })[1]).to.equal(nil)
		end)

		it("returns nil after exhausting all archetypes", function()
			local signature = Signature.new()

			local archetype = createArchetype(signature, { 5 }, {})

			local query = QueryResult.new({ archetype }, {})

			query()

			expect(({ query() })[1]).to.equal(nil)
			expect(({ query() })[1]).to.equal(nil)
		end)
	end)
end
