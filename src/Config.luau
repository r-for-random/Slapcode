local config = {}

-- MODULES
config.OOC = true
config.D20 = true
config.Naming = true
config.Customization = true

-- GLOBALS
config.MenuSlideTime = 0.5 -- the time it takes in seconds for all of the menus to slide in and out

-- CUSTOMIZATION
config.Increment = 0.01 -- I do not recommend changing this
config.Bounds = Vector3.new(10, 10, 10) -- x, y, z values for accessory movement bounds
config.BoundsOffset = Vector3.new(0, 1.5, 0)
config.BoundingBoxColor = Color3.fromRGB(85, 255, 127)
config.MaxAccessoryCount = 100
config.MaxPlayerScale = 1.2
config.MinPlayerScale = 0.8
config.MaxSaves = 100

-- DICE
config.DiceTypes = {
	{
		name = "d6",
		numSides = 6,
	},

	{
		name = "d12",
		numSides = 12,
	},

	{
		name = "d20",
		numSides = 20,
	},

	{
		name = "Make your own in the config!",
		numSides = 100000,
	},
}

-- NAMING
config.MaxNameChars = 30
config.MaxBioChars = 2000
config.NametagCustomization = true -- If this is set to false, all players will have to use the default font and colors below
config.DefaultNametagFont = "RobotoCondensed" -- If you enter an invalid font name here, it'll default to Creepster
config.DefaultNametagFillColor = { R = 255, G = 255, B = 255 }
config.DefaultNametagOutlineColor = { R = 0, G = 0, B = 0 }

return config
