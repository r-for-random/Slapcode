local ReplicatedStorage = game:GetService("ReplicatedStorage")

local util = {}

local slapcodeFolder = ReplicatedStorage.Slapcode
local config = require(slapcodeFolder.Config)
local SLIDING_TIME = config.MenuSlideTime

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
util.MenuSlideTweenInfo = TweenInfo.new(SLIDING_TIME, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local remotes = slapcodeFolder.remotes
local hideMenuBindable = remotes.HideMenu

local activeMenus = {}

function util.cleanUpNum(str: string): number?
	str = string.gsub(str, "[^%d%.]", "")
	return tonumber(str)
end

function util.toggleMenu(menu: Frame, currentVisibility: boolean)
	local slideInTween = TweenService:Create(menu, util.MenuSlideTweenInfo, { AnchorPoint = Vector2.new(1, 0.5) })
	local slideOutTween = TweenService:Create(menu, util.MenuSlideTweenInfo, { AnchorPoint = Vector2.new(0, 0.5) })

	if currentVisibility then
		slideOutTween:Play()
		local index = table.find(activeMenus, menu)
		table.remove(activeMenus, index)
	else
		for _, otherMenu in activeMenus do
			if otherMenu == menu then
				warn(
					`RPMenu: C Stack Overflow avoided! {otherMenu} was added to activeMenus in RPMenuUtilities despite currentVisibility being false or nil.`
				)
				continue
			end
			hideMenuBindable:Fire(otherMenu)
		end

		slideInTween:Play()
		table.insert(activeMenus, menu)
	end
end

return util
