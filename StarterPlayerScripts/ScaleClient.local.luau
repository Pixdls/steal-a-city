--!strict
-- Applies each player's "Scale" attribute to their character on this client
-- (plan §9). Every client scales every character, so everyone sees the same
-- giants. For the local player it also scales jump and camera zoom.
--
-- Untested starter: verify in Studio during week 1 (check HipHeight at spawn,
-- and that remote giants don't sink into the ground).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local localPlayer = Players.LocalPlayer

local BASE_JUMP_POWER = StarterPlayer.CharacterJumpPower
local BASE_MAX_ZOOM = StarterPlayer.CameraMaxZoomDistance

local tweenInfo = TweenInfo.new(Config.SCALE_TWEEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local function applyLocalStats(character: Model, scale: number)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = BASE_JUMP_POWER * math.sqrt(scale)
	end
	localPlayer.CameraMaxZoomDistance = BASE_MAX_ZOOM * scale
end

local function watchCharacter(player: Player, character: Model)
	local current = Instance.new("NumberValue")
	current.Value = character:GetScale()

	current.Changed:Connect(function(value)
		if character.Parent then
			character:ScaleTo(value)
		end
	end)

	local activeTween: Tween? = nil
	local function onScaleChanged(instant: boolean)
		local target = player:GetAttribute("Scale")
		if typeof(target) ~= "number" then
			return
		end
		target = math.clamp(target, Config.MIN_SCALE, Config.MAX_SCALE)
		if instant then
			current.Value = target
		else
			if activeTween then activeTween:Cancel() end
			activeTween = TweenService:Create(current, tweenInfo, { Value = target })
			;(activeTween :: Tween):Play()
		end
		if player == localPlayer then
			applyLocalStats(character, target)
		end
	end

	local connection = player:GetAttributeChangedSignal("Scale"):Connect(function()
		onScaleChanged(false)
	end)
	character.Destroying:Connect(function()
		connection:Disconnect()
		if activeTween then activeTween:Cancel() end
		current:Destroy()
	end)

	character:WaitForChild("Humanoid")
	onScaleChanged(true) -- respawn at full size, no tween
end

local function watchPlayer(player: Player)
	if player.Character then
		task.spawn(watchCharacter, player, player.Character)
	end
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
end

for _, player in Players:GetPlayers() do
	watchPlayer(player)
end
Players.PlayerAdded:Connect(watchPlayer)
