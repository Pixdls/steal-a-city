--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
local Format = require(RS.Shared.Format)
local Data = require(script.Parent.Data)
local Income = {}
local started = false
function Income.GetRate(player: Player): number
 local data = Data.Get(player); if not data then return 0 end
 local rate = 0
 for _, slot in data.Slots do rate += Catalog.Income(slot.id,slot.variant) end
 return rate*(1+data.Rebirths*Config.REBIRTH_INCOME)*(if player:GetAttribute("DoubleCash") == true then 2 else 1)
end
local function offline(player: Player)
 local earned = math.floor(Income.GetRate(player)*Data.TakeOfflineSeconds(player)*Config.OFFLINE_RATE)
 if earned <= 0 then return end
 Data.Update(player,function(data: Data.PlayerData) data.Cash += earned end)
 -- Persist the message as an attribute too, so a late-loading HUD cannot miss it.
 local message = "While you were away: "..Format.Cash(earned)
 player:SetAttribute("OfflineNotice",message)
 ;(RS.Remotes.Notify :: RemoteEvent):FireClient(player,message)
end
function Income.Start()
 if started then return end; started = true
 Data.Loaded:Connect(offline)
 for _, player in Players:GetPlayers() do if Data.Get(player) then offline(player) end end
 task.spawn(function()
  while started do
   task.wait(1)
   for _, player in Players:GetPlayers() do
    local rate = Income.GetRate(player)
    if rate > 0 then Data.Update(player,function(data: Data.PlayerData) data.Cash += rate end) end
   end
  end
 end)
end
return Income
