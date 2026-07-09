local PluginManager = require(script.Parent.PluginManager)

return function()
	describe("PluginManager", function()
		it("should create a plugin manager instance", function()
			local manager = PluginManager.new()

			expect(manager).to.be.ok()
			expect(manager._plugins).to.be.ok()
		end)

		it("should register a plugin", function()
			local manager = PluginManager.new()

			local plugin = {

				Name = "TestPlugin",

				Hooks = {},
			}

			local result = manager:Register(plugin)

			expect(result).to.be.ok()
			expect(manager._plugins.TestPlugin).to.equal(plugin)
		end)

		it("should reject duplicated plugins", function()
			local manager = PluginManager.new()

			local plugin = {

				Name = "TestPlugin",

				Hooks = {},
			}

			manager:Register(plugin)

			local result = manager:Register(plugin)

			expect(result.ok).to.equal(false)
		end)

		it("should execute registered hooks", function()
			local manager = PluginManager.new()

			local executed = false

			manager:Register({

				Name = "HookPlugin",

				Hooks = {

					onInit = function()
						executed = true
					end,
				},
			})

			local result = manager:dispatch("onInit")

			expect(result.ok).to.equal(true)
			expect(executed).to.equal(true)
		end)

		it("should execute hooks with arguments", function()
			local manager = PluginManager.new()

			local receivedValue

			manager:Register({

				Name = "ArgumentPlugin",

				Hooks = {

					onStart = function(value)
						receivedValue = value
					end,
				},
			})

			manager:dispatch("onStart", 123)

			expect(receivedValue).to.equal(123)
		end)

		it("should execute middleware in order", function()
			local manager = PluginManager.new()

			local order = {}

			manager:Register({

				Name = "MiddlewareA",

				Hooks = {},

				Middleware = function(stage, next)
					table.insert(order, "A_before")

					local result = next(stage)

					table.insert(order, "A_after")

					return result
				end,
			})

			manager:Register({

				Name = "MiddlewareB",

				Hooks = {},

				Middleware = function(stage, next)
					table.insert(order, "B_before")

					local result = next(stage)

					table.insert(order, "B_after")

					return result
				end,
			})

			manager:wrapStage("Init", function()
				table.insert(order, "Stage")

				return {
					ok = true,
				}
			end)

			expect(order[1]).to.equal("A_before")
			expect(order[2]).to.equal("B_before")
			expect(order[3]).to.equal("Stage")
			expect(order[4]).to.equal("B_after")
			expect(order[5]).to.equal("A_after")
		end)

		it("should catch hook errors", function()
			local manager = PluginManager.new()

			manager:Register({

				Name = "BrokenPlugin",

				Hooks = {

					onInit = function()
						error("failed")
					end,
				},
			})

			local result = manager:dispatch("onInit")

			expect(result.ok).to.equal(false)
		end)
	end)
end
