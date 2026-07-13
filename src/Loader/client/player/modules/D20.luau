local config = require(game.ReplicatedStorage.Slapcode.Config)
local utilities = require(script.Parent.Parent.Util)
local remotes = game.ReplicatedStorage.Slapcode.remotes
local hideMenuBindable = remotes.HideMenu
local hideSubMenusBindable = remotes.CustomizationRemotes.HideAllSubMenus

if not config.DiceTypes or #config.DiceTypes == 0 then
	error("No dice types to use D20 with. Update this in RPModules.Utilities.Config.")
end

return function(params: {
	button: GuiButton,
	player: Player,
})
	local player = params.player
	local button = params.button
	button.LayoutOrder = 2

	local diceFrame = player.PlayerGui.SlapcodeGui.DiceMenu

	local visible = false

	local function toggleMenu()
		utilities.toggleMenu(diceFrame, visible)
		hideSubMenusBindable:Fire()
		visible = not visible
	end

	button.Activated:Connect(toggleMenu)

	hideMenuBindable.Event:Connect(function(menu: Frame)
		if menu == diceFrame and visible then
			toggleMenu()
		end
	end)
end
