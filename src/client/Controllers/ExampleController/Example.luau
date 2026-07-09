local ExampleController = {}

local Internal = script.Parent:WaitForChild("Internal")
local ExampleInternal = require(Internal:WaitForChild("ExampleInternal"))

function ExampleController:PreInit(Component)
	ExampleInternal:ExampleFunction("PreInit")
end

function ExampleController:Init(Component)
	ExampleInternal:ExampleFunction("Init")
end

function ExampleController:PostInit(Component)
	ExampleInternal:ExampleFunction("PostInit")
end

function ExampleController:Shutdown(Component)
	ExampleInternal:ExampleFunction("Shutdown")
end

return ExampleController
