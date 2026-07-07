local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InventoryUI = {}

local Interface = Players.LocalPlayer.PlayerGui:WaitForChild("Inventory") :: ScreenGui & {
	Main: Frame & {
		ScrollingFrame: ScrollingFrame & {
			Template: Frame & {
				ItemName: TextLabel,
			},
		},
	},
}

InventoryUI.isOpenned = false
InventoryUI._template = Interface.Main.ScrollingFrame.Template
InventoryUI._cachedsItems = {}
InventoryUI._first = true

local tableUtils = require(ReplicatedStorage.Shared.Utils.Table)

function InventoryUI:Open()
	Interface.Main.Position = UDim2.new(0.5, 0, 1.25, 0)
	Interface.Main.Rotation = -13.5

	TweenService:Create(Interface.Main, TweenInfo.new(1, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Rotation = 0,
	}):Play()

	Interface.Enabled = true
	InventoryUI.isOpenned = true
end

function InventoryUI:Close()
	Interface.Main.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(Interface.Main, TweenInfo.new(0.47, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
		Position = UDim2.new(0.5, 0, 1.3, 0),
	}):Play()

	task.delay(0.43, function()
		Interface.Enabled = false
	end)

	InventoryUI.isOpenned = false
end

function InventoryUI:CreateItemFrame(receiveItemName)
	if self._cachedsItems[receiveItemName] then
		return
	end

	local newInvetoryItem = self._template:Clone()
	newInvetoryItem.Parent = self._template.Parent
	newInvetoryItem.Visible = true
	newInvetoryItem.ItemName.Text = tostring(receiveItemName)

	self._cachedsItems[receiveItemName] = newInvetoryItem
end

function InventoryUI:Create(inventoryInStringFormat)
	local inventoryInTableFormat = tableUtils.stringToTable(inventoryInStringFormat)
	if self._first then
		self._first = false
		for _, itemName in ipairs(inventoryInTableFormat) do
			self:CreateItemFrame(tostring(itemName))
		end

		return
	end

	local lastIndex = #inventoryInTableFormat
	local currentItem = inventoryInTableFormat[lastIndex]

	self:CreateItemFrame(tostring(currentItem))
end

function InventoryUI:Remove(itemName)
	if self.__cachedsItems[itemName] then
		self.__cachedsItems[itemName]:Destroy()
		self.__cachedsItems[itemName] = nil
	end
end

return InventoryUI
