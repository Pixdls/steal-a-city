--!nonstrict
-- Edit-time facade masters. Ground/back-plane origin; street faces +Z.
-- Run AFTER BuildAssets, which replaces Assets. All dimensions are studs.
return function(Kit)
	Kit.ensureStuds()
	local storage = game:GetService("ReplicatedStorage")
	local assets = storage:FindFirstChild("Assets") or Kit.folder("Assets", storage)
	local old = assets:FindFirstChild("Facades")
	if old then old:Destroy() end
	local facades = Kit.folder("Facades", assets)
	local V, C = Kit.V, Kit.C
	local counts = { Lobby = {}, Ranch = {}, Western = {}, Transition = {}, Blocker = {} }
	local total, modules = 0, 0

	local function part(m, name, x, y, z, sx, sy, sz, color, solid)
		local make = solid and Kit.part or Kit.decor
		return make(m, name, V(sx, sy, sz), V(x, y, z), color)
	end
	local function model(name, width, theme, height, color, depth)
		local m = Kit.model(name, facades)
		m:SetAttribute("Width", width)
		m:SetAttribute("Theme", theme)
		m:SetAttribute("Footprint", V(width, height, depth or 12))
		m.PrimaryPart = Kit.marker(m, "Root", V(1, 1, 1), V(0, 0, 0))
		part(m, "BackWall", 0, height / 2, 0.75, width, height, 1.5, color, true)
		return m
	end
	local function sign(m, text, width, y, color, name, z)
		z = z or 2.1
		-- Four edge bars, never a plate hidden behind another plate.
		local plate = part(m, name or "SignPlate", 0, y, z, width, 4, 0.6, color)
		for _, s in {-1, 1} do
			part(m, "SignUpright", s * (width / 2 + 0.4), y, z + 0.1, 0.8, 4, 0.8, C.Cream)
			part(m, "SignBorder", 0, y + s * 2.4, z + 0.1, width + 1.6, 0.8, 0.8, C.Cream)
		end
		Kit.label(plate, Enum.NormalId.Back, text, C.Charcoal, 20)
		return plate
	end
	local function lantern(m, x, y, z, backing)
		backing = backing or 1.5
		-- Bracket touches the wall and the hanger; caps butt against the glow.
		part(m, "LanternBracket", x, y + 2.6, (backing + z) / 2, 0.4, 0.4, z - backing, C.WoodDark)
		part(m, "LanternHanger", x, y + 1.95, z, 0.4, 0.9, 0.4, C.Charcoal)
		Kit.lamp(m, "LanternGlow", V(1.6, 2.2, 1.6), V(x, y, z))
		for _, s in {-1, 1} do
			part(m, "LanternCap", x, y + s * 1.3, z, 2, 0.4, 2, C.Charcoal)
		end
	end
	local function window(m, x, floor, shutters)
		-- Clear opening: 6 x 8; bottom/sill at floor + 3. Front frame is .6 proud.
		local y = floor + 7
		part(m, "WindowGlass", x, y, 1.7, 6, 8, 0.4, C.Sky)
		for _, s in {-1, 1} do
			part(m, "WindowJamb", x + s * 3.3, y, 2, 0.6, 8, 1, C.Cream)
			-- Ground-floor headers merge into the matching porch roof.
			local trim = floor == 0.6 and s == 1 and C.WoodDark or C.Cream
			part(m, "WindowHeaderSill", x, y + s * 4.3, 2, 7.2, 0.6, 1, trim)
		end
		-- Mullions start at the glass front; their intersections share one colour.
		part(m, "WindowMullion", x, y, 2.2, 0.4, 8, 0.6, C.Cream)
		part(m, "WindowTransom", x, y, 2.2, 6, 0.4, 0.6, C.Cream)
		if shutters then
			for _, s in {-1, 1} do
				local xx = x + s * 4.85
				part(m, "WindowShutter", xx, y, 1.9, 2.5, 8, 0.8, shutters)
				for _, dy in {-2.6, 2.6} do
					part(m, "ShutterStrap", xx, y + dy, 2.5, 2.5, 0.5, 0.4, C.WoodDark)
				end
			end
		end
	end
	local function door(m, x, floor, color, prefix)
		prefix = prefix or "Door"
		part(m, prefix, x, floor + 4, 1.9, 5, 8, 0.8, color)
		for _, s in {-1, 1} do
			part(m, prefix .. "Jamb", x + s * 2.9, floor + 4, 2.1, 0.8, 8, 1.2, C.Cream)
		end
		part(m, prefix .. "Lintel", x, floor + 8.4, 2.1, 6.6, 0.8, 1.2, C.Cream)
		for _, dx in {-1.25, 0, 1.25} do
			part(m, prefix .. "PlankJoint", x + dx, floor + 4, 2.4, 0.12, 7.6, 0.2, C.WoodDark)
		end
		part(m, prefix .. "Latch", x + 1.8, floor + 3.8, 2.6, 0.4, 0.8, 0.6, C.Gold)
	end
	local function hay(m, x, floor, z, width, depth)
		part(m, "HayBale", x, floor + 1.5, z, width, 3, depth, C.Gold)
		for _, s in {-1, 1} do
			part(m, "HayBinding", x + s * width * 0.3, floor + 1.5, z + depth / 2 + 0.1,
				0.25, 3, 0.2, C.WoodDark)
			part(m, "HayBindingTop", x + s * width * 0.3, floor + 3.1, z,
				0.25, 0.2, depth, C.WoodDark)
		end
	end
	local function barrel(m, x, floor, z)
		-- Segmented cylinder: hoops replace sections of the barrel, never intersect it.
		local heights = {0.5, 0.4, 2.2, 0.4, 0.5}
		local y = floor
		for i, h in heights do
			local band = i == 2 or i == 4
			local p = Kit.decor(m, band and "BarrelHoop" or "BarrelStaves", V(h, 3, 3),
				CFrame.new(x, y + h / 2, z) * CFrame.Angles(0, 0, math.pi / 2), band and C.Charcoal or C.Wood)
			p.Shape = Enum.PartType.Cylinder
			y += h
		end
	end
	local function wheel(m, x, y, z)
		local rim = Kit.decor(m, "CartWheelRim", V(0.4, 2.6, 2.6),
			CFrame.new(x, y, z) * CFrame.Angles(0, math.pi / 2, 0), C.WoodDark)
		rim.Shape = Enum.PartType.Cylinder
		part(m, "CartWheelSpoke", x, y, z + 0.35, 2.1, 0.4, 0.3, C.Wood)
		part(m, "CartWheelSpoke", x, y, z + 0.35, 0.4, 2.1, 0.3, C.Wood)
		part(m, "CartWheelHub", x, y, z + 0.65, 0.7, 0.7, 0.3, C.Slate)
	end
	local function leaf(m, name, x, y, z, sx, sy, sz, color)
		local p = part(m, name, x, y, z, sx, sy, sz, color or C.Leaf)
		p.CastShadow = false
		return p
	end
	local function porch(m, w)
		-- Ten deep: z=1.5..11.5. Deck top is the storey's floor datum (.6).
		local planks = math.floor(w / 2)
		for i = 1, planks do
			part(m, "BoardwalkPlank", -w / 2 + (i - 0.5) * w / planks, 0.3, 6.5,
				w / planks - 0.08, 0.6, 10, C.Wood, true)
		end
		for _, s in {-1, 1} do
			local x = s * (w / 2 - 1)
			part(m, "PorchPost", x, 6.1, 10.7, 1, 11, 1, C.Cream, true)
			-- Chunky stepped knee brackets meet, rather than pierce, the posts.
			part(m, "PorchBrace", x - s * 1.25, 10.8, 10.7, 1.5, 1.6, 0.8, C.Wood)
			part(m, "PorchBraceTip", x - s * 2.5, 11.2, 10.7, 1, 0.8, 0.8, C.Wood)
		end
		part(m, "PorchRoof", 0, 12, 6.5, w, 0.8, 10, C.WoodDark, true)
		part(m, "PorchFascia", 0, 12, 11.7, w, 0.8, 0.4, C.Cream)
	end
	local function cornice(m, w, height)
		part(m, "Cornice", 0, height - 0.6, 2.5, w, 1.2, 2, C.Cream)
		part(m, "CorniceShadow", 0, height - 1.6, 2, w - 2, 0.8, 1, C.WoodDark)
	end

	-- Hedge fronts are at most six deep, including flowers and lantern caps.
	for _, spec in {{"LobbyA", 54}, {"LobbyB", 54}, {"LobbyCorner", 30}} do
		local name, w = spec[1], spec[2]
		local m = model(name, w, "Lobby", 48, C.GrassDark, 6)
		part(m, "HedgeBody", 0, 22, 2.25, w, 44, 1.5, C.GrassDark, true)
		part(m, "HedgeTopBand", 0, 46, 2.25, w, 4, 1.5, C.Grass)
		-- Leaf tufts lie in a reserved high band, clear of all carpentry.
		for i = 1, math.floor(w / 7) do
			leaf(m, "LeafCluster", -w / 2 + 3.5 + (i - 1) * 7, 38 + i % 2,
				3.7, 5, 4, 1.4)
		end
		for _, side in {-1, 1} do
			leaf(m, "HedgeFootCluster", side * (w / 2 - 4), 2, 4.1, 6, 4, 2.2)
			leaf(m, "HedgeFootCrown", side * (w / 2 - 4), 4.6, 4.1, 4, 1.2, 1.8)
		end
		-- Window/door assemblies use the same dimensions but mount on the hedge face.
		local before = #m:GetChildren()
		if name == "LobbyA" then
			for _, x in {-13, 13} do window(m, x, 14, C.Wood) end
		elseif name == "LobbyB" then
			door(m, -9, 0, C.Wood)
			window(m, 12, 14, C.Wood)
		else
			window(m, 0, 14)
		end
		local children = m:GetChildren()
		for i = before + 1, #children do
			if children[i]:IsA("BasePart") then children[i].CFrame += V(0, 0, 1.5) end
		end
		if name == "LobbyA" then
			for _, x in {-13, 13} do
				part(m, "FlowerBox", x, 15.5, 4.2, 8, 1.2, 2.4, C.Cream)
				for i = -1, 1 do
					leaf(m, "FlowerLeaves", x + i * 2.4, 16.5, 4.9, 1.6, 0.8, 1.6)
					leaf(m, "FlowerBloom", x + i * 2.4, 17.15, 4.9, 1.2, 0.5, 1.2, C.Pink)
				end
			end
		end
		sign(m, name == "LobbyB" and "GARDEN SHED" or "CITY GARDENS", math.min(w - 8, 22), 31, C.Sand, nil, 3.5)
		lantern(m, name == "LobbyCorner" and 10 or -w / 2 + 4, 10, 4.8, 3)
	end

	local function barn(name)
		local m = model(name, 48, "Ranch", 48, C.BarnRed)
		for i = 0, 11 do
			part(m, "PlankBatten", -22 + i * 4, 33, 1.7, 0.4, 5, 0.4, C.BarnRed)
		end
		for _, x in {-23, 23} do part(m, "CornerTrim", x, 22.5, 2.2, 2, 45, 0.6, C.Cream) end
		cornice(m, 48, 48)
		return m
	end
	do
		local m = barn("BarnDoors")
		door(m, -3.3, 0, C.Wood, "LeftDoor")
		door(m, 3.3, 0, C.Wood, "RightDoor")
		window(m, 0, 14, C.Wood)
		sign(m, "RANCH", 24, 39, C.Sand)
		for _, x in {-16, 16} do hay(m, x, 0, 5.5, 6, 3.5) end
		lantern(m, -17, 17, 4)
		lantern(m, 17, 17, 4)
		part(m, "HoistBeam", 0, 29, 4.5, 1, 1, 6, C.WoodDark)
		part(m, "HoistRope", 0, 25, 7, 0.2, 7, 0.2, C.Cream)
	end
	do
		local m = barn("BarnSide")
		porch(m, 44)
		door(m, 0, 0.6, C.Wood)
		window(m, 0, 14, C.Wood)
		sign(m, "HAY & GRAIN", 28, 39, C.Sand)
		for _, x in {-15, -10} do barrel(m, x, 0.6, 6.5) end
		hay(m, 13, 0.6, 6.5, 8, 3.5)
		lantern(m, -17, 18, 4)
	end
	do
		local m = model("Silo", 24, "Ranch", 48, C.Slate)
		-- Block-built silo relief; horizontal courses butt, with bands replacing slices.
		for i = 0, 5 do
			part(m, "SiloCourse", 0, i * 7 + 3.1, 4.75, 12, 6.2, 6.5, C.Slate, true)
			part(m, "SiloBand", 0, i * 7 + 6.6, 4.75, 12, 0.8, 6.5, C.Charcoal)
		end
		for i = 0, 2 do
			part(m, "SiloRoofTier", 0, 42.75 + i * 1.5, 4.75, 13 - i * 3, 1.5, 6.5 - i, C.BarnRed)
		end
		part(m, "Vent", 0, 47, 4.75, 1.6, 1, 1.6, C.Slate)
		part(m, "VentCap", 0, 47.75, 4.75, 2.4, 0.5, 2.4, C.Charcoal)
		for _, x in {-1.4, 1.4} do part(m, "LadderRail", x, 21, 8.4, 0.4, 42, 0.8, C.WoodDark) end
		for i = 1, 20 do part(m, "LadderRung", 0, i * 2, 8.6, 2.4, 0.4, 0.4, C.Slate) end
		for _, x in {-9, 9} do lantern(m, x, 17, 4) end
		sign(m, "GRAIN", 5, 32, C.Sand, nil, 9.4)
	end
	do
		local m = model("Fence", 48, "Ranch", 42, C.GrassDark)
		m:SetAttribute("Footprint", V(48, 48, 12))
		-- Three 14-high terraces: each ledge steps back 2.5, with no nested volumes.
		for i, color in {C.GrassDark, C.Grass, C.Leaf} do
			local front = 8.5 - (i - 1) * 2.5
			part(m, "HillTerrace" .. i, 0, (i - 0.5) * 14, (1.5 + front) / 2,
				48, 14, front - 1.5, color, true)
		end
		for _, x in {-14, 14} do
			leaf(m, "HillBush", x, 43.5, 2.5, 6, 3, 2)
			leaf(m, "HillBushCrown", x, 45.5, 2.5, 4, 1, 1.6)
		end
		part(m, "HillTreeTrunk", 0, 44, 2.5, 1.2, 4, 1.2, C.Wood)
		leaf(m, "HillTreeCrown", 0, 47, 2.5, 6, 2, 2)
		leaf(m, "HillTreeBranchLeaves", -2.1, 45.3, 2.5, 2.6, 1.4, 1.8)
		local posts = {-20, -10, 0, 10, 20}
		for _, x in posts do part(m, "FencePost", x, 2.5, 9.2, 1.4, 5, 1.4, C.Cream, true) end
		for i = 1, #posts - 1 do
			for _, y in {1.5, 3.8} do
				part(m, "FenceRail", (posts[i] + posts[i + 1]) / 2, y, 9.2, 8.6, 0.9, 0.8, C.Wood)
			end
		end
		part(m, "CartBed", -8, 2.9, 10.9, 12, 0.6, 2, C.WoodDark)
		for _, x in {-13, -3} do wheel(m, x, 1.3, 11.1) end
		part(m, "CartSide", -8, 4, 11.9, 12, 1.6, 0.2, C.Wood)
		for _, x in {-11, -5} do hay(m, x, 3.2, 10.7, 5, 1.6) end
		part(m, "CartTongue", 1, 2.9, 10.9, 6, 0.6, 0.6, C.WoodDark)
		sign(m, "RANCH TRAIL", 18, 20, C.Sand, nil, 6.5)
		lantern(m, 18, 10, 10.5, 8.5)
	end

	local shops = {
		{"WestBank", 36, 46, C.Lilac, "BANK"},
		{"WestHotel", 44, 48, C.Teal, "HOTEL"},
		{"WestStore", 40, 44, C.Sand, "GENERAL STORE"},
		{"WestJail", 32, 42, C.Purple, "JAIL"},
		{"WestSheriff", 32, 46, C.Orange, "SHERIFF"},
		{"WestBlacksmith", 40, 44, C.Wood, "BLACKSMITH"},
		{"WestBarber", 28, 40, C.Pink, "BARBER"},
		{"WestStables", 44, 48, C.BarnRed, "STABLES"},
	}
	for _, spec in shops do
		local name, w, h, accent, title = table.unpack(spec)
		local m = model(name, w, "Western", h, accent)
		porch(m, w)
		cornice(m, w, h)
		-- Storey bands and high battens live outside the window/sign rectangles.
		for _, y in {14, 28.8} do part(m, "StoreyBand", 0, y, 1.9, w, 0.8, 0.8, C.WoodDark) end
		for _, s in {-1, 1} do
			part(m, "UpperCornerTrim", s * (w / 2 - 0.5), 20.7, 2, 1, 11.8, 1, C.Cream)
			part(m, "FalseFrontBatten", s * (w / 2 - 1), h - 8, 1.8, 0.6, 9, 0.6, C.WoodDark)
		end
		sign(m, title, w - 8, h - 7, C.WoodDark)
		if name == "WestStables" then
			door(m, -3.3, 0.6, C.Wood, "StableLeftDoor")
			door(m, 3.3, 0.6, C.Wood, "StableRightDoor")
			for _, x in {-16, 16} do hay(m, x, 0.6, 6, 6, 3) end
		else
			door(m, 0, 0.6, C.Wood)
			for _, x in {-w * 0.29, w * 0.29} do window(m, x, 0.6) end
		end
		for _, x in {-w * 0.25, w * 0.25} do window(m, x, 14.6) end
		lantern(m, 0, 18, 4.5)
		if name == "WestHotel" then
			part(m, "BalconyFloor", 0, 14.3, 7, w - 4, 0.6, 7, C.Wood, true)
			part(m, "BalconyRail", 0, 17.3, 10.2, w - 4, 0.6, 0.6, C.Cream)
			for i = 0, 9 do
				part(m, "Baluster", -(w - 5) / 2 + i * (w - 5) / 9, 15.8, 10.2, 0.5, 2.4, 0.5, C.Cream)
			end
		elseif name == "WestBank" then
			for _, x in {-5, 5} do
				part(m, "ColumnBase", x, 1.1, 7.5, 2, 1, 2, C.Cream)
				part(m, "StoneColumn", x, 6.1, 7.5, 1.4, 9, 1.4, C.Cream)
				part(m, "ColumnCapital", x, 11.1, 7.5, 2.4, 1, 2.4, C.Cream)
			end
		elseif name == "WestJail" then
			for _, x in {-w * 0.29, w * 0.29} do
				for i = -2, 2 do part(m, "WindowBar", x + i, 7.6, 2.75, 0.3, 8, 0.5, C.Charcoal) end
			end
		elseif name == "WestSheriff" then
			part(m, "BadgeVertical", 0, 25.5, 2.2, 1, 4, 0.8, C.Gold)
			part(m, "BadgeHorizontal", 0, 25.5, 2.2, 4, 1, 0.8, C.Gold)
		elseif name == "WestBarber" then
			for i = 0, 7 do
				part(m, "BarberPoleStripe", 8, 1.1 + i, 7, 1.4, 1, 1.4, i % 2 == 0 and accent or C.Cream)
			end
			part(m, "BarberPoleCap", 8, 8.9, 7, 2, 0.6, 2, C.Charcoal)
		elseif name == "WestStore" then
			barrel(m, -13, 0.6, 6)
			part(m, "Crate", 11, 2.1, 6, 3, 3, 3, C.Wood)
			part(m, "CrateLid", 11, 3.9, 6, 3.4, 0.6, 3.4, C.WoodDark)
		elseif name == "WestBlacksmith" then
			part(m, "ForgeHearth", -12, 2.1, 6, 6, 3, 4, C.Slate, true)
			part(m, "ForgeCoals", -12, 3.8, 6, 4, 0.4, 3, C.Gold)
			part(m, "ForgeFlue", -12, 7.8, 4.4, 2, 7.6, 0.8, C.Charcoal)
			part(m, "AnvilStump", 8, 1.85, 6, 3, 2.5, 3, C.Wood)
			part(m, "AnvilFoot", 8, 3.4, 6, 3, 0.6, 2.5, C.Slate)
			part(m, "AnvilWaist", 8, 4.1, 6, 1.8, 0.8, 1.8, C.Slate)
			part(m, "AnvilFace", 8, 4.9, 6, 5, 0.8, 2.5, C.Slate)
		end
	end

	do
		local m = model("TransitionJog", 10, "Transition", 48, C.Slate)
		for i = 0, 11 do
			local split = i % 2 == 0 and -1 or 1
			for _, span in {{-3.5, split - 0.15}, {split + 0.15, 3.5}} do
				part(m, "RetainingStone", (span[1] + span[2]) / 2, 1.85 + i * 3.8, 2.4,
					span[2] - span[1], 3.4, 1.8, C.Slate, true)
			end
		end
		for _, x in {-4.25, 4.25} do part(m, "RetainingPost", x, 23.4, 2.4, 1.5, 46.8, 1.8, C.WoodDark, true) end
		part(m, "RetainingCap", 0, 47.4, 2.4, 10, 1.2, 1.8, C.Wood, true)
		sign(m, "TOWN →", 6, 30, C.Sand, nil, 3.7)
	end
	do
		local m = model("EndWall", 120, "Blocker", 48, C.WoodDark)
		for i = 0, 23 do
			part(m, "BarricadeTimber", -57.5 + i * 5, 23, 2.1, 4.6, 46, 1.2, C.Wood)
		end
		for _, y in {12, 28, 44} do part(m, "CrossRail", 0, y, 3.2, 120, 1.2, 1, C.WoodDark) end
		part(m, "BarricadeCap", 0, 47, 2.1, 120, 2, 1.2, C.Sand)
		-- Gate sits on its own forward layer, with two standard five-by-eight leaves.
		local before = #m:GetChildren()
		door(m, -3.3, 0, C.Wood, "GateLeftDoor")
		door(m, 3.3, 0, C.Wood, "GateRightDoor")
		local children = m:GetChildren()
		for i = before + 1, #children do
			if children[i]:IsA("BasePart") then children[i].CFrame += V(0, 0, 1.2) end
		end
		for _, x in {-12, 12} do lantern(m, x, 8, 5, 2.7) end
		local plate = sign(m, "SIZE", 42, 36, C.Sand, "Sign", 3.3)
		plate:SetAttribute("MapTextTarget", true)
	end

	-- Counts are calculated from the completed masters, including invisible roots.
	for _, m in facades:GetChildren() do
		local n = 0
		for _, p in m:GetDescendants() do if p:IsA("BasePart") then n += 1 end end
		m:SetAttribute("PartCount", n)
		total += n
		modules += 1
		table.insert(counts[m:GetAttribute("Theme")], m.Name .. "=" .. n)
	end
	local lines = {"Built ReplicatedStorage.Assets.Facades: " .. modules .. " modules, " .. total .. " parts (including roots)."}
	for _, theme in {"Lobby", "Ranch", "Western", "Transition", "Blocker"} do
		table.insert(lines, theme .. ": " .. table.concat(counts[theme], ", "))
	end
	local summary = table.concat(lines, "\n")
	print(summary)
	return summary
end
