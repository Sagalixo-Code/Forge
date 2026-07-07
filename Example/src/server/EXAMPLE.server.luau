local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ECS = require(ReplicatedStorage.Lib.World)

local Systems = {
	require(script.Parent.Systems.MovementSystem),
}
local Components = {
	Health = 1,
	Position = 2,
	Velocity = 3,
}

local frames = 0
local total = 0

local World = ECS.new()

local start = os.clock()

World:addSystems(Systems)
World:startSystems()

for i = 1, 200000 do
	local e = World:spawn()

	World:set(e, Components.Health, 100)
	World:set(e, Components.Position, Vector3.zero)
	World:set(e, Components.Velocity, Vector3.one)

	local currentHealth = World:get(e, Components.Health)
	World:set(e, Components.Health, currentHealth - 10)
end

RunService.Heartbeat:Connect(function(dt)
	local start = os.clock()

	World:update(dt)

	total += os.clock() - start
	frames += 1

	if frames >= 60 then
		print("Average update:", total / frames)

		frames = 0
		total = 0
	end
end)

print("Spawn time:", os.clock() - start)
print("Entities:", World:count())
