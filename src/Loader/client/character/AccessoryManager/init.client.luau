local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local localPlayer = Players.LocalPlayer
local slapcodeFolder = ReplicatedStorage.Slapcode
local util = require(slapcodeFolder.CustomizationShared)

local guiFrame: Frame = localPlayer.PlayerGui.SlapcodeGui.CustomizationMenu
local newAccessoryFrame: Frame = guiFrame.NewAccessoryFrame
local accessoryListFrame: ScrollingFrame = guiFrame.AccessoryListFrame.AccessoryListScrollingFrame
local loadAccessoryButton: TextButton = newAccessoryFrame.LOAD
local accessoryListLabel: TextButton = script:WaitForChild("AccessoryListLabel")
local detailedCustomizationFrame: Frame = guiFrame.LowerBoundingBox.DetailedCustomizationFrame
local characterFrame: Frame = guiFrame.UpperBoundingBox.CharacterFrame
local savingFrame: Frame = guiFrame.SavingFrame

local util = require(slapcodeFolder.CustomizationShared)
local remotes = slapcodeFolder.remotes.CustomizationRemotes
local config = require(slapcodeFolder.Config)
if not config.Customization then
	return
end

local handles = require(script:WaitForChild("Handles"))

local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(config.MenuSlideTime, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local accessoryImages = {
	accessory = "rbxassetid://119626871921881",
}

local function slide(menu: Frame, direction: string)
	local dir = if direction == "Up" then 1 elseif direction == "Down" then 0 else nil
	if not dir then
		return
	end

	local tween = TweenService:Create(menu, tweenInfo, { AnchorPoint = Vector2.new(0.5, dir) })
	tween:Play()
end

local function getAccessoryTextureId(instance: Accessory): number
	return instance:WaitForChild("Handle"):FindFirstChildOfClass("SpecialMesh").TextureId
end

local function createVisibleBoundingBox(): Part
	local char = localPlayer.Character
	local hrp = char.HumanoidRootPart

	local box = Instance.new("Part")
	box.Name = "BoundingBox"
	box.CanCollide = false
	box.CanTouch = false
	box.CanQuery = false
	box.Transparency = 0.8
	box.Size = config.Bounds
	box.Color = config.BoundingBoxColor
	box.Material = Enum.Material.SmoothPlastic
	box:PivotTo(hrp:GetPivot() + config.BoundsOffset)

	local weld = Instance.new("WeldConstraint")
	weld.Parent = box
	weld.Part0 = box
	weld.Part1 = hrp

	box.Parent = char

	return box
end

localPlayer.CharacterAppearanceLoaded:Connect(function()
	for _, item in accessoryListFrame:GetChildren() do
		if not item:IsA("GuiObject") then
			continue
		end
		item:Destroy()
	end
end)

------------------------------------------------------------------------------------------------------------- DETAILED ACCESSORY FUNCTIONS

local currentAccessory: util.AccessoryInfo = nil
local connections: { RBXScriptConnection } = {}

local currentHandles = nil
local handleMode: string = nil
local visibleBoundingBox: Part = nil

local function closeHandles()
	currentHandles:Destroy()
	currentHandles = nil
	handleMode = nil
end

local function updateAccessoryName(textBox: TextBox, priorName: string, label: TextLabel)
	local enteredText = textBox.Text
	if enteredText == "" then
		label.Text = priorName
		textBox.Text = priorName
	else
		label.Text = enteredText
	end
end

------------------------------------------------------------------------------------------------------------- DETAILED ACCESSORY MENU

local function closeDetailedCustomizationMenu()
	if currentHandles then
		closeHandles()
	end
	currentAccessory = nil
	for _, connection: RBXScriptConnection in connections do
		connection:Disconnect()
	end
	if visibleBoundingBox then
		visibleBoundingBox:Destroy()
	end
	slide(detailedCustomizationFrame, "Up")
end
remotes.HideAllSubMenus.Event:Connect(closeDetailedCustomizationMenu)

local function openDetailedCustomizationMenu(accessoryInfo: util.AccessoryInfo, accessoryLabel: TextButton)
	local inst = accessoryInfo.Instance
	assert(inst, `AccessoryInfo with name {accessoryInfo.Name} is missing instance despite label being loaded`)
	currentAccessory = accessoryInfo

	inst.Destroying:Connect(closeDetailedCustomizationMenu)

	local accessoryName = detailedCustomizationFrame.AccessoryName
	accessoryName.Text = accessoryInfo.Name

	-- Rename
	local connection = accessoryName.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local newName = accessoryName.Text
		inst.Name = newName
		accessoryLabel.TextLabel.Text = newName
		accessoryInfo.Name = newName
	end)
	table.insert(connections, connection)

	-- Retexture
	local textureTextBox = detailedCustomizationFrame.TextureTextBox
	textureTextBox.Text = ""
	connection = textureTextBox.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local textureId = remotes.Texture:InvokeServer(inst, util.cleanUpId(textureTextBox.Text))
		if not textureId then
			return
		end
		accessoryInfo.TextureId = textureId
	end)
	table.insert(connections, connection)

	-- Restore texture
	local restoreTextureButton: GuiButton = detailedCustomizationFrame.RestoreTexture
	connection = restoreTextureButton.Activated:Connect(function()
		local textureId = remotes.Texture:InvokeServer(inst, accessoryInfo.MarketplaceTextureId)
		if not textureId then
			return
		end
		accessoryInfo.TextureId = textureId
	end)
	table.insert(connections, connection)

	-- Change transparency
	local transparencyTextBox = detailedCustomizationFrame.TransparencyTextBox
	transparencyTextBox.Text = accessoryInfo.Transparency
	connection = transparencyTextBox.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local transparency = util.cleanUpNum(transparencyTextBox.Text)
		if not transparency then
			return
		end
		remotes.SetTransparency:FireServer(inst, transparency)
		accessoryInfo.Transparency = transparency
	end)
	table.insert(connections, connection)

	-- Change weld part
	local weldEditBox = detailedCustomizationFrame.EditWeld
	weldEditBox.Text = accessoryInfo.WeldedPart
	connection = weldEditBox:GetPropertyChangedSignal("Text"):Connect(function()
		remotes.SetWeld:FireServer(inst, weldEditBox.Text)
		accessoryInfo.WeldedPart = weldEditBox.Text
	end)
	table.insert(connections, connection)

	--------------------------------------------------------------- Accessory editing
	local function setUpTextBoxChange(accessoryInfoKey: string, textBox: TextBox, newDim3: util.Dim3)
		accessoryInfo[accessoryInfoKey] = newDim3
		local str = util.convertDim3ToString(newDim3)
		textBox.Text = str
	end

	-- Reposition
	local positionTextBox = detailedCustomizationFrame.PositionTextBox
	positionTextBox.Text = util.convertDim3ToString(accessoryInfo.Position)
	connection = remotes.AccessoryMoved.Event:Connect(function(newPosition: util.Dim3)
		setUpTextBoxChange("Position", positionTextBox, newPosition)
	end)
	table.insert(connections, connection)
	connection = positionTextBox.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local newPos = util.convertStringToDim3(positionTextBox.Text)
		if not newPos then
			positionTextBox.Text = util.convertDim3ToString(accessoryInfo.Position)
			return
		end

		local success = remotes.TranslateWeld:InvokeServer(inst:GetAttribute("GUID"), newPos)
		if success then
			remotes.AccessoryMoved:Fire(newPos)
		else
			positionTextBox.Text = util.convertDim3ToString(accessoryInfo.Position)
		end
	end)
	table.insert(connections, connection)

	-- Rotate
	local rotationTextBox = detailedCustomizationFrame.RotationTextBox
	rotationTextBox.Text = util.convertDim3ToString(accessoryInfo.Rotation)
	connection = remotes.AccessoryRotated.Event:Connect(function(newRotation: util.Dim3)
		setUpTextBoxChange("Rotation", rotationTextBox, newRotation)
	end)
	table.insert(connections, connection)
	connection = rotationTextBox.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local newRot = util.convertStringToDim3(rotationTextBox.Text)
		if not newRot then
			rotationTextBox.Text = util.convertDim3ToString(accessoryInfo.Rotation)
			return
		end
		local newRotRadians = util.dim3ToRad(newRot)

		local success = remotes.RotateWeld:InvokeServer(inst:GetAttribute("GUID"), newRotRadians)
		if success then
			remotes.AccessoryRotated:Fire(newRot)
		else
			rotationTextBox.Text = util.convertDim3ToString(accessoryInfo.Rotation)
		end
	end)
	table.insert(connections, connection)

	-- Size
	local sizeTextBox = detailedCustomizationFrame.SizeTextBox
	sizeTextBox.Text = util.convertDim3ToString(accessoryInfo.Size)
	connection = remotes.AccessorySized.Event:Connect(function(newSize: util.Dim3)
		setUpTextBoxChange("Size", sizeTextBox, newSize)
	end)
	table.insert(connections, connection)
	connection = sizeTextBox.FocusLost:Connect(function(enterPressed: boolean)
		if not enterPressed then
			return
		end
		local newSize = util.convertStringToDim3(sizeTextBox.Text)
		if not newSize then
			sizeTextBox.Text = util.convertDim3ToString(accessoryInfo.Size)
			return
		end

		local success = remotes.SizeWeld:InvokeServer(inst:GetAttribute("GUID"), newSize)
		if success then
			remotes.AccessorySized:Fire(newSize)
		else
			sizeTextBox.Text = util.convertDim3ToString(accessoryInfo.Size)
		end
	end)
	table.insert(connections, connection)

	--------------------------------------------------------------- Handles
	local accessoryHandle = inst:FindFirstChild("Handle")
	assert(accessoryHandle, `{accessoryInfo.Name} is missing handle`)

	local function setUpEditButton(createHandles: (player: Player, handle: BasePart) -> self, mode: string)
		if not currentHandles then
			currentHandles = createHandles(localPlayer, accessoryHandle :: BasePart)
			handleMode = mode
			visibleBoundingBox = createVisibleBoundingBox()
		elseif handleMode ~= mode then
			currentHandles:Destroy()
			currentHandles = createHandles(localPlayer, accessoryHandle :: BasePart)
			handleMode = mode
		else
			closeHandles()
			if visibleBoundingBox then
				visibleBoundingBox:Destroy()
			end
		end
	end

	local positionEditBox = detailedCustomizationFrame.EditPosition
	connection = positionEditBox.Activated:Connect(function()
		setUpEditButton(handles.createMoveHandles, "Move")
	end)
	table.insert(connections, connection)

	local rotationEditBox = detailedCustomizationFrame.EditRotation
	connection = rotationEditBox.Activated:Connect(function()
		setUpEditButton(handles.createRotateHandles, "Rotate")
	end)
	table.insert(connections, connection)

	local sizeEditBox = detailedCustomizationFrame.EditSize
	connection = sizeEditBox.Activated:Connect(function()
		setUpEditButton(handles.createSizeHandles, "Size")
	end)
	table.insert(connections, connection)

	slide(detailedCustomizationFrame, "Down")
end

------------------------------------------------------------------------------------------------------------- CHARACTER MENU

local characterMenuOpen = true

characterFrame.OpenButton.Activated:Connect(function()
	if characterMenuOpen then
		slide(characterFrame, "Down")
	else
		slide(characterFrame, "Up")
	end
	characterMenuOpen = not characterMenuOpen
end)

-- Skin color customizer
local initialSkinColor = util.getTorsoColor(localPlayer.Character)
local skinColorTextBox: TextBox = characterFrame.SkinColorTextBox
skinColorTextBox.Text = util.convertColor3ToString(initialSkinColor)
local skinColorImage: Frame = characterFrame.SkinColorImage
skinColorImage.BackgroundColor3 = initialSkinColor
skinColorTextBox.FocusLost:Connect(function(enterPressed: boolean)
	if not enterPressed then
		return
	end
	local color = util.convertStringToColor3(skinColorTextBox.Text)
	if not color then
		skinColorTextBox.Text = util.convertColor3ToString(util.getTorsoColor(localPlayer.Character))
		return
	end
	remotes.SetSkinColor:FireServer(color)
	skinColorTextBox.Text = util.convertColor3ToString(color)
	skinColorImage.BackgroundColor3 = color
end)

-- Character scaling
local sizeTextBox: TextBox = characterFrame.SizeTextBox
sizeTextBox.Text = localPlayer.Character:GetScale()
sizeTextBox.FocusLost:Connect(function(enterPressed: boolean)
	if not enterPressed then
		return
	end
	local size = util.cleanUpNum(sizeTextBox.Text)
	if not size then
		sizeTextBox.Text = util.roundToIncrement(localPlayer.Character:GetScale())
		return
	end
	size = math.clamp(size, config.MinPlayerScale, config.MaxPlayerScale)
	remotes.SetCharacterSize:FireServer(size)
	sizeTextBox.Text = size
end)

------------------------------------------------------------------------------------------------------------- REGULAR ACCESSORY MENU

local accessories: { util.AccessoryInfo } = {}

local function addAccessoryLabel(meshId: number, guid: string, ogTexture: number)
	local instance = util.getAccessoryFromGuid(localPlayer, guid)
	local handle = instance:WaitForChild("Handle")
	local weld = handle:FindFirstChildWhichIsA("Weld")
	local mesh = handle:FindFirstChildWhichIsA("SpecialMesh")
	local newAccessoryLabel = accessoryListLabel:Clone()
	local nameLabel = newAccessoryLabel:WaitForChild("TextLabel")

	local accessoryInfo: util.AccessoryInfo = {
		Instance = instance,
		Name = instance.Name,
		MeshId = meshId,
		MarketplaceTextureId = ogTexture,
		TextureId = getAccessoryTextureId(instance),
		Position = util.roundDim3ToIncrement(util.convertVector3ToDim3(weld.C1.Position)),
		Rotation = util.roundDim3ToIncrement(util.convertRotationToDim3(weld.C1.Rotation)),
		Scale = util.roundDim3ToIncrement(util.convertVector3ToDim3(mesh.Scale)),
		Size = util.roundDim3ToIncrement(util.convertVector3ToDim3(handle.Size)),
		Transparency = handle.Transparency,
		WeldedPart = weld.Part1.Name,
	}

	table.insert(accessories, accessoryInfo)

	instance.Destroying:Connect(function()
		newAccessoryLabel:Destroy()
		if currentAccessory == accessoryInfo then
			closeDetailedCustomizationMenu()
		end
		table.remove(accessories, table.find(accessories, accessoryInfo))
		table.clear(accessoryInfo)
	end)

	nameLabel.Text = instance.Name
	newAccessoryLabel:WaitForChild("Frame").ImageLabel.Image = accessoryImages["accessory"]
	newAccessoryLabel.Parent = accessoryListFrame

	local cross = newAccessoryLabel:WaitForChild("Cross")
	cross.Activated:Connect(function()
		remotes.Delete:FireServer(guid)
	end)

	local gear = newAccessoryLabel:WaitForChild("Gear")
	gear.Activated:Connect(function()
		if not currentAccessory then
			openDetailedCustomizationMenu(accessoryInfo, newAccessoryLabel)
		elseif currentAccessory == accessoryInfo then
			closeDetailedCustomizationMenu()
		else
			closeDetailedCustomizationMenu()
			task.wait(config.MenuSlideTime)
			openDetailedCustomizationMenu(accessoryInfo, newAccessoryLabel)
		end
	end)
end

loadAccessoryButton.Activated:Connect(function()
	if remotes.MaxAccessories:InvokeServer() then
		return
	end

	local assetId = util.cleanUpId(newAccessoryFrame.AccessoryIDTextBox.Text)
	local enteredAssetType = newAccessoryFrame.TypeDisplayFrame.TypeDisplay.Text
	local char = localPlayer.Character

	local success: boolean
	if enteredAssetType == "Accessory" then
		local textureId = util.cleanUpId(newAccessoryFrame.TextureIDTextBox.Text)
		local accessory: loader.accessory = {
			id = assetId,
			texture = textureId,
		}

		local loadedInstance, meshId, ogTexture = remotes.Load:InvokeServer(enteredAssetType, accessory)
		if loadedInstance then
			addAccessoryLabel(meshId, loadedInstance :: Accessory, ogTexture)
		end
	elseif enteredAssetType == "Face" then
		remotes.Load:InvokeServer(enteredAssetType, assetId)
	elseif enteredAssetType == "Shirt" then
		remotes.Load:InvokeServer(enteredAssetType, assetId)
	elseif enteredAssetType == "Pants" then
		remotes.Load:InvokeServer(enteredAssetType, assetId)
	elseif enteredAssetType == "T-Shirt" then
		remotes.Load:InvokeServer(enteredAssetType, assetId)
	end
end)

remotes.AddAccessoryLabel.OnClientEvent:Connect(function(meshId: number, guid: string, textureId: string)
	addAccessoryLabel(meshId, guid, textureId)
end)

------------------------------------------------------------------------------------------------------------- SAVING MENU

local selectedSave = script.SelectedSave

local savingScrollingFrame: ScrollingFrame = savingFrame.SavingScrollingFrame
local function getSaveButton(saveName: string): TextButton?
	for _, save in savingScrollingFrame:GetChildren() do
		if not save:IsA("TextButton") then
			continue
		end
		if save.Text == saveName then
			return save
		end
	end
end

local selectedSaveFrame: Frame = savingFrame.Controls.SelectedSave
local function refreshSaves()
	for _, button in savingScrollingFrame:GetChildren() do
		if button:IsA("GuiButton") then
			button:Destroy()
		end
	end

	local saves = remotes.ListSaves:InvokeServer()
	for _, save: string in saves do
		local label = script.SaveLabel:Clone()
		label.Text = save
		label.Parent = savingScrollingFrame
		label.Activated:Connect(function()
			selectedSave.Value = save
		end)
	end

	selectedSave.Value = ""
end

selectedSave.Changed:Connect(function()
	(selectedSaveFrame.SelectedSaveName :: TextLabel).Text = selectedSave.Value
	if selectedSave.Value == "" then
		return
	end

	local saveExists = false -- a little paranoia is healthy
	for _, save in remotes.ListSaves:InvokeServer() do
		if save == selectedSave.Value then
			saveExists = true
			break
		end
	end
	if not saveExists then
		selectedSave.Value = ""
	end
end)

local loadButton: GuiButton = selectedSaveFrame.Load
loadButton.Activated:Connect(function()
	if not selectedSave then
		return
	end
	remotes.LoadSave:FireServer(selectedSave.Value)
end)

local overwriteButton: GuiButton = selectedSaveFrame.Overwrite
local function overwrite()
	if not selectedSave then
		return
	end
	remotes.Save:InvokeServer(selectedSave.Value, accessories)
end
overwriteButton.Activated:Connect(overwrite)

local deleteButton: GuiButton = selectedSaveFrame.Delete
deleteButton.Activated:Connect(function()
	if not selectedSave then
		return
	end
	remotes.DeleteSave:FireServer(selectedSave.Value)
	local saveButton = getSaveButton(selectedSave.Value)
	if saveButton then
		saveButton:Destroy()
	end
	selectedSave.Value = ""
end)

local newSaveFrame: Frame = savingFrame.Controls.NewSave
local createButton: GuiButton = newSaveFrame.CREATE
createButton.Activated:Connect(function()
	local saveName = (newSaveFrame.SaveNameTextBox :: TextBox).Text
	if saveName:len() == 0 then
		return
	end
	for _, save: string in remotes.ListSaves:InvokeServer() do
		if save == saveName then
			selectedSave.Value = save
			overwrite()
			return
		end
	end

	local name: util.NameInfo? = nil
	if config.Naming then
		name = localPlayer.PlayerScripts:FindFirstChild("Slapcode").NamesManager.GetOwnNametag:Invoke()
	end

	local success = remotes.Save:InvokeServer(saveName, accessories, name)
	if success then
		refreshSaves()
	end
end)

refreshSaves()
