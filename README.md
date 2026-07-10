**Forge is a modern Roblox framework inspired by the architecture of Rust, Bevy, ASP.NET Core, and other infrastructure-focused frameworks. Rather than abstracting Roblox APIs, it provides a predictable lifecycle, modular architecture, and type-safe foundation for building scalable and maintainable experiences.**

## Example Bootstrap

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Forge = require(ReplicatedStorage.Lib.ForgeInit).new()

local Components = {}

for _, module in script.Components:GetChildren() do
	Components[module.Name] = require(module)
end

Forge:bootstrap(script.Services, Components)
Forge:run(script.Systems)
```

## Example Service

```lua
local ExampleService = {}

local Internal = script.Parent:WaitForChild("Internal")
local ExampleInternal = require(Internal:WaitForChild("ExampleInternal"))

function ExampleService:PreInit(Component)
	ExampleInternal:ExampleFunction("PreInit")
end

function ExampleService:Init(Component)
	ExampleInternal:ExampleFunction("Init")
end

function ExampleService:PostInit(Component)
	ExampleInternal:ExampleFunction("PostInit")
end

function ExampleService:PlayerAdded(Player, Component)
	ExampleInternal:ExampleFunction("PlayerAdded")
end

function ExampleService:PlayerRemoving(Player, Component)
	ExampleInternal:ExampleFunction("PlayerRemoving")
end

function ExampleService:CharacterAdded(Player, Character, Component)
	ExampleInternal:ExampleFunction("CharacterAdded")
end

function ExampleService:CharacterRemoving(Player, Character, Component)
	ExampleInternal:ExampleFunction("CharacterRemoving")
end

function ExampleService:Shutdown(Component)
	ExampleInternal:ExampleFunction("Shutdown")
end

return ExampleService
```

## Example Internal

```lua
local ExampleInternal = {}

function ExampleInternal:ExampleFunction(msg: string)
	print("ExampleService " .. msg)
end

return ExampleInternal
```
