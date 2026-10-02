--!nonstrict
-- Edit-time map builder (plan v4 §2). Rebuilds workspace.Map from scratch.
-- Run from Studio (Edit):
--   local B = game.ServerScriptService.Build
--   local Kit = loadstring(B.Kit.Source)()
--   return loadstring(B.BuildMap.Source)()(Kit)
-- Road runs toward -Z, lobby at z >= 0, ground top at y = 0, x = 0 is the road centre.

return function(Kit)
	local V, rgb, part, label = Kit.V, Kit.rgb, Kit.part, Kit.label
	local rng = Kit.rng
	Kit.ensureStuds()

	for _, name in { "Map", "StudTest", "Baseplate" } do
		local old = workspace:FindFirstChild(name)
		if old then old:Destroy() end
	end
	local cone = workspace:FindFirstChild("TrafficCone")
	if cone then cone.Parent = game:GetService("ServerStorage") end

	local Map = Instance.new("Folder")
	Map.Name = "Map"
	local Bounds = Kit.folder("Bounds", Map)
	local WALL_H = 56

	-- Palette
	local GRASS = rgb(96, 214, 66)
	local HEDGE = rgb(88, 196, 60)
	local DIRT = rgb(196, 142, 88)
	local WOOD = rgb(168, 112, 66)
	local DARKWOOD = rgb(112, 70, 42)
	local WHITE = rgb(245, 245, 240)
	local GLASS = rgb(40, 52, 96)
	local GOLD = rgb(255, 196, 40)

	---------------------------------------------------------------- helpers
	-- Flat relief on a wall. Wall plane is x = at (alongX false) or z = at (alongX true);
	-- inward (+1/-1) is the side players see. along/y are the centre; w x h the size.
	local function plate(parent, name, at, inward, alongX, along, y, w, h, color, depth, opts)
		depth = depth or 0.6
		local c = at + inward * depth / 2
		local size = alongX and V(w, h, depth) or V(depth, h, w)
		local pos = alongX and V(along, y, c) or V(c, y, along)
		opts = opts or {}
		if opts.CanCollide == nil then opts.CanCollide = false end
		return part(parent, name, size, pos, color, opts)
	end
	local function inwardFace(inward, alongX)
		if alongX then return inward > 0 and Enum.NormalId.Back or Enum.NormalId.Front end
		return inward > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	end
	local function window(parent, at, inward, alongX, along, y, shutter)
		plate(parent, "WindowFrame", at, inward, alongX, along, y, 8, 10, WHITE, 0.6)
		plate(parent, "WindowGlass", at, inward, alongX, along, y, 6, 8, GLASS, 0.9)
		plate(parent, "WindowBar", at, inward, alongX, along, y, 0.6, 8, WHITE, 1.1)
		plate(parent, "WindowBar", at, inward, alongX, along, y, 6, 0.6, WHITE, 1.1)
		if shutter then
			plate(parent, "Shutter", at, inward, alongX, along - 5.6, y, 3, 10, shutter, 0.9)
			plate(parent, "Shutter", at, inward, alongX, along + 5.6, y, 3, 10, shutter, 0.9)
		end
	end
	local function door(parent, at, inward, alongX, along, color, trim)
		plate(parent, "DoorFrame", at, inward, alongX, along, 7, 9, 14, trim or WHITE, 0.6)
		plate(parent, "Door", at, inward, alongX, along, 6.5, 7, 13, color, 0.9)
		plate(parent, "Knob", at, inward, alongX, along + 2.2, 6, 0.8, 0.8, GOLD, 1.3)
	end
	local function sign(parent, at, inward, alongX, along, y, w, h, text, color, textColor)
		local p = plate(parent, "Sign", at, inward, alongX, along, y, w, h, color, 1)
		label(p, inwardFace(inward, alongX), text, textColor or WHITE)
		return p
	end
	local function lantern(parent, at, inward, alongX, along, y)
		plate(parent, "LanternArm", at, inward, alongX, along, y + 1.6, 0.6, 0.6, rgb(50, 50, 60), 2.4)
		local c = at + inward * 2.2
		part(parent, "Lantern", V(1.6, 2.2, 1.6), alongX and V(along, y, c) or V(c, y, along), rgb(255, 214, 120), { Material = Kit.NEON, CanCollide = false })
	end
	-- Side walls of a corridor section (z0 > z1), both sides at +-half.
	local function sideWalls(parent, z0, z1, half, color, cap)
		for _, s in { -1, 1 } do
			Kit.wall(parent, "Wall", z1, z0, s * half, -s, false, WALL_H, color)
			part(parent, "WallCap", V(8, 2, z0 - z1), V(s * (half + 3), WALL_H + 1, (z0 + z1) / 2), cap or GRASS)
			Kit.bound(Bounds, V(2, 400, z0 - z1), V(s * (half + 1), 200 + WALL_H, (z0 + z1) / 2))
		end
	end
	-- Year arch across the road at z with pillars at +-half.
	local function arch(parent, z, half, text, sub, color)
		local m = Kit.model("Arch", parent)
		for _, s in { -1, 1 } do
			part(m, "Pillar", V(8, 50, 8), V(s * (half - 4), 25, z), color)
			part(m, "PillarCap", V(10, 3, 10), V(s * (half - 4), 51.5, z), WHITE)
		end
		local beam = part(m, "Beam", V(half * 2, 10, 6), V(0, 46, z), color)
		label(beam, Enum.NormalId.Back, text, WHITE, 8)
		label(beam, Enum.NormalId.Front, text, WHITE, 8)
		part(m, "BeamTrim", V(half * 2 + 2, 1.5, 7), V(0, 40.5, z), WHITE)
		if sub then
			local board = part(m, "SizeSign", V(26, 6, 1), V(0, 35.5, z), rgb(40, 44, 60), { CanCollide = false })
			label(board, Enum.NormalId.Back, sub, GOLD)
			part(m, "Chain", V(0.5, 2.5, 0.5), V(-10, 39.2, z), rgb(60, 60, 70), { CanCollide = false })
			part(m, "Chain", V(0.5, 2.5, 0.5), V(10, 39.2, z), rgb(60, 60, 70), { CanCollide = false })
		end
		return m
	end
	local function spawnMarker(folder, id, x, y, z, yaw)
		local m = Kit.marker(folder, id, V(2, 1, 2), CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw or 0), 0))
		m:SetAttribute("ObjectId", id)
		return m
	end
	-- Market stall, counter facing -Z (toward the gate).
	local function stall(parent, name, x, z, color, text)
		local m = Kit.model(name, parent)
		for _, dx in { -7, 7 } do
			for _, dz in { -4, 4 } do part(m, "Post", V(1.4, 11, 1.4), V(x + dx, 5.5, z + dz), DARKWOOD) end
		end
		part(m, "Counter", V(16, 4, 3), V(x, 2, z - 4), WOOD)
		part(m, "CounterTop", V(17, 0.8, 4), V(x, 4.4, z - 4), rgb(120, 120, 130))
		part(m, "Back", V(16, 9, 1), V(x, 4.5, z + 4.5), WOOD)
		for i = 0, 4 do
			local c = i % 2 == 0 and color or WHITE
			part(m, "Awning", V(3.4, 0.8, 13), CFrame.new(x - 6.8 + i * 3.4, 11.6, z - 1) * CFrame.Angles(math.rad(12), 0, 0), c)
		end
		local s = part(m, "Sign", V(16, 4, 0.8), V(x, 15.5, z - 6), color, { CanCollide = false })
		label(s, Enum.NormalId.Front, text)
		part(m, "Ring", V(0.3, 18, 18), CFrame.new(x, 0.3, z - 14) * CFrame.Angles(0, 0, math.rad(90)), color,
			{ Material = Kit.NEON, Shape = Enum.PartType.Cylinder, Transparency = 0.5, CanCollide = false })
		local prompt = Kit.marker(m, "Prompt", V(2, 2, 2), V(x, 4, z - 7))
		m.PrimaryPart = prompt
		return m
	end

	---------------------------------------------------------------- LOBBY (Home)
	local LOBBY_X, LOBBY_Z = 100, 262
	local GATE = 34 -- half-width of the gate opening = Ranch Trail half-width
	local Home = Kit.folder("Home", Map)
	Kit.ground(Home, "Grass", -LOBBY_X, LOBBY_X, 0, LOBBY_Z, GRASS)
	local path = part(Home, "Path", V(18, 0.3, LOBBY_Z - 40), V(0, 0.1, (LOBBY_Z - 40) / 2), DIRT, { CanCollide = false })
	path.CastShadow = false

	local zone = Kit.marker(Home, "SafeZone", V(LOBBY_X * 2, 200, LOBBY_Z), V(0, 100, LOBBY_Z / 2))
	zone:SetAttribute("GateZ", 0)

	-- Walls: sides, back, front with the gate opening
	local HomeWalls = Kit.folder("Walls", Home)
	for _, s in { -1, 1 } do
		Kit.wall(HomeWalls, "Wall", 0, LOBBY_Z, s * LOBBY_X, -s, false, WALL_H, HEDGE)
		part(HomeWalls, "WallCap", V(8, 2, LOBBY_Z + 12), V(s * (LOBBY_X + 3), WALL_H + 1, LOBBY_Z / 2), GRASS)
		Kit.wall(HomeWalls, "Wall", s > 0 and GATE or -LOBBY_X, s > 0 and LOBBY_X or -GATE, 0, 1, true, WALL_H, HEDGE)
		Kit.bound(Bounds, V(2, 400, LOBBY_Z), V(s * (LOBBY_X + 1), 200 + WALL_H, LOBBY_Z / 2))
		-- windows and lanterns between the plots
		for k = 0, 3 do
			local zc = 30 + k * 54
			window(HomeWalls, s * LOBBY_X, -s, false, zc, 26, rgb(64, 150, 70))
			lantern(HomeWalls, s * LOBBY_X, -s, false, zc + 27, 20)
		end
		window(HomeWalls, 0, 1, true, s * 62, 26, rgb(64, 150, 70))
		door(HomeWalls, 0, 1, true, s * 84, rgb(60, 140, 60))
	end
	Kit.wall(HomeWalls, "Wall", -LOBBY_X, LOBBY_X, LOBBY_Z, -1, true, WALL_H, rgb(240, 150, 70))
	part(HomeWalls, "WallCap", V(LOBBY_X * 2 + 12, 2, 8), V(0, WALL_H + 1, LOBBY_Z + 3), GRASS)
	Kit.bound(Bounds, V(LOBBY_X * 2, 400, 2), V(0, 200 + WALL_H, LOBBY_Z + 1))

	-- Gate arch and the safe-zone line
	arch(Home, 0, GATE + 4, "RANCH TRAIL  ·  1880", nil, rgb(70, 110, 210)).Name = "GiantGate"
	part(Home, "SafeLine", V(GATE * 2, 0.3, 1.5), V(0, 0.15, 1), rgb(255, 70, 70), { Material = Kit.NEON, CanCollide = false })
	local safeText = Kit.marker(Home, "SafeText", V(40, 0.2, 8), V(0, 0.2, 9))
	label(safeText, Enum.NormalId.Top, "SAFE ZONE", rgb(140, 230, 255)).Rotation = 180

	-- Leaderboards on the back wall
	local Boards = Kit.folder("Boards", Home)
	for _, b in { { "Richest", -72, "RICHEST", rgb(60, 190, 90) }, { "Biggest", 72, "BIGGEST", rgb(70, 150, 240) } } do
		local frame = plate(Boards, b[1] .. "Frame", LOBBY_Z, -1, true, b[2], 24, 34, 30, DARKWOOD, 1)
		frame.Name = b[1] .. "Frame"
		local board = plate(Boards, b[1], LOBBY_Z, -1, true, b[2], 22, 30, 20, rgb(250, 250, 245), 1.4)
		sign(Boards, LOBBY_Z, -1, true, b[2], 35.5, 30, 5, b[3], b[4]).Name = b[1] .. "Title"
		board:SetAttribute("Board", b[1])
	end

	-- Stations along the back
	local Stations = Kit.folder("Stations", Home)
	stall(Stations, "Sell", -30, 244, rgb(230, 60, 60), "SELL")
	stall(Stations, "Shop", 30, 244, rgb(70, 200, 90), "SHOP")
	stall(Stations, "Footprints", 60, 244, rgb(250, 150, 50), "FOOTPRINTS")
	do -- Crusher: hopper on a machine with two rollers
		local m = Kit.model("Crusher", Stations)
		part(m, "Base", V(14, 5, 12), V(0, 2.5, 246), rgb(70, 76, 96))
		part(m, "Body", V(12, 6, 10), V(0, 8, 246), rgb(90, 110, 200))
		for _, dx in { -2.6, 2.6 } do
			part(m, "Roller", V(9, 5, 5), CFrame.new(dx, 12.5, 246) * CFrame.Angles(0, math.rad(90), 0), rgb(200, 200, 210), { Shape = Enum.PartType.Cylinder })
		end
		part(m, "HopperL", V(1.5, 6, 10), CFrame.new(-6.5, 15, 246) * CFrame.Angles(0, 0, math.rad(-18)), GOLD)
		part(m, "HopperR", V(1.5, 6, 10), CFrame.new(6.5, 15, 246) * CFrame.Angles(0, 0, math.rad(18)), GOLD)
		part(m, "Light", V(2, 2, 2), V(0, 9, 240.5), rgb(120, 255, 120), { Material = Kit.NEON, CanCollide = false })
		local s = part(m, "Sign", V(14, 4, 0.8), V(0, 21, 241), rgb(90, 110, 200), { CanCollide = false })
		label(s, Enum.NormalId.Front, "CRUSHER")
		local sub = part(m, "SubSign", V(12, 2.2, 0.6), V(0, 3, 239.6), rgb(40, 44, 60), { CanCollide = false })
		label(sub, Enum.NormalId.Front, "3 same  →  1 better", GOLD)
		m.PrimaryPart = Kit.marker(m, "Prompt", V(2, 2, 2), V(0, 4, 238))
	end

	-- Plots: 4 per side along the lobby, open toward the centre lane. 1-4 west, 5-8 east.
	local ACCENTS = {
		rgb(240, 80, 80), rgb(250, 160, 50), rgb(250, 220, 60), rgb(110, 220, 90),
		rgb(70, 200, 230), rgb(80, 120, 240), rgb(170, 100, 240), rgb(250, 120, 200),
	}
	local Plots = Kit.folder("Plots", Home)
	local benchTemplate = game.ReplicatedStorage:FindFirstChild("Assets")
		and game.ReplicatedStorage.Assets:FindFirstChild("Props")
		and game.ReplicatedStorage.Assets.Props:FindFirstChild("BenchPress")
	local PX0, PW, PD = 38, 60, 50 -- front edge |x|, depth along X, width along Z
	local id = 0
	for _, s in { -1, 1 } do
		for k = 0, 3 do
			id += 1
			local zc = 30 + k * 54
			local accent = ACCENTS[id]
			local function at(u, v, y) return V(s * (PX0 + u), y or 0, zc + v) end
			local m = Kit.model("Plot" .. id, Plots)
			local floor = part(m, "Floor", V(PW, 0.6, PD), at(PW / 2, 0, 0.3), rgb(232, 198, 140))
			part(m, "Border", V(PW + 2, 0.4, PD + 2), at(PW / 2, 0, 0.15), accent, { CanCollide = false })
			-- fence: two sides and the front with a gap
			local function fence(u0, v0, u1, v1)
				local a, b = at(u0, v0), at(u1, v1)
				local d = b - a
				local n = math.max(1, math.round(d.Magnitude / 10))
				for i = 0, n do
					local p = a + d * (i / n)
					part(m, "Post", V(1.4, 5, 1.4), p + V(0, 2.5, 0), WHITE)
					part(m, "PostCap", V(1.8, 0.8, 1.8), p + V(0, 5.4, 0), accent)
				end
				local mid = (a + b) / 2
				local size = math.abs(d.X) > math.abs(d.Z) and V(d.Magnitude, 0.9, 0.7) or V(0.7, 0.9, d.Magnitude)
				part(m, "Rail", size, mid + V(0, 3.6, 0), accent)
				part(m, "Rail", size, mid + V(0, 1.6, 0), WHITE)
			end
			fence(0, -PD / 2, PW, -PD / 2)
			fence(0, PD / 2, PW, PD / 2)
			fence(0, -PD / 2, 0, -9)
			fence(0, 9, 0, PD / 2)
			-- sign beside the entrance, facing the lane
			part(m, "SignPost", V(1.2, 9, 1.2), at(-1.5, 12, 4.5), DARKWOOD)
			local sg = part(m, "Sign", V(0.8, 4.5, 12), at(-1.5, 12, 10), WHITE, { CanCollide = false })
			label(sg, s < 0 and Enum.NormalId.Right or Enum.NormalId.Left, "Plot " .. id, rgb(40, 44, 60))
			part(m, "SignTrim", V(1, 5.3, 12.8), at(-1.4, 12, 10), accent, { CanCollide = false })
			Kit.marker(m, "SpawnPoint", V(4, 1, 4), CFrame.lookAt(at(6, 0, 3), at(-10, 0, 3)))
			-- bench press (front corner)
			local bench
			if benchTemplate then
				bench = benchTemplate:Clone()
				bench:PivotTo(CFrame.lookAt(at(8, -17, 0.6), at(-10, -17, 0.6)))
				local bcf, bsize = bench:GetBoundingBox() -- its pivot is the seat, so lift it onto the floor
				bench:PivotTo(bench:GetPivot() + V(0, 0.6 - (bcf.Y - bsize.Y / 2), 0))
			else
				bench = Kit.model("BenchPress", nil)
				bench.PrimaryPart = part(bench, "Seat", V(3, 2, 7), at(8, -17, 1.6), rgb(220, 60, 60))
				part(bench, "Rack", V(7, 6, 1), at(8, -19.5, 3.6), rgb(90, 96, 110))
				Kit.marker(bench, "Prompt", V(2, 2, 2), at(4, -17, 3))
				local us = part(bench, "UpgradeSign", V(0.5, 3, 5), at(3, -11, 4), WOOD, { CanCollide = false })
				label(us, s < 0 and Enum.NormalId.Right or Enum.NormalId.Left, "Upgrade")
			end
			bench.Name = "BenchPress"
			bench.Parent = m
			-- safe pads along one side
			local pads = Kit.folder("SafePads", m)
			for i = 1, 6 do
				local pad = part(pads, "Pad" .. i, V(0.5, 6.5, 6.5), CFrame.new(at(6 + (i - 1) * 8.5, 20, 0.85)) * CFrame.Angles(0, 0, math.rad(90)),
					GOLD, { Shape = Enum.PartType.Cylinder, CanCollide = false })
				if i > 2 then pad.Transparency = 1 end
			end
			-- display slots (5 x 4) and the showcase podium
			local slots = Kit.folder("Slots", m)
			local n = 0
			for _, v in { -18, -10.5, -3, 4.5 } do
				for _, u in { 17, 24.5, 32, 39.5, 47 } do
					n += 1
					Kit.marker(slots, "Slot" .. n, V(1, 1, 1), CFrame.lookAt(at(u, v, 0.6), at(u - 10, v, 0.6)))
				end
			end
			part(m, "ShowcaseBase", V(10, 1, 10), at(54.5, 13, 1.1), accent)
			part(m, "Showcase", V(8.5, 1, 8.5), at(54.5, 13, 2.1), GOLD)
			m.PrimaryPart = floor
			m:SetAttribute("PlotId", id)
			m:SetAttribute("Owner", 0)
		end
	end

	---------------------------------------------------------------- STAGES
	local Stages = Kit.folder("Stages", Map)
	local function stage(name, index, z0, z1, half, recommended)
		local f = Kit.folder(name, Stages)
		f:SetAttribute("StageId", name)
		f:SetAttribute("Index", index)
		f:SetAttribute("ZStart", z0)
		f:SetAttribute("ZEnd", z1)
		f:SetAttribute("HalfWidth", half)
		f:SetAttribute("RecommendedSize", recommended)
		return f, Kit.folder("Spawns", f), Kit.folder("SafeSpawns", f), Kit.folder("ChaserPosts", f)
	end

	-- STAGE 1: Ranch Trail (1880). Narrow dirt path through a meadow, red barn walls.
	local BARN = rgb(190, 62, 52)
	do
		local Z0, Z1, H = 0, -170, GATE
		local f, spawns, safes, posts = stage("RanchTrail", 1, Z0, Z1, H, 10)
		Kit.ground(f, "Meadow", -H, H, Z1, Z0, rgb(140, 206, 72))
		part(f, "Path", V(18, 0.3, Z0 - Z1), V(0, 0.1, (Z0 + Z1) / 2), DIRT, { CanCollide = false, CastShadow = false })
		for _ = 1, 14 do -- worn edges of the path
			local z = rng:NextNumber(Z1 + 6, Z0 - 6)
			part(f, "PathEdge", V(4, 0.3, rng:NextInteger(6, 14)), V((rng:NextNumber() < 0.5 and -1 or 1) * 10.5, 0.1, z), DIRT, { CanCollide = false, CastShadow = false })
		end
		sideWalls(f, Z0 - 6, Z1, H, BARN, rgb(96, 70, 60))
		for _, s in { -1, 1 } do
			local x, inw = s * H, -s
			plate(f, "Trim", x, inw, false, (Z0 + Z1) / 2 - 3, WALL_H - 2, Z0 - Z1 - 6, 3, WHITE, 0.8)
			plate(f, "Trim", x, inw, false, (Z0 + Z1) / 2 - 3, 1.5, Z0 - Z1 - 6, 3, WHITE, 0.8)
			for z = Z0 - 20, Z1 + 10, -28 do
				plate(f, "Batten", x, inw, false, z, WALL_H / 2, 2.5, WALL_H, WHITE, 0.8)
			end
			for i, z in { -34, -90, -146 } do
				if (i + (s > 0 and 1 or 0)) % 2 == 0 then
					-- barn door with X bracing
					plate(f, "BarnDoor", x, inw, false, z, 10, 18, 20, rgb(150, 44, 40), 0.7)
					plate(f, "DoorTrim", x, inw, false, z, 20.5, 20, 1.6, WHITE, 1)
					plate(f, "DoorTrim", x, inw, false, z - 9.2, 10, 1.6, 20, WHITE, 1)
					plate(f, "DoorTrim", x, inw, false, z + 9.2, 10, 1.6, 20, WHITE, 1)
					for _, a in { 48, -48 } do
						local c = x + inw * 0.55
						part(f, "Brace", V(1.1, 26, 1.6), CFrame.new(c, 10, z) * CFrame.Angles(math.rad(a), 0, 0), WHITE, { CanCollide = false })
					end
					window(f, x, inw, false, z, 36)
				else
					window(f, x, inw, false, z, 14, rgb(250, 250, 245))
					plate(f, "HayLoft", x, inw, false, z, 36, 10, 8, rgb(230, 190, 80), 0.9)
					plate(f, "HayLoftTrim", x, inw, false, z, 40.6, 12, 1.4, WHITE, 1.1)
				end
				lantern(f, x, inw, false, z + 14, 18)
			end
			-- rail fence hugging the wall
			for z = Z0 - 12, Z1 + 12, -12 do
				part(f, "FencePost", V(1.2, 5, 1.2), V(s * (H - 1.6), 2.5, z), DARKWOOD)
			end
			for _, y in { 1.8, 3.8 } do
				part(f, "FenceRail", V(0.7, 0.9, Z0 - Z1 - 24), V(s * (H - 1.6), y, (Z0 + Z1) / 2), WOOD, { CanCollide = false })
			end
		end
		local order = { "Bucket", "HayBale", "Bucket", "HayBale", "Bucket", "Cactus", "Bucket", "HayBale", "Scarecrow", "Bucket", "Cactus", "HayBale",
			"Bucket", "Scarecrow", "Cactus", "HayBale", "CoveredWagon", "Bucket", "Scarecrow", "Cactus", "HayBale", "Scarecrow", "Cactus", "CoveredWagon" }
		for i, oid in order do
			local s = i % 2 == 0 and -1 or 1
			local z = -20 - (i - 1) * 6
			local x = oid == "CoveredWagon" and s * 21 or s * rng:NextInteger(13, 27)
			if i == 1 then x = 12 end -- the tutorial bucket, right outside the gate
			spawnMarker(spawns, oid, x, 0, z, oid == "CoveredWagon" and 0 or rng:NextInteger(-25, 25))
		end
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(-6, 0, -58))
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(5, 0, -128))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(0, 0, -86))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(-4, 0, -150))
	end

	-- TRANSITION: the trail widens into the main street; red barn gives way to plank fronts.
	local TOWN = rgb(204, 160, 104)
	do
		local f = Kit.folder("Transition1", Stages)
		local halves = { 39.5, 45, 50.5, 56 }
		local prev = GATE
		for i, half in halves do
			local z0 = -170 - (i - 1) * 10
			local z1 = z0 - 10
			local color = i <= 2 and BARN or WOOD
			sideWalls(f, z0, z1, half, color, i <= 2 and rgb(96, 70, 60) or DARKWOOD)
			for _, s in { -1, 1 } do -- the jog facing the lobby side
				Kit.wall(f, "Jog", s > 0 and prev or -half, s > 0 and half + 6 or -prev, z0, -1, true, WALL_H, color)
			end
			local ground = i <= 2 and rgb(140, 206, 72) or TOWN
			Kit.ground(f, "Ground", -half, half, z1, z0, ground, 2)
			local pathHalf = 9 + i * 5.25
			part(f, "Path", V(pathHalf * 2, 0.3, 10), V(0, 0.1, (z0 + z1) / 2), i <= 2 and DIRT or TOWN, { CanCollide = false, CastShadow = false })
			prev = half
		end
		arch(f, -190, 45 + 4, "COWBOY TOWN  ·  1880", "SIZE 300+", rgb(150, 96, 60)).Name = "YearArch"
	end

	-- STAGE 2: Cowboy Town (1880). Wide dirt street, boardwalks, false-front shops as walls.
	do
		local Z0, Z1, H = -210, -400, 56
		local f, spawns, safes, posts = stage("CowboyTown", 2, Z0, Z1, H, 300)
		Kit.ground(f, "Street", -H, H, Z1, Z0, TOWN)
		local BW = 0.6 -- boardwalk height
		for _, s in { -1, 1 } do
			part(f, "Boardwalk", V(26, BW, Z0 - Z1), V(s * 43, BW / 2, (Z0 + Z1) / 2), WOOD)
			part(f, "BoardwalkEdge", V(1, BW + 0.3, Z0 - Z1), V(s * 30.5, (BW + 0.3) / 2, (Z0 + Z1) / 2), DARKWOOD, { CanCollide = false })
			Kit.bound(Bounds, V(2, 400, Z0 - Z1), V(s * (H + 1), 200 + WALL_H, (Z0 + Z1) / 2))
			-- false fronts: one facade per shop along the wall
			local fronts = { rgb(214, 172, 110), rgb(150, 98, 62), rgb(92, 168, 156), rgb(206, 92, 70), rgb(232, 214, 160), rgb(120, 140, 190) }
			local names = s < 0 and { "BANK", "HOTEL", "GENERAL STORE", "BARBER", "JAIL", "TELEGRAPH" }
				or { "SHERIFF", "BLACKSMITH", "DENTIST", "STABLES", "BAKERY", "POST OFFICE" }
			local z = Z0
			local i = 0
			while z > Z1 + 1 do
				i += 1
				local w = math.min(rng:NextInteger(26, 36), z - Z1)
				if z - w - Z1 < 14 then w = z - Z1 end
				local h = rng:NextInteger(38, WALL_H)
				local color = fronts[(i + (s > 0 and 2 or 0) - 1) % #fronts + 1]
				local x, inw, mid = s * H, -s, z - w / 2
				Kit.wall(f, "Front", z - w, z, x, inw, false, h, color)
				part(f, "FrontCap", V(8, 2, w), V(s * (H + 3), h + 1, mid), DARKWOOD)
				plate(f, "Cornice", x, inw, false, mid, h - 1.5, w, 3, Kit.shade(color, 0.75), 1.2)
				plate(f, "Corner", x, inw, false, z - 0.8, h / 2, 1.6, h, Kit.shade(color, 0.75), 0.9)
				sign(f, x, inw, false, mid, 27, math.min(w - 6, 24), 5, names[(i - 1) % #names + 1], rgb(250, 240, 210), rgb(90, 50, 30))
				door(f, x, inw, false, mid, Kit.shade(color, 0.6), rgb(250, 240, 210))
				if w >= 30 then
					window(f, x, inw, false, mid - 9.5, 8)
					window(f, x, inw, false, mid + 9.5, 8)
				end
				window(f, x, inw, false, mid, 37.5 > h - 8 and h - 10 or 37)
				-- porch roof over the boardwalk
				part(f, "Porch", V(9, 0.8, w - 2), CFrame.new(s * (H - 4.3), 17.5, mid) * CFrame.Angles(0, 0, math.rad(s * 10)), Kit.shade(color, 0.6), { CanCollide = false })
				for _, dz in { -w / 2 + 2, w / 2 - 2 } do
					part(f, "PorchPost", V(1, 16.5, 1), V(s * (H - 8), BW + 8.25, mid + dz), rgb(250, 240, 210))
				end
				lantern(f, x, inw, false, mid + 5.5, 14)
				z -= w
			end
		end
		-- wagon ruts down the street
		for _, x in { -6, 6 } do
			part(f, "Rut", V(1.4, 0.3, Z0 - Z1 - 8), V(x, 0.1, (Z0 + Z1) / 2), Kit.shade(TOWN, 0.85), { CanCollide = false, CastShadow = false })
		end
		local order = { "WaterTrough", "Outhouse", "WaterTrough", "Stagecoach", "Outhouse", "WaterTrough", "WaterTower", "WaterTrough", "Outhouse", "Stagecoach", "WaterTrough",
			"Saloon", "Outhouse", "WaterTrough", "WaterTower", "Stagecoach", "Outhouse", "WaterTrough", "Outhouse", "Stagecoach", "WaterTower", "Saloon" }
		local band = { WaterTrough = 33, Outhouse = 36.5, Stagecoach = 16, WaterTower = 45.5, Saloon = 45.5 }
		for i, oid in order do
			local s = i % 2 == 0 and -1 or 1
			local z = -224 - (i - 1) * 8
			local x = s * band[oid]
			local y = math.abs(x) > 30 and BW or 0
			local yaw = (oid == "Stagecoach") and 0 or (s > 0 and 90 or -90) -- fronts face the street
			spawnMarker(spawns, oid, x, y, z, yaw)
		end
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(-8, 0, -270))
		Kit.marker(safes, "SafeSpawn", V(2, 1, 2), V(9, 0, -352))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(0, 0, -300))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(-10, 0, -378))
		Kit.marker(posts, "ChaserPost", V(2, 1, 2), V(10, 0, -384))
		-- end of the road for now
		Kit.wall(f, "EndWall", -H - 6, H + 6, Z1, 1, true, WALL_H, rgb(150, 150, 160))
		sign(f, Z1, 1, true, 0, 30, 70, 12, "CASTLE VILLAGE  ·  1250", rgb(60, 70, 110))
		sign(f, Z1, 1, true, 0, 18, 40, 7, "COMING SOON", GOLD, rgb(40, 44, 60))
		Kit.bound(Bounds, V(H * 2, 400, 2), V(0, 200 + WALL_H, Z1 - 1))
	end

	---------------------------------------------------------------- lighting
	local L = game:GetService("Lighting")
	L.ClockTime = 14.2
	L.Brightness = 2.8
	L.Ambient = rgb(110, 112, 124)
	L.OutdoorAmbient = rgb(150, 152, 162)
	local atm = L:FindFirstChildOfClass("Atmosphere")
	if atm then atm.Density = 0.1; atm.Haze = 0; atm.Offset = 0; atm.Glare = 0 end
	local dof = L:FindFirstChildOfClass("DepthOfFieldEffect")
	if dof then dof.Enabled = false end
	local cc = L:FindFirstChild("MapColor") or Instance.new("ColorCorrectionEffect")
	cc.Name = "MapColor"; cc.Saturation = 0.2; cc.Contrast = 0.08; cc.Parent = L

	Map.Parent = workspace
	local n = 0
	for _, d in Map:GetDescendants() do
		if d:IsA("BasePart") then n += 1 end
	end
	return "Map built: " .. n .. " parts"
end
