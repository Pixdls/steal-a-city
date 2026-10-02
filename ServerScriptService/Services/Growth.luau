--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Format = require(RS.Shared.Format)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Growth = {}
type Lift = {root: BasePart, humanoid: Humanoid, anchored: boolean, connection: RBXScriptConnection}
local lifting: {[Player]: Lift} = {}
local started = false
function Growth.GetBenchRate(player: Player): number
 local data = Data.Get(player)
 if not data then return 0 end
 local tier = Config.BENCH_TIERS[math.clamp(data.BenchLevel,1,#Config.BENCH_TIERS)]
 return tier.rate*(1+data.Rebirths*Config.REBIRTH_GROWTH)*(if player:GetAttribute("DoubleGrowth") == true then 2 else 1)
end
function Growth.Refresh(player: Player)
 local data = Data.Get(player)
 if not data then return end
 player:SetAttribute("Scale",Config.ScaleForSize(data.Size))
 local multiplier = Config.SpeedForSize(data.Size)
 if player:GetAttribute("SlowMode") == true then multiplier = math.min(multiplier,Config.SLOW_MULTIPLIER) end
 local weight = player:GetAttribute("CarryWeight")
 local ratio = if typeof(weight) == "number" then math.clamp((data.Size/math.max(weight,1))^Config.CARRY_EXPONENT,Config.CARRY_MIN_RATIO,1) else 1
 if typeof(weight) == "number" then player:SetAttribute("CarryRatio",ratio) else player:SetAttribute("CarryRatio",nil) end
 local humanoid = if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
 if humanoid then humanoid.WalkSpeed = if lifting[player] then 0 else Config.BASE_WALK_SPEED*multiplier*ratio end
end
function Growth.StopLifting(player: Player)
 local state = lifting[player]
 if not state then return end
 lifting[player] = nil; state.connection:Disconnect()
 if state.root.Parent then state.root.Anchored = state.anchored end
 if state.humanoid.Parent then state.humanoid.Sit = false end
 player:SetAttribute("Lifting",false); Growth.Refresh(player)
end
local function sign(player: Player)
 local plot = Plots.GetPlot(player); local data = Data.Get(player)
 local bench = if plot then plot:FindFirstChild("BenchPress") else nil
 local board = if bench then bench:FindFirstChild("UpgradeSign") else nil
 local label = if board then board:FindFirstChildWhichIsA("TextLabel",true) else nil
 if not data or not label then return end
 local nextTier = Config.BENCH_TIERS[data.BenchLevel+1]
 label.Text = if nextTier then `Level {data.BenchLevel} -> {data.BenchLevel+1}  {if data.Funnel.freeBench then Format.Cash(nextTier.cost) else "FREE"}` else `Level {data.BenchLevel} · MAX`
end
local function attach(player: Player, plot: Model)
 local bench = plot:FindFirstChild("BenchPress")
 local part = if bench then bench:FindFirstChild("Prompt") else nil
 local seat = if bench then bench:FindFirstChild("Seat") else nil
 if not part or not part:IsA("BasePart") or not seat or not seat:IsA("BasePart") then return end
 -- Plot prompts survive ownership changes; callbacks resolve the current owner.
 if part:FindFirstChild("LiftPrompt") then sign(player); return end
 local function valid(who: Player): (BasePart?, Humanoid?)
  if Plots.GetPlot(who) ~= plot or not Data.Get(who) then return nil,nil end
  local character = who.Character
  local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
  local hum = if character then character:FindFirstChildOfClass("Humanoid") else nil
  if not root or not root:IsA("BasePart") or not hum or hum.Health <= 0 or (root.Position-part.Position).Magnitude > Config.BENCH_DISTANCE+Config.PICKUP_TOLERANCE then return nil,nil end
  return root,hum
 end
 local lift = Instance.new("ProximityPrompt"); lift.Name = "LiftPrompt"; lift.ActionText = "Lift"; lift.RequiresLineOfSight = false; lift.MaxActivationDistance = Config.BENCH_DISTANCE; lift.Parent = part
 lift.Triggered:Connect(function(who: Player)
  if lifting[who] then Growth.StopLifting(who); return end
  local root,hum = valid(who)
  if not root or not hum or who:GetAttribute("CarryRatio") ~= nil or root.Anchored then return end
  local anchored = root.Anchored
  root.CFrame = seat.CFrame+Vector3.new(0,Config.SPAWN_CLEARANCE/2,0); root.Anchored = true; hum.Sit = true
  local connection = hum:GetPropertyChangedSignal("Jump"):Connect(function() if hum.Jump then Growth.StopLifting(who) end end)
  lifting[who] = {root=root,humanoid=hum,anchored=anchored,connection=connection}
  who:SetAttribute("Lifting",true); Growth.Refresh(who)
 end)
 local upgrade = Instance.new("ProximityPrompt"); upgrade.Name = "UpgradePrompt"; upgrade.ActionText = "Upgrade"; upgrade.KeyboardKeyCode = Enum.KeyCode.F; upgrade.UIOffset = Vector2.new(0,70); upgrade.RequiresLineOfSight = false; upgrade.MaxActivationDistance = Config.BENCH_DISTANCE; upgrade.Parent = part
 upgrade.Triggered:Connect(function(who: Player)
  local root = valid(who); if not root then return end
  Data.Update(who,function(data: Data.PlayerData)
   local tier = Config.BENCH_TIERS[data.BenchLevel+1]; if not tier then return end
   local cost = if data.Funnel.freeBench then tier.cost else 0
   if data.Cash < cost then return end
   data.Cash -= cost; data.BenchLevel += 1; data.Funnel.freeBench = true
  end)
 end)
 sign(player)
end
function Growth.Start()
 if started then return end; started = true
 local remotes = RS:WaitForChild("Remotes")
 ;(remotes.SlowMode :: RemoteEvent).OnServerEvent:Connect(function(player: Player,on: any)
  if typeof(on) ~= "boolean" then return end
  player:SetAttribute("SlowMode",on); Growth.Refresh(player)
 end)
 ;(remotes.StopLifting :: RemoteEvent).OnServerEvent:Connect(function(player: Player) Growth.StopLifting(player) end)
 Plots.Assigned:Connect(attach)
 local function watch(player: Player)
  player:GetAttributeChangedSignal("CarryWeight"):Connect(function() Growth.Refresh(player) end)
  player.CharacterAdded:Connect(function(character)
   Growth.StopLifting(player)
   local hum = character:WaitForChild("Humanoid",10)
   if hum and hum:IsA("Humanoid") then hum.Died:Connect(function() Growth.StopLifting(player) end); Growth.Refresh(player) end
  end)
  local plot = Plots.GetPlot(player); if plot then attach(player,plot) end
  Growth.Refresh(player)
 end
 Players.PlayerAdded:Connect(watch); for _, player in Players:GetPlayers() do watch(player) end
 Players.PlayerRemoving:Connect(Growth.StopLifting)
 Data.Loaded:Connect(function(player: Player) Growth.Refresh(player); sign(player) end)
 Data.Changed:Connect(function(player: Player) Growth.Refresh(player); sign(player) end)
 task.spawn(function()
  while started do
   task.wait(1)
   for player,state in lifting do
    if not state.root.Parent or state.humanoid.Health <= 0 or state.humanoid.MoveDirection.Magnitude > 0 or state.humanoid.Jump then Growth.StopLifting(player)
    else local rate = Growth.GetBenchRate(player); Data.Update(player,function(data: Data.PlayerData) data.Size += rate end) end
   end
  end
 end)
end
return Growth
