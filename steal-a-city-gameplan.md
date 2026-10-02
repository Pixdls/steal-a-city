# Steal a City — game plan v4

Version 4, 2026-10-02. The approved final decisions replace v3. Numbers are starting values to tune in playtests. This plan takes precedence where older project instructions disagree.

**What changed since v3**

- One road now connects 10 launch stages, with 16 planned, each a city of its era.
- The lobby is 8 plots beside the road. The Giant Juice and museum stories are gone.
- A bench press on each plot provides the main growth; deliveries add a growth bump.
- Safes reveal objects and Secret buildings, with mixed timers and a Secret guarantee counter.
- Player theft happens through the Stomp on the road. Plots are safehouses.
- Variants, the Crusher, cash-only rebirth and the Index form the collection economy.
- The tutorial introduces a bucket, a guaranteed Gold safe reward and a free bench upgrade.
- Launch purchases and a 7–14 day production plan replace the old monetisation and schedule.

## 1. The game in one breath

Carry the city home. Start with buckets, end with pyramids. Your collection earns cash; your bench makes you grow. The bigger you get, the bigger what you can steal and the faster what chases you. Other players can knock loose what you carry on the road.

The name is **Steal a City**; backup: **Steal the World**. Each stage is a city of its era: Cowboy Town, Castle Village, Pharaoh City, Moon City. There is no lore to explain. Steal An Egg is the closest reference, alongside Steal a Brainrot and Grow a Garden. Copy what works and add the giant/city touch.

## 2. The map

You spawn on your own plot. The lobby has no plaza or fountain: 8 plots line both sides of the road's start, following Steal An Egg. Each has a bench press. Shop, Footprints/cosmetics, Sell and Crusher sit along the edges. The safe-zone line, the **Giant Gate**, is just past the plots.

Tan cliffs with grass tops and trees enclose everything. The cliff wall is the only backdrop. Everything in front of the cliffs on the road is stealable.

Target **10 stages at launch, 16 planned**. Each gets 5 objects: 2 small, 2 medium and 1 showpiece. Objects generally get bigger further along, but later stages still have small objects. Early stages are about 150–200 studs long; later ones get slightly longer. Every showpiece has a 2x-scaled stage chaser guarding it, without a separate boss system.

| # | Stage / year arch | Road | Objects, small to showpiece | Chaser | Secret building, safes only | Release |
|---|---|---|---|---|---|---|
| 1 | Ranch Trail (1880) | Narrow dirt path | Bucket, hay bale, cactus, scarecrow, **covered wagon** | Ranch dog | Cloudmill, floating sails | Launch |
| 2 | Cowboy Town (1880) | Wide dirt street, wooden boardwalks | Water trough, outhouse, stagecoach, water tower, **saloon** | Sheriff | Haunted Saloon | Launch |
| 3 | Castle Village (1250) | Cobblestones | Market stall, well, catapult, windmill, **castle tower** | Knight on foot | Dragon Keep | Launch |
| 4 | Pirate Port (1700) | Wooden docks by water | Cannon, anchor, treasure pile, lighthouse, **pirate ship** | Pirate captain | Ghost Ship | Launch |
| 5 | Main Street (2026) | Two-lane road | Car, ice-cream truck, house, corner shop, **school** | Officer | Candy House | Launch |
| 6 | Highway (2026) | Highway | Bus, fire truck, tanker, billboard, **gas station** | Police car | Monster Truck Arena | Launch |
| 7 | Downtown (2026) | City plaza | Fountain, cinema, apartment block, mall, **Ferris wheel** | SWAT van; helicopter spotlight is spectacle only | Disco Tower | Launch |
| 8 | Pharaoh City (3000 BC) | Sand road | Obelisk, statue, Sphinx, temple, **pyramid** | Mummy; 2x Mummy at pyramid | Sunstone Sphinx | Launch |
| 9 | Roman City (100 AD) | Marble road | Chariot, temple, aqueduct, arena gate, **Colosseum** | Gladiator | Vesuvius Temple | Launch |
| 10 | Frozen Peaks | Snow road | Sled, cabin, ski lift, ice palace, **ice castle** | Yeti | Santa's Workshop | Launch; Christmas hook, first cut if late |
| 11 | Dino Jungle | Ferns, mud | Fossils, skeletons, **T-Rex skeleton** | T-Rex | tbd | Update |
| 12 | Skyline | Steel and glass | Crane, tower, **stadium** | Foreman | tbd | Update |
| 13 | World Wonders | Plaza | Big Ben, Eiffel Tower, **Statue of Liberty** | Museum guard | tbd | Update |
| 14 | Future City (3000) | Neon glass | Hover car, robot, **megatower** | Robot cop | tbd | Update |
| 15 | Space Port | Launch platform | Satellite, shuttle, **rocket** | Astronaut | tbd | Update |
| 16 | Moon City, finale | Moon dust | Rover, lander, **moon base** | Alien | tbd | Update; later “steal the Moon” event |

Update-stage object lists are incomplete; the remaining objects are tbd. Keep the existing traffic-cone model as a road prop.

Transitions take **30–50 studs**. Surfaces blend, cliffs change colour, and props from both stages mix. Roads widen gradually, never suddenly from one lane to four. A year arch with a recommended-Size sign sits in each transition. No portals or time-travel story.

The launch route changes as follows:

- Ranch Trail → Cowboy Town: path widens into a dusty main street with boardwalks.
- Cowboy Town → Castle Village: dirt → gravel → cobbles; wood becomes stone.
- Castle Village → Pirate Port: cobbles descend to the sea and wooden docks.
- Pirate Port → Main Street: old docks → modern pier → promenade → asphalt.
- Main Street → Highway: an on-ramp widens two lanes to four.
- Highway → Downtown: highway exit becomes city boulevard.
- Downtown → Pharaoh City: sand blows over cracked asphalt into a sand road.
- Pharaoh City → Roman City: sand becomes white marble.
- Roman City → Frozen Peaks: marble climbs into a snowy mountain pass.

Taking an object leaves a mess until it respawns in **60–120 seconds**, with a new variant roll. Houses leave foundations, broken pipes spraying water, sparking wires and dust. Hydrants leave water jets; lamps leave sparking stumps; cars leave oil, tire marks and alarms. Benches, bins and mailboxes leave bolts and litter; fountains leave dry basins.

Aim for about **3 spawn points per player per stage**, then tune so 8 players cannot strip it bare. Variants roll per spawn, not per player.

## 3. Size, speed and carrying

Start at **$0 and Size 10**. Size is the main stat and reaches billions. Visible scale runs from **1x to 4x**: fast early growth, increasingly hard progress toward the cap. Speed and strength keep rising after 4x. A **Slow Mode** toggle helps when speed becomes difficult to steer.

Anything can be lifted. A heavy load causes a strained walk and sweat, with no locks or “Size needed” text. Object weight is roughly the Size a player has when that object is their best. Recommended Size rises about **3x per stage through stages 1–3, then 4x**.

`Carry speed = walk speed × clamp((Size / weight)^0.5, 0.25, 1)`

This means full speed when weight is at or below Size, and never below **25%** of walk speed.

The **bench press** is the main growth source, equivalent to Steal An Egg's treadmill. It works while AFK, **online only**. Costs rise roughly 20x and gains roughly 4x between tiers. The tutorial gives the first upgrade free.

| Bench cost | Size gained per second |
|---|---:|
| Free | 2 |
| $500 | 8 |
| $15K | 30 |
| $250K | 120 |
| $5M | 500 |
| $120M | 2K |
| $3B | 8K |
| $75B | 30K |
| $2T | 120K |
| $50T | 500K |

Bench levels can also be bought with Robux; those levels survive rebirth.

`Delivery bump = bench rate × 120 seconds × clamp(weight / Size, 0.25, 2)`

A delivery is worth roughly **2 minutes** of bench growth, with more for heavy loads. Group joining gives a one-time Size boost. Global like goals can give everyone a boost, for example at **10K likes**. No individual like/favourite rewards.

## 4. Economy

Use big numbers formatted **K, M, B, T, Qa**. The first object earns **$1/s**. Each stage's best object earns about **7x** the previous stage's best.

Pacing targets: first delivery **0:30**, first bench upgrade **2:00**, **$1M at 25–30 minutes**, billions in a few hours, trillions after a few days. Early useful upgrades should be about **3–6 minutes** of income apart.

| Variant | Income multiplier | Spawn chance | Presentation |
|---|---:|---:|---|
| Gold | x3 | 8% | Gold appearance |
| Diamond | x10 | 2% | Diamond appearance |
| Neon | x35 | 0.5% | Glow and local light beam |
| Rainbow | x120 | 0.1% | Server-wide alert |

Seasonal variants come later. Secret building variants stop at **Diamond**.

Plots start with **8 slots**, rising to **20**. Each purchased +1 slot costs about **10x** the previous one: **$500, $5K, $50K…**. Objects appear at trophy scale in a dense “giant's hoard” pile. Each plot has **1 showcase podium** for its best showpiece or Secret. A full plot triggers a pickup warning; overflow goes into a backpack.

**Sell** pays **60 seconds** of the object's income. The **Crusher** turns **3 identical objects into 1 of the next variant**, showing income before and after. The first creation of each gives an Index reward.

Offline objects earn **30% for up to 6 hours**. Safes continue cracking; the bench stops. Show one small “While you were away: $X” card. The later **Long Nap** pass raises this to **60% for 24 hours**.

**Rebirth launches with the game.** It requires cash only: **$1B first, x5 each time**, reachable after about **2–3 hours**. It resets cash, objects, Size and cash-bought bench levels. Each rebirth gives **+50% income, +50% growth and +1 slot**. Index progress, cosmetics, passes and Robux bench levels stay.

The **Index** rewards each first discovery. All **5 objects** of a stage give a stage stamp, a one-time Size/cash reward and a badge. All variants of a stage give a trail. Secret silhouettes are visible from day one.

## 5. Safes and Secret buildings

Safes are our equivalent of eggs. Each stage has **1–2 safe spawns**. Stages **1–3** mostly produce Piggy Banks, **4–6** Cash Safes, and **7–10** Armoured safes or Vaults. Ranch Trail never rolls a Vault. Players see era-specific skins and names, such as **Sheriff's Safe** and **Pharaoh's Sarcophagus**; tier names are internal.

**Contents roll at pickup.** Crack-now buys time only.

| Tier | Timer | Guaranteed at least | Secret chance |
|---|---|---|---:|
| Piggy Bank | 10–30 seconds | An object of that stage | 1% |
| Cash Safe | 5–15 minutes | Gold variant | 4% |
| Armoured | 1–3 hours | Diamond variant | 12% |
| Vault | 8–24 hours | Diamond + 30 minutes of income in cash | 30% |
| Event safes, post-launch | Up to 48 hours | tbd | tbd |

Mixed timers give quick rewards and reasons to return. Safes keep cracking offline and are opened by hand. One shared reveal animation swings the door open; a tiny building or object emerges and grows onto the plot.

The safe pad shows **“Secret guaranteed in N safes”** instead of a lucky bar. Piggy Banks do not count; Cash adds **1**, Armoured **3**, Vault **7**. The guarantee is at **25**, subject to tuning.

Start with **2 safe pads**, rising to **6 through cash upgrades**, plus a queue of **3 waiting safes**. Any queued safe can be thrown away. Secrets earn **5x their stage's showpiece**. A carried safe attracts that stage's chasers and can be stomped loose and stolen.

Crack-now launches at roughly **9–199 Robux**, scaling with time left, with odds shown and PolicyService gating. Direct safe sales start **2 weeks after launch**, also with odds and `ArePaidRandomItemsRestricted` gating. Restricted players get disclosed fixed contents.

## 6. Chasers

One shared chase system serves every stage. Their personalities come from sounds, catch animations and idle actions: these are the game's characters.

Chasers get faster in later stages. Within a stage, heavier loads relative to Size bring **1, 2 or 3 chasers**, never faster ones. Maximum **3 per carrier, 16 per server**. Pickup gives a **1-second** siren or bark warning; chasers spawn **40–60 studs** behind you.

A catch returns the object to its spot. You ragdoll, fly far back toward home and get up after about **2 seconds**, with no death screen. Dropping makes chasers return to their posts. Picking up again makes them rush to a fixed distance behind you, then resume normal chase speed. They brake, honk or bark at the Giant Gate and stop. There is never a paid escape button.

## 7. Hitting other players (the Stomp)

Plots are safehouses. The **STOMP** works only on the road, outside the safe zone. Only empty-handed players can use it; only carriers can be hit.

Hotbar slot **1** hits the nearest carrier in a roughly **70° cone**, about **12 studs** ahead. Reach is identical at every Size; only the effect grows. A **0.25-second** foot wind-up and ground shadow warn the victim.

Cooldown is **5 seconds**. A stomped player gets **6 seconds** of immunity and ragdolls for **1.5 seconds**. Nobody can grab the dropped object for **0.5 seconds**; the victim must wait **2 seconds**. Tutorial deliveries are immune. Stomp purchases change appearance only, never power.

Dropping loot also lets a big friend gift it to a small friend. A **Banana Peel** trap comes post-launch. If victims cannot tell who hit them in playtests, fall back to a slap.

## 8. First two minutes

The guided opening runs through about 150 seconds:

1. **0–45 seconds:** spawn on your plot. An arrow and glowing trail lead to a reserved Ranch Trail bucket. “Grab it!” A slow ranch dog follows. Delivery gives a cash pop and big visible growth.
2. **45–100 seconds:** follow the arrow to a reserved Piggy Bank with a **10-second** timer. Carry it home and place it on a pad. It reveals a guaranteed **Gold** object.
3. **100–150 seconds:** try something slightly too heavy and crawl. “Get stronger!” points to the bench. The first bench upgrade is free.
4. Enter free play with a dismissible “next goal” pill.

Hints use at most **4 words**. Show the group-reward prompt at **minute 5**. By **minute 10**, the player should have tried a showpiece.

Log every tutorial step, the **2nd voluntary pickup**, first catch, first Stomp loss, and leaving within **60 seconds** of a loss.

## 9. Screens and controls

Follow Steal An Egg's layout, with thick black outlines, bright colours, chunky stroked text and cartoon icons. Keep the mobile joystick and jump area clear.

| Position | Controls and information |
|---|---|
| Bottom-left | Size with a “+” to buy growth/bench; big green cash below |
| Left middle | Large Shop and Index buttons; Slow Mode below; Rebirth appears only when affordable |
| Bottom-centre | Hotbar: Stomp (1), later Banana Peel (2) |
| Right | Safes with ready-count badge, Daily/Events, boosts |
| Bottom-right | Next server event countdown, such as “Gold Rush in 12m” |
| While carrying | Large tap DROP button; PICK UP uses ProximityPrompt |

Nearby objects alone show nameplates with name, variant and $/s. Plot income uses one combined “+$X” pop.

## 10. Events and retention

Launch includes **7 cumulative daily stamps**. Missing a day never resets them; stamp **7** gives a Cash Safe. There are **3 playtime gifts**, at **5, 15 and 30 minutes**.

A server event runs every **30 minutes on the clock**, with a visible countdown. **Gold Rush** makes Gold much likelier for **3 minutes**; **Meteor Night** raises Neon chance. Also launch stage badges, **Richest** and **Biggest** leaderboards, the group reward, global like goals and codes for YouTubers.

After launch, run a Saturday update with **Admin Abuse**: extra spawns and boosted odds, never free Secrets for the whole server. The scenery crane handles admin drops. Add a stage every **2 weeks**; between stages use a variant event, new Secret, safe skin or Admin Abuse. Frozen Peaks is the Christmas hook; Halloween is missed.

## 11. Robux

| Launch purchase | Robux | What it provides |
|---|---:|---|
| 2x Cash | 349 | Doubled cash |
| 2x Growth | 399 | Doubled growth |
| +2 Safe Pads | 149 | Additional safe pads |
| Starter Pack | 99 | Fixed, disclosed contents |
| Bench tiers | About 799 total for whole line | Bench levels retained through rebirth |
| Crack-now | 9–199 | Removes remaining wait; price follows time left |
| Cosmetics | 49–299 | Footprints and Stomp effects |

Post-launch: **VIP, Long Nap, Server Luck, cash packs, gifting, direct safe sales and Admin Panel**. Server Luck affects the whole server and shows odds. Remaining contents and prices are tbd.

Never sell combat power, escape or anything that pays to hurt other players. No pets at launch.

## 12. Look and sound

Use blocky, low-poly shapes with studs/checker textures, saturated colour and clear silhouettes. Give each stage its own palette. Keep particles restrained and camera shake toggleable. Launch with **3 music tracks**.

Spend polish time on giant footsteps, the uproot crack, safe reveals, rarity stings, lively Rainbow/Neon variants and small Secret animations.

## 13. Policy

Paid random items show numeric odds totalling **100%** before purchase, provide a benefit on every outcome, and use `PolicyService:GetPolicyInfoForPlayerAsync` with `ArePaidRandomItemsRestricted`. Apply this to crack-now and later random offers, including Server Luck and direct safe sales. Restricted players receive disclosed fixed contents for direct safe purchases. Free spawn variants are separate from paid random offers.

No wagering, simulated gambling, spin-for-coins or watch-to-earn. Keep violence cartoon and bloodless. No individual like/favourite rewards; use global like goals instead.

Complete the maturity questionnaire from the actual content. Before publishing, check current Kids/Select eligibility, age-access and engagement-review requirements. V3's conflicting thresholds and regional lists are not launch rules; confirm the live requirements before deciding on an expedited review or organic trial.

## 14. Technical plan

The server validates pickup, drop, catch, delivery and Stomp. Check carry paths and speed against Size to prevent teleport and speed exploits; never trust client numbers.

`Services/Data.luau` is the only saved-data writer, using ProfileStore for session locking and autosave. Save data, never instances:

- Plot slot: `{id, variant}`.
- Safe: `{tier, stage, contents, readyAt}`.
- Showcase: a slot reference.

Store timestamps for capped offline income and safe completion. Keep rebirth as an integer and calculate its income multiplier when needed.

The server sets the Player's **Scale** attribute from **1x–4x** on an eased curve; clients apply `Model:ScaleTo`. WalkSpeed continues increasing past the visual cap through a separate speed stat. Keep the half-scale world approach, ramps and spawn/camera checks from v3.

The real carried object stays put while aftermath is shown. Weld a lightweight, non-colliding proxy with a recognisable silhouette to the carrier; track ownership in a server table. Leaving while carrying returns the object. Variants are material, colour, light and particle data, not extra models. Put tunable values in `ReplicatedStorage/Shared/Config.luau`.

Chasers use Humanoid `MoveTo` every **0.2 seconds** along the road lane, without pathfinding. After **1.5 seconds** without progress, hop or teleport back to the lane. Catch checks run on the server at about **6 studs**, with latency tolerance.

Build map parts in Studio with `tools/build_map.luau`. Make stealable objects, showpieces, Secrets and chasers through Creator Store kit-bashing and the Blender → FBX pipeline; reserve Blender mainly for showpieces and Secrets where possible. Use streaming and low-poly models. Check carried buildings and dense plots on a cheap phone with the MicroProfiler; use Studio's device simulator and multiplayer tests with **8 players**.

Studio MCP and Script Sync remain the workflow; no Rojo. Test the actual phone controls, saving, purchases and server validation before publishing.

## 15. Production plan and launch

Target launch in **7–14 days**. Codex handles usage-heavy code, Studio building, Blender modelling and documentation; Claude orchestrates and verifies.

Parallel Studio work uses separate scratch places per stage, saved as models/packages and inserted into the main place. Bulk Blender runs headless with `blender -b --python`. Never put two agents in one Studio window or Blender instance.

| Phase | Code lane | Figma lane | Studio map lane | Blender lane | Gate |
|---|---|---|---|---|---|
| 0 | Game plan v4 | — | — | — | Owner approves |
| 1: core loop, days 1–2 | Data, plots, carry, delivery, Size/speed curve, bench, chasers, Stomp, Piggy Bank | HUD and all menus | New lobby; stages 1–2 and transition | 10 objects for stages 1–2; Piggy Bank | Owner tests carry/chase feel and stage length |
| 2: content, days 3–4 | Safes, variants, Crusher, Index, offline, rebirth; UI from Figma | Icons, thumbnail | Stages 3–10 and transitions | Objects for stages 3–10, showpieces, Secrets, chaser looks | Owner plays everything |
| 3: extras, day 5 | Onboarding, events, daily rewards, Robux, exploit checks | — | Aftermath and safe-reveal effects | — | — |
| 4: polish, days 6–7+ | Economy tuning, phone performance, odds UI | — | — | — | Questionnaire, publish |

Target 10 stages. Frozen Peaks is first to cut if late. If stages **3–6** miss schedule, ship **8 stages**: Roman City and Frozen Peaks become the first updates.

Soft launch publicly without promotion first. Read onboarding completion and loss-related exits in Creator Analytics. Use Acquisition → Home Recommendations to inspect play-through and bounce against comparable experiences.

Retain v3's targets: **D1 20%+, D7 6%+, median session 12+ minutes, 2+ sessions/day**. If D1 is below **13% after 500 organic players**, investigate the first two minutes before expanding the meta. These are working targets, not promises.

A/B test icons and thumbnails and make friend joins easy. Keep organic Home results distinct from paid, friend and search traffic when judging discovery. Check current discovery and engagement-review guidance before spending. V3's small daily sponsor test over **2–3 weeks**, then tapering as recommendations grow, remains an approach to test rather than a guaranteed formula.

Capture a clip that explains play in **3 seconds**: a small player crawling with a bus as police arrive, or a giant carrying a Ferris wheel. Use it for mid-size Roblox channels and codes. Follow with Saturday updates and the **2-week stage cadence**.

## 16. Cut list

Do not build:

- Giant Juice lore, museum fiction, Feed Machine or a separate gym. Growth uses the plot bench.
- Base raids, locks, shields or recovery contracts.
- Crane countdown, “what's underneath”, headline billboard or crates on visible objects.
- Pets at launch or a Gloves shop.
- Paid escape/Getaway or paid combat power.
- A separate boss system, including a Pharaoh boss; the 2x Mummy covers it.
- Portals, time-travel story or a floor-by-floor skyscraper.
- Individual like/favourite rewards or a “most stolen” leaderboard.

The old three-district map, monetisation tables and eight-week schedule are superseded by this plan.

## 17. What still isn't proven

- Does carrying feel good on a phone, including heavy loads and high speed?
- Can victims clearly see who Stomped them?
- Do 8 players on one road feel crowded or fun?
- Can objects without faces carry enough charm? Chasers and Secrets must supply it.

These need playtests. The first owner gate tests carry/chase feel and stage length before the content build expands.
