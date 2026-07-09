--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SystemRunner = require(ReplicatedStorage.Lib.SystemRunner)

return function()
	describe("SystemRunner", function()
		local folder: Folder
		local components

		beforeEach(function()
			folder = Instance.new("Folder")
			components = {}
		end)

		afterEach(function()
			folder:Destroy()
		end)

		local function createSystem(name: string, module)
			local m = Instance.new("ModuleScript")
			m.Name = name

			getfenv(require).module = module

			m.Source = [[
				return getfenv(require).module
			]]

			m.Parent = folder

			return m
		end

		it("loads systems", function()
			createSystem("Movement", {})

			local runner = SystemRunner.new(folder, components)

			expect(#runner._systems).to.equal(1)
		end)

		it("sorts by priority", function()
			createSystem("B", {
				Priority = 10,
			})

			createSystem("A", {
				Priority = 1,
			})

			local runner = SystemRunner.new(folder, components)

			expect(runner._systems[1].Name).to.equal("A")
			expect(runner._systems[2].Name).to.equal("B")
		end)

		it("creates update list", function()
			createSystem("Movement", {
				Update = function() end,
			})

			createSystem("Inventory", {})

			local runner = SystemRunner.new(folder, components)

			expect(#runner._updateSystems).to.equal(1)
			expect(runner._updateSystems[1].Name).to.equal("Movement")
		end)

		it("creates late update list", function()
			createSystem("Camera", {
				LateUpdate = function() end,
			})

			local runner = SystemRunner.new(folder, components)

			expect(#runner._lateUpdateSystems).to.equal(1)
		end)

		it("returns systems by name", function()
			local system = {}

			createSystem("Combat", system)

			local runner = SystemRunner.new(folder, components)

			expect(runner:getSystem("Combat")).to.equal(system)
		end)

		it("returns nil for unknown systems", function()
			local runner = SystemRunner.new(folder, components)

			expect(runner:getSystem("Unknown")).to.equal(nil)
		end)

		it("counts systems implementing Update", function()
			createSystem("A", {
				Update = function() end,
			})

			createSystem("B", {
				Update = function() end,
			})

			createSystem("C", {})

			local runner = SystemRunner.new(folder, components)

			expect(runner:countImplementing(SystemRunner.Flag.Update)).to.equal(2)
		end)

		it("counts systems implementing LateUpdate", function()
			createSystem("A", {
				LateUpdate = function() end,
			})

			createSystem("B", {})

			local runner = SystemRunner.new(folder, components)

			expect(runner:countImplementing(SystemRunner.Flag.LateUpdate)).to.equal(1)
		end)

		it("calls Start", function()
			local started = false

			createSystem("Test", {
				Start = function()
					started = true
				end,
			})

			local runner = SystemRunner.new(folder, components)

			runner:start()

			expect(started).to.equal(true)

			runner:stop()
		end)

		it("calls Stop", function()
			local stopped = false

			createSystem("Test", {
				Stop = function()
					stopped = true
				end,
			})

			local runner = SystemRunner.new(folder, components)

			runner:start()
			runner:stop()

			expect(stopped).to.equal(true)
		end)

		it("returns failures", function()
			local runner = SystemRunner.new(folder, components)

			expect(type(runner:getFailures())).to.equal("table")
		end)

		it("update rebuilds update lists", function()
			createSystem("Movement", {
				Update = function() end,
			})

			local runner = SystemRunner.new(folder, components)

			table.clear(runner._updateSystems)

			expect(#runner._updateSystems).to.equal(0)

			runner:update()

			expect(#runner._updateSystems).to.equal(1)
		end)
	end)
end
