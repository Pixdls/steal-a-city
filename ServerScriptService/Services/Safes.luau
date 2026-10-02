--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
local Data = require(script.Parent.Data)
local Plots = require(script.Parent.Plots)
local Carry = require(script.Parent.Carry)
local WorldObjects = require(script.Parent.WorldObjects)
local Safes = {}
local random=Random.new()
type StageState = {markers: {BasePart}, available: WorldObjects.Handle?, generation: number}
type PadView = {entry: Data.Safe, marker: BasePart, model: Model, label: TextLabel, prompt: ProximityPrompt}
local stages: {[string]: StageState} = {}
local views: {[Player]: {PadView}} = {}
local folders: {[Player]: Folder} = {}
local signatures: {[Player]: string} = {}
local lastNotice: {[Player]: number} = {}
local started=false
local function padsCount(data: Data.PlayerData): number return math.clamp(math.floor(data.SafePads),Config.SAFE_START_PADS,Config.SAFE_MAX_PADS) end
function Safes.CanPickup(player: Player): boolean
 local data=Data.Get(player)
 return data~=nil and #data.Safes<padsCount(data)+Config.SAFE_QUEUE
end
local function capacity(player: Player, _handle: WorldObjects.Handle): boolean
 if Safes.CanPickup(player) then return true end
 if os.clock()>(lastNotice[player] or 0) then
  lastNotice[player]=os.clock()+2; (RS.Remotes.Notify :: RemoteEvent):FireClient(player,"Safe pads full")
 end
 return false
end
local function roll(_player: Player, handle: WorldObjects.Handle)
 if handle.safe then return end -- Theft and re-pickup preserve the original roll.
 local options=Catalog.GetStageObjects(handle.stage); local definition=Catalog.Safes[handle.id]
 local variant="Normal"; local rollValue=random:NextNumber(); local cumulative=0
 for i=#Config.VARIANTS,2,-1 do
  local candidate=Config.VARIANTS[i]; cumulative+=candidate.chance*Config.SAFE_VARIANT_BOOST
  if rollValue<cumulative then variant=candidate.id; break end
 end
 local selected=options[random:NextInteger(1,#options)]
 handle.safe={tier=handle.id,stage=handle.stage,contents={id=selected.id,variant=variant},readyAt=random:NextInteger(definition.minSeconds,definition.maxSeconds)}
 -- While carried, readyAt stores the rolled duration; delivery converts it to UTC.
end
local function deliver(player: Player, info: Carry.CarryInfo): boolean
 local entry=info.handle.safe
 if not entry or not capacity(player,info.handle) then return false end
 local saved=false
 Data.Update(player,function(data: Data.PlayerData)
  if #data.Safes>=padsCount(data)+Config.SAFE_QUEUE then return end
  table.insert(data.Safes,{tier=entry.tier,stage=entry.stage,contents={id=entry.contents.id,variant=entry.contents.variant},readyAt=os.time()+entry.readyAt})
  saved=true
 end)
 return saved
end
local function spawnSafe(stageId: string)
 local state=stages[stageId]
 if not state or state.available or #state.markers==0 then return end
 local lightest=Catalog.GetStageObjects(stageId)[1]; if not lightest then return end
 local marker=state.markers[random:NextInteger(1,#state.markers)]
 local handle: WorldObjects.Handle={kind="safe",id="PiggyBank",variant="Normal",stage=stageId,weight=lightest.weight*Catalog.Safes.PiggyBank.weightMultiplier,marker=marker,model=nil,aftermath=nil,state="available",generation=0,availableAt=0,blockedUntil=0,distance=Config.PICKUP_DISTANCE}
 state.available=handle; WorldObjects.Register(handle)
end
local function taken(_player: Player, info: Carry.CarryInfo)
 if info.kind~="safe" then return end
 local state=stages[info.stage]; if not state or state.available~=info.handle then return end
 state.available=nil; state.generation+=1; local generation=state.generation
 task.delay(random:NextNumber(Config.SAFE_RESPAWN_MIN,Config.SAFE_RESPAWN_MAX),function()
  if state.generation==generation then spawnSafe(info.stage) end
 end)
end
local function returning(handle: WorldObjects.Handle): boolean
 local state=stages[handle.stage]
 if not state or (state.available and state.available~=handle) then WorldObjects.Retire(handle); return true end
 state.available=handle; state.generation+=1; handle.safe=nil
 return false
end
local function reveal(entry: Data.Safe, cf: CFrame)
 local model=WorldObjects.CreateModel(entry.contents.id,entry.contents.variant)
 local extent=model:GetExtentsSize(); local target=model:GetScale()*Config.TROPHY_SIZE/math.max(extent.X,extent.Y,extent.Z,0.01)
 model:ScaleTo(target*0.05); model:PivotTo(cf); model.Parent=workspace.Live
 for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CanCollide=false; part.CanTouch=false end end
 local value=Instance.new("NumberValue"); value.Value=target*0.05
 local connection=value.Changed:Connect(function(scale: number) if model.Parent then model:ScaleTo(scale); model:PivotTo(cf) end end)
 local tween=TweenService:Create(value,TweenInfo.new(Config.SAFE_REVEAL_SECONDS,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Value=target})
 tween.Completed:Once(function() connection:Disconnect(); value:Destroy(); model:Destroy() end); tween:Play()
end
function Safes.Open(player: Player, index: number): boolean
 local data=Data.Get(player); local playerViews=views[player]
 if not data or not playerViews or index%1~=0 or index<1 or index>padsCount(data) then return false end
 local view=playerViews[index]; local entry=data.Safes[index]
 if not view or not entry or view.entry~=entry then return false end
 local character=player.Character; local root=if character then character:FindFirstChild("HumanoidRootPart") else nil
 local hum=if character then character:FindFirstChildOfClass("Humanoid") else nil
 if not root or not root:IsA("BasePart") or not hum or hum.Health<=0 or (root.Position-view.marker.Position).Magnitude>Config.SAFE_OPEN_DISTANCE+Config.PICKUP_TOLERANCE then return false end
 if not entry or entry.readyAt>os.time() or not entry.contents or not Catalog.GetObject(entry.contents.id) then return false end
 local cf=view.marker.CFrame+Vector3.new(0,view.marker.Size.Y/2,0)
 local definition=Catalog.GetObject(entry.contents.id)
 if not definition then return false end
 local removed=false
 Data.Update(player,function(profile: Data.PlayerData)
  if profile.Safes[index]==entry and entry.readyAt<=os.time() then table.remove(profile.Safes,index); removed=true end
 end)
 if not removed then return false end
 -- No yielding between removing the safe and granting its contents; disconnects
 -- cannot lose a reward during the purely cosmetic reveal.
 Plots.AddObject(player,entry.contents.id,entry.contents.variant)
 reveal(entry,cf)
 ;(RS.Remotes.Notify :: RemoteEvent):FireClient(player,"Opened "..definition.name.." · "..entry.contents.variant.."!")
 return true
end
local function updateLabels(player: Player)
 local count=0
 for _, view in views[player] or {} do
  local remaining=math.max(0,view.entry.readyAt-os.time())
  view.label.Text=if remaining==0 then "OPEN!" else tostring(remaining).."s"
  view.prompt.Enabled=remaining==0
  if remaining==0 then count+=1 end
 end
 player:SetAttribute("SafesReady",count)
end
function Safes.Render(player: Player)
 local data=Data.Get(player); local plot=Plots.GetPlot(player)
 if not data or not plot then return end
 local padFolder=plot:FindFirstChild("SafePads"); if not padFolder then return end
 local keys={tostring(padsCount(data)),tostring(plot:GetAttribute("PlotId"))}
 for _, entry in data.Safes do table.insert(keys,entry.tier..":"..entry.readyAt..":"..(if entry.contents then entry.contents.id..":"..entry.contents.variant else "invalid")) end
 local signature=table.concat(keys,"|")
 if signatures[player]==signature then updateLabels(player); return end
 signatures[player]=signature
 if folders[player] then folders[player]:Destroy() end
 local folder=Instance.new("Folder"); folder.Name="Safes_"..player.UserId; folder.Parent=workspace.Live; folders[player]=folder
 local playerViews: {PadView}={}; views[player]=playerViews
 for i=1,Config.SAFE_MAX_PADS do
  local marker=padFolder:FindFirstChild("Pad"..i)
  if not marker or not marker:IsA("BasePart") then continue end
  marker.Transparency=if i<=padsCount(data) then 0 else 1
  if i>padsCount(data) then continue end
  local entry=data.Safes[i]; if not entry or not entry.contents or not Catalog.Safes[entry.tier] then continue end
  local model=WorldObjects.CreateModel(entry.tier,"Normal")
  model:PivotTo(marker.CFrame+Vector3.new(0,marker.Size.Y/2,0)); model.Parent=folder
  for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CanCollide=false end end
  local gui=Instance.new("BillboardGui"); gui.Size=UDim2.fromOffset(150,45); gui.StudsOffsetWorldSpace=Vector3.new(0,4,0); gui.MaxDistance=70; gui.Adornee=model.PrimaryPart; gui.Parent=model
  local label=Instance.new("TextLabel"); label.Size=UDim2.fromScale(1,1); label.BackgroundTransparency=1; label.TextColor3=Color3.fromRGB(255,224,94); label.TextStrokeTransparency=0; label.Font=Enum.Font.FredokaOne; label.TextSize=24; label.Parent=gui
  local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open"; prompt.ObjectText="Piggy Bank"; prompt.MaxActivationDistance=Config.SAFE_OPEN_DISTANCE; prompt.RequiresLineOfSight=false; prompt.Enabled=false; prompt:SetAttribute("OwnerUserId",player.UserId); prompt.Parent=model.PrimaryPart
  prompt.Triggered:Connect(function(who: Player) if who==player then Safes.Open(player,i) end end)
  playerViews[i]={entry=entry,marker=marker,model=model,label=label,prompt=prompt}
 end
 player:SetAttribute("SafesQueued",math.max(0,#data.Safes-padsCount(data))); updateLabels(player)
end
function Safes.Start()
 if started then return end; started=true
 Carry.RegisterKind("safe",{canPickup=capacity,prepare=roll,deliver=deliver})
 WorldObjects.RegisterKind("safe",{returning=returning,respawn=WorldObjects.Retire})
 Carry.PickedUp:Connect(taken)
 Data.Loaded:Connect(Safes.Render); Data.Changed:Connect(Safes.Render); Plots.Assigned:Connect(Safes.Render)
 Players.PlayerRemoving:Connect(function(player: Player)
  if folders[player] then folders[player]:Destroy() end
  folders[player]=nil; views[player]=nil; signatures[player]=nil; lastNotice[player]=nil
 end)
 local map=workspace:FindFirstChild("Map"); local stageFolder=if map then map:FindFirstChild("Stages") else nil
 if stageFolder then
  for stageId in Catalog.Stages do
   local stage=stageFolder:FindFirstChild(stageId); local folder=if stage then stage:FindFirstChild("SafeSpawns") else nil
   local markers: {BasePart}={}
   if folder then for _, marker in folder:GetChildren() do if marker:IsA("BasePart") then table.insert(markers,marker) end end end
   stages[stageId]={markers=markers,available=nil,generation=0}; spawnSafe(stageId)
  end
 end
 for _, player in Players:GetPlayers() do Safes.Render(player) end
 task.spawn(function() while started do task.wait(1); for player in views do updateLabels(player) end end end)
end
return Safes
