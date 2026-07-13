local utilities = require(script.Parent.Parent.Util)
local remotes = game.ReplicatedStorage.Slapcode.remotes
local hideMenuBindable = remotes.HideMenu

return function(params: {
	button: GuiButton,
	player: Player,
})
	local player = params.player
	local button = params.button
	button.LayoutOrder = 1

	local namingFrame = player.PlayerGui.SlapcodeGui.NamingMenu

	local visible = false

	local function toggleMenu()
		utilities.toggleMenu(namingFrame, visible)
		visible = not visible
	end

	button.Activated:Connect(toggleMenu)

	hideMenuBindable.Event:Connect(function(menu: Frame)
		if menu == namingFrame and visible then
			toggleMenu()
		end
	end)
end
