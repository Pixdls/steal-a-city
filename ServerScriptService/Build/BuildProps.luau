--!nonstrict
-- Edit-time prop masters. Owns Assets.Props.Set only; BenchPress is untouched.
return function(Kit)
	local V, C = Kit.V, Kit.C
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
		or Kit.folder("Assets", game:GetService("ReplicatedStorage"))
	local props = assets:FindFirstChild("Props") or Kit.folder("Props", assets)
	local previous = props:FindFirstChild("Set")
	if previous then previous:Destroy() end
	local set = Kit.folder("Set", props)
	Kit.ensureStuds()
	local masters = {}
	local function master(name, footprint)
		local m = Kit.model(name, set)
		m.PrimaryPart = Kit.marker(m, "Root", V(1, 1, 1), V(0, 0, 0))
		m:SetAttribute("Footprint", footprint)
		m:PivotTo(CFrame.identity)
		table.insert(masters, m)
		return m
	end
	local function solid(m, name, x, y, z, px, py, pz, color)
		return Kit.part(m, name, V(x, y, z), V(px, py, pz), color)
	end
	local function detail(m, name, x, y, z, px, py, pz, color)
		return Kit.decor(m, name, V(x, y, z), V(px, py, pz), color)
	end
	-- Roblox cylinders run along local X. These are stacked slices, never
	-- coloured sleeves embedded into another cylinder.
	local function cylinder(m, name, diameter, height, pos, color, orientation)
		return Kit.decor(m, name, V(height, diameter, diameter),
			CFrame.new(pos) * (orientation or CFrame.Angles(0, 0, math.pi / 2)), color,
			{ Shape = Enum.PartType.Cylinder })
	end
	local function ring(m, prefix, width, depth, thickness, height, y, color, z)
		z = z or 0
		detail(m, prefix .. "Front", width, height, thickness, 0, y, z + (depth - thickness) / 2, color)
		detail(m, prefix .. "Back", width, height, thickness, 0, y, z - (depth - thickness) / 2, color)
		detail(m, prefix .. "Left", thickness, height, depth - 2 * thickness, -(width - thickness) / 2, y, z, color)
		detail(m, prefix .. "Right", thickness, height, depth - 2 * thickness, (width - thickness) / 2, y, z, color)
	end

	do
		local m = master("Barrel", V(3, 4, 3))
		for _, row in ipairs({
			{ "LowerStaves", 0, 0.6, 2.8, C.Wood },
			{ "LowerHoop", 0.6, 1, 3, C.Charcoal },
			{ "MiddleStaves", 1, 3, 2.9, C.Wood },
			{ "UpperHoop", 3, 3.4, 3, C.Charcoal },
			{ "UpperStaves", 3.4, 3.6, 2.8, C.Wood },
			{ "LidRim", 3.6, 4, 3, C.Cream },
		}) do
			cylinder(m, row[1], row[4], row[3] - row[2], V(0, (row[2] + row[3]) / 2, 0), row[5])
		end
	end
	do
		local m = master("Crate", V(3, 3, 3))
		-- Twelve edge beams surround six inset panels. Their volumes partition
		-- the cube rather than placing a darker frame through a solid box.
		for _, x in ipairs({ -1.25, 1.25 }) do
			for _, z in ipairs({ -1.25, 1.25 }) do
				solid(m, "CornerBeam", 0.5, 3, 0.5, x, 1.5, z, C.WoodDark)
			end
		end
		for _, y in ipairs({ 0.25, 2.75 }) do
			for _, z in ipairs({ -1.25, 1.25 }) do
				solid(m, "CrossBeam", 2, 0.5, 0.5, 0, y, z, C.WoodDark)
			end
			for _, x in ipairs({ -1.25, 1.25 }) do
				solid(m, "SideBeam", 0.5, 0.5, 2, x, y, 0, C.WoodDark)
			end
			detail(m, "HorizontalPanel", 2, 0.4, 2, 0, y, 0, C.Wood)
		end
		for _, z in ipairs({ -1.2, 1.2 }) do detail(m, "FacePanel", 2, 2, 0.4, 0, 1.5, z, C.Wood) end
		for _, x in ipairs({ -1.2, 1.2 }) do detail(m, "SidePanel", 0.4, 2, 2, x, 1.5, 0, C.Wood) end
		detail(m, "Stencil", 1.2, 0.6, 0.1, 0, 1.5, 1.45, C.Cream)
	end

	local function lantern(m, offset)
		local function p(name, x, y, z, px, py, pz)
			return Kit.decor(m, name, V(x, y, z), offset * CFrame.new(px, py, pz), C.Charcoal)
		end
		p("LanternFoot", 1.6, 0.4, 1.6, 0, 0.2, 0)
		p("LanternRoof", 1.6, 0.4, 1.6, 0, 1.8, 0)
		for _, x in ipairs({ -0.6, 0.6 }) do
			for _, z in ipairs({ -0.6, 0.6 }) do p("CageBar", 0.4, 1.2, 0.4, x, 1, z) end
		end
		Kit.lamp(m, "Light", V(0.6, 1.2, 0.6), offset * CFrame.new(0, 1, 0))
		-- Deliberately thin square hanging hook, open underneath the crown.
		p("HookLeft", 0.2, 0.6, 0.2, -0.3, 2.3, 0)
		p("HookRight", 0.2, 0.6, 0.2, 0.3, 2.3, 0)
		p("HookCrown", 0.8, 0.2, 0.2, 0, 2.5, 0)
	end
	lantern(master("Lantern", V(1.6, 2.6, 1.6)), CFrame.identity)
	do
		local m = master("LanternPost", V(1.6, 11, 4.2))
		solid(m, "Post", 1.2, 10.6, 1.2, 0, 5.3, 0, C.WoodDark)
		solid(m, "OverheadArm", 0.6, 0.4, 3.6, 0, 10.8, 1.2, C.WoodDark)
		-- Lantern hook touches the arm's underside, forward of the post.
		lantern(m, CFrame.new(0, 8, 2.8))
	end
	do
		local m = master("HitchingPost", V(5, 3, 1))
		for _, x in ipairs({ -2.1, 2.1 }) do solid(m, "Upright", 0.8, 3, 1, x, 1.5, 0, C.WoodDark) end
		solid(m, "HitchRail", 3.4, 0.6, 0.6, 0, 2.1, 0, C.Wood)
		for _, x in ipairs({ -1, 1 }) do
			-- Four bars form an actual open tie ring, wholly ahead of the rail.
			for _, dx in ipairs({ -0.25, 0.25 }) do detail(m, "RingSide", 0.1, 0.5, 0.2, x + dx, 2.1, 0.4, C.Charcoal) end
			for _, y in ipairs({ 1.85, 2.35 }) do detail(m, "RingCrossbar", 0.4, 0.1, 0.2, x, y, 0.4, C.Charcoal) end
		end
	end
	do
		local m = master("Trough", V(6, 2.5, 3))
		for _, x in ipairs({ -2.3, 2.3 }) do
			for _, z in ipairs({ -0.95, 0.95 }) do solid(m, "Leg", 0.6, 0.6, 0.6, x, 0.3, z, C.WoodDark) end
		end
		solid(m, "BasinFloor", 6, 0.4, 3, 0, 0.8, 0, C.Wood)
		for _, y in ipairs({ 1.25, 1.75, 2.25 }) do ring(m, "BasinPlank", 6, 3, 0.4, 0.5, y, C.Wood) end
		detail(m, "Water", 5.2, 0.4, 2.2, 0, 2, 0, C.Sky) -- surface 2.2; rim 2.5
	end
	do
		local m = master("Signpost", V(6, 9, 1.8))
		solid(m, "Post", 1.2, 9, 1.2, 0, 4.5, 0, C.WoodDark)
		detail(m, "Sign", 6, 3, 0.4, 0, 6.9, 0.8, C.Cream)
		for _, y in ipairs({ 5.6, 8.2 }) do detail(m, "SignBorder", 5.6, 0.2, 0.2, 0, y, 1.1, C.Wood) end
		for _, x in ipairs({ -2.7, 2.7 }) do detail(m, "SignEnd", 0.2, 2.4, 0.2, x, 6.9, 1.1, C.Wood) end
	end
	do
		local m = master("Bench", V(6, 3, 2))
		for _, x in ipairs({ -2.3, 2.3 }) do
			solid(m, "FrontLeg", 0.6, 1.4, 0.6, x, 0.7, 0.6, C.WoodDark)
			solid(m, "BackLeg", 0.6, 1.4, 0.6, x, 0.7, -0.6, C.WoodDark)
			solid(m, "BackSupport", 0.6, 1.6, 0.4, x, 2.2, -0.8, C.WoodDark)
		end
		for _, z in ipairs({ -0.225, 0.525 }) do solid(m, "SeatPlank", 6, 0.4, 0.75, 0, 1.6, z, C.Wood) end
		for _, y in ipairs({ 2.05, 2.75 }) do solid(m, "BackPlank", 6, 0.5, 0.4, 0, y, -0.4, C.Wood) end
	end
	do
		local m = master("FlowerBox", V(4, 1.5, 1.5))
		solid(m, "BoxFloor", 4, 0.4, 1.5, 0, 0.2, 0, C.Wood)
		ring(m, "BoxSide", 4, 1.5, 0.4, 0.5, 0.65, C.Wood)
		detail(m, "Soil", 3.2, 0.4, 0.7, 0, 0.6, 0, C.GrassDark)
		for i, color in ipairs({ C.Pink, C.Gold, C.Cream, C.Pink, C.Gold }) do
			local x = (i - 3) * 0.62
			local stem = detail(m, "FlowerStem" .. i, 0.16, 0.3, 0.16, x, 0.95, 0, C.Leaf)
			local flower = detail(m, "Flower" .. i, 0.5, 0.4, 0.5, x, 1.3, 0, color)
			stem.CastShadow, flower.CastShadow = false, false
		end
	end
	do
		local m = master("MilkCan", V(1.2, 2.2, 1.2))
		cylinder(m, "CanBase", 1.2, 0.4, V(0, 0.2, 0), C.Slate)
		cylinder(m, "CanBody", 1.2, 1.2, V(0, 1, 0), C.Slate)
		cylinder(m, "CanNeck", 0.8, 0.2, V(0, 1.7, 0), C.Slate)
		cylinder(m, "Lid", 1, 0.2, V(0, 1.9, 0), C.Charcoal)
		detail(m, "LidGrip", 0.4, 0.2, 0.2, 0, 2.1, 0, C.Charcoal)
	end

	-- Six cylindrical felloe segments make an open chunky rim, with six
	-- individual radial spokes. Hub is on the front of the spokes, not inside.
	-- Rotate the hexagonal rim 15 degrees so its X/Y extents match.
	local rimAngle = math.rad(15)
	local rimRadius = (2 - 0.2 * math.cos(rimAngle))
		/ (math.cos(rimAngle) + math.tan(math.pi / 6) * math.sin(rimAngle))
	local rimLength = 2 * rimRadius * math.tan(math.pi / 6)
	local function wheel(m, transform, prefix)
		for i = 1, 6 do
			local angle = (i - 1) * math.pi / 3 + rimAngle
			local radial = CFrame.Angles(0, 0, angle)
			local rim = cylinder(m, prefix .. "Rim" .. i, 0.4, rimLength,
				V(0, 0, 0), C.Wood, CFrame.identity)
			rim.CFrame = transform * radial * CFrame.new(0, rimRadius, 0)
			Kit.decor(m, prefix .. "Spoke" .. i, V(0.4, 1.7, 0.4),
				transform * radial * CFrame.new(0, 0.85, 0), C.Wood)
		end
		cylinder(m, prefix .. "Hub", 0.8, 0.2, V(0, 0, 0), C.Charcoal, CFrame.identity).CFrame =
			transform * CFrame.new(0, 0, 0.3) * CFrame.Angles(0, math.pi / 2, 0)
	end
	do
		local tilt = CFrame.Angles(math.rad(-12), 0, 0)
		-- Lowest rim point is the cylinder's radial support, exactly grounded.
		local cosine = math.cos(math.rad(12))
		local axisY = math.sin(rimAngle) * cosine
		local baseY = rimRadius * math.cos(rimAngle) * cosine
			+ rimLength * axisY / 2 + 0.2 * math.sqrt(1 - axisY * axisY)
		local m = master("WagonWheel", V(4, 4, 1.5))
		wheel(m, CFrame.new(0, baseY, 0) * tilt, "Wheel")
	end
	do
		local m = master("HayCart", V(7, 5, 4))
		-- Same wheel geometry, stood upright with hubs facing outward.
		wheel(m, CFrame.new(-3.05, 2, 0) * CFrame.Angles(0, -math.pi / 2, 0), "LeftWheel")
		wheel(m, CFrame.new(3.05, 2, 0) * CFrame.Angles(0, math.pi / 2, 0), "RightWheel")
		solid(m, "CartBed", 5.7, 0.5, 4, 0, 2.75, 0, C.Wood)
		for _, x in ipairs({ -1.35, 1.35 }) do detail(m, "HayBale", 2.5, 2, 3.4, x, 4, 0, C.Gold) end
	end
	do
		local m = master("CactusPot", V(2, 4, 2))
		cylinder(m, "PotBase", 1.6, 0.4, V(0, 0.2, 0), C.Dirt)
		cylinder(m, "PotBody", 1.8, 0.6, V(0, 0.7, 0), C.Dirt)
		cylinder(m, "PotRim", 2, 0.4, V(0, 1.2, 0), C.Cream)
		detail(m, "CactusTrunk", 0.6, 2.6, 0.6, -0.2, 2.7, 0, C.Leaf)
		detail(m, "CactusArm", 0.7, 0.4, 0.4, 0.45, 2.6, 0, C.Leaf)
		detail(m, "CactusFinger", 0.4, 0.8, 0.4, 0.6, 3.2, 0, C.Leaf)
	end
	do
		local m = master("BulletinBoard", V(8, 7, 1))
		for _, x in ipairs({ -3.6, 3.6 }) do solid(m, "FramePost", 0.8, 7, 0.8, x, 3.5, -0.1, C.WoodDark) end
		for _, y in ipairs({ 2.2, 6.6 }) do solid(m, "FrameRail", 6.4, 0.8, 0.8, 0, y, -0.1, C.WoodDark) end
		detail(m, "Board", 6.4, 3.6, 0.4, 0, 4.4, -0.1, C.Cream)
		for i = 1, 3 do detail(m, "Poster" .. i, 1.5, 2.4, 0.1, (i - 2) * 2, 4.4, 0.15, C.Sand) end
	end
	local function fencePost(m, x)
		solid(m, "Post", 1.2, 4.6, 1.2, x, 2.3, 0, C.Cream)
		detail(m, "Cap", 1.4, 0.4, 1.4, x, 4.8, 0, C.Gold)
		-- Three cream post courses provide chunky foot/shaft/collar relief.
		solid(m, "PostFoot", 1.4, 0.4, 1.4, x, 0.2, 0, C.Cream)
		detail(m, "PostCollar", 1.4, 0.4, 1.4, x, 4.2, 0, C.Cream)
		detail(m, "PostFace", 0.6, 0.8, 0.1, x, 3.4, 0.65, C.Cream)
	end
	do
		local m = master("FenceModule", V(11.4, 5, 1.4))
		m:SetAttribute("ChainLength", 10)
		m:SetAttribute("PivotConvention", "LeftPostBase")
		fencePost(m, 0)
		fencePost(m, 10)
		-- Rails meet the shaft edge and clear the wider foot/collar.
		solid(m, "UpperRail", 8.8, 0.9, 0.8, 5, 3.1, 0, C.Cream)
		solid(m, "LowerRail", 8.8, 0.9, 0.8, 5, 1.4, 0, C.Wood)
	end
	fencePost(master("FencePost", V(1.4, 5, 1.4)), 0)
	do
		local m = master("PathEdge", V(8, 0.6, 1))
		for i = 1, 4 do
			local x = (i - 2.5) * 2
			solid(m, "StoneBase" .. i, 2, 0.4, 1, x, 0.2, 0, C.Sand)
			detail(m, "StoneCrown" .. i, 1.8, 0.2, 0.8, x, 0.5, 0, C.Sand)
		end
	end
	do
		local m = master("Steps", V(5, 2, 5))
		-- +Z is the bottom approach; five separate boards in each tread.
		for i = 1, 5 do
			local x = i - 3
			solid(m, "LowerTread" .. i, 1, 1, 2.5, x, 0.5, 1.25, C.Wood)
			solid(m, "UpperTread" .. i, 1, 2, 2.5, x, 1, -1.25, C.Wood)
		end
	end
	do
		local m = master("Tumbleweed", V(2.5, 2.5, 2.5))
		-- Same-colour crossed twigs keep the dense centre free of coloured
		-- intersections. Thin sticks are deliberate dry-foliage detail.
		local length = 2.5 * math.sqrt(2) - 0.24
		for i = 1, 6 do
			Kit.decor(m, "DryTwig" .. i, V(0.24, length, 0.24),
				CFrame.new(0, 1.25, 0) * CFrame.Angles(0, (i - 1) * math.pi / 3, 0)
				* CFrame.Angles(0, 0, math.pi / 4), C.WoodDark,
				{ CastShadow = false })
		end
	end
	do
		local m = master("WaterPump", V(2, 4.5, 2))
		solid(m, "PumpFoot", 1, 0.4, 1, -0.5, 0.2, -0.5, C.Slate)
		cylinder(m, "PumpBarrel", 0.6, 2.6, V(-0.5, 1.7, -0.5), C.Slate)
		solid(m, "PumpHead", 0.8, 0.6, 0.8, -0.5, 3.3, -0.5, C.Slate)
		solid(m, "Spout", 0.4, 0.4, 1.2, -0.5, 2.7, 0.2, C.Slate)
		detail(m, "SpoutLip", 0.4, 0.4, 0.4, -0.5, 2.3, 0.6, C.Slate)
		detail(m, "HandlePivot", 1, 0.4, 0.4, 0, 3.6, -0.5, C.Slate)
		detail(m, "HandleLever", 0.4, 1.1, 0.4, 0.5, 3.95, -0.5, C.Slate)
		solid(m, "BucketBase", 1, 0.2, 0.8, -0.5, 0.1, 0.6, C.Wood)
		-- Open bucket under the outlet; four walls meet the floor edges.
		for _, z in ipairs({ 0.3, 0.9 }) do detail(m, "BucketPlank", 1, 1, 0.2, -0.5, 0.7, z, C.Wood) end
		for _, x in ipairs({ -0.9, -0.1 }) do detail(m, "BucketSide", 0.2, 1, 0.4, x, 0.7, 0.6, C.Wood) end
	end

	local counts = {}
	for _, m in ipairs(masters) do
		local count = 0
		for _, item in ipairs(m:GetDescendants()) do
			if item:IsA("BasePart") then count += 1 end
		end
		table.insert(counts, m.Name .. ": " .. count)
	end
	return "Built Assets.Props.Set (part counts include Root): " .. table.concat(counts, "; ")
end
