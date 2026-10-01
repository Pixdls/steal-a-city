--!strict
-- Tunable numbers from the game plan (v3). Shared by server and client.
-- Change values here, not inline in systems.

local Config = {}

-- Size / scale (plan §4, §9)
Config.MIN_SCALE = 1
Config.MAX_SCALE = 4 -- visible avatar scale cap; numeric Size keeps rising past it
Config.SCALE_TWEEN_TIME = 0.6
Config.SIZE_AT_MAX_SCALE = 100 -- placeholder curve: Size 1 -> 1x, Size 100+ -> 4x (tune in week 2)

-- Plots (plan §3)
Config.PLOT_COUNT = 8
Config.MAX_PLAYERS = 8

-- Economy (plan §4)
Config.OFFLINE_CAP_SECONDS = 8 * 60 * 60
Config.OFFLINE_RATE = 0.5 -- judgement call: "reduced rate" is not specified in the plan
Config.LONG_NAP_CAP_SECONDS = 24 * 60 * 60

-- Theft protection (plan §4)
Config.SHIELD_UNTIL_SIZE = 10
Config.JOIN_LOCK_SECONDS = 30

-- Onboarding (plan §4, §5)
Config.NO_CATCH_UNTIL_DELIVERY = 3

-- Variants multiply income (plan §4)
Config.VARIANT_MULTIPLIER = {
	Normal = 1,
	Gold = 3,
	Neon = 5,
	Frozen = 8,
	Rainbow = 10,
	Seasonal = 12,
}

-- Size -> visible scale. Linear placeholder; swap for a curve that feels good.
function Config.ScaleForSize(size: number): number
	local t = math.clamp((size - 1) / (Config.SIZE_AT_MAX_SCALE - 1), 0, 1)
	return Config.MIN_SCALE + (Config.MAX_SCALE - Config.MIN_SCALE) * t
end

-- Data store name. Bump the suffix only to wipe all test data.
Config.DATA_STORE_NAME = "PlayerData_v1"

return Config
