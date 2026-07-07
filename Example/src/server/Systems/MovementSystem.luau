local MovementSystem = {}

function MovementSystem:PreInit(world)
	print("1")
end

function MovementSystem:Init(world)
	print("2")
end

function MovementSystem:Start(world)
	print("3")
end

function MovementSystem:Update(dt, entities)
	for _, entity in ipairs(entities) do
		local position = entity:GetComponent("Position")
		local velocity = entity:GetComponent("Velocity")

		if position and velocity then
			position.x = position.x + velocity.x * dt
			position.y = position.y + velocity.y * dt
		end
	end
end

return MovementSystem
