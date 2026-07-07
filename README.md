# KraftECS

An archetype-based Entity Component System for Roblox, focused on performance, scalability, and a simple API.

## Features

- Archetype-based storage
- Bitset signatures
- Column-oriented components
- Automatic archetype migration
- Deferred command buffer
- Fast queries
- Generation-based entity IDs
- Runtime hooks
- Strict Luau

## Example

```lua
local entity = world:spawn()

world:set(entity, Position, Vector3.zero)
world:set(entity, Velocity, Vector3.new(10, 0, 0))

for entity, position, velocity in world:query(Position, Velocity) do
	position += velocity
end
```

## Goals

- High performance
- Low memory overhead
- Clean, predictable API
- Scalable architecture
- Type-safe code

## Status

KraftECS is under active development and the API may change before the first stable release.

## License

MIT
