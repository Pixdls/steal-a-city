--!nonstrict
-- Edit-time Cowboy Town dressing. Owns only the three ZoneTown subfolders.
return function(Kit, ctx)
	local town = assert(ctx.map.Stages:FindFirstChild("CowboyTown"), "CowboyTown must exist")
	local C, V = Kit.C, Kit.V
	local layout = ctx.town or { z0 = -340, z1 = -680 }
	local near, far = layout.z0, layout.z1 + 8
	local folders = {}
	for _, category in { "Props", "Foliage", "Lighting" } do
		local parent = assert(town:FindFirstChild(category), "Missing " .. category)
		local old = parent:FindFirstChild("ZoneTown")
		if old then old:Destroy() end
		folders[category] = Kit.folder("ZoneTown", parent)
	end
	local function partCount(instance)
		local n = 0
		for _, item in instance:GetDescendants() do
			if item:IsA("BasePart") then n += 1 end
		end
		return n
	end
	local initial = partCount(town)
	local used, budget = initial, 3800
	local actual, targets, failures = {}, {}, {}
	local occupied, markers, obstacles = {}, {}, {}
	local function bounds(part)
		local cf, sz = part.CFrame, part.Size
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local hx = (math.abs(r.X)*sz.X + math.abs(u.X)*sz.Y + math.abs(l.X)*sz.Z)/2
		local hy = (math.abs(r.Y)*sz.X + math.abs(u.Y)*sz.Y + math.abs(l.Y)*sz.Z)/2
		local hz = (math.abs(r.Z)*sz.X + math.abs(u.Z)*sz.Y + math.abs(l.Z)*sz.Z)/2
		return {x0=cf.X-hx, x1=cf.X+hx, y0=cf.Y-hy, y1=cf.Y+hy,
			z0=cf.Z-hz, z1=cf.Z+hz, color=part.Color}
	end
	local function visibleBounds(model)
		local list = {}
		local rect = {x0=math.huge, x1=-math.huge, z0=math.huge, z1=-math.huge}
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local b = bounds(p)
				table.insert(list, b)
				rect.x0, rect.x1 = math.min(rect.x0,b.x0), math.max(rect.x1,b.x1)
				rect.z0, rect.z1 = math.min(rect.z0,b.z0), math.max(rect.z1,b.z1)
			end
		end
		return rect, list
	end
	local function intersects(a,b)
		return a.x0 < b.x1+0.1 and a.x1 > b.x0-0.1 and a.z0 < b.z1+0.1 and a.z1 > b.z0-0.1
	end
	-- Read markers, including attributes used to locate the saloon sign. Never edit them.
	local saloon
	for _, name in {"Spawns", "SafeSpawns", "ChaserPosts"} do
		local folder = town:FindFirstChild(name)
		if folder then
			for _, p in folder:GetDescendants() do
				if p:IsA("BasePart") then
					table.insert(markers, {x0=p.Position.X-6, x1=p.Position.X+6,
						z0=p.Position.Z-6, z1=p.Position.Z+6})
					local isSaloon = string.find(string.lower(p.Name), "saloon", 1, true)
					for _, value in p:GetAttributes() do
						if type(value) == "string" and string.find(string.lower(value), "saloon", 1, true) then isSaloon = true end
					end
					if isSaloon and (not saloon or p.Position.Z > saloon.Z) then saloon = p.Position end
				end
			end
		end
	end
	-- Existing planks, ground patches, facade details and other builders are obstacles.
	for _, p in town:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then table.insert(obstacles,bounds(p)) end
	end
	local function fits(rect, list, street)
		if rect.z0 < far+0.1 or rect.z1 > near-0.1 then return false end
		if street then
			if not ((rect.x0 >= 40 and rect.x1 <= 47) or (rect.x1 <= -40 and rect.x0 >= -47)) then return false end
		else
			if not ((rect.x0 >= 48 and rect.x1 <= 59.9) or (rect.x1 <= -48 and rect.x0 >= -59.9)) then return false end
		end
		for _, r in markers do if intersects(rect,r) then return false end end
		for _, r in occupied do if intersects(rect,r) then return false end end
		for _, a in list do
			for _, b in obstacles do
				local dx = math.min(a.x1,b.x1)-math.max(a.x0,b.x0)
				local dy = math.min(a.y1,b.y1)-math.max(a.y0,b.y0)
				local dz = math.min(a.z1,b.z1)-math.max(a.z0,b.z0)
				if dx > 0.05 and dy > 0.05 and dz > 0.05 then return false end
			end
		end
		return true
	end
	local function request(key, count) targets[key] = (targets[key] or 0)+count end
	local function accept(model, key, street, patch)
		local rect, list = visibleBounds(model)
		local cost = partCount(model)
		if used+cost > budget then return false, "budget" end
		-- Patches may enter the street interior; they must still clear ruts and markers.
		local valid
		if patch then
			valid = rect.z0 >= far+0.1 and rect.z1 <= near-0.1
				and ((rect.x0 >= 10 and rect.x1 <= 46) or (rect.x1 <= -10 and rect.x0 >= -46))
			for _, r in markers do if intersects(rect,r) then valid=false end end
			for _, r in occupied do if intersects(rect,r) then valid=false end end
			for _, a in list do
				for _, b in obstacles do
					if intersects(a,b) and math.min(a.y1,b.y1)-math.max(a.y0,b.y0)>0.05 then valid=false end
				end
			end
		else valid = fits(rect,list,street) end
		if not valid then return false, "clearance" end
		table.insert(occupied,rect)
		used += cost
		actual[key] = (actual[key] or 0)+1
		return true
	end
	local function place(name, key, side, x, z, category, street, modify)
		local master = ctx.propSet:FindFirstChild(name)
		if not master then failures[name]="missing master" return nil end
		local model = Kit.place(master,CFrame.identity,folders[category or "Props"])
		if modify then modify(model) end
		-- Face the street (+Z of each master points inward).
		local yaw = -side*math.pi/2
		for _, offset in {0, 2, -2, 4, -4, 6, -6, 8, -8, 10, -10, 12, -12} do
			model:PivotTo(CFrame.new(side*x,street and 0 or 0.6,z+offset)*CFrame.Angles(0,yaw,0))
			local ok, reason = accept(model,key,street)
			if ok then model.Name=key..string.format("%02d",actual[key]) return model end
			failures[key]=reason
			if reason=="budget" then break end
		end
		model:Destroy()
		return nil
	end
	local function label(model, partName, text)
		if not model then return end
		local p=model:FindFirstChild(partName,true)
		if p then Kit.label(p,Enum.NormalId.Back,text,C.Charcoal) end
	end
	-- Lamps first: 26-stud rhythm, with bounded local shifts around marker reservations.
	for _, side in {-1,1} do
		for z=near-9,far+5,-26 do
			request("LanternPost",1)
			-- The arm overhangs the street, but only the post needs boardwalk support.
			-- Point +Z along the boardwalk to keep its entire envelope inside 48..60.
			place("LanternPost","LanternPost",side,49,z,"Lighting",false,function(m)
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") and p~=m.PrimaryPart then p.CFrame=CFrame.Angles(0,side*math.pi/2,0)*p.CFrame end
				end
			end)
		end
	end
	-- Steps meet the outer face of the existing boardwalk lip at |x|=47.
	-- Merge the master's adjacent same-colour boards into two broad treads.
	for _, side in {-1,1} do
		local sites={near-4,far+4}
		for z=near-60,far+20,-60 do table.insert(sites,z) end
		for _, z in sites do
			request("Steps",1)
			place("Steps","Steps",side,44.5,z,"Props",true,function(m)
				for _, p in m:GetChildren() do if p:IsA("BasePart") and p~=m.PrimaryPart then p:Destroy() end end
				-- Face outward here: the tall tread is adjacent to the boardwalk.
				Kit.part(m,"LowerTread",V(5,0.3,2.5),V(0,0.15,-1.25),C.Wood)
				Kit.part(m,"UpperTread",V(5,0.6,2.5),V(0,0.3,1.25),C.Wood)
				m:SetAttribute("Footprint",V(5,0.6,5))
				-- place() faces inward, so reverse the treads for that orientation.
				for _, p in m:GetChildren() do if p:IsA("BasePart") and p~=m.PrimaryPart then p.CFrame=CFrame.Angles(0,math.pi,0)*p.CFrame end end
			end)
		end
	end
	request("HitchingPost",8) request("Trough",4)
	for _, side in {-1,1} do
		for i=0,3 do
			local z=near-30-i*78
			place("HitchingPost","HitchingPost",side,50,z)
			if i%2==0 then place("Trough","Trough",side,53,z-8) end
		end
	end
	request("BulletinBoard",2) request("Signpost",2)
	for _, side in {-1,1} do
		local m=place("BulletinBoard","BulletinBoard",side,58,near-76)
		for i,text in {"WANTED","REWARD","TOWN MEETING"} do label(m,"Poster"..i,text) end
	end
	label(place("Signpost","Signpost",1,55,far+16),"Sign","CASTLE VILLAGE →")
	local saloonSide=saloon and (saloon.X<0 and -1 or 1) or -1
	label(place("Signpost","Signpost",saloonSide,55,saloon and saloon.Z+10 or near-186),"Sign","SALOON")
	request("CactusPot",6) request("Barrel",16) request("CrateStack",6)
	for _, side in {-1,1} do
		for i=0,2 do place("CactusPot","CactusPot",side,58,near-46-i*100) end
		for i=0,3 do
			local z=near-18-i*82
			place("Barrel","Barrel",side,58,z)
			place("Barrel","Barrel",side,58,z-3.3)
		end
		for i=0,2 do
			place("Crate","CrateStack",side,58,near-62-i*98,"Props",false,function(m)
				local top=ctx.propSet.Crate:Clone()
				top:PivotTo(CFrame.new(0,3,0))
				for _, p in top:GetChildren() do if p~=top.PrimaryPart then p.Parent=m end end
				top:Destroy()
				m:SetAttribute("Footprint",V(3,6,3))
			end)
		end
	end
	request("Tumbleweed",5) request("WagonWheel",3)
	for i=1,5 do place("Tumbleweed","Tumbleweed",i%2==0 and -1 or 1,44,near-38-i*48,"Props",true) end
	for i=1,3 do place("WagonWheel","WagonWheel",i%2==0 and -1 or 1,58,near-105-(i-1)*80) end

	-- Scatter into the same parent so successive calls preserve cluster separation.
	-- Revalidate returned clones against the actual geometry and remaining budget.
	local function scatter(key,names,region,count,seed,patch,dry)
		request(key,count)
		if not ctx.Scatter then failures[key]="Scatter unavailable" return end
		local avoid=table.clone(markers)
		for _, r in occupied do table.insert(avoid,r) end
		local before={}
		for _, m in folders.Foliage:GetChildren() do before[m]=true end
		ctx.Scatter(folders.Foliage,names,region,count,{avoid=avoid,groundNames={"Street"},
			seed=seed,scale={1,1},clusters={min=2,max=4,radius=7}})
		for _, m in folders.Foliage:GetChildren() do
			if not before[m] then
				for _, p in m:GetDescendants() do
					if p:IsA("BasePart") and p.Transparency<1 then
						p.CastShadow=false
						if dry then p.Color=C.Sand end
					end
				end
				local ok,reason=accept(m,key,true,patch)
				if not ok then failures[key]=reason m:Destroy() end
			end
		end
	end
	for _, side in {-1,1} do
		local edge={x0=side<0 and -47 or 42,x1=side<0 and -42 or 47,z0=far+1,z1=near-2}
		-- One cactus per side anchors the final twelve usable studs before the wall.
		local endEdge={x0=edge.x0,x1=edge.x1,z0=far+1,z1=layout.z1+20}
		scatter("CactusTall",{"CactusTall"},endEdge,1,791+side)
		scatter("CactusTall",{"CactusTall"},edge,1,801+side)
		scatter("DryShrub",{"DryShrub1","DryShrub2"},edge,5,811+side)
		scatter("DryTuft",{"GrassTuft1","GrassTuft2","GrassTuft3"},edge,30,821+side,false,true)
		scatter("Patch",{"DirtPatch1","WornPatch1"},
			{x0=side<0 and -46 or 10,x1=side<0 and -10 or 46,z0=far+1,z1=near-2},10,831+side,true,true)
	end
	local summary={string.format("Cowboy Town: %d/%d parts (existing %d; added %d)",used,budget,initial,used-initial)}
	for _, category in {"Props","Foliage","Lighting"} do
		table.insert(summary,category..": "..partCount(folders[category]).." parts")
	end
	local keys={}
	for key in targets do table.insert(keys,key) end
	table.sort(keys)
	for _, key in keys do
		local count=actual[key] or 0
		table.insert(summary,string.format("%s %d/%d%s",key,count,targets[key],count<targets[key]
			and (" ["..(failures[key] or "scatter clearance").."]") or ""))
	end
	return table.concat(summary,"; ")
end
