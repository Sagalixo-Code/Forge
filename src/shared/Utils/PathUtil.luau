--!strict

local PathUtil = {}

function PathUtil.Get(data: { [any]: any }, path: { string }): any
	local current = data

	for _, key in ipairs(path) do
		if typeof(current) ~= "table" then
			return nil
		end

		current = current[key]

		if current == nil then
			return nil
		end
	end

	return current
end

function PathUtil.Set(data: { [any]: any }, path: { string }, value: any): boolean
	local current = data

	for i = 1, #path - 1 do
		local key = path[i]

		if typeof(current) ~= "table" then
			return false
		end

		if current[key] == nil then
			return false
		end

		current = current[key]
	end

	if typeof(current) ~= "table" then
		return false
	end

	current[path[#path]] = value
	return true
end

function PathUtil.Remove(data: { [any]: any }, path: { string }): boolean
	local current = data

	for i = 1, #path - 1 do
		local key = path[i]

		if typeof(current) ~= "table" then
			return false
		end

		current = current[key]

		if current == nil then
			return false
		end
	end

	if typeof(current) ~= "table" then
		return false
	end

	current[path[#path]] = nil
	return true
end

function PathUtil.Exists(data: { [any]: any }, path: { string }): boolean
	return PathUtil.Get(data, path) ~= nil
end

return PathUtil
