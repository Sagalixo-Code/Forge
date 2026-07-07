local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Scheduler = require(ReplicatedStorage.Shared.Utils.Scheduler)
local World = require(script.Parent.World)
return function()
	describe("World", function()
		it("create entity and add component", function()
			local world = World.new()
			local entity = world:CreateEntity()

			local HealthComponent = world:RegisterComponent("Health")
			HealthComponent:Set(entity, 100)

			Scheduler:Every(1, function()
				HealthComponent:Update(entity, function(old)
					return old + 100
				end)
			end)
		end)
	end)
end
