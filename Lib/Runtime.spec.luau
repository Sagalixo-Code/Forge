local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Runtime = require(ReplicatedStorage.Lib.Runtime)

return function()
	describe("Runtime", function()
		local callbacks
		local registry
		local runtime

		beforeEach(function()
			callbacks = {}

			registry = {}

			function registry:getStageCallbacks(stage)
				return callbacks[stage] or {}
			end

			runtime = Runtime.new(registry, {})
		end)

		it("creates a new runtime", function()
			expect(runtime).never.to.equal(nil)
			expect(runtime._registry).to.equal(registry)
		end)

		it("runs synchronous stages", function()
			local called = false

			callbacks.Init = {
				function()
					called = true
				end,
			}

			local result = runtime:run("Init", false)

			expect(result:isOk()).to.equal(true)
			expect(called).to.equal(true)
		end)

		it("returns the number of executed callbacks", function()
			callbacks.Init = {
				function() end,
				function() end,
				function() end,
			}

			local result = runtime:run("Init", false)

			expect(result:unwrap()).to.equal(3)
		end)

		it("collects callback errors", function()
			callbacks.Init = {
				function()
					error("boom")
				end,
			}

			local result = runtime:run("Init", false)

			expect(result:isErr()).to.equal(true)
			expect(#result:unwrapOr({})).to.equal(1)
		end)

		it("initializes all init stages", function()
			local count = 0

			callbacks.PreInit = {
				function()
					count += 1
				end,
			}

			callbacks.Init = {
				function()
					count += 1
				end,
			}

			callbacks.PostInit = {
				function()
					count += 1
				end,
			}

			local result = runtime:init()

			expect(result:isOk()).to.equal(true)
			expect(count).to.equal(3)
		end)

		it("returns errors during init", function()
			callbacks.Init = {
				function()
					error("Init failed")
				end,
			}

			local result = runtime:init()

			expect(result:isErr()).to.equal(true)
		end)

		it("starts successfully", function()
			local pre = false

			callbacks.PreStart = {
				function()
					pre = true
				end,
			}

			callbacks.Start = {
				function() end,
			}

			callbacks.PostStart = {
				function() end,
			}

			local result = runtime:start()

			expect(result:isOk()).to.equal(true)
			expect(pre).to.equal(true)
		end)

		it("returns errors during start", function()
			callbacks.PreStart = {
				function()
					error("oops")
				end,
			}

			local result = runtime:start()

			expect(result:isErr()).to.equal(true)
		end)

		it("runs shutdown", function()
			local called = false

			callbacks.Shutdown = {
				function()
					called = true
				end,
			}

			local result = runtime:shutdown()

			expect(result:isOk()).to.equal(true)
			expect(called).to.equal(true)
		end)
	end)
end
