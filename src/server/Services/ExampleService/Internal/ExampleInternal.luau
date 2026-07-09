local ExampleInternal = {}

function ExampleInternal:ExampleFunction(msg: string)
	print("ExampleService " .. msg)
end

return ExampleInternal
