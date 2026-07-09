local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forge = require(ReplicatedStorage.Lib.ForgeInit)
local ExampleService = ReplicatedStorage.Shared.Tests.ExampleService

return function()
	describe("Forge", function()
		it("should create a new instance", function()
			local forge = Forge.new()

			expect(forge).to.be.ok()
			expect(forge._runtime).to.equal(nil)
		end)

		it("should expose components table", function()
			local forge = Forge.new()

			expect(type(forge:getComponents())).to.equal("table")
		end)

		it("should bootstrap services", function()
			local forge = Forge.new()

			local folder = Instance.new("Folder")
			ExampleService:Clone().Parent = folder

			forge:bootstrap(folder, {})

			expect(forge._runtime).to.be.ok()
		end)

		it("should error when run is called before bootstrap", function()
			local forge = Forge.new()

			expect(function()
				forge:run()
			end).to.throw()
		end)

		it("should run after bootstrap", function()
			local forge = Forge.new()

			local services = Instance.new("Folder")
			ExampleService:Clone().Parent = services

			local systems = Instance.new("Folder")

			forge:bootstrap(services, {})

			expect(function()
				forge:run(systems)
			end).never.to.throw()
		end)
	end)
end
