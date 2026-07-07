--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const coreflex = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CoreFlex")
const logger = require(ReplicatedStorage.Shared.Utils.Logger)
const Components = {}

const SafeRequire_LOG = logger.new("SafeRequire")
SafeRequire_LOG:SetLevel(logger.Levels.DEBUG)

const function safeRequire(module)
	local success, result = pcall(require, module)
	if success then
		return result
	else
		SafeRequire_LOG:Debug("Failed to require module:", module.Name, "Error:", result)
		return nil
	end
end

for _, module in script.Parent.Components:GetChildren() do
	if module:IsA("ModuleScript") then
		Components[module.Name] = safeRequire(module)
	elseif module:IsA("Folder") then
		Components[module.Name] = {}

		for _, folderChildrens in ipairs(module:GetChildren()) do
			if folderChildrens:IsA("ModuleScript") then
				Components[module.Name][folderChildrens.Name] = safeRequire(folderChildrens)
			end
		end
	end
end

const Loader = safeRequire(coreflex.Loader)

local module = {}

function module:bootstrap()
	Loader:Init(script.Parent.Services, Components)
end

return module
