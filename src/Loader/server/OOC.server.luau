local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Slapcode").remotes.OOCRemotes
local oocRemote = remotes.ToggleOOC

local beams: { [string]: Beam } = {}
local clones: { [string]: Model } = {}
local transparencyCache: { [Player]: { [Instance]: number } } = {}

local OOC_TRANSPARENCY_MULT = 0.7
local OOC_CGROUP_NAME = "OOC Clone"

PhysicsService:RegisterCollisionGroup(OOC_CGROUP_NAME)
for _, group in PhysicsService:GetRegisteredCollisionGroups() do
	PhysicsService:CollisionGroupSetCollidable(OOC_CGROUP_NAME, group.name, false)
end

Players.PlayerAdded:Connect(function(player)
	transparencyCache[player] = {}
end)
Players.PlayerRemoving:Connect(function(player: Player)
	transparencyCache[player] = nil
end)

local function getHumanoidRootPart(char)
	return char.HumanoidRootPart
end

local function disableCollision(char: Model)
	getHumanoidRootPart(char).Anchored = true
	for _, part in char:GetChildren() do
		if not part:IsA("BasePart") then
			continue
		end
		part.CollisionGroup = OOC_CGROUP_NAME
	end
end

local function goTransparent(player: Player)
	local char = player.Character
	for _, part in char:GetDescendants() do
		if (part:IsA("BasePart") or part:IsA("Decal")) and part.Transparency ~= 1 then
			if part.Transparency ~= 0 then
				transparencyCache[player][part] = part.Transparency
			end
			part.Transparency = 1 - ((1 - part.Transparency) * (1 - OOC_TRANSPARENCY_MULT))
		end
	end
end

local function goOpaque(player: Player)
	local char = player.Character
	for _, part in char:GetDescendants() do
		if (part:IsA("BasePart") or part:IsA("Decal")) and part.Transparency ~= 1 then
			local transparencyValue = transparencyCache[player][part]
			if not transparencyValue then
				transparencyValue = 0
			end
			part.Transparency = transparencyValue
		end
	end
end

local function createBeam(char0, char1)
	local att0 = Instance.new("Attachment")
	att0.Parent = getHumanoidRootPart(char0)
	local att1 = Instance.new("Attachment")
	att1.Parent = getHumanoidRootPart(char1)

	local beam = Instance.new("Beam")
	beam:SetAttribute("Player", char1.Name)
	beams[char0.Name] = beam

	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Parent = game.Workspace
end

local function cleanUpOOCStuff(name)
	local clone = clones[name]
	local beam = beams[name]

	if clone then
		clone:Destroy()
		clones[name] = nil
	end
	if beam then
		beam:Destroy()
		beams[name] = nil
	end
end

local function clonePlayer(char)
	local humanoid = char.Humanoid
	humanoid:UnequipTools()
	task.wait(0.2)

	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = false

	clone.Parent = game.Workspace
	disableCollision(clone)
	return clone
end

function enterOOC(player)
	local char = player.Character
	local clonedChar = clonePlayer(char)
	goTransparent(player)
	createBeam(char, clonedChar)
	clones[player.Name] = clonedChar

	local function onDeath()
		cleanUpOOCStuff(clonedChar)
	end

	local function onLeave(charCheck)
		if charCheck.Name == char.Name then
			cleanUpOOCStuff(clonedChar)
		end
	end

	local humanoid = char.Humanoid
	player.CharacterRemoving:Connect(onLeave)
end

function exitOOC(player)
	local char = player.Character
	local clone = clones[player.Name]

	if clone then
		char:PivotTo(clone:GetPivot())
		goOpaque(player)
	end

	cleanUpOOCStuff(player.Name)
end

oocRemote.OnServerEvent:Connect(function(player, state)
	if state then
		enterOOC(player)
	else
		exitOOC(player)
	end
end)
