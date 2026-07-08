local ExampleController = {}

function ExampleController:PreInit(Component)
	print("ExampleController PreInit")
end

function ExampleController:Init(Component)
	print("ExampleController Init")
end

function ExampleController:PostInit(Component)
	print("ExampleController PostInit")
end

function ExampleController:PlayerAdded(Player, Component)
	print("ExampleController PlayerAdded")
end

function ExampleController:PlayerRemoving(Player, Component)
	print("ExampleController PlayerRemoving")
end

function ExampleController:CharacterAdded(Player, Character, Component)
	print("ExampleController CharacterAdded")
end

function ExampleController:CharacterRemoving(Player, Character, Component)
	print("ExampleController CharacterRemoving")
end

return ExampleController
