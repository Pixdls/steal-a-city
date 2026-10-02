--!nonstrict
-- Edit-time map builder (plan v4 §2, docs/MAP_REVAMP.md). Rebuilds workspace.Map.
-- Run from Studio (Edit):
--   local B = game.ServerScriptService.Build
--   local Kit = loadstring(B.Kit.Source)()
--   return loadstring(B.BuildMap.Source)()(Kit)
-- Structure and runtime markers live here. Zone dressing (props, foliage, lights) is done by
-- Build/ZoneLobby, ZoneRanch, ZoneTown when they exist. Road runs toward -Z, lobby at z >= 0,
-- ground top at y = 0, x = 0 is the road centre.

return function(Kit)
	local V, part, label, C = Kit.V, Kit.part, Kit.label, Kit.C
	local rng = Kit.rng
	Kit.ensureStuds()

	for _, name in { "Map", "StudTest", "Baseplate", "FacadePreview", "AssetPreview" } do
		local old = workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local cone = workspace:FindFirstChild("TrafficCone")
	if cone then cone.Parent = game:GetService("ServerStorage") end

	local Assets = game.ReplicatedStorage:FindFirstChild("Assets")
	local Facades = Assets and Assets:FindFirstChild("Facades")
	local PropSet = Assets and Assets:FindFirstChild("Props") and Assets.Props:FindFirstChild("Set")
	local benchTemplate = Assets and Assets:FindFirstChild("Props") and Assets.Props:FindFirstChild("BenchPress")

	local Map = Instance.new("Folder")
	Map.Name = "Map"
	local Bounds = Kit.folder("Bounds", Map)
	local WALL_H = 48
	local FRONT_LOBBY, FRONT_STAGE = 8, 12 -- frontage strips reserved for facade depth

	-- A zone folder with the standard sub-folders.
	local function zone(name, parent)
		local f = Kit.folder(name, parent or Map)
		for _, sub in { "Structure", "Props", "Foliage", "Lighting" } do Kit.folder(sub, f) end
		return f
	end

	---------------------------------------------------------------- helpers
	local function plate(parent, name, at, inward, alongX, along, y, w, h, color, depth)
		depth = depth or 0.6
		local c = at + inward * depth / 2
		local size = alongX and V(w, h, depth) or V(depth, h, w)
		local pos = alongX and V(along, y, c) or V(c, y, along)
		return Kit.decor(parent, name, size, pos, color)
	end
	local function inwardFace(inward, alongX)
		if alongX then return inward > 0 and Enum.NormalId.Back or Enum.NormalId.Front end
		return inward > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	end
	local function sign(parent, at, inward, alongX, along, y, w, h, text, color, textColor)
		local p = plate(parent, "Sign", at, inward, alongX, along, y, w, h, color, 1)
		label(p, inwardFace(inward, alongX), text, textColor or C.Cream)
		return p
	end
	-- Side walls of a corridor section (z0 > z1), both sides at +-half, with grass caps and bounds.
	local function sideWalls(parent, z0, z1, half, color)
		for _, s in { -1, 1 } do
			Kit.wall(parent, "Wall", z1, z0, s * half, -s, false, WALL_H, color)
			part(parent, "WallCap", V(8, 2, z0 - z1), V(s * (half + 3), WALL_H + 1, (z0 + z1) / 2), C.Grass)
			Kit.bound(Bounds, V(2, 400, z0 - z1), V(s * (half + 1), 200 + WALL_H, (z0 + z1) / 2))
		end
	end
	-- Facade row along a wall line; names cycle until the span is filled.
	local function facadeRow(parent, names, a0, a1, at, inward, alongX, startIndex)
		if not Facades then return end
		local yaw = alongX and (inward > 0 and 0 or 180) or (inward > 0 and 90 or -90)
		local pos, i = a0, startIndex or 1
		while true do
			local tmpl = Facades:FindFirstChild(names[(i - 1) % #names + 1])
			if not tmpl then return end
			local w = tmpl:GetAttribute("Width") or 40
			if pos + w > a1 + 0.5 then return end
			local centre = alongX and V(pos + w / 2, 0, at) or V(at, 0, pos + w / 2)
			Kit.place(tmpl, CFrame.new(centre) * CFrame.Angles(0, math.rad(yaw), 0), parent)
			pos += w
			i += 1
		end
	end
	-- Year arch across the road at z with pillars at +-half. PrimaryPart = Base marker.
	local function arch(parent, name, z, half, text, sub, color)
		local m = Kit.model(name, parent)
		for _, s in { -1, 1 } do
			part(m, "PillarBase", V(10, 3, 10), V(s * (half - 4), 1.5, z), C.Cream)
			part(m, "Pillar", V(8, 33, 8), V(s * (half - 4), 19.5, z), color)
			part(m, "PillarCap", V(10, 3, 10), V(s * (half - 4), 37.5, z), C.Cream)
			Kit.lamp(m, "ArchLamp", V(2, 2, 2), V(s * (half - 4), 28, z - 5))
		end
		local inner = (half - 9) * 2 -- between the pillar caps
		local beam = part(m, "Beam", V(inner, 10, 6), V(0, 44, z), color)
		label(beam, Enum.NormalId.Back, text, C.Cream, 8)
		label(beam, Enum.NormalId.Front, text, C.Cream, 8)
		Kit.decor(m, "BeamTrim", V(inner, 1.5, 6.4), V(0, 38.25, z), C.Cream)
		Kit.decor(m, "BeamTrim", V(inner, 1.5, 6.4), V(0, 49.75, z), C.Cream)
		if sub then
			local board = Kit.decor(m, "SizeSign", V(26, 6, 1), V(0, 31.5, z), C.Charcoal)
			label(board, Enum.NormalId.Back, sub, C.Gold)
			Kit.decor(m, "Chain", V(0.5, 3, 0.5), V(-10, 36, z), C.Slate)
			Kit.decor(m, "Chain", V(0.5, 3, 0.5), V(10, 36, z), C.Slate)
		end
		m.PrimaryPart = Kit.marker(m, "Base", V(2, 1, 2), V(0, 0.5, z))
		return m
	end
	local function spawnMarker(folder, id, x, y, z, yaw)
		local m = Kit.marker(folder, id, V(2, 1, 2), CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
		m:SetAttribute("ObjectId", id)
		return m
	end
	-- Fence run from a to b (y = 0), accent-capped posts. Uses the FenceModule master when present.
	local function fenceRun(parent, a, b, accent)
		local d = b - a
		local len = d.Magnitude
		local dir = d.Unit
		local yaw = math.atan2(-dir.Z, dir.X) -- module runs along +X
		local master = PropSet and PropSet:FindFirstChild("FenceModule")
		if master then
			local fp = master:GetAttribute("Footprint")
			local w = fp and fp.X or 10
			local n = math.max(1, math.floor(len / w + 0.001))
			local step = len / n
			local c = master:Clone()
			c:ScaleTo(step / w)
			for i = 0, n - 1 do
				local m = Kit.place(c, CFrame.new(a + dir * (i * step)) * CFrame.Angles(0, yaw, 0), parent)
				for _, cap in m:GetDescendants() do if cap.Name == "Cap" then cap.Color = accent end end
			end
			c:Destroy()
			local post = PropSet:FindFirstChild("FencePost")
			if post then
				local m = Kit.place(post, CFrame.new(b) * CFrame.Angles(0, yaw, 0), parent)
				for _, cap in m:GetDescendants() do if cap.Name == "Cap" then cap.Color = accent end end
			end
			return
		end
		local n = math.max(1, math.round(len / 10))
		for i = 0, n do
			local p = a + d * (i / n)
			part(parent, "FencePost", V(1.4, 5, 1.4), p + V(0, 2.5, 0), C.Cream)
			Kit.decor(parent, "FenceCap", V(1.8, 0.8, 1.8), p + V(0, 5.4, 0), accent)
		end
		local mid = (a + b) / 2
		local size = math.abs(d.X) > math.abs(d.Z) and V(len - 1.4, 0.9, 0.7) or V(0.7, 0.9, len - 1.4)
		Kit.decor(parent, "FenceRail", size, mid + V(0, 3.6, 0), accent)
		Kit.decor(parent, "FenceRail", size, mid + V(0, 1.6, 0), C.Cream)
	end
	-- Market stall (station), counter facing -Z.
	local function stall(parent, name, x, z, color, text)
		local m = Kit.model(name, parent)
		for _, dx in { -7, 7 } do
			for _, dz in { -4, 4 } do part(m, "Post", V(1.4, 11, 1.4), V(x + dx, 5.5, z + dz), C.WoodDark) end
		end
		part(m, "Counter", V(12.6, 4, 3), V(x, 2, z - 4), C.Wood)
		Kit.decor(m, "CounterTop", V(12.6, 0.8, 3.6), V(x, 4.4, z - 4), C.Slate)
		part(m, "Back", V(12.6, 9, 1), V(x, 5.5, z + 4.5), C.Wood)
		Kit.decor(m, "Shelf", V(12, 0.6, 1.4), V(x, 6, z + 3.3), C.WoodDark)
		for i = 0, 4 do
			local c = i % 2 == 0 and color or C.Cream
			Kit.decor(m, "Awning", V(3.4, 0.8, 13), CFrame.new(x - 6.8 + i * 3.4, 11.6, z - 1) * CFrame.Angles(math.rad(12), 0, 0), c)
		end
		local s = Kit.decor(m, "Sign", V(16, 4, 0.8), V(x, 15.5, z - 6), color)
		label(s, Enum.NormalId.Front, text)
		Kit.decor(m, "SignTrim", V(16.6, 0.6, 1), V(x, 17.8, z - 6), C.Cream)
		Kit.decor(m, "SignTrim", V(16.6, 0.6, 1), V(x, 13.2, z - 6), C.Cream)
		Kit.lamp(m, "StallLamp", V(1.6, 1.6, 1.6), V(x - 8.6, 9, z - 5))
		Kit.decor(m, "Ring", V(0.3, 18, 18), CFrame.new(x, 0.15, z - 14) * CFrame.Angles(0, 0, math.rad(90)), color,
			{ Material = Enum.Material.Neon, Shape = Enum.PartType.Cylinder, Transparency = 0.5 })
		local prompt = Kit.marker(m, "Prompt", V(2, 2, 2), V(x, 4, z - 7))
		m.PrimaryPart = prompt
		return m
	end

	---------------------------------------------------------------- LOBBY (Home)
	local LOBBY_X, LOBBY_Z = 112, 262
	local GATE = 40
	local S1_HALF, S1_END = 56, -300
	local S2_HALF, S2_START, S2_END = 72, -340, -680
	local Home = zone("Home", Map)
	local HS, HLight = Home.Structure, Home.Lighting
	Kit.ground(HS, "Grass", -LOBBY_X, LOBBY_X, 0, LOBBY_Z, C.Grass, 30, C.GrassDark, { 10, 37 })
	Kit.decor(HS, "Path", V(18, 0.1, LOBBY_Z - 40), V(0, 0.05, (LOBBY_Z - 40) / 2), C.Dirt, { CastShadow = false })

	local zoneMarker = Kit.marker(Home, "SafeZone", V(LOBBY_X * 2, 200, LOBBY_Z), V(0, 100, LOBBY_Z / 2))
	zoneMarker:SetAttribute("GateZ", 0)

	-- Walls: sides, back, front with the gate opening
	for _, s in { -1, 1 } do
		Kit.wall(HS, "Wall", 0, LOBBY_Z, s * LOBBY_X, -s, false, WALL_H, C.GrassDark)
		part(HS, "WallCap", V(8, 2, LOBBY_Z + 12), V(s * (LOBBY_X + 3), WALL_H + 1, LOBBY_Z / 2), C.Grass)
		Kit.wall(HS, "Wall", s > 0 and GATE or -LOBBY_X, s > 0 and LOBBY_X or -GATE, 0, 1, true, WALL_H, C.GrassDark)
		Kit.bound(Bounds, V(2, 400, LOBBY_Z), V(s * (LOBBY_X + 1), 200 + WALL_H, LOBBY_Z / 2))
		facadeRow(HS, { "LobbyA", "LobbyB", "LobbyA", "LobbyB", "LobbyCorner" }, 6, LOBBY_Z - 4, s * LOBBY_X, -s, false, s > 0 and 2 or 1)
		facadeRow(HS, { "LobbyB" }, s > 0 and GATE + 4 or -LOBBY_X + 4, s > 0 and LOBBY_X - 4 or -GATE - 4, 0, 1, true)
	end
	Kit.wall(HS, "BackWall", -LOBBY_X, LOBBY_X, LOBBY_Z, -1, true, WALL_H, C.Sand)
	part(HS, "WallCap", V(LOBBY_X * 2 + 12, 2, 8), V(0, WALL_H + 1, LOBBY_Z + 3), C.Grass)
	Kit.bound(Bounds, V(LOBBY_X * 2, 400, 2), V(0, 200 + WALL_H, LOBBY_Z + 1))
	for y = 8, WALL_H - 8, 12 do -- back wall trims: no large flat faces
		Kit.decor(HS, "BackTrim", V(LOBBY_X * 2 - 2, 1.2, 0.4), V(0, y, LOBBY_Z - 0.2), C.Wood)
	end
	for x = -LOBBY_X + 14, LOBBY_X - 14, 28 do
		Kit.decor(HS, "BackBatten", V(2, WALL_H - 4, 0.6), V(x, WALL_H / 2, LOBBY_Z - 0.3), C.Wood)
	end

	-- Gate arch and the safe-zone line
	arch(HS, "GiantGate", -11, GATE + 4, "RANCH TRAIL  ·  1880", nil, C.Sky)
	Kit.decor(HS, "SafeLine", V(GATE * 2, 0.1, 1.5), V(0, 0.15, 1), C.BarnRed, { Material = Enum.Material.Neon })
	local safeText = Kit.marker(HS, "SafeText", V(40, 0.2, 8), V(0, 0.2, 9))
	label(safeText, Enum.NormalId.Top, "SAFE ZONE", C.Sky).Rotation = 180

	-- Leaderboards framed into the back wall
	local Boards = Kit.folder("Boards", Home)
	for _, b in { { "Richest", -72, "RICHEST", C.Leaf }, { "Biggest", 72, "BIGGEST", C.Sky } } do
		plate(Boards, "FrameTop", LOBBY_Z, -1, true, b[2], 33, 34, 2, C.WoodDark, 1.4)
		plate(Boards, "FrameBottom", LOBBY_Z, -1, true, b[2], 11, 34, 2, C.WoodDark, 1.4)
		plate(Boards, "FrameSide", LOBBY_Z, -1, true, b[2] - 16, 22, 2, 20, C.WoodDark, 1.4)
		plate(Boards, "FrameSide", LOBBY_Z, -1, true, b[2] + 16, 22, 2, 20, C.WoodDark, 1.4)
		local board = plate(Boards, b[1], LOBBY_Z, -1, true, b[2], 22, 30, 20, C.Cream, 1.4)
		sign(Boards, LOBBY_Z, -1, true, b[2], 37.5, 30, 5, b[3], b[4]).Name = b[1] .. "Title"
		board:SetAttribute("Board", b[1])
	end

	-- Stations along the back
	local Stations = Kit.folder("Stations", Home)
	stall(Stations, "Sell", -34, 244, C.BarnRed, "SELL")
	stall(Stations, "Shop", 34, 244, C.Leaf, "SHOP")
	stall(Stations, "Footprints", 68, 244, C.Orange, "FOOTPRINTS")
	do
		local m = Kit.model("Crusher", Stations)
		part(m, "Base", V(14, 5, 12), V(0, 2.5, 246), C.Slate)
		part(m, "Body", V(12, 6, 10), V(0, 8, 246), C.Sky)
		for _, dx in { -2.6, 2.6 } do
			part(m, "Roller", V(9, 5, 5), CFrame.new(dx, 12.5, 246) * CFrame.Angles(0, math.rad(90), 0), C.Cream, { Shape = Enum.PartType.Cylinder })
		end
		Kit.decor(m, "HopperL", V(1.5, 6, 10), CFrame.new(-6.5, 15, 246) * CFrame.Angles(0, 0, math.rad(-18)), C.Gold)
		Kit.decor(m, "HopperR", V(1.5, 6, 10), CFrame.new(6.5, 15, 246) * CFrame.Angles(0, 0, math.rad(18)), C.Gold)
		Kit.lamp(m, "Light", V(2, 2, 2), V(0, 9, 239))
		local s = Kit.decor(m, "Sign", V(14, 4, 0.8), V(0, 21, 241), C.Sky)
		label(s, Enum.NormalId.Front, "CRUSHER")
		local sub = Kit.decor(m, "SubSign", V(12, 2.2, 0.6), V(0, 3, 239.6), C.Charcoal)
		label(sub, Enum.NormalId.Front, "3 same  →  1 better", C.Gold)
		m.PrimaryPart = Kit.marker(m, "Prompt", V(2, 2, 2), V(0, 4, 238))
	end

	-- Plots: 4 per side, open toward the centre lane. 1-4 west, 5-8 east.
	local Plots = Kit.folder("Plots", Home)
	local PX0, PW, PD = 40, 60, 50
	local id = 0
	for _, s in { -1, 1 } do
		for k = 0, 3 do
			id += 1
			local zc = 30 + k * 54
			local accent = Kit.ACCENTS[id]
			local function at(u, v, y) return V(s * (PX0 + u), y or 0, zc + v) end
			local m = Kit.model("Plot" .. id, Plots)
			local floor = part(m, "Floor", V(PW, 0.6, PD), at(PW / 2, 0, 0.3), C.Sand)
			Kit.decor(m, "Border", V(PW + 2, 0.4, 1), at(PW / 2, -PD / 2 - 0.5, 0.2), accent)
			Kit.decor(m, "Border", V(PW + 2, 0.4, 1), at(PW / 2, PD / 2 + 0.5, 0.2), accent)
			Kit.decor(m, "Border", V(1, 0.4, PD), at(-0.5, 0, 0.2), accent)
			Kit.decor(m, "Border", V(1, 0.4, PD), at(PW + 0.5, 0, 0.2), accent)
			local Fence = Kit.folder("Fence", m)
			local FO, GZ = 1.75, 2 -- fence sits outside the floor; neighbours share the fence in the 4-stud gap
			fenceRun(Fence, at(-FO, -PD / 2 - GZ), at(PW, -PD / 2 - GZ), accent)
			if k == 3 then fenceRun(Fence, at(PW, PD / 2 + GZ), at(-FO, PD / 2 + GZ), accent) end
			fenceRun(Fence, at(-FO, -PD / 2 - GZ), at(-FO, -9), accent)
			fenceRun(Fence, at(-FO, 9), at(-FO, PD / 2 + GZ), accent)
			part(m, "SignPost", V(1.2, 9, 1.2), at(-2.3, 12, 4.5), C.WoodDark)
			local sg = Kit.decor(m, "Sign", V(0.8, 4.5, 12), at(-3.3, 12, 10), C.Cream)
			label(sg, s < 0 and Enum.NormalId.Right or Enum.NormalId.Left, "Plot " .. id, C.Charcoal)
			Kit.decor(m, "SignTrim", V(1, 0.6, 12.8), at(-3.4, 12, 12.55), accent)
			Kit.decor(m, "SignTrim", V(1, 0.6, 12.8), at(-3.4, 12, 7.45), accent)
			Kit.marker(m, "SpawnPoint", V(4, 1, 4), CFrame.lookAt(at(6, 0, 3), at(-10, 0, 3)))
			local bench
			if benchTemplate then
				bench = Kit.palettize(benchTemplate:Clone())
				bench:PivotTo(CFrame.lookAt(at(8, -17, 0.6), at(-10, -17, 0.6)))
				local bcf, bsize = bench:GetBoundingBox()
				bench:PivotTo(bench:GetPivot() + V(0, 0.6 - (bcf.Y - bsize.Y / 2), 0))
			else
				bench = Kit.model("BenchPress", nil)
				bench.PrimaryPart = part(bench, "Seat", V(3, 2, 7), at(8, -17, 1.6), C.BarnRed)
				part(bench, "Rack", V(7, 6, 1), at(8, -19.5, 3.6), C.Slate)
				Kit.marker(bench, "Prompt", V(2, 2, 2), at(4, -17, 3))
				local us = Kit.decor(bench, "UpgradeSign", V(0.5, 3, 5), at(3, -11, 4), C.Wood)
				label(us, s < 0 and Enum.NormalId.Right or Enum.NormalId.Left, "Upgrade")
			end
			bench.Name = "BenchPress"
			bench.Parent = m
			local pads = Kit.folder("SafePads", m)
			for i = 1, 6 do
				local pad = Kit.decor(pads, "Pad" .. i, V(0.4, 6.5, 6.5), CFrame.new(at(6 + (i - 1) * 8.5, 20, 0.8)) * CFrame.Angles(0, 0, math.rad(90)),
					C.Gold, { Shape = Enum.PartType.Cylinder })
				if i > 2 then pad.Transparency = 1 end
			end
			local slots = Kit.folder("Slots", m)
			local n = 0
			for _, v in { -18, -10.5, -3, 4.5 } do
				for _, u in { 17, 24.5, 32, 39.5, 47 } do
					n += 1
					Kit.marker(slots, "Slot" .. n, V(1, 1, 1), CFrame.lookAt(at(u, v, 0.6), at(u - 10, v, 0.6)))
				end
			end
			part(m, "ShowcaseBase", V(10, 1, 10), at(54.5, 13, 1.1), accent)
			part(m, "Showcase", V(8.5, 1, 8.5), at(54.5, 13, 2.1), C.Gold)
			m.PrimaryPart = floor
			m:SetAttribute("PlotId", id)
			m:SetAttribute("Owner", 0)
		end
	end
	-- lamps along the lane
	for z = 40, LOBBY_Z - 40, 54 do
		for _, s in { -1, 1 } do
			local post = PropSet and PropSet:FindFirstChild("LanternPost")
			if post then
				Kit.place(post, CFrame.new(s * 30, 0, z), HLight)
			else
				part(HLight, "LampPost", V(1, 11, 1), V(s * 30, 5.5, z), C.WoodDark)
				Kit.lamp(HLight, "Lamp", V(1.8, 1.8, 1.8), V(s * 30, 12, z))
			end
		end
	end
	for _, s in { -1, 1 } do -- bounds beside the gate
		Kit.bound(Bounds, V(LOBBY_X - GATE, 400, 2), V(s * (LOBBY_X + GATE) / 2, 200 + WALL_H, -2))
	end

	---------------------------------------------------------------- STAGES
	local Stages = Kit.folder("Stages", Map)
	local function stage(name, index, z0, z1, half, recommended)
		local f = zone(name, Stages)
		f:SetAttribute("StageId", name)
		f:SetAttribute("Index", index)
		f:SetAttribute("ZStart", z0)
		f:SetAttribute("ZEnd", z1)
		f:SetAttribute("HalfWidth", half)
		f:SetAttribute("RecommendedSize", recommended)
		return f, Kit.folder("Spawns", f), Kit.folder("SafeSpawns", f), Kit.folder("ChaserPosts", f)
	end

	-- STAGE 1: Ranch Trail (1880). Dirt path through a meadow, red barn walls.
	do
		local Z0, Z1, H = 0, S1_END, S1_HALF
		local f, spawns, safes, posts = stage("RanchTrail", 1, Z0, Z1, H, 10)
		local St = f.Structure
		Kit.ground(St, "Meadow", -H, H, Z1, Z0, C.Grass, 60, C.GrassDark, { 16, H - FRONT_STAGE })
		Kit.decor(St, "Path", V(24, 0.1, Z0 - Z1), V(0, 0.05, (Z0 + Z1) / 2), C.Dirt, { CastShadow = false })
		for _, s in { -1, 1 } do -- worn lips along the path edge
			for z = Z0 - 10, Z1 + 10, -24 do
				Kit.decor(St, "PathLip", V(3, 0.1, rng:NextInteger(8, 16)), V(s * 13.5, 0.05, z), C.Sand, { CastShadow = false })
			end
		end
		sideWalls(St, Z0 - 6, Z1, H, C.BarnRed)
		for _, s in { -1, 1 } do
			facadeRow(St, { "BarnDoors", "Fence", "BarnSide", "Silo", "Fence", "BarnSide", "BarnDoors", "Silo" }, Z1 + 4, Z0 - 10, s * H, -s, false, s > 0 and 3 or 1)
		end
		local order = { "Bucket", "HayBale", "Bucket", "HayBale", "Bucket", "Cactus", "Bucket", "HayBale", "Scarecrow", "Bucket", "Cactus", "HayBale",
			"Bucket", "Scarecrow", "Cactus", "HayBale", "CoveredWagon", "Bucket", "Scarecrow", "Cactus", "HayBale", "Scarecrow", "Cactus", "CoveredWagon" }
		spawnMarker(spawns, "Bucket", 14, 0, -24, 10) -- the tutorial bucket, just outside the gate
		for i = 2, #order do
			local oid = order[i]
			local s = i % 2 == 0 and -1 or 1
			local z = -70 - (i - 2) * 10
			local x = oid == "CoveredWagon" and s * 34 or s * rng:NextInteger(14, H - FRONT_STAGE - 4)
			spawnMarker(spawns, oid, x, 0, z, oid == "CoveredWagon" and 0 or rng:NextInteger(-25, 25))
		end
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(-8, 0, -120))
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(6, 0, -240))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(0, 0, -150))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(-6, 0, -275))
	end

	-- TRANSITION: the trail widens into the main street; barn red gives way to plank fronts.
	do
		local f = zone("Transition1", Stages)
		local St = f.Structure
		local halves = { 60, 64, 68, 72 }
		local prev = S1_HALF
		for i, half in halves do
			local z0 = S1_END - (i - 1) * 10
			local z1 = z0 - 10
			local color = i <= 2 and C.BarnRed or C.Wood
			sideWalls(St, z0, z1, half, color)
			for _, s in { -1, 1 } do -- the jog facing the lobby side
				local a0, a1 = s > 0 and prev + 6 or -half - 6, s > 0 and half + 6 or -prev - 6
				Kit.wall(St, "Jog", a0, a1, z0, -1, true, WALL_H, color)
				Kit.decor(St, "JogPost", V(1.6, WALL_H - 2, 1.6), V(s * (half - 0.8), (WALL_H - 2) / 2, z0 - 0.8), C.WoodDark)
			end
			Kit.ground(St, "Ground", -half, half, z1, z0, i <= 2 and C.Grass or C.Dirt, 2, i <= 2 and C.GrassDark or C.Sand, { 12 + i * 8.5 + 1, half - 2 })
			local pathHalf = 12 + i * 8.5
			Kit.decor(St, "Path", V(pathHalf * 2, 0.1, 10), V(0, 0.05, (z0 + z1) / 2), C.Dirt, { CastShadow = false })
			prev = half
		end
		arch(St, "YearArch", S1_END - 25, 65, "COWBOY TOWN  ·  1880", "SIZE 300+", C.Wood)
	end

	-- STAGE 2: Cowboy Town (1880). Wide dirt street, boardwalks, false-front shops as walls.
	do
		local Z0, Z1, H = S2_START, S2_END, S2_HALF
		local f, spawns, safes, posts = stage("CowboyTown", 2, Z0, Z1, H, 300)
		local St = f.Structure
		Kit.ground(St, "Street", -H, H, Z1, Z0, C.Dirt, 60, C.Sand, { 10, H - 26 })
		local BW = 0.6
		for _, s in { -1, 1 } do
			local ZE = Z1 + 8 -- the end-wall facade needs the last 8 studs
			part(St, "Boardwalk", V(24, BW, Z0 - ZE), V(s * (H - 12), BW / 2, (Z0 + ZE) / 2), C.Wood)
			for z = Z0 - 2, ZE + 2, -2 do -- plank lines
				Kit.decor(St, "PlankLine", V(24, 0.05, 0.3), V(s * (H - 12), BW + 0.025, z), C.WoodDark, { CastShadow = false })
			end
			Kit.decor(St, "BoardwalkEdge", V(1, BW + 0.3, Z0 - ZE), V(s * (H - 24.5), (BW + 0.3) / 2, (Z0 + ZE) / 2), C.WoodDark)
			Kit.bound(Bounds, V(2, 400, Z0 - Z1), V(s * (H + 1), 200 + WALL_H, (Z0 + Z1) / 2))
			Kit.wall(St, "Wall", Z1, Z0, s * H, -s, false, WALL_H, C.Wood)
			part(St, "WallCap", V(8, 2, Z0 - Z1), V(s * (H + 3), WALL_H + 1, (Z0 + Z1) / 2), C.Grass)
			facadeRow(St, { "WestBank", "WestHotel", "WestStore", "WestJail", "WestSheriff", "WestBlacksmith", "WestBarber", "WestStables" }, Z1 + 4, Z0 - 4, s * H, -s, false, s > 0 and 5 or 1)
		end
		for _, x in { -9, 9 } do -- wagon ruts
			Kit.decor(St, "Rut", V(1.4, 0.1, Z0 - Z1 - 8), V(x, 0.05, (Z0 + Z1) / 2), C.Sand, { CastShadow = false })
		end
		local order = { "WaterTrough", "Outhouse", "WaterTrough", "Stagecoach", "Outhouse", "WaterTrough", "WaterTower", "WaterTrough", "Outhouse", "Stagecoach", "WaterTrough",
			"Saloon", "Outhouse", "WaterTrough", "WaterTower", "Stagecoach", "Outhouse", "WaterTrough", "Outhouse", "Stagecoach", "WaterTower", "Saloon" }
		local band = { WaterTrough = H - 27, Outhouse = H - 24, Stagecoach = 20, WaterTower = H - 21, Saloon = H - 21 }
		for i, oid in order do
			local s = i % 2 == 0 and -1 or 1
			local z = Z0 - 24 - (i - 1) * 14
			local x = s * band[oid]
			local y = math.abs(x) > H - 24 and BW or 0
			local yaw = (oid == "Stagecoach") and 0 or (s > 0 and 90 or -90)
			spawnMarker(spawns, oid, x, y, z, yaw)
		end
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(-8, 0, Z0 - 110))
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(9, 0, Z0 - 260))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(0, 0, Z0 - 170))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(-12, 0, Z1 + 30))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(12, 0, Z1 + 24))
		-- end of the road for now
		Kit.wall(St, "EndWall", -H - 6, H + 6, Z1, 1, true, WALL_H, C.Slate)
		if Facades and Facades:FindFirstChild("EndWall") then
			local m = Kit.place(Facades.EndWall, CFrame.new(0, 0, Z1), St)
			local sp = m:FindFirstChild("Sign", true)
			if sp then label(sp, Enum.NormalId.Back, "CASTLE VILLAGE · 1250  —  COMING SOON", C.Charcoal) end
		else
			sign(St, Z1, 1, true, 0, 30, 70, 12, "CASTLE VILLAGE  ·  1250", C.Sky)
			sign(St, Z1, 1, true, 0, 18, 40, 7, "COMING SOON", C.Gold, C.Charcoal)
		end
		Kit.bound(Bounds, V(H * 2, 400, 2), V(0, 200 + WALL_H, Z1 - 1))
	end

	---------------------------------------------------------------- lighting
	local L = game:GetService("Lighting")
	L.ClockTime = 14.2
	L.Brightness = 2.8
	L.Ambient = Color3.fromRGB(110, 112, 124)
	L.OutdoorAmbient = Color3.fromRGB(150, 152, 162)
	local atm = L:FindFirstChildOfClass("Atmosphere")
	if atm then atm.Density = 0.1; atm.Haze = 0; atm.Offset = 0; atm.Glare = 0 end
	local dof = L:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
	local cc = L:FindFirstChild("MapColor") or Instance.new("ColorCorrectionEffect")
	cc.Name = "MapColor"; cc.Saturation = 0.2; cc.Contrast = 0.08; cc.Parent = L

	Map.Parent = workspace

	---------------------------------------------------------------- zone dressing
	local B = game.ServerScriptService:FindFirstChild("Build")
	local Scatter
	if B and B:FindFirstChild("BuildFoliage") and Assets and Assets:FindFirstChild("Foliage") then
		local ok, res = pcall(function() return loadstring(B.BuildFoliage.Source)() end)
		if ok and type(res) == "function" then
			local ok2, mod = pcall(res, Kit)
			if ok2 and type(mod) == "table" then Scatter = mod.Scatter end
		end
	end
	local ctx = {
		map = Map, Scatter = Scatter, propSet = PropSet, facades = Facades,
		lobby = { x = LOBBY_X, z = LOBBY_Z, gate = GATE, plotX0 = PX0, plotW = PW, plotD = PD, frontage = FRONT_LOBBY },
		ranch = { z0 = 0, z1 = S1_END, half = S1_HALF, pathHalf = 12, frontage = FRONT_STAGE },
		transition = { z0 = S1_END, z1 = S2_START },
		town = { z0 = S2_START, z1 = S2_END, half = S2_HALF, boardwalk = 24, frontage = FRONT_STAGE },
	}
	local dressed = {}
	for _, name in { "ZoneLobby", "ZoneRanch", "ZoneTown" } do
		local script = B and B:FindFirstChild(name)
		if script then
			local ok, err = pcall(function() return loadstring(script.Source)()(Kit, ctx) end)
			table.insert(dressed, name .. ": " .. tostring(ok and err or ("ERROR " .. tostring(err))))
		end
	end

	local n = 0
	for _, d in Map:GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
	end
	return "Map built: " .. n .. " parts" .. (#dressed > 0 and ("\n" .. table.concat(dressed, "\n")) or "")
end
