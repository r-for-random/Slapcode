local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local slapcodeFolder = game:GetService("ReplicatedStorage"):WaitForChild("Slapcode")
local loader = require(script.Parent.AccessoryLoader)
local util = require(slapcodeFolder.CustomizationShared)
local remotes = slapcodeFolder.remotes.CustomizationRemotes
local nameRemotes = slapcodeFolder.remotes.NameRemotes

local scope = if game:GetService("RunService"):IsStudio() then "Studio" else "Live"
local datastore = DataStoreService:GetDataStore("SlapcodeSaves", scope)

local saving = {}

type SaveData = {
	["Name"]: { util.NameInfo? },
	["CharSize"]: number,
	["Accessories"]: { util.AccessoryInfo },
	["Face"]: string,
	["TShirt"]: string,
	["Shirt"]: string,
	["Pants"]: string,
	["BodyColors"]: { [string]: util.Dim3 },
}

local bodyPartNames: { string } = {
	"Head",
	"Torso",
	"Left Arm",
	"Right Arm",
	"Left Leg",
	"Right Leg",
}

local function getBodyColors(character: Model): { [string]: util.Dim3 }
	local colors: { [string]: util.Dim3 } = {}
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		local bodyParts: { Part } = {}
		for _, child in character:GetChildren() do
			if child:IsA("Part") and table.find(bodyPartNames, child.Name) then
				table.insert(bodyParts, child)
			end
		end

		for _, bodyPart in bodyParts do
			colors[bodyPart.Name] = util.convertColor3ToDim3(bodyPart.Color)
		end
	else
		colors = {
			["Head"] = util.convertColor3ToDim3(bodyColors.HeadColor3),
			["Torso"] = util.convertColor3ToDim3(bodyColors.TorsoColor3),
			["Left Arm"] = util.convertColor3ToDim3(bodyColors.LeftArmColor3),
			["Right Arm"] = util.convertColor3ToDim3(bodyColors.RightArmColor3),
			["Left Leg"] = util.convertColor3ToDim3(bodyColors.LeftLegColor3),
			["Right Leg"] = util.convertColor3ToDim3(bodyColors.RightLegColor3),
		}
	end
	return colors
end

local function setBodyColors(colors: { [string]: util.Dim3 }, character: Model)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		local bodyParts: { Part } = {}
		for _, child in character:GetChildren() do
			if child:IsA("Part") and table.find(bodyPartNames, child.Name) then
				table.insert(bodyParts, child)
			end
		end

		for _, bodyPart in bodyParts do
			bodyPart.Color = util.convertDim3ToColor3(colors[bodyPart.Name])
		end
	else
		bodyColors.HeadColor3 = util.convertDim3ToColor3(colors["Head"])
		bodyColors.TorsoColor3 = util.convertDim3ToColor3(colors["Torso"])
		bodyColors.LeftArmColor3 = util.convertDim3ToColor3(colors["Left Arm"])
		bodyColors.RightArmColor3 = util.convertDim3ToColor3(colors["Right Arm"])
		bodyColors.LeftLegColor3 = util.convertDim3ToColor3(colors["Left Leg"])
		bodyColors.RightLegColor3 = util.convertDim3ToColor3(colors["Right Leg"])
	end
end

local function getMatchingAccessory(accessory: Instance, match: { util.AccessoryInfo }): util.AccessoryInfo?
	for _, accessoryInfo in match do
		if not accessoryInfo.Instance then
			return
		end
		if accessory == accessoryInfo.Instance then
			return accessoryInfo
		end
	end
	return
end

local function newSaveData(
	character: Model,
	clientAccessories: { util.AccessoryInfo },
	clientName: { util.NameInfo? }
): SaveData
	local tShirt = character:FindFirstChildOfClass("ShirtGraphic")
	local shirt = character:FindFirstChildWhichIsA("Shirt")
	local pants = character:FindFirstChildWhichIsA("Pants")
	local face = character:FindFirstChild("Head"):FindFirstChildWhichIsA("Decal")

	local saveData: SaveData = {
		["Name"] = clientName,
		["CharSize"] = character:GetScale(),
		["Accessories"] = {},
		["Face"] = if face then face.Texture else "",
		["TShirt"] = if tShirt then tShirt.Graphic else "",
		["Shirt"] = if shirt then shirt.ShirtTemplate else "",
		["Pants"] = if pants then pants.PantsTemplate else "",
		["BodyColors"] = getBodyColors(character),
	}

	for _, accessory in character:GetChildren() do
		if not accessory:IsA("Accessory") then
			continue
		end
		local matchingAccessory = getMatchingAccessory(accessory, clientAccessories)
		local handle = accessory:FindFirstChild("Handle")
		if not handle then
			continue
		end
		local mesh = handle:FindFirstChildOfClass("SpecialMesh")
		local weld = handle:FindFirstChildOfClass("Weld")
		local attachment = handle:FindFirstChildOfClass("Attachment")
		if not mesh or not weld or not attachment then
			continue
		end

		local meshId
		if matchingAccessory then
			meshId = matchingAccessory.MeshId
		else
			meshId = mesh.MeshId
		end

		local rx, ry, rz = weld.C1:ToEulerAnglesXYZ()
		local x0, y0, z0 = weld.C0:ToEulerAnglesXYZ()

		local accessoryInfo: util.AccessoryInfo = {
			Name = if matchingAccessory then matchingAccessory.Name else accessory.Name,
			MeshId = meshId,
			MarketplaceTextureId = if matchingAccessory then matchingAccessory.MarketplaceTextureId else mesh.TextureId,
			TextureId = mesh.TextureId,
			Position = util.convertVector3ToDim3(weld.C1.Position),
			Rotation = {
				x = math.deg(rx),
				y = math.deg(ry),
				z = math.deg(rz),
			},
			Scale = util.convertVector3ToDim3(mesh.Scale),
			Size = util.convertVector3ToDim3(handle.Size),
			Transparency = handle.Transparency,
			WeldedPart = weld.Part1.Name,
			AttachmentName = attachment.Name,
			AttachmentPosition = util.convertVector3ToDim3(attachment.Position),
			AttachmentOrientation = util.convertVector3ToDim3(attachment.Orientation),
			P0 = util.convertVector3ToDim3(weld.C0.Position),
			R0 = { x = x0, y = y0, z = z0 },
		}
		table.insert(saveData.Accessories, accessoryInfo)
	end

	return saveData
end

function saving.save(
	player: Player,
	saveName: string,
	clientAccessories: { util.AccessoryInfo },
	clientName: { util.NameInfo? }
): boolean
	local char = player.Character
	if not char then
		return false
	end

	local saves = saving.getSaves(player)
	local saveData = newSaveData(char, clientAccessories, clientName)

	local success, errorMessage = pcall(function()
		datastore:SetAsync(`{player.UserId}/{saveName}`, HttpService:JSONEncode(saveData), { player.UserId })
	end)
	if success then
		if not table.find(saves, saveName) then
			table.insert(saves, saveName)
		end -- adds to cache
		return true
	else
		warn(errorMessage)
		return false
	end
end

local savesCache: { [string]: { string } } = {}

local function getKeys(keys: DataStoreKeyPages, userId: string): { string }
	while true do
		for _, key: DataStoreKey in keys:GetCurrentPage() do
			table.insert(savesCache[userId], string.match(key.KeyName, `{userId}/(.+)`))
		end

		if keys.IsFinished then
			break
		end
		keys:AdvanceToNextPageAsync()
	end
	return savesCache[userId]
end

local function listKeysAsync(userId: string): { string }
	if not savesCache[userId] then
		savesCache[userId] = {}
	end
	local success, keys = pcall(function()
		return datastore:ListKeysAsync(`{userId}/`, 100, "", true)
	end)
	while not success do
		warn(
			`Slapcode: Error getting the datastore keys for customization saves. If you're in Studio, enable Studio Access to Datastores and try again. If you aren't, tough luck.`
		)
		task.wait(20)
		success, keys = pcall(function()
			return datastore:ListKeysAsync(`{userId}/`, 100, "", true)
		end)
	end
	return getKeys(keys, userId)
end

function saving.getSaves(player: Player): { string }
	local userId = tostring(player.UserId)
	if savesCache[userId] then
		return savesCache[userId]
	else
		return listKeysAsync(userId)
	end
end

function saving.deleteSave(player: Player, saveName: string)
	local saves = saving.getSaves(player)
	local saveIndex = table.find(saves, saveName)
	if not saveIndex then
		return
	end

	local success, errorMessage = pcall(function()
		datastore:RemoveAsync(`{player.UserId}/{saveName}`)
	end)
	if success then
		table.remove(saves, saveIndex)
	else
		warn(errorMessage)
	end
end

local function applySave(player: Player, save: SaveData)
	local character = player.Character
	if not character then
		return
	end

	character:ScaleTo(save.CharSize)

	if save.Face:len() > 0 then
		loader.loadFace(save.Face, character)
	end

	if save.TShirt:len() > 0 then
		loader.loadTShirt(save.TShirt, character)
	end

	if save.Shirt:len() > 0 then
		loader.loadShirt(save.Shirt, character)
	end

	if save.Pants:len() > 0 then
		loader.loadPants(save.Pants, character)
	end

	setBodyColors(save.BodyColors, character)

	for _, accessory in character:GetChildren() do
		if accessory:IsA("Accessory") then
			accessory:Destroy()
		end
	end

	for _, accessory in save.Accessories do
		if not accessory.AttachmentName or not accessory.AttachmentPosition or not accessory.AttachmentOrientation then
			continue
		end

		local newAccessory = Instance.new("Accessory")
		newAccessory.Name = accessory.Name

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = util.convertDim3ToVector3(accessory.Scale)
		handle.Transparency = if accessory.Transparency then accessory.Transparency else 0
		handle.Anchored = false
		handle.CanCollide = false
		handle.Parent = newAccessory

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.FileMesh
		mesh.Name = "SpecialMesh"
		mesh.MeshId = accessory.MeshId
		mesh.TextureId = accessory.TextureId
		mesh.Scale = util.convertDim3ToVector3(accessory.Scale)
		if not util.isHeadAccessory(accessory.AttachmentName) then
			mesh.Scale = mesh.Scale * 1 / save.CharSize
		end
		mesh.Parent = handle

		local attachment = Instance.new("Attachment")
		attachment.Name = accessory.AttachmentName
		attachment.Position = util.convertDim3ToVector3(accessory.AttachmentPosition)
		attachment.Orientation = util.convertDim3ToVector3(accessory.AttachmentOrientation)
		attachment.Parent = handle

		newAccessory.Parent = character

		task.defer(function()
			local weld = handle:FindFirstChildWhichIsA("Weld")
			if not weld then
				return
			end
			if accessory.WeldedPart then
				local bodyPart = character:FindFirstChild(accessory.WeldedPart)
				if bodyPart and bodyPart:IsA("BasePart") then
					weld.Part1 = bodyPart
				end
			end

			weld.C1 = CFrame.new(util.convertDim3ToVector3(accessory.Position))
				* CFrame.fromOrientation(
					math.rad(accessory.Rotation.x),
					math.rad(accessory.Rotation.y),
					math.rad(accessory.Rotation.z)
				)
			weld.C0 = CFrame.new(util.convertDim3ToVector3(accessory.P0))
				* CFrame.fromEulerAnglesXYZ(accessory.R0.x, accessory.R0.y, accessory.R0.z)
			weld.Parent = handle

			if accessory.Size then
				handle.Size = util.convertDim3ToVector3(accessory.Size)
			else
				local originalSize = handle:FindFirstChildWhichIsA("Vector3Value")
				if originalSize then
					handle.Size = originalSize.Value
				end
			end

			local guid = loader.addGuid(newAccessory)
			task.wait(0.2)
			remotes.AddAccessoryLabel:FireClient(player, mesh.MeshId, guid, mesh.TextureId)
		end)
	end

	if save.Name and nameRemotes and nameRemotes.UpdateNametag then
		nameRemotes.UpdateNametag:FireAllClients(player, save.Name)
	end
end

function saving.loadSave(player: Player, saveName: string)
	local success, save = pcall(function()
		local options = Instance.new("DataStoreGetOptions")
		options.UseCache = false
		return datastore:GetAsync(`{player.UserId}/{saveName}`, options)
	end)
	if not success then
		warn(save)
		return
	end

	applySave(player, HttpService:JSONDecode(save))
end

return saving
