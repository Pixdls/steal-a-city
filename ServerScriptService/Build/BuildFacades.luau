--!nonstrict
-- Edit-time facade library. Pivot: ground centre of back plane; street: +Z.
-- Run AFTER BuildAssets (which replaces Assets), before the map builder.
return function(Kit)
	Kit.ensureStuds()
	local storage = game:GetService("ReplicatedStorage")
	local assets = storage:FindFirstChild("Assets") or Kit.folder("Assets", storage)
	local old = assets:FindFirstChild("Facades")
	if old then old:Destroy() end
	local facades = Kit.folder("Facades", assets)
	local V, rgb = Kit.V, Kit.rgb
	local white, cream = rgb(255, 250, 225), rgb(255, 231, 174)
	local wood, oak, dark = rgb(159, 83, 32), rgb(218, 146, 62), rgb(83, 43, 27)
	local red, gold, metal = rgb(211, 43, 43), rgb(255, 191, 36), rgb(87, 107, 121)
	local black, glass = rgb(29, 29, 38), rgb(65, 166, 203)
	local green, leaf, pink = rgb(49, 174, 64), rgb(112, 209, 65), rgb(255, 116, 171)
	local counts = { Lobby = {}, Ranch = {}, Western = {}, Blocker = {} }
	local total = 0

	-- Decoration is non-colliding by default; only substantial shells/floors opt in.
	local function part(m, name, x, y, z, sx, sy, sz, color, solid, rotation)
		return Kit.part(m, name, V(sx, sy, sz), CFrame.new(x, y, z) * (rotation or CFrame.identity), color,
			{ CanCollide = solid == true, CanTouch = false })
	end
	local function cylinder(m, name, x, y, z, height, diameter, color, axis, solid)
		local rotation = axis == "Z" and CFrame.Angles(0, math.pi / 2, 0)
			or axis == "X" and CFrame.identity or CFrame.Angles(0, 0, math.pi / 2)
		local p = part(m, name, x, y, z, height, diameter, diameter, color, solid, rotation)
		p.Shape = Enum.PartType.Cylinder
		return p
	end
	local function beam(m, name, a, b, thickness, color)
		return Kit.part(m, name, V(thickness, thickness, (b - a).Magnitude),
			CFrame.lookAt((a + b) / 2, b), color, { CanCollide = false, CanTouch = false })
	end
	local function wedge(m, name, x, y, z, sx, sy, sz, color)
		local p = Instance.new("WedgePart")
		p.Name, p.Size, p.CFrame = name, V(sx, sy, sz), CFrame.new(x, y, z)
		p.Anchored, p.CanCollide, p.CanTouch = true, false, false
		p.Material, p.MaterialVariant = Enum.Material.Plastic, "Studs"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Color, p.Parent = color, m
		return p
	end
	local function model(name, width, theme, height, color, depth)
		local m = Kit.model(name, facades)
		m:SetAttribute("Width", width)
		m:SetAttribute("Theme", theme)
		m.PrimaryPart = Kit.marker(m, "Root", V(1, 1, 1), V(0, 0, 0))
		part(m, "BackWall", 0, height / 2, depth / 2, width, height, depth, color, true)
		return m
	end
	local function finish(m)
		local n = 0
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") then n += 1 end
		end
		m:SetAttribute("PartCount", n)
		total += n
		table.insert(counts[m:GetAttribute("Theme")], m.Name .. "=" .. n)
	end
	local function sign(m, text, width, y, color)
		part(m, "SignFrame", 0, y, 5.25, width + 1.6, 7, 1.5, cream)
		local p = part(m, "SignPlate", 0, y, 6.1, width, 5.5, 0.5, color)
		Kit.label(p, Enum.NormalId.Back, text, gold, 20)
		return p
	end
	local function lantern(m, x, y, z)
		part(m, "LanternBracket", x, y + 2.8, z - 0.9, 0.6, 0.6, 2.8, dark)
		part(m, "LanternGlow", x, y, z, 1.4, 2.3, 1.4, gold)
		for _, dy in {-1.35, 1.35} do part(m, "LanternCap", x, y + dy, z, 2, 0.5, 2, black) end
		for _, dx in {-0.8, 0.8} do part(m, "LanternFrame", x + dx, y, z + 0.75, 0.2, 2.3, 0.2, black) end
	end
	local function window(m, x, y, z, trim, shutters)
		part(m, "WindowSurround", x, y, z, 7, 9, 1.2, trim)
		part(m, "WindowGlass", x, y, z + 0.65, 5.4, 7.3, 0.3, glass)
		part(m, "Mullion", x, y, z + 0.9, 0.5, 7.4, 0.5, trim)
		part(m, "Transom", x, y, z + 0.9, 5.5, 0.5, 0.5, trim)
		part(m, "WindowSill", x, y - 4.3, z + 1, 8, 0.8, 2.5, trim)
		if shutters then
			for _, s in {-1, 1} do
				part(m, "Shutter", x + s * 4.6, y, z + 0.4, 2.2, 8.5, 0.8, shutters)
				part(m, "ShutterStrap", x + s * 4.6, y - 2.3, z + 0.9, 2.2, 0.6, 0.3, dark)
			end
		end
	end
	local function barrel(m, x, y, z)
		cylinder(m, "Barrel", x, y + 2.3, z, 4.6, 3.8, wood, "Y", true)
		for _, h in {0.7, 3.8} do cylinder(m, "BarrelHoop", x, y + h, z, 0.4, 4, metal) end
		cylinder(m, "BarrelLid", x, y + 4.65, z, 0.2, 3.3, oak)
	end
	local function hay(m, x, y, z, width)
		part(m, "HayBale", x, y + 1.5, z, width, 3, 3.5, gold, true)
		for _, s in {-1, 1} do
			part(m, "HayBinding", x + s * width * 0.3, y + 1.5, z + 1.8, 0.35, 3, 0.2, dark)
			part(m, "HayBindingTop", x + s * width * 0.3, y + 3.05, z, 0.35, 0.2, 3.5, dark)
		end
	end
	local function wheel(m, x, y, z, radius)
		cylinder(m, "WheelRim", x, y, z, 0.65, radius * 2, dark, "Z")
		cylinder(m, "WheelInset", x, y, z + 0.36, 0.15, radius * 1.6, oak, "Z")
		for i = 0, 2 do
			part(m, "WheelSpokes", x, y, z + 0.52, radius * 1.8, 0.35, 0.25, cream, false, CFrame.Angles(0, 0, i * math.pi / 3))
		end
		cylinder(m, "WheelHub", x, y, z + 0.7, 0.4, 0.9, metal, "Z")
	end
	local function door(m, x, width, height, z, color, crossed)
		part(m, "DoorFrame", x, height / 2 + 1, z, width + 2, height + 2, 1.2, cream)
		part(m, "Door", x, height / 2 + 1, z + 0.7, width, height, 0.8, color)
		part(m, "DoorSeam", x, height / 2 + 1, z + 1.15, 0.3, height, 0.15, dark)
		if crossed then
			for _, s in {-1, 1} do
				local cx = x + s * width / 4
				beam(m, "DoorX", V(cx - width / 4 + 0.7, 2, z + 1.3), V(cx + width / 4 - 0.7, height, z + 1.3), 0.75, cream)
				beam(m, "DoorX", V(cx + width / 4 - 0.7, 2, z + 1.3), V(cx - width / 4 + 0.7, height, z + 1.3), 0.75, cream)
			end
		end
		part(m, "DoorLatch", x + 1, height * 0.45, z + 1.4, 0.4, 1.3, 0.5, gold)
	end

	-- Garden walls: clipped hedge masses, deep planters, bright carpentry.
	for _, spec in {{"LobbyA", 54}, {"LobbyB", 54}, {"LobbyCorner", 30}} do
		local name, w = spec[1], spec[2]
		local m = model(name, w, "Lobby", 44, green, 4)
		part(m, "HedgeFoot", 0, 2, 3, w, 4, 6, leaf, true)
		for i = 1, 5 do
			local x = -w / 2 + (i - 0.5) * w / 5
			part(m, "ClippedCrown", x, 44, 3, w / 5, 4 + i % 2, 6, i % 2 == 0 and leaf or green)
			part(m, "LeafCluster", x, 9 + i % 3 * 9, 4.3, w / 6, 7, 2, Kit.shade(green, 1 + i % 2 * 0.13))
		end
		part(m, "PicketTopRail", 0, 47, 3, w, 0.9, 1, white)
		for i = 0, math.floor((w - 2) / 4) do
			part(m, "Picket", -w / 2 + 1 + i * 4, 47, 3, 1, 5, 1, white)
		end
		if name == "LobbyA" then
			for _, x in {-13, 13} do
				window(m, x, 25, 4.5, white, oak)
				part(m, "FlowerBox", x, 19, 6.6, 9, 2.6, 3.6, white, true)
				part(m, "Soil", x, 20.35, 6.6, 8, 0.3, 2.8, dark)
				for i = -1, 1 do part(m, "Flowers", x + i * 2.5, 21.2, 6.6, 1.8, 1.5, 1.8, i == 0 and gold or pink) end
			end
			lantern(m, 0, 31, 7)
		elseif name == "LobbyB" then
			door(m, -9, 11, 23, 4.4, oak, true)
			part(m, "GateLintel", -9, 27, 5, 16, 2, 5, white)
			cylinder(m, "RoundWindowFrame", 12, 31, 4.9, 1.5, 10, white, "Z")
			cylinder(m, "RoundWindow", 12, 31, 5.75, 0.4, 8, glass, "Z")
			part(m, "RoundWindowCross", 12, 31, 6.1, 0.6, 8, 0.4, white)
			part(m, "RoundWindowCross", 12, 31, 6.1, 8, 0.6, 0.4, white)
			for i = 1, 7 do part(m, "ClimbingVine", 21 + math.sin(i) * 2, 4 + i * 4, 5.4, 3, 5, 2.4, leaf) end
			part(m, "BirdhousePost", 8, 7, 8, 0.8, 14, 0.8, white)
			part(m, "Birdhouse", 8, 15, 8, 4, 4, 3.5, pink)
			wedge(m, "BirdhouseRoof", 8, 18, 8, 5, 2, 4.5, red)
			cylinder(m, "BirdEntrance", 8, 15.5, 9.85, 0.2, 1.5, dark, "Z")
			part(m, "BirdPerch", 8, 14.3, 10.3, 0.5, 0.5, 1.5, oak)
		else
			lantern(m, 0, 25, 7)
			for i = 1, 12 do part(m, "HedgeTuft", -12 + (i - 1) % 4 * 8, 5 + math.floor((i - 1) / 4) * 8, 5, 5, 4, 3, leaf) end
		end
		finish(m)
	end

	local function barn(name)
		local m = model(name, 48, "Ranch", 47, red, 4)
		for i = 0, 11 do part(m, "PlankBatten", -22 + i * 4, 23, 4.3, 0.45, 46, 0.7, Kit.shade(red, 0.8)) end
		for _, x in {-23, 23} do part(m, "CornerTrim", x, 24, 4.8, 2, 48, 1.5, white) end
		part(m, "RoofDeck", 0, 48, 3, 48, 2, 6, dark, true)
		part(m, "RoofRidge", 0, 50, 2, 47, 2, 2, white)
		for _, x in {-16, 0, 16} do part(m, "RoofSeam", x, 49.2, 4, 0.6, 0.5, 4, metal) end
		return m
	end
	do
		local m = barn("BarnDoors")
		door(m, 0, 28, 25, 4.7, dark, true)
		window(m, 0, 38, 4.8, white, oak)
		part(m, "LoftBeam", 0, 43.5, 7, 1, 1, 6, dark)
		part(m, "HoistRope", 0, 39, 9.5, 0.25, 8, 0.25, cream)
		lantern(m, 19, 26, 7)
		for _, x in {-19, 19} do hay(m, x, 0, 7, 5) end
		finish(m)
	end
	do
		local m = barn("BarnSide")
		door(m, 0, 12, 10, 4.8, dark, true)
		-- Elevated hatch and projecting sill expose the golden hay from above.
		part(m, "LoftFrame", 0, 35, 4.8, 15, 12, 1.5, white)
		part(m, "LoftOpening", 0, 35, 5.7, 12, 9, 0.5, black)
		part(m, "LoftSill", 0, 29, 7, 16, 1, 6, oak)
		hay(m, 0, 29.5, 7.5, 9)
		for _, x in {-8, 8} do part(m, "OpenHatch", x, 35, 6, 3, 10, 2, red) end
		wedge(m, "LeanToRoof", 0, 19, 7.5, 42, 4, 8, dark)
		part(m, "ShedFascia", 0, 17.3, 11, 42, 1.3, 1, white)
		for _, x in {-19, 19} do part(m, "ShedPost", x, 8.5, 10.5, 1.2, 17, 1.2, oak) end
		barrel(m, -14, 0, 7.5)
		barrel(m, -9, 0, 7.5)
		wheel(m, 13, 4, 7, 3.8)
		finish(m)
	end
	do
		local m = model("Silo", 24, "Ranch", 20, red, 2)
		cylinder(m, "SiloBody", 0, 24, 6, 46, 11, rgb(174, 187, 187), "Y", true)
		for _, y in {3, 12, 22, 32, 44} do cylinder(m, "SiloBand", 0, y, 6, 0.65, 11.5, metal) end
		for i = 0, 4 do cylinder(m, "DomedRoofTier", 0, 47 + i * 1.2, 6, 1.4, 11.6 - i * 1.8, red) end
		cylinder(m, "Vent", 0, 53, 6, 2, 1.6, metal)
		cylinder(m, "VentCap", 0, 54.3, 6, 0.6, 2.8, dark)
		for _, x in {-1.4, 1.4} do part(m, "LadderRail", x, 23, 11.6, 0.3, 44, 0.3, dark) end
		for i = 1, 18 do part(m, "LadderRung", 0, i * 2.4, 11.6, 3, 0.3, 0.3, metal) end
		for _, x in {-10, 10} do part(m, "WallPost", x, 10, 2.5, 1, 20, 1, white) end
		part(m, "WallCap", 0, 20, 2, 24, 1, 3, white)
		part(m, "GrainChute", 7.8, 4, 5, 4, 3, 3, metal, true)
		barrel(m, -8.5, 0, 6)
		finish(m)
	end
	do
		local m = model("Fence", 48, "Ranch", 56, rgb(153, 205, 111), 1)
		part(m, "LowFieldWall", 0, 10, 2, 48, 20, 2, rgb(114, 180, 80), true)
		for i = 0, 6 do part(m, "FencePost", -22 + i * 7.3, 8, 4, 1.4, 16, 1.4, white) end
		for _, y in {5, 12} do part(m, "FenceRail", 0, y, 4, 48, 1.5, 1.4, oak) end
		part(m, "CartBed", -8, 4, 8, 13, 1, 5, dark, true)
		for _, z in {5.7, 10.3} do part(m, "CartSide", -8, 6, z, 13, 3, 0.6, oak) end
		for _, x in {-13, -3} do wheel(m, x, 3, 10.7, 2.3) end
		hay(m, -10, 6, 8, 5)
		hay(m, -4, 6, 8, 5)
		part(m, "CartTongue", 1, 3, 8, 6, 0.7, 0.7, wood)
		part(m, "PumpPlinth", 16, 0.6, 7, 7, 1.2, 7, metal, true)
		cylinder(m, "PumpBody", 16, 4.5, 7, 7, 1.8, green)
		part(m, "PumpSpout", 14.5, 6, 7, 3, 0.8, 0.8, metal)
		part(m, "SpoutMouth", 13.3, 5.4, 7, 0.8, 1.4, 0.8, metal)
		beam(m, "PumpHandle", V(16, 8, 7), V(20, 6, 7), 0.6, dark)
		part(m, "WaterBasin", 12, 1.6, 7, 3, 2, 3, oak)
		part(m, "BasinWater", 12, 2.65, 7, 2.5, 0.15, 2.5, glass)
		finish(m)
	end

	-- Common boardwalk structure; substantial four-stud shells cast deep shadows.
	local function shop(name, w, h, color, title)
		local m = model(name, w, "Western", h - 3, color, 4)
		part(m, "Foundation", 0, 0.6, 5.5, w, 1.2, 11, dark, true)
		part(m, "Boardwalk", 0, 1.5, 7.5, w, 0.6, 8, oak, true)
		for i = 1, 6 do part(m, "BoardwalkJoint", -w / 2 + i * w / 7, 1.83, 7.5, 0.16, 0.08, 7.8, dark) end
		for i = 1, 5 do part(m, "Siding", 0, 5 + i * 5, 4.15, w - 2, 0.35, 0.5, Kit.shade(color, 0.8)) end
		for _, x in {-w / 2 + 1, w / 2 - 1} do
			part(m, "CornerPillar", x, (h - 3) / 2, 4.5, 1.8, h - 3, 1.5, cream)
			part(m, "PorchPost", x, 10, 10.2, 1.2, 17, 1.2, cream)
			beam(m, "PorchKneeBrace", V(x, 14, 10.2), V(x + (x < 0 and 3 or -3), 18, 10.2), 0.7, oak)
		end
		wedge(m, "PorchRoof", 0, 20, 7.5, w, 3, 8, dark)
		part(m, "PorchFascia", 0, 18.8, 11.3, w, 1.3, 0.8, oak)
		part(m, "RoofDeck", 0, h - 4, 2.5, w, 1.2, 5, dark, true)
		part(m, "FalseFront", 0, h - 5, 4.5, w - 1, 8, 1.5, color)
		part(m, "Cornice", 0, h - 0.7, 4.5, w, 1.4, 3, cream)
		for _, x in {-w * 0.3, 0, w * 0.3} do part(m, "CorniceCorbel", x, h - 2.2, 5.3, 1.5, 2, 2, oak) end
		for _, x in {-w * 0.25, w * 0.25} do part(m, "RoofSeam", x, h - 3.3, 2, 0.6, 0.25, 3.5, metal) end
		sign(m, title, w - 7, h - 6, dark)
		return m
	end
	local shops = {
		{"WestBank", 36, 49, rgb(146, 158, 169), "BANK"},
		{"WestHotel", 44, 56, rgb(54, 145, 143), "HOTEL"},
		{"WestStore", 40, 46, rgb(206, 151, 64), "GENERAL STORE"},
		{"WestJail", 32, 42, rgb(128, 139, 157), "JAIL"},
		{"WestSheriff", 32, 48, rgb(193, 99, 50), "SHERIFF"},
		{"WestBlacksmith", 40, 44, rgb(106, 119, 128), "BLACKSMITH"},
		{"WestBarber", 28, 40, rgb(212, 96, 87), "BARBER"},
		{"WestStables", 44, 50, rgb(157, 106, 62), "STABLES"},
	}
	for _, spec in shops do
		local name, w, h = spec[1], spec[2], spec[3]
		local m = shop(name, w, h, spec[4], spec[5])
		if name == "WestBlacksmith" then
			-- The shallow back wall stays intact; the open bay projects in front of it.
			part(m, "OpenBayShadow", 0, 10, 4.35, 29, 16, 0.4, black)
			part(m, "ForgeHearth", -10, 3.5, 7.2, 7, 4, 5, red, true)
			part(m, "ForgeCoals", -10, 5.6, 7.2, 5, 0.4, 3, gold)
			part(m, "ForgeHood", -10, 10, 6, 8, 3, 4, metal)
			part(m, "Chimney", -10, 28, 2.4, 5, 40, 4.5, red, true)
			part(m, "ChimneyCap", -10, 48, 2.5, 6, 1, 5, dark)
			for i = 1, 3 do part(m, "SmokeBlock", -10 + i * 0.7, 48 + i * 2, 3, 2 + i * 0.4, 1.8, 2.5, rgb(174 + i * 14, 181 + i * 12, 185 + i * 10)) end
			part(m, "AnvilStump", 4, 3.4, 8, 4, 3.2, 4, wood, true)
			part(m, "AnvilFoot", 4, 5.3, 8, 4, 0.8, 3, metal)
			part(m, "AnvilWaist", 4, 6.3, 8, 2.3, 1.5, 2, metal)
			part(m, "AnvilFace", 4, 7.3, 8, 5, 0.8, 2.8, black)
			wedge(m, "AnvilHorn", 7, 7, 8, 1.5, 1.2, 2.8, metal)
			barrel(m, 14, 1.8, 7.5)
		elseif name == "WestStables" then
			door(m, 0, 27, 16, 4.7, dark, true)
			window(m, 0, 31, 4.8, cream, red)
			hay(m, -16, 1.8, 8, 7)
			hay(m, 16, 1.8, 8, 7)
			part(m, "HitchingRail", 0, 5.5, 10.8, 21, 0.8, 0.8, oak)
			for _, x in {-9, 9} do part(m, "HitchingPost", x, 3.8, 10.8, 0.8, 4, 0.8, dark) end
		else
			door(m, 0, 6, 13, 4.6, dark, false)
			for _, x in {-w * 0.29, w * 0.29} do window(m, x, 10, 4.7, cream, name ~= "WestJail" and red or nil) end
			if name == "WestBank" then
				for _, x in {-6, 6} do
					cylinder(m, "StoneColumn", x, 10, 9, 16, 2, cream)
					for _, y in {2, 18} do part(m, "ColumnCapital", x, y, 9, 3.4, 1.3, 3.4, white) end
				end
				part(m, "BankPediment", 0, 33, 5, 26, 2, 2.5, cream)
			elseif name == "WestHotel" then
				part(m, "BalconyFloor", 0, 22, 7.5, w - 2, 1, 8, oak, true)
				for _, x in {-13, 13} do window(m, x, 31, 4.7, cream, nil) end
				part(m, "BalconyDoor", 0, 29, 4.8, 6, 13, 1, dark)
				part(m, "BalconyRail", 0, 27, 11, w - 2, 0.8, 0.8, cream)
				for i = -5, 5 do part(m, "Baluster", i * 3.8, 24.5, 11, 0.5, 4.5, 0.5, cream) end
				for _, x in {-20, 20} do part(m, "BalconySideRail", x, 27, 7.8, 0.8, 0.8, 6.4, cream) end
			elseif name == "WestStore" then
				for _, x in {-15, 15} do barrel(m, x, 1.8, 8) end
				part(m, "Crate", 9, 3.6, 8, 4, 3.6, 4, oak, true)
				beam(m, "CrateBrace", V(7.2, 2, 10.1), V(10.8, 5.2, 10.1), 0.5, cream)
				part(m, "CrateLid", 9, 5.5, 8, 4.2, 0.4, 4.2, wood)
			elseif name == "WestJail" then
				for _, x in {-w * 0.29, w * 0.29} do
					for i = -2, 2 do part(m, "WindowBar", x + i, 10, 5.9, 0.3, 7.5, 0.5, black) end
				end
				lantern(m, 0, 27, 7)
			elseif name == "WestSheriff" then
				-- Five radial arms give the raised badge a star silhouette.
				for i = 0, 4 do
					local a = i * 2 * math.pi / 5
					part(m, "BadgeStar", math.sin(a) * 1.5, 31 + math.cos(a) * 1.5, 6, 1.1, 3.6, 1.1, gold, false, CFrame.Angles(0, 0, -a))
				end
				-- A star on the sign as well as the large carved badge below it.
				local plate = m:FindFirstChild("SignPlate")
				plate:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel").Text = "★ SHERIFF ★"
				lantern(m, 0, 22, 7)
			elseif name == "WestBarber" then
				for i = 0, 7 do cylinder(m, "BarberPoleStripe", 9.5, 3 + i * 1.2, 9, 1.2, 1.8, i % 2 == 0 and red or white) end
				for _, y in {2, 12.2} do cylinder(m, "PoleCap", 9.5, y, 9, 0.8, 2.4, gold) end
			end
		end
		finish(m)
	end

	do
		local m = model("EndWall", 120, "Blocker", 56, dark, 4)
		for i = 0, 23 do
			local x = -57.5 + i * 5
			part(m, "BarricadeTimber", x, 27, 4.6, 4.6, 54, 1.6, i % 2 == 0 and oak or wood)
		end
		for _, y in {8, 26, 48} do part(m, "CrossRail", 0, y, 6, 120, 2.5, 2, dark) end
		for _, x in {-48, -24, 0, 24, 48} do
			beam(m, "DiagonalBrace", V(x - 10, 3, 7.3), V(x + 10, 24, 7.3), 1.3, cream)
			part(m, "Buttress", x, 10, 8, 3, 20, 6, wood, true)
		end
		local plate = sign(m, "", 76, 37, red)
		plate:SetAttribute("MapTextTarget", true)
		part(m, "BarricadeCap", 0, 55, 4, 120, 2, 6, oak)
		finish(m)
	end

	local lines = { "Built ReplicatedStorage.Assets.Facades: 16 modules, " .. total .. " parts (including roots)." }
	for _, theme in {"Lobby", "Ranch", "Western", "Blocker"} do
		table.insert(lines, theme .. ": " .. table.concat(counts[theme], ", "))
	end
	local summary = table.concat(lines, "\n")
	print(summary) -- Exactly five lines; callers also receive the same summary.
	return summary
end
