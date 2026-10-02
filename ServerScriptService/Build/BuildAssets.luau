--!nonstrict
-- Edit-time templates only. Front is -Z; all static pivots are ground-centred.
return function(Kit)
	Kit.ensureStuds()
	local storage = game:GetService("ReplicatedStorage")
	local previous = storage:FindFirstChild("Assets")
	if previous then previous:Destroy() end
	local assets = Kit.folder("Assets", storage)
	local objects = Kit.folder("Objects", assets)
	local safes = Kit.folder("Safes", assets)
	local props = Kit.folder("Props", assets)
	local chasers = Kit.folder("Chasers", assets)
	local V, rgb = Kit.V, Kit.rgb
	local wood, lightWood, darkWood = rgb(159, 83, 32), rgb(218, 146, 62), rgb(83, 43, 27)
	local metal, black, cream = rgb(87, 107, 121), rgb(29, 29, 38), rgb(255, 238, 190)
	local gold, red, blue = rgb(255, 191, 36), rgb(211, 43, 43), rgb(45, 157, 230)
	local white, pink, green = rgb(255, 250, 225), rgb(255, 116, 171), rgb(49, 174, 64)
	local summaries = {}

	local function block(m, name, x, y, z, sx, sy, sz, color, rotation)
		return Kit.part(m, name, V(sx, sy, sz), CFrame.new(x, y, z) * (rotation or CFrame.identity), color)
	end
	local function marker(m, name, position, size)
		return Kit.part(m, name, size or V(0.1, 0.1, 0.1), position, white, {
			Transparency = 1, CanCollide = false, CanTouch = false, CanQuery = false, CastShadow = false,
		})
	end
	local function template(parent, id, size)
		local m = Kit.model(id, parent)
		m:SetAttribute("ObjectId", id)
		m:SetAttribute("Footprint", size)
		m.PrimaryPart = marker(m, "Root", V(0, 0, 0))
		return m
	end
	local function cylinder(m, name, x, y, z, length, diameter, color, upright)
		local p = block(m, name, x, y, z, length, diameter, diameter, color,
			upright and CFrame.Angles(0, 0, math.pi / 2) or nil)
		p.Shape = Enum.PartType.Cylinder -- cylinder axis is local X
		return p
	end
	local function beam(m, name, a, b, thickness, color)
		return Kit.part(m, name, V(thickness, thickness, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), color)
	end
	local function wedge(m, name, position, size, color, rotation)
		local p = Instance.new("WedgePart")
		p.Name, p.Size = name, size
		p.CFrame = CFrame.new(position) * (rotation or CFrame.identity)
		p.Anchored, p.Material, p.MaterialVariant = true, Enum.Material.Plastic, "Studs"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Color, p.Parent = color, m
		return p
	end
	local function finish(m)
		local count = 0
		for _, item in m:GetDescendants() do
			if item:IsA("BasePart") then count += 1 end
		end
		m:SetAttribute("PartCount", count)
		table.insert(summaries, m.Name .. "=" .. count)
	end
	local function wheels(m, halfWidth, frontZ, rearZ, radius)
		for _, x in {-halfWidth, halfWidth} do
			for _, z in {frontZ, rearZ} do
				cylinder(m, "Tire", x, radius, z, 0.5, radius * 2, darkWood)
				local outside = x + (x < 0 and -0.27 or 0.27)
				cylinder(m, "WoodWheel", outside, radius, z, 0.08, radius * 1.63, lightWood)
				block(m, "Spoke", outside, radius, z, 0.12, radius * 1.55, 0.19, cream)
				block(m, "Spoke", outside, radius, z, 0.12, 0.19, radius * 1.55, cream)
				cylinder(m, "Hub", outside, radius, z, 0.22, 0.48, metal)
			end
		end
	end

	do
		local m = template(objects, "Bucket", V(2, 2, 2))
		block(m, "Bottom", 0, 0.15, 0, 1.7, 0.3, 1.7, darkWood)
		for _, x in {-0.78, 0.78} do block(m, "SideStave", x, 0.72, 0, 0.22, 1.3, 1.7, wood) end
		for _, z in {-0.78, 0.78} do block(m, "EndStave", 0, 0.72, z, 1.7, 1.3, 0.22, lightWood) end
		for _, y in {0.35, 1.13} do
			for _, z in {-0.9, 0.9} do block(m, "Band", 0, y, z, 1.9, 0.13, 0.12, metal) end
		end
		for _, x in {-0.94, 0.94} do block(m, "HandleArm", x, 1.46, 0, 0.12, 0.96, 0.16, metal) end
		block(m, "Handle", 0, 1.92, 0, 2, 0.16, 0.22, darkWood)
		finish(m)
	end
	do
		local m = template(objects, "HayBale", V(4, 3, 3))
		block(m, "Bale", 0, 1.35, 0, 4, 2.7, 3, gold)
		for _, x in {-1.2, 1.2} do
			block(m, "StrapTop", x, 2.72, 0, 0.28, 0.12, 3.02, red)
			for _, z in {-1.5, 1.5} do block(m, "StrapSide", x, 1.35, z, 0.28, 2.7, 0.1, red) end
		end
		for i = 1, 3 do
			block(m, "Straw", -0.65 + i * 0.3, 2.86, 0.1 + i * 0.19, 0.12, 0.18, 1.2, cream, CFrame.Angles(0, i * 0.25, 0))
			block(m, "HayGrain", 0, 0.45 + i * 0.48, -1.52, 1.65, 0.1, 0.05, lightWood)
		end
		finish(m)
	end
	do
		local m = template(objects, "Cactus", V(3, 7, 3))
		block(m, "Sand", 0, 0.15, 0, 3, 0.3, 3, cream)
		block(m, "Trunk", 0, 3.25, 0, 1.05, 6, 1.05, green)
		block(m, "Crown", 0, 6.35, 0, 0.8, 0.4, 0.8, green)
		for _, side in {-1, 1} do
			local y = side < 0 and 3.1 or 4.1
			block(m, "Arm", side * 0.85, y, 0, 1.2, 0.65, 0.7, green)
			block(m, "RaisedArm", side * 1.14, y + 0.7, 0, 0.62, 1.6, 0.7, green)
			block(m, "ArmRidge", side * 1.14, y + 0.75, -0.37, 0.13, 1.3, 0.08, rgb(120, 215, 75))
		end
		for _, x in {-0.3, 0.3} do block(m, "Ridge", x, 3.2, -0.54, 0.1, 5.55, 0.08, rgb(120, 215, 75)) end
		for i = 1, 4 do block(m, "Spine", 0.05, i + 1, -0.65, 0.18, 0.12, 0.25, cream) end
		block(m, "Flower", 0.13, 6.76, 0, 0.85, 0.48, 0.65, pink)
		block(m, "FlowerCentre", 0.13, 6.79, -0.35, 0.3, 0.22, 0.12, gold)
		finish(m)
	end
	do
		local m = template(objects, "Scarecrow", V(4, 8, 2))
		block(m, "Post", 0, 2.65, 0.25, 0.42, 5.3, 0.4, darkWood)
		block(m, "Shirt", 0, 4.85, 0, 1.6, 2, 0.85, red)
		for _, side in {-1, 1} do
			block(m, "Sleeve", side * 1.23, 5.35, 0, 1.3, 0.75, 0.8, red)
			block(m, "StrawHand", side * 1.86, 5.35, 0, 0.28, 0.48, 0.5, gold)
			block(m, "Trouser", side * 0.48, 3.75, 0, 0.65, 0.65, 0.8, blue)
			block(m, "StrawHem", side * 0.48, 3.36, 0, 0.54, 0.3, 0.6, gold)
			block(m, "PlaidVertical", side * 0.47, 4.85, -0.45, 0.15, 1.95, 0.08, gold)
		end
		for _, y in {4.4, 5.15} do block(m, "PlaidHorizontal", 0, y, -0.46, 1.6, 0.12, 0.09, cream) end
		block(m, "Head", 0, 6.4, 0, 1.2, 1.2, 1, cream)
		block(m, "HatBrim", 0, 7.08, 0, 2.2, 0.2, 2, gold)
		block(m, "HatCrown", -0.12, 7.56, 0, 1.2, 0.88, 1.15, lightWood)
		block(m, "HatBand", -0.12, 7.25, -0.59, 1.2, 0.17, 0.08, red)
		for _, x in {-0.3, 0.3} do block(m, "ButtonEye", x, 6.55, -0.53, 0.17, 0.2, 0.09, black) end
		block(m, "Smile", 0, 6.14, -0.54, 0.55, 0.09, 0.1, darkWood)
		block(m, "Nose", 0, 6.35, -0.59, 0.18, 0.2, 0.2, red)
		finish(m)
	end
	do
		local m = template(objects, "CoveredWagon", V(7, 8, 12))
		wheels(m, 3.05, -3.2, 3.2, 1.5)
		block(m, "Bed", 0, 2.45, 0.7, 5.6, 0.5, 8.8, darkWood)
		for _, x in {-2.65, 2.65} do
			for i = 1, 3 do block(m, "SidePlank", x, 2.7 + i * 0.42, 0.7, 0.24, 0.39, 8.6, i % 2 == 0 and wood or lightWood) end
		end
		block(m, "Tailgate", 0, 3.35, 4.85, 5.4, 1.4, 0.22, wood)
		-- Five overlapping canvas panels form a faceted arch, open at both ends.
		for _, x in {-2.6, 2.6} do block(m, "CanvasWall", x, 5.2, 0.7, 0.24, 2.7, 8.5, white) end
		for _, side in {-1, 1} do
			block(m, "CanvasShoulder", side * 1.93, 7.03, 0.7, 1.95, 0.25, 8.5, white, CFrame.Angles(0, 0, side * -math.pi / 4))
		end
		block(m, "CanvasTop", 0, 7.87, 0.7, 2.7, 0.26, 8.5, white)
		for _, z in {-3.4, 0.7, 4.8} do
			block(m, "CanvasSeam", 0, 8, z, 2.7, 0.05, 0.13, cream)
			for _, x in {-2.74, 2.74} do block(m, "CanvasTie", x, 4.6, z, 0.08, 1.4, 0.12, lightWood) end
		end
		block(m, "DriverSeat", 0, 3.25, -4.3, 4.4, 0.4, 1.3, wood)
		block(m, "SeatBack", 0, 3.75, -3.7, 4.4, 0.8, 0.2, darkWood)
		block(m, "Tongue", 0, 1.7, -4.85, 0.4, 0.4, 2.3, wood)
		block(m, "Yoke", 0, 1.7, -5.7, 2.2, 0.3, 0.3, lightWood)
		finish(m)
	end
	do
		local m = template(objects, "WaterTrough", V(6, 2.5, 3))
		for _, x in {-2.3, 2.3} do
			for _, z in {-1, 1} do block(m, "Leg", x, 0.6, z, 0.5, 1.2, 0.5, darkWood) end
		end
		block(m, "Bottom", 0, 0.9, 0, 5.7, 0.3, 2.7, wood)
		for _, z in {-1.35, 1.35} do block(m, "Side", 0, 1.65, z, 6, 1.7, 0.3, lightWood) end
		for _, x in {-2.85, 2.85} do block(m, "End", x, 1.65, 0, 0.3, 1.7, 2.7, wood) end
		block(m, "Water", 0, 2.05, 0, 5.4, 0.2, 2.4, blue)
		for _, x in {-1.95, 1.95} do block(m, "IronBrace", x, 1.65, -1.52, 0.16, 1.65, 0.08, metal) end
		block(m, "Ripple", -0.7, 2.17, 0.1, 1.4, 0.04, 0.13, white)
		finish(m)
	end
	do
		local m = template(objects, "Outhouse", V(4, 8, 4))
		block(m, "Foundation", 0, 0.2, 0, 4, 0.4, 4, darkWood)
		for _, x in {-1.8, 1.8} do block(m, "Wall", x, 3.65, 0, 0.3, 6.5, 3.7, wood) end
		block(m, "Back", 0, 3.65, 1.75, 3.5, 6.5, 0.3, lightWood)
		for _, x in {-1.45, 1.45} do block(m, "DoorFrame", x, 3.6, -1.8, 0.65, 6.4, 0.3, lightWood) end
		block(m, "DoorBottom", 0, 2.4, -1.82, 2.25, 4, 0.22, wood)
		block(m, "DoorTop", 0, 6.15, -1.82, 2.25, 1.5, 0.22, wood)
		-- Actual opening between door pieces; offset inset creates a crescent silhouette.
		for _, x in {-0.85, 0.85} do block(m, "MoonFrame", x, 4.9, -1.82, 0.55, 1, 0.22, wood) end
		cylinder(m, "MoonShadow", 0, 4.9, -1.72, 0.08, 0.92, black).CFrame = CFrame.new(0, 4.9, -1.72) * CFrame.Angles(0, math.pi / 2, 0)
		cylinder(m, "MoonBite", 0.26, 5.04, -1.87, 0.13, 0.82, wood).CFrame = CFrame.new(0.26, 5.04, -1.87) * CFrame.Angles(0, math.pi / 2, 0)
		for _, y in {1.4, 3.8} do block(m, "Hinge", -1.03, y, -1.98, 0.35, 0.2, 0.12, metal) end
		block(m, "Latch", 0.8, 3.35, -2, 0.16, 0.32, 0.16, gold)
		wedge(m, "SlopingRoof", V(0, 7.35, 0), V(4, 1.3, 4), darkWood)
		block(m, "Step", 0, 0.26, -1.6, 2.5, 0.52, 0.8, lightWood)
		finish(m)
	end
	do
		local m = template(objects, "Stagecoach", V(6, 8, 11))
		wheels(m, 2.55, -3.6, 3.6, 1.4)
		block(m, "Chassis", 0, 1.9, 0, 4.9, 0.45, 10, darkWood)
		block(m, "Cabin", 0, 3.25, 0.4, 4.75, 2.3, 6.6, red)
		block(m, "CabinRoof", 0, 6.18, 0.4, 5.3, 0.4, 7.1, black)
		for _, x in {-2.28, 2.28} do
			for _, z in {-2.6, 0.4, 3.4} do block(m, "WindowPillar", x, 5.05, z, 0.25, 2.1, 0.28, gold) end
			for _, z in {-1.1, 1.9} do block(m, "Window", x, 5.12, z, 0.12, 1.7, 2.6, rgb(56, 104, 142)) end
			block(m, "GoldStripe", x * 1.06, 3.65, 0.4, 0.1, 0.18, 6.6, gold)
			block(m, "Footboard", x, 2.5, 0.4, 0.8, 0.18, 3, lightWood)
			block(m, "RackRail", x, 6.65, 0.4, 0.16, 0.65, 6.5, gold)
		end
		for _, z in {-2.7, 3.5} do block(m, "RackEnd", 0, 6.65, z, 4.6, 0.65, 0.16, gold) end
		block(m, "DriverSeat", 0, 3.6, -4.05, 4.2, 0.45, 1.6, black)
		block(m, "DriverBack", 0, 4.15, -3.3, 4.2, 1, 0.25, red)
		block(m, "Tongue", 0, 1.85, -4.75, 0.4, 0.3, 1.5, wood)
		block(m, "Trunk", -0.65, 7.1, 0.6, 2.7, 1.4, 2.5, wood)
		for _, x in {-1.45, 0.15} do block(m, "LuggageStrap", x, 7.82, 0.6, 0.17, 0.13, 2.5, gold) end
		block(m, "Suitcase", 1.4, 6.95, 1.4, 0.95, 1.1, 1.8, blue)
		for _, x in {-1.8, 1.8} do block(m, "Lantern", x, 4.6, -3.3, 0.5, 0.75, 0.55, gold) end
		finish(m)
	end
	do
		local m = template(objects, "WaterTower", V(9, 20, 9))
		for _, x in {-3.25, 3.25} do
			for _, z in {-3.25, 3.25} do block(m, "Leg", x, 6, z, 0.65, 12, 0.65, darkWood) end
		end
		for _, z in {-3.25, 3.25} do
			beam(m, "CrossBrace", V(-3.25, 2, z), V(3.25, 10.9, z), 0.35, lightWood)
			beam(m, "CrossBrace", V(3.25, 2, z), V(-3.25, 10.9, z), 0.35, wood)
		end
		for _, x in {-3.25, 3.25} do beam(m, "SideBrace", V(x, 2, -3.25), V(x, 10.9, 3.25), 0.35, wood) end
		block(m, "Platform", 0, 11.7, 0, 8.4, 0.5, 8.4, darkWood)
		-- Twelve chunky tangent planks make a hollow, round-ish tank.
		for i = 0, 11 do
			local a = i * math.pi / 6
			block(m, "TankPlank", math.sin(a) * 3.65, 14.65, math.cos(a) * 3.65, 2.05, 5.4, 0.45,
				i % 2 == 0 and lightWood or wood, CFrame.Angles(0, a, 0))
		end
		for _, y in {12.35, 16.85} do cylinder(m, "TankBand", 0, y, 0, 0.28, 8.05, metal, true) end
		-- Stacked polygonal discs suggest a toy cone without a mesh.
		for i = 1, 4 do cylinder(m, "RoofTier", 0, 17.3 + i * 0.55, 0, 0.6, 9 - (i - 1) * 2.05, red, true) end
		block(m, "RoofFinial", 0, 19.8, 0, 0.5, 0.4, 0.5, gold)
		for _, x in {-0.65, 0.65} do block(m, "LadderRail", x, 6, -4.2, 0.15, 12, 0.15, metal) end
		for i = 1, 10 do block(m, "LadderRung", 0, i * 1.12, -4.2, 1.4, 0.13, 0.15, metal) end
		finish(m)
	end
	do
		local m = template(objects, "Saloon", V(22, 18, 16))
		block(m, "Foundation", 0, 0.35, 0, 22, 0.7, 16, darkWood)
		block(m, "Building", 0, 7.2, 2, 20, 13, 11, wood)
		for i = 1, 6 do block(m, "FacadePlank", 0, 1 + i * 1.8, -3.58, 20, 0.16, 0.18, lightWood) end
		block(m, "Porch", 0, 0.95, -5.55, 21.4, 0.5, 4.9, lightWood)
		block(m, "Balcony", 0, 7.4, -5.55, 21.4, 0.5, 4.9, darkWood)
		block(m, "Awning", 0, 13.85, -5.5, 22, 0.4, 5, red)
		for _, x in {-9.8, -3.5, 3.5, 9.8} do
			block(m, "PorchPost", x, 4.2, -7.25, 0.5, 6.1, 0.5, cream)
			block(m, "BalconyPost", x, 10.55, -7.25, 0.4, 6.25, 0.4, cream)
		end
		block(m, "BalconyRail", 0, 9.4, -7.3, 21.1, 0.28, 0.28, gold)
		for i = -4, 4 do block(m, "Baluster", i * 2.3, 8.5, -7.3, 0.2, 1.6, 0.2, cream) end
		block(m, "DoorRecess", 0, 3.6, -3.69, 4.6, 5, 0.16, black)
		for _, side in {-1, 1} do
			block(m, "SwingDoor", side * 1.13, 3.2, -3.9, 2.1, 2.9, 0.25, lightWood, CFrame.Angles(0, side * 0.13, 0))
			block(m, "DoorBrace", side * 1.13, 3.2, -4.08, 1.85, 0.22, 0.16, darkWood)
		end
		for _, y in {4.1, 10.4} do
			for _, x in {-6.5, 6.5} do
				block(m, "WindowFrame", x, y, -3.71, 3, 3.8, 0.22, cream)
				block(m, "Window", x, y, -3.87, 2.5, 3.3, 0.13, blue)
				block(m, "Mullion", x, y, -3.96, 0.18, 3.3, 0.08, cream)
				block(m, "Mullion", x, y, -3.96, 2.5, 0.18, 0.08, cream)
				for _, s in {-1, 1} do block(m, "Shutter", x + s * 1.95, y, -3.8, 0.8, 3.65, 0.23, red) end
			end
		end
		block(m, "UpperDoor", 0, 10, -3.7, 2.8, 4.4, 0.2, darkWood)
		block(m, "Roof", 0, 14, 2, 21.5, 0.45, 11.5, darkWood)
		block(m, "FalseFront", 0, 15.6, -3.45, 20.8, 4.4, 0.6, lightWood)
		block(m, "Cornice", 0, 17.8, -3.45, 22, 0.4, 0.95, cream)
		local sign = block(m, "SaloonSign", 0, 15.8, -3.83, 13.5, 2.5, 0.25, red)
		Kit.label(sign, Enum.NormalId.Front, "SALOON", gold, 24)
		for _, x in {-8.8, 8.4} do
			cylinder(m, "Barrel", x, 2.05, -5.3, 1.7, 1.5, wood, true)
			for _, y in {1.5, 2.6} do cylinder(m, "BarrelBand", x, y, -5.3, 0.16, 1.57, metal, true) end
		end
		finish(m)
	end
	do
		local m = template(safes, "PiggyBank", V(4, 4, 5))
		block(m, "Body", 0, 2, 0.25, 3.5, 2.8, 3.9, pink)
		block(m, "Head", 0, 2.1, -1.5, 2.8, 2.4, 1.6, rgb(255, 143, 182))
		block(m, "Snout", 0, 1.8, -2.25, 1.6, 0.9, 0.5, rgb(230, 77, 137))
		for _, x in {-1.2, 1.2} do
			for _, z in {-1.1, 1.5} do block(m, "Hoof", x, 0.4, z, 0.65, 0.8, 0.7, rgb(171, 54, 109)) end
			wedge(m, "Ear", V(x * 0.8, 3.5, -1.3), V(0.7, 1, 0.7), pink)
			block(m, "Eye", x * 0.65, 2.65, -2.32, 0.25, 0.33, 0.1, black)
			block(m, "Nostril", x * 0.3, 1.85, -2.52, 0.18, 0.2, 0.08, black)
		end
		block(m, "CoinSlot", 0, 3.43, 0.3, 1.1, 0.08, 0.18, black)
		block(m, "TailBase", 0.15, 2.2, 2.35, 0.3, 0.3, 0.3, pink)
		block(m, "CurlyTail", 0.45, 2.45, 2.35, 0.3, 0.65, 0.3, pink)
		block(m, "Cheek", -1.65, 2.05, -1.5, 0.45, 0.5, 0.7, rgb(255, 172, 192))
		finish(m)
	end
	do
		local m = Kit.model("BenchPress", props)
		m:SetAttribute("Footprint", V(8, 6, 6))
		for _, x in {-2.4, 2.4} do
			block(m, "RackFoot", x, 0.15, 0.6, 0.65, 0.3, 4.2, metal)
			block(m, "Upright", x, 2.5, 1, 0.4, 5, 0.4, metal)
			block(m, "BarHook", x, 4.25, 0.6, 0.5, 0.25, 0.8, gold)
		end
		for _, z in {-1.5, 1.25} do block(m, "BenchLeg", 0, 0.95, z, 0.5, 1.9, 0.5, metal) end
		m.PrimaryPart = block(m, "Seat", 0, 2.05, -0.3, 1.9, 0.5, 4.4, red)
		cylinder(m, "Barbell", 0, 4.52, 0.55, 7.8, 0.22, metal)
		for _, x in {-3.25, 3.25} do
			cylinder(m, "WeightPlate", x, 4.52, 0.55, 0.5, 2.2, black)
			cylinder(m, "PlateHub", x, 4.52, 0.55, 0.65, 0.6, gold)
		end
		block(m, "SignPost", 3.75, 0.6, -2.1, 0.25, 1.2, 0.25, darkWood)
		-- Angled side sign keeps a readable 5-stud board inside the compact footprint.
		local sign = block(m, "UpgradeSign", 3.75, 2.7, -0.45, 5, 3, 0.5, blue, CFrame.Angles(0, math.pi / 2, 0))
		Kit.label(sign, Enum.NormalId.Front, "UPGRADE", white, 20)
		marker(m, "Prompt", V(0, 2, -2.9), V(0.2, 0.2, 0.2))
		finish(m)
	end

	local function rig(id, rootY, hipHeight, size)
		local m = Kit.model(id, chasers)
		m:SetAttribute("ChaserId", id)
		m:SetAttribute("Footprint", size)
		local root = marker(m, "HumanoidRootPart", V(0, rootY, 0), V(2, 2, 1))
		root.CanCollide, root.CanQuery, root.Anchored = true, true, false
		m.PrimaryPart = root
		local humanoid = Instance.new("Humanoid")
		humanoid.RequiresNeck = false
		humanoid.HipHeight = hipHeight
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid.RigType = Enum.HumanoidRigType.R15
		humanoid.Parent = m
		return m
	end
	local function weldRig(m)
		for _, p in m:GetDescendants() do
			if p:IsA("BasePart") and p ~= m.PrimaryPart then
				p.Anchored, p.Massless, p.CanCollide = false, true, false
				local weld = Instance.new("WeldConstraint")
				weld.Part0, weld.Part1, weld.Parent = m.PrimaryPart, p, p
			end
		end
		finish(m)
	end
	do
		local m = rig("RanchDog", 1.6, 0.6, V(2.8, 3.2, 4.2))
		block(m, "Body", 0, 1.65, 0.4, 1.8, 1.5, 2.4, wood)
		block(m, "SaddlePatch", 0, 2.43, 0.5, 1.4, 0.12, 1.3, white)
		for _, x in {-0.62, 0.62} do
			for _, z in {-0.3, 1.15} do block(m, "Paw", x, 0.5, z, 0.55, 1, 0.65, white) end
		end
		block(m, "Collar", 0, 1.85, -0.65, 1.92, 0.4, 0.45, red)
		block(m, "Head", 0, 2.15, -1.05, 1.9, 1.6, 1.25, wood)
		block(m, "Muzzle", 0, 1.9, -1.8, 1.25, 0.65, 0.6, white)
		block(m, "Nose", 0, 2.02, -2.12, 0.55, 0.3, 0.12, black)
		for _, side in {-1, 1} do
			block(m, "FloppyEar", side * 1.08, 2.35, -0.87, 0.5, 1.6, 0.6, darkWood, CFrame.Angles(0, 0, side * 0.12))
			block(m, "Eye", side * 0.52, 2.48, -1.7, 0.23, 0.27, 0.1, black)
			block(m, "AngryBrow", side * 0.52, 2.7, -1.72, 0.48, 0.14, 0.12, darkWood, CFrame.Angles(0, 0, side * 0.28))
		end
		block(m, "Tail", 0, 2, 1.8, 0.4, 0.9, 0.4, wood, CFrame.Angles(-0.35, 0, 0))
		weldRig(m)
	end
	do
		local m = rig("Sheriff", 2.7, 1.7, V(3.5, 6, 2))
		block(m, "Torso", 0, 3.25, 0, 1.8, 1.9, 0.9, cream)
		for _, side in {-1, 1} do
			block(m, "Boot", side * 0.5, 0.55, -0.12, 0.8, 1.1, 1.15, darkWood)
			block(m, "Trouser", side * 0.5, 1.65, 0, 0.72, 1.3, 0.8, blue)
			block(m, "Sleeve", side * 1.2, 3.25, 0, 0.55, 1.6, 0.7, cream)
			block(m, "Hand", side * 1.2, 2.3, 0, 0.5, 0.5, 0.65, lightWood)
			block(m, "Vest", side * 0.55, 3.3, -0.5, 0.65, 1.8, 0.16, darkWood)
		end
		block(m, "Head", 0, 4.7, 0, 1.3, 1.15, 1.05, lightWood)
		block(m, "HatBrim", 0, 5.35, 0, 3.2, 0.2, 2, gold)
		block(m, "HatCrown", 0, 5.7, 0.1, 1.7, 0.6, 1.2, wood)
		block(m, "HatBand", 0, 5.48, -0.53, 1.7, 0.16, 0.1, red)
		for _, x in {-0.32, 0.32} do block(m, "Eye", x, 4.85, -0.56, 0.2, 0.19, 0.08, black) end
		block(m, "Moustache", 0, 4.45, -0.61, 0.85, 0.21, 0.18, darkWood)
		block(m, "StarBadge", -0.55, 3.65, -0.64, 0.42, 0.42, 0.12, gold, CFrame.Angles(0, 0, math.pi / 4))
		weldRig(m)
	end
	return "Built ReplicatedStorage.Assets (BaseParts, including roots): " .. table.concat(summaries, ", ")
end
