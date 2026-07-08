local ExampleService = {}

function ExampleService:PreInit(Component)
	print("ExampleService PreInit")
end

function ExampleService:Init(Component)
	print("ExampleService Init")
end

function ExampleService:PostInit(Component)
	print("ExampleService PostInit")
end

function ExampleService:PlayerAdded(Player, Component)
	print("ExampleService PlayerAdded")
end

function ExampleService:PlayerRemoving(Player, Component)
	print("ExampleService PlayerRemoving")
end

function ExampleService:CharacterAdded(Player, Character, Component)
	print("ExampleService CharacterAdded")
end

function ExampleService:CharacterRemoving(Player, Character, Component)
	print("ExampleService CharacterRemoving")
end

return ExampleService
