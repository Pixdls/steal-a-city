--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Format = require(RS:WaitForChild("Shared"):WaitForChild("Format"))
local player = Players.LocalPlayer
local remotes = RS:WaitForChild("Remotes")
local gui = Instance.new("ScreenGui"); gui.Name = "PhaseOneHud"; gui.ResetOnSpawn = false; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
local function label(name: string, text: string, position: UDim2, size: UDim2): TextLabel
 local item = Instance.new("TextLabel"); item.Name=name; item.Text=text; item.Position=position; item.Size=size; item.BackgroundTransparency=1; item.Font=Enum.Font.FredokaOne; item.TextColor3=Color3.new(1,1,1); item.TextSize=28; item.TextStrokeColor3=Color3.fromRGB(25,22,30); item.TextStrokeTransparency=0; item.TextXAlignment=Enum.TextXAlignment.Left; item.Parent=gui
 return item
end
local function button(name: string, text: string, position: UDim2, color: Color3): TextButton
 local item = Instance.new("TextButton"); item.Name=name; item.Text=text; item.Position=position; item.Size=UDim2.fromOffset(150,48); item.Font=Enum.Font.FredokaOne; item.TextColor3=Color3.new(1,1,1); item.TextSize=23; item.TextStrokeTransparency=0; item.BackgroundColor3=color; item.Parent=gui
 local corner = Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,12); corner.Parent=item
 local stroke = Instance.new("UIStroke"); stroke.Thickness=3; stroke.Color=Color3.fromRGB(25,22,30); stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; stroke.Parent=item
 return item
end
local size = label("Size","",UDim2.new(0,18,1,-120),UDim2.fromOffset(260,40))
local cash = label("Cash","",UDim2.new(0,18,1,-80),UDim2.fromOffset(260,44)); cash.TextColor3=Color3.fromRGB(93,255,102); cash.TextSize=34
local slow = button("SlowMode","SLOW: OFF",UDim2.new(0,18,0.5,-35),Color3.fromRGB(76,142,221))
local drop = button("Drop","DROP",UDim2.new(0.5,-75,1,-155),Color3.fromRGB(255,134,44)); drop.Visible=false
local _stomp = button("Stomp","1 · STOMP",UDim2.new(0.5,-75,1,-72),Color3.fromRGB(213,73,58))
local safesReady = label("SafesReady","SAFES · 0 ready",UDim2.new(1,-200,0.5,-24),UDim2.fromOffset(190,60)); safesReady.TextSize=20; safesReady.TextWrapped=true
local function refreshSafes()
 local ready=player:GetAttribute("SafesReady") or 0
 local queued=player:GetAttribute("SafesQueued") or 0
 safesReady.Text="SAFES · "..tostring(ready).." ready"..(if queued>0 then "\n"..tostring(queued).." queued" else "")
 safesReady.TextColor3=if ready>0 then Color3.fromRGB(255,224,94) else Color3.new(1,1,1)
end
player:GetAttributeChangedSignal("SafesReady"):Connect(refreshSafes)
player:GetAttributeChangedSignal("SafesQueued"):Connect(refreshSafes)
refreshSafes()
local toast = label("Toast","",UDim2.new(0.5,-160,0,20),UDim2.fromOffset(320,70)); toast.TextXAlignment=Enum.TextXAlignment.Center; toast.TextWrapped=true; toast.TextSize=22; toast.Visible=false
local function layout()
 local mobile = UIS.TouchEnabled
 size.Position=UDim2.new(0,18,1,if mobile then -260 else -120)
 cash.Position=UDim2.new(0,18,1,if mobile then -220 else -80)
end
local function refresh()
 size.Text="👟 "..Format.Number(player:GetAttribute("Size") or 10)
 cash.Text=Format.Cash(player:GetAttribute("Cash") or 0)
 drop.Visible=player:GetAttribute("CarryRatio") ~= nil
 slow.Text=if player:GetAttribute("SlowMode") == true then "SLOW: ON" else "SLOW: OFF"
end
for _, attribute in {"Size","Cash","CarryRatio","SlowMode"} do player:GetAttributeChangedSignal(attribute):Connect(refresh) end
slow.Activated:Connect(function() (remotes.SlowMode :: RemoteEvent):FireServer(player:GetAttribute("SlowMode") ~= true) end)
drop.Activated:Connect(function() (remotes.Drop :: RemoteEvent):FireServer() end)
local toastId = 0
local function notify(message: any)
 if typeof(message) == "table" then message=message.message end
 if typeof(message) ~= "string" then return end
 toastId += 1; local id=toastId; toast.Text=message; toast.Visible=true
 task.delay(5,function() if toastId == id then toast.Visible=false end end)
end
;(remotes.Notify :: RemoteEvent).OnClientEvent:Connect(notify)
if player:GetAttribute("OfflineNotice") then notify(player:GetAttribute("OfflineNotice")) end
local sentStop = false
RunService.RenderStepped:Connect(function()
 if player:GetAttribute("Lifting") ~= true then sentStop=false; return end
 local hum = if player.Character then player.Character:FindFirstChildOfClass("Humanoid") else nil
 if hum and (hum.MoveDirection.Magnitude > 0 or hum.Jump) and not sentStop then
  sentStop=true; (remotes.StopLifting :: RemoteEvent):FireServer()
 end
end)
UIS.JumpRequest:Connect(function() if player:GetAttribute("Lifting") == true then (remotes.StopLifting :: RemoteEvent):FireServer() end end)
UIS:GetPropertyChangedSignal("TouchEnabled"):Connect(layout)
layout(); refresh()
