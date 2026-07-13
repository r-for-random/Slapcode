local utilities = require(script.Parent.Parent.Util)
local remotes = game:GetService("ReplicatedStorage").Slapcode.remotes
local hideMenuBindable = remotes.HideMenu
local hideSubMenusBindable = remotes.CustomizationRemotes.HideAllSubMenus

return function(params: {
	button: GuiButton,
	player: Player,
})
	local player = params.player
	local button = params.button
	button.LayoutOrder = 0

	local customizationFrame = player.PlayerGui.SlapcodeGui.CustomizationMenu

	local visible = false

	local function toggleMenu()
		utilities.toggleMenu(customizationFrame, visible)
		visible = not visible
		if not visible then
			hideSubMenusBindable:Fire()
		end
	end

	button.Activated:Connect(toggleMenu)

	hideMenuBindable.Event:Connect(function(menu: Frame)
		if menu == customizationFrame and visible then
			toggleMenu()
		end
	end)
end
