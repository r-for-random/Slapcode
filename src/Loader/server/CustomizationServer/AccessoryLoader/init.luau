local CustomizationLoader = {}
local AssetService = game:GetService("AssetService")
local HttpService = game:GetService("HttpService")
local InsertService = game:GetService("InsertService")
local MarketplaceService = game:GetService("MarketplaceService")

local slapcodeFolder = game:GetService("ReplicatedStorage"):WaitForChild("Slapcode")
local bounding = require(slapcodeFolder.Bounding)
local config = require(slapcodeFolder.Config)

local mac = require(script.MeshAccessoryCreator)

export type accessory = { id: number, texture: number? }

local productInfoCache: { [number]: { [string]: any } } = {}

local ACCEPTED_ACCESORY_TYPES = { -- these are the types of accessories, from like back to shoulder to whatever
	Enum.AssetType:FromValue(41),
	Enum.AssetType:FromValue(42),
	Enum.AssetType:FromValue(43),
	Enum.AssetType:FromValue(44),
	Enum.AssetType:FromValue(45),
	Enum.AssetType:FromValue(46),
	Enum.AssetType:FromValue(47),
	Enum.AssetType:FromValue(8),
	Enum.AssetType:FromValue(4),
}

local function validateNum(num: number): boolean
	return num == num and math.abs(num) ~= math.huge
end

local function getVectorRatio(v: Vector3): Vector3
	local largest: number = math.max(v.X, v.Y, v.Z)
	return Vector3.new(v.X / largest, v.Y / largest, v.Z / largest)
end

-- Adds a GUID attribute to an instance and returns the GUID string
function CustomizationLoader.addGuid(inst: Instance): string
	local guid = HttpService:GenerateGUID(false)
	inst:SetAttribute("GUID", guid)
	return guid
end

function CustomizationLoader.getAssetType(id: number): Enum.AssetType?
	if not id then
		return nil
	end
	local productInfo = productInfoCache[id]

	if not productInfo then
		local success, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.Asset)
		end)
		if not success then
			warn(productInfo)
			return nil
		end
		productInfoCache[id] = info
		productInfo = info
	end

	local assetTypeId = productInfo.AssetTypeId
	local assetType = Enum.AssetType:FromValue(assetTypeId :: number)

	return assetType
end

-- Returns the image URI from a decal, image, shirt, pants, or t-shirt asset ID, or returns nil if it's not one of those types
function CustomizationLoader.getImageId(id: number): string?
	local assetType = CustomizationLoader.getAssetType(id)

	if assetType == Enum.AssetType.Image then
		return `rbxassetid://{id}`
	end

	local loadedAsset = InsertService:LoadAsset(id)
	local child = loadedAsset:GetChildren()[1]
	local imageId: string = nil

	if child:IsA("Decal") then
		imageId = child.Texture
	elseif child:IsA("Shirt") then
		imageId = child.ShirtTemplate
	elseif child:IsA("Pants") then
		imageId = child.PantsTemplate
	elseif child:IsA("ShirtGraphic") then
		imageId = child.Graphic
	end

	loadedAsset:Destroy()
	return imageId
end

-- Loads an accessory (exported type) onto a character and gives it a GUID, returning the GUID and marketplace texture URI
function CustomizationLoader.loadAccessory(accessory: accessory, character: Model): (string, string, string)
	local id = accessory.id

	local assetType = CustomizationLoader.getAssetType(id)
	if not assetType then
		warn(`Accessory is not a valid asset type.`)
		return
	end

	if not table.find(ACCEPTED_ACCESORY_TYPES, assetType) then
		warn(`Accessory is a {assetType.Name}.`)
		return
	end

	local loadedAccessory: Accessory
	local isMesh = false
	if assetType == Enum.AssetType:FromName("Mesh") then
		loadedAccessory = mac.createMeshAccessory(id)
		isMesh = true
	else
		loadedAccessory = InsertService:LoadAsset(id):FindFirstChildWhichIsA("Accessory")
	end

	if not loadedAccessory then
		warn(`Accessory failed to load.`)
		return
	end

	local texture = accessory.texture
	local handle = loadedAccessory:FindFirstChildWhichIsA("BasePart")
	if not handle then
		return
	end
	local mesh = handle:FindFirstChildOfClass("SpecialMesh")
	if not mesh then
		return
	end
	local meshId = mesh.MeshId

	local ogTexture = mesh.TextureId
	if texture then
		local imageId = CustomizationLoader.getImageId(texture)
		mesh.TextureId = imageId
	end

	local guid = CustomizationLoader.addGuid(loadedAccessory)

	loadedAccessory.Parent = character

	local originalSize = handle:FindFirstChildWhichIsA("Vector3Value")
	if not originalSize then
		originalSize = Instance.new("Vector3Value")
		originalSize.Name = "OriginalSize"
		originalSize.Value = mac.getOriginalSize(meshId)
		originalSize.Parent = handle
	elseif originalSize.Value == Vector3.one then
		originalSize.Value = mac.getOriginalSize(meshId)
	end

	handle.Size = originalSize.Value

	if isMesh then
		local isOutsideBounds =
			bounding.isOutsideBounds(character, loadedAccessory.Handle, character.HumanoidRootPart:GetPivot())
		if isOutsideBounds then
			local handle = loadedAccessory.Handle
			local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
			local initialSize = handle.Size

			local bounds: Vector3 = config.Bounds
			local ratio = getVectorRatio(handle.Size)
			local newSize = ratio * bounds
			handle.Size = newSize

			mesh.Scale = newSize / initialSize
		end
	end

	return guid, meshId, ogTexture
end

-- Loads an asset as the character's face texture
function CustomizationLoader.loadFace(id: any, character: Model)
	if typeof(id) == "number" then
		id = CustomizationLoader.getImageId(id)
	end
	if not id then
		return
	end

	local face = character:FindFirstChild("Head"):FindFirstChild("face") :: Decal
	if face then
		face.Texture = id
	else
		local newFace = Instance.new("Decal")
		newFace.Texture = id
		newFace.Name = "face"
		newFace.Parent = character:FindFirstChild("Head")
	end
end

-- Loads an asset as the character's shirt
function CustomizationLoader.loadShirt(id: any, character: Model)
	if typeof(id) == "number" then
		id = CustomizationLoader.getImageId(id)
	end
	if not id then
		return
	end

	local shirt = character:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt.ShirtTemplate = id
	else
		local newShirt = Instance.new("Shirt")
		newShirt.ShirtTemplate = id
		newShirt.Parent = character
	end
end

function CustomizationLoader.loadTShirt(id: any, character: Model)
	if typeof(id) == "number" then
		id = CustomizationLoader.getImageId(id)
	end
	if not id then
		return
	end

	local shirtGraphic = character:FindFirstChildOfClass("ShirtGraphic")
	if shirtGraphic then
		shirtGraphic.Graphic = id
	else
		local newShirtGraphic = Instance.new("ShirtGraphic")
		newShirtGraphic.Graphic = id
		newShirtGraphic.Parent = character
	end
end

-- Loads an asset as the character's pants
function CustomizationLoader.loadPants(id: any, character: Model)
	if typeof(id) == "number" then
		id = CustomizationLoader.getImageId(id)
	end
	if not id then
		return
	end

	local pants = character:FindFirstChildOfClass("Pants")
	if pants then
		pants.PantsTemplate = id
	else
		local newPants = Instance.new("Pants")
		newPants.PantsTemplate = id
		newPants.Parent = character
	end
end

-- Sets a Color3 as the character's skin color
function CustomizationLoader.setSkinColor(color: Color3, character: Model)
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		for _, child in character:GetChildren() do
			if child:IsA("BasePart") then
				child.Color = color
			end
		end
	else
		bodyColors.HeadColor3 = color
		bodyColors.TorsoColor3 = color
		bodyColors.LeftArmColor3 = color
		bodyColors.RightArmColor3 = color
		bodyColors.LeftLegColor3 = color
		bodyColors.RightLegColor3 = color
	end
end

-- Resizes the character
function CustomizationLoader.setCharacterSize(size: number, character: Model)
	if not validateNum(size) then
		return
	end
	character:ScaleTo(size)
end

-- Textures an accessory, returning the texture image ID
function CustomizationLoader.setTexture(accessory: Accessory, textureId): string?
	if typeof(textureId) == "number" then
		textureId = CustomizationLoader.getImageId(textureId)
	end
	if not textureId then
		return
	end

	accessory:FindFirstChildWhichIsA("BasePart"):FindFirstChildOfClass("SpecialMesh").TextureId = textureId

	return textureId
end

-- Edits accessory transparency
function CustomizationLoader.setTransparency(accessory: Accessory, transparency: number)
	if not validateNum(transparency) then
		return
	end
	local handle = accessory:FindFirstChildWhichIsA("BasePart")
	if not handle then
		return
	end
	handle.Transparency = transparency
end

-- Changes the part that the accessory is welded to
function CustomizationLoader.setWeld(accessory: Accessory, part: BasePart)
	local handle = accessory:FindFirstChildWhichIsA("BasePart")
	if not handle then
		return
	end
	local weld = handle:FindFirstChildWhichIsA("Weld")
	if not weld then
		return
	end
	weld.Part1 = part
end

return CustomizationLoader
