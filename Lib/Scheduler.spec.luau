local Scheduler = require(script.Parent.Scheduler)

return function()
	describe("Scheduler", function()
		it("creates an empty scheduler", function()
			local scheduler = Scheduler.new()

			expect(#scheduler._systems).to.equal(0)
		end)

		it("schedules a single system", function()
			local scheduler = Scheduler.new()

			local function system() end

			scheduler:scheduleSystem(system)

			expect(#scheduler._systems).to.equal(1)
			expect(scheduler._systems[1]).to.equal(system)
		end)

		it("schedules multiple systems", function()
			local scheduler = Scheduler.new()

			local function a() end
			local function b() end
			local function c() end

			scheduler:scheduleSystems({ a, b, c })

			expect(#scheduler._systems).to.equal(3)
		end)

		it("does not schedule duplicates", function()
			local scheduler = Scheduler.new()

			local function system() end

			scheduler:scheduleSystem(system)
			scheduler:scheduleSystem(system)
			scheduler:scheduleSystems({ system })

			expect(#scheduler._systems).to.equal(1)
		end)

		it("runs function systems", function()
			local scheduler = Scheduler.new()

			local called = false

			local function system(world, dt)
				called = true

				expect(world).to.equal("World")
				expect(dt).to.equal(1 / 60)
			end

			scheduler:scheduleSystem(system)
			scheduler:run("World", 1 / 60)

			expect(called).to.equal(true)
		end)

		it("runs callback table systems", function()
			local scheduler = Scheduler.new()

			local calls = 0

			scheduler:scheduleSystem({
				callbacks = {
					function()
						calls += 1
					end,

					function()
						calls += 1
					end,
				},
			})

			scheduler:run({}, 0)

			expect(calls).to.equal(2)
		end)

		it("increments execution count", function()
			local scheduler = Scheduler.new()

			local function system() end

			scheduler:scheduleSystem(system)

			scheduler:run({}, 0)
			scheduler:run({}, 0)
			scheduler:run({}, 0)

			local state = scheduler._systemState[system]

			expect(state.executionCount).to.equal(3)
		end)

		it("updates lastExecution", function()
			local scheduler = Scheduler.new()

			local function system() end

			scheduler:scheduleSystem(system)

			local before = os.clock()

			scheduler:run({}, 0)

			local state = scheduler._systemState[system]

			expect(state.lastExecution >= before).to.equal(true)
		end)

		it("disable prevents execution", function()
			local scheduler = Scheduler.new()

			local count = 0

			local function system()
				count += 1
			end

			scheduler:scheduleSystem(system)

			scheduler:disable(system)
			scheduler:run({}, 0)

			expect(count).to.equal(0)
		end)

		it("enable resumes execution", function()
			local scheduler = Scheduler.new()

			local count = 0

			local function system()
				count += 1
			end

			scheduler:scheduleSystem(system)

			scheduler:disable(system)
			scheduler:enable(system)

			scheduler:run({}, 0)

			expect(count).to.equal(1)
		end)

		it("preserves scheduling order", function()
			local scheduler = Scheduler.new()

			local order = {}

			local function a()
				table.insert(order, "A")
			end

			local function b()
				table.insert(order, "B")
			end

			local function c()
				table.insert(order, "C")
			end

			scheduler:scheduleSystems({ a, b, c })

			scheduler:run({}, 0)

			expect(order[1]).to.equal("A")
			expect(order[2]).to.equal("B")
			expect(order[3]).to.equal("C")
		end)

		it("stores system names", function()
			local scheduler = Scheduler.new()

			local function TestSystem() end

			scheduler:scheduleSystem(TestSystem)

			expect(scheduler._systemNames[TestSystem]).never.to.equal(nil)
		end)
	end)
end
