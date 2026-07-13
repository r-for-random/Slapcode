--!strict
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local TextService = game:GetService("TextService")
local shared = game:GetService("ReplicatedStorage"):WaitForChild("Slapcode")
local config = require(shared:WaitForChild("Config"))

if not config.Naming then
	return
end

local remotes = shared.remotes.NameRemotes :: Folder
local createNametag = remotes:FindFirstChild("CreateNametag") :: RemoteEvent
local updateNametag = remotes:FindFirstChild("UpdateNametag") :: RemoteEvent
local destroyNametag = remotes:FindFirstChild("DestroyNametag") :: RemoteEvent
local sendCooldown = remotes:FindFirstChild("SendCooldown") :: RemoteEvent

local names: { [Player]: { Name: string, Bio: string, Font: string, FillColor: { [string]: number }, OutlineColor: { [string]: number } } } =
	{}

StarterPlayer.NameDisplayDistance = 0

Players.PlayerAdded:Connect(function(player)
	for _, otherPlayer in Players:GetChildren() do
		if not otherPlayer:IsA("Player") then
			continue
		end
		if otherPlayer == player then
			continue
		end
		if not names[otherPlayer] then
			warn(`{otherPlayer.Name} not keyed in names dictionary`)
			continue
		end
		createNametag:FireClient(player, otherPlayer, names[otherPlayer])
	end

	player.CharacterAdded:Connect(function(character)
		if not names[player] then
			names[player] = {
				Name = player.Name,
				Bio = "",
				Font = config.DefaultNametagFont,
				FillColor = config.DefaultNametagFillColor,
				OutlineColor = config.DefaultNametagOutlineColor,
			}
		else
			destroyNametag:FireAllClients(player)
		end
		createNametag:FireAllClients(player, names[player])
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	names[player] = nil
	destroyNametag:FireAllClients(player)
end)

-- updating nametag info
local RATE_LIMIT = 60 -- seconds
local lastNameUpdateTimes: { [number]: number } = {}
local lastBioUpdateTimes: { [number]: number } = {}

local function canUpdate(player: Player, param: "Name" | "Bio"): (boolean, number)
	local table = if param == "Name" then lastNameUpdateTimes else lastBioUpdateTimes

	local lastUpdateTime = table[player.UserId]
	if not lastUpdateTime then
		return true, 0
	end

	local timeSinceLastUpdate = tick() - lastUpdateTime
	return timeSinceLastUpdate > RATE_LIMIT, math.max(RATE_LIMIT - timeSinceLastUpdate, 0)
end

updateNametag.OnServerEvent:Connect(
	function(player, param: "Name" | "Bio" | "Font" | "FillColor" | "OutlineColor", text: string)
		if param == "Name" or param == "Bio" then
			local canUpdate, cooldown = canUpdate(player, param)
			if not canUpdate then
				sendCooldown:FireClient(player, param, cooldown)
				return
			end
			if param == "Name" then
				lastNameUpdateTimes[player.UserId] = tick()
			else
				lastBioUpdateTimes[player.UserId] = tick()
			end

			local success, filterResult = pcall(function()
				return TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
			end)
			if not success then
				error(filterResult)
			end
			text = filterResult:GetNonChatStringForBroadcastAsync()
		end
		names[player][param] = text
		updateNametag:FireAllClients(player, names[player])
	end
)
