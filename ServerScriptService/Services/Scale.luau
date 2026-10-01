--!strict
-- Scale: the server decides how big each player looks (plan §9).
-- It only sets the "Scale" attribute on the Player; every client applies
-- Model:ScaleTo locally (server-side scaling jitters).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Data = require(script.Parent.Data)

local Scale = {}

local function refresh(player: Player)
	local size = player:GetAttribute("Size")
	if typeof(size) == "number" then
		player:SetAttribute("Scale", Config.ScaleForSize(size))
	end
end

function Scale.Start()
	Data.Loaded:Connect(function(player: Player)
		refresh(player)
		player:GetAttributeChangedSignal("Size"):Connect(function()
			refresh(player)
		end)
	end)
end

return Scale
