--!strict
-- Carry pose for every character on this client: arms up while carrying,
-- a strained lean when the load is heavy. Poses are written to Motor6D
-- Transform after the Animator each frame, on top of the normal walk animation.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

type Pose = { arms: number, lean: number, bob: number }
local poses: { [Model]: Pose } = {}

local function joint(character: Model, r15: string, r15Parent: string, r6: string): Motor6D?
	local parent = character:FindFirstChild(r15Parent)
	local m = parent and parent:FindFirstChild(r15)
	if m and m:IsA("Motor6D") then
		return m
	end
	local torso = character:FindFirstChild("Torso")
	local m6 = torso and torso:FindFirstChild(r6)
	return if m6 and m6:IsA("Motor6D") then m6 else nil
end

local function targetFor(player: Player): (number, number)
	local ratio = player:GetAttribute("CarryRatio")
	if typeof(ratio) ~= "number" then
		return 0, 0
	end
	local strain = math.clamp((0.7 - ratio) / 0.45, 0, 1) -- 0 light, 1 crawling
	return 1, strain
end

local baseC0: { [Motor6D]: CFrame } = {}
local function setPose(m: Motor6D?, rot: CFrame)
	if not m then
		return
	end
	-- Pose through C0 (the joint's rest offset): the Animator only writes Transform,
	-- so the walk animation keeps playing on top of the raised arms.
	local base = baseC0[m]
	if not base then
		base = m.C0
		baseC0[m] = base
	end
	m.C0 = base * rot
end

RunService.Heartbeat:Connect(function(dt)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local pose = poses[character]
		if not pose then
			pose = { arms = 0, lean = 0, bob = 0 }
			poses[character] = pose
		end
		local arms, strain = targetFor(player)
		local k = math.min(1, dt * 10)
		pose.arms += (arms - pose.arms) * k
		pose.lean += (strain - pose.lean) * k
		if pose.arms < 0.005 and pose.lean < 0.005 and pose.bob == 0 then
			continue
		end
		pose.bob = (pose.arms < 0.005 and pose.lean < 0.005) and 0 or pose.bob + dt * (4 - 2.5 * strain)
		local lift = math.rad(165) * pose.arms
		local wobble = math.sin(pose.bob) * math.rad(4) * pose.lean
		setPose(joint(character, "RightShoulder", "RightUpperArm", "Right Shoulder"), CFrame.Angles(-lift, 0, math.rad(12) * pose.arms + wobble))
		setPose(joint(character, "LeftShoulder", "LeftUpperArm", "Left Shoulder"), CFrame.Angles(-lift, 0, -math.rad(12) * pose.arms - wobble))
		local waist = joint(character, "Waist", "UpperTorso", "Neck")
		if waist and waist.Name == "Waist" then
			setPose(waist, CFrame.Angles(math.rad(-22) * pose.lean, math.sin(pose.bob * 2) * math.rad(5) * pose.lean, 0))
		end
	end
end)

local function forget(character: Model)
	poses[character] = nil
	for m in baseC0 do
		if m:IsDescendantOf(character) then
			baseC0[m] = nil
		end
	end
end
Players.PlayerRemoving:Connect(function(player)
	if player.Character then
		forget(player.Character)
	end
end)
for _, player in Players:GetPlayers() do
	player.CharacterRemoving:Connect(forget)
end
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(forget)
end)
