--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Catalog = require(RS.Shared.Catalog)
local Format = require(RS.Shared.Format)
local Data = require(script.Parent.Data)
local WorldObjects = require(script.Parent.WorldObjects)
local Plots = {}
local assigned = require(RS.Shared.Signal).new()
Plots.Assigned = assigned
local plots: {Model} = {}
local owners: {[Player]: Model} = {}
local rendered: {[Player]: Folder} = {}
local signatures: {[Player]: string} = {}
local started = false
function Plots.GetPlot(player: Player): Model? return owners[player] end
function Plots.Render(player: Player)
 local data = Data.Get(player); local plot = owners[player]
 if not data or not plot then return end
 local keys = {}
 for _, slot in data.Slots do table.insert(keys,slot.id..":"..slot.variant) end
 local signature = table.concat(keys,"|")
 if signatures[player] == signature then return end
 signatures[player] = signature
 if rendered[player] then rendered[player]:Destroy() end
 local folder = Instance.new("Folder"); folder.Name = "Plot"..tostring(plot:GetAttribute("PlotId")); folder.Parent = workspace.Live
 rendered[player] = folder
 local slots = plot:FindFirstChild("Slots")
 for i, slot in data.Slots do
  local marker = if slots then slots:FindFirstChild("Slot"..i) else nil
  local object = Catalog.GetObject(slot.id)
  if not marker or not marker:IsA("BasePart") or not object then continue end
  local model = WorldObjects.CreateModel(slot.id,slot.variant)
  local size = model:GetExtentsSize(); local largest = math.max(size.X,size.Y,size.Z)
  if largest > 0 then model:ScaleTo(model:GetScale()*Config.TROPHY_SIZE/largest) end
  model:PivotTo(marker.CFrame); model.Parent = folder
  for _, part in model:GetDescendants() do if part:IsA("BasePart") then part.CanCollide = false end end
  local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(180,48); gui.StudsOffsetWorldSpace = Vector3.new(0,Config.TROPHY_SIZE+1,0); gui.MaxDistance = 60; gui.Adornee = model.PrimaryPart; gui.Parent = model
  local label = Instance.new("TextLabel"); label.Size = UDim2.fromScale(1,1); label.BackgroundTransparency = 1; label.TextColor3 = Color3.new(1,1,1); label.TextStrokeTransparency = 0; label.Font = Enum.Font.FredokaOne; label.TextSize = 14
  label.Text = object.name.." · "..slot.variant.."\n"..Format.Cash(Catalog.Income(slot.id,slot.variant)).."/s"; label.Parent = gui
 end
end
function Plots.AddObject(player: Player, id: string, variant: string): boolean
 if not Catalog.GetObject(id) then return false end
 local placed = false
 Data.Update(player,function(data: Data.PlayerData)
  local entry = {id=id,variant=Catalog.GetVariant(variant).id}
  placed = #data.Slots < data.SlotCount
  table.insert(if placed then data.Slots else data.Backpack,entry)
  data.Index[id] = data.Index[id] or {}; data.Index[id][entry.variant] = true
 end)
 return placed
end
local function spawnAtPlot(player: Player, character: Model)
 local root = character:WaitForChild("HumanoidRootPart",10)
 local plot = owners[player]; local spawn = if plot then plot:FindFirstChild("SpawnPoint") else nil
 if root and spawn and spawn:IsA("BasePart") and player.Character == character then character:PivotTo(spawn.CFrame+Vector3.new(0,Config.SPAWN_CLEARANCE,0)) end
end
local function assign(player: Player)
 if owners[player] then return end
 for _, plot in plots do
  if (plot:GetAttribute("Owner") or 0) ~= 0 then continue end
  owners[player] = plot; plot:SetAttribute("Owner",player.UserId); player:SetAttribute("PlotId",plot:GetAttribute("PlotId"))
  local sign = plot:FindFirstChild("Sign"); local label = if sign then sign:FindFirstChildWhichIsA("TextLabel",true) else nil
  if label then label.Text = player.DisplayName end
  if player.Character then task.spawn(spawnAtPlot,player,player.Character) end
  Plots.Render(player); assigned:Fire(player,plot); return
 end
 warn("[Plots] No free plot for "..player.Name)
end
function Plots.Start()
 if started then return end; started = true
 local map = workspace:WaitForChild("Map",Config.MAP_WAIT_SECONDS)
 local home = if map then map:FindFirstChild("Home") else nil
 local folder = if home then home:FindFirstChild("Plots") else nil
 if not folder then warn("[Plots] Map.Home.Plots missing"); return end
 for _, plot in folder:GetChildren() do if plot:IsA("Model") then table.insert(plots,plot) end end
 table.sort(plots,function(a,b) return (a:GetAttribute("PlotId") or 0) < (b:GetAttribute("PlotId") or 0) end)
 local function watch(player: Player)
  player.CharacterAdded:Connect(function(character) task.spawn(spawnAtPlot,player,character) end)
  assign(player)
 end
 Players.PlayerAdded:Connect(watch)
 for _, player in Players:GetPlayers() do watch(player) end
 Data.Loaded:Connect(function(player: Player) assign(player); Plots.Render(player) end)
 Data.Changed:Connect(Plots.Render)
 Players.PlayerRemoving:Connect(function(player: Player)
  local plot = owners[player]
  if plot then
   plot:SetAttribute("Owner",0)
   local sign = plot:FindFirstChild("Sign"); local label = if sign then sign:FindFirstChildWhichIsA("TextLabel",true) else nil
   if label then label.Text = "Unclaimed" end
  end
  if rendered[player] then rendered[player]:Destroy() end
  owners[player] = nil; rendered[player] = nil; signatures[player] = nil
  for _, waiting in Players:GetPlayers() do if waiting ~= player and not owners[waiting] then assign(waiting) end end
 end)
end
return Plots
