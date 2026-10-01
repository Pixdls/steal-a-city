# Steal a City — game plan

Version 3, 2026-09-30. Built from live Roblox chart data (26 charts, 964 games), Rolimons player histories, Roblox's official discovery/analytics/policy docs, teardowns of Steal An Egg / Steal a Brainrot / Grow a Garden / Ride A Pet / Keyboard Escape, and four independent reviews (retention, monetisation, technical, and a Codex design pass). Where a claim comes from a source it is marked; where it is a judgement call it says so.

---

## 1. The game in one breath

You drank the Giant Juice. The city is your collection now. Carry cones, then cars, then houses, then landmarks home to your plot; everything on display earns coins. The bigger you get, the bigger the things you can lift and the bigger what comes after you. Other giants can raid your plot. Last thing to steal: the Moon.

**Title:** Steal a City (Codex's pick over "Steal a Skyscraper": it covers cones through landmarks, and version one has no skyscrapers yet). Group name trick from Steal An Egg: name the group "and Carry It Home" so the listing reads "Steal a City — and Carry It Home".

---

## 2. Fiction (fixed)

The v2 fiction had holes: why deliveries and gym reps both grow you, why a cone earns money, why police chase you on the road but not on your lawn, why other giants can raid but police can't. One fiction that closes all of them, kid-readable:

1. You drank the Giant Juice, so every heavy thing you carry home makes you bigger.
2. Your plot is your Giant Museum: people pay to see what you've taken, so everything on display earns coins, even while you sleep.
3. The city defends itself, and the bigger the thing you take, the bigger what comes after you: a guard dog, police cars, a helicopter, tanks and jets, a giant robot.
4. The city's forces stop at the Giant Gate at the edge of Home; only other giants dare come past it.
5. When you're big enough, you can eat something from your museum to grow even faster, and when you've outgrown the city you Rebirth: start small again with more Giant Juice in your veins.

Everything below follows from these five sentences. The gym is gone (it had no job without hard gates and competed with the core loop, per the retention review). "Eat what you stole" replaces it as the coin-and-duplicate sink.

---

## 3. Map

One road out of Home, districts in a row, buildings on both sides so the walls are the city. Districts get taller, not wider; a new district is one week's build appended to the end.

| District | Objects | Chaser | Version |
|---|---|---|---|
| Home | 8 plots, Giant Gate, Feed Machine, Crane pad | none | v1 |
| Street | cones, bikes, bins, benches, mailboxes | guard dog | v1 |
| Highway | cars, buses, trucks, food trucks | police cars | v1 |
| Downtown | houses, shops, fountain, Ferris wheel, statue | SWAT helicopter | v1 |
| Skyline | towers, stadium, rocket, roller coaster | tanks and jets | week 3 after launch |
| Landmarks | Eiffel Tower, Pyramids, Big Ben, Colosseum, Statue of Liberty | giant robot | week 6-7 |
| The Moon | one object, hangs over your plot | — | month 3+ |

- Objects respawn 60-120 s after being taken.
- A **Crane** in Downtown drops a new object on a visible countdown every few minutes; it can roll a variant. This is the rare-spawn moment, with a server-wide announcement.
- **Rebirth stays on the same map** (sky, palette and season swap, higher multiplier). New cities (Tokyo, Egypt, Moon base) are a month-6 feature, not a week-one promise. Four maps for one builder was the v2 mistake.

---

## 4. Rules

**Size** is the only stat.
- +Size per delivery, scaled by the object's weight. No gym.
- **Feed:** put an object from your plot into the Feed Machine to convert it into Size. Sink for duplicates and coins (feeding costs coins).
- Visible avatar scale: 1x to 4x (the city is built at about half scale so 4x reads as a giant on a phone). Numerical Size keeps rising past that; only reach and speed keep growing.

**Weight** is the tension.
- You can pick up anything. Carry speed = your Size versus the object's weight. A Size-5 kid lifts a car and crawls; a Size-40 giant walks off with it.
- Before you pick up, the prompt shows the expected carry speed and danger ("SLOW · police will catch you"). Weight is a decision, not a surprise (Codex addition).
- Empty-handed speed grows with Size (giant stride), capped at 3-4x. Out fast, home slow.

**Chasers** spawn on grab, tiered by the object, and follow you home (fixes the v2 contradiction where district lanes met a kid with a cone in Downtown with a helicopter). They stop at the Giant Gate. Touch = drop + fling + respawn at Home.
- **No chaser can catch you until your third delivery** (the dog barks and follows). A scripted failure in minute one is the single biggest bounce risk (Roblox's onboarding guidance: deliver the first joyful loop inside 5 minutes; their funnel example lost 70% between step 1 and 2).
- Every district has a dangerous shortcut and a safer detour so escaping is a skill, not a ratio (Codex).

**Player theft** (rewritten after the griefing review):
- Eligibility is keyed on the **object**, not the thief's Size: any player can lift a tier-N object off a plot whose total value is above a floor. Size brackets keyed on players were trivially gamed with alts.
- **Only the owner (or their plot guard) can tap a carrier to make them drop it**, and only within a radius of the victim's plot. "Anyone can tap anyone" would have handed the road to griefers, which was Steal a Brainrot's top complaint until its Jan 2026 anti-griefing update.
- Stolen objects are never destroyed, only moved.
- **Shield until your first successful theft from another player or until Size 10, whichever is later** (a "first session" shield would expire exactly on the D1 return visit, the session that decides retention).
- Timed base lock: 30 s on join, on-demand lock bought with coins (+10 s per rebirth), as Steal a Brainrot does.
- Starter slots are permanent and grow with rebirth. No theft while you're offline.

**Economy**
- Coins/sec from each displayed object; **variants multiply income** (Gold 3x, Neon 5x, Frozen 8x, Rainbow 10x, seasonal 12x), not just looks. Stacking multipliers are what make Steal a Brainrot's and Grow a Garden's collections matter.
- Offline earnings capped at 8 hours at a reduced rate.
- Sinks: plot slots, locks, Feed, Crane summons, rebirth.
- **Rebirth is gated on coins plus named objects** ("own a Gold Bus and a Ferris Wheel"), the way Steal a Brainrot gates on cash plus two named units. That turns the collection book into the quest log.
- After being robbed, the game offers a **recovery contract**: a short task that replaces the base object (not the variant). A loss should create a comeback, not an exit.

**Collection** (day one): index per object and variant, with permanent bonuses at milestones. Plot arrangement: move and rotate your haul with snap placement on mobile.

---

## 5. First two minutes

1. Spawn on your plot at Size 1. A cone ten metres away with a big PICK UP prompt and an 11-second timed hint. Carry it home (15 s). It plants, coins tick, you visibly grow.
2. A bike on a different route. Second delivery, second growth. The dog follows but can't catch.
3. A Size-40 giant walks past holding a bus. A tower stands on someone's plot in the distance. Goal shown, not told.
4. Minute two: the Crane countdown hits zero, a Neon fire hydrant drops with a server-wide announcement, and someone races for it.

Log the onboarding funnel (spawn, first pickup, first plant, first growth, first Highway object) from day one.

---

## 6. Social and cadence

- Servers of 6-8.
- **Landmark event every 15 minutes:** a landmark crash-lands at the far end in pieces; each piece carried home pays everyone a share and shows each player's contribution. This is the co-play reason that isn't robbing each other (co-play days is an algorithm signal).
- Saturday update at a fixed hour plus a 30-60 minute **Admin Abuse** window before it (Steal An Egg runs this every Saturday 8am PT). The server-wide spawn/boost commands must exist on day one even if the first event is week two.
- Monthly seasonal variant: Haunted (October), Frozen (December).
- Like + favourite + group join reward (Steal An Egg gives a big stat boost for all three). Weekly codes tied to the Saturday update.

---

## 7. Monetisation

What the comparables actually sell: Steal An Egg has two passes (2x Money 399, 2x Growth Speed 467) and makes the rest on consumables; Steal a Brainrot has 2x Money 299, VIP 375-499, Admin 7,499-9,999, and sells Server Luck (249/999/2,999) and Lucky Blocks; Keyboard Escape sells 44 cosmetic passes from 19 to 2,645 Robux and nothing else. Grow a Garden sells theft itself at 37 Robux.

**Gamepasses (six, permanent)**
| Pass | Robux | What |
|---|---|---|
| 2x Coins | 299 | the genre's default first buy |
| 2x Growth | 399 | faster Size gain; one tier, never stackable, never "bigger" |
| VIP | 399 | +50% coins, tag, gold name, VIP footprints, +2 plot slots |
| Crane Radar | 249 | map ping when a rare variant or crane drop spawns (Ride A Pet kept exactly this pass and shelved its others) |
| Long Nap | 349 | 24 h offline earnings instead of 8 h |
| Mayor's Panel | 4,999 | positive-sum admin: trigger the landmark event, force a rare spawn for the server, change the weather |

**Cosmetic ladder:** giant footprints (glowing, lava, snow), carry trails, stomp sounds, plot skylines, 49 to 1,499 Robux with two flex items at 1,999. Everyone sees the giant, so these are visible from across the map.

**Consumables (developer products)**
- Server Luck 2x/15 min 249, 4x/30 min 799 (buyer announced and thanked).
- Crane Drop 99: summon the crane now, random object with the variant roll, odds shown.
- Getaway 29: NPC chasers vanish for 20 s, sold at the moment the jets arrive. NPCs only; never protection from players.
- Starter Pack 189, one time: coins, a footprint, two Crane Drops.
- Coin packs 99/499/1,999, never surfaced first.
- Everything giftable to another player.

**Subscription:** Giant Club, 149 Robux/month: daily Crane Drop, +25% coins, monthly cosmetic.

**Free:** group join +10% coins; like milestones unlock footprints; weekly codes; a Roblox Plus-only footprint (Plus signups pay the creator a bonus).

**Removed from the draft:** paid base locks (ransom), a permanent Luck pass (pointless next to Server Luck and drags you into per-player odds display), "Giant Hour" (breaks the flex hierarchy), separate plot-slot pass (folded into VIP). Size is never sold.

**Revenue model** (assumptions: DAU ≈ 25x average CCU, 1.5-3 earned Robux per DAU per day, DevEx $0.0038/Robux; under-13 spend per hour is falling platform-wide, so budget on the low column):

| Avg CCU | ≈ USD/day |
|---|---|
| 5K | $700 - $1,400 |
| 20K | $2,900 - $5,700 |
| 100K | $14,000 - $28,500 |

Creator Rewards (the 2025 replacement for Premium Payouts) add roughly 5% on top, not the 20-50% SEO sites claim.

---

## 8. Policy

- **Paid random items** (Server Luck, Crane Drop): numeric odds summing to 100% shown before purchase, some benefit on every outcome, gated with `PolicyService.ArePaidRandomItemsRestricted` (restricted: Brazil under-18, unverified 18+, AU/BE/NL/UK). Give restricted players a fixed-object crane drop instead. Free spawn variants are not paid random items.
- **No simulated gambling:** no coin wagering, no spin wheels for coins.
- **Kids/Select:** violence blocks Kids eligibility; "flattened by tanks" stays cartoon and bloodless. A new game is shown only to age-checked 16+ players until it passes the engagement check (sources disagree: 250 vs 500 highly engaged plays in 60 days; expedited review 50,000 vs 100,000 Robux refundable; check the live page before launch).
- **No watch-to-earn** anywhere (the rule created by Steal An Egg's delisting in August 2026).

---

## 9. Technical plan (from the engineering review)

- **Scaling:** server sets a `Scale` attribute (1-4x); each client applies `Model:ScaleTo` locally with a tween (server-side scaling jitters); scale WalkSpeed, JumpPower and `CameraMaxZoomDistance` by the same number; ramps, not stairs; check HipHeight at spawn. World at ~0.5x, avatar capped at 4x.
- **Carrying:** the real object stays on the map; the server welds a small (0.3-0.5x), massless, non-colliding proxy to the carrier's torso and records the carry in a server table. Pick-up via ProximityPrompt (works on mobile); pick-up, drop, catch and delivery are all server-validated by distance and state. Clipping is accepted (Steal a Brainrot does the same); a hold, not a tap, to drop.
- **Chasers:** Humanoid rigs looping `MoveTo` between waypoints; on grab, spawn the tiered chaser and `MoveTo` the carrier every 0.2 s; catch is a server distance check. No pathfinding.
- **Data:** ProfileStore (session locking, autosave, the module AI assistants know best); one Data module owns all writes; offline income from a stored timestamp clamped to the cap; rebirth stored as an integer, multiplier computed at income time.
- **Plots:** eight plot models with an Owner attribute; save slot data (`{id, variant, lockedUntil}`), never instances; variants as data (material, colour, light, particles), not duplicate models.
- **Performance:** the risk is carried buildings and 24 plots of towers on a phone, not the avatars; low-poly held proxies, one LOD per slot, MicroProfiler on a cheap Android from week 2, streaming on with plots persistent.
- **Content:** block landmarks from parts and unions (they read better in miniature than AI meshes), Creator Store meshes for cars and trees, Cube/Meshy only for hero shapes, "wow" from motion and lighting.
- **Tooling:** Roblox Studio's official MCP server lets Claude Code edit scripts, run playtests and read output inside the open place; no Rojo needed. Studio Server & Clients mode for 8-player tests; Device Simulator plus one real cheap phone weekly.

---

## 10. Build schedule (one person, AI-assisted scripting)

| Week | Build | Milestone |
|---|---|---|
| 1 | Greybox Street, 8 plots, Giant Gate. ProfileStore data, plot claim, Scale attribute + client ScaleTo + camera | grow in place, data persists |
| 2 | Carry system: prompt with carry preview, proxy weld, weight-speed rule, delivery, coin tick | cone-to-plot loop playable; first phone test |
| 3 | Guard dog chaser (spawn on grab, follow home, Giant Gate stop), catch/drop/fling, respawn timers, no-catch-until-third-delivery; real Street props | the "one more run" test: build one bus, one route, one pursuer and make it excellent before anything else (Codex's "one thing") |
| 4 | Highway + police cars, Feed Machine, slots and locks shop, offline earnings, shield rules, funnel logging. Server & Clients test with 8 | full economy loop |
| 5 | Player theft (object-tier eligibility, owner-only tap, locks), variants with multipliers, collection book with milestone bonuses, rebirth (same map, gated on coins + named objects) | meta complete |
| 6 | Downtown + helicopter, Crane with countdown and announcements, two moving wonders (Ferris wheel, fountain), first-two-minutes polish, sound. Team Test with friends on phones | private test build |
| 7-8 | Landmark event, admin-abuse commands, monetisation pass (passes + Server Luck + Crane Drop with odds UI + policy gating), recovery contract, performance tuning, Kids/Select prep, icon/thumbnail/trailer clip | launch candidate |

**Cut order if behind:** landmark event → collection milestones → Downtown (ship two districts) → player theft (ship PvE with locks stubbed) → variants beyond Gold → offline earnings.

**Post-launch roadmap:** week 2 Saturday Admin Abuse + daily streak/playtime chest; week 3 Skyline district; week 4 seasonal Haunted variant; week 5-6 leaderboards + private servers; week 6-7 Landmarks; month 3 the Moon; month 6 new cities; trading not before month 3 and only with Roblox's trade-safety work.

---

## 11. Launch plan

1. **Soft launch** with the game public but unpromoted; read the onboarding funnel and bounce buckets in Creator Analytics (Acquisition → Home Recommendations shows play-through and the two bounce buckets against a 50th-90th percentile band of similar games).
2. **Targets:** D1 20%+, D7 6%+, median session 12+ min, 2+ sessions/day. Platform benchmarks (GameAnalytics 2026): D1 median 10.3%, p90 15.9%, p99 22.2%; D7 median 1.6%; session median 9.8 min. If D1 is under 13% after the first 500 organic players, the first two minutes are broken, not the meta.
3. **Kids/Select:** the algorithm only scores organic Home traffic; ads, friends and search don't count toward ranking but do feed the engagement check. Decide whether to pay the expedited review or grind the 16+ trial.
4. **Ads:** small daily sponsor budget for 2-3 weeks to feed the engagement check and the funnel, then taper as home recommendations take over (developer folklore, consistent across sources).
5. **YouTube:** the game must produce one clip that explains itself in three seconds (a tiny kid grabbing a bus and crawling as police arrive; a giant carrying a Ferris wheel past screaming NPCs). Send that clip to mid-size Roblox channels; Foltyn/Caylus historically arrive on their own when a game crosses ~100K (they appear in 7 of 9 breakout stories).
6. **Cadence from week one:** Saturday update + Admin Abuse + codes, every week, without exception. Every sustainer does this; the decayed games stopped.

---

## 12. What still isn't proven

- Nobody has shipped giant + theft. The bet is that "kid carrying a building" is a stronger video than "kid carrying an egg".
- Carrying feel on a phone is the make-or-break, and it can only be judged in the week-3 prototype.
- "A collection of things" versus "a collection of monsters": the moving wonders and named landmarks are the answer, and they are all on the builder.
- 100K is rare (12 games on the platform today, 3 made this year). This plan aims at the family where it has happened, with the fresh twist that family requires, and every rule in it is there to protect the signals Roblox actually scores.
