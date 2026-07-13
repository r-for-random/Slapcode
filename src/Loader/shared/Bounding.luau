-- credit to RabbyDevs <3
local config = require(game:GetService("ReplicatedStorage").Slapcode.Config)
local BOUNDS = config.Bounds
local BOUNDS_OFFSET = config.BoundsOffset

local Bounding = {}

local function checkPartBounds(
	part: BasePart,
	center: CFrame
): boolean -- center is where the bounding is centered on, usually HRP
	local boundsCF = center * CFrame.new(BOUNDS_OFFSET)
	local halfBounds = BOUNDS / 2

	local partCF = part.CFrame
	local partSize = part.Size
	local halfPartSize = partSize / 2

	local corners = {
		partCF * Vector3.new(-halfPartSize.X, -halfPartSize.Y, -halfPartSize.Z),
		partCF * Vector3.new(halfPartSize.X, -halfPartSize.Y, -halfPartSize.Z),
		partCF * Vector3.new(-halfPartSize.X, halfPartSize.Y, -halfPartSize.Z),
		partCF * Vector3.new(halfPartSize.X, halfPartSize.Y, -halfPartSize.Z),
		partCF * Vector3.new(-halfPartSize.X, -halfPartSize.Y, halfPartSize.Z),
		partCF * Vector3.new(halfPartSize.X, -halfPartSize.Y, halfPartSize.Z),
		partCF * Vector3.new(-halfPartSize.X, halfPartSize.Y, halfPartSize.Z),
		partCF * Vector3.new(halfPartSize.X, halfPartSize.Y, halfPartSize.Z),
	}

	for _, corner in corners do
		local cornerRelative = boundsCF:PointToObjectSpace(corner)

		if
			math.abs(cornerRelative.X) > halfBounds.X
			or math.abs(cornerRelative.Y) > halfBounds.Y
			or math.abs(cornerRelative.Z) > halfBounds.Z
		then
			return true
		end
	end

	return false
end

local function scanBoundParts(parts: { BasePart }, scannedParts: { BasePart })
	local clonedScanned = table.clone(scannedParts)
	for _, part in parts do
		local joint = part:FindFirstChildWhichIsA("JointInstance")
		if joint then
			if joint:IsA("Motor6D") then -- this case shouldn't happen with slapcode but might as well leave it in
				if
					joint.Part0
					and table.find(scannedParts, joint.Part0)
					and not table.find(clonedScanned, joint.Part1)
				then
					table.insert(clonedScanned, joint.Part1)
				end
			else
				if
					joint.Part1
					and table.find(scannedParts, joint.Part1)
					and not table.find(scannedParts, joint.Part0)
				then
					table.insert(clonedScanned, joint.Part0)
				end
			end
		end
	end

	if #clonedScanned ~= #scannedParts then
		return scanBoundParts(parts, clonedScanned)
	else
		return clonedScanned
	end
end

function Bounding.isOutsideBounds(char: Model, part: BasePart, hrpCF: CFrame): boolean
	local partsToScan = {}
	for _, inst in char:GetDescendants() do
		if inst:IsA("BasePart") then
			table.insert(partsToScan, inst)
		end
	end

	local partsToCheck = scanBoundParts(partsToScan, { part })

	for _, weldedPart in partsToCheck do
		if checkPartBounds(weldedPart, hrpCF) then
			return true
		end
	end

	return false
end

return Bounding
