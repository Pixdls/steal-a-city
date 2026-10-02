--!nonstrict
-- Edit-time only. Rebuild masters, then call result.Scatter(zone.Foliage, names, region, count, opts).
return function(Kit)
	local V, C = Kit.V, Kit.C
	local storage = game:GetService("ReplicatedStorage")
	local assets = storage:FindFirstChild("Assets") or Kit.folder("Assets", storage)
	local previous = assets:FindFirstChild("Foliage")
	if previous then previous:Destroy() end
	local foliage = Kit.folder("Foliage", assets)
	Kit.ensureStuds()

	local function master(name, size)
		local model = Kit.model(name, foliage)
		local root = Kit.decor(model, "Root", V(1, 1, 1), V(0, 0, 0), C.Leaf,
			{ Transparency = 1, CastShadow = false })
		model.PrimaryPart = root
		model:SetAttribute("Footprint", size)
		model:PivotTo(CFrame.new())
		return model
	end

	local function block(model, name, size, position, color, tiny)
		return Kit.decor(model, name, size, position, color, { CastShadow = not tiny })
	end

	-- Kit.decor supplies the common stud/decor properties; wedges retain all of them.
	local function wedge(model, name, size, frame, color)
		local template = block(model, name, size, frame, color, true)
		local part = Instance.new("WedgePart")
		for _, property in { "Name", "Size", "CFrame", "Color", "Material", "MaterialVariant",
			"Anchored", "CanCollide", "CanQuery", "CanTouch", "CastShadow", "TopSurface", "BottomSurface" } do
			part[property] = template[property]
		end
		template:Destroy()
		part.Parent = model
		return part
	end

	-- Each blade occupies its own separated cell, including its tilted bounding box.
	-- Bottom corners are computed from the tilt, so no blade sinks below the root.
	local bladeSites = { {-0.64, -0.64}, {0.64, -0.64}, {-0.64, 0.64}, {0.64, 0.64} }
	for variant = 1, 3 do
		local model = master("GrassTuft" .. variant, V(2, 2, 2))
		local random = Random.new(410 + variant)
		block(model, "HeartBlade", V(0.4, 2, 0.4), V(0, 1, 0), C.Leaf, true)
		for i = 1, variant + 1 do
			local site = bladeSites[i]
			local angle = math.rad(random:NextNumber(-6, 6))
			local height = random:NextNumber(1.25, 1.7)
			local bottomOffset = (height * math.cos(angle) + 0.4 * math.abs(math.sin(angle))) / 2
			local frame = CFrame.new(site[1], bottomOffset, site[2]) * CFrame.Angles(0, 0, angle)
			local color = i % 2 == 0 and C.Grass or C.GrassDark
			if i % 2 == 0 then
				block(model, "OuterBlade" .. i, V(0.4, height, 0.4), frame, color, true)
			else
				wedge(model, "PointedBlade" .. i, V(0.4, height, 0.4), frame, color)
			end
		end
	end

	for _, spec in { {"Pink", C.Pink}, {"Gold", C.Gold}, {"Cream", C.Cream}, {"Sky", C.Sky} } do
		local model = master("Flower" .. spec[1], V(1.4, 2.6, 1.4))
		block(model, "Stem", V(0.4, 2.2, 0.4), V(0, 1.1, 0), C.Leaf, true)
		block(model, "LeftLeaf", V(0.4, 0.4, 0.4), V(-0.4, 0.8, 0), C.Leaf, true)
		block(model, "RightLeaf", V(0.4, 0.4, 0.4), V(0.4, 1.4, 0), C.Leaf, true)
		-- Petals tile a cross around the centre; their inner edges butt exactly.
		block(model, "PetalFront", V(0.5, 0.4, 0.45), V(0, 2.2, 0.475), spec[2], true)
		block(model, "PetalBack", V(0.5, 0.4, 0.45), V(0, 2.2, -0.475), spec[2], true)
		block(model, "PetalLeft", V(0.45, 0.4, 0.5), V(-0.475, 2.2, 0), spec[2], true)
		block(model, "PetalRight", V(0.45, 0.4, 0.5), V(0.475, 2.2, 0), spec[2], true)
		-- Raised centre avoids a flush different-colour top surface.
		block(model, "FlowerCentre", V(0.5, 0.4, 0.5), V(0, 2.4, 0),
			spec[1] == "Gold" and C.Charcoal or C.Gold, true)
	end

	-- Terraces meet at horizontal seams; upper colour always starts at lower top.
	for index, size in { V(5, 4, 5), V(7, 5, 6) } do
		local model = master("Bush" .. index, size)
		local sx, sy, sz = size.X, size.Y, size.Z
		block(model, "LowCanopy", V(sx - 1, 1.2, sz - 1), V(0, 0.6, 0), C.GrassDark)
		block(model, "LeftLobe", V(0.5, 1.6, sz - 2), V(-sx / 2 + 0.25, 0.8, 0), C.Leaf)
		block(model, "RightLobe", V(0.5, 1.9, sz - 2), V(sx / 2 - 0.25, 0.95, 0), C.Leaf)
		block(model, "FrontLobe", V(sx - 2, 1.4, 0.5), V(0, 0.7, sz / 2 - 0.25), C.Leaf)
		block(model, "BackLobe", V(sx - 2, 1.7, 0.5), V(0, 0.85, -sz / 2 + 0.25), C.Leaf)
		block(model, "MiddleCanopy", V(sx - 1.6, sy - 2.2, sz - 1.6), V(0, sy / 2 + 0.1, 0), C.Leaf)
		block(model, "Crown", V(sx - 3, 1, sz - 3), V(0, sy - 0.5, 0), C.GrassDark)
	end

	for index, size in { V(2, 2, 2), V(3.5, 2.8, 3), V(5, 3.8, 4) } do
		local model = master("Rock" .. index, size)
		block(model, "StoneBase", V(size.X, 0.8, size.Z), V(0, 0.4, 0), C.Slate)
		block(model, "StoneShoulder", V(size.X - 0.4, size.Y - 1.3, size.Z - 0.4),
			V(0, (size.Y - 1.3) / 2 + 0.8, 0), C.Slate)
		block(model, "SunlitCap", V(size.X - 0.9, 0.5, size.Z - 0.9),
			V(0.1, size.Y - 0.25, -0.1), C.Cream)
	end

	for index = 1, 2 do
		local model = master("DryShrub" .. index, V(3, 3, 3))
		block(model, "WoodyStem", V(0.5, 2.5, 0.5), V(0, 1.25, 0), C.WoodDark, true)
		block(model, "CrownLeaves", V(0.9, 0.5, 0.9), V(0, 2.75, 0), C.Sand, true)
		for i, site in { {-1, 0}, {1, 0}, {0, -1}, {0, 1} } do
			local height = 1.4 + ((i + index) % 3) * 0.25
			block(model, "Twig" .. i, V(0.4, height, 0.4), V(site[1], height / 2, site[2]), C.WoodDark, true)
			block(model, "DryLeaves" .. i, V(1, 0.5, 1), V(site[1], height + 0.25, site[2]),
				i % 2 == 0 and C.Gold or C.Sand, true)
		end
	end

	do
		local model = master("CactusTall", V(3, 7, 3))
		block(model, "CentralStem", V(1, 6.4, 1), V(0, 3.2, 0), C.Leaf)
		block(model, "LeftElbow", V(1, 0.6, 0.8), V(-1, 2.3, 0), C.Leaf)
		block(model, "LeftArm", V(0.6, 2.4, 0.8), V(-1.2, 3.8, 0), C.Leaf)
		block(model, "RightElbow", V(1, 0.6, 0.8), V(1, 3.3, 0), C.Leaf)
		block(model, "RightArm", V(0.6, 2.1, 0.8), V(1.2, 4.65, 0), C.Leaf)
		block(model, "PinkBloom", V(0.8, 0.6, 0.8), V(0, 6.7, 0), C.Pink, true)
	end

	-- Disjoint strips make connected, stepped silhouettes without layered plates.
	local function patch(name, width, depth, color, variant)
		local model = master(name, V(width, 0.1, depth))
		local widths = variant == 2 and {0.45, 0.8, 1, 0.65, 0.35} or {0.5, 0.85, 1, 0.75, 0.4}
		for strip = 1, 5 do
			local w = width * widths[strip]
			local x = (strip == 2 and -1 or strip == 4 and 1 or 0) * width * 0.05
			block(model, "GroundStrip" .. strip, V(w, 0.1, depth / 5),
				V(x, 0.05, -depth / 2 + (strip - 0.5) * depth / 5), color, true)
		end
	end
	patch("DirtPatch1", 8, 6, C.Dirt, 1)
	patch("DirtPatch2", 14, 9, C.Dirt, 2)
	patch("DirtPatch3", 20, 12, C.Dirt, 3)
	patch("WornPatch1", 8, 6, C.GrassDark, 1)
	patch("WornPatch2", 16, 10, C.GrassDark, 2)

	-- opts.clusters: {min=3, max=7, radius=6}, {3,7}, or a fixed items-per-cluster number.
	-- opts.seed optionally makes a scatter reproducible. Returns the number actually placed;
	-- blocked or invalid terrain is skipped after a bounded retry budget.
	local function Scatter(parent, masters, region, count, opts)
		opts = opts or {}
		assert(parent and parent:IsA("Instance"), "Scatter needs a destination Instance")
		assert(region.x0 < region.x1 and region.z0 < region.z1, "Scatter needs a nonempty rectangle")
		local random = Random.new(opts.seed or 731)
		local scaleRange = opts.scale or {0.85, 1.15}
		assert(scaleRange[1] > 0 and scaleRange[2] >= scaleRange[1], "Invalid scatter scale range")
		local cluster = opts.clusters
		local minItems, maxItems, radius = 3, 7, 6
		if type(cluster) == "number" then
			minItems, maxItems = cluster, cluster
		elseif type(cluster) == "table" then
			minItems, maxItems = cluster.min or cluster[1] or 3, cluster.max or cluster[2] or 7
			radius = cluster.radius or 6
		end
		minItems = math.max(1, math.floor(minItems))
		maxItems = math.max(minItems, math.floor(maxItems))
		assert(radius >= 0, "Cluster radius must be nonnegative")
		local allowed = {}
		for _, name in opts.groundNames or {"Grass", "Meadow", "Street", "Floor", "Boardwalk", "Ground"} do
			allowed[name] = true
		end
		local props = assets:FindFirstChild("Props")
		local set = props and props:FindFirstChild("Set")
		local choices = {}
		for _, name in masters do
			local source = foliage:FindFirstChild(name) or (set and set:FindFirstChild(name))
			assert(source and source:IsA("Model") and source.PrimaryPart, "Missing scatter master: " .. name)
			local footprint = source:GetAttribute("Footprint")
			assert(typeof(footprint) == "Vector3", "Missing Footprint: " .. name)
			table.insert(choices, {model = source, footprint = footprint})
		end
		count = math.max(0, math.floor(count))
		if #choices == 0 or count == 0 then return 0 end
		local occupied = {}
		-- Repeated calls to this parent also preserve separation between placed masters.
		for _, child in parent:GetChildren() do
			if child:IsA("Model") then
				local frame, size = child:GetBoundingBox()
				local halfX = (math.abs(frame.RightVector.X) * size.X + math.abs(frame.UpVector.X) * size.Y
					+ math.abs(frame.LookVector.X) * size.Z) / 2
				local halfZ = (math.abs(frame.RightVector.Z) * size.X + math.abs(frame.UpVector.Z) * size.Y
					+ math.abs(frame.LookVector.Z) * size.Z) / 2
				table.insert(occupied, {x0 = frame.X - halfX, x1 = frame.X + halfX,
					z0 = frame.Z - halfZ, z1 = frame.Z + halfZ})
			end
		end
		local function intersects(a, b)
			return a.x0 < b.x1 + 0.1 and a.x1 > b.x0 - 0.1
				and a.z0 < b.z1 + 0.1 and a.z1 > b.z0 - 0.1
		end
		local placed, remaining, centerX, centerZ = 0, 0, 0, 0
		local clusterAttempts = 0
		for _ = 1, math.max(100, count * 60) do
			if placed >= count then break end
			if remaining == 0 or clusterAttempts >= 40 then
				centerX = random:NextNumber(region.x0, region.x1)
				centerZ = random:NextNumber(region.z0, region.z1)
				remaining = random:NextInteger(minItems, maxItems)
				clusterAttempts = 0
			end
			clusterAttempts += 1
			local angle = random:NextNumber(0, 2 * math.pi)
			local distance = math.sqrt(random:NextNumber()) * radius
			local x, z = centerX + math.cos(angle) * distance, centerZ + math.sin(angle) * distance
			local choice = choices[random:NextInteger(1, #choices)]
			local scale = random:NextNumber(scaleRange[1], scaleRange[2])
			local yaw = opts.yawRandom == false and 0 or random:NextNumber(0, 2 * math.pi)
			local sx, sz = choice.footprint.X * scale, choice.footprint.Z * scale
			local hx = (math.abs(math.cos(yaw)) * sx + math.abs(math.sin(yaw)) * sz) / 2
			local hz = (math.abs(math.sin(yaw)) * sx + math.abs(math.cos(yaw)) * sz) / 2
			local bounds = {x0 = x - hx, x1 = x + hx, z0 = z - hz, z1 = z + hz}
			if bounds.x0 < region.x0 or bounds.x1 > region.x1 or bounds.z0 < region.z0 or bounds.z1 > region.z1 then continue end
			local blocked = false
			for _, rect in opts.avoid or {} do
				if intersects(bounds, rect) then blocked = true break end
			end
			if blocked then continue end
			for _, rect in occupied do
				if intersects(bounds, rect) then blocked = true break end
			end
			if blocked then continue end
			local position, ground = Kit.groundAt(x, z, {parent})
			if not position or not ground or not allowed[ground.Name] or position.Y > 2 then continue end
			Kit.place(choice.model, CFrame.new(position) * CFrame.Angles(0, yaw, 0), parent, scale)
			table.insert(occupied, bounds)
			placed += 1
			remaining -= 1
		end
		return placed
	end

	return { summary = "Built 20 foliage masters: 3 grasses, 4 flowers, 2 bushes, 3 rocks, 2 shrubs, cactus, 5 ground patches.", Scatter = Scatter }
end
