--!strict
local RS = game:GetService("ReplicatedStorage")
local remotes = RS:FindFirstChild("Remotes")
if not remotes then remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = RS end
for _, name in {"Drop","SlowMode","Notify","Stomp","OpenSafe","StopLifting"} do
 if not remotes:FindFirstChild(name) then local event = Instance.new("RemoteEvent"); event.Name = name; event.Parent = remotes end
end
if not workspace:FindFirstChild("Live") then local live = Instance.new("Folder"); live.Name = "Live"; live.Parent = workspace end
local services = script.Parent.Services
-- Subscribe before Data begins asynchronous profile loading.
for _, name in {"WorldObjects","Plots","Growth","Carry","Chasers","Stomp","Safes","Income","Data"} do
 local service = require(services:FindFirstChild(name) :: ModuleScript)
 service.Start()
end
print("[Steal a City] Phase 1 foundation started")
