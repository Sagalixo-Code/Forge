local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CmdrClient = {}

function CmdrClient:Init()
	task.wait(2)

	local cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient", 99))
	cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
end

return CmdrClient
