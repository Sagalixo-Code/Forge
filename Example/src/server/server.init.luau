local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ECS = require(ReplicatedStorage.Lib.World)

local Systems = {
	require(script.Parent.Systems.MovementSystem),
}

local World = ECS.new()

local start = os.clock()

World:addSystems(Systems)

for i = 1, 100000 do
	local e = World:spawn()

	World:set(e, "Health", 100)
	World:set(e, "Position", Vector3.zero)
	World:set(e, "Velocity", Vector3.one)

	World:onChange(e, function(entity, componentName, oldValue, newValue)
		if componentName == "Health" then
			print("Entity", entity, "Health changed from", oldValue, "to", newValue)
		end
	end)

	local currentHealth = World:get(e, "Health")
	World:set(e, "Health", currentHealth - 10)
end

World:startSystems()

RunService.Heartbeat:Connect(function(dt)
	World:update(dt)
end)

print("Spawn time:", os.clock() - start)
print("Entities:", World:count())
