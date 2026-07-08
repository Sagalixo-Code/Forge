local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forge = require(ReplicatedStorage.Lib.ForgeInit).new()

local Components = {}

for _, module in script.Components:GetChildren() do
	Components[module.Name] = require(module)
end

Forge:bootstrap(script.Controllers, Components)
Forge:run(script.UI)
