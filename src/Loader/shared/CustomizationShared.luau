local config = require(script.Parent:WaitForChild("Config"))

local util = {}

export type Dim3 = {
	x: number,
	y: number,
	z: number,
}

export type AccessoryInfo = {
	Instance: Instance?,
	Name: string,
	MeshId: string,
	MarketplaceTextureId: string,
	TextureId: string,
	Position: Dim3,
	Rotation: Dim3,
	Scale: Dim3,
	Size: Dim3?,
	Transparency: number?,
	WeldedPart: string?,
	AttachmentName: string?,
	AttachmentPosition: Dim3?,
	AttachmentOrientation: Dim3?,
	P0: Dim3?,
	R0: Dim3?,
}

export type NameInfo = {
	Name: string,
	Bio: string,
	Font: string,
	FillColor: { [string]: number },
	OutlineColor: { [string]: number },
}

function util.getAccessoryFromGuid(player: Player, guid: string): Accessory?
	for _, child in player.Character:GetChildren() do
		if not child:IsA("Accessory") then
			continue
		end
		if child:GetAttribute("GUID") == guid then
			return child
		end
	end
	return nil
end

local headAttachments = {
	"FaceCenterAttachment",
	"FaceFrontAttachment",
	"HairAttachment",
	"HatAttachment",
	"NeckRigAttachment",
}
function util.isHeadAccessory(attachmentName: string): boolean
	for _, name in headAttachments do
		if attachmentName == name then
			return true
		end
	end
	return false
end

function util.cleanUpId(id: string): number?
	id = string.gsub(id, "%D", "")
	return tonumber(id)
end

function util.cleanUpNum(str: string): number?
	str = string.gsub(str, "[^%d%.]", "")
	return tonumber(str)
end

local INCREMENT = config.Increment
function util.roundToIncrement(value: number)
	local scale = 10 ^ 12
	local scaledValue = math.floor(value * scale + 0.5)
	local scaledIncrement = math.floor(INCREMENT * scale + 0.5)

	local rounded = math.floor((scaledValue / scaledIncrement) + 0.5) * scaledIncrement

	return rounded / scale
end

function util.roundDim3ToIncrement(dim3: Dim3)
	return { x = util.roundToIncrement(dim3.x), y = util.roundToIncrement(dim3.y), z = util.roundToIncrement(dim3.z) }
end

function util.dim3ToRad(dim3: Dim3): Dim3
	return { x = math.rad(dim3.x), y = math.rad(dim3.y), z = math.rad(dim3.z) }
end

function util.convertRotationToDim3(cf: CFrame): Dim3
	local rx, ry, rz = cf:ToEulerAnglesXYZ()
	return { x = math.deg(rx), y = math.deg(ry), z = math.deg(rz) }
end

function util.convertDim3ToString(dim3: Dim3): string
	return `({dim3.x}, {dim3.y}, {dim3.z})`
end

function util.convertColor3ToString(color: Color3): string
	return `({math.round(color.R * 255)}, {math.round(color.G * 255)}, {math.round(color.B * 255)})`
end

function util.convertStringToDim3(str: string): Dim3?
	local dim3: utilities.Dim3 = {}
	local args = string.split(str, ",")

	if #args ~= 3 then
		return
	end

	for i, v in args do
		args[i] = util.cleanUpNum(v)
		if not args[i] then
			return
		end
	end
	dim3.x = args[1] :: number
	dim3.y = args[2] :: number
	dim3.z = args[3] :: number

	return dim3
end

function util.convertStringToColor3(str: string): Color3?
	local args = string.split(str, ",")

	if #args ~= 3 then
		return
	end

	for i, v in args do
		args[i] = util.cleanUpNum(v)
		if not args[i] then
			return
		end
	end

	return Color3.fromRGB(args[1] :: number, args[2] :: number, args[3] :: number)
end

function util.convertColor3ToDim3(color: Color3): Dim3
	return {
		x = color.R,
		y = color.G,
		z = color.B,
	}
end

function util.convertDim3ToColor3(dim3: Dim3): Color3
	return Color3.new(dim3.x, dim3.y, dim3.z)
end

function util.convertVector3ToDim3(vector3: Vector3): Dim3
	return {
		x = vector3.X,
		y = vector3.Y,
		z = vector3.Z,
	}
end

function util.convertDim3ToVector3(dim3: Dim3): Vector3
	return Vector3.new(dim3.x, dim3.y, dim3.z)
end

function util.getTorsoColor(char: Model): Color3?
	local bodyColors = char:FindFirstChildOfClass("BodyColors")

	if not bodyColors then
		local torso = char:WaitForChild("Torso")
		if torso:IsA("Part") then
			return torso.Color
		end
		return
	end

	return bodyColors.TorsoColor3
end

return util
