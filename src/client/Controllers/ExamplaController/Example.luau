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

return ExampleController
