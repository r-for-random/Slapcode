--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local shared = game:GetService("ReplicatedStorage").Slapcode
local config = require(shared:WaitForChild("Config")) -- I don't need to use waitforchild here but if I don't the editor screams at me
local util = require(script.Parent.Util)

if not config.Naming then
	return
end

local remotes = shared.remotes.NameRemotes :: Folder
local createNametag = remotes:FindFirstChild("CreateNametag") :: RemoteEvent
local updateNametag = remotes:FindFirstChild("UpdateNametag") :: RemoteEvent
local destroyNametag = remotes:FindFirstChild("DestroyNametag") :: RemoteEvent
local sendCooldown = remotes:FindFirstChild("SendCooldown") :: RemoteEvent
local nametagTemplate = script.Nametag
local listItemTemplate = script.ListItem

local localPlayer = Players.LocalPlayer
local slapcodeGui = localPlayer.PlayerGui:WaitForChild("SlapcodeGui") :: ScreenGui
local nameGui = slapcodeGui:FindFirstChild("NamingMenu") :: Frame
local bioDisplay = slapcodeGui:FindFirstChild("BioDisplay") :: Frame

local namesFolder = Instance.new("Folder")
namesFolder.Name = "Nametags"
namesFolder.Parent = slapcodeGui

local visibleNametags = true

type NameInfo = {
	Name: string,
	Bio: string,
	Font: string,
	FillColor: { [string]: number },
	OutlineColor: { [string]: number },
}

local function getFont(str: string): Enum.Font
	local font = Enum.Font:FromName(str)
	if font then
		return font
	else
		return Enum.Font.Creepster
	end
end

local function getNametag(str: string): BillboardGui?
	for _, nametag in namesFolder:GetChildren() do
		if nametag:IsA("BillboardGui") and nametag.Name == str then
			return nametag
		end
	end
	return nil
end

local function convertRGBToString(rgb: { [string]: number }): string
	return `({rgb.R}, {rgb.G}, {rgb.B})`
end

local function convertRGBToColor3(rgb: { [string]: number }): Color3
	return Color3.fromRGB(rgb.R, rgb.G, rgb.B)
end

local function convertStringToRGB(str: string): { [string]: number }?
	local rgb: { [string]: number } = {}
	local args: { any } = string.split(str, ",")

	if #args ~= 3 then
		return nil
	end

	for i, v in args do
		args[i] = util.cleanUpNum(v)
		if not args[i] then
			return nil
		end
	end
	rgb.R = args[1] :: number
	rgb.G = args[2] :: number
	rgb.B = args[3] :: number

	return rgb
end

local bioName = bioDisplay:FindFirstChild("Name") :: TextLabel
local bioBioFrame = bioDisplay:FindFirstChild("ScrollingFrame")
local bioBioBio -- come on, you think of a better name
if bioBioFrame then
	bioBioBio = bioBioFrame:FindFirstChild("Bio") :: TextLabel
else
	return
end
local cross = bioDisplay:FindFirstChild("Cross") :: GuiButton

local slideIn = TweenService:Create(bioDisplay, util.MenuSlideTweenInfo, { Position = UDim2.new(0.5, 0, 0.5, 0) })
local slideOut = TweenService:Create(bioDisplay, util.MenuSlideTweenInfo, { Position = UDim2.new(0.5, 0, 1.5, 0) })

local function displayBio(nametag: BillboardGui)
	local button = nametag:FindFirstChildOfClass("TextButton")
	if not button then
		return
	end
	local bio = nametag:FindFirstChildOfClass("StringValue")
	if not bio then
		return
	end

	bioName.Text = button.Text
	bioBioBio.Text = bio.Value

	cross.Activated:Once(function()
		slideOut:Play()
	end)

	slideIn:Play()
end

script.GetOwnNametag.OnInvoke = function(): NameInfo?
	local nametag = getNametag(tostring(localPlayer.UserId))
	if not nametag then
		return nil
	end
	local button = nametag:FindFirstChildOfClass("TextButton")
	if not button then
		return nil
	end
	local bio = nametag:FindFirstChildOfClass("StringValue")
	if not bio then
		return nil
	end

	return {
		Name = button.Text,
		Bio = bio.Value,
		Font = button.Font.Name,
		FillColor = {
			R = math.round(button.TextColor3.R * 255),
			G = math.round(button.TextColor3.G * 255),
			B = math.round(button.TextColor3.B * 255),
		},
		OutlineColor = {
			R = math.round(button.TextStrokeColor3.R * 255),
			G = math.round(button.TextStrokeColor3.G * 255),
			B = math.round(button.TextStrokeColor3.B * 255),
		},
	}
end

-- evil UI code below
local nameEntry = nameGui:FindFirstChild("NameEntry") :: TextBox
local bioFrame = nameGui:FindFirstChild("ScrollingFrame") :: ScrollingFrame
local bioEntry = bioFrame:FindFirstChild("BioEntry") :: TextBox
local nameChars = nameGui:FindFirstChild("NameChars") :: TextLabel
local bioChars = nameGui:FindFirstChild("BioChars") :: TextLabel

local lbb = nameGui:FindFirstChild("LowerBoundingBox") :: Frame
local fc = lbb:FindFirstChild("FillColor") :: Frame
local fillEntry = fc:FindFirstChild("FillColorEntry") :: TextBox
local fillDisplay = fc:FindFirstChild("FillColorDisplay") :: Frame
local oc = lbb:FindFirstChild("OutlineColor") :: Frame
local outlineEntry = oc:FindFirstChild("OutlineColorEntry") :: TextBox
local outlineDisplay = oc:FindFirstChild("OutlineColorDisplay") :: Frame
local fontButton = lbb:FindFirstChild("Font") :: TextButton
local dropdownBox = nameGui:FindFirstChild("FontsDropdown") :: Frame
local fontsDropdown = dropdownBox:FindFirstChild("ScrollingFrame") :: ScrollingFrame
local hideNametagsButton = lbb:FindFirstChild("HideNametags") :: TextButton

local function loadNameGui(nameInfo: NameInfo)
	nameEntry.Text = nameInfo.Name
	bioEntry.Text = nameInfo.Bio
	fillEntry.Text = convertRGBToString(nameInfo.FillColor) -- could be invalid because server doesn't check but who cares bro
	outlineEntry.Text = convertRGBToString(nameInfo.OutlineColor)
	fillDisplay.BackgroundColor3 = convertRGBToColor3(nameInfo.FillColor)
	outlineDisplay.BackgroundColor3 = convertRGBToColor3(nameInfo.OutlineColor)
	fontButton.Text = nameInfo.Font
	fontButton.Font = getFont(nameInfo.Font)
end

createNametag.OnClientEvent:Connect(function(player: Player, nameInfo: NameInfo)
	local char = player.Character
	if not char then
		return
	end
	local nametag = nametagTemplate:Clone()
	local button = nametag.TextButton
	nametag.Name = player.UserId
	button.Text = nameInfo.Name
	button.TextColor3 = Color3.fromRGB(nameInfo.FillColor.R, nameInfo.FillColor.G, nameInfo.FillColor.B)
	button.TextStrokeColor3 = Color3.fromRGB(nameInfo.OutlineColor.R, nameInfo.OutlineColor.G, nameInfo.OutlineColor.B)
	button.Font = getFont(nameInfo.Font)
	nametag.Bio.Value = nameInfo.Bio
	nametag.Enabled = visibleNametags
	nametag.Adornee = char:WaitForChild("Head")

	nametag.TextButton.Activated:Connect(function()
		displayBio(nametag)
	end)

	if player == localPlayer then
		loadNameGui(nameInfo)
	end

	nametag.Parent = namesFolder
end)

updateNametag.OnClientEvent:Connect(function(player: Player, nameInfo: NameInfo)
	local nametag = getNametag(tostring(player.UserId))
	if not nametag then
		return
	end
	local button = nametag:FindFirstChildOfClass("TextButton")
	if not button then
		return
	end
	local bio = nametag:FindFirstChildOfClass("StringValue")
	if not bio then
		return
	end

	button.Text = nameInfo.Name
	button.TextColor3 = Color3.fromRGB(nameInfo.FillColor.R, nameInfo.FillColor.G, nameInfo.FillColor.B)
	button.TextStrokeColor3 = Color3.fromRGB(nameInfo.OutlineColor.R, nameInfo.OutlineColor.G, nameInfo.OutlineColor.B)
	button.Font = getFont(nameInfo.Font)
	bio.Value = nameInfo.Bio

	if player == localPlayer then
		loadNameGui(nameInfo)
	end
end)

destroyNametag.OnClientEvent:Connect(function(player: Player)
	local nametag = getNametag(tostring(player.UserId))
	if nametag then
		nametag:Destroy()
	end
end)

-- nametag customization
if config.NametagCustomization then
	-- colors
	fillEntry.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local rgb = convertStringToRGB(fillEntry.Text)
		if not rgb then
			return
		end
		fillEntry.Text = convertRGBToString(rgb)
		updateNametag:FireServer("FillColor", rgb)
	end)
	outlineEntry.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local rgb = convertStringToRGB(outlineEntry.Text)
		if not rgb then
			return
		end
		outlineEntry.Text = convertRGBToString(rgb)
		updateNametag:FireServer("OutlineColor", rgb)
	end)

	-- fonts
	local fontMenuOpen = false
	local fontsIn = TweenService:Create(fontsDropdown, util.MenuSlideTweenInfo, { AnchorPoint = Vector2.new(0, 0) })
	local fontsOut = TweenService:Create(fontsDropdown, util.MenuSlideTweenInfo, { AnchorPoint = Vector2.new(0, 1) })

	for _, fontType in Enum.Font:GetEnumItems() do
		if fontType == Enum.Font.Unknown then
			continue
		end
		local item = listItemTemplate:Clone()
		item.Text = fontType.Name
		item.Font = fontType
		item.Activated:Connect(function()
			updateNametag:FireServer("Font", item.Text)
			fontsOut:Play()
			fontMenuOpen = false
		end)
		item.Parent = fontsDropdown
	end

	fontButton.Activated:Connect(function()
		if fontMenuOpen then
			fontsOut:Play()
		else
			fontsIn:Play()
		end
		fontMenuOpen = not fontMenuOpen
	end)
else
	lbb.Visible = false
end

-- bio textbox autoscaling
bioEntry:GetPropertyChangedSignal("TextFits"):Connect(function()
	while not bioEntry.TextFits do
		bioFrame.CanvasSize = UDim2.new(0, 0, 0, bioFrame.CanvasSize.Y.Offset + 16)
		bioFrame.CanvasPosition = Vector2.new(0, bioFrame.CanvasSize.Y.Offset - bioFrame.AbsoluteWindowSize.Y)
	end
end)

bioEntry:GetPropertyChangedSignal("TextBounds"):Connect(function()
	if bioFrame.CanvasSize.Y.Offset > bioEntry.TextBounds.Y + 16 then
		bioFrame.CanvasSize = UDim2.new(0, 0, 0, bioEntry.TextBounds.Y)
		bioFrame.CanvasPosition = Vector2.new(0, bioFrame.CanvasSize.Y.Offset - bioFrame.AbsoluteWindowSize.Y)
	end
end)

-- hide nametags
hideNametagsButton.Activated:Connect(function()
	visibleNametags = not visibleNametags
	for _, nametag in namesFolder:GetChildren() do
		if not nametag:IsA("BillboardGui") then
			continue
		end
		nametag.Enabled = visibleNametags
	end
	hideNametagsButton.Text = if visibleNametags then "Hide All Nametags" else "Show All Nametags"
end)

-- char limits
nameChars.Text = `0/{config.MaxNameChars}`
nameEntry:GetPropertyChangedSignal("Text"):Connect(function()
	if nameEntry.Text:len() > config.MaxNameChars then
		nameEntry.Text = nameEntry.Text:sub(1, config.MaxNameChars)
		return
	end
	nameChars.Text = `{nameEntry.Text:len()}/{config.MaxNameChars}`
end)

bioChars.Text = `0/{config.MaxBioChars}`
bioEntry:GetPropertyChangedSignal("Text"):Connect(function()
	if bioEntry.Text:len() > config.MaxBioChars then
		bioEntry.Text = bioEntry.Text:sub(1, config.MaxBioChars)
		return
	end
	bioChars.Text = `{bioEntry.Text:len()}/{config.MaxBioChars}`
end)

-- server connection
nameEntry.FocusLost:Connect(function()
	updateNametag:FireServer("Name", nameEntry.Text)
end)

bioEntry.FocusLost:Connect(function()
	updateNametag:FireServer("Bio", bioEntry.Text)
end)

sendCooldown.OnClientEvent:Connect(function(param: "Name" | "Bio", cooldown: number)
	local isName = param == "Name"
	local label = if isName then nameChars else bioChars
	local entry = if isName then nameEntry else bioEntry
	local max = if isName then config.MaxNameChars else config.MaxBioChars

	for i = cooldown, math.max(cooldown - 5, 0), -1 do
		label.Text = `Cannot update for another {math.max(math.round(i), 0)} seconds`
		task.wait(1)
	end
	label.Text = `{entry.Text:len()}/{max}`
end)
