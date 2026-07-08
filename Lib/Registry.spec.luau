local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.Lib.Registry)
local Flags = require(ReplicatedStorage.Lib.Flags)

return function()
	describe("Registry", function()
		it("registers a service", function()
			local service = {
				Init = function() end,
			}

			Registry:registerService("TestService", service)

			expect(Registry:getService("TestService")).to.equal(service)
		end)

		it("registers a controller", function()
			local controller = {
				Start = function() end,
			}

			Registry:registerController("TestController", controller)

			expect(Registry:getController("TestController")).to.equal(controller)
		end)

		it("returns nil for unknown services", function()
			expect(Registry:getService("DoesNotExist")).to.equal(nil)
		end)

		it("computes flags correctly", function()
			local service = {
				Init = function() end,
				Start = function() end,
			}

			local id = Registry:registerService("FlagService", service)

			local flags = Registry:getFlags("service", id)

			expect(Flags.has(flags, Flags.Init)).to.equal(true)
			expect(Flags.has(flags, Flags.Start)).to.equal(true)
			expect(Flags.has(flags, Flags.PostInit)).to.equal(false)
		end)

		it("stores stage callbacks", function()
			local function init() end

			Registry:registerService("CallbackService", {
				Init = init,
			})

			local callbacks = Registry:getStageCallbacks("Init")

			expect(#callbacks).to.be.greaterThan(0)
			expect(callbacks[#callbacks]).to.equal(init)
		end)

		it("counts implementations", function()
			local service = {
				Start = function() end,
			}

			Registry:registerService("CounterService", service)

			local count = Registry:countImplementing("service", Flags.Start)

			expect(count).to.be.greaterThan(0)
		end)

		it("rejects duplicate service names", function()
			Registry:registerService("DuplicateService", {})

			expect(function()
				Registry:registerService("DuplicateService", {})
			end).to.throw()
		end)
	end)
end
