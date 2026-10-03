# Steal a City

Roblox giant + carry/steal tycoon. The full design is the game plan v4
(`steal-a-city-gameplan.md`, keep a copy in this folder). When a rule here and
the plan disagree, the plan wins; say so instead of guessing.

## Tooling

- **Roblox Studio MCP** (built into Studio): read/edit scripts, run Luau,
  start/stop playtests, read console output, take screenshots, simulate input.
  Every tool needs a `studio_id`; call `list_roblox_studios` first.
- **Script Sync** keeps the `.luau` files in this folder and the scripts in
  Studio in step, both directions. Only Script, LocalScript, ModuleScript and
  Folder sync. Parts, models, plots, UI and attributes live in the place file,
  so build those through MCP (`execute_luau`, `insert_asset`) and save the place.
- No Rojo. No Wally. ProfileStore is vendored in `ServerScriptService/Packages`.
- Git tracks the scripts, `tools/` and the source models in `assets/models/`.
  The place file is backed up by Studio version history (File > Version
  History) and publishing.

## File layout (Script Sync naming)

| On disk | In Studio |
|---|---|
| `ServerScriptService/Main.server.luau` | server entry, starts services in order |
| `ServerScriptService/Services/*.luau` | one ModuleScript per system with `.Start()` |
| `ServerScriptService/Packages/` | third-party modules, don't edit |
| `ReplicatedStorage/Shared/*.luau` | modules both sides use (`Config`) |
| `StarterPlayerScripts/*.local.luau` | client scripts (LocalScripts); Script Sync does not pick up NEW files here |
| `ReplicatedStorage/Client/*.client.luau` | client scripts (RunContext Client); put new client scripts here |
| `ReplicatedStorage/Shared/Signal.luau` | by-reference signal; use it instead of BindableEvents (those copy tables) |
| `ServerScriptService/Build/*.luau` | edit-time builders (`Kit`, `BuildMap`, `BuildAssets`); run in Studio with `loadstring(B.X.Source)()(Kit)` |

`name.luau` = ModuleScript, `name.server.luau` = Script, `name.local.luau` =
LocalScript, `name.client.luau` = Script with RunContext Client,
`folder/init.server.luau` = script with children.
Scripts in `StarterPlayerScripts` use `.local.luau`: a `.client.luau` Script
there runs more than once.
Duplicate names in one folder can't sync.

## Rules (from plan §14)

- Server is the authority. Pick-up, drop, catch, delivery and Stomp are
  validated on the server by distance and state; check carry path and speed
  against Size. Never trust a client number.
- `Services/Data.luau` is the only writer of saved data. Read with
  `Data.Get(player)`, write with `Data.Update(player, fn)`. Save data, never
  instances: plot slots are `{id, variant}`;
  safes are `{tier, stage, contents, readyAt}`.
- Size is the main stat. Server sets the Player's `Scale` attribute (1-4x,
  eased curve); clients run `Model:ScaleTo`. Speed keeps rising past the 4x
  visual cap via a separate speed stat. World is built at about 0.5x.
- Tunable numbers go in `ReplicatedStorage/Shared/Config.luau`.
- Carrying: the real object stays put (aftermath shows); weld a light,
  non-colliding proxy that keeps the object's silhouette to the carrier and
  record the carry in a server table. Leaving while carrying returns it.
- Chasers: Humanoid `MoveTo` every 0.2 s, no pathfinding; catch is a server
  distance check with latency tolerance; caught = ragdoll + fling home, the
  object returns. Stop at the Giant Gate (safe-zone line).
- Variants are data (material, colour, light, particles), not extra models.
- Policy: paid random items show odds and are gated with
  `PolicyService:GetPolicyInfoForPlayerAsync` (`ArePaidRandomItemsRestricted`).
  No wagering, no spin-for-coins, no watch-to-earn, cartoon violence only.
- Use `--!strict` and typed Luau in new modules.

## Working loop

1. Edit the `.luau` files here (Script Sync pushes them into Studio).
2. `start_stop_play` to playtest, `get_console_output` to read errors,
   `screen_capture` when the change is visual.
3. Stop the playtest before editing again. Commit when a milestone works.

Studio's data stores: turn on Game Settings > Security > "Enable Studio
Access to API Services" after the place is published, or ProfileStore runs
in mock mode and nothing saves between tests.

## Model pipeline (Blender to Studio)

1. **Model** in Blender (Blender MCP) at real-world size in metres, origin at
   the bottom centre. Roblox keeps one colour per MeshPart, so bake material
   colours into a face-corner colour attribute (`BYTE_COLOR`, `CORNER`).
2. **Export** the selected object to `assets/models/<name>.fbx` with
   `bpy.ops.export_scene.fbx(filepath=..., use_selection=True,
   object_types={"MESH"}, global_scale=0.018, colors_type="SRGB")`.
   Roblox reads the FBX centimetre values as studs, so `global_scale` is
   0.01 x studs per metre; 1.8 studs per metre is the half-scale world.
   The Blender MCP `export_scene` tool can't set the scale: a default export
   arrives 100 studs per metre.
3. **Upload** with `tools/upload_model.sh assets/models/<name>.fbx "Display
   Name"`. It posts to the Open Cloud Assets API as a Model owned by user
   566042674, polls the operation and prints the asset ID on stdout. It needs
   `curl`, `jq` and `$ROBLOX_API_KEY`; the key is set in the interactive zsh
   profile, so from an agent shell run it as
   `zsh -ic 'ROBLOX_API_KEY="$ROBLOX_API_KEY" tools/upload_model.sh ...'`.
   Every run creates a new asset; it does not update an old one.
4. **Insert** with Studio MCP `insert_asset` (`assetType` Model). Then through
   `execute_luau`: anchor the parts, set the MeshPart `Color` to white (it
   tints the vertex colours), and `PivotTo` so the bounding box sits on the
   surface. `screen_capture` to check, then save the place.

| Model | Source | Asset ID |
|---|---|---|
| Traffic cone | `assets/models/cone.fbx` | 120938429116640 |

## Current milestone

Open-lobby rebuild and custom prompts (plan file /Users/Work/.claude/plans/pasted-content-id-05d1-decisions-update-wise-dijkstra.md). Checkpoints 1-4 need owner approval.
