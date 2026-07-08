local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SystemRunner = require(ReplicatedStorage.Lib.SystemRunner)

return function()
	describe("SystemRunner", function()
		local function createSystem(name: string, source: string): ModuleScript
			local module = Instance.new("ModuleScript")
			module.Name = name
			module.Source = source
			return module
		end

		it("creates a runner", function()
			local folder = Instance.new("Folder")

			local runner = SystemRunner.new(folder, {})

			expect(runner).never.to.equal(nil)
			expect(#runner._systems).to.equal(0)
			expect(#runner._updateSystems).to.equal(0)
		end)

		it("sorts systems by priority", function()
			local folder = Instance.new("Folder")

			createSystem(
				"B",
				[[
				return { Priority = 10 }
			]]
			).Parent = folder

			createSystem(
				"A",
				[[
				return { Priority = 1 }
			]]
			).Parent = folder

			local runner = SystemRunner.new(folder, {})

			expect(runner._systems[1].Priority).to.equal(1)
			expect(runner._systems[2].Priority).to.equal(10)
		end)

		it("collects update systems", function()
			local folder = Instance.new("Folder")

			createSystem(
				"A",
				[[
				return {
					Update = function() end
				}
			]]
			).Parent = folder

			createSystem(
				"B",
				[[
				return {}
			]]
			).Parent = folder

			local runner = SystemRunner.new(folder, {})

			runner:update()

			expect(#runner._updateSystems).to.equal(1)
		end)

		it("calls Start on every system", function()
			local called = 0

			local runner = setmetatable({
				_systems = {
					{
						Start = function()
							called += 1
						end,
					},
					{
						Start = function()
							called += 1
						end,
					},
				},
				_updateSystems = {},
				_components = {},
			}, SystemRunner)

			runner:start()

			expect(called).to.equal(2)
		end)

		it("calls Stop on every system", function()
			local called = 0

			local runner = setmetatable({
				_systems = {
					{
						Stop = function()
							called += 1
						end,
					},
					{
						Stop = function()
							called += 1
						end,
					},
				},
				_updateSystems = {},
				_components = {},
			}, SystemRunner)

			runner:stop()

			expect(called).to.equal(2)
		end)

		it("ignores systems without Update", function()
			local runner = setmetatable({
				_systems = {
					{},
					{},
				},
				_updateSystems = {},
				_components = {},
			}, SystemRunner)

			runner:update()

			expect(#runner._updateSystems).to.equal(0)
		end)
	end)
end
