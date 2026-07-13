local uis = game:GetService("UserInputService")

local caller = {}

local arcHandles = require(script.ArcHandles)
local moveHandles = require(script.MoveHandles)
local util = require(script.Util)
local slapcodeFolder = game:GetService("ReplicatedStorage").Slapcode
local bounding = require(slapcodeFolder.Bounding)
local config = require(slapcodeFolder.Config)
local utilities = require(slapcodeFolder.CustomizationShared)

local remotes = slapcodeFolder.remotes.CustomizationRemotes
local translateWeld = remotes.TranslateWeld
local rotateWeld = remotes.RotateWeld
local sizeWeld = remotes.SizeWeld
local accessoryMovedBindable = remotes.AccessoryMoved
local accessoryRotatedBindable = remotes.AccessoryRotated
local accessorySizedBindable = remotes.AccessorySized

local INCREMENT = config.Increment
local BOUNDS = config.Bounds
local BOUNDS_OFFSET = Vector3.new(0, 1.5, 0)
local MIN_SIZE = 0.01

local function convertVector3ToDim3(vector3: Vector3): utilities.Dim3
	return {
		x = utilities.roundToIncrement(vector3.X),
		y = utilities.roundToIncrement(vector3.Y),
		z = utilities.roundToIncrement(vector3.Z),
	} :: utilities.Dim3
end

local function getShiftVector(side, delta)
	local directions = {
		[Enum.NormalId.Right] = Vector3.new(1, 0, 0),
		[Enum.NormalId.Left] = Vector3.new(-1, 0, 0),
		[Enum.NormalId.Top] = Vector3.new(0, 1, 0),
		[Enum.NormalId.Bottom] = Vector3.new(0, -1, 0),
		[Enum.NormalId.Front] = Vector3.new(0, 0, -1),
		[Enum.NormalId.Back] = Vector3.new(0, 0, 1),
	}

	return (directions[side] or Vector3.zero) * delta
end

function caller.createMoveHandles(player: Player, handle: BasePart)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char.HumanoidRootPart
	if not hrp then
		return
	end
	local accessoryWeld = handle:FindFirstChildWhichIsA("Weld")
	local initialState

	local function onDragStart()
		initialState = accessoryWeld.C1
	end

	local function onDrag(side: Enum.NormalId, distance: number)
		local currentC1 = accessoryWeld.C1
		distance = util.GetIncrementMultiple(distance, INCREMENT)
		local shift = getShiftVector(side, distance)
		local offset = CFrame.new(shift)
		accessoryWeld.C1 = initialState:ToWorldSpace(offset)

		if bounding.isOutsideBounds(char, handle, hrp:GetPivot()) then
			accessoryWeld.C1 = currentC1
		end
	end

	local function onDragEnd()
		local newPosition = convertVector3ToDim3(accessoryWeld.C1.Position)
		local success = translateWeld:InvokeServer(handle.Parent:GetAttribute("GUID"), newPosition)
		if not success then
			return
		end

		accessoryMovedBindable:Fire(newPosition)
	end

	local options: moveHandles.Options = {
		Adornee = handle,
		Parent = player.PlayerGui,
		OnDragStart = onDragStart,
		OnDrag = onDrag,
		OnDragEnd = onDragEnd,
		OnDestroy = function() end,
	}

	return moveHandles.new(options)
end

function caller.createRotateHandles(player: Player, handle: BasePart)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char.HumanoidRootPart
	if not hrp then
		return
	end
	local accessoryWeld = handle:FindFirstChildWhichIsA("Weld")
	local initialState

	local function onDragStart()
		initialState = accessoryWeld.C1
	end

	local function onDrag(axis, rotation: number)
		local currentC1 = accessoryWeld.C1
		rotation = math.deg(rotation)
		rotation = util.GetIncrementMultiple(rotation, INCREMENT)
		local rotationCFrame = CFrame.fromAxisAngle(Vector3.FromAxis(axis), math.rad(rotation))
		accessoryWeld.C1 = initialState * rotationCFrame

		if bounding.isOutsideBounds(char, handle, hrp:GetPivot()) then
			accessoryWeld.C1 = currentC1
		end
	end

	local function onDragEnd()
		local rx, ry, rz = accessoryWeld.C1:ToOrientation()
		local success =
			rotateWeld:InvokeServer(handle.Parent:GetAttribute("GUID"), { x = rx, y = ry, z = rz } :: utilities.Dim3)
		if not success then
			return
		end

		local rotationDegrees = {
			x = utilities.roundToIncrement(math.deg(rx)),
			y = utilities.roundToIncrement(math.deg(ry)),
			z = utilities.roundToIncrement(math.deg(rz)),
		} :: utilities.Dim3
		accessoryRotatedBindable:Fire(rotationDegrees)
	end

	local options: moveHandles.Options = {
		Adornee = handle,
		Parent = player.PlayerGui,
		OnDragStart = onDragStart,
		OnDrag = onDrag,
		OnDragEnd = onDragEnd,
		OnDestroy = function() end,
	}

	return arcHandles.new(options)
end

function caller.createSizeHandles(player: Player, handle: BasePart)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char.HumanoidRootPart
	if not hrp then
		return
	end
	local accessoryWeld = handle:FindFirstChildWhichIsA("Weld")
	local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")

	local universal -- size on every axis at once
	local initialSize
	local originalSize
	local initialCFrame

	local function onDragStart()
		universal = uis:IsKeyDown(Enum.KeyCode.LeftControl)
		initialSize = handle.Size
		originalSize = handle.OriginalSize.Value
		initialCFrame = accessoryWeld.C1
	end

	local function onDrag(side: Enum.NormalId, distance: number)
		distance = util.GetIncrementMultiple(distance, INCREMENT)
		local shift
		if universal then
			shift = Vector3.new(distance, distance, distance)
		else
			shift = getShiftVector(side, distance)
		end
		if side.Value > 2 then
			shift *= -1
		end -- inverts the shift if it's on any of the negative axes

		local currentSize = handle.Size
		local currentScale = mesh.Scale
		local currentCFrame = accessoryWeld.C1

		local newSize = initialSize + shift
		local clampedSize =
			Vector3.new(math.max(newSize.X, MIN_SIZE), math.max(newSize.Y, MIN_SIZE), math.max(newSize.Z, MIN_SIZE))

		handle.Size = clampedSize
		mesh.Scale = clampedSize / originalSize

		if bounding.isOutsideBounds(char, handle, hrp:GetPivot()) then
			mesh.Scale = currentScale
			handle.Size = currentSize
			accessoryWeld.C1 = currentCFrame
		end
	end

	local function onDragEnd()
		local newSize = convertVector3ToDim3(handle.Size)
		local newScale = convertVector3ToDim3(mesh.Scale)
		local success = sizeWeld:InvokeServer(handle.Parent:GetAttribute("GUID"), newSize, newScale)
		if not success then
			return
		end

		accessorySizedBindable:Fire(newSize)
	end

	local options: moveHandles.Options = {
		Adornee = handle,
		Parent = player.PlayerGui,
		OnDragStart = onDragStart,
		OnDrag = onDrag,
		OnDragEnd = onDragEnd,
		OnDestroy = function() end,
	}

	return moveHandles.new(options)
end

return caller
