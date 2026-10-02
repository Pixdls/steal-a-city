--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
local Carry = require(script.Parent.Carry)
local Data = require(script.Parent.Data)
local Ragdoll = require(script.Parent.Ragdoll)
local WorldObjects = require(script.Parent.WorldObjects)
local Chasers = {}
type Agent = {handle: WorldObjects.Handle, model: Model, root: BasePart, hum: Humanoid, owner: Player?, info: Carry.CarryInfo?, home: Vector3, mode: string, since: number, sampleAt: number, sample: Vector3}
local agents: {Agent} = {}
local tickets: {[Player]: number} = {}
local random = Random.new()
local live: Folder
local started = false
local function rootOf(player: Player): BasePart?
 local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
 return if root and root:IsA("BasePart") then root else nil
end
function Chasers.IsSafePosition(position: Vector3): boolean
 if position.Z >= 0 then return true end
 local map = workspace:FindFirstChild("Map"); local home = if map then map:FindFirstChild("Home") else nil
 local safe = if home then home:FindFirstChild("SafeZone") else nil
 if safe and safe:IsA("BasePart") then
  local p = safe.CFrame:PointToObjectSpace(position); local h = safe.Size/2
  return math.abs(p.X)<=h.X and math.abs(p.Y)<=h.Y and math.abs(p.Z)<=h.Z
 end
 return false
end
local function posts(stage: string): {BasePart}
 local map = workspace:FindFirstChild("Map"); local stages = if map then map:FindFirstChild("Stages") else nil
 local folder = if stages then stages:FindFirstChild(stage) else nil
 local markers = if folder then folder:FindFirstChild("ChaserPosts") else nil
 local result: {BasePart} = {}
 if markers then for _, marker in markers:GetChildren() do if marker:IsA("BasePart") then table.insert(result,marker) end end end
 return result
end
local function makeModel(id: string, giant: boolean): (Model, Humanoid, BasePart)
 local assets = RS:FindFirstChild("Assets"); local folder = if assets then assets:FindFirstChild("Chasers") else nil
 local source = if folder then folder:FindFirstChild(id) else nil
 local model = if source and source:IsA("Model") then source:Clone() else Instance.new("Model")
 local hum = model:FindFirstChildOfClass("Humanoid")
 local root = model:FindFirstChild("HumanoidRootPart")
 if not hum or not root or not root:IsA("BasePart") then
  model:Destroy(); model = Instance.new("Model")
  local block = Instance.new("Part"); block.Name="HumanoidRootPart"; block.Size=Vector3.new(3,3,3)
  block.Color=if id=="RanchDog" then Color3.fromRGB(158,96,48) else Color3.fromRGB(57,85,171)
  block.Parent=model; root=block
  hum=Instance.new("Humanoid"); hum.RequiresNeck=false; hum.HipHeight=0; hum.Parent=model
 end
 local body = root :: BasePart; local humanoid = hum :: Humanoid
 model.Name=id; model.PrimaryPart=body
 for _, child in model:GetDescendants() do
  if child:IsA("Script") or child:IsA("LocalScript") then child:Destroy()
  elseif child:IsA("BasePart") then child.Anchored=false; child.CollisionGroup="Chasers" end
 end
 if giant then model:ScaleTo(2) end
 humanoid.WalkSpeed=Config.BASE_WALK_SPEED*Catalog.Chasers[id].speedMultiplier
 humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
 model.Parent=live
 for _, part in model:GetDescendants() do
  if part:IsA("BasePart") and not part.Anchored then pcall(function() part:SetNetworkOwner(nil) end) end
 end
 return model,humanoid,body
end
local function ground(position: Vector3, root: BasePart, hum: Humanoid): Vector3
 -- The contract's road is flat at y=0; do not raycast onto stealable rooftops.
 return Vector3.new(position.X,root.Size.Y/2+hum.HipHeight,math.min(position.Z,Config.CHASER_GATE_Z))
end
local function goHome(agent: Agent)
 agent.mode="home"; agent.since=os.clock(); agent.owner=nil; agent.info=nil
end
local function stop(player: Player, _info: Carry.CarryInfo, _reason: string?)
 tickets[player]=(tickets[player] or 0)+1
 for _, agent in agents do
  if agent.owner==player then
   local root=rootOf(player)
   if root and Chasers.IsSafePosition(root.Position) then agent.mode="gate"; agent.since=os.clock(); agent.info=nil
   else goHome(agent) end
  end
 end
end
local function pickup(player: Player, info: Carry.CarryInfo)
 local root=rootOf(player)
 if not root or Chasers.IsSafePosition(root.Position) then return end
 local stage=Catalog.Stages[info.stage]; if not stage then return end
 -- A re-pickup replaces this handle's returning agents, including another owner's.
 for i=#agents,1,-1 do
  local a=agents[i]
  if a.handle==info.handle or a.owner==player then a.model:Destroy(); table.remove(agents,i) end
 end
 tickets[player]=(tickets[player] or 0)+1; local ticket=tickets[player]
 local isRush=info.handle.availableAt>0
 local data=Data.Get(player); local ratio=info.weight/math.max(if data then data.Size else Config.START_SIZE,1)
 local count=math.min(Config.CHASER_MAX_PER_PLAYER,if ratio<0.5 then 1 elseif ratio<=1.5 then 2 else 3)
 ;(RS.Remotes.Notify :: RemoteEvent):FireClient(player,{kind="chaser",message="Here they come!",sound="chaserWarning",stage=info.stage,delay=Config.CHASER_WARNING})
 task.delay(Config.CHASER_WARNING,function()
  local current=rootOf(player)
  if tickets[player]~=ticket or Carry.GetCarry(player)~=info or not current or Chasers.IsSafePosition(current.Position) then return end
  local markers=posts(info.stage)
  for i=1,math.min(count,Config.CHASER_MAX_SERVER-#agents) do
   local object=Catalog.GetObject(info.id)
   local model,hum,body=makeModel(stage.chaser,i==1 and object~=nil and object.tier=="showpiece")
   local distance=if isRush then Config.CHASER_RUSH_DISTANCE else random:NextNumber(Config.CHASER_SPAWN_MIN,Config.CHASER_SPAWN_MAX)
   local pos=ground(Vector3.new(math.clamp(current.Position.X+(i-2)*4,-stage.halfWidth+4,stage.halfWidth-4),0,current.Position.Z-distance),body,hum)
   model:PivotTo(CFrame.new(pos)); body.AssemblyLinearVelocity=Vector3.zero
   local home=if #markers>0 then markers[(i-1)%#markers+1].Position else info.handle.marker.Position
   table.insert(agents,{handle=info.handle,model=model,root=body,hum=hum,owner=player,info=info,home=home,mode="chase",since=os.clock(),sampleAt=os.clock(),sample=pos})
  end
 end)
end
local function tick()
 local now=os.clock()
 for i=#agents,1,-1 do
  local a=agents[i]
  if not a.model.Parent or a.hum.Health<=0 then a.model:Destroy(); table.remove(agents,i); continue end
  -- Clamp even a physics overshoot before the next movement command.
  if a.root.Position.Z>Config.CHASER_GATE_Z then
   a.model:PivotTo(CFrame.new(ground(a.root.Position,a.root,a.hum))); a.root.AssemblyLinearVelocity=Vector3.zero
  end
  local target=a.home
  if a.mode=="chase" then
   local owner=a.owner; local root=if owner then rootOf(owner) else nil
   if not owner or not root or Carry.GetCarry(owner)~=a.info then goHome(a)
   elseif Chasers.IsSafePosition(root.Position) then
    a.mode="gate"; a.since=now
    ;(RS.Remotes.Notify :: RemoteEvent):FireClient(owner,{kind="chaser",sound="chaserGate",message="Safe!",stage=if a.info then a.info.stage else ""})
   else
    target=root.Position
    local tolerance=math.min(Config.CHASER_MAX_TOLERANCE,root.AssemblyLinearVelocity.Magnitude*Config.CHASER_VELOCITY_TOLERANCE)
    if (root.Position-a.root.Position).Magnitude<=Config.CHASER_CATCH_DISTANCE+tolerance then
     Carry.ReturnToSpawn(owner)
     if owner.Character then Ragdoll.Apply(owner.Character,Config.CHASER_RAGDOLL_SECONDS); Ragdoll.Fling(owner.Character,Vector3.new(0,Config.CHASER_FLING_UP,Config.CHASER_FLING_SPEED)) end
     ;(RS.Remotes.Notify :: RemoteEvent):FireClient(owner,{kind="caught",message="Caught! Your loot went back.",sound="caught"})
     Data.LogFunnel(owner,"firstCatch"); goHome(a)
    end
   end
  end
  if a.mode=="gate" then
   target=Vector3.new(a.root.Position.X,0,Config.CHASER_GATE_Z)
   if now-a.since>=Config.CHASER_GATE_WAIT then goHome(a) end
  end
  if a.mode=="home" then
   target=a.home
   if (Vector3.new(target.X,0,target.Z)-Vector3.new(a.root.Position.X,0,a.root.Position.Z)).Magnitude<4 or now-a.since>Config.CHASER_RETURN_TIMEOUT then
    a.model:Destroy(); table.remove(agents,i); continue
   end
  end
  target=ground(target,a.root,a.hum)
  a.hum:MoveTo(target)
  if now-a.sampleAt>=Config.CHASER_STUCK_SECONDS then
   local delta=target-a.root.Position
   if (a.root.Position-a.sample).Magnitude<Config.CHASER_STUCK_DISTANCE and delta.Magnitude>Config.CHASER_RECOVERY_STEP then
    a.model:PivotTo(CFrame.new(ground(a.root.Position+delta.Unit*Config.CHASER_RECOVERY_STEP,a.root,a.hum))); a.root.AssemblyLinearVelocity=Vector3.zero
   end
   a.sample=a.root.Position; a.sampleAt=now
  end
 end
end
function Chasers.Start()
 if started then return end; started=true
 for _, name in {"Chasers","Objects"} do pcall(function() PhysicsService:RegisterCollisionGroup(name) end) end
 PhysicsService:CollisionGroupSetCollidable("Chasers","Chasers",false)
 PhysicsService:CollisionGroupSetCollidable("Chasers","Objects",false)
 live=Instance.new("Folder"); live.Name="Chasers"; live.Parent=workspace.Live
 -- Covers world models, carry proxies and future assets without changing their creators.
 local function tag(instance: Instance)
  if instance:IsA("BasePart") and not instance:IsDescendantOf(live) then instance.CollisionGroup="Objects" end
 end
 for _, instance in workspace.Live:GetDescendants() do tag(instance) end
 workspace.Live.DescendantAdded:Connect(tag)
 for stageId, stage in Catalog.Stages do
  for _, marker in posts(stageId) do
   local model,hum,root=makeModel(stage.chaser,false)
   model.Name=stage.chaser.."Idle"; model:PivotTo(CFrame.new(ground(marker.Position,root,hum))); root.Anchored=true
  end
 end
 Carry.PickedUp:Connect(pickup); Carry.Dropped:Connect(stop)
 Carry.Delivered:Connect(function(player: Player,info: Carry.CarryInfo) stop(player,info,"delivered") end)
 Players.PlayerRemoving:Connect(function(player: Player)
  tickets[player]=nil
  for _, a in agents do if a.owner==player then goHome(a) end end
 end)
 task.spawn(function() while started do task.wait(Config.CHASER_TICK); tick() end end)
end
return Chasers
