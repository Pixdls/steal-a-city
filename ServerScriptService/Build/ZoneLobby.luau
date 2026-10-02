--!nonstrict
-- Edit-time dresser. Owns only Home.{Props,Foliage,Lighting}.LobbyDressing.
-- The requested full foliage schedule needs a larger zone budget; never silently
-- exceed 2,600 parts to reach it. Summary reports actual placements and shortfalls.
return function(Kit, ctx)
	local home = assert(ctx.map:FindFirstChild("Home"), "ZoneLobby needs Map.Home")
	local set = assert(ctx.propSet, "ZoneLobby needs Props.Set")
	local V, C = Kit.V, Kit.C
	local budget = 3600
	local function countParts(parent)
		local count = 0
		for _, item in parent:GetDescendants() do
			if item:IsA("BasePart") then count += 1 end
		end
		return count
	end
	local destinations = {}
	for _, category in { "Props", "Foliage", "Lighting" } do
		local parent = assert(home:FindFirstChild(category), "Missing Home." .. category)
		local previous = parent:FindFirstChild("LobbyDressing")
		if previous then previous:Destroy() end
		destinations[category] = Kit.folder("LobbyDressing", parent)
	end
	local initial = countParts(home)
	local remaining = math.max(0, budget - initial)
	local counts, skipped = {}, 0
	local function tally(name, amount)
		counts[name] = (counts[name] or 0) + amount
	end
	local function bounds(part)
		local cf, size = part.CFrame, part.Size
		local r, u, l = cf.RightVector, cf.UpVector, cf.LookVector
		local h = V(math.abs(r.X) * size.X + math.abs(u.X) * size.Y + math.abs(l.X) * size.Z,
			math.abs(r.Y) * size.X + math.abs(u.Y) * size.Y + math.abs(l.Y) * size.Z,
			math.abs(r.Z) * size.X + math.abs(u.Z) * size.Y + math.abs(l.Z) * size.Z) / 2
		return { lo = cf.Position - h, hi = cf.Position + h }
	end
	local obstacles, avoid = {}, {}
	local function reserve(rect)
		table.insert(avoid, rect)
	end
	local function remember(part)
		if part.Transparency >= 1 then return end
		local box = bounds(part)
		table.insert(obstacles, box)
		-- Ground is raycast terrain, not an obstacle rectangle for scatter.
		if box.hi.Y > 0.2 then
			reserve({ x0 = box.lo.X - 0.15, x1 = box.hi.X + 0.15,
				z0 = box.lo.Z - 0.15, z1 = box.hi.Z + 0.15 })
		end
	end
	for _, item in home:GetDescendants() do
		if item:IsA("BasePart") then remember(item) end
	end
	local markerRects = {}
	for _, item in ctx.map:GetDescendants() do
		if not item:IsA("BasePart") then continue end
		local parent = item.Parent
		if item.Name == "SpawnPoint" or item:IsA("SpawnLocation")
			or (parent and (parent.Name == "Spawns" or parent.Name == "SafeSpawns" or parent.Name == "ChaserPosts")) then
			local p = item.Position
			local rect = { x0 = p.X - 6, x1 = p.X + 6, z0 = p.Z - 6, z1 = p.Z + 6 }
			table.insert(markerRects, rect)
			reserve(rect) -- square conservatively contains the required six-stud circle
		end
	end
	local protected = {}
	for _, side in { -1, 1 } do
		for k = 0, 3 do
			local z = 30 + k * 54
			local floor = { x0 = side < 0 and -100 or 40, x1 = side < 0 and -40 or 100,
				z0 = z - 25, z1 = z + 25 }
			-- Preserve the full existing +/-9 entrance, wider than the requested gap.
			local entrance = { x0 = side < 0 and -40 or 30, x1 = side < 0 and -30 or 40,
				z0 = z - 9, z1 = z + 9 }
			table.insert(protected, floor)
			table.insert(protected, entrance)
			reserve(floor)
			reserve(entrance)
		end
	end
	reserve({ x0 = -30, x1 = 30, z0 = 0, z1 = 262 })
	local function intersectsRect(box, rect)
		return box.lo.X < rect.x1 + 0.1 and box.hi.X > rect.x0 - 0.1
			and box.lo.Z < rect.z1 + 0.1 and box.hi.Z > rect.z0 - 0.1
	end
	local function clear(model)
		for _, part in model:GetDescendants() do
			if not part:IsA("BasePart") or part.Transparency >= 1 then continue end
			local b = bounds(part)
			if b.lo.X < -103.8 or b.hi.X > 103.8 or b.lo.Z < 2 or b.hi.Z > 259 then return false end
			for _, rect in protected do if intersectsRect(b, rect) then return false end end
			for _, rect in markerRects do if intersectsRect(b, rect) then return false end end
			for _, a in obstacles do
				-- Ground contact is allowed; all above-ground foreign geometry gets
				-- a 0.1 horizontal clearance, including differently coloured faces.
				if b.lo.Y < a.hi.Y - 0.001 and b.hi.Y > a.lo.Y + 0.001
					and b.lo.X < a.hi.X + 0.1 and b.hi.X > a.lo.X - 0.1
					and b.lo.Z < a.hi.Z + 0.1 and b.hi.Z > a.lo.Z - 0.1 then return false end
			end
		end
		return true
	end
	local function place(name, x, z, yaw, category)
		local master = set:FindFirstChild(name)
		if not master or countParts(master) > remaining then skipped += 1 return nil end
		local model = Kit.place(master, CFrame.new(x, 0, z) * CFrame.Angles(0, yaw or 0, 0), nil)
		if not clear(model) then model:Destroy() skipped += 1 return nil end
		model.Name = name .. "_" .. tostring((counts[name] or 0) + 1)
		model.Parent = destinations[category or "Props"]
		remaining -= countParts(model)
		tally(name, 1)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then remember(part) end
		end
		return model
	end
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local foliageSet = assets and assets:FindFirstChild("Foliage")
	local seed = 801
	local function scatter(names, region, requested, category)
		if not ctx.Scatter or not foliageSet then return end
		local cost = 0
		for _, name in names do
			local master = foliageSet:FindFirstChild(name)
			if not master then return end
			cost = math.max(cost, countParts(master))
		end
		local amount = math.min(requested, math.floor(remaining / math.max(1, cost)))
		if amount == 0 then return end
		seed += 1
		local before = countParts(destinations.Foliage)
		local previous = {}
		for _, model in destinations.Foliage:GetChildren() do previous[model] = true end
		local placed = ctx.Scatter(destinations.Foliage, names, region, amount, {
			avoid = avoid, groundNames = { "Grass", "Meadow", "Ground" },
			seed = seed, scale = { 1, 1 }, yawRandom = false,
			clusters = { min = 2, max = 4, radius = 3 },
		})
		remaining -= countParts(destinations.Foliage) - before
		tally(category, placed or 0)
		for _, model in destinations.Foliage:GetChildren() do
			if not previous[model] then
				for _, part in model:GetDescendants() do
					if part:IsA("BasePart") then remember(part) end
				end
			end
		end
	end

	-- Benches face the lane. Their six-stud length stays wholly inside the
	-- lane-side verge; boxes sit behind them, short of the fence at |x|=38.25.
	for _, side in { -1, 1 } do
		for _, z in { 57, 111, 165 } do
			place("Bench", side * 33.5, z, -side * math.pi / 2)
			place("FlowerBox", side * 36.2, z, -side * math.pi / 2)
		end
	end
	-- Guarantee an opportunity for colour at every entrance before spending
	-- the remaining budget on repeat edging or random wall foliage.
	for _, side in { -1, 1 } do
		for k = 0, 3 do
			local z = 30 + k * 54
			scatter({ "FlowerPink", "FlowerGold", "FlowerCream", "FlowerSky" },
				{ x0 = side < 0 and -35 or 31, x1 = side < 0 and -31 or 35,
					z0 = z - 16, z1 = z - 10 }, 1, "Flowers")
		end
	end
	local sign = place("Signpost", -34, 10, 0)
	if sign then
		local face = sign:FindFirstChild("Sign", true)
		if face then Kit.label(face, Enum.NormalId.Back, "RANCH TRAIL →\nSAFE ZONE", C.Charcoal) end
	end
	local board = place("BulletinBoard", -66, 230, math.pi)
	if board then
		for i, text in { "RANCH TRAIL\nEXPLORE", "YOUR PLOT\nBUILD & GROW", "SAFE ZONE\nWELCOME HOME" } do
			local poster = board:FindFirstChild("Poster" .. i, true)
			if poster then Kit.label(poster, Enum.NormalId.Back, text, C.Charcoal, 28) end
		end
	end
	-- PathEdge is the explicit lane exception: it sits OUTSIDE the dirt,
	-- not on its raised surface. Prioritize matching start/end accents.
	for _, z in { 8, 214, 62, 116, 170, 35, 89, 143, 197 } do
		local edge = set:FindFirstChild("PathEdge")
		if not edge or remaining < countParts(edge) * 2 + 60 then break end
		for _, side in { -1, 1 } do place("PathEdge", side * 9.6, z, math.pi / 2) end
	end
	-- Station lamps supplement the station and lane lights owned by BuildMap.
	for _, x in { -52, 52 } do place("LanternPost", x, 244, math.pi, "Lighting") end
	place("Barrel", -34, 253, 0)
	-- Retain sixteen parts for living detail before the relatively costly crate.
	local crate = set:FindFirstChild("Crate")
	if crate and remaining >= countParts(crate) + 16 then place("Crate", 34, 253, 0) end
	-- Bushes anchor the front/back verge corners without touching floors or
	-- facade feet. Larger wall masses cannot fit the four-stud outer strip.
	for _, side in { -1, 1 } do
		for _, z in { 17, 218 } do
			scatter({ "Bush1" }, { x0 = side < 0 and -37 or 30.2,
				x1 = side < 0 and -30.2 or 37, z0 = z - 3, z1 = z + 3 }, 1, "Bushes")
		end
	end
	for _, side in { -1, 1 } do
		-- Narrow outer wall strip and inner plot borders, both outside floors.
		for _, band in { {101.2, 103.8}, {31, 35.5} } do
			scatter({ "GrassTuft1", "GrassTuft2", "GrassTuft3" },
				{ x0 = side < 0 and -band[2] or band[1], x1 = side < 0 and -band[1] or band[2],
					z0 = 10, z1 = 218 }, 23, "Tufts")
		end
		scatter({ "Rock1" }, { x0 = side < 0 and -99 or 80, x1 = side < 0 and -80 or 99,
			z0 = 220, z1 = 225 }, 5, "Rocks")
	end
	local totals = {}
	for _, category in { "Props", "Foliage", "Lighting" } do
		table.insert(totals, category .. "=" .. countParts(destinations[category]) .. " parts")
	end
	local details = {}
	for _, name in { "Bench", "FlowerBox", "Signpost", "BulletinBoard", "LanternPost", "Barrel", "Crate", "PathEdge",
		"Tufts", "Flowers", "Bushes", "Rocks" } do
		table.insert(details, name .. "=" .. (counts[name] or 0))
	end
	return string.format("Lobby: %s; %s. Home=%d/%d parts (existing=%d); skipped props=%d. Foliage targets=90/40/16/10; actual=%d/%d/%d/%d. Scatter available=%s.",
		table.concat(totals, ", "), table.concat(details, ", "), countParts(home), budget, initial, skipped,
		counts.Tufts or 0, counts.Flowers or 0, counts.Bushes or 0, counts.Rocks or 0, tostring(ctx.Scatter ~= nil))
end
