--!nonstrict
-- Build kit shared by the edit-time builders (BuildMap, BuildAssets).
-- Not used at runtime. Run a builder from Studio (Edit) with:
--   local B = game.ServerScriptService.Build
--   local Kit = loadstring(B.Kit.Source)()
--   return loadstring(B.BuildMap.Source)()(Kit)
-- Style (plan v4 §12): blocky stud parts, saturated colours, themed walls.

local Kit = {}

local STUD_MAP = "rbxassetid://98853406976096" -- grey stud tile, tinted by part colour
Kit.V = Vector3.new
Kit.NEON = Enum.Material.Neon
Kit.rng = Random.new(7)

function Kit.rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- Style Bible palette (docs/MAP_REVAMP.md §3). Map builders use these names only;
-- the audit flags any other colour inside workspace.Map.
Kit.C = {
	Grass = Color3.fromRGB(96, 214, 66),
	GrassDark = Color3.fromRGB(72, 180, 52),
	Leaf = Color3.fromRGB(60, 150, 50),
	Dirt = Color3.fromRGB(206, 160, 104),
	Sand = Color3.fromRGB(232, 210, 160),
	Wood = Color3.fromRGB(168, 112, 66),
	WoodDark = Color3.fromRGB(90, 56, 34),
	BarnRed = Color3.fromRGB(200, 52, 46),
	Cream = Color3.fromRGB(245, 240, 225),
	Sky = Color3.fromRGB(70, 160, 230),
	Gold = Color3.fromRGB(255, 196, 40),
	Slate = Color3.fromRGB(96, 104, 120),
	Charcoal = Color3.fromRGB(30, 32, 42),
	Teal = Color3.fromRGB(90, 170, 160),
	Pink = Color3.fromRGB(240, 120, 180),
	Purple = Color3.fromRGB(150, 90, 220),
	Orange = Color3.fromRGB(250, 140, 50),
	Lilac = Color3.fromRGB(150, 150, 200),
}
Kit.ACCENTS = { Kit.C.BarnRed, Kit.C.Orange, Kit.C.Gold, Kit.C.Leaf, Kit.C.Sky, Kit.C.Purple, Kit.C.Teal, Kit.C.Pink }

-- Warm lantern: neon block plus a real light.
function Kit.lamp(parent, name, size, pos, opts)
	local p = Kit.part(parent, name, size, pos, Color3.fromRGB(255, 214, 120), { Material = Enum.Material.Neon, CanCollide = false, CanQuery = false, CanTouch = false })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 214, 120)
	l.Range = (opts and opts.range) or 18
	l.Brightness = (opts and opts.brightness) or 1.5
	l.Shadows = false
	l.Parent = p
	return p
end

-- Decor part: no collision, no queries, optional no shadow.
function Kit.decor(parent, name, size, pos, color, opts)
	opts = opts or {}
	opts.CanCollide = false
	opts.CanQuery = false
	opts.CanTouch = false
	return Kit.part(parent, name, size, pos, color, opts)
end

-- Clone a master (Assets.Props / Assets.Foliage) to a pivot. The master's pivot is its base centre.
function Kit.place(master, cframe, parent, scale)
	local c = master:Clone()
	if scale and scale ~= 1 then c:ScaleTo(scale) end
	c:PivotTo(cframe)
	c.Parent = parent
	return c
end

-- Ground hit under (x, z) from height 80, ignoring ignoreList. Returns position or nil.
function Kit.groundAt(x, z, ignoreList)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList or {}
	params.RespectCanCollide = true
	local hit = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -120, 0), params)
	return hit and hit.Position or nil, hit and hit.Instance or nil
end

-- The "Studs" MaterialVariant gives every Plastic part the stud look.
function Kit.ensureStuds()
	local MS = game:GetService("MaterialService")
	local mv = MS:FindFirstChild("Studs")
	if not mv then
		mv = Instance.new("MaterialVariant")
		mv.Name = "Studs"
		mv.BaseMaterial = Enum.Material.Plastic
		mv.Parent = MS
	end
	mv.ColorMap = STUD_MAP
	mv.StudsPerTile = 5
end

function Kit.folder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Kit.model(name, parent)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

-- Anchored stud part. pos is a Vector3 or CFrame. opts sets any Part property
-- (Material = Kit.NEON, Shape, Transparency, CanCollide, ...).
function Kit.part(parent, name, size, pos, color, opts)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = typeof(pos) == "CFrame" and pos or CFrame.new(pos)
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.MaterialVariant = "Studs"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts then
		for k, v in opts do
			if k == "Material" then
				p.MaterialVariant = ""
			end
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- Invisible, non-colliding marker (spawn points, zones).
function Kit.marker(parent, name, size, pos)
	return Kit.part(parent, name, size, pos, Color3.new(1, 1, 1), {
		Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false,
	})
end

-- Invisible wall that keeps players in.
function Kit.bound(parent, size, pos)
	return Kit.part(parent, "Bound", size, pos, Color3.new(1, 1, 1), {
		Transparency = 1, CastShadow = false, CanQuery = false, CanTouch = false,
	})
end

-- Chunky outlined text on a part face.
function Kit.label(p, face, text, color, pixelsPerStud)
	local g = Instance.new("SurfaceGui")
	g.Face = face
	g.LightInfluence = 0
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pixelsPerStud or 12
	g.Parent = p
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextScaled = true
	t.Font = Enum.Font.FredokaOne
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Parent = g
	local s = Instance.new("UIStroke")
	s.Thickness = 5
	s.Color = Color3.fromRGB(20, 20, 30)
	s.Parent = t
	return t
end

function Kit.shade(color, f)
	return Color3.new(math.clamp(color.R * f, 0, 1), math.clamp(color.G * f, 0, 1), math.clamp(color.B * f, 0, 1))
end

-- Themed wall: one slab plus flat patches in lighter and darker tones (the
-- patchwork look of the reference walls). The wall runs along Z at x, or
-- along X at z when alongX is true. inward is +1/-1: the side players see.
function Kit.wall(parent, name, a0, a1, at, inward, alongX, height, color, thickness, patchColor)
	thickness = thickness or 6
	local len, mid = a1 - a0, (a0 + a1) / 2
	local c = at - inward * thickness / 2
	local size = alongX and Vector3.new(len, height, thickness) or Vector3.new(thickness, height, len)
	local pos = alongX and Vector3.new(mid, height / 2, c) or Vector3.new(c, height / 2, mid)
	local wall = Kit.part(parent, name, size, pos, color)
	local n = patchColor and math.floor(len / 16) or 0
	local placed = {}
	for _ = 1, n do
		local w, h = Kit.rng:NextInteger(1, 3) * 8, Kit.rng:NextInteger(1, 2) * 8
		local along = a0 + Kit.rng:NextInteger(0, math.max(0, math.floor((len - w) / 8))) * 8 + w / 2
		local y = Kit.rng:NextInteger(0, math.max(0, math.floor((height - h) / 8))) * 8 + h / 2
		local free = true
		for _, r in placed do
			if math.abs(r.a - along) < (r.w + w) / 2 and math.abs(r.y - y) < (r.h + h) / 2 then free = false break end
		end
		if not free then continue end
		table.insert(placed, { a = along, y = y, w = w, h = h })
		local tone = patchColor
		local ps = alongX and Vector3.new(w, h, 0.2) or Vector3.new(0.2, h, w)
		local pp = alongX and Vector3.new(along, y, at + inward * 0.1) or Vector3.new(at + inward * 0.1, y, along)
		Kit.decor(parent, "WallPatch", ps, pp, tone, { CastShadow = false })
	end
	return wall
end

-- Ground slab with patchwork tiles on top. Top surface sits at y = 0.
-- Snap every visible part colour of a model to the nearest palette colour.
function Kit.palettize(model)
	local list = {}
	for _, c in Kit.C do table.insert(list, c) end
	table.insert(list, Color3.fromRGB(255, 214, 120))
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			local best, bd = p.Color, math.huge
			for _, c in list do
				local d = (c.R - p.Color.R) ^ 2 + (c.G - p.Color.G) ^ 2 + (c.B - p.Color.B) ^ 2
				if d < bd then best, bd = c, d end
			end
			p.Color = best
		end
	end
	return model
end

-- band = { inner, outer }: patches only where inner < |x| < outer (keeps them off paths, floors, boardwalks).
function Kit.ground(parent, name, x0, x1, z0, z1, color, patches, patchColor, band)
	local size = Vector3.new(math.abs(x1 - x0), 4, math.abs(z1 - z0))
	local g = Kit.part(parent, name, size, Vector3.new((x0 + x1) / 2, -2, (z0 + z1) / 2), color)
	local lx, lz = math.min(x0, x1), math.min(z0, z1)
	local placed = {}
	for _ = 1, patches or math.floor(size.X * size.Z / 900) do
		local w, d = Kit.rng:NextInteger(1, 3) * 8, Kit.rng:NextInteger(1, 3) * 8
		if w < size.X and d < size.Z then
			local x = lx + Kit.rng:NextInteger(0, math.floor((size.X - w) / 8)) * 8 + w / 2
			local z = lz + Kit.rng:NextInteger(0, math.floor((size.Z - d) / 8)) * 8 + d / 2
			local free = true
			for _, r in placed do
				if math.abs(r.x - x) < (r.w + w) / 2 and math.abs(r.z - z) < (r.d + d) / 2 then free = false break end
			end
			if band then
				local lo, hi = math.abs(x) - w / 2, math.abs(x) + w / 2
				if (x - w / 2) * (x + w / 2) < 0 or lo < band[1] or hi > band[2] then free = false end
			end
			if not free then continue end
			table.insert(placed, { x = x, z = z, w = w, d = d })
			local tone = patchColor or Kit.C.GrassDark
			Kit.decor(parent, "GroundPatch", Vector3.new(w, 0.1, d), Vector3.new(x, 0.05, z), tone, { CastShadow = false })
		end
	end
	return g
end

return Kit
