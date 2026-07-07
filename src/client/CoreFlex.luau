const Players = game:GetService("Players")
const ReplicatedStorage = game:GetService("ReplicatedStorage")
const coreflex = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreFlex")
const storage = {
}

local function safeRequire(module)
	local success, result = pcall(require, module)
	if success then
		return result
	else
		warn("Failed to require module:", module.Name, "Error:", result)
		return nil
	end
end

for _, module in script.Parent.Storage:GetChildren() do
	if module:IsA("ModuleScript") then
		storage[module.Name] = safeRequire(module)
	end
end

local Components = {
	Loader = safeRequire(coreflex:WaitForChild("Loader")),
}

Players.PlayerAdded:Connect(function()
	print(tick())
end)

local module = {}

function module:bootstrap()
	Components.Loader:Init(script.Parent.Controllers, storage)
end

return module
