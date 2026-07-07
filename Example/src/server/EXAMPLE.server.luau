local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ECS = require(ReplicatedStorage.Lib.World)

local MovementSystem = require(script.Parent.Systems.MovementSystem)

local Components = {
	Health = 1,
	Position = 2,
	Velocity = 3,
}

local ENTITY_COUNT = 200000

local World = ECS.new()

World:addSystems({
	MovementSystem,
})

World:startSystems()

local function SpawnEntities(amount: number)
	local start = os.clock()

	for i = 1, amount do
		local entity = World:spawn()

		World:set(entity, Components.Health, 100)

		World:set(entity, Components.Position, Vector3.zero)

		World:set(entity, Components.Velocity, Vector3.one)
	end

	return os.clock() - start
end

local spawnTime = SpawnEntities(ENTITY_COUNT)

print("Entities:", World:count())
print("Spawn time:", spawnTime)
print("Entities/sec:", ENTITY_COUNT / spawnTime)

local frames = 0
local updateTotal = 0
local minUpdate = math.huge
local maxUpdate = 0

RunService.Heartbeat:Connect(function(dt)
	local start = os.clock()

	World:update(dt)

	local elapsed = os.clock() - start

	updateTotal += elapsed
	frames += 1

	if elapsed < minUpdate then
		minUpdate = elapsed
	end

	if elapsed > maxUpdate then
		maxUpdate = elapsed
	end

	if frames >= 120 then
		print("Update Benchmark")
		print("Average:", updateTotal / frames)
		print("Min:", minUpdate)
		print("Max:", maxUpdate)
		print("FPS Cost:", (updateTotal / frames) * 1000, "ms")

		frames = 0
		updateTotal = 0
		minUpdate = math.huge
		maxUpdate = 0
	end
end)
