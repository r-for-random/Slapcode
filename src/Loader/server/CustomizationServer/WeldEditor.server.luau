local slapcodeFolder = game:GetService("ReplicatedStorage"):WaitForChild("Slapcode")
local remotes = slapcodeFolder.remotes.CustomizationRemotes
local bounding = require(slapcodeFolder.Bounding)
local util = require(slapcodeFolder.CustomizationShared)

local function getHandleFromGuid(player: Player, guid: string): Part?
	for _, child in player.Character:GetChildren() do
		if child:GetAttribute("GUID") == guid then
			return child:FindFirstChildWhichIsA("Part")
		end
	end
	return nil
end

remotes.TranslateWeld.OnServerInvoke = function(player, parentGuid: string, newPos: util.Dim3)
	local char = player.Character
	local handle = getHandleFromGuid(player, parentGuid)
	local weld = handle:FindFirstChildWhichIsA("Weld")

	local originalC1 = weld.C1
	weld.C1 = CFrame.new(newPos.x, newPos.y, newPos.z) * weld.C1.Rotation

	local isOutsideBounds = bounding.isOutsideBounds(char, handle, char.HumanoidRootPart:GetPivot())
	if isOutsideBounds then
		weld.C1 = originalC1
		return false
	end

	return true
end

remotes.RotateWeld.OnServerInvoke = function(player, parentGuid: string, newRot: util.Dim3): boolean
	local char = player.Character
	local handle = getHandleFromGuid(player, parentGuid)
	local weld = handle:FindFirstChildWhichIsA("Weld")

	local originalC1 = weld.C1
	weld.C1 = CFrame.new(weld.C1.Position) * CFrame.fromOrientation(newRot.x, newRot.y, newRot.z)

	local isOutsideBounds = bounding.isOutsideBounds(char, handle, char.HumanoidRootPart:GetPivot())
	if isOutsideBounds then
		weld.C1 = originalC1
		return false
	end

	return true
end

remotes.SizeWeld.OnServerInvoke = function(
	player,
	parentGuid: string,
	newSize: util.Dim3,
	newScale: util.Dim3?
): boolean
	local char = player.Character
	local handle = getHandleFromGuid(player, parentGuid)
	local weld = handle:FindFirstChildWhichIsA("Weld")
	local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
	local originalSize = handle:FindFirstChildWhichIsA("Vector3Value").Value

	if not newScale then
		newScale = {
			x = newSize.x / originalSize.X,
			y = newSize.y / originalSize.Y,
			z = newSize.z / originalSize.Z,
		}
	end

	local originalSize = handle.Size
	local originalScale = mesh.Scale

	local newSizeVector = Vector3.new(newSize.x, newSize.y, newSize.z)
	local newScaleVector = Vector3.new(newScale.x, newScale.y, newScale.z)
	handle.Size = newSizeVector
	mesh.Scale = newScaleVector

	local isOutsideBounds = bounding.isOutsideBounds(char, handle, char.HumanoidRootPart:GetPivot())
	if isOutsideBounds then
		handle.Size = originalSize
		mesh.Scale = originalScale
		return false
	end

	return true
end
