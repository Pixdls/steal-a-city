--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local UIS=game:GetService("UserInputService")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local ProximityPromptService=game:GetService("ProximityPromptService")
local Config=require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local player=Players.LocalPlayer
local remotes=RS:WaitForChild("Remotes")
local effects=Instance.new("Folder"); effects.Name="CombatEffects"; effects.Parent=workspace:WaitForChild("Live")
-- The server still validates ownership, even if a modified client re-enables it.
ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
 local owner=prompt:GetAttribute("OwnerUserId")
 if typeof(owner)=="number" and owner~=player.UserId then prompt.Enabled=false end
end)
local sentAt=0
local function stomp()
 if UIS:GetFocusedTextBox() or player:GetAttribute("CarryRatio")~=nil then return end
 if workspace:GetServerTimeNow()<(player:GetAttribute("StompReadyAt") or 0) or os.clock()-sentAt<0.2 then return end
 sentAt=os.clock(); (remotes.Stomp :: RemoteEvent):FireServer()
end
UIS.InputBegan:Connect(function(input: InputObject,processed: boolean)
 if not processed and (input.KeyCode==Enum.KeyCode.F or input.KeyCode==Enum.KeyCode.ButtonX or input.KeyCode==Enum.KeyCode.One) then stomp() end
end)
local function ground(position: Vector3): Vector3
 local params=RaycastParams.new(); params.FilterType=Enum.RaycastFilterType.Exclude
 local excluded: {Instance}={workspace.Live}
 for _, who in Players:GetPlayers() do if who.Character then table.insert(excluded,who.Character) end end
 params.FilterDescendantsInstances=excluded; params.RespectCanCollide=true
 local hit=workspace:Raycast(position+Vector3.new(0,2,0),Vector3.new(0,-100,0),params)
 return (if hit then hit.Position else Vector3.new(position.X,0,position.Z))+Vector3.new(0,0.08,0)
end
local function part(): Part
 local p=Instance.new("Part"); p.Anchored=true; p.CanCollide=false; p.CanQuery=false; p.CanTouch=false; p.CastShadow=false; p.Material=Enum.Material.Neon; p.Parent=effects
 return p
end
local function effect(payload: any)
 if typeof(payload)~="table" then return end
 -- Sound hooks are emitted on this same Notify stream (chaserWarning/chaserGate/caught).
 if payload.kind~="stompWindup" and payload.kind~="stompImpact" then return end
 if typeof(payload.position)~="Vector3" then return end
 local scale=math.clamp(if typeof(payload.scale)=="number" then payload.scale else 1,Config.MIN_SCALE,Config.MAX_SCALE)
 local centre=ground(payload.position); local radius=Config.STOMP_EFFECT_RADIUS*scale
 if payload.kind=="stompWindup" then
  local shadow=part(); shadow.Shape=Enum.PartType.Cylinder; shadow.Material=Enum.Material.SmoothPlastic
  shadow.Color=Color3.fromRGB(50,25,20); shadow.Transparency=0.55
  shadow.Size=Vector3.new(0.05,radius*2,radius*2); shadow.CFrame=CFrame.new(centre)*CFrame.Angles(0,0,math.pi/2)
  Debris:AddItem(shadow,Config.STOMP_WINDUP); return
 end
 -- A hollow expanding ring, entirely cosmetic: no camera motion or physics.
 local segments=24
 for i=1,segments do
  local angle=i/segments*math.pi*2; local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
  local p=part(); p.Color=Color3.fromRGB(255,203,94); p.Transparency=0.15
  p.Size=Vector3.new(0.3*scale,0.1,0.2*scale)
  p.CFrame=CFrame.lookAt(centre+direction*scale,centre)*CFrame.Angles(0,math.pi/2,0)
  local target=CFrame.lookAt(centre+direction*radius,centre)*CFrame.Angles(0,math.pi/2,0)
  TweenService:Create(p,TweenInfo.new(Config.STOMP_EFFECT_SECONDS),{CFrame=target,Size=Vector3.new(0.3*scale,0.1,2*math.pi*radius/segments),Transparency=1}):Play()
  Debris:AddItem(p,Config.STOMP_EFFECT_SECONDS+0.1)
 end
end
;(remotes.Notify :: RemoteEvent).OnClientEvent:Connect(effect)
local hud=player:WaitForChild("PlayerGui"):WaitForChild("PhaseOneHud")
local button=hud:WaitForChild("Stomp") :: TextButton
button.Activated:Connect(stomp)
local ring=Instance.new("Frame"); ring.Name="CooldownRing"; ring.BackgroundTransparency=1; ring.Size=UDim2.fromOffset(38,38); ring.Position=UDim2.new(1,5,0.5,-19); ring.Parent=button
local segments: {Frame}={}
for i=1,24 do
 local angle=(i/24)*2*math.pi-math.pi/2
 local segment=Instance.new("Frame"); segment.AnchorPoint=Vector2.new(0.5,0.5); segment.Size=UDim2.fromOffset(4,7)
 segment.Position=UDim2.fromOffset(19+16*math.cos(angle),19+16*math.sin(angle)); segment.Rotation=math.deg(angle)+90
 segment.BorderSizePixel=0; segment.BackgroundColor3=Color3.fromRGB(255,224,94); segment.Parent=ring; segments[i]=segment
end
RunService.RenderStepped:Connect(function()
 local remaining=math.max(0,(player:GetAttribute("StompReadyAt") or 0)-workspace:GetServerTimeNow())
 button.Text=if remaining>0 then string.format("STOMP · %.1fs",remaining) else "1 · STOMP"
 button.AutoButtonColor=remaining==0 and player:GetAttribute("CarryRatio")==nil
 button.BackgroundColor3=if button.AutoButtonColor then Color3.fromRGB(213,73,58) else Color3.fromRGB(100,77,76)
 ring.Visible=remaining>0
 for i,segment in segments do segment.BackgroundTransparency=if i/24<=remaining/Config.STOMP_COOLDOWN then 0 else 0.85 end
end)
