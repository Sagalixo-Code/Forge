local Scheduler = require(script.Parent.Scheduler)

return function()
	describe("Scheduler", function()
		it("creates an empty scheduler", function()
			local scheduler = Scheduler.new()

			expect(#scheduler._systems).to.equal(0)
			expect(#scheduler._updateSystems).to.equal(0)
		end)

		it("schedules a single system", function()
			local scheduler = Scheduler.new()

			local system = {}

			scheduler:scheduleSystem(system)

			expect(#scheduler._systems).to.equal(1)
			expect(scheduler._systems[1]).to.equal(system)
		end)

		it("schedules multiple systems", function()
			local scheduler = Scheduler.new()

			local a = {}
			local b = {}
			local c = {}

			scheduler:scheduleSystems({
				a,
				b,
				c,
			})

			expect(#scheduler._systems).to.equal(3)
		end)

		it("does not schedule duplicates", function()
			local scheduler = Scheduler.new()

			local system = {}

			scheduler:scheduleSystem(system)
			scheduler:scheduleSystem(system)

			expect(#scheduler._systems).to.equal(1)
		end)

		it("registers update systems", function()
			local scheduler = Scheduler.new()

			local system = {}

			function system:Update() end

			scheduler:scheduleSystem(system)

			expect(#scheduler._updateSystems).to.equal(1)
			expect(scheduler._updateSystems[1].system).to.equal(system)
		end)

		it("runs lifecycle hooks", function()
			local scheduler = Scheduler.new()

			local calls = {}

			local system = {}

			function system:PreInit()
				table.insert(calls, "PreInit")
			end

			function system:Init()
				table.insert(calls, "Init")
			end

			function system:Start()
				table.insert(calls, "Start")
			end

			scheduler:scheduleSystem(system)

			scheduler:initialize({})

			expect(calls[1]).to.equal("PreInit")
			expect(calls[2]).to.equal("Init")
			expect(calls[3]).to.equal("Start")
		end)

		it("updates systems", function()
			local scheduler = Scheduler.new()

			local called = false

			local system = {}

			function system:Update(world, dt)
				called = true

				expect(world).to.equal("World")
				expect(dt).to.equal(1 / 60)
			end

			scheduler:scheduleSystem(system)

			scheduler:update("World", 1 / 60)

			expect(called).to.equal(true)
		end)

		it("increments execution count", function()
			local scheduler = Scheduler.new()

			local system = {}

			function system:Update() end

			scheduler:scheduleSystem(system)

			scheduler:update({}, 0)
			scheduler:update({}, 0)
			scheduler:update({}, 0)

			local state = scheduler._systemState[system]

			expect(state.executionCount).to.equal(3)
		end)

		it("updates lastExecution", function()
			local scheduler = Scheduler.new()

			local system = {}

			function system:Update() end

			scheduler:scheduleSystem(system)

			local before = os.clock()

			scheduler:update({}, 0)

			local state = scheduler._systemState[system]

			expect(state.lastExecution >= before).to.equal(true)
		end)

		it("disable prevents update", function()
			local scheduler = Scheduler.new()

			local count = 0

			local system = {}

			function system:Update()
				count += 1
			end

			scheduler:scheduleSystem(system)

			scheduler:disable(system)

			scheduler:update({}, 0)

			expect(count).to.equal(0)
		end)

		it("enable resumes update", function()
			local scheduler = Scheduler.new()

			local count = 0

			local system = {}

			function system:Update()
				count += 1
			end

			scheduler:scheduleSystem(system)

			scheduler:disable(system)
			scheduler:enable(system)

			scheduler:update({}, 0)

			expect(count).to.equal(1)
		end)

		it("preserves update order", function()
			local scheduler = Scheduler.new()

			local order = {}

			local a = {}

			function a:Update()
				table.insert(order, "A")
			end

			local b = {}

			function b:Update()
				table.insert(order, "B")
			end

			local c = {}

			function c:Update()
				table.insert(order, "C")
			end

			scheduler:scheduleSystems({
				a,
				b,
				c,
			})

			scheduler:update({}, 0)

			expect(order[1]).to.equal("A")
			expect(order[2]).to.equal("B")
			expect(order[3]).to.equal("C")
		end)

		it("stores system state", function()
			local scheduler = Scheduler.new()

			local system = {}

			scheduler:scheduleSystem(system)

			local state = scheduler._systemState[system]

			expect(state).never.to.equal(nil)
			expect(state.enabled).to.equal(true)
			expect(state.executionCount).to.equal(0)
		end)
	end)
end
