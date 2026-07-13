--!strict
local InsertService = game:GetService("InsertService")

local mac = {}

local function createMeshPart(meshId: string): MeshPart -- you can't make me pcall this
	return InsertService:CreateMeshPartAsync(meshId, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Precise)
end

function mac.getOriginalSize(meshId: string): Vector3
	local mesh = createMeshPart(meshId)
	local size = mesh.Size
	mesh:Destroy()
	return size
end

function mac.createMeshAccessory(meshNum: number): Accessory
	local meshId = `rbxassetid://{meshNum}`
	local mesh = createMeshPart(meshId)
	local size = mesh.Size
	mesh:Destroy()

	local accessory = Instance.new("Accessory")

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = size
	handle.Transparency = 0
	handle.Parent = accessory

	local originalSize = Instance.new("Vector3Value")
	originalSize.Name = "OriginalSize"
	originalSize.Value = size
	originalSize.Parent = handle

	local specialMesh = Instance.new("SpecialMesh")
	specialMesh.Name = "SpecialMesh"
	specialMesh.MeshType = Enum.MeshType.FileMesh
	specialMesh.MeshId = meshId
	specialMesh.Parent = handle

	local attachment = Instance.new("Attachment")
	attachment.Name = "HatAttachment"
	attachment.Parent = handle

	return accessory
end

return mac
