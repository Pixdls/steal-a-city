--!strict
-- Server entry point. Starts each service in order.

local Services = script.Parent.Services

local Data = require(Services.Data)
local Scale = require(Services.Scale)

Scale.Start() -- connect to Data.Loaded before Data starts loading players
Data.Start()

print("[Steal a City] server started")
