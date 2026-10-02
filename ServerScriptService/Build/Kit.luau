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
function Kit.wall(parent, name, a0, a1, at, inward, alongX, height, color, thickness)
	thickness = thickness or 6
	local len, mid = a1 - a0, (a0 + a1) / 2
	local c = at - inward * thickness / 2
	local size = alongX and Vector3.new(len, height, thickness) or Vector3.new(thickness, height, len)
	local pos = alongX and Vector3.new(mid, height / 2, c) or Vector3.new(c, height / 2, mid)
	local wall = Kit.part(parent, name, size, pos, color)
	local n = math.floor(len / 16)
	for _ = 1, n do
		local w, h = Kit.rng:NextInteger(1, 3) * 8, Kit.rng:NextInteger(1, 2) * 8
		local along = a0 + Kit.rng:NextInteger(0, math.max(0, math.floor((len - w) / 8))) * 8 + w / 2
		local y = Kit.rng:NextInteger(0, math.max(0, math.floor((height - h) / 8))) * 8 + h / 2
		local tone = Kit.shade(color, Kit.rng:NextNumber() < 0.5 and 0.9 or 1.1)
		local ps = alongX and Vector3.new(w, h, 0.4) or Vector3.new(0.4, h, w)
		local pp = alongX and Vector3.new(along, y, at + inward * 0.1) or Vector3.new(at + inward * 0.1, y, along)
		Kit.part(parent, "Patch", ps, pp, tone, { CanCollide = false, CastShadow = false })
	end
	return wall
end

-- Ground slab with patchwork tiles on top. Top surface sits at y = 0.
function Kit.ground(parent, name, x0, x1, z0, z1, color, patches)
	local size = Vector3.new(math.abs(x1 - x0), 4, math.abs(z1 - z0))
	local g = Kit.part(parent, name, size, Vector3.new((x0 + x1) / 2, -2, (z0 + z1) / 2), color)
	local lx, lz = math.min(x0, x1), math.min(z0, z1)
	for _ = 1, patches or math.floor(size.X * size.Z / 900) do
		local w, d = Kit.rng:NextInteger(1, 3) * 8, Kit.rng:NextInteger(1, 3) * 8
		if w < size.X and d < size.Z then
			local x = lx + Kit.rng:NextInteger(0, math.floor((size.X - w) / 8)) * 8 + w / 2
			local z = lz + Kit.rng:NextInteger(0, math.floor((size.Z - d) / 8)) * 8 + d / 2
			local tone = Kit.shade(color, Kit.rng:NextNumber() < 0.5 and 0.93 or 1.07)
			Kit.part(parent, "Patch", Vector3.new(w, 0.2, d), Vector3.new(x, 0.05, z), tone, { CanCollide = false, CastShadow = false })
		end
	end
	return g
end

return Kit
