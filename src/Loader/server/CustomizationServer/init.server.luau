local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local slapcodeFolder = ReplicatedStorage:WaitForChild("Slapcode")
local remotes = slapcodeFolder.remotes.CustomizationRemotes
local config = require(slapcodeFolder.Config)
local loader = require(script.AccessoryLoader)
local saving = require(script.CustomizationSaving)
local util = require(slapcodeFolder.CustomizationShared)

if not config.Customization then
	return
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAppearanceLoaded:Connect(function(char)
		local accessories = char.Humanoid:GetAppliedDescription():GetAccessories(true)
		for _, child in char:GetChildren() do
			if child:IsA("Accessory") then
				child:Destroy()
			end
		end
		for _, accessory in accessories do
			local accessoryButCorrectType: loader.accessory = {
				id = accessory.AssetId,
			}
			local guid, meshId, ogTexture = load(player, "Accessory", accessoryButCorrectType)
			remotes.AddAccessoryLabel:FireClient(player, meshId, guid, ogTexture)
		end

		char.ModelStreamingMode = Enum.ModelStreamingMode.Persistent -- fixes a conflict between welds and streaming
		local humanoid: Humanoid = char:WaitForChild("Humanoid")
		humanoid.AutomaticScalingEnabled = false
	end)
end)

remotes.MaxAccessories.OnServerInvoke = function(player: Player): boolean
	local accessories = 0
	for _, child in player.Character:GetChildren() do
		if child:IsA("Accessory") then
			accessories += 1
		end
	end
	return accessories >= config.MaxAccessoryCount
end

remotes.AddGuid.OnServerInvoke = function(player: Player, inst: Instance): string
	return loader.addGuid(inst)
end

function load(player: Player, assetType: string, asset): (string?, string?)
	local success = false
	local char = player.Character
	if assetType == "Accessory" then
		return loader.loadAccessory(asset, char)
	elseif assetType == "Face" then
		loader.loadFace(asset, char)
	elseif assetType == "Shirt" then
		loader.loadShirt(asset, char)
	elseif assetType == "Pants" then
		loader.loadPants(asset, char)
	elseif assetType == "T-Shirt" then
		loader.loadTShirt(asset, char)
	else
		warn("Invalid asset type")
	end
end
remotes.Load.OnServerInvoke = load

remotes.Texture.OnServerInvoke = function(player, accessory: Accessory, texture)
	local textureString = loader.setTexture(accessory, texture)
	return textureString
end

remotes.SetTransparency.OnServerEvent:Connect(function(player, accessory: Accessory, transparency: number)
	loader.setTransparency(accessory, transparency)
end)

remotes.SetWeld.OnServerEvent:Connect(function(player, accessory: Accessory, bodyPartName: string)
	local char = player.Character
	if not char then
		return
	end
	local bodyPart = char:FindFirstChild(bodyPartName)
	if not bodyPart and bodyPart:IsA("BasePart") then
		return
	end
	loader.setWeld(accessory, bodyPart)
end)

remotes.SetSkinColor.OnServerEvent:Connect(function(player, color: Color3)
	loader.setSkinColor(color, player.Character)
end)

remotes.SetCharacterSize.OnServerEvent:Connect(function(player, size: number)
	loader.setCharacterSize(size, player.Character)
end)

remotes.Delete.OnServerEvent:Connect(function(player, guid: string)
	local instance = util.getAccessoryFromGuid(player, guid)
	if not instance then
		warn(`Accessory with GUID {guid} not found`)
		return
	end
	instance:Destroy()
end)

remotes.Save.OnServerInvoke = function(
	player,
	saveName: string,
	accessories: { util.AccessoryInfo },
	name: { util.NameInfo? }
)
	return saving.save(player, saveName, accessories, name)
end

remotes.ListSaves.OnServerInvoke = function(player)
	return saving.getSaves(player)
end

remotes.DeleteSave.OnServerEvent:Connect(function(player, saveName: string)
	saving.deleteSave(player, saveName)
end)

remotes.LoadSave.OnServerEvent:Connect(function(player, saveName: string)
	saving.loadSave(player, saveName)
end)
