local Validate = {}

function Validate.system(name: string, module: any)
	local errors = {}
	if type(module) ~= "table" then
		table.insert(errors, "Module must be a table")
	else
		if module.Start and type(module.Start) ~= "function" then
			table.insert(errors, "Start must be a function")
		end
		if module.Update and type(module.Update) ~= "function" then
			table.insert(errors, "Update must be a function")
		end
	end

	return {
		ok = #errors == 0,
		errors = errors,
	}
end

return Validate
