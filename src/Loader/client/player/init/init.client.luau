local Players = game:GetService("Players")

local config = require(game:GetService("ReplicatedStorage").Slapcode.Config)

local menu = Players.LocalPlayer.PlayerGui:WaitForChild("SlapcodeGui").RPMenu
local frame = menu.Frame
local buttonTemplate = script:WaitForChild("Button")
local buttons = {}

for _, module: ModuleScript in script.Parent.modules:GetChildren() do
	if not config[module.Name] then
		continue
	end

	if not module:IsA("ModuleScript") then
		continue
	end
	local required
	xpcall(function()
		required = require(module)
	end, function(err)
		warn(`Slapcode: Error loading '{module:GetFullName()}': {err}`)
	end)

	if required then
		local button = buttonTemplate:Clone()
		button.Parent = frame
		button.Text = module:GetAttribute("ButtonText") or module.Name
		button.Name = module.Name
		required({
			button = button,
			player = game.Players.LocalPlayer,
		})

		table.insert(buttons, button)
		print(`Slapcode: Loaded {module.Name}!`)
	end
end

if #buttons > 0 then
	menu.ImageButton.Visible = true
end
