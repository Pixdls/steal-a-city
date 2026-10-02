--!nonstrict
-- Edit-time dresser. Owns only ZoneRanch folders in these two zones.
-- PathEdge is the explicit exception to the clear |x| < 14 running lane.
return function(Kit, ctx)
	assert(ctx and ctx.map and ctx.propSet, "ZoneRanch requires the BuildMap context")
	local foliage = game:GetService("ReplicatedStorage").Assets:FindFirstChild("Foliage")
	local reports = {}
	local function parts(instance)
		local count = 0
		for _, p in instance:GetDescendants() do
			if p:IsA("BasePart") then count += 1 end
		end
		return count
	end
	-- Actual world bounds include asymmetric lantern arms and already-leaning wheels.
	local function bounds(p)
		local cf, s = p.CFrame, p.Size / 2
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local hx = math.abs(r.X)*s.X + math.abs(u.X)*s.Y + math.abs(l.X)*s.Z
		local hy = math.abs(r.Y)*s.X + math.abs(u.Y)*s.Y + math.abs(l.Y)*s.Z
		local hz = math.abs(r.Z)*s.X + math.abs(u.Z)*s.Y + math.abs(l.Z)*s.Z
		return {x0=cf.X-hx, x1=cf.X+hx, z0=cf.Z-hz, z1=cf.Z+hz,
			y0=cf.Y-hy, y1=cf.Y+hy}
	end
	local function modelBounds(model)
		local b = {x0=math.huge, x1=-math.huge, z0=math.huge, z1=-math.huge}
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local a = bounds(p)
				b.x0, b.x1 = math.min(b.x0,a.x0), math.max(b.x1,a.x1)
				b.z0, b.z1 = math.min(b.z0,a.z0), math.max(b.z1,a.z1)
			end
		end
		return b
	end
	local function overlaps(a,b)
		return a.x0 < b.x1+0.1 and a.x1 > b.x0-0.1
			and a.z0 < b.z1+0.1 and a.z1 > b.z0-0.1
	end
	local function dress(zone, budget, z0, z1, outer, lane)
		local folders, counts, avoid = {}, {}, {}
		for _, category in {"Props", "Foliage", "Lighting"} do
			local parent = assert(zone:FindFirstChild(category), "Missing " .. category)
			local old = parent:FindFirstChild("ZoneRanch")
			if old then old:Destroy() end
			folders[category] = Kit.folder("ZoneRanch", parent)
		end
		-- Square exclusions conservatively contain the required six-stud circles.
		-- Include neighbouring-zone markers so the boundary cannot bypass clearance.
		for _, descendant in ctx.map.Stages:GetDescendants() do
			if descendant:IsA("Folder") and (descendant.Name == "Spawns"
				or descendant.Name == "SafeSpawns" or descendant.Name == "ChaserPosts") then
				for _, marker in descendant:GetDescendants() do
					if marker:IsA("BasePart") then
						local p = marker.Position
						table.insert(avoid, {x0=p.X-6,x1=p.X+6,z0=p.Z-6,z1=p.Z+6})
					end
				end
			end
		end
		-- Preserve other dressers and existing raised ground details as occupied space.
		for _, p in zone:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local b = bounds(p)
				if b.y1 > 0.05 and b.y0 < 12 then table.insert(avoid,b) end
			end
		end
		local used = parts(zone)
		local skipped = 0
		local function place(name, category, x, z, yaw, label, fixed)
			local master = ctx.propSet:FindFirstChild(name)
			assert(master and master.PrimaryPart, "Missing prop master: " .. name)
			local cost = parts(master)
			if used + cost > budget then skipped += 1 return nil end
			local clone = Kit.place(master, CFrame.new(x,0,z)*CFrame.Angles(0,yaw or 0,0), nil)
			-- Keep authored scale. Search along the verge if a spawn occupies the preferred site.
			local offsets = fixed and {0} or {0,4,-4,8,-8,12,-12,16,-16,20,-20}
			for _, dz in offsets do
				clone:PivotTo(CFrame.new(x,0,z+dz)*CFrame.Angles(0,yaw or 0,0))
				local b = modelBounds(clone)
				local inner = name == "PathEdge" and 12 or lane
				local clear = b.x0 >= -outer and b.x1 <= outer and b.z0 >= z1+1
					and b.z1 <= z0-1 and (b.x1 <= -inner or b.x0 >= inner)
				if clear then
					for _, occupied in avoid do
						if overlaps(b, occupied) then clear = false break end
					end
				end
				if clear then
					clone.Name = name .. string.format("_%03d", (counts[name] or 0)+1)
					clone.Parent = folders[category]
					if label then
						Kit.label(assert(clone:FindFirstChild("Sign",true)), Enum.NormalId.Back, label, Kit.C.Charcoal)
					end
					table.insert(avoid,b)
					used += cost
					counts[name] = (counts[name] or 0)+1
					return clone
				end
			end
			clone:Destroy()
			skipped += 1
			return nil
		end
		local seed = 1800
		local function scatter(names, count, inner, edge, label, scale)
			if not ctx.Scatter or not foliage then return end
			local maxCost = 0
			for _, name in names do
				local master = assert(foliage:FindFirstChild(name), "Missing foliage master: " .. name)
				maxCost = math.max(maxCost, parts(master))
			end
			local allowance = math.min(count, math.floor((budget-used)/maxCost))
			for sideIndex, side in {-1,1} do
				local n = sideIndex == 1 and math.ceil(allowance/2) or math.floor(allowance/2)
				if n <= 0 then continue end
				seed += 1
				local before = parts(folders.Foliage)
				local region = {x0=side < 0 and -edge or inner, x1=side < 0 and -inner or edge,
					z0=z1+3, z1=z0-3}
				local actual = ctx.Scatter(folders.Foliage, names, region, n, {
					avoid=avoid, groundNames={"Meadow","Ground"}, seed=seed,
					clusters={min=3,max=6,radius=5}, scale=scale or {0.9,1.1},
				})
				used += parts(folders.Foliage)-before
				counts[label] = (counts[label] or 0)+(actual or 0)
			end
		end
		local function remaining() return math.max(0,budget-used) end
		local function finish()
			local entries = {}
			for name, count in counts do table.insert(entries,name .. "=" .. count) end
			table.sort(entries)
			table.insert(reports, string.format("%s: Props=%d, Foliage=%d, Lighting=%d parts; total=%d/%d; skipped props=%d; %s%s",
				zone.Name,parts(folders.Props),parts(folders.Foliage),parts(folders.Lighting),parts(zone),budget,
				skipped,table.concat(entries,", "),ctx.Scatter and "" or "; Scatter unavailable"))
		end
		return place, scatter, remaining, finish
	end

	local ranch = ctx.map.Stages.RanchTrail
	local r = ctx.ranch
	local place, scatter, remaining, finish = dress(ranch,3400,r.z0,r.z1,44,14)
	-- Arms point into the meadow, away from the facade strip. Wheel masters already lean.
	for _, side in {-1,1} do
		for z = r.z0-14, r.z1+10, -28 do
			place("LanternPost","Lighting",side*42,z,-side*math.pi/2,nil,true)
		end
	end
	for i, z in {-42,-148,-254} do
		local side = i%2 == 0 and -1 or 1
		place("HayCart","Props",side*31,z,side*math.pi/2)
		place("WagonWheel","Props",side*39,z+7,-side*math.pi/2)
	end
	for i, z in {-56,-112,-196,-266} do
		local side = i%2 == 0 and 1 or -1
		for _, offset in {-2,2} do place("Barrel","Props",side*34,z+offset,0) end
		place("Tumbleweed","Props",side*24,z-9,0)
	end
	for i=1,6 do
		place("MilkCan","Props",(i%2 == 0 and -1 or 1)*38,-28-(i-1)*46,0)
	end
	place("WaterPump","Props",-28,-38,math.pi/2)
	place("WaterPump","Props",28,-216,-math.pi/2)
	place("Signpost","Props",-22,-18,0,"RANCH TRAIL")
	place("Signpost","Props",22,-280,0,"COWBOY TOWN →")
	-- Eight-stud modules, with alternate sixteen-stud stretches left open.
	for _, side in {-1,1} do
		for index=0,35 do
			if index%4 < 2 then
				place("PathEdge","Props",side*12.5,r.z0-8-index*8,math.pi/2,nil,true)
			end
		end
	end
	-- Full wish list is ~1,750 foliage parts alone. Reserve all categories proportionally
	-- after actual prop costs, using worst-case master costs rather than optimistic averages.
	local specs = {
		{{"DirtPatch1","WornPatch1"},20,20,35,"Patches",{1,1}},
		{{"Bush1","Bush2"},12,35,44,"Bushes"},
		{{"Rock1","Rock2","Rock3"},16,14,23,"Rocks"},
		{{"DryShrub1","DryShrub2"},12,29,40,"Shrubs"},
		{{"FlowerPink","FlowerGold","FlowerCream","FlowerSky"},50,36,44,"Flowers"},
		{{"GrassTuft1","GrassTuft2","GrassTuft3"},90,36,44,"FacadeTufts"},
		{{"GrassTuft1","GrassTuft2","GrassTuft3"},60,14,18,"PathTufts"},
	}
	local wantedCost = 0
	if foliage and ctx.Scatter then
		for _, spec in specs do
			local cost = 0
			for _, name in spec[1] do cost = math.max(cost,parts(assert(foliage:FindFirstChild(name)))) end
			wantedCost += cost*spec[2]
		end
		local fraction = math.min(1,remaining()/math.max(1,wantedCost))
		for _, spec in specs do
			scatter(spec[1],math.floor(spec[2]*fraction),spec[3],spec[4],spec[5],spec[6])
		end
	end
	finish()

	local t = ctx.transition
	place, scatter, remaining, finish = dress(ctx.map.Stages.Transition1,500,t.z0,t.z1,54,40)
	for _, side in {-1,1} do place("LanternPost","Lighting",side*50,t.z0-12,-side*math.pi/2) end
	place("Signpost","Props",44,t.z0-8,0,"SIZE 300+ RECOMMENDED")
	scatter({"Bush1"},4,43,54,"Bushes")
	scatter({"Rock1","Rock2"},6,43,54,"Rocks")
	finish()
	return table.concat(reports,"\n")
end
