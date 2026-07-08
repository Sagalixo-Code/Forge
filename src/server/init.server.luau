local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forge = require(ReplicatedStorage.Lib.ForgeInit).new()
local TestEZ = require(ReplicatedStorage.Packages.TestEZ)

local Components = {}

for _, module in script.Components:GetChildren() do
	Components[module.Name] = require(module)
end

TestEZ.TestBootstrap:run(ReplicatedStorage.Lib:GetChildren(), nil, { noXpcallByDefault = true })

Forge:bootstrap(script.Services, Components)
Forge:run(script.Systems)
