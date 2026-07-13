local remotes = game:GetService("ReplicatedStorage").Slapcode.remotes.OOCRemotes
local oocRemote = remotes.ToggleOOC

local ooc = false

return function(params: {
	button: GuiButton,
	player: Player,
})
	local player = params.player
	local button = params.button
	button.LayoutOrder = 3

	local debounce = false
	button.Activated:Connect(function()
		if debounce then
			return
		end
		debounce = true

		ooc = not ooc
		oocRemote:FireServer(ooc)

		task.wait(1)
		debounce = false
	end)
end
