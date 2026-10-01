--!strict
-- Data: the ONLY module that writes saved player data (plan §9).
-- Other systems read with Data.Get and write with Data.Update.
-- Saves data, never instances: plot slots are {id, variant, lockedUntil}.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local ProfileStore = require(ServerScriptService.Packages.ProfileStore)

export type Slot = {
	id: string,
	variant: string,
	lockedUntil: number,
}

local TEMPLATE = {
	Coins = 0,
	Size = 1,
	Rebirths = 0, -- integer; multiplier is computed at income time
	Slots = {} :: { Slot },
	Collection = {} :: { [string]: { [string]: boolean } }, -- [objectId][variant] = true
	Deliveries = 0,
	PlayerThefts = 0, -- successful thefts from other players (ends the shield)
	LastSeen = 0, -- os.time() at last save, for offline earnings
	Funnel = {} :: { [string]: boolean }, -- onboarding steps already logged
}

export type PlayerData = typeof(TEMPLATE)

local store = ProfileStore.New(Config.DATA_STORE_NAME, TEMPLATE)
local profiles: { [Player]: any } = {}
local offlineSeconds: { [Player]: number } = {}

local loadedEvent = Instance.new("BindableEvent")

local Data = {}

-- Fires (player, data) once a player's profile is ready.
Data.Loaded = loadedEvent.Event

-- Attributes mirrored onto the Player so clients and UI can read them.
local MIRRORED = { "Coins", "Size", "Rebirths" }

local function mirror(player: Player, data: PlayerData)
	for _, key in MIRRORED do
		player:SetAttribute(key, (data :: any)[key])
	end
end

local function onPlayerAdded(player: Player)
	local profile = store:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("Could not load your data. Please rejoin.")
		return
	end

	profile:AddUserId(player.UserId) -- GDPR
	profile:Reconcile()

	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		offlineSeconds[player] = nil
		player:Kick("Your data session ended. Please rejoin.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	local data = profile.Data :: PlayerData
	local now = os.time()
	if data.LastSeen > 0 then
		offlineSeconds[player] = math.clamp(now - data.LastSeen, 0, Config.OFFLINE_CAP_SECONDS)
	else
		offlineSeconds[player] = 0
	end
	data.LastSeen = now

	profiles[player] = profile
	mirror(player, data)
	loadedEvent:Fire(player, data)
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile.Data.LastSeen = os.time()
		profile:EndSession()
	end
end

-- Read-only by convention. Returns nil if the profile isn't loaded yet.
function Data.Get(player: Player): PlayerData?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- All writes go through here. Returns false if the profile isn't loaded.
function Data.Update(player: Player, mutate: (data: PlayerData) -> ()): boolean
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return false
	end
	mutate(profile.Data)
	mirror(player, profile.Data)
	return true
end

-- Seconds offline (already clamped to the cap). Returns it once, then 0,
-- so the economy system can't pay offline income twice.
function Data.TakeOfflineSeconds(player: Player): number
	local seconds = offlineSeconds[player] or 0
	offlineSeconds[player] = 0
	return seconds
end

-- Logs an onboarding funnel step once per player (plan §5).
function Data.LogFunnel(player: Player, step: string)
	Data.Update(player, function(data)
		if not data.Funnel[step] then
			data.Funnel[step] = true
			print(`[Funnel] {player.UserId} {step}`)
			-- TODO week 4: send to AnalyticsService:LogFunnelStepEvent
		end
	end)
end

function Data.Start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return Data
