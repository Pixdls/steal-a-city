--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local Carry = require(script.Parent.Carry)
local Data = require(script.Parent.Data)
local Chasers = require(script.Parent.Chasers)
local Ragdoll = require(script.Parent.Ragdoll)
local Stomp = {}
local cooldown: {[Player]: number} = {}
local immunity: {[Player]: number} = {}
local started = false
local function aliveRoot(player: Player): BasePart?
 local character=player.Character
 local hum=if character then character:FindFirstChildOfClass("Humanoid") else nil
 local root=if character then character:FindFirstChild("HumanoidRootPart") else nil
 if not character or not hum or hum.Health<=0 or character:GetAttribute("Ragdolled")==true or not root or not root:IsA("BasePart") or root.Anchored then return nil end
 return root
end
local function validStomper(player: Player): BasePart?
 local root=aliveRoot(player)
 if not root or not Data.Get(player) or Carry.IsCarrying(player) or Chasers.IsSafePosition(root.Position) then return nil end
 return root
end
local function validTarget(stomper: Player, root: BasePart, target: Player): boolean
 if target==stomper or not Carry.IsCarrying(target) or os.clock()<(immunity[target] or 0) then return false end
 local other=aliveRoot(target); local data=Data.Get(target)
 if not other or not data or data.Deliveries<Config.STOMP_PROTECTED_DELIVERIES or Chasers.IsSafePosition(other.Position) then return false end
 local delta=other.Position-root.Position
 if delta.Magnitude>Config.STOMP_RANGE then return false end
 local flat=Vector3.new(delta.X,0,delta.Z); local look=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
 return flat.Magnitude<0.01 or (look.Magnitude>0 and look.Unit:Dot(flat.Unit)>=math.cos(math.rad(Config.STOMP_CONE_DEGREES/2)))
end
function Stomp.Try(player: Player): boolean
 if os.clock()<(cooldown[player] or 0) then return false end
 local root=validStomper(player); if not root then return false end
 local target: Player?=nil; local nearest=math.huge
 for _, candidate in Players:GetPlayers() do
  if validTarget(player,root,candidate) then
   local other=aliveRoot(candidate)
   if other then local distance=(other.Position-root.Position).Magnitude; if distance<nearest then target=candidate; nearest=distance end end
  end
 end
 cooldown[player]=os.clock()+Config.STOMP_COOLDOWN
 player:SetAttribute("StompReadyAt",workspace:GetServerTimeNow()+Config.STOMP_COOLDOWN)
 local character=player.Character
 ;(RS.Remotes.Notify :: RemoteEvent):FireAllClients({kind="stompWindup",userId=player.UserId,position=root.Position,scale=player:GetAttribute("Scale") or 1,duration=Config.STOMP_WINDUP})
 task.delay(Config.STOMP_WINDUP,function()
  if player.Character~=character or player.Parent~=Players then return end
  local current=validStomper(player); if not current then return end
  ;(RS.Remotes.Notify :: RemoteEvent):FireAllClients({kind="stompImpact",userId=player.UserId,position=current.Position,scale=player:GetAttribute("Scale") or 1})
  if not target or target.Parent~=Players or not validTarget(player,current,target) then return end
  immunity[target]=os.clock()+Config.STOMP_IMMUNITY
  target:SetAttribute("StompImmuneUntil",workspace:GetServerTimeNow()+Config.STOMP_IMMUNITY)
  -- WorldObjects.Drop already enforces DROP_GRAB_DELAY and DROP_OWNER_DELAY.
  Carry.ForceDrop(target,"stomp")
  if target.Character then Ragdoll.Apply(target.Character,Config.STOMP_RAGDOLL_SECONDS) end
  ;(RS.Remotes.Notify :: RemoteEvent):FireClient(player,"You stomped "..target.DisplayName.."!")
  ;(RS.Remotes.Notify :: RemoteEvent):FireClient(target,player.DisplayName.." stomped you!")
  Data.LogFunnel(target,"firstStompLoss")
 end)
 return true
end
function Stomp.Start()
 if started then return end; started=true
 ;(RS.Remotes.Stomp :: RemoteEvent).OnServerEvent:Connect(function(player: Player) Stomp.Try(player) end)
 Players.PlayerRemoving:Connect(function(player: Player) cooldown[player]=nil; immunity[player]=nil end)
end
return Stomp
