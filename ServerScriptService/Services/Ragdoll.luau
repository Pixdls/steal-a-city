--!strict
local Ragdoll = {}
type State = {untilTime: number, platform: boolean, rotate: boolean}
local active: {[Model]: State} = {}
function Ragdoll.Apply(character: Model, seconds: number)
 local hum = character:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health <= 0 then return end
 local prior = active[character]
 if prior then prior.untilTime = math.max(prior.untilTime,os.clock()+seconds); return end
 local state = {untilTime=os.clock()+seconds,platform=hum.PlatformStand,rotate=hum.AutoRotate}
 active[character] = state; character:SetAttribute("Ragdolled",true)
 local root = character:FindFirstChild("HumanoidRootPart")
 if root and root:IsA("BasePart") and not root.Anchored then pcall(function() root:SetNetworkOwner(nil) end) end
 hum.Sit = false; hum.AutoRotate = false; hum.PlatformStand = true
 hum:ChangeState(Enum.HumanoidStateType.Physics)
 task.spawn(function()
  repeat task.wait(math.max(0.05,state.untilTime-os.clock())) until os.clock() >= state.untilTime or not character.Parent
  if active[character] ~= state then return end
  active[character] = nil
  if character.Parent and hum.Parent then
   character:SetAttribute("Ragdolled",nil)
   hum.PlatformStand = state.platform; hum.AutoRotate = state.rotate
   if hum.Health > 0 and not state.platform then hum:ChangeState(Enum.HumanoidStateType.GettingUp) end
   local root = character:FindFirstChild("HumanoidRootPart")
   if root and root:IsA("BasePart") and not root.Anchored then pcall(function() root:SetNetworkOwnershipAuto() end) end
  end
 end)
end
function Ragdoll.Fling(character: Model, velocity: Vector3)
 local root = character:FindFirstChild("HumanoidRootPart")
 if not root or not root:IsA("BasePart") or root.Anchored then return end
 pcall(function() root:SetNetworkOwner(nil) end)
 root.AssemblyLinearVelocity = velocity
 -- Also restore ownership for callers that fling without Apply.
 task.delay(2,function()
  if root.Parent and not root.Anchored and not active[character] then pcall(function() root:SetNetworkOwnershipAuto() end) end
 end)
end
return Ragdoll
