--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Growth = require(script.Parent.Growth)
local WorldObjects = require(script.Parent.WorldObjects)
export type CarryInfo = {kind: string?, id: string, variant: string, stage: string, weight: number, handle: WorldObjects.Handle, proxy: Model, lastPosition: Vector3, lastCheck: number, maxSpeed: number}
local Carry = {}
type KindHooks = {canPickup: (Player, WorldObjects.Handle) -> boolean, prepare: (Player, WorldObjects.Handle) -> (), deliver: (Player, CarryInfo) -> boolean}
local kinds: {[string]: KindHooks} = {}
function Carry.RegisterKind(kind: string, hooks: KindHooks) kinds[kind] = hooks end
local Signal = require(RS.Shared.Signal)
local picked = Signal.new(); Carry.PickedUp = picked
local dropped = Signal.new(); Carry.Dropped = dropped
local delivered = Signal.new(); Carry.Delivered = delivered
local carrying: {[Player]: CarryInfo} = {}
local cooldown: {[Player]: number} = {}
local started = false
local function rootOf(player: Player): BasePart?
 local root = if player.Character then player.Character:FindFirstChild("HumanoidRootPart") else nil
 return if root and root:IsA("BasePart") then root else nil
end
function Carry.IsCarrying(player: Player): boolean return carrying[player] ~= nil end
function Carry.GetCarry(player: Player): CarryInfo? return carrying[player] end
local function release(player: Player): CarryInfo?
 local info = carrying[player]
 if not info then return nil end
 carrying[player] = nil; info.proxy:Destroy(); player:SetAttribute("CarryWeight",nil); player:SetAttribute("CarryRatio",nil)
 cooldown[player] = os.clock()+Config.PICKUP_COOLDOWN; Growth.Refresh(player)
 return info
end
function Carry.ReturnToSpawn(player: Player)
 local info = release(player)
 if info then WorldObjects.Return(info.handle); dropped:Fire(player,info,"returned") end
end
local function pathValid(player: Player, info: CarryInfo, root: BasePart): boolean
 local data = Data.Get(player)
 if not data then return false end
 local speed = Config.BASE_WALK_SPEED*Config.SpeedForSize(data.Size)*(player:GetAttribute("CarryRatio") or 1)
 info.maxSpeed = math.max(info.maxSpeed,speed)
 local delta = root.Position-info.lastPosition
 return Vector3.new(delta.X,0,delta.Z).Magnitude <= info.maxSpeed*(os.clock()-info.lastCheck)*Config.PATH_SPEED_TOLERANCE+Config.PATH_DISTANCE_TOLERANCE
end
function Carry.ForceDrop(player: Player, reason: string?)
 local root = rootOf(player)
 if not root then Carry.ReturnToSpawn(player); return end
 local current = carrying[player]
 if current and not pathValid(player,current,root) then Carry.ReturnToSpawn(player); return end
 local info = release(player); if not info then return end
 local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
 local excluded: {Instance} = {workspace.Live}
 for _, p in Players:GetPlayers() do if p.Character then table.insert(excluded,p.Character) end end
 params.FilterDescendantsInstances = excluded; params.RespectCanCollide = true
 local hit = workspace:Raycast(root.Position+Vector3.new(0,Config.DROP_RAY_HEIGHT,0),Vector3.new(0,-Config.DROP_RAY_LENGTH,0),params)
 if not hit then WorldObjects.Return(info.handle) else WorldObjects.Drop(info.handle,CFrame.new(hit.Position),player) end
 dropped:Fire(player,info,reason or "drop")
end
function Carry.Pickup(player: Player, handle: WorldObjects.Handle): boolean
 local data = Data.Get(player); local root = rootOf(player); local character = player.Character
 local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
 if not data or not root or not character or not humanoid or humanoid.Health <= 0 or character:GetAttribute("Ragdolled") == true or root.Anchored or Carry.IsCarrying(player) or player:GetAttribute("Lifting") == true or os.clock() < (cooldown[player] or 0) then return false end
 local model = handle.model; local object = Catalog.GetObject(handle.id)
 local hooks = if handle.kind then kinds[handle.kind] else nil
 local weight = handle.weight or (if object then object.weight else nil)
 if not model or not model.PrimaryPart or not weight or (handle.kind ~= nil and not hooks) or (root.Position-model.PrimaryPart.Position).Magnitude > handle.distance+Config.PICKUP_TOLERANCE then return false end
 if hooks and not hooks.canPickup(player,handle) then return false end
 if not WorldObjects.Take(handle,player) then return false end
 if hooks then hooks.prepare(player,handle) end
 local proxy = WorldObjects.CreateModel(handle.id,handle.variant)
 local size = proxy:GetExtentsSize(); local largest = math.max(size.X,size.Y,size.Z)
 local height = character:GetExtentsSize().Y*Config.ScaleForSize(data.Size)
 if largest > 0 then proxy:ScaleTo(proxy:GetScale()*height*Config.CARRY_HEIGHT_RATIO/largest) end
 local primary = proxy.PrimaryPart
 if not primary then proxy:Destroy(); WorldObjects.Return(handle); return false end
 proxy:PivotTo(root.CFrame*CFrame.new(0,height*0.65,0)); proxy.Parent = workspace.Live
 for _, part in proxy:GetDescendants() do
  if part:IsA("BasePart") then
   part.Anchored = false; part.Massless = true; part.CanCollide = false; part.CanQuery = false; part.CanTouch = false
   if part ~= primary then local weld = Instance.new("WeldConstraint"); weld.Part0 = primary; weld.Part1 = part; weld.Parent = part end
  end
 end
 local weld = Instance.new("WeldConstraint"); weld.Part0 = root; weld.Part1 = primary; weld.Parent = primary
 player:SetAttribute("CarryWeight",weight); Growth.Refresh(player)
 local info: CarryInfo = {kind=handle.kind,id=handle.id,variant=handle.variant,stage=handle.stage,weight=weight,handle=handle,proxy=proxy,lastPosition=root.Position,lastCheck=os.clock(),maxSpeed=humanoid.WalkSpeed}
 carrying[player] = info
 if not hooks and #data.Slots >= data.SlotCount then (RS.Remotes.Notify :: RemoteEvent):FireClient(player,"Plot full — delivery goes to backpack") end
 picked:Fire(player,info); return true
end
local function tickCarry(player: Player, info: CarryInfo)
 local root = rootOf(player); local data = Data.Get(player)
 if not root or not data then Carry.ReturnToSpawn(player); return end
 local now = os.clock(); local elapsed = now-info.lastCheck
 local speed = Config.BASE_WALK_SPEED*Config.SpeedForSize(data.Size)*(player:GetAttribute("CarryRatio") or 1)
 info.maxSpeed = math.max(info.maxSpeed,speed)
 local delta = root.Position-info.lastPosition
 local horizontal = Vector3.new(delta.X,0,delta.Z).Magnitude
 if horizontal > info.maxSpeed*elapsed*Config.PATH_SPEED_TOLERANCE+Config.PATH_DISTANCE_TOLERANCE then Carry.ReturnToSpawn(player); return end
 if elapsed >= Config.PATH_SAMPLE_SECONDS then info.lastPosition=root.Position; info.lastCheck=now; info.maxSpeed=speed end
 local plot = Plots.GetPlot(player); local floor = if plot then plot:FindFirstChild("Floor") else nil
 if not floor or not floor:IsA("BasePart") then return end
 local point = floor.CFrame:PointToObjectSpace(root.Position)
 if math.abs(point.X)>floor.Size.X/2 or math.abs(point.Z)>floor.Size.Z/2 or math.abs(point.Y)>Config.DELIVERY_Y_TOLERANCE*Config.ScaleForSize(data.Size) then return end
 local bump = Growth.GetBenchRate(player)*Config.DELIVERY_SECONDS*math.clamp(info.weight/data.Size,Config.DELIVERY_MIN_RATIO,Config.DELIVERY_MAX_RATIO)
 local hooks = if info.kind then kinds[info.kind] else nil
 if hooks and not hooks.deliver(player,info) then return end
 release(player)
 local placed = if hooks then true else Plots.AddObject(player,info.id,info.variant)
 Data.Update(player,function(profile: Data.PlayerData) profile.Size += bump; profile.Deliveries += 1 end)
 Data.LogFunnel(player,"firstDelivery"); WorldObjects.Respawn(info.handle); delivered:Fire(player,info,placed)
end
function Carry.Start()
 if started then return end; started = true
 WorldObjects.PickupRequested:Connect(Carry.Pickup)
 ;(RS.Remotes.Drop :: RemoteEvent).OnServerEvent:Connect(function(player: Player) Carry.ForceDrop(player,"manual") end)
 local function watch(player: Player)
  player.CharacterRemoving:Connect(function() Carry.ReturnToSpawn(player) end)
  local function characterAdded(character: Model)
   local humanoid = character:WaitForChild("Humanoid",10)
   if humanoid and humanoid:IsA("Humanoid") then humanoid.Died:Connect(function() Carry.ReturnToSpawn(player) end) end
  end
  player.CharacterAdded:Connect(characterAdded)
  if player.Character then task.spawn(characterAdded,player.Character) end
 end
 Players.PlayerAdded:Connect(watch); for _, player in Players:GetPlayers() do watch(player) end
 Players.PlayerRemoving:Connect(function(player: Player) Carry.ReturnToSpawn(player); cooldown[player]=nil end)
 local accumulator = 0
 RunService.Heartbeat:Connect(function(dt: number)
  accumulator += dt; if accumulator < Config.DELIVERY_INTERVAL then return end; accumulator = 0
  for player, info in carrying do tickCarry(player,info) end
 end)
end
return Carry
