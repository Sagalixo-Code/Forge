local HttpService = game:GetService("HttpService")
local module = {}

function module.forEach(tbl: { [any]: any }, callback: (value: any, key: any) -> ())
	for key, value in pairs(tbl) do
		task.spawn(callback, value, key)
	end
end

function module.tableToString<T>(tbl: { T }): string?
	if type(tbl) ~= "table" then
		return
	end

	local success, result = pcall(function()
		return HttpService:JSONEncode(tbl)
	end)

	if not success then
		return
	end

	return result
end

function module.stringToTable(str)
	if type(str) ~= "string" or str == "" then
		return {}
	end

	local success, result = pcall(function()
		return HttpService:JSONDecode(str)
	end)

	if not success then
		return {}
	end

	return result
end

return module
