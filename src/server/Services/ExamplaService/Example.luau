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

return ExampleService
