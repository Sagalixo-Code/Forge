local Players = game:GetService("Players")
local InterfaceModule = {}
local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("Coins")

function InterfaceModule:Update(Currencie)
	Interface.Frame.TextLabel.Text = Currencie
end

return InterfaceModule
