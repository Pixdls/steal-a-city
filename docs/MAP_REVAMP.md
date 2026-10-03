# Map revamp: Phase 1 audit, Style Bible and build plan

Date: 2026-10-02. Target: ship-ready classic stud style, matching the Steal An Egg references
(lobby, main street, pirate port, desert). Nothing in this plan is built yet; the owner
approves this document first.

## 1. Audit of the current map (workspace.Map, 3,735 parts)

Automated audit (axis-aligned parts, zone by zone) plus visual review of the screenshots.

| # | Problem | Where | Count / evidence |
|---|---|---|---|
| 1 | Parts of different colour intersecting by more than 0.05 studs | everywhere | **1,508 pairs** |
| 2 | Coplanar faces with different colours (the flicker) | ground and wall "Patch" plates lying on each other at the same height; facade back planes flush with the wall slab behind them; fence rails sunk into posts | the audit's exact-plane test found 0 because patches sit 0.15 above the ground, but patch-on-patch and facade-on-slab are coplanar in practice and flicker |
| 3 | Too many colours | whole map | **93 distinct colours**; target 12 core + 6 accents |
| 4 | Scale inconsistent | lobby vs stages vs objects | plots 60 x 50 with 7-stud trophies; facades 56 tall next to 2-stud buckets; lobby hedge walls same height as a saloon; door heights vary 8-14 |
| 5 | Facades clip into gameplay | lobby | hedge "feet" and leaf clusters protrude 4-15 studs into plot floors and fences |
| 6 | Hierarchy not per zone | Map.Home / Map.Stages / Map.Bounds | decor, structure, markers and props mixed in one folder per zone; patches are loose parts; 2 models without PrimaryPart (GiantGate, YearArch) |
| 7 | No foliage at all | everywhere | 0 grass tufts, flowers, bushes, rocks |
| 8 | Props missing | everywhere | only what is baked into facades (barrels, wheels); no hitching posts, troughs, crates, lamps as placed props; no path edging; no signage beyond arches |
| 9 | Lighting | everywhere | neon lantern blocks with no PointLight; no light at night |
| 10 | Transition reads as a cut | Ranch Trail -> Cowboy Town | stepped wall jogs show bare slab edges; the "Fence" facade's hill backing reads as random green blocks (your screenshot 1) |
| 11 | Flat slabs | lobby back wall, end wall backing, transition walls | large untextured faces, which the brief forbids |
| 12 | Placeholder stations | lobby | Sell / Shop / Footprints stalls and Crusher are rough; leaderboards blank |
| 13 | Ground patches | all floors | flat 0.2-stud plates with random tone; they do not read as dirt or worn grass |
| 14 | Naming | small | all parts have names, but 400+ are "Patch"; plot fences are "Post/Rail" x 300 |

Not problems, for the record: 0 unanchored parts, 0 default names, bounds are invisible and
non-colliding, the stud material is one MaterialVariant used everywhere (consistent scale).

## 2. Where the brief and the game design disagree (owner decides)

1. **Studs on top faces only vs all faces.** The brief says top-facing surfaces. The reference
   screenshots (Steal An Egg lobby and shops) have studs on walls too. Current setup: one
   MaterialVariant on every face, 1.25-stud studs. Recommendation: keep all faces, as in the
   references.
2. **Interiors.** The brief wants a full saloon interior (bar, piano, stairs, balcony). In this
   game the saloon is a stealable object players carry away, shown at trophy size on their plot,
   and the buildings along the road are facades (the walls of the corridor) that players cannot
   enter. A full interior would never be seen. Recommendation: facades get real porch depth and
   open fronts where it fits (blacksmith, stables) and one walk-in showpiece per stage later;
   no hidden interiors.
3. **Scale standards.** The brief's table (doors 8 tall, ceilings 12-14, R15 5.5 tall) is adopted
   for facades and lobby structures. Stealable objects keep their catalog sizes (bucket 2,
   saloon 22 wide) because the whole point is carrying small things first and buildings later;
   they are toys, not architecture.
4. **Blender.** The brief prefers Blender for curved props. Our proven pipeline builds everything
   from stud parts (the saloon, water tower, facades) and that is what the references do; MeshParts
   cannot take the stud material. Recommendation: parts only, cylinders for barrels and wheels;
   Blender stays available for later organic shapes.
5. **Agents.** Codex builders cannot see Studio at the same time as Claude. Builders write builder
   scripts (one file per zone or per master set); the Lead runs them in Studio, screenshots, and
   feeds results back. The Auditor is a fresh Codex run plus the audit script.

## 3. Style Bible

### Palette (12 core + 6 accents; nothing else)

| Role | Colour (RGB) | Use |
|---|---|---|
| Grass | 96, 214, 66 | lobby and ranch ground, hedge tops |
| Grass dark | 72, 180, 52 | hedge bodies, grass tufts, patch variation |
| Leaf | 60, 150, 50 | bushes, cactus, tree tops |
| Dirt | 206, 160, 104 | paths, cowboy street, dirt patches |
| Sand | 232, 210, 160 | boardwalk edges, worn ground, cream fronts |
| Wood | 168, 112, 66 | planks, posts, boardwalk, barrels |
| Wood dark | 90, 56, 34 | trims, beams, roof edges, fence shadows |
| Barn red | 200, 52, 46 | barns, accents |
| Cream | 245, 240, 225 | window frames, trims, fences, signs |
| Sky / water | 70, 160, 230 | windows, water, troughs |
| Gold | 255, 196, 40 | sign text, safe pads, year signs, hay |
| Slate | 96, 104, 120 | metal, stone, machinery, silo |
| Charcoal | 30, 32, 42 | outlines, text stroke, door shadows, barrels bands |
| Accent teal | 90, 170, 160 | one shop front, plot colour |
| Accent pink | 240, 120, 180 | one shop front, flowers, plot colour |
| Accent purple | 150, 90, 220 | plot colour, boost shop |
| Accent orange | 250, 140, 50 | plot colour, footprints shop |
| Accent lilac-grey | 150, 150, 200 | the old western "bank" blue-grey, one front only |

Rule: a builder picks from this table by role name. The audit flags any other colour.
Variants (Gold, Neon, Rainbow) and UI are outside this table.

### Materials and studs
- Every visible part: Material Plastic + MaterialVariant "Studs" (grey stud tile, tinted by part
  colour, 1.25-stud studs, all faces). Exceptions: Neon for lamps and glow, Glass never.
- Lamps: Neon block + a PointLight (range 18, brightness 1.5, warm 255,214,120).
- No Texture or Decal instances on parts. No unions, no MeshParts in the map.

### Scale table (R15 ~ 5.5 tall; the world is built for a 1x player, giants grow to 4x)
| Thing | Size |
|---|---|
| Door | 5 wide, 8 tall; swinging saloon doors 3.5 tall centred at 4 |
| Window | 6 x 8, sill 3 above floor, frame 0.6 proud, shutters 2.5 wide |
| Storey | 14 floor to floor; facades 2 storeys = 28-32, false fronts to 40-48 |
| Walls (corridor sides) | 48 tall (down from 56), 6 thick, grass-capped |
| Porch | 10 deep, roof at 11, posts 1 x 11, railing 3 tall |
| Fence | posts 1.4 x 5, two rails 0.8 x 0.9, 10 apart |
| Bar / counter | 4 tall; table 3; chair seat 2; stool 2.5 |
| Stairs | 1 rise, 2.5 run, 5 wide |
| Boardwalk | 0.6 tall, 24 deep, plank lines every 2 |
| Path | 24 wide in the ranch, edged with 1-stud dirt lip; cowboy street 92 wide |
| Grass tuft | 1.5-2.5 tall blocks; flower 2.5 tall; bush 4-7; rock 2-5 |
| Props | barrel 3 x 4, crate 3 cube, trough 6 x 2.5 x 3, hitching post 5 x 3, lantern 1.6 x 2.2 |

### Geometry rules (from the brief, enforced by the audit)
1. No coplanar overlapping faces of different colour: parts butt, or are offset >= 0.05, or
   share colour where hidden. Patches become insets (0.1 below the surface) or raised plates
   >= 0.1 proud, never on top of each other.
2. Nothing clips visibly. Facades stop at the wall plane; their feet stay inside their own
   strip (a 12-stud "frontage strip" the layout reserves along every wall).
3. Nothing floats: scatter uses raycast grounding, gap < 0.02.
4. Hierarchy: `Workspace.Map.<Zone>.{Structure, Props, Foliage, Lighting, Markers}`; markers
   (spawns, safe spawns, chaser posts, plot slots) keep their runtime names and attributes.
5. Every Model has a PrimaryPart at its base centre and a real name.
6. Everything anchored; decor CanCollide/CanTouch/CanQuery false; tiny foliage CastShadow false.
7. Parts and cylinders only.

### Detail rules
- Every wall face gets one layer of secondary detail (trim, plank lines, frames, baseboard,
  battens) and every zone gets props at its edges, not in the lane players run through.
- Foliage in clusters: denser along walls, path edges and building feet; never in the road.
- Signage: every facade has a sign plate; every station a sign; arches name the stage and year.
- Lighting: a lantern every 24-30 studs, all with PointLights.

## 3b. Scale table (added 2026-10-03, owner approval required before rebuilding)

Reference: a 1x R15 player is 5.0 studs from feet to head top (hats excluded); knee 1.4,
hip 2.3, chest 3.5, eye 4.5. At 4x the same player is 20 studs tall. The world is built at
about half scale (plan v4 §14): a real saloon is ~9 m wide, which would be 32+ studs at full
scale; ours is 22. Rule for stealables: nothing smaller than knee-to-hip height (1.4-2.3) on
its shortest readable axis, and the small tier should reach the hip or waist so it never
reads as foot-sized. Carried proxies keep real size up to 1.3x the player's height.

| Object | Current (W x H x D) | Proposed | At 1x player | At 4x player | Why |
|---|---|---|---|---|---|
| Bucket (S1 small) | 2 x 2 x 2 | **3 x 2.6 x 3**, handle 0.5 thick | knee-to-hip, two hands wide | a cup | was foot-sized |
| Hay Bale (S1 small) | 4 x 3 x 3 | 4.5 x 3 x 3.5 | hip height, chest wide | a brick | fine, slightly wider |
| Cactus (S1 medium) | 3 x 7 x 3 | 3.5 x 7.5 x 3.5, arms 1.2 thick | taller than the player | waist | fine |
| Scarecrow (S1 medium) | 4 x 8 x 2 | 5 x 8.5 x 2 | taller than the player, arms wide | hip | fine |
| Covered Wagon (S1 showpiece) | 7 x 8 x 12 | 8 x 9 x 13, wheels 4 | roof above the head, two players long | knee-high toy | fine |
| Water Trough (S2 small) | 6 x 2.5 x 3 | 6 x 2.8 x 3 | hip height, player-long | ankle | ok as a small |
| Outhouse (S2 small) | 4 x 8 x 4 | 4.5 x 9 x 4.5 | a door you'd walk into | hip | fine |
| Stagecoach (S2 medium) | 6 x 8 x 11 | 7 x 9 x 12 | roof above the head | knee | fine |
| Water Tower (S2 medium) | 9 x 20 x 9 | 10 x 22 x 10 | 4 players tall | just above the head | fine |
| Saloon (S2 showpiece) | 22 x 18 x 16 | 24 x 20 x 18 | 2 storeys you'd walk into, door 5 x 8 | waist | the showpiece reads as a building |
| Piggy Bank (safe) | 3.6 x 4.1 x 5.1 | 3.5 x 3.5 x 4.5 | hip | ankle | fine |

Lobby layout (owner decision 2026-10-03, final and approved at checkpoint 1): **7 plots, 7 players per server**. Five plots along the back cliff have 60 x 50 floors, 12-stud gaps and a total width of 348; entrances face the gate. One 50 x 60 plot on each side sits in the front half, entrances facing each other toward the centre. Every entrance has a 36-deep apron outside the floor for its bench press and upgrade sign. Reserve 40 behind every plot for planned expansion: behind the back row, toward the side cliffs for the side plots.

The lobby interior is 570 x 274, the open centre 318 x 116. Side apron to back-row apron: 18; side plot to stall row: 38. The 88-wide Giant Gate is centred on the front edge, Shop and Footprints left, Sell and Crusher right; the safe-zone line has a SAFE ZONE decal and shield icons. Spawn-to-gate walks across the open centre to the nearest gate edge are P1 217, P2 193, P3 190, P4 193, P5 217, P6 190, P7 190 studs, all within the 190–280 target. This approved layout supersedes the older lobby placement below.

Lobby pieces (built for the 1x player; giants simply tower over them):
| Piece | Size | Note |
|---|---|---|
| Plot | 60 x 50 back-row floor, 50 x 60 side floor, 20 slots, showcase podium 10 x 10 | a trophy is 6-7 studs: hip-to-head height at 1x |
| Bench press | 8 x 6 x 6, bar at 4.5, seat at 2 | a player lies on it |
| Upgrade sign | board 8 x 4 on a 7 post, two price badges | like the reference treadmill sign |
| Stall | 16 x 17 x 10 with 11-tall posts, counter 4 | the clerk stands behind the counter |
| Giant Gate arch | 88 wide, beam at 44-54 | giants at 4x (20 tall) pass under with room |
| Walls / cliffs | 48 tall | 2.4x a maxed giant, so nobody sees over |
| Plot fence | posts 1.4 x 5, rails 0.9 | hip-high |
| Lantern post | 11 tall | lamp above head height |
| Lobby open centre | 318 x 116 | 7 plots face the centre |

Stage corridors: Ranch Trail 112 wide x 300 long with a 24 path; Cowboy Town 144 x 340 with a
92 street and 24 boardwalks. A 4x giant (20 tall, ~8 wide) carrying a saloon (24 wide) fits
with 60 studs to spare.

## 4. Zone-by-zone build plan

Zones: **Lobby**, **Ranch Trail**, **Transition**, **Cowboy Town**. (The end wall belongs to Cowboy Town.)

| Zone | Structure | Props | Foliage | Lighting | Part budget |
|---|---|---|---|---|---|
| Lobby | plots moved inward 16 studs so facades never touch them; hedge facades 48 tall; back wall gets a facade row (greenhouse, garden shed, flower wall) with the two leaderboards framed into it; station buildings (Sell, Crusher, Shop, Footprints) rebuilt as small detailed kiosks; gate arch rebuilt with PrimaryPart | plot fences from a fence master, plot signs, benches, flower boxes, path edging | grass tufts along all walls and plot borders, flower clumps at every plot entrance, bushes at corners | lanterns on every plot post pair + arch | 2,600 |
| Ranch Trail | walls 48 tall; the Fence module gets a real layered hill backing (3 terraces, bushes, a tree) instead of a green slab; path edged with dirt lip and worn patches as insets; corner trims at wall ends | hay carts, barrels, water pumps, fence runs, milk cans, signposts, scarecrow silhouettes on the hill | tufts, flowers, dry shrubs in clusters along fences and barn feet; rocks at the path edge | lantern per facade, 2 per silo | 2,800 |
| Transition | stepped jogs dressed as rock-and-timber retaining walls with corner posts; ground blends via irregular dirt insets; the year arch gets a PrimaryPart, posts with braces and hanging lanterns | signpost "COWBOY TOWN ->", wagon wheel, barrels | shrubs on the jogs | 2 | 500 |
| Cowboy Town | boardwalk with plank lines and steps every 40; hitching posts and troughs in front of every third facade; ruts as insets; the end barricade gets a gate, lanterns and a SIZE sign; porch roofs get support braces | barrels, crates, hay, cactus pots, water barrels, signs, bulletin board with wanted posters (SurfaceGui) | dry tufts, tumbleweed balls, cactus clusters at wall feet | hanging lanterns on every porch | 3,200 |

Masters first (one builder file each), then zone builders place clones:
- `Build/BuildProps.luau`: barrel, crate, lantern (with light), hitching post, trough, signpost,
  bench, flower box, milk can, wagon wheel, hay cart, cactus pot, bulletin board, fence module.
- `Build/BuildFoliage.luau`: grass tuft x3, flower x4 colours, bush x2, rock x3, dry shrub x2,
  tumbleweed, dirt inset x3 shapes; plus `Scatter(zone, rules)` with raycast grounding,
  cluster placement, random yaw and 0.85-1.15 scale.
- `Build/BuildFacades.luau` (revise): heights per the scale table, hill backing for Fence,
  feet inside the frontage strip, palette only.
- `Build/BuildMap.luau` (revise): new hierarchy, frontage strips, patch insets, zone budgets.
- `Build/Audit.luau`: the audit script as a module (overlap, coplanar, floating, naming,
  hierarchy, palette, counts) returning a report string; run by the Lead each cycle.

### Agents and ownership
- LEAD (Claude): this document, runs builders in Studio, screenshots, the Review Loop, final call.
- PROPS (Codex): BuildProps.luau. FOLIAGE (Codex): BuildFoliage.luau.
- BUILDER Lobby, BUILDER Ranch+Transition, BUILDER Cowboy Town (Codex, one file each, sequential
  edits to BuildMap through the Lead to avoid two editors on one file).
- AUDITOR (Codex, fresh run each cycle): reads the audit report and the screenshots the Lead
  attaches, scores each zone 1-10 on geometry, scale, detail density, style match, composition,
  names the 3 biggest weaknesses, cannot edit.

### Review Loop
Per zone: audit script (zero errors required) -> screenshots (wide, eye level, close-ups of
joins) -> Auditor score (every score >= 9) -> builders fix -> repeat. Minimum 3 cycles per zone,
each logged in this file under "Cycle log".

## 5. Phase order
1. Owner approves this plan.
2. Cleanup: new hierarchy in BuildMap, patches to insets, plots inward, facade feet constrained,
   wall height 48, palette enforced in Kit (colour names only).
3. Masters: props and foliage builders (Codex, parallel). Facade revision (Codex).
4. Zone builds, Lobby first (it is what every player sees first), then Ranch, Transition, Town.
5. Detail pass: scatter, lights, signage.
6. Review Loop until pass. Then commit, publish.

## Cycle log

### Cycle 1 (2026-10-03): extended audit + master sweep
Audit extended: oriented bounding boxes for every part (rotated, wedge, cylinder, ball, mesh),
a disconnected-parts check (any visible part not touching the rest of its model within 0.1),
and a scale check against an `ExpectedSize` attribute. Re-running it on the dressed map raised
the error count from 0 to 660. The props sheet (every master beside a 5.5-stud R15 dummy,
`workspace.PropsSheet`) was screenshotted in sections.

**Broken, incomplete or wrongly scaled assets found (owner saw 2, sweep found 24):**

| # | Asset | Problem | Fix |
|---|---|---|---|
| 1 | Props/HayCart | reads as half a wagon: 2 wheels, no axle, no shafts, no sides, bed too short | rebuild: 4 wheels on 2 axles, bed with side rails, shafts, hay on top |
| 2 | Props/WagonWheel | placed "leaning" against nothing; spokes clip the hub (3 overlaps) | lean only when a wall/cart is behind it; hub as one cylinder, spokes end at the hub face |
| 3 | Objects/Bucket (2 studs) | reads as foot-sized next to the dummy; handle thinner than 0.4 | 2.6 x 2.4 x 2.6 with a 0.5 handle; it stays the first, lightest pickup |
| 4 | All 16 facade signs | the sign board and its 2 uprights touch nothing: they hang in front of the facade | signs become hanging boards on 2 chains from a bracket, or post-mounted boards whose posts stand on the porch; connected by construction |
| 5 | Facade WestHotel balcony | floor, rail and 10 balusters disconnected from the wall | balcony floor cantilevered from the wall with 2 brackets |
| 6 | Facade WestSheriff badge | star badge floats in front of the sign | mount on the sign plate |
| 7 | Facade BarnDoors hay loft | 2 hay bales + 8 bindings float at the loft hatch | hay sits on the loft shelf |
| 8 | Objects/CoveredWagon | tongue, yoke, driver seat and seat back disconnected | attach to the bed |
| 9 | Objects/Stagecoach | 2 lanterns, driver seat and back disconnected | attach to the body |
| 10 | Objects/WaterTower | legs, braces, platform, ladder and tank planks disconnected from the tank (37 loose parts) | tank sits on the platform, legs touch the platform, ladder rungs touch the rails |
| 11 | Props/WaterPump | bucket floats under the spout | bucket on the ground touching the base |
| 12 | Props/BenchPress | seat and 2 legs disconnected | legs touch the seat |
| 13 | Lobby Crusher | sign and light float | mount on the body |
| 14 | Foliage/GrassTuft1-3 | blades don't touch each other (2-4 loose each) | blades share a base block |
| 15 | Foliage/Bush1-2 | lobes overlap the canopy by up to 2.5 studs (16 overlaps) | lobes butt against the canopy |
| 16 | Foliage/Flower* | petals overlap the centre | petals around the centre, not through it |
| 17 | Foliage/DryShrub1-2 | leaves overlap the stem | leaves attached to stem ends |
| 18 | Props/Barrel | 4.5 tall vs spec 4 (lid rim sits above the top) | rim inset |
| 19 | Props/LanternPost | arm + lantern extend 4.2 wide; lantern hangs 0.4 below its hook | hook touches lantern |
| 20 | Props/Signpost | board 6 wide looks small for a 9.5 post; text later renders as a black blob (your screenshot) | board 8 x 4 with a 0.6 frame, text at 10 px/stud |
| 21 | Lobby stall Shop/Sell/Footprints | awning slats intersect the posts and sign trims (23 overlaps) | slats start inside the post line |
| 22 | Objects/Saloon | sign text never renders (label face is wrong side) | fix label face |
| 23 | Plot fences | a fence line was shared between neighbours, so the plot's own fence is missing on one side | each plot owns its fence; neighbours' fences offset 1 stud |
| 24 | Scale check | no master had an ExpectedSize yet, so scale was unverified | every builder sets `ExpectedSize`; audit flags +-25% |
