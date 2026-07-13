local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")

local Loader = {}

function Loader.startup()
	local client = script.client
	local player = client.player
	local character = client.character
	local shared = script.shared
	local gui = client.gui
	local modules = player.modules

	shared.Name = "Slapcode"
	shared.Parent = ReplicatedStorage
	script.Parent.Config.Parent = shared

	for _, child in gui:GetChildren() do
		child.Parent = StarterGui
	end

	player.Name = "Slapcode"
	player.Parent = StarterPlayer.StarterPlayerScripts
	character.Name = "Slapcode"
	character.Parent = StarterPlayer.StarterCharacterScripts
end

return Loader
