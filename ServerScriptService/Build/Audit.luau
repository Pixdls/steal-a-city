--!nonstrict
-- Edit-time map audit (docs/MAP_REVAMP.md, Review Loop step 1).
-- Run: local Kit = loadstring(B.Kit.Source)(); return loadstring(B.Audit.Source)()(Kit)
-- Reports, per zone: intersections and coplanar same-direction faces between parts of
-- different colour, floating models, missing PrimaryParts, default names, off-palette
-- colours, hierarchy, part counts. Zero errors is the bar.

return function(Kit, opts)
	opts = opts or {}
	local Map = workspace:FindFirstChild("Map")
	if not Map then return "no workspace.Map" end
	local EPS, PEN = 0.01, 0.05
	local MAX_LIST = opts.maxList or 12
	local palette = {}
	for _, c in Kit.C do palette[string.format("%d,%d,%d", math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))] = true end
	palette["255,214,120"] = true -- lamp neon
	local ALLOWED_SUB = { Structure = true, Props = true, Foliage = true, Lighting = true, Markers = true,
		Plots = true, SafeZone = true, Stations = true, Boards = true, Spawns = true, SafeSpawns = true, ChaserPosts = true, Walls = true }

	local function zoneOf(inst)
		local z = inst
		while z.Parent and z.Parent ~= Map and z.Parent.Parent ~= Map do z = z.Parent end
		if z.Parent == Map then return z.Name end
		return z.Parent.Name .. "." .. z.Name
	end

	local zones = {}
	local function Z(name)
		local z = zones[name]
		if not z then
			z = { parts = 0, boxes = {}, unanchored = 0, names = {}, noPrimary = {}, offPalette = {}, offPaletteCount = 0, floating = {}, floatingCount = 0,
				intersect = {}, intersectCount = 0, coplanar = {}, coplanarCount = 0, hierarchy = {},
				disconnected = {}, disconnectedCount = 0, scale = {}, scaleCount = 0 }
			zones[name] = z
		end
		return z
	end
	local function add(list, count, s) if #list < MAX_LIST then table.insert(list, s) end end
	local function short(inst) return inst:GetFullName():gsub("^Workspace%.Map%.", "") end

	for _, d in Map:GetDescendants() do
		if d:IsA("BasePart") then
			local z = Z(zoneOf(d))
			z.parts += 1
			if not d.Anchored then z.unanchored += 1 end
			if d.Name == "Part" or d.Name == "Union" or d.Name == "MeshPart" then add(z.names, 0, short(d)) end
			if d.Transparency < 1 then
				local key = string.format("%d,%d,%d", math.round(d.Color.R * 255), math.round(d.Color.G * 255), math.round(d.Color.B * 255))
				if not palette[key] then z.offPaletteCount += 1; add(z.offPalette, 0, short(d) .. " " .. key) end
				local cf, s = d.CFrame, d.Size
				local aligned = math.abs(math.abs(cf.LookVector.Z) - 1) < 1e-3 and math.abs(math.abs(cf.UpVector.Y) - 1) < 1e-3
				local block = d:IsA("Part") and d.Shape == Enum.PartType.Block
				local h = Vector3.new(
					math.abs(cf.RightVector.X) * s.X + math.abs(cf.UpVector.X) * s.Y + math.abs(cf.LookVector.X) * s.Z,
					math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z,
					math.abs(cf.RightVector.Z) * s.X + math.abs(cf.UpVector.Z) * s.Y + math.abs(cf.LookVector.Z) * s.Z) / 2
				-- Rotated, wedge, cylinder, ball and mesh parts use a shrunk world box (their true volume is
				-- inside it), so a flagged overlap is real; coplanar tests only run on aligned blocks.
				local exact = block and aligned
				if not exact then h = h * 0.8 end
				table.insert(z.boxes, { p = d, min = cf.Position - h, max = cf.Position + h, key = key, exact = exact })
			end
		elseif d:IsA("Model") then
			local z = Z(zoneOf(d))
			if d.Name == "Model" then add(z.names, 0, short(d)) end
			if not d.PrimaryPart then add(z.noPrimary, 0, short(d)) end
		elseif d:IsA("Folder") and d.Parent and d.Parent.Parent == Map and d.Parent.Name ~= "Stages" then
			if not ALLOWED_SUB[d.Name] then add(Z(d.Parent.Name).hierarchy, 0, short(d)) end
		end
	end

	-- overlap and coplanar checks (spatial hash per zone)
	local CELL = 24
	for _, z in zones do
		local grid = {}
		for i, e in z.boxes do
			for x = math.floor(e.min.X / CELL), math.floor(e.max.X / CELL) do
				for y = math.floor(e.min.Y / CELL), math.floor(e.max.Y / CELL) do
					for zz = math.floor(e.min.Z / CELL), math.floor(e.max.Z / CELL) do
						local c = x .. "," .. y .. "," .. zz
						grid[c] = grid[c] or {}
						table.insert(grid[c], i)
					end
				end
			end
		end
		local seen = {}
		for _, list in grid do
			for a = 1, #list do
				for b = a + 1, #list do
					local i, j = list[a], list[b]
					local pk = math.min(i, j) * 1e6 + math.max(i, j)
					if not seen[pk] then
						seen[pk] = true
						local A, B = z.boxes[i], z.boxes[j]
						if A.key ~= B.key then
							local o = { X = math.min(A.max.X, B.max.X) - math.max(A.min.X, B.min.X),
								Y = math.min(A.max.Y, B.max.Y) - math.max(A.min.Y, B.min.Y),
								Z = math.min(A.max.Z, B.max.Z) - math.max(A.min.Z, B.min.Z) }
							if o.X > PEN and o.Y > PEN and o.Z > PEN then
								z.intersectCount += 1
								add(z.intersect, 0, string.format("%s <> %s (%.2f,%.2f,%.2f)", short(A.p), short(B.p), o.X, o.Y, o.Z))
							elseif A.exact and B.exact and o.X > -EPS and o.Y > -EPS and o.Z > -EPS then
								for _, ax in { "X", "Y", "Z" } do
									local others = { X = { "Y", "Z" }, Y = { "X", "Z" }, Z = { "X", "Y" } }
									if o[others[ax][1]] > 0.3 and o[others[ax][2]] > 0.3 then
										if math.abs(A.max[ax] - B.max[ax]) < EPS or math.abs(A.min[ax] - B.min[ax]) < EPS then
											z.coplanarCount += 1
											add(z.coplanar, 0, string.format("%s <> %s [%s]", short(A.p), short(B.p), ax))
											break
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- disconnected parts: every visible part of a model must touch (within 0.1) the rest of its model
	local function partBox(p)
		local c, s = p.CFrame, p.Size
		local h = Vector3.new(
			math.abs(c.RightVector.X) * s.X + math.abs(c.UpVector.X) * s.Y + math.abs(c.LookVector.X) * s.Z,
			math.abs(c.RightVector.Y) * s.X + math.abs(c.UpVector.Y) * s.Y + math.abs(c.LookVector.Y) * s.Z,
			math.abs(c.RightVector.Z) * s.X + math.abs(c.UpVector.Z) * s.Y + math.abs(c.LookVector.Z) * s.Z) / 2
		return c.Position - h, c.Position + h
	end
	local function disconnected(m)
		local parts = {}
		for _, p in m:GetDescendants() do if p:IsA("BasePart") and p.Transparency < 1 then table.insert(parts, p) end end
		if #parts < 2 then return 0 end
		local boxes, adj = {}, {}
		for i, p in parts do local lo, hi = partBox(p); boxes[i] = { lo, hi }; adj[i] = {} end
		for i = 1, #parts do
			for j = i + 1, #parts do
				local A, B = boxes[i], boxes[j]
				if A[1].X <= B[2].X + 0.1 and B[1].X <= A[2].X + 0.1 and A[1].Y <= B[2].Y + 0.1 and B[1].Y <= A[2].Y + 0.1 and A[1].Z <= B[2].Z + 0.1 and B[1].Z <= A[2].Z + 0.1 then
					table.insert(adj[i], j); table.insert(adj[j], i)
				end
			end
		end
		local seen, stack, n = { [1] = true }, { 1 }, 1
		while #stack > 0 do
			local i = table.remove(stack)
			for _, j in adj[i] do if not seen[j] then seen[j] = true; n += 1; table.insert(stack, j) end end
		end
		return #parts - n
	end
	-- scale check: masters carry an ExpectedSize attribute (Vector3) set by their builders; +-25% tolerance
	for _, m in Map:GetDescendants() do
		if m:IsA("Model") and m.PrimaryPart then
			local z = Z(zoneOf(m))
			local isLeaf = true
			for _, c in m:GetChildren() do if c:IsA("Model") then isLeaf = false break end end
			if isLeaf then
				local dc = disconnected(m)
				if dc > 0 then z.disconnectedCount += 1; add(z.disconnected, 0, short(m) .. " (" .. dc .. " loose)") end
				local exp = m:GetAttribute("ExpectedSize")
				if typeof(exp) == "Vector3" then
					local _, size = m:GetBoundingBox()
					local sc = m:GetScale()
					local ratio = math.max(size.X / (exp.X * sc), size.Y / (exp.Y * sc), size.Z / (exp.Z * sc))
					local ratio2 = math.min(size.X / (exp.X * sc), size.Y / (exp.Y * sc), size.Z / (exp.Z * sc))
					if ratio > 1.25 or ratio2 < 0.75 then z.scaleCount += 1; add(z.scale, 0, string.format("%s %.1fx%.1fx%.1f vs %s", short(m), size.X, size.Y, size.Z, tostring(exp))) end
				end
			end
		end
	end

	-- floating models: bounding-box bottom must rest on something (ground top is y = 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = false
	for _, m in Map:GetDescendants() do
		if m:IsA("Model") and m.PrimaryPart and #m:GetChildren() > 0 then
			local cf = m:GetBoundingBox()
			local bottom = math.huge -- lowest VISIBLE part; invisible roots sit around the pivot
			for _, p in m:GetDescendants() do
				if p:IsA("BasePart") and p.Transparency < 1 then
					local c, sz = p.CFrame, p.Size -- world AABB half-height of a rotated part
					local hy = math.abs(c.RightVector.Y) * sz.X / 2 + math.abs(c.UpVector.Y) * sz.Y / 2 + math.abs(c.LookVector.Y) * sz.Z / 2
					bottom = math.min(bottom, p.Position.Y - hy)
				end
			end
			if bottom == math.huge then continue end
			params.FilterDescendantsInstances = { m }
			local hit = workspace:Raycast(Vector3.new(cf.Position.X, bottom + 1, cf.Position.Z), Vector3.new(0, -2.5, 0), params)
			local gap = hit and (bottom - hit.Position.Y) or (bottom > 0.02 and bottom or 0)
			if gap > 0.02 then
				local z = Z(zoneOf(m))
				z.floatingCount += 1
				add(z.floating, 0, string.format("%s gap=%.2f", short(m), gap))
			end
		end
	end

	local out, errors = {}, 0
	local names = {}
	for n in zones do table.insert(names, n) end
	table.sort(names)
	for _, n in names do
		local z = zones[n]
		local e = z.unanchored + #z.names + #z.noPrimary + z.offPaletteCount + z.floatingCount + z.intersectCount + z.coplanarCount + #z.hierarchy + z.disconnectedCount + z.scaleCount
		errors += e
		table.insert(out, string.format("== %s: %d parts, %d errors (intersect %d, coplanar %d, floating %d, disconnected %d, scale %d, off-palette %d, noPrimary %d, names %d, unanchored %d, hierarchy %d)",
			n, z.parts, e, z.intersectCount, z.coplanarCount, z.floatingCount, z.disconnectedCount, z.scaleCount, z.offPaletteCount, #z.noPrimary, #z.names, z.unanchored, #z.hierarchy))
		for _, k in { "intersect", "coplanar", "floating", "disconnected", "scale", "offPalette", "noPrimary", "names", "hierarchy" } do
			if #z[k] > 0 then table.insert(out, "  " .. k .. ": " .. table.concat(z[k], " | ")) end
		end
	end
	table.insert(out, 1, "AUDIT total errors: " .. errors)
	return table.concat(out, "\n")
end
