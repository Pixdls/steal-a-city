--!strict
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
export type Handle = {kind: string?, weight: number?, safe: {tier: string, stage: string, contents: {id: string, variant: string}, readyAt: number}?, id: string, variant: string, stage: string, marker: BasePart, model: Model?, aftermath: BasePart?, state: string, generation: number, availableAt: number, blockedUserId: number?, blockedUntil: number, distance: number}
local WorldObjects = {}
type KindHooks = {returning: (Handle) -> boolean, respawn: (Handle) -> ()}
local kinds: {[string]: KindHooks} = {}
function WorldObjects.RegisterKind(kind: string, hooks: KindHooks) kinds[kind] = hooks end
local requested = require(RS.Shared.Signal).new()
WorldObjects.PickupRequested = requested
local handles: {Handle} = {}
local random = Random.new()
local objects: Folder
local started = false
function WorldObjects.GetHandles(): {Handle} return table.clone(handles) end
function WorldObjects.ApplyVariant(model: Model, variantId: string)
 model:SetAttribute("Variant", variantId)
 if variantId == "Normal" then return end
 local variant = Catalog.GetVariant(variantId)
 for _, part in model:GetDescendants() do
  if part:IsA("BasePart") then part.Color = variant.color; part.Material = variant.material end
 end
 if model.PrimaryPart and (variantId == "Neon" or variantId == "Rainbow") then
  local light = Instance.new("PointLight")
  light.Color = variant.color; light.Range = 10; light.Brightness = 1; light.Parent = model.PrimaryPart
 end
end
function WorldObjects.CreateModel(id: string, variant: string): Model
 local assets = RS:FindFirstChild("Assets")
 local folder = if assets then assets:FindFirstChild(if Catalog.Safes[id] then "Safes" else "Objects") else nil
 local source = if folder then folder:FindFirstChild(id) else nil
 local model: Model
 if source and source:IsA("Model") and source:FindFirstChildWhichIsA("BasePart",true) then model = source:Clone() else
  model = Instance.new("Model")
  local object = Catalog.GetObject(id) or Catalog.Safes[id]
  local part = Instance.new("Part")
  part.Size = if object then object.size else Vector3.new(3,3,3)
  part.CFrame = CFrame.new(0,part.Size.Y/2,0)
  part.PivotOffset = CFrame.new(0,-part.Size.Y/2,0)
  part.Color = Color3.fromRGB(184,142,82); part.Parent = model; model.PrimaryPart = part
 end
 model.Name = id
 if not model.PrimaryPart then model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart",true) end
 for _, child in model:GetDescendants() do
  if child:IsA("BasePart") then child.Anchored = true
  elseif child:IsA("Script") or child:IsA("LocalScript") or child:IsA("ProximityPrompt") then child:Destroy() end
 end
 model:SetAttribute("ObjectId",id)
 WorldObjects.ApplyVariant(model,variant)
 return model
end
local function clear(handle: Handle)
 if handle.model then handle.model:Destroy(); handle.model = nil end
end
local function present(handle: Handle, cf: CFrame)
 local model = WorldObjects.CreateModel(handle.id,handle.variant)
 model:PivotTo(cf); model.Parent = objects; handle.model = model
 model:SetAttribute("StageId",handle.stage)
 local primary = model.PrimaryPart
 if not primary then warn("[WorldObjects] Empty asset: "..handle.id); return end
 local prompt = Instance.new("ProximityPrompt")
 prompt.ActionText = "Pick up"; prompt.ObjectText = (Catalog.Objects[handle.id] or Catalog.Safes[handle.id]).name
 prompt.HoldDuration = 0; prompt.MaxActivationDistance = handle.distance; prompt.RequiresLineOfSight = false
 prompt.Parent = primary
 prompt.Triggered:Connect(function(player) requested:Fire(player,handle) end)
end
-- Kind callbacks return true when they consume a return (e.g. an obsolete safe).
function WorldObjects.Return(handle: Handle)
 local hooks = if handle.kind then kinds[handle.kind] else nil
 if hooks and hooks.returning(handle) then return end
 handle.generation += 1; clear(handle)
 if handle.aftermath then handle.aftermath:Destroy(); handle.aftermath = nil end
 handle.state = "available"; handle.availableAt = 0; handle.blockedUserId = nil
 present(handle,handle.marker.CFrame)
end
function WorldObjects.Respawn(handle: Handle)
 local hooks = if handle.kind then kinds[handle.kind] else nil
 if hooks then hooks.respawn(handle); return end
 handle.generation += 1; clear(handle); handle.state = "respawning"
 local generation = handle.generation
 task.delay(random:NextNumber(Config.RESPAWN_MIN_SECONDS,Config.RESPAWN_MAX_SECONDS),function()
  if handle.generation ~= generation then return end
  local roll = random:NextNumber(); local total = 0
  for _, variant in Config.VARIANTS do total += variant.chance; if roll < total then handle.variant = variant.id; break end end
  WorldObjects.Return(handle)
  if handle.variant == "Rainbow" then (RS.Remotes.Notify :: RemoteEvent):FireAllClients("Rainbow "..Catalog.Objects[handle.id].name.." appeared!") end
  local model = handle.model
  if model then
   local scale = model:GetScale()
   local value = Instance.new("NumberValue"); value.Value = scale*0.8
   local connection = value.Changed:Connect(function(n) if model.Parent then model:ScaleTo(n) end end)
   local tween = TweenService:Create(value,TweenInfo.new(Config.RESPAWN_POP_SECONDS),{Value=scale})
   tween.Completed:Once(function() connection:Disconnect(); value:Destroy() end); tween:Play()
  end
 end)
end
function WorldObjects.Take(handle: Handle, player: Player): boolean
 if handle.state ~= "available" and handle.state ~= "dropped" then return false end
 if os.clock() < handle.availableAt or (handle.blockedUserId == player.UserId and os.clock() < handle.blockedUntil) then return false end
 handle.generation += 1; handle.state = "carried"; clear(handle)
 if not handle.aftermath then
  local dust = Instance.new("Part"); dust.Name = "Aftermath"; dust.Anchored = true; dust.CanCollide = false
  dust.Size = Vector3.new(4,0.1,4); dust.Color = Color3.fromRGB(149,129,99); dust.CFrame = handle.marker.CFrame; dust.Parent = objects
  local emitter = Instance.new("ParticleEmitter"); emitter.Rate = 0; emitter.Lifetime = NumberRange.new(0.5,1); emitter.Speed = NumberRange.new(2,4); emitter.Parent = dust; emitter:Emit(8)
  Debris:AddItem(emitter,2); handle.aftermath = dust
 end
 return true
end
function WorldObjects.Drop(handle: Handle, cf: CFrame, previousOwner: Player?)
 handle.generation += 1; clear(handle); handle.state = "dropped"
 handle.availableAt = os.clock()+Config.DROP_GRAB_DELAY
 handle.blockedUserId = if previousOwner then previousOwner.UserId else nil
 handle.blockedUntil = os.clock()+Config.DROP_OWNER_DELAY
 present(handle,cf)
 local generation = handle.generation
 task.delay(Config.DROP_RETURN_SECONDS,function() if handle.generation == generation and handle.state == "dropped" then WorldObjects.Return(handle) end end)
end
function WorldObjects.Retire(handle: Handle)
 handle.generation += 1; handle.state = "retired"; clear(handle)
 if handle.aftermath then handle.aftermath:Destroy(); handle.aftermath = nil end
 local index = table.find(handles,handle); if index then table.remove(handles,index) end
end
function WorldObjects.Register(handle: Handle)
 table.insert(handles,handle); WorldObjects.Return(handle)
end
function WorldObjects.Start()
 if started then return end; started = true
 local live = workspace:FindFirstChild("Live")
 if not live then live = Instance.new("Folder"); live.Name = "Live"; live.Parent = workspace end
 objects = Instance.new("Folder"); objects.Name = "Objects"; objects.Parent = live
 local map = workspace:WaitForChild("Map",Config.MAP_WAIT_SECONDS)
 local stages = if map then map:FindFirstChild("Stages") else nil
 if not stages then warn("[WorldObjects] Map.Stages missing; objects disabled"); return end
 for _, stage in stages:GetChildren() do
  local spawns = stage:FindFirstChild("Spawns")
  if not spawns then continue end
  for _, marker in spawns:GetChildren() do
   if not marker:IsA("BasePart") then continue end
   local id = marker:GetAttribute("ObjectId")
   local object = if typeof(id) == "string" then Catalog.GetObject(id) else nil
   if not object then warn("[WorldObjects] Unknown ObjectId at "..marker:GetFullName()); continue end
   local variant = "Normal"; local roll = random:NextNumber(); local total = 0
   for _, v in Config.VARIANTS do total += v.chance; if roll < total then variant = v.id; break end end
   local handle: Handle = {id=object.id,variant=variant,stage=object.stage,marker=marker,model=nil,aftermath=nil,state="available",generation=0,availableAt=0,blockedUserId=nil,blockedUntil=0,distance=math.min(Config.PICKUP_MAX_DISTANCE,Config.PICKUP_DISTANCE+object.size.Magnitude*Config.PICKUP_SIZE_FACTOR)}
   table.insert(handles,handle); WorldObjects.Return(handle)
  end
 end
end
return WorldObjects
