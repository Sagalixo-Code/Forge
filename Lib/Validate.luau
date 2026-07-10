local Validate = {}

function Validate.system(name: string, module: any)
	local errors = {}
	if typeof(module) ~= "table" then
		table.insert(errors, "Module must be a table")
	else
		if module.Start and typeof(module.Start) ~= "function" then
			table.insert(errors, "Start must be a function")
		end
		if module.Update and typeof(module.Update) ~= "function" then
			table.insert(errors, "Update must be a function")
		end
	end

	return {
		ok = #errors == 0,
		errors = errors,
	}
end

return Validate
