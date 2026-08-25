## v0.4.32 Kanto OPEN WORLD / WORLD OCEAN ownership

The detached Yellow excursion no longer treats `excursion.active` as equivalent to the public `OPEN WORLD` setting. Renderer ownership and residency are separate: Kanto can remain the active voxel presentation while `OPEN WORLD = OFF`, in which case `Quality.kantoRadius()` owns the connected-sector radius. `OPEN WORLD = ON` switches the excursion to a progressively materialized BFS of the full Yellow outdoor graph. Direct neighbours are forced ready immediately; farther adapters are prepared in small quality-tier batches and then flow through the same shared-body `VoxelScene` path.

`WORLD OCEAN` now keys its Kanto frame-cache entry by the actual residency scope. Streamed mode uses the current map/radius; Open World mode includes the current prepared/total graph count, forcing the perimeter mesh to expand as more Kanto maps join rather than reusing a stale early coastline.

## v0.3.89 — League state is run-scoped; Hall of Fame state is Gold-owned

Yellow's Elite Four scripts mix three concerns that cannot safely be copied wholesale into a Gold save: physical room block replacement, temporary challenge state, and endgame save/credits bookkeeping. v0.3.89 splits them. `KantoLeague.lua` owns only immutable Yellow facts (boss classes/parties, previous/next rooms and exact block swaps). `TwinRegionWorld` owns a Kanto-local run bit plus temporary boss events and prevents retreat warps while that run is active. A blackout or completed induction deletes those temporary trainer-win rows and restamps the room geometry, so rematches start from Lorelei rather than from a half-cleared challenge.

The permanent achievement is deliberately not reimplemented. Champion victory calls Gen1Recomp's `src.core.gen2.HallOfFame.induct` and uses `src.ui.gen2.HallOfFame` for the induction animation. That gives Gold the real Hall-of-Fame counter/team snapshots while the companion restores the pre-call `spawnAfterChampion` byte, preventing this parallel Yellow League from overwriting a native Gold post-credit destination.

## v0.3.78 — Character/object palettes are not background material palettes

The latest screenshot gave a decisive diagnostic: the Kanto player shared the same cream/olive cast as the buildings. Native Gold does not color Chris from the map's BG material ramp; `src/world/gen2/Player.lua` draws through `SpriteRenderer`, and Gen-2 `World` supplies the real `PAL_OW_RED` object palette for the current time of day. The excursion bridge was instead constructing Yellow `SPRITE_RED` via `npcSpriteFor`, which colors detached Yellow sheets from `activeKantoPalette`. That was conceptually the wrong layer even when the RGB values happened to look plausible. v0.3.78 therefore reuses `world.player.sprite` directly for the Kanto proxy.

The same screenshot also showed dense black/brown path checker and wall speckle. That came from `_shadeTransferPlan`: it deliberately split a flat 8x8 source shade across several Johto shades to reproduce donor histogram counts. This was mathematically closer to a donor tile but visually unlike the clean source texture and unlike Johto's actual spatial art. `colorize` now keeps the geometry/source texel shade index exactly and changes only the selected Johto BG palette ramp. `_shadeTransferPlan` remains only as a compatibility/test helper and is no longer on the visible atlas path.

The v0.3.77 scene-frequency material lock remains useful: Cherrygrove/Route 29 still decide the stable roof/facade/ground/grass/etc family, and route/city supplements fill missing roles. What changed is the final operation: `native shade -> locked Johto ramp`, with no donor texture or histogram redistribution.

## v0.3.77 — Why individual donor matching still looked inconsistent

v0.3.76 proved that Kanto could receive Johto's exact palette/shade populations without copying Johto's spatial tile art, but it still resolved the visible donor independently per Kanto tile. That is too permissive for `TILESET_JOHTO`: several alternate civic/structure palette families are valid in one tileset, and a locally closest donor is not necessarily the family dominating the scene the player is comparing against.

v0.3.77 therefore introduces a scene-level material vocabulary. `mapTileFrequencies` counts actual tile placements through the donor map's block body. `materialProfiles` chooses one dominant PalMap slot and one representative shade-population tile for each semantic family from those weighted placements. `resolvedColorSlot` consults that locked family before any per-tile nearest donor. The per-tile mapping remains only as a fallback and diagnostic.

Every source tile also receives a semantic category before remap success is known. This closes the previous fallback leak for uncommon Kanto trim. Route 29 and Cherrygrove supplement one another only for missing material families, so a route-side civic facade can still use Johto's civic family without replacing Route 29's terrain vocabulary.

## v0.3.76 — Why v0.3.75 could still look yellow

v0.3.75 quantile-mapped four shade **classes**, not individual pixels. That is lossy when Kanto and Johto use different shade populations: one source class cannot be divided, so a large pale source class remains a large pale output class. The visible result is exactly the lingering yellow/olive coverage reported after the previous pass.

v0.3.76 performs a monotone 64-pixel transfer instead. Pixels keep Kanto/native-Kanto spatial ownership and are sorted primarily by original shade; only equal-shade pixels are ordered by a fixed Bayer rank. The selected Johto donor's four histogram counts then partition that ordered list. The result preserves Kanto edges and relative light/dark structure while reproducing Johto's actual per-tile color proportions.

No Johto donor pixel coordinate is copied, gameplay/collision is untouched, and the eight active Gold palettes still come from the host's current palette/time/display-mode pipeline.

## v0.3.75 — Why copying Johto 2bpp pixels was wrong

v0.3.74 treated the selected Johto material tile as both color identity and texture-pattern authority. The supplied screenshot made the failure obvious: a Johto roof/brick pattern could be stretched conceptually across Kanto facade/terrain tiles, producing giant pink striping. Geometry remained Kanto, but the surface texel layout did not.

v0.3.75 restores the correct separation. Kanto/native-Kanto owns spatial surface art. The scene-selected Johto tile supplies its exact PalMap slot plus a target four-shade histogram. A monotonic quantile map converts Kanto's shade indices toward Johto's light/mid/dark balance without moving pixels. This preserves Kanto silhouettes and surface detail while matching Johto palette/contrast behavior much more faithfully.

## v0.3.73 — Why v0.3.72 still looked different in the screenshots

v0.3.72 separated Kanto geometry from Johto color authority, but its color remap still searched every tile in `TILESET_JOHTO`. That tileset contains several legitimate structure/roof palette slots. A Kanto roof could therefore choose a brown/olive Johto roof even while the compared Johto city was visibly using the bright magenta civic roof family.

v0.3.73 makes color selection scene-aware. Town/city maps prefer Cherrygrove, routes prefer Route 29, the donor map's block list limits which Johto tiles participate in material-slot voting, and authored building templates split `building:roof` from `building:facade`. This keeps Kanto silhouettes and native Gen-2 Kanto geometry while matching the visible Johto material family more directly.

## v0.3.72 — Kanto geometry stays Kanto; color authority moves to Johto

The previous projection path used one Gen-2 donor for both shape/texture and palette identity. That was structurally useful because native Gen-2 Kanto is often the best donor for Kanto buildings and terrain, but it also meant companion Kanto could carry a visibly different palette family from Johto. v0.3.72 separates those responsibilities.

`KantoGen2Style.donorFor` still chooses the best geometry donor. The new color-donor path chooses `TILESET_JOHTO`/New Bark for outdoor maps and a functionally matching Gen-2 interior for interiors. A second nearest-material remap is built only for color-slot selection. Geometry pixels provide the 2bpp shade pattern; the selected Johto PalMap slot and Johto active palette profile provide the RGB output. Source map ids, block/collision data, Kanto building templates and gameplay state are never rewritten.

The projection cache signature changed to `g2-johto-colors-372-r1`, intentionally invalidating old disk/memory projections. Gen1Recomp `dev` remains `9713977755fb87f3a7cc336d5a841cf3f3b15e31`.

## v0.3.71 — Classic Kanto rewards use Gold-owned transaction seams

Current Gen1Recomp hand-ports the Celadon Eevee, Dojo prize, Silph Lapras, Magikarp salesman, Oak aides, Mr. Psychic, Route 16 Fly gift and Celadon vending scripts for Red/Yellow. The companion's detached dialogue sandbox intentionally suppresses their mutating script commands when those maps are visited from Gold, so v0.3.71 gives only these map/text rows dedicated transaction ownership ahead of the sandbox.

Pokemon rewards go through the existing Gen-2 `Mon.new` + `storeGoldMon` path, with gift happiness 120, player OT normalization, current-box fallback and Gold Pokedex ownership. Item rewards resolve by safe Gold item/move identity and use the real Bag API. Money changes occur only after the reward is accepted. Companion-local events remain the only cross-region completion authority; Gold story flags are not borrowed. Physical reward objects (Celadon Eevee and the selected Dojo ball) are hidden in the existing Kanto physical-state layer and repaired on map entry after upgrades.

This release intentionally excludes numeric TM translations whose move meaning changed between generations. Copycat's Mimic and the rooftop girl's reward TMs remain dialogue-only rather than minting an incorrect Gold move. Gen1Recomp `dev` remains at 9713977755fb87f3a7cc336d5a841cf3f3b15e31 (2026-08-19), unchanged from the v0.3.70 compatibility check.

## v0.3.70 — Yellow starter gifts become real Gold-owned Kanto services

Current Gen1Recomp registers Yellow's Melanie, Damian and Officer Jenny sidequests in `data/scripts/yellow_gifts.lua`, but the companion Kanto bridge deliberately runs ordinary Yellow NPCs through `KantoDialogue`, whose detached sandbox suppresses `give_pokemon` and other gameplay mutation. That made these three NPCs presentation-correct but reward-incomplete. v0.3.70 gives only those exact map/text rows dedicated service ownership ahead of the sandbox.

The port preserves the authored gates while translating state ownership to Gold. Melanie checks the explicit Yellow follower happiness bridge when one exists, otherwise the highest actual party PIKACHU happiness, with the retail 147 threshold; Damian has no prerequisite; Jenny reads the Kanto THUNDER badge that the existing Gold gym-badge bridge awards after Lt. Surge. All gifts are level 10, `Mon.new(..., { happiness = 120 })` is used for Gen-2 gift friendship, and `storeGoldMon` stamps non-traded arrivals through current Gen1Recomp `Mon.stampOT` before real party/current-box insertion and Pokédex ownership.

The companion stores only one-time Kanto completion events. It never writes Yellow story flags into Gold. Completion is set after successful storage, and Melanie's authored Bulbasaur object is represented only as local physical hide state with map-entry repair. The current Gen1Recomp dev head checked for this release is 9713977755fb87f3a7cc336d5a841cf3f3b15e31 (2026-08-19); its Gen-2 Mon happiness/OT APIs and Yellow gift definitions remain compatible with this bridge.

## v0.3.69 — Fan Club and Bike Shop become safe Gold-owned Kanto services

The dialogue bridge intentionally cannot mutate the real Gold save, so the Fan Club chairman and Bike Shop clerk previously had a presentation-only ceiling: they could speak, but the BIKE VOUCHER/BICYCLE chain could not actually complete. v0.3.69 gives these two exact text rows dedicated service ownership ahead of the dialogue sandbox.

Gold remains authoritative for the actual BICYCLE and for key-item pocket capacity. Gold/Silver normally has no BIKE_VOUCHER item definition, so the chairman stores voucher possession in the companion's `EVENT_RECEIVED_BIKE_VOUCHER` while checking the real KEY_ITEM pocket capacity; if a compatible host does define BIKE_VOUCHER, the real Bag item is used. The Bike Shop writes BICYCLE first, then consumes physical/local voucher possession by setting `EVENT_GOT_BICYCLE`. Existing Gold ownership backfills the Kanto bits on interaction. No Yellow story flags are copied into Gold and no Yellow map/cutscene VM is dispatched.

The impossible ¥1,000,000 retail sale is presentation-only and never changes money/items. This keeps the original shop outcome while avoiding a fake cross-region economy path.

## v0.3.68 — Saffron and Museum are explicit physical/service ownership

The Yellow map scripts for the four Saffron guards and Museum 1F are safe to port because their important effects are local access/service mechanics, not story progression. `KantoCivic.lua` keeps their immutable map facts separate from the already-large TwinRegionWorld chunk: exact trigger cells, guard text constants, pushback axis, retail drink order, Museum price/rope cells, and Old Amber object/text identities.

Runtime ownership remains split deliberately. Gold/Silver's save owns `money` and `inventory`; handing a Saffron guard a drink removes exactly one real Gold item, Museum admission subtracts ¥50 from Gold, and OLD AMBER is inserted through Gold's Bag API. `yellowPhysicalEventsV1` stores only the foreign-region `EVENT_GAVE_GUARDS_DRINK`, `EVENT_BOUGHT_MUSEUM_TICKET`, and `EVENT_GOT_OLD_AMBER` completion bits. No Yellow save/story flag is copied into Gold and no map ASM/cutscene dispatcher runs.

The Old Amber display uses the existing Kanto hidden-object persistence/spatial invalidation path so its collision/actor representation disappears immediately. Map-entry migration reasserts that hidden physical state for an existing completion event. Completed-cell civic checks run before trainer sight/random encounters, matching their role as map-script access rules.

## v0.3.67 — iOS orientation ownership is presentation-local

Gen1Recomp's `src/core/Orientation.lua` deliberately applies orientation locks on Android only; iOS is governed by Info.plist and the bundled LÖVE window layer still exposes the live display-orientation enum. v0.3.67 therefore does not attempt to mutate UIKit/SDL orientation policy from a content mod. Instead, `AndroidFullFrameFlip.lua` is broadened into a mobile whole-frame compatibility wrapper: Android keeps manual `screenFlip`, while iOS checks `love.window.getDisplayOrientation()` and normalizes only `landscapeflipped`.

The transform remains outside Game2's full draw so world, HUD, menu/battle overlays and touch controls share one coordinate frame. Touch point `(x,y)` maps to `(w-x,h-y)` and deltas map to `(-dx,-dy)` under the correction. Regular iOS landscape is a direct native draw and allocates no correction canvas. The iOS option defaults ON but can opt out without uninstalling the wrapper. Stable option/orientation callback identities are protected once then called directly, matching the project's established hot-path policy.

Crucially, this does not alter `GoldVoxelBridge.frameGeometry`: Gold/Kanto drawWorld output remains logical-sized, and Gen1 worldOverride/Android TouchSkin physical sizing remains exactly as before.

## v0.3.66 — Connected Kanto dynamics and player-card ownership are change-driven

v0.3.65 retained the immutable connected-neighbor descriptor view but still recomputed its two movement-sensitive booleans every presentation frame. v0.3.66 splits that last dynamic layer from camera/animation time: `KantoFrameCache.neighborDynamics` keys the current result by completed Kanto cell and exact world-travel vector. A steady frame therefore leaves every neighbor untouched; cell/vector changes refresh once, and a connected-view rebuild clears the scalar key before reuse.

Second-ring directional prefetch also no longer derives and normalizes map-center geometry repeatedly. Each descriptor caches its normalized root-to-neighbor direction when built, with an on-demand derivation only for a legacy/hot-reloaded descriptor missing the new fields. The movement vector itself is normalized once per dynamic refresh. Direct neighbors remain always-prefetched and existing seam-urgency thresholds are unchanged.

The visible Kanto player proxy now caches its resolved SpriteRenderer/card across frames using only real identity inputs: map id, Bicycle state, synchronized Gold palette key, custom-player ownership and the hidden Gold player's SpriteRenderer identity. The Character Selector/custom-player `active()` export is still defensive on first sight of an object/function identity, then leaves `pcall` until that identity changes. RETURN TO JOHTO still drops the proxy and frame cache, so no Kanto sprite/map references cross the hard residency boundary.

## v0.3.65 — Connected Kanto neighborhood descriptors are frame-persistent

The solved `sectorRecords` topology is immutable for a root/radius until the imported region is rebuilt. Earlier no-lag passes cached that topology but still reconstructed its render descriptor layer every presentation frame. `KantoFrameCache.neighborView` now keys the reusable neighbor/direct-neighbor arrays by source map, Kanto radius and the cached sector-record table identity. A steady frame therefore keeps map references, offsets, depths, parent ids and directions in place; only the movement-sensitive `urgent` and `prefetch` booleans are refreshed.

Actor visibility remains generation/cell keyed independently. `invalidateActorView` does not touch the neighbor view, while a root/radius/source identity change wipes membership before repopulation and pool trimming. `FrameCache.release` still drops the sector-table key and all Kanto references at RETURN TO JOHTO.

GoldVoxelBridge's Kanto state handoff is also companion-owned code, so v0.3.65 gives it the same trusted-callback treatment already used for timer/input hot paths: one protected call per helper identity, direct calls afterward, and automatic revalidation if the function is replaced.

## v0.3.64 — Idle Kanto frames stop resolving actor state that is not due

`tickKantoNpcAI` used to resolve the current private map, authoritative NPC list and role cache on every rendered Kanto frame before checking the 0.70-second wander timer. v0.3.64 makes the maintained role record observable without allocating it: a cached mover list is interpolated directly when non-empty, otherwise the timer can return immediately without touching map/entity state. Only a due wander decision resolves collision/NPC data.

The same release removes two remaining stable-callback guards from the steady-state frame path. `stack:top()` and Love's RNG are protected once when their object/function identity first appears and direct thereafter, with identity changes automatically re-arming the defensive path. Trainer landings are also cheaper: the directional alignment test runs before persistence/header work, and imported trainer objects cache their immutable win ID/header. These changes affect scheduling/caching only; Yellow trainer ranges, line-of-sight collision, battle ownership and defeated-state semantics are unchanged.

## v0.3.63 — Kanto position persistence is checkpointed, not rewritten every cell

`mod.save` is the loader's save-slot namespace, and the previous Kanto landing path rebuilt `{mapId,x,y,facing,surfing,biking,forcedBike,lastOutside,...}` plus a deep copy of LAST_MAP for every cell. v0.3.63 keeps a single excursion-local snapshot, mutates scalar fields in place and reuses the same nested LAST_MAP record. Same-process persistence reads point at the current snapshot immediately, while ordinary travel crosses the save bridge only every eight changed cells.

All state transitions that materially change recovery ownership remain exact checkpoints: Kanto entry/return, authored warps, dungeon falls, Fly/relocation, Surf/Bicycle changes and route seams call the forced path. Opening a menu/overlay flushes a partial travel batch once, which both captures a natural pause/save point and avoids repeated writes on later covered frames. A forced call with no changed/dirty state is a no-op.

This is presentation/runtime bookkeeping only. Gold's party/bag/Pokedex/badges, Yellow physical state, Kanto collision/warp rules and all voxel/Character Selector rendering remain unchanged.

## v0.3.62 — Kanto ordinary landings no longer pay special-warp costs

The Yellow warp table is immutable for a built Kanto map and `ForeignGen1Map:warpAtCell` is already O(1). v0.3.62 moves that cheap lookup to the top of the completed-cell landing path. If no warp record exists, the runtime does not enter `resolveWarp`, does not inspect warp-pad/hole collision tiles, and does not run the second ExtraWarpCheck arm. Authored door, carpet, edge, pad and hole semantics are unchanged because all existing warp logic still runs whenever the O(1) index reports a real warp.

Warp bounce ownership is also unchanged but no longer string-based in normal runtime. The excursion stores the destination map and cell as scalars and clears them only after leaving that cell. A legacy `ignoreWarpKey` string is still recognized so older parity harnesses/integrations remain valid. Encounter-option caching is visit-local and is invalidated while an overlay is open, which is where mod settings are normally changed; entering/leaving Kanto also clears it.

## v0.3.61 — Kanto collision ownership stays exact while hot reads become cached

The Gen-1 surface is still authoritative for collision semantics; v0.3.61 only changes how often immutable tile/rule data is decoded. `ForeignGen1Map:cellTile` caches authored in-bounds collision cells and `setBlock` invalidates the exact 2x2 cell footprint of a changed block. Out-of-bounds border-extension reads remain uncached so their legacy semantics cannot alias a row-major cache key.

Because `ForeignGen1Map` is private to this companion and its methods are bounds-safe, render-rate passability and elevation-pair probes use direct calls. Unknown/external map objects retain the defensive `pcall` fallback. Gold input/timer methods likewise receive one protected identity probe before the stable fast path. Ledge and warp-carpet rules join the existing immutable `fieldIndex`; old injected/cache shapes retain list-scan fallbacks.

## v0.3.60 — Kanto actor ownership moves from scans to maintained views

v0.3.59 removed more voxel/palette hot-path work, leaving actor-side CPU/GC as the next avoidable moving-frame cost. `KantoSpatial.roles` now derives trainer/wanderer membership once from an authoritative NPC list and maintains a separate active-mover set. Trainer sight iterates trainers only; AI selection iterates wanderers only; interpolation iterates movers only.

`KantoFrameCache.actorView` reuses current-map entity and neighbor-ghost candidate arrays while `(map, player cell, actor distance, sector radius, actorGeneration)` is unchanged. `KantoSpatial.move/remove/invalidate` increments `actorGeneration`, so a walker, trainer approach, despawn, pickup, boulder move or roaming-Pokemon removal cannot leave the cached visibility view stale. Neighbor candidates are cached with one extra cell of allowance because the old filter used sub-cell player pixels; `VoxelScene` still performs the exact final view-distance/camera cull.

TwinRegionWorld now fills a reusable `_stadiumDirectNeighbors` array while it already knows graph depth, and GoldVoxelBridge consumes that exact identity. KantoFrameCache/VoxelScene pool trimming clears fields in records above the current high-water mark, retaining allocation capacity but not references to maps/actors/meshes from a route that is no longer visible. RETURN TO JOHTO still hard-releases the entire Kanto frame cache.

## v0.3.59 — Kanto moving-frame ownership after v0.3.58

v0.3.58 removed the largest Kanto allocation and background-meshing spikes. Profiling the remaining steady movement path showed that `VoxelScene.prefetch` still rebuilt several short-lived containers every frame and, more importantly, ran `openWorldFullMasks` even when `_stadiumSharedWorldBodies` meant Kanto would request BODY meshes and never consume those masks. v0.3.59 makes the shared-body decision before mask construction and moves the live/visibility/readiness arrays into the excursion's existing frame scratch.

The culling helpers also previously called `Quality.worldCullPadding`, `detailCullPadding` and `actorCullPadding` via protected calls for each map or actor. `_prepareCullView` now resolves those three values once per render and stores both the padding and expanded camera rectangles. The residency loop records each neighbor's visibility into reusable scratch and the later mesh loop consumes that exact result.

`ChunkMesher.setLive` historically retained the caller's `live` table as `prevLive`. That contract was incompatible with reusing one Kanto dictionary: clearing it on the next frame would silently rewrite the mesher's previous generation. v0.3.59 keeps two private live sets and copies/switches them only when residency actually changes, preserving the one-neighborhood grace behavior with no transition allocation.

Finally, the old 0.25-second `syncGoldPalette` throttle still performed a full `worldPaletteProfile` every poll. That profile scans the Johto PalMap repeatedly to derive semantic slots and serializes all eight active palettes. `GoldColorAtlas.worldPaletteInputs` is an intentionally cheap invalidation seam; unchanged daytime, GBC display mode, palette-set table and PalMap table return immediately. Full profile generation remains authoritative after a real change, so Kanto color/time fidelity is unchanged.

No Kanto movement/collision authority, Gen1Recomp story behavior, Character Selector frame ownership, Gold logical drawWorld sizing, Android viewport contract, mesh geometry or quality preset is changed.

## v0.3.58 — Kanto steady-frame CPU/GC ownership

The Kanto renderer already cached expensive sector topology, but the v0.3.57 steady path still created a fresh render-state table, neighbor descriptors, entity/ghost arrays, pose records, water draw rows, cull/context records and repeated neighbor translation matrices on visible frames. LuaJIT can reclaim those objects, but reclamation itself becomes visible as irregular GC/frame-time spikes on mobile and lower-power hardware.

`lib/KantoFrameCache.lua` now makes this presentation scratch visit-local and reusable. `Twin.excursionState` explicitly scrubs and repopulates the same state/arrays each frame, while `VoxelScene` pools pose/water records and reuses cull/world-context/dark-tint/atlas scratch. Neighbor descriptors retain only their stable cached model transform between uses. `FrameCache.release` aggressively clears all references before Kanto unload/RETURN TO JOHTO, so this optimization does not weaken the twin-region residency boundary.

The other important source of hitching was work that was technically "background" but could still perform expensive preparation on the visible frame. `scheduleKantoDiskWarm` previously could call `ensureForeignMap` for arbitrary Kanto records; that may deep-copy a map definition, decode/colorize its atlas and construct its adapter before the cooperative mesher even starts. During visible Kanto v0.3.58 restricts warm candidates to the current prepared map and already-prepared connected neighbors. The historical whole-region survey remains available only when gameplay is covered.

`GoldVoxelBridge` now tells `ChunkMesher` that every visible Kanto frame is interactive for cache-only purposes, including idle frames. When the current Kanto body is already present it uses the `kanto-visible` hint: real neighbor/prefetch jobs receive a short Quality-mode-specific CPU slice while the current sector remains untouched. A genuinely missing current body still receives the normal urgent build slice. This changes scheduling only; mesh contents, resolution and draw distance are unchanged.

The per-frame forced-bike sync also uses scalar `(map,x,y)` identity instead of constructing a composite string. All Android/Gold logical-canvas geometry from v0.3.48 remains untouched.

## v0.3.57 — Pokemon Tower 5F physical heal/no-battle rule

Current Gen1Recomp's `data/scripts/story3.lua` treats Pokemon Tower 5F's center pad as a map-step rule: cells `(10,8)`, `(11,8)`, `(10,9)`, `(11,9)` set a temporary `EVENT_IN_PURIFIED_ZONE` latch, run `HealParty` once when newly entered, and return true on every occupied step so `BIT_NO_BATTLES` suppresses encounters. Leaving the 2x2 area clears the latch. The script's presentation is `HealParty -> GBFadeOutToWhite -> Delay3 -> Delay3 -> GBFadeInFromWhite -> _PokemonTower5FPurifiedZoneText`, with no Pokemon Center heal jingle.

The Kanto companion now mirrors that as **physical presentation-local state**, not Yellow story authority. `lib/KantoTower.lua` owns the exact cell set and visit-local latch. `afterExcursionCellLanding` runs the rule before trainer/wild encounter ownership; an occupied purified cell consumes the landing, so neither visible roaming Pokemon nor optional CLASSIC STEP ENC can start there. Stepping outside clears the latch and normal encounter flow resumes.

Healing remains Gen-2 authoritative. `healGoldParty` first calls Gold's `world:healParty()` and uses a Tower-specific diagnostic counter; older hosts fall back to the canonical `src.pokemon.Pokemon.heal` helper so HP, status and PP/PP-Up restoration remain correct. No Yellow party copy is created and no Yellow event flag is written into Gold.

`KantoTower.present` supplies the white palette-style 24 + 6 + 24 frame sequence as a non-opaque logical 160x144 state. That matches Game2's drawWorld contract and therefore does not reintroduce the v0.3.47 physical-framebuffer/Android zoom bug. The imported text label is preferred, with a small ROM-free fallback for stale caches.

RETURN TO JOHTO clears the temporary latch. If the excursion later resumes directly on a saved purified cell, `Twin.teleportToPalletTown` invokes the same handler once so the new Kanto visit is immediately healed/protected. Pokemon Tower 6F Marowak/story progression remains intentionally outside this physical-only pass.

## v0.3.56 — Kanto owns Character Selector special-card and retained-yaw presentation state

v0.3.55 fixed the largest animation seam by refreshing Character Selector's cached voxel skeleton from the visible Kanto proxy. Two smaller cross-region state leaks remained because the selected renderer still runs against the **real Gold Player identity**.

First, renderer eligibility and Character Selector's generic `playerUsesSpecialCard` path can inspect Surf/Bike/Fishing state on that Player. Kanto exists only as a presentation-local proxy while the real Gold world remains in Johto, so those values are not interchangeable. `red3dRendererForPose` now treats a Kanto proxy as authoritative: Kanto Bicycle/Surf/Fishing suppress the humanoid and fall back to the authored special card, while hidden Johto special state is ignored for a Kanto frame. `withFreeVisualWalk` mirrors the proxy's loose mount fields only for the renderer call, and the proxy explicitly pins `fishing=false` so metatable fallback cannot inherit Johto fishing. Ordinary Johto continues through the existing engine-owned special-card check.

Second, Character Selector stores third-person travel continuity on Player (`red3dFreeBodyYaw`, `red3dLastWorldX`, `red3dLastWorldZ`, plus projected yaw). Leaving those shared meant a hidden Johto selector pass could rewrite the retained sample between Kanto passes. The Kanto proxy now owns a private copy of those presentation fields. Each Kanto renderer call exposes the private copy to the real Player, captures any updated actual-travel yaw/sample back to the proxy, then restores Johto's original values. The first Kanto frame starts its previous-world sample at the current Kanto coordinates, so the region jump is never mistaken for motion.

While standing, a change in Kanto's own `facing` (interaction/warp) is treated as an explicit turn-in-place and updates the retained body yaw. Merely orbiting the third-person camera does not change Kanto `facing`, so Character Selector's normal retained-travel-yaw behavior is preserved.

No collision, warp, Bicycle rules, Android viewport sizing, voxel quality, battle rendering or Gold save authority changed in this release.

## v0.3.55 — Kanto owns Character Selector frame preparation while visible

Current `randyadr/Gen1Recomp-Character-Selector` (checked at `019e10c4be57c98d3b86742bf2be5ba61348fa8b`) separates model animation preparation from drawing. `Renderer:beginVoxelFrame(player, pose)` samples locomotion and writes `voxelFrameWalking`, `voxelFrameBlend`, `voxelFrameClock` and `voxelFrameKey`; `Renderer:ensureSkinned(..., useVoxelFrame=true)` then trusts that cached frame, and `drawVoxel` / `drawVoxelShadow` do not call `beginVoxelFrame` themselves.

The Kanto bridge had already solved player identity and field mirroring: it delegates the Kanto proxy to the selected Character Selector renderer through the real Gold player object and temporarily supplies Kanto `moving`, facing, position, `progress`, target and step timing. The missing piece was **frame ownership**. Because Kanto manually invoked `drawVoxel`, a cached frame prepared earlier from the hidden Johto player could remain authoritative and keep the rig idle even while the Kanto model translated.

`OverworldStadium.refreshKantoPlayerSkinAnimation` now runs before Kanto shadow/main player draws. For current selectors it calls `beginVoxelFrame` through the existing render-only `withFreeVisualWalk` bridge, records the Kanto `voxelFrameKey`, and reuses it for the rest of the same VoxelScene frame. If an intervening selector pass changes the key, Kanto refreshes again before its next draw. The bridge additionally mirrors `red3dMoveStickX/Y` / `red3dAnalogMoveActive` so clip-selection logic sees Kanto's movement magnitude, and `jumping` / `hopFrames` so authored jump clips can follow Kanto ledges.

For older selectors without `beginVoxelFrame`, the bridge clears stale `voxelFrameKey` / `voxelUploadedKey`; their `updateVoxelMesh` therefore falls back to the selector's live `animationState()` path. The refresh is gated on `_stadiumGen1Excursion`, so ordinary Johto poses remain entirely selector-owned. All temporary Gold-player fields are restored after preparation/draw.

No Kanto collision/elevation/warp state and no Android/Gold framebuffer contract changed in this release.

## v0.3.54 — dialogue audio stays presentation-only; actor lookup becomes spatial

The v0.3.53 sandbox already captured Gen1Recomp TextBox objects, but it discarded their options before replay. That erased an engine-owned detail: `Commands.play_cry` stores `pendingCry`, then `show_text` converts it into TextBox `auto.sound` plus the authored wait behavior. v0.3.54 admits `play_cry` because it only mutates the detached script context, then copies **only** the safe TextBox presentation fields (`instant`, `auto.sound`, `auto.delay`, `auto.wait`) into the real Kanto box. The captured sound closure still references the detached proxy data/save. `auto.tick`, `auto.onOverlap` and arbitrary handler callbacks remain inside/suppressed by the sandbox.

`lib/KantoSpatial.lua` removes repeated actor-array scans from the Kanto movement hot path. Each map keeps separate NPC and Pokémon cell-bucket records keyed to the authoritative cached list identity. `at()` is constant-time by cell; buckets remain arrays so temporary duplicate occupancy and `except` semantics stay correct. `move()` edits old/new buckets in place. `remove()` handles roaming/static Pokémon disappearing into battle. Any operation that replaces the authoritative actor list invalidates the matching spatial record.

The index is presentation/gameplay-local and contains only entity references/coordinates; it is never serialized. Region palette/render unloads clear the indexes with the other actor caches. No culling or graphics reduction is involved.

## v0.3.53 — `text_asm` presentation without Yellow story authority

`data/generated/text_pointers.lua` cannot contain the actual speech for a `text_asm` pointer; the extractor records `asm=true` because the visible branch is owned by the hand-ported `data/scripts/*` map handler. The old Kanto companion treated that marker as a hard stop. The new `lib/KantoDialogue.lua` uses the current `src/script/MapScripts` **base** contribution as the presentation source, with explicit Yellow-only overlays for modules that a Gold host does not attach. This is intentionally **not** a second progression VM.

Every replay session gets a detached save and fake overworld. The real `TextBox.new`/`ListMenu.new` entry points are temporarily captured so engine handlers and `ScriptRunner` rows can run their normal asynchronous dialogue flow; after the sandbox returns, the captured jobs are displayed through TwinRegionWorld's normal Kanto `showMessage`/`askYesNo`/`listMenu` adapters. Continuation callbacks re-enter the sandbox before resuming the handler, which preserves multi-box and choice flows without leaving the patched environment installed between frames.

`Commands.resolve` is narrowed during row-script replay. Dialogue/control/check commands and clone-only flag writes remain functional. Battles and map-leaving commands halt. Other unsafe commands become no-ops. Function handlers are additionally isolated behind the cloned save/fake stack/fake overworld, with native Screens and audio presentation suppressed. Existing Kanto-special handlers run before this bridge and still own any real item/battle/world mutation.

A cache-wide audit is stored in `Twin.kantoDialogueAudit`; `Twin.status()` surfaces the audit plus bridge sessions/handled/fallback/suppression/error counters.

## v0.3.52 — Game Corner physical progression without Yellow story VM

`field.gameCornerPoster` is treated like the other Kanto physical-output tables: it describes one persistent geometry transition, not permission to execute Yellow story state. `KantoState.applyPhysicalBlocks` stamps the closed/open entrance before `ForeignGen1Map` collision and voxel construction; the live poster action writes the companion's namespaced physical event and refreshes that block through the shared `refreshBlock` path.

The poster guard's useful cartridge-side result is likewise represented physically. A Game Corner Rocket trainer win persists a hidden-object key, actor caches are invalidated, and old `yellowTrainerWinsV1` saves are migrated on map entry. This intentionally skips the authored walk-away dialogue/choreography while preventing a defeated guard from permanently occupying the interaction lane. Gold remains inventory/battle/save authority.

The region-local immutable `fieldIndex` now also compiles `field.spinners` by exact cell and `field.badgeGates` into exact checkpoints plus northbound row records. Runtime checks prefer those O(1) tables and keep source-array fallbacks for stale/test fixtures. This extends the v0.3.51 indexing strategy without changing authored field behavior.

## v0.3.51 — Kanto elevation collision + Bicycle ownership

Current Gen1Recomp collision is not only `Map:isWalkableCell`: `src/world/Collision.lua` checks an extracted source/destination tile-pair table after destination passability. Those rows are physical elevation boundaries in cave/forest tilesets, with separate land and water lists. The Kanto companion now mirrors that layer before NPC/boulder occupancy in grid movement and before axis wall sliding in continuous FIRST/THIRD PERSON movement.

Pair rows and other stable field rules are compiled into `region.fieldIndex` once per Kanto region. Symmetric tile-pair keys use the two byte tile ids; bicycle map/tileset membership, dark-map membership, slope maps, forced-bike clear maps and force-bike cells are similarly direct-indexed. Compatibility fallbacks still scan the source arrays for stale/test data without an index.

Manual Bicycle remains Gold-owned. The companion reads Gold's BICYCLE inventory and extracted `field.bikeRiding`, changes only excursion presentation/movement state, and never writes Yellow inventory. `forcedBike` is a separate lock from `biking`: the Route 16/18 gate scripts clear the lock while preserving a mounted rider, which is now safe because KANTO FIELD exposes a normal dismount action.

## v0.3.50 — Kanto Cycling Road + optimization notes

- Cycling Road is kept in the **physical/story-free** layer. The runtime reads `field.forcedMovement.tiles` and `slopeMaps`; no Route 16/17/18 Yellow story script VM is enabled.
- The force-bike state belongs only to the Kanto excursion. Gold inventory remains authoritative for whether a BICYCLE exists, and the companion never writes a Yellow inventory/save location.
- Route 17 idle downhill is map-relative `down` even in FIRST/THIRD PERSON; user directional input remains camera-relative there and wins over the simulated downhill input. Held A/B is a continuous brake, matching current Gen1Recomp's held-state rule rather than an edge press.
- The companion clears both `forcedBike` and its visual `biking` state on the Route 16/18 gate clear maps. This is intentionally safer than native's ability to remain manually mounted because Kanto FREE ROAM does not yet expose a standalone Bicycle item action.
- `KantoState` tables now use a visit-local read-through/write-through persistence cache. Cache lifetime is explicitly bounded by Kanto enter/return; event writes update the cached table immediately.
- `KantoState.restampClosedDoors` defers per-block voxel invalidation and emits one `ChunkMesher.refresh(map.id)` after the batch. Dynamic collision/block values still change immediately; only redundant geometry rebuild requests are coalesced.
- No graphics-quality preset, culling distance or model fidelity was reduced for this optimization pass.

## v0.3.49 — Kanto dynamic geometry is local physical state

Yellow map scripts normally stamp several interior blocks and use event bits to remember which geometry is open. The Kanto companion cannot execute those story scripts safely because Gold remains the authoritative game/save. v0.3.49 therefore mirrors only their **physical outputs** in `TwinRegionWorld`: a namespaced mod-save event table (`yellowPhysicalEventsV1`) plus the Vermilion puzzle state (`yellowTrashPuzzleV1`). Gold inventory/trainer outcomes may authorize those physical changes, but no Yellow cutscene VM or native Yellow save is advanced.

`ensureForeignMap` applies the physical block state before `ForeignGen1Map` collision and `ChunkMesher` construction, so locked/open geometry agrees across movement and rendering. Live changes call `ChunkMesher.refresh` on the changed block. `closedDoorRows` prefers extracted `field.cardKeyDoors.closedDoors` and falls back to the current upstream rows for stale caches. Yellow's Rocket B4F skip is explicit; B1F remains active.

Silph CARD KEY interaction matches a door by authored block coordinate and locked tile/block identity, writes that row's exact event, then opens its row-specific block (`$0e`, or `$03` on 11F). The Vermilion helper consumes extracted `hiddenExtras.trashCans` when present and carries a stale-cache fallback for all 15 cans. Its second-switch picker deliberately reproduces the cartridge's count-as-bitmask selector and zero-result can-0 bug.

Existing trainer wins are migrated lazily from `yellowTrainerWinsV1` through each object's extracted trainer-header event. This keeps physical gates monotonic across upgrades without inventing story progression.

## v0.3.48 — Gold drawWorld is logical, Gen1 worldOverride is physical

The two render-pipeline consumers have different size contracts. Current Gen1 `Renderer:endFrame()` treats `worldOverride` as framebuffer pixels and applies DPI conversion while presenting it. Current Gold `World:drawPipeline()` instead performs `G.draw(override, 0, 0)` inside Game2's already-logical scene. A provider cannot use one normalization rule for both.

`GoldVoxelBridge.frameGeometry()` now branches on generation. Generation 2 uses `ctx.ww/ctx.wh` (the logical Gold scene) as both the required output size and the normalization target; generation 1 retains `EngineViewportCompat.renderGeometry()` and its physical GameViewport/TouchSkin behavior. This is intentionally independent from world coverage (`vw/vh`), which still belongs to camera/culling.

## v0.3.47 — Android TouchSkin framing ownership

Current Gen1Recomp has two nested mobile layout layers that a custom world renderer must not conflate. `GameViewport` owns the game rectangle inside the OS window, while `Renderer.displayMetrics()` then asks `TouchSkin.viewport()` for the actual gameplay drawable inside that game surface. The latter is expressed in framebuffer pixels and may be substantially smaller than the phone framebuffer because the skin reserves control space.

The Gold/Kanto voxel provider previously used the smaller engine world coverage (`viewW/viewH`) but projected it across the full GameViewport framebuffer. `Renderer:endFrame()` subsequently clipped/composited against the TouchSkin gameplay area, making that full-frame projection appear magnified/cropped on Android. v0.3.47 mirrors the engine order: resolve full GameViewport pixels, resolve the TouchSkin drawable, render the world at the drawable aspect/size, then place that image into a full-frame framebuffer canvas for the pipeline/compose handoff.

This distinction also resolves internal-resolution ownership. `graphicsResolution` changes only the private VoxelScene render target; it must never change the dimensions of the canvas returned to current `worldOverride`, which is a framebuffer-sized 1:1 image. Direct physical Android touch polling reserves engine `TouchControls` first, then converts through GameViewport and checks the TouchSkin logical rectangle before steering the camera.

## v0.3.46 — Kanto ledges and connection-overlap parity

Kanto free roam now uses the Yellow cache's extracted `field.ledges` rows as gameplay geometry. The rule is deliberately data-driven: tileset, facing/input, standing tile and front ledge tile must all match. A successful hop owns two cells and may land on a connected outdoor map, using the same connection-offset equation as ordinary Kanto route handoffs. FIRST/THIRD PERSON routes the circular body's ledge collision through this same resolver and exposes an 8px visual lift through the player proxy for voxel presentation.

`ForeignGen1Map.connectionLanding` no longer clamps perpendicular coordinates. Gen-1 map connections represent an overlap strip, not the whole edge; an out-of-strip coordinate now fails closed. This keeps neighbour collision authoritative and avoids inventing a destination-corner landing.

Story/cutscene ASM remains disabled; this release changes physical Kanto traversal only.

## v0.3.45 — Kanto warp/interior ownership

The Yellow companion region intentionally remains a story-free sub-runtime, but its physical movement rules still need to agree with Gen1Recomp's Gen-1 overworld. Current `Map.lua` keys warps/signs by `y * widthCells + x`, border-extends several tile queries, and classifies FACILITY `$20/$11`, CAVERN `$22`, and INTERIOR `$55` as warp pads/holes. The private Gold-side `ForeignGen1Map` now mirrors that surface instead of carrying its older independent lookup assumptions.

Current `Warp.lua` has two completed-step paths: a normal `onArrive` for door/warp collision tiles, then `onCollision`/`ExtraWarpCheck` when the direction remains held (or forced warp state is active). The companion runtime previously did only the first path on a successful step, so non-door carpet/edge warps could be skipped unless movement had physically collided. v0.3.45 adds that second arm while retaining `ignoreWarpKey` so the destination entry tile cannot immediately bounce the player back.

Victory Road 3F's `(23,15)` CAVERN `$22` cell is a walkable physical hole whose fall is normally supplied by the map script, not a regular warp record. Because Kanto story scripts remain deliberately disabled, v0.3.45 bridges only that documented physical fall to 2F `(22,16)`. Seafoam continues to use the existing extracted `field.seafoam` implementation rather than this fallback.

## v0.3.44 — GameViewport ownership

Current Gen1Recomp wraps each Game2 frame in `GameViewport.begin/setTarget/finish`, so `love.graphics.getDimensions()` continues to describe the OS window even while the game is rendering into a smaller local canvas. The render pipeline/compose contexts normally carry the right metrics, but this mod has intentional fallback paths and Android physical-touch polling that bypass normal Game2 callback conversion. v0.3.44 makes those paths viewport-aware without requiring the new engine module on older hosts.

Raw physical touch coordinates are still tested against Gen1Recomp's `TouchControls` before conversion because those controls are OS-window chrome drawn after `GameViewport.finish()`. Camera-space operations then pass through `GameViewport.toLocal()` and discard touches outside the gameplay rectangle. Render fallbacks prefer explicit pipeline viewport metrics, then `GameViewport.dimensions()/pixelDimensions()`, and only use whole-window LOVE metrics as the compatibility fallback.

## v0.3.43 — presentation animation and shared-world frame pacing

Gold's true-direction controller deliberately owns `px/py` without setting `Player.moving`, because setting that gameplay flag would re-enter the native grid-step state machine. DIORAMA does use native grid movement, which is why external/custom player animation worked there. v0.3.43 makes the distinction explicit: `VoxelScene` repairs only the captured player pose to the native 16-frame 0/1 walk cadence, while `OverworldStadium` temporarily mirrors `moving/progress/target/stepFrames` only around Character Selector draw calls and restores the source player immediately.

The Kanto hitch was a second ownership mismatch. v0.3.42 made outdoor Kanto BODY-only, but `GoldVoxelBridge`'s historical map-entry prime still synchronously requested FULL geometry on every root-map id change. v0.3.43 gives `_stadiumSharedWorldBodies` its own promotion path: reuse/queue BODY only. `ChunkMesher.pump(covered, interactive)` also distinguishes real terrain from cache-only warmers; interactive throttling never reduces an urgent visible mesh budget, only background persistent-cache cooking.

## v0.3.40 — Canonical Kanto entry and projection safety

Pallet teleport is no longer inferred from cache destination naming. The companion layer uses Yellow's canonical Red-house door `(5,5)` and a bounded set of immediate south-side landing cells, validates them against the private Gen-1 collision adapter plus projected source material, and remigrates all pre-340 Kanto position persistence. This is intentionally stricter than ordinary movement: it is an entry/recovery invariant that prevents border/scenery coordinates from becoming a saved Kanto origin.

`KantoGen2Style` now requires a generic donor surface tile to be collision-pure across the native Gen-2 blockset unless the authored voxel profile explicitly pins its material. Mixed-use donor art therefore falls back to structure instead of winning a ground vote. Accepted texture matches color through the donor tile's exact PalMap slot/2bpp shade. `KantoGen2Style.PROJECTION_REV` and `VoxelDiskCache` geometry revision are both bumped so old projection geometry cannot survive this classifier change.

## v0.3.35 — Kanto local respawn + field-rule bridge

Kanto now owns a presentation-local heal/whiteout point rather than reusing Gold's native `blackoutMap`. Center arrival/healing stores a safe cell plus LAST_MAP exterior in mod persistence. A Kanto loss still runs the real Gen-2 battle consequences, then the companion layer re-roots at that Kanto Center; RETURN TO JOHTO compares the live hidden Gold world with the anchor captured at Kanto entry and reloads that exact Gold map/cell only when a whiteout moved it.

`KANTO FIELD` is a lightweight START-menu bridge for moves whose destination/state must be Kanto-local: FLASH uses current Gen-2 FieldMoves eligibility and applies a render-light multiplier on extracted `field.darkMaps`; DIG returns to the Kanto LAST_MAP exterior; TELEPORT returns to the Kanto Center point. Spinner RLE from `field.spinners`, hidden coins and `field.badgeGates` run without arbitrary Yellow script execution.

## v0.3.33 — Kanto physical-world gameplay

`TwinRegionWorld` now bridges non-story Yellow field behavior into the Gold/Silver authority model. Cut detection follows current Gen1Recomp's Yellow rules (OVERWORLD tree `$3d`, tall grass `$52`, GYM plant `$50`) and applies imported `field.cutTreeSwaps`, while eligibility is read from current Gen-2 `FieldMoves` (Gold party + HIVE badge). Mutated foreign-map block arrays are persisted and passed through `ChunkMesher.refresh`, so both live geometry and v0.3.32 disk signatures observe the new layout.

Strength uses current Gen-2 FieldMoves party/badge policy (PLAIN badge) but moves Yellow's explicit `SPRITE_BOULDER` object events. Positions live in `yellowBoulderPositionsV1`; invalid destinations, warp cells and occupied cells are rejected. Ordinary boulder movement deliberately stops short of Seafoam hole semantics until `field.seafoam` hole/current events are wired as a dedicated system.

Trainer sight now consumes `trainer_headers.lua` range data and the live Yellow presentation entity's facing. Current `maps.py` stores `movement = STAY/WALK` and puts a STAY object's `SPRITE_FACING_*` in `range`; the bridge now handles that extractor contract (plus the older movement-encoded fallback). WALK objects receive bounded current-map roaming with interpolated poses and collision-safe destination selection.

## v0.3.32 — Persistent sector-cache architecture

The old v0.2.x cache was intentionally disabled after stale/incomplete geometry was reproduced. v0.3.32 does not re-enable that implementation unchanged: `VoxelDiskCache` now uses `EngineCompat.fs()` (engine-owned save/portable routing), a new `VXM3` commit format, a new geometry revision, full map/tile/UV + slot + seam-mask signatures, binary length checks, and metadata-last commits. `ChunkMesher` reads persistent terrain before auxiliary meshes, writes only after the live mesh has landed, and exposes cache-only jobs that never allocate GPU meshes. `TwinRegionWorld` feeds those cache-only jobs across the Yellow outdoor graph while Kanto is active and cancels them on RETURN TO JOHTO.

## v0.3.31 — Kanto residency/streaming performance

Kanto is no longer a second render graph kept warm beside Gold. `GoldVoxelBridge.effectiveOpenWorld()` promotes residency for the Yellow graph only while the Kanto excursion is active (unless the user explicitly enabled OPEN WORLD for Gold), and `TwinRegionWorld.regionRecords()` does not materialize Yellow terrain during ordinary Johto play. `VoxelScene.prefetch()` carries `_stadiumResidencyRegion` and passes `forgetPrevious=true` into `ChunkMesher.setLive()` on Johto/Kanto transitions, so the one-neighbourhood grace cache used for house round-trips does not retain the inactive region.

`TwinRegionWorld.returnToJohto()` now releases Kanto-owned decoded atlas ImageData, colored atlas Images, sprite ImageData/Images, foreign map adapters and actor/sector presentation caches. The imported Yellow tables and persistent Kanto gameplay state remain, so re-entry rebuilds only the needed sector. Direct neighbours request a body mesh even when `neighborVisible()` is false; movement-direction second-ring records can opt into the same background prefetch. Actor map bounds are tested before `entitiesForMap()` so far sectors do not allocate NPC/Pokemon presentation state. Sector BFS results are cached until a palette/map-adapter reset.

The v0.3.30 texture donor path now uses a matched Johto donor tile's own `tilePalettes` PalMap slot when available. That means a pattern-matched Johto tile uses both the real donor pixels and the real Gen-2 palette slot; unmatched/unique Kanto tiles retain the semantic water/grass/ground/door/structure fallback. Gold palette-profile checks are throttled to 0.25 s in steady state.

## v0.3.30 — Yellow Kanto movement and Johto presentation parity

The foreign Yellow Kanto runtime now uses the same continuous first/third-person movement scale as the Gold camera controller (360-degree camera-relative analog vector, diagonal travel, circular body, wall sliding), while preserving its own Kanto cell/warp/encounter state machine at cell crossings. Diorama and Surf continue through the discrete mover. Kanto presentation returns to a canonical Johto Gold palette profile and adds conservative same-semantic 8x8 Johto texture donors; unique Yellow/Kanto patterns are retained when no sufficiently close Johto match exists.

## v0.3.28 — Yellow Kanto free-roam core

The Yellow companion-region adapter is now a persistent, story-free second-region runtime for Gold/Silver. It consumes current Gen1Recomp Yellow cache `text_pointers` / `trainer_headers`, preserves Yellow-authored palette families, and routes non-story systems into Gold's save/battle/UI services: trainer/Gym battles, Kanto badges, Bag pickups, Marts, Center healing, PC storage, wild catching and Surf. `text_asm` story/cutscene handlers remain disabled by design.

## v0.3.27 — Native Gen-2 Kanto parity

The Gen-2 host already routes Johto and Kanto through the same native world/collision/warp/object machinery, so this pass targets the remaining presentation-layer disparity. `Structures.lua` no longer asks whether a tileset is named Johto before applying the authored stepped tree crown. Instead, each voxel profile names its own `tree_crown` source art, and a per-cell art test decides whether a round collision object is an actual tree. `tree_art` separately drives open-world forest border/apron inference. Kanto therefore receives the same tree-hull machinery without reusing Johto tile IDs or turning Kanto boulders/cut trees into trees.
The Kanto adaptive building detector also accepts larger framed candidates (40×32 source tiles instead of 24×16) so tall/wide one-off city landmarks are not excluded by the old house-sized scan ceiling. Its strict full-base, recognized-roof, real-door and no-prior-claim checks are unchanged.

The v0.3.26 adaptive Kanto building fallback and companion-region seam/warp repairs remain in place. StadiumBattleFX/announcer behavior is intentionally unchanged.

## v0.3.26 — Kanto repair pass

This release leaves the v0.3.25 Stadium announcer/import path intact and moves the main work back to the world. Gold's native Gen-2 Kanto now gets a conservative roof fallback plus a Kanto-only adaptive building detector that derives unmatched framed facades from their own map tiles after exact templates have first claim. The optional Yellow companion Kanto receives reciprocal seam repair, Plateau/outside handling, Gen1Recomp-style LAST_MAP and arrival/collision/edge warp routing, safe destination validation, and invalid-position recovery to Pallet Town.

## v0.3.25 — shared PC/Android announcer playback

The importer itself remains the existing platform-neutral flow: desktop uses its normal picker and Android uses the system document picker, then both hand the selected Stadium 1 bytes to the same Lua extractor. The remaining playback bug was a filesystem-namespace mismatch. The announcer persisted WAVs through `SaveData.persistenceFs()`/`EngineCompat.fs()` but later passed those persistence-relative names directly to `love.audio.newSource`; portable desktop storage and mobile storage are not guaranteed to be the audio engine's relative-path namespace. v0.3.25 reads each WAV through the same persistence backend and hands the WAV bytes to LÖVE (`FileData`, with `SoundData` fallback). The new TEST STADIUM ANNOUNCER action exercises that exact path with clip 223.

## v0.3.24 — Android announcer disk-cache fix

The v0.3.23 ROM decoder could complete while its 823 WAV byte strings were stored in a backend that was not guaranteed to round-trip binary records on Android. v0.3.24 uses `SaveData.persistenceFs()` through `EngineCompat.fs()`, matching the existing Stadium model importer. ROM-derived voices are real save-directory WAV files and the announcer loads those paths directly with the audio engine. A cache cannot become READY until write/read-back and playback probes succeed.

## v0.3.23 — Android Stadium 1 announcer importer

The Gen-2 Android ROM row now accepts both private Stadium sources through the same system document picker. Stadium 2 remains owned by the existing 001-251 model/world importer. A validated Pokemon Stadium (USA) v1.0 selection is routed into StadiumBattleFX and its 823 MORT speech streams are decoded incrementally by a pure-Lua mobile-safe decoder into mod-scoped announcer cache storage. No external builder process or bundled voice data is required.

## v0.3.22 — StadiumBattleFX 2.1.7 completeness audit

The v0.3.21 package had copied the entire 2.1.7 Lua tree, but a transitive/runtime audit showed that several important source modules were still reference-only. v0.3.22 activates `StadiumFxPlayer`, the native interpreter/dedicated renderers, source Stadium 1 DSM7 move attachment/camera metadata, native camera selector timing, `StadiumScreenFx` borderless replay, fallback notices and diagnostic/cache actions. `STADIUM_BATTLE_FX_AUDIT.md` records the 77/77 hash audit and the intentionally superseded alternate model/provider backends.

The source Stadium1/embedded-Stadium2 model ownership layers are still not registered. The active model provider remains this project's Gold-aware Stadium2 National Dex 001–251 renderer; a private `BattleHost` compatibility proxy exposes its attachment/hit/faint surface to source effect code. Native Stadium1 frame indices are not written into Stadium2 rigs; native metadata is used for attachment tags and camera choreography while the existing Stadium2 animation router remains authoritative.

`StadiumFxPlayer` now consumes Gold `battle.move_used` / `battle.damage_dealt` events, the Gold animation entry calls `noteMove`, and its fractional clock follows **STADIUM ATTACK SPEED**. The source hit bridge resolves through current `Stadium.hit`; faint timing remains owned by the established Gold/Stadium2 faint lifecycle rather than racing it. Screen-wide source operations are replayed after composition for borderless coverage, with the lighter supplemental wash suppressed when the exact source overlay already drew.

The options hook now exposes cache rebuild and source diagnostic export actions. A compatible external `BATTLE_CINEMATICS` owner using the camera-ownership protocol can suppress this port's attack-camera directive to prevent double camera control.

## v0.3.21 — StadiumBattleFX 2.1.7 presentation port

This release embeds the user-supplied MIT StadiumBattleFX 2.1.7 source and adapts its presentation systems to the Gold/Stadium2 architecture instead of installing its Gen-1 battle/model host wholesale. Gold remains the logic authority; the existing Stadium2 renderer remains the Pokemon-model authority. The port consumes the source's complete 165-move registry/timing/dispatch metadata, 2D cartridge/procedural renderers, full-screen effects, attack-camera profiles, attachment semantics, hit/faint timing, ROM-derived boss-room and trainer-portrait extractors, and announcer routing.

The original StadiumBattleFX Stadium 1 model host and embedded Gen-1 Stadium2 appearance host are intentionally not registered as competing model providers: this project already has a full National Dex 001-251 Stadium2 importer, DSM7 rigs, overworld/battle model lifecycle, shadows, double-battle actors and attachment projection. `Stadium.attachmentWorld` is the compatibility seam that lets source effects use the current animated Stadium2 bones instead. Likewise, ordinary StadiumBattleFX portable arenas do not replace LIVE OVERWORLD BATTLES; compatible ROM-derived boss rooms are opt-in while ordinary fights retain the captured encounter world.

Pokemon Stadium (USA) v1.0 is optional here rather than required. Without it, Gold keeps the 165-move timing/camera/body-animation integration and procedural/world-space fallbacks. With the validated private ROM, the source extractors can build effect textures, Stadium boss rooms, trainer portraits and—starting in v0.3.23—the private 823-clip announcer cache locally. The public source archive still contains no announcer WAVs. A prebuilt personal `assets/announcer` pack remains compatible, but Android users can now build the same playable cache directly by selecting their Stadium 1 ROM through the mod's system Files picker.

## v0.3.20 — modern live-battle movement / impact layer

`BattleModernMechanics.lua` observes Gold's real `src.ui.gen2.BattleState:animForMove()` event and the live battle HP values, but never writes to Gold battle state. It classifies contact-like damaging moves conservatively, builds a temporary attacker approach/return offset, and builds defender recoil only when HP actually drops. `Stadium.updateGen2` adds those offsets only when constructing the model matrices; `arena.player`, `arena.player2`, and `arena.enemy` remain the stable manual-control anchors.

`BattlePokemonControl.lua` now keeps per-side world-space velocity. Left-stick/WASD input is camera-relative, deadzone-rescaled, accelerated toward target velocity and decelerated toward rest. Arena and opponent constraints remove only the velocity component that pushes farther into the boundary, preserving tangential slide instead of hard-clamping the whole motion. During a contact performance or hit recoil, `BattleModernMechanics.movementScale()` temporarily reduces manual motion so the model cannot skate sideways through the animation.

`BattleCinematic.lua` reads the same presentation positions and impact state. The camera therefore follows contact lunges/recoil without moving Gold's battle anchors, uses a tighter FOV during active attacks, and applies deterministic decaying impact shake/zoom after real damage. No game RNG is consumed. The entire layer is fail-soft and can be disabled with `battleModernMotion`.

## v0.3.18 — embedded Weather FX replaces legacy weather

The previous `lib/Weather.lua` was a self-contained four-state post effect that drew rectangular pixel clouds plus simple rain/fog. v0.3.18 turns `Weather.lua` into a compatibility facade over `WeatherFXCore`, with Weather FX 4.10 source/assets vendored under `weatherfx/`.

`WeatherFXCore` deliberately does not execute Weather FX's original `main.lua`. It loads only the weather presentation/state stack and calls it from this host's existing seams: `input.step` advances Scene/TOD/Seasons/WeatherState/Draw/Audio; `VoxelAtmosBridge` attaches the 3D atmosphere directly to this package's `BaseV`; and the existing `Voxel3D.endScene -> Weather.paintOverlay` seam draws Weather FX's remaining 2D layers. This avoids registering a second independent mod, avoids duplicate pipeline ownership, and prevents Weather FX's Steel/Fairy/Dark, variant-encounter, tornado and battle-rule installers from mutating this package.

The embedded `mod.find` facade resolves `STADIUM2_OVERWORLD_MODELS` directly to the live `BaseV` namespace and refuses alternate voxel hosts, so the atmosphere cannot accidentally attach to a separately installed Dramaless/Potato renderer. The old `weatherClouds` option is retired; Weather FX owns cloud presentation.

Third-party `weatherfx/lib/voxel_atmos/*` keeps Campo's MIT licence/notice unchanged.

## v0.3.17 — flight owns player presentation across setMap

Gold `World:setMap` calls `applyPlayerState(Bike.mapSetupState(...))` on every map entry. The v0.3.16 unrestricted flight fallback can intentionally cross a connection that normal ground movement would reject, so its destination edge can be water or a forced-bike area. That makes Gold write SURF/BIKE even while `FlyYourPokemon.state.mode == "flight"`. `OverworldStadium.red3dSpecialCard` correctly suppresses the Character Selector renderer for those normal ground states, which exposed the stock 2D trainer after the seam.

v0.3.17 resolves the ownership conflict in two places: `FlyYourPokemon.preserveFlightPlayerPresentation` keeps the live Gold player NORMAL while airborne and marks `_flyYourPokemonFlight3D`; `OverworldStadium.red3dSpecialCard` ignores Surf/Bike suppression only when that marker is present **and** the exported flight state is still active. Both native and fallback `tryConnection` paths reassert presentation after `setMap`, and landing/session reset clears the marker.

## v0.3.16 — connected flight ignores discovery history; sky traffic is render-only

The previous free-flight `tryConnection` wrapper checked `state.reachedMaps[target]` before loading a connected destination. That made physical riding behave like a Fly-map unlock list. v0.3.16 removes that check entirely: if Gold exposes a valid cardinal connection and `Map.connectionLanding` resolves it, Flight may enter it regardless of prior visitation.

Ambient sky Pokémon live in `lib/AmbientFlyers.lua`. They are never inserted into Gold gameplay ownership; `main.lua` merges them with the existing visible-Wilds provider only at `GoldVoxelBridge.setExtraEntitiesProvider`. `OverworldStadium` recognizes `_ambientFlyingPokemon` for whole-model airborne pitch/bank and suppresses their shadow caster. This keeps the feature separate from player-mount teardown and from encounter/collision logic.

## v0.3.15 — flight reads engine input directly

The v0.3.14 ownership model still used GoldCameraControls as a temporary input mailbox. That was unnecessary and order-sensitive: Game2 calls `world:pollInput(self.input)` before `world:step()`, so FlyYourPokemon's `pollInput` wrapper captured the correct `_stadiumFreeIntentX/Z`, but its later `stepBody` wrapper reset the copy before consumption. The result was a stable mount that could not steer.

v0.3.15 makes Flight independent from that temporary field. The airborne `pollInput` instance guard prevents Gold from creating ground/grid movement intent. At the guarded `stepBody` tail, Flight reads the live engine input itself (`FirstPerson.moveVector`, with an engine-Input fallback), rotates through `FirstPerson.moveWorld` only when the free camera is engaged, and otherwise uses map-relative DIORAMA steering. `_stadiumFree*` remains cleared so GoldCameraControls cannot move the same player a second time.

## v0.3.14 — flight/GoldCameraControls ownership

Free-camera flight must not bypass GoldCameraControls' `World:pollInput` wrapper. That wrapper is where `FirstPerson.moveVector()` is rotated into `_stadiumFreeIntentX/Z`; returning before it leaves the last intent stale while the GoldCameraControls `stepBody` tail is still installed. v0.3.14 treats GoldCameraControls as an **input sampler only** during Flight: its fresh world vector is copied, its free-move ownership fields are immediately cleared, then FlyYourPokemon moves once after the native `stepBody`. This preserves analog/camera-relative steering while preventing both systems from moving the player in the same tick.

## v0.2.95

Kanto terrain no longer uses only `GoldColorAtlas.worldRamp()`. `GoldColorAtlas.worldPaletteProfile()` exposes the resolved active Johto eight-slot palette set and semantic slot hints; `TwinRegionWorld` applies those slots to Yellow water/shore/grass/walkable/door/structure source tiles. The averaged ramp remains a compatibility fallback only.

`pokemonEntity()` no longer requires a successfully generated 2D runtime sheet before creating the Kanto Pokemon entity. Explicit `stadiumDex` / `pokemonDex` identity is enough for `VoxelScenePatch` + `OverworldStadium` to rescue and render the Stadium rig.

The Kanto player still unwraps to the original Gold player for Character Selector identity, but `withFreeVisualWalk()` now mirrors the presentation proxy's px/py/cell/facing/stepFlip/animClock onto that source only inside the draw/shadow pcall and restores every field afterward. Kanto camera-relative movement uses `FirstPerson.moveVector()` + `moveWorld()` + `pointBody()` before Gen-1 collision stepping.

## v0.2.86 performance / perimeter-ocean / Yellow battle bridge

The renderer now centralizes expensive choices in `lib/Quality.lua`. Presets control internal scene scale, ShadowMap sizing/refresh, Water reflection rung, camera-relative far-map/actor visibility, Yellow excursion sector radius and ChunkMesher coroutine budgets. GoldComposeBridge still owns final window composition, so resolution scaling cannot affect Gold UI/input coordinates. Far-map culling is reversible residency/presentation culling only.

`TwinRegionWorld` no longer eagerly decodes every Yellow outdoor atlas. The solved graph remains complete as lightweight placement records; survey atlases are materialized progressively, while an excursion synchronously prepares only its current/connected sector. WORLD OCEAN is a multi-quad perimeter mesh around separate Gold/Yellow land-component bounds and carries rectangle metadata so VoxelScene can skip both water and shadow/reflection work when every strip is offscreen.

Yellow trainers are intentionally **data bridged, not VM bridged**: map-object `trainerClass`/`trainerParty` resolves against the imported Yellow `trainers.lua`, but the resulting species/levels are handed to Gold `World:startScriptedBattle`. This preserves Gold battle/UI/party/save systems while allowing Yellow Gym and ordinary trainer fights. No Yellow story event VM, badge-gate script or cutscene progression is executed. Character Selector receives the hidden original Gold player as renderer identity while Kanto proxy pose data supplies world placement.

## v0.2.84 — Kanto cache/Map compatibility fix

The v0.2.83 twin-region loader had one Gold-only compatibility mistake: a mod-side `require("src.world.Map")` is intentionally served by Gen1Recomp's Gen2Compat as the live Gen-2 Map class. That class classifies outdoor maps from Gold's `environment` field and derives passability from `COLL_*`; inactive Red/Blue/Yellow cache records instead carry Gen-1 tileset names and walkable tile-ID lists. Passing those foreign records through the Gold alias rejected the whole Kanto graph.

`TwinRegionWorld` now owns a small private **ForeignGen1Map** adapter for inactive Gen-1 terrain only. It resolves Gen-1 blocks/tiles, walkable cells, water, grass, doors/warps and counter cells from the inactive cache without patching or replacing Gold's Map module. Inactive cache reads also save/clear/restore `CacheFs.prefix` and run `CacheFs.migrateLegacyRedCache()` before probing so a Gold boot cannot accidentally look for `gold/red/...` and older root-level Red imports are migrated by the engine's own idempotent path.

`GEN-1 KANTO REGION` now implies full stitched-world **residency** while the toggle is ON, independent of the user's saved `OPEN WORLD` option. The bridge and survey zoom use this effective-open-world state, but the actual OPEN WORLD preference is never rewritten. Pallet teleport shares the repaired region loader, so its destination lookup and excursion movement now use the same private Gen-1 map semantics. No DSM7 rebuild is involved.

## v0.2.83 — Presentation-local Gen-1 Pallet excursion

The twin-region loader remains an inactive-cache reader; it still never mounts Red/Blue/Yellow over Gold. `TwinRegionWorld` now exposes a Pallet excursion state built from the namespaced Gen-1 maps. `GoldVoxelBridge.makeState` selects that state only while the excursion flag is active, and `GoldCameraControls` blocks the hidden Gold player's movement/interact input during the excursion. This keeps Game2/save ownership entirely Gen-2 while allowing outdoor Gen-1 collision traversal in the same Stadium voxel renderer.

## v0.2.82 twin-region ocean / Gen-1 companion world

This release deliberately adds the second region at the **voxel-neighbor layer**, not to Game2's live Gold world tables. `TwinRegionWorld` reads an inactive `red/`, `blue/`, or `yellow/` generated cache through engine-owned `src.import.CacheFs`, builds the Gen-1 outdoor cardinal graph with `src.world.Map`, namespaces runtime map ids with `__GEN1__`, and appends those maps to GoldVoxelBridge's OPEN WORLD neighbor list. The existing ChunkMesher, TerrainAtlas, Structures, seam masks, shadows and water renderer therefore remain authoritative. Gold keeps collision, scripts, NPCs, encounters and warps.

The region is normalized once around `PALLET_TOWN`, then translated east of the currently rooted Gold OPEN WORLD graph with a fixed 384px sea gap. Re-rooting Gold during a connection transition translates both graphs consistently. WORLD OCEAN is a single four-vertex plane below native water and grows to combined Gold + optional Gen-1 bounds plus a 768px margin. It goes through VoxelScene's existing reflective water and shadow passes.

The inactive Gen-1 atlas is decoded from cache bytes through `love.data.newByteData` + `love.image.newImageData(Data)` when supported. If that decode route is unavailable, a semantic true-color atlas keeps the authentic map/block geometry renderable without mounting the inactive version over Gold's generated assets.

## v0.2.81 Gold party-leader follower binding

- Trainer `follow` mode now treats the saved party slot as authoritative. Slot 1 remains the default, so Gold PARTY -> SWITCH naturally replaces the follower when the top-of-party Pokemon changes.
- `ControlEngine:_syncFollowLeaderBinding()` runs before player/trailer visual sync and rewrites the persistent follower fingerprint to the Pokemon currently occupying that slot. This fixes the old behavior where `Selection:getActiveFollowerMon()` deliberately chased the starter fingerprint to its new party position.
- Trailer composition also compares `spec.mon ~= trailer.pokepcMon`, not species alone, so same-species and shiny/non-shiny swaps trigger a correct rebind.
- Explicit FOLLOW selections still bind another party slot; the mod does not reorder the party itself.
- No Stadium DSM7 cache rebuild is required.

## v0.2.80 Gen-2 full-color follower recovery

- The mod is Gen-2-only, so its Pokemon follower/wild sprite providers no longer derive Gen-1 luminance sheets based on `PaletteFX.mode`. The original RGBA follower sheets are always served as `trueColor=true`.
- `lib/follower/control_engine.lua` uses colored normal/shiny submerged sheets directly during water-surface refreshes; entering/leaving water can no longer swap a colored follower for a grayscale one.
- Party follower icons use the resolved sprite definition's `trueColor` contract instead of `paletteFxRedpp()`.
- This release changes no DSM format and requires no Stadium 2 cache rebuild.

## v0.2.79 DSM7 render-tile origin/window parity

The RDP texture path is tile-relative: after the tile shift, SL/TL from `G_SETTILESIZE` are subtracted before clamp/wrap/mirror. SH/TH are the inclusive clamp bounds, and mask zero forces clamping even if MIRROR/WRAP bits are present. DSM6 recorded `G_SETTILE` but discarded `G_SETTILESIZE`, so it could not reproduce this after extraction. DSM7 scans both commands, bakes the origin into packed UVs, resolves the effective sampling span, and crops each decoded texture variant to that span so LOVE's native clamp/repeat/mirrored-repeat addresses the same texel range.

## v0.2.78 DSM6 material fidelity + National-number Pokédex

The Stadium fragment parser previously rebuilt textured primitives from texture-table pixels plus a CI4 palette selector, but discarded the render tile's S/T address fields and treated Vtx bytes 12..14 as normals unconditionally. DSM6 persists the per-primitive address/lighting/tint result. Material DL scanning is recursive with a hard budget, render-tile shifts/masks are folded into packed UVs, and LOVE's sampler is switched per primitive to repeat / mirrored-repeat / clamp. A negative Stadium texture index now resolves to a neutral 1x1 material for every species, with DSM6 tint supplying unlit/material colour.

The cache marker now accepts DSM6 rev1 only. This is deliberate: DSM4/DSM5 do not contain the missing material bits, so runtime heuristics cannot reconstruct them safely.

For the modern Pokédex, `GoldSubmenuBattleStyle` wraps the live `PokedexMenu:order()` only while custom UI is enabled and returns a stable sort of `dex.entries[*].dex`. This changes the backing list, not just rendering, so `current()`, cursor movement and 3D preview ownership all use the same National-number row.

## v0.2.77 independent player/Pokémon model ownership

`GoldVoxelBridge` now exports two model gates: `V.modelsEnabled()` remains the Stadium Pokémon gate backed by the existing `stadium3dSprites` option, while `V.playerModelsEnabled()` is backed by the new `player3dModel` option. `OverworldStadium` uses the player gate only for the `red_3d_player` renderer and its mesh-shadow/card-artifact suppression; Pokémon preparation/draw/cast continues to use the Pokémon gate. This means disabling the player model cannot release or flatten Stadium Pokémon, and disabling Stadium Pokémon cannot disable the selected Character Selector skin.

## v0.2.76 Stadium dialogue + extended OPEN WORLD zoom

- `TextBoxBattleStyle` patches presentation only. `src.render.TextBox:update`, substitution, pagination, CONT/page waits, auto/stay semantics and callbacks remain engine-owned. The custom draw reconstructs the currently typed visible prefix from `self.pages` + `Font.split()` and renders it in window space after cancelling Gold's centered 160x144 UI transform.
- `ChoiceBox` receives the same presentation-only treatment; its native up/down/A/B and 15-frame answer hold remain unchanged.
- `DioramaZoom` now reads `worldZoomRange`: STANDARD=2.20, FAR=4.00, WORLD=8.00, EXTREME=12.00. The initial value remains 1.0, so existing camera startup framing is unchanged.
- `OpenWorldZoom` wraps the official `zoom.range` hook. With OPEN WORLD active and a non-STANDARD range, its lower offset becomes `-S`, allowing `Zoom.scale()` to reach the engine's existing 0.25 hard floor. Integer stepping/persistence remain engine-owned.
- Current engine check: `dev` head `7804ef97938c25da4cf86257a161b9f5f32e2a3d`; the shared TextBox and Zoom seams used here are present on that snapshot.

## v0.2.75 battle overlay geometry + posed-model camera fit

- `BattleControllerUI.drawCommandDiamond` now reserves independent vertical lanes. The bottom PACK/DOWN command ends well above the footer, and icon/font size is bounded by panel height so wide/short windows cannot force command text into the stick hint.
- `StadiumRig:posedBounds()` exposes the already-calculated current pose AABB without duplicating skinning internals.
- `PartyModelPreview` builds the current pose before camera selection, transforms its live bounds into preview-world scale, centers the camera on the posed mesh, and computes distance from both vertical FOV and `tan(horizontalFov/2) = aspect * tan(verticalFov/2)`. Model depth is included in the eye distance.
- The Pokédex caller uses posed-bounds horizontal/vertical padding rather than the old bind-height `focusY` workaround.

## v0.2.74 Gold live-battle command startup

- v0.2.74 follower seams: connected outdoor Gold maps now apply the preserved Wilds trailer handoff synchronously inside `map.entered`, after destination people lists are rebuilt but before another render can occur. This removes the one-frame follower pop without recreating the trailer.

- Current Gold `BattleState:update` holds `phase = intro/resolving` text at `messageTimer > 0` until A/B; it then changes to `phase = menu` during a fixed step before the next render. The custom direct controller wrapper previously treated that logical menu state as immediately clickable.
- `BattleControllerUI` now separates **visual readiness** from **input arming**. A normal command menu must complete one `drawCommandDiamond` pass before face-button / arrow / D-pad shortcuts are accepted. Warmup edges are swallowed instead of leaking into Gold's hidden native menu.
- Ordinary custom-UI battle intro prompts are auto-confirmed through Gold's own input queue after a short hold. This is restricted to `phase == intro`, excluding tutorial/contest and all later decision/message phases.
- A mapped face button that is forwarded during intro is marked held in the polling fallback until release, preventing the same physical A/Cross edge from being reinterpreted as PACK when the menu becomes ready.

## v0.2.73 Gold follower ownership correction

- Reverts v0.2.72's Gold-only `partyTrailMons()` reservation: Wilds again supplies follower slot #1 on Gold and owns its interpolation/trail state.
- Gold's native `src.world.gen2.Follower` remains a fallback only. When embedded Wilds is present, native `pikachuFollower` entities are purged while `pokepcTrailer` entities are explicitly preserved.
- This matches the shared Wilds control engine's existing `shouldSpawnStockFollower` behavior, which already suppresses the stock/native follower in ordinary FOLLOW mode when Wilds trailers are active.
- `LEAD PARTY FOLLOWER` now gates the Wilds trail list itself so OFF actually removes followers.

## v0.2.72 Gold follower transition ownership

- Gold's native `src.world.gen2.Follower` owns primary follower slot #1.
- Embedded Wilds `partyTrailMons()` reserves that slot on Gold and only creates trailers for configured followers #2+.
- Extra trailers anchor behind the native Gold follower when present.
- `GoldPartyFollower` de-duplicates orphan native followers on `map.entered` and keeps the current/newest engine entity.
- Native Gold follower species follows the embedded Wilds active FOLLOW selection when available, with party slot #1 as early-boot fallback.

## v0.2.71 Wilds sandbox recovery
- The current mod sandbox throws on `love.filesystem`. Wilds runtime-sheet probes were still dereferencing it during `registerContent()`, aborting the embedded Wilds factory before any map could initialize.
- Wilds asset existence/read paths now use `EngineCompat` (`mod:read` / `mod:info`, with engine-owned persistence FS fallback). Raw `io` fallbacks were removed from the active runtime-sheet/water paths.
- This is additive to v0.2.70: voxel terrain, Stadium models, Character Selector coexistence and compose/drawWorld compatibility remain intact.

## v0.2.70 current-sandbox renderer recovery
- Current Gen1Recomp blocks `love.system` inside mod-owned code. GoldVoxelBridge and GoldComposeBridge now use engine `src.core.Platform` first and guard the complete legacy `love.system` expression inside `pcall`.
- GoldPipelineBridge is active again on current engines through `render_pipelines.drawWorld`.
- If `red_3d_player` / Character Selector is installed, the Stadium pipeline deliberately remains OFF so Gen1Recomp does not zero the selector's `voxel` pipeline. The compose bridge remains the world owner and OverworldStadium still consumes `red3dPlayerRenderer:drawVoxel` for the selected skin.

## v0.2.69 desktop compose/canvas recovery

- Desktop uses the confirmed v0.2.45 `render.compose` ownership path again; `GoldPipelineBridge` is not registered.
- `Voxel3D.canvasRestorePolicy()`, `ShadowMap.canvasRestorePolicy()`, and `AntiAlias.canvasRestorePolicy()` report `physical-screen` on Windows/Linux/macOS/unknown desktop targets and `nested-caller` on Android/iOS.
- `Voxel3D` begin/end cleanup, the `ShadowMap` prepass, and `AntiAlias.resolve()` all follow that same platform policy. This preserves Android's v0.2.58 whole-frame fix without forcing desktop back into an intermediate canvas that can be overwritten by Gold's native 2D present. Because `red_3d_player` is delegated from inside the voxel scene, the same fix also restores the Skin Selector's 3D character path when the voxel world is active.
- The v0.2.68 pipeline file remains in source for reference but is inert in this release.

## v0.2.68 current Gold world-pipeline compatibility

- Current desktop Gen1Recomp now consumes `render_pipelines.drawWorld` on Gold. The old Gen-2 port assumption that Gold had to be replaced only at `render.compose` is no longer sufficient.
- `lib/GoldPipelineBridge.lua` registers `stadium2_gold_voxel` with `priority = 1100`, an OFF/ON ladder, a cheap option gate, and a `drawWorld(ctx)` callback that hands `ctx.state` (the live Gold World) to `GoldVoxelBridge.renderFrame`.
- `game.ready`, `map.entered`, and this mod's voxel/Open World option changes synchronize the engine pipeline level. The mod option remains authoritative; no user hotkey is required to activate the engine world pass.
- `GoldComposeBridge` remains installed. A one-frame handoff bit from `GoldPipelineBridge` tells it when current Gold already rendered voxels, preventing duplicate `VoxelScene` work. If an older host never calls `drawWorld`, the bit is never set and the original compose path runs unchanged.
- The drawWorld canvas uses `ctx.width`/`ctx.height`, matching the engine pipeline compositor. Legacy compose continues to use its existing physical/logical scaling path.

## v0.2.66

- Restored the known-working v0.2.45 live `ChunkMesher` implementation for current/neighbor voxel terrain.
- Removed `VoxelDiskCache` from the live mesher dependency path; persistent disk-cache I/O remains disabled.
- Keeps v0.2.65 Stadium ROM import compatibility and all later UI/follower/settings/Open World features.

## v0.2.66 Stadium ROM import compatibility notes

- Current Gen1Recomp mod sandboxes no longer expose raw `love.system`, `love.filesystem`, or `io` to mod chunks. v0.2.64 still dereferenced those APIs when the Stadium ROM action was pressed, which explains a picker-time crash even after boot recovery succeeded.
- `lib/EngineCompat.lua` now resolves engine-owned `src.core.Platform`, `src.core.SaveData`, `src.core.HostShell`, and `src.import.RomImporter` services behind guarded calls.
- Android/iOS uses the engine RomImporter mobile ROM-picker branch so the native bridge executes in engine scope. `picked_rom.gb` is treated only as a temporary transport filename; the mod validates N64 magic before calling `StadiumInstall.beginFrom`.
- Desktop dialog output is staged into the save directory through HostShell and then read through `SaveData.persistenceFs`; no raw mod `io.open` remains in the Stadium import path.
- StadiumInstall, StadiumPack, and Lugia diagnostic output use the same engine persistence filesystem.

## v0.2.64 recovery notes

- Regression boundary confirmed by device testing: v0.2.45 boots while later builds crash at Play on the same install.
- Startup now guards all optional post-v0.2.45 presentation/settings installers.
- `ModSettingsPersistence` no longer overrides `ManagerState:persistOptions`, rebinds `game.options`, or calls `Game2:persistOptions`; it persists only this mod's changed key.
- `AndroidFullFrameFlip` does not patch `Game2:draw` unless the engine reports Android.
- Persistent `VoxelDiskCache` I/O is recovery-disabled; in-memory meshing/cache remains active.

## v0.2.62 runtime notes
- `PartyModelPreview` builds/skinned the current Stadium pose before selecting the preview camera, scans the posed vertex rows through the actor model matrix, and computes a camera distance from both horizontal and vertical FOV.
- If posed bounds cannot be measured, the previous height/radius estimate remains as a safe fallback.
- UI panel dimensions are unchanged in this release; the fix is entirely the internal model-view camera.

## v0.2.61 runtime notes
- Gen2 `src.world.gen2.Follower` still owns movement/trailing. The mod now changes only that NPC's local `spriteDef` after spawn, keyed by the live party lead's National Dex number; the global `SPRITE_PIKACHU` placeholder remains untouched.
- Pokédex viewer geometry is UI-only; preview camera/model scale is unchanged from v0.2.59.
- Categorized settings keep ManagerState as the value/persistence owner and only restore root cursor/scroll state on category return.

## v0.2.60 runtime notes

- `customUI=false` bypasses PauseMenuBattleStyle, GoldSubmenuBattleStyle, ModMenuBattleStyle, categorized settings presentation and BattleControllerUI ownership.
- GoldComposeBridge ignores pause-backdrop flags while native UI is selected so original opaque/full-screen pages behave normally.
- Pokédex preview panel height is increased without widening the panel or reducing the v0.2.59 model scale.

## v0.2.59 runtime notes
- Stadium UI previews retain high-resolution overscan but use tighter camera distance and a higher focus target. This specifically fixes the v0.2.58 tradeoff where clipping was reduced by making the Pokémon too small.
- No UI panel dimensions changed.
- v0.2.58 cache safety and Android flip rendering remain unchanged.

## v0.2.58 runtime notes
- Current-map correctness now wins over persistent-cache speed: only non-urgent/far FULL maps may be restored from disk. If a disk-restored far map becomes urgent/current, its terrain/water mesh is released and rebuilt before becoming authoritative.
- Offscreen render passes must restore their caller canvas. This is required by Android whole-frame rotation and also makes Voxel3D/ShadowMap/AA composable with future final-frame effects.
- PartyModelPreview's fifth argument is an optional framing table (`renderScale`, `heightExtent`, `radiusExtent`, `cameraMargin`, `focusY`, `fovDeg`). Existing four-argument callers continue to use safer defaults.

## v0.2.55 — Persistent Cache / Settings / Pokédex Preview
- `lib/VoxelDiskCache.lua` persists the unindexed six-float vertex stream produced by ChunkMesher's FFI sink for FULL terrain + water meshes. Cache signatures include map body tiles, dimensions/tileset identity and canonicalized seam masks; cached geometry is uploaded directly to LOVE meshes before auxiliary scenery warms.
- `lib/ModSettingsPersistence.lua` patches the Gen2 ManagerState persistence seam to call `Game2:persistOptions()` after ManagerState updates `save.options.modOptions` / `loader.modOptions`.
- `GoldSubmenuBattleStyle` reuses `PartyModelPreview` for POKéDEX list/entry model showcases and releases the preview actor on PokedexMenu exit.

## v0.2.54 — Native Tilt + Live Pause Backdrops
Gold/Recomp's built-in OPTIONS `TILT` setting now directly changes the voxel diorama camera pitch; the separate mod DIORAMA TILT row is removed. Pause-launched OPTIONS, POKéDEX, POKéMON, PACK, POKéGEAR, AJ/Trainer Card and SAVE keep the live voxel overworld visible behind their custom glass UI, matching MOD SETTINGS.

## v0.2.52 pause settings shortcut
- Uses the official `ui.start_menu.items` hook; no engine StartMenu item table is replaced.
- Injects after the native `option` row, then pushes `ManagerState`, selects this mod by id, and calls its native `openOptions` method.
- Clears ManagerState's intermediate back stack so B returns to START directly.

## v0.2.51
- Added **3D POKéMON / SPRITES** in Mod Options.
- ON (default): current Stadium/3D model presentation.
- OFF: keeps the voxel renderer, OPEN WORLD, 3D terrain, trees, buildings, grass, props, weather and cameras, but restores Gold-style 2D sprite/card characters and Pokemon.
- OFF also disables Stadium model previews in the custom party/battle PKMN menus and releases live-battle Stadium combatants so Gold's normal 2D battle pics can render over the voxel battlefield.
- The lead party follower and visible Wilds Pokemon remain functional using their 2D sprite providers.

## v0.2.50
- Live battle trainer grounding fix: the battle-only trainer stand can still move horizontally for composition, but its vertical height is now anchored to the real player/encounter ground instead of whatever raised tree/cliff voxel happens to sit under the displaced stand point.
- Clears stale step/ledge lift and disables the free-roam visual walking/bobbing bridge while battle mode owns the trainer pose, preventing the trainer from drifting or floating above the ground during camera movement.
- OPEN WORLD full-3D rendering and v0.2.49 tree void filling are otherwise unchanged.

## v0.2.49
- OPEN WORLD tree void-fill refinement: remaining stitched white gaps are now filled by side-aware edge tree sampling, reducing missed holes and making the synthetic forest apron follow the nearby map edge more closely.
- Keeps the open-world + voxel/3D combination intact; this update only refines how remaining outdoor void patches are forest-filled.

v0.2.48 note: OPEN WORLD now backfills remaining outdoor stitched voids with matching tree/forest filler instead of leaving white rectangular holes.


## v0.2.47 OPEN WORLD 3D integration

- OPEN WORLD now implies an active Gold voxel provider; it cannot silently become the engine's flat survey renderer.
- Open-world neighbours use full ChunkMesher meshes with per-map cardinal seam masks. The outside ring/apron remains on boundary maps, closing the visible world perimeter at very large zoom.
- VoxelScene records a per-frame ready-neighbour set and gates neighbour terrain auxiliaries (figures/grass/flowers/shadows) to it. This preserves the current/ready 3D world while farther meshes build.
- TerrainAtlas calls are guarded per map and fall back to the atlas attached by GoldVoxelBridge, preventing a single distant atlas failure from aborting the composed voxel frame.
- OFF retains the original body-only direct-neighbour streaming behavior.

## v0.2.46 — OPEN WORLD now extends, never replaces, the 3D scene

The v0.2.45 graph refactor accidentally deleted `neighborUrgent()` while `adaptedNeighbors()` still invoked it for every depth-1 connected map. That error occurred while constructing the Gold voxel state, so `GoldComposeBridge` correctly failed open to the already-rendered flat Gold frame. The visible symptom was severe: the new map-residency work appeared present, but all of this mod's VoxelScene-only presentation — voxel terrain, 3D scenery/grass and Stadium-model entities — vanished.

v0.2.46 restores the helper and adds a regression test that reaches the actual `adaptedNeighbors()` path rather than testing the graph math in isolation. OPEN WORLD is now treated strictly as a residency-set choice: `makeState()` always carries the same current map, merged Gold entities/visible Wilds Pokemon, ghosts and camera state; ON only expands `state.neighbors` to the connected graph. Consequently every existing VoxelScene pass (terrain/structures, water, figures, actors/Stadium replacements, grass and flowers, shadows) keeps executing.

The option transition is also explicit. `mod.options_changed` invalidates `neighborMapCache` and `openWorldGraphCache` immediately, while the render frame independently re-reads `mod.options:get("openWorld")`. On the first OFF frame, VoxelScene's `open|...` -> `stream|...` live-key transition calls `ChunkMesher.setLive(..., true)`, dropping the far meshes instead of retaining the previous open-world generation.

## v0.2.45 — optional full connected-map OPEN WORLD

`GoldVoxelBridge` now has two residency modes selected by the `openWorld` mod option. The default streaming path is unchanged: adapt the current map's direct cardinal connections, request those neighbour body meshes, and let `VoxelScene.prefetch` / `ChunkMesher.setLive` bound residency to the current neighbourhood.

With OPEN WORLD enabled, the bridge breadth-first walks `map.def.connections` through `world.maps`. Connection offsets are accumulated from each source map so every reachable connected map is expressed in current-map coordinates. Root direct neighbours still prefer Gold's own `world.neighbors` offsets; deeper maps use the same `offset * 32` / source-width / destination-width placement math as the proven direct adapter. The graph excludes warp-only destinations.

The full graph is passed to `VoxelScene` as render neighbours and therefore joins the live mesh/animated-atlas set. Far maps request body-only meshes as normal-priority cooperative jobs; only first-ring destinations near an approached edge become urgent. Current-map border masks are explicitly restricted to `depth <= 1`, and `V.goldNeighbors` remains first-ring-only for third-person camera collision, avoiding world-size scans in those hot paths.

Switching OPEN WORLD off clears the adapted-map graph cache. The smaller `VoxelScene` live key makes `ChunkMesher.setLive` cancel/release far jobs/meshes and `TerrainAtlas.setLive` release far per-map animated atlases. If graph traversal itself fails, the bridge logs it and falls back to direct-neighbour streaming instead of disabling the voxel renderer.

## v0.2.44 — BATTLE COMMANDS is a native/custom UI switch

`BattleControllerUI.owns()` and its input-ownership gate now both return false when the mod option `battleCommands` is OFF. That is intentionally broader than v0.2.43: the scene renderer no longer bakes the replacement HUD into the 3D battle shot, controller/keyboard events are no longer intercepted by the custom command layer, and `GoldComposeBridge` therefore takes its existing fail-open/native path and composites Gold's own Gen-2 battle UI. Turning the option back ON restores the custom Stadium battle presentation without changing battle rules.

## v0.2.38 — actual Gold START menu + exact custom battle-selector styling

## v0.2.40 Mod Manager / third-party pause-menu scope

- `lib/ModMenuBattleStyle.lua` owns the standard Mod Manager presentation for every mod, including per-mod `options_schema` pages.
- A Mod Manager instance created while Gold's START menu is on top becomes transparent so the voxel world remains behind the glass submenu; managers opened elsewhere retain an opaque dark surround.
- The `screen.pushed` listener only replaces drawing for recognizable list-like third-party states in the pause chain. It does not replace their update methods or guess at bespoke custom renderers.
- Built-in Gold pause screens remain owned by `GoldSubmenuBattleStyle.lua`; the bridge detects those tags and does not double-wrap them.


## v0.2.39 pause/submenu presentation scope

The custom START skin now shows the normal full pause list in one tall panel. `GoldSubmenuBattleStyle` tags submenu instances only when their constructor is reached while `src.ui.gen2.StartMenu` is the current stack top. Tagged built-in screens become transparent presentation overlays and receive custom renderers; their original update/action methods are untouched. This prevents field/battle/script users of the same Gen-2 menu classes from being globally reskinned. Pokedex graphics-heavy AREA/search utility views intentionally retain their native renderer rather than discarding gameplay information. Externally injected pause rows remain owned by their injecting mod.

v0.2.37 patched the wrong class (`src.ui.StartMenu`, the Gen-1 path). Gold's visible gameplay menu is `src.ui.gen2.StartMenu`; its rows include PACK and PokéGEAR and every row carries the two-line MENU ACCOUNT description seen in the Gold UI. v0.2.38 patches `src.ui.gen2.StartMenu.draw` directly and leaves `update`, `choose`, `close`, `Chrome.List`, unlock rules and `ui.start_menu.items` hook results untouched.

The renderer intentionally mirrors `BattleControllerUI`'s custom PACK/PKMN selector values rather than merely using a vaguely modern theme: panel fill `0.018, 0.026, 0.045`, 0.82 selector alpha, 0.20 white border, the same 42%-width right-side selector geometry, four visible rows, 0.07/0.17 row fills and 0.72 selected outline. The selected MENU ACCOUNT description is drawn as the same left-side battle-message panel language. Quit YES/NO is also custom-rendered.

`GoldComposeBridge` redraws Gold's visible stack after painting the voxel world. The pause renderer calls `love.graphics.origin()` inside that draw, so on the voxel compose path it escapes the centered 160x144 transform and draws at the same whole-window resolution as the custom battle HUD. A small-target scale fallback keeps the renderer usable on direct native-canvas paths. Any rendering error calls Gold's original `StartMenu:draw()` so the menu cannot become invisible or unusable.

## v0.2.35 — custom in-battle PKMN / PACK overlays

Normal live 3D battles no longer push `Gen2PartyMenu` or `Gen2PackMenu` for the two face-button commands. `BattleControllerUI` holds a lightweight selector state while the underlying Gold `BattleState` remains in `phase == "menu"`, consumes only selector D-pad/A/B events, and draws four Stadium-style rows over the existing world. A valid switch is submitted through Gold's battle action API. Battle items call Gold's `useItem`; party-target item effects call Gold's `applyPartyItem`, with a custom party target and custom move target for single-slot PP items. Tutorial/contest and non-normal submenu flows remain native.

## v0.2.34 — let Gold open its own battle submenus

The controller diamond no longer calls `openPack()` / `openParty()` itself. It writes Gold's own battle-menu cursor (`FIGHT=1`, `PKMN=2`, `PACK=3`, `RUN=4`) and queues a synthetic GB `A` edge on the live `Input` object. On the next fixed step Gold's existing `BattleState:update()` performs the exact cartridge-style branch, including its current `Screens.push` calls, stack ownership, item rules, switch rules and callbacks. The custom HUD also stops owning presentation while the battle state is `submenu`, so the native Pack/Party screen remains visible and receives ordinary input.

## v0.2.32 — guaranteed HUD draw ownership

The v0.2.31 compositor-based HUD could still disappear because Gold's live 3D battle shot and the later UI compositor do not always agree on which stack object owns presentation. v0.2.32 removes that dependency: `VoxelScene.render()` asks `OverworldBattle.battle()` for the exact live Gen-2 `BattleState` and draws `BattleControllerUI` while the world scene canvas is still bound. `GoldComposeBridge` sees the scene-owned HUD flag and skips duplicate overlay composition. If the scene draw fails, the existing compositor/native UI fallback remains available.

The battle occlusion shader now excludes geometry through `groundY + 8.5`, preserving jump ledges and other low map borders while continuing to clear taller trees/bushes/walls from combat sightlines.

## v0.2.32 - controller HUD visibility hardening

The 0.2.30 full battle replacement could hide Gold's native command canvas successfully while failing to surface the replacement command panel on hosts where the live Gold BattleState was not the exact object returned by the simple stack-top lookup. The compositor now asks `GoldVoxelBridge.battleScreen()`, which forwards the BattleState stored by `OverworldBattle.battle()`. It only owns the frame when that BattleState (or a wrapper sharing the same logic battle) is the visible top state, so PACK/PARTY screens still fall back to Gold. The command panel also uses a presentation-only command-ready gate that spans the one-step `resolving -> menu` seam.

# v0.2.29 controller input boundary

The core issue in v0.2.28 was hook placement. `src.core.Input:gamepadaxis` converts `leftx/lefty` into held GB directions using its own hysteresis before `BattleState:update` reads them. Wrapping `Game2:gamepadpressed` could not stop that conversion. `BattleControllerUI.install` now wraps the live `game.input` methods themselves: analog `leftx/lefty` are swallowed only while the normal BattleState owns the screen, and any pre-existing `source="stick"` direction is released/cleared. D-pad input still uses the native path for move/item/party submenus.

Physical face buttons are intercepted at `Input:gamepadpressed` while `phase == "menu"`, before `GamepadMap` maps them to GB A/B. A per-controller release latch prevents the release event from leaking into the newly opened submenu. A frame poll of `isGamepadDown` provides a fallback for platform/controller stacks that miss mapped button events. Keyboard WASD is similarly withheld from native GB directions in the live battle state, while arrow keys activate the four command positions directly.

The camera bug had a separate unreachable seam: Gold's `OverworldBattle.update` intentionally calls `CamControl.tick` only on the non-Gold legacy path. v0.2.29 therefore polls `FirstPerson.pollMappedRightStick` from `BattleCinematic.frameImpl` itself and applies `manualLook` there. This guarantees that the exact camera returned to `VoxelScene` sees right-stick input.

# v0.2.28 battle visibility / controller UI

### Occlusion handling

Gold route geometry is packed into one depth-tested `ChunkMesher` mesh, so fading a named tree/wall object after meshing is not available without rebuilding the map into many draw calls. v0.2.28 handles battle visibility in `Voxel3D` instead. The vertex shader carries uncurved world position; while `BattleScene` draws terrain it enables two camera-to-combatant XZ capsules plus a softer midpoint bubble. Fragments more than five world pixels above encounter ground are dither-discarded inside those regions. Because discarded fragments never write depth, the Pokemon/effects behind them become genuinely visible; ground stays opaque and the uniform is disabled before Pokemon/FX draws.

### Command UI and inputs

`BattleControllerUI.lua` only claims Gold `BattleState.phase == "menu"`. SDL face-button names map spatially to the requested PlayStation layout (`x`/west Fight, `b`/east Run, `a`/south Pack, `y`/north Pokemon). PC arrows mirror those positions. The module calls the same BattleState public methods (`submit`, `openPack`, `openParty`) and reproduces the native Fight entry/Struggle gate, then hands every submenu back to Gold.

`GoldComposeBridge` redraws the 3D battle canvas over the lower native command region before the custom dock, so the old opaque white menu is removed rather than merely tinted. This restoration happens only during `phase == "menu"`; move lists, messages, item screens and party screens remain native.

### Camera/control

Direct Pokemon movement accepts WASD in addition to left stick. `CamControl.tick` now branches live-world battles to `BattleCinematic.manualLook`; the previous code updated `BattleCam` even though `BattleCinematic` owned the rendered camera.

# v0.2.27

- Added direct control of the player's active Stadium 2 Pokemon during Gold live-world battles.
- Left stick moves the 3D Pokemon camera-relative inside a bounded battle arena.
- PlayStation Square / Xbox X (SDL gamepad `x`) triggers real imported Stadium 2 skeletal attack performances. Repeated presses cycle safe non-idle clips for the current species.
- The battle camera treats direct-control mode as player-active and follows the controlled Pokemon.
- Direct movement is presentation-only: Gold remains authoritative for HP, turns, moves, switching, items, catches and battle outcomes.
- Control waits until the player's 3D Pokemon has completed its entrance and is actually visible; trainer intro/tutorial/faint states are not hijacked.
- Lugia retains the v0.2.22 untextured-body material fix and v0.2.26 attack-root pinning/safe-clip exclusions.

## v0.2.26 Lugia attack-stage travel removal

The imported Stadium 2 Lugia attack clips contain camera-stage translation that is valid when Stadium follows one Pokemon with its own shot, but looks like teleporting/flying when replayed as a world-space actor under Gen1Recomp's fixed live-battle camera. Clip filtering alone was insufficient because even visually usable clips can carry the common torso/root through a large stage arc.

`StadiumRig:measureBind()` now retains per-bone bind translations as runtime-only metadata. `StadiumRig:pinBoneToBind()` subtracts the current-to-bind translation of a selected posed bone from every pivot/draw matrix. `StadiumMon:build()` applies this only to Dex 249 while `state == "attack"`, using runtime bone #3 (the uploaded Lugia diagnostic's `bone[2]`, the common torso/root for wings/neck/tail). This preserves local skeletal animation and removes only bulk actor travel. No DSM bytes or shared species routing are changed.

## v0.2.25 Gold attack presentation fail-open bridge

The v0.2.23 OBJ suppression was too optimistic: `BattleState:animForMove` could start Gold's native animation, then Gold could replace that runner with its after-hit animation before `OverworldBattle.update` rendered the voxel shot. The 3D adapter therefore saw no matching runner while the UI wrapper had already hidden `BattleAnimView:drawObjects`.

v0.2.25 latches `{move, side, resolved def, token, elapsed}` at `animForMove` and advances the world-space effect on its own short clock. The skeletal bridge resolves symbolic Gold move keys through `Battle:moveDef` to the move definition's numeric `index` before calling `StadiumMon:attackGen2`. Native OBJ suppression is now fail-open and requires two successful world-space draw frames for the same token before hiding Gold's sprite layer.

## v0.2.16 Lugia root-cause pass: preserve geo joint flags

The previous Lugia recovery passes were working with incomplete packed data. `StadiumFragment` had always decoded command `0x1D`'s `flags` byte, but `StadiumBuild` dropped it when writing DSM4. Stadium's own renderer does not treat all joints the same: `geo_layout.c::func_80018490` converts those bits into a transform mode, and `func_800143C0` selects different matrix/scale behavior from that mode. Lugia's Stadium 2 tree mixes those semantics enough for the lost byte to become visible as detached rigid pieces.

DSM5 adds one raw flag byte to every bone record. Both `StadiumBuild.bindMatrices` and `StadiumRig:pose` now reproduce the two non-camera source paths instead of trying normal/absolute/flat hierarchy guesses. A DSM4 cache cannot be repaired perfectly at runtime because the flag byte was never stored, so the format marker is bumped and a one-time Stadium 2 ROM re-import is intentional.

## v0.2.15 Lugia hierarchy probe / capture skill pass

Dex 249 is no longer rejected before `StadiumPack.load`. `StadiumRig.new` probes the bind pose before `measureBind`, selecting a hierarchy interpretation only for Lugia. The preferred repair keeps parent rotation while treating translations as model-space; the flat mode is used only when it is dramatically more compact. Repaired stance metrics overwrite the stale DSM4 measurements in memory, so existing caches are usable without deletion. Lugia remains `staticPose=true` because Stadium 2 move/context routing still maps all contexts to animation 0; this prevents a provisional clip from tearing the repaired mesh apart.

Capture difficulty now affects both retention and player skill. `strengthResistance` is computed when aim begins, its normalized strength shrinks the on-screen hit radius and speeds the ring, and `throwQuality` has stricter grade cutoffs. `startThrow` stores screen aim error as a lateral/vertical world-space endpoint; `drawWorld` follows that endpoint so a MISS is physically visible.

## v0.2.14 first-map free-camera animation lifecycle fix

The v0.2.13 walking bridge correctly spoofed `Player.moving` only during the external Character Selector draw, but it discovered whether free movement was active through `Game.overworld` / `StateStack`. On the initial Gold map that compatibility facade can lag the live `Game2.world`; crossing a map connection refreshes it, which explains why the trainer animation only began working after a transition.

`GoldVoxelBridge.makeState()` now copies `_stadiumFreeMoveActive`, `_stadiumFreeVisualMoving`, and the animation distance from the exact world being rendered. `VoxelScene.posesOf()` carries the visual-moving bit on the player's captured pose. `OverworldStadium.withFreeVisualWalk()` consumes that pose-local state first, with the old world lookup only as an older-call-site fallback.

## v0.2.13 Lugia fallback and free-camera character animation

Dex 249 remains rejected by `StadiumMon` because the current local Stadium 2 hierarchy decode is known to explode the body into separated parts. The fallback no longer delegates to the roaming entity's generic sprite. `OverworldStadium` retains the resolved Dex id even after rig preparation fails and draws `follower_249_normal.png` / shiny directly through the voxel billboard pipeline with a fixed presentation scale and explicit solid alpha/depth state.

Gold true free-camera movement deliberately advances continuous `px/py` without setting the engine's grid-step `Player.moving` flag. That is correct for gameplay but left external character skins idle because their walk pose can key from the engine flag. `GoldCameraControls` now records `_stadiumFreeVisualMoving` from actual displacement. `OverworldStadium` consumes that bit only around the 3D Character Selector's `drawVoxel` / `drawVoxelShadow` calls: it temporarily exposes moving + walk phase, calls the renderer, and restores the real fields immediately. No collision/script state observes the spoof.

## v0.2.11 manual capture input, Ball material and Lugia safety

The capture trigger now wraps the documented `input.step` mod hook. Gold raises this once per fixed logic tick before `Input:step`, so raw R3/right-mouse edges are visible even if the player has not crossed a cell. `world.stepped` remains useful for spawn updates, but it cannot be the activation clock for a stationary aiming mechanic. The contact handler is intentionally left unset, so Wilds' `_startBattleNative` remains authoritative when the player physically touches a roaming Pokémon.

The supplied Poké Ball COLLADA mesh uses an atlas-oriented material/UV layout that did not map consistently through this renderer's single diffuse texture path. v0.2.11 therefore uses a tiny generated UV sphere at runtime and a dedicated equirectangular Poké Ball texture. The sphere's V coordinate is inverted relative to its latitude so LOVE's image-top V=0 maps red to the north/top hemisphere rather than the bottom.

Lugia's failure is not treated as a mere scale or idle-animation problem anymore. The user's local Stadium 2 decode is visibly separated at the model/bind level, so Dex 249 is a species-specific 3D rejection for now: `StadiumMon:setSpecies(249)` returns false and the existing voxel entity path draws Gold's ordinary sprite billboard. This is intentionally preferable to claiming the 3D mesh is repaired when the local ROM-derived hierarchy cannot be validated in this environment.

## v0.2.07 live-battle trainer presentation

`lib/OverworldBattle.lua` already filters Gold's native `BattleState:drawPic` whenever the corresponding Stadium subject is visible. Earlier builds deliberately exempted `playerSide + showPlayerTrainer`, allowing Gold's 2D trainer back-pic through during the opening. In the live voxel presentation that is now redundant because `VoxelScenePatch` keeps and repositions the actual 3D player trainer beside the player's combatant.

v0.2.07 removes that exemption. During `goldShotFor(self)` live-world battles, a covered player pic is suppressed even while `showPlayerTrainer` is true. The battle state itself is untouched, so Gold still performs the normal trainer-to-Pokémon send-out sequence logically; only the duplicate 2D render is skipped. Non-live/fallback Gold battles still call the native draw path unchanged.

## v0.2.06 overworld capture integration

The visible-Wilds contact seam is wrapped rather than replaced. `OverworldCapture.begin()` only claims ordinary battleable visible encounters when a regular POKé BALL, voxel renderer, empty stack and party/current-box capacity are available; all other cases execute the original `_startBattle` function.

A transparent `_stadiumCaptureOverlay` state freezes `Game2` overworld logic through the engine's existing StateStack update priority while `render.compose` continues to render the live world. `FirstPerson.onTop()` treats only this tagged state as camera-driving, so the existing relative mouse and polled mapped right-stick inputs keep steering aim without making normal menus camera-active.

The user-supplied COLLADA ball was converted to the renderer's Position/TexCoord/Shade mesh format at packaging time. Its diffuse V coordinate is flipped to match the supplied atlas. The runtime ball is transformed directly in Voxel3D and therefore participates in normal world depth/occlusion.

Catch success uses `src.battle.gen2.Catching.attempt`; the caught record is built with `src.battle.gen2.Mon.new`, then stored in the same party/box/Pokédex table shapes used by Gold. The minigame consumes a regular Poké Ball with `Bag.remove` at throw time. Quality modifies the synthetic overworld HP/catch-rate inputs, but the species catch rate remains authoritative.

## v0.2.05 camera input reliability

`lib/GoldVoxelBridge.lua` now treats desktop F6 as an edge-triggered state as well as an event. `Game2:keypressed` still handles the normal low-latency path, but `renderFrame()` calls `pollCameraHotkey()` before resolving `cameraMode`; this protects camera cycling from later callback replacement while a shared `f6Down` latch prevents duplicate cycles.

`lib/FirstPerson.lua` keeps the existing `Game2:gamepadaxis` / raw joystick wrappers and adds `pollMappedRightStick()`. Each update samples connected mapped gamepads' `rightx/righty` axes and chooses the strongest active right-stick vector. That state is processed by the existing squared stick response in `FirstPerson.update`, alongside the existing mouse-delta accumulator, so both devices continue to control one yaw/pitch pair.

## v0.2.04 connected-map voxel streaming

The important Gold compatibility change is in `lib/GoldVoxelBridge.lua`. Upstream Gold already computes connected-map image records (`id/ox/oy/image`) and can look multiple hops outward, but earlier Stadium2 builds intentionally converted that list to `neighbors = {}` because `VoxelScene` requires real Map objects. v0.2.04 adapts the current map's direct cardinal connections back into `src.world.gen2.Map` instances, attaches the same Gold atlas/color renderer used by the current map, and passes those maps to `VoxelScene`.

Only direct connections are rendered as voxel neighbours in this release. That guarantees at least one whole map of look-ahead in every available direction while bounding mobile GPU/memory cost. Gold remains authoritative for actual connection crossing, NPC scripts, collision and warps. Neighbor bodies are async-preloaded; an edge-proximity flag promotes the approached destination to the urgent build slice. A warm body mesh is accepted as the new current-map bootstrap after a seam, while a cold boot still synchronously primes the full map with connected-neighbour masks.

The adapter also adds `map` to matching native Gold neighbour records. This activates existing third-person/follower compatibility code that already expected `nb.map` but previously received only image records.

## v0.2.03 forest apron and battle-camera safety

`ChunkMesher.RING` is now eight Gen-2 blocks, and `Structures.RING/ROUND_RING` match it at 32 tiles. The synthetic outdoor border therefore remains real meshed round-tree geometry for twice the previous distance on all four sides; connected-neighbour masking remains unchanged.

`BattleCinematic.frame` is now an error boundary around the optional camera. It validates battle animation/arena values and returns no placed camera on an unexpected engine shape, allowing the normal overworld camera to render the battle. `OverworldBattle` also uses `(table.unpack or unpack)` with explicit result counts for the `advanceQueue` observer, fixing LuaJIT/LÖVE hosts that do not expose `table.unpack`.

## v0.2.02 active-turn battle framing and trainer sideline

Gold's Gen-2 `BattleState` exposes the real move attacker through `anim.hudSide`, and each queued `move` event also carries its acting `side`. The live battle shim now observes (without consuming or changing) `advanceQueue()` and stores `_stadiumActiveSide` for the current resolving turn. `BattleCinematic` uses the animation's `hudSide` first, then that resolving-turn latch, and clears back to a two-subject frame once the menu/move-selection phase returns. This avoids the v0.2.01 sine-wave guess about which Pokemon should lead the shot.

The cinematic camera now solves an eased shoulder angle behind the acting Pokemon and uses an active-subject-weighted focus point (strongest during a move animation). Between turns it returns to midpoint and resumes the slow orbit.

`exactGoldArena()` now also computes `trainerStand`, offset outward and backward from the player's combatant. The VoxelScene Stadium patch applies that stand point only to the captured **visual pose** of the player when `_stadiumLiveBattle` is set; the engine Player object, collision cell, scripts, post-battle location, and save coordinates are untouched.

DIORAMA's continuous distance clamp is widened from 0.55–2.20 to **0.24–2.20**.

## v0.2.01 continuous diorama lens and live battle orbit

`DioramaZoom.lua` owns a continuous distance multiplier (0.55x–2.20x). `Voxel3D` applies it only to the classic orbit camera distance, so 1ST/3RD placed cameras are unaffected. `CamControl` routes desktop wheel/trackpad events directly to that value on the FULL/DIORAMA rung. `GoldVoxelBridge` also polls `love.touch` directly for two free Android contacts and applies the pinch ratio to the same value, avoiding the late Game2 callback seam that previously made Android pinch unreliable.

`BattleCinematic.lua` builds a placed camera from `OverworldBattle.cameraContext()`: midpoint of the live arena pair, encounter ground height, and current Gen2 BattleState. `VoxelScene` gives that camera final authority only while a live-world battle exists. The orbit radius/height ease rather than cut; `screen.anim ~= nil` tightens the shot during attack animation. Manual right-thumb/mouse deltas are routed to `BattleCinematic.manualLook`, which holds automatic orbit for 2.5 seconds and then resumes smoothly. No battle logic, damage, menus, or world coordinates are altered.

## v0.2.00 Android touch and perimeter runtime paths

The v0.1.99 right-thumb path still lived exclusively inside `Game2:touchpressed/touchmoved` wrappers. On Android builds where the overlay/input chain bypasses a late instance wrapper, those methods never see the free finger; the already-working camera slider had solved the same class of failure by polling `love.touch` each render frame. `GoldVoxelBridge.updateRightLookTouches` now does the same for camera look, rejects overlay/slider contacts, suspends itself when two free right-side contacts indicate pinch, and writes directly through `FirstPerson.lookBy`. It is serviced from both free-roam `renderFrame` and battle `updateBattle`.

For live-world Gold battles, `CamControl.battleLive` now treats `shot.liveWorld` as steerable without consulting `BattleCam.steerable`; that flag belongs to the legacy staged arena and is not initialised by the normal voxel camera used by Gold live-world fights.

The perimeter fix now changes the generated geometry rather than only its class cutoff: `ChunkMesher.RING` is four blocks and `Structures.RING/ROUND_RING` are 16 tiles, so the new outer block is physically present and carved with the same cylinder/canopy tree shapes.

## v0.1.99 Android right-thumb look and perimeter forest depth

`FirstPerson.install(game)` now treats only the right 55% of open Android screen as a free-look touchpad; `TouchControls:hitTest()` still wins for the virtual D-pad/buttons. `CamControl` uses the same right-side gate during battles. For Gold live-world battles, `OverworldBattle.shot().liveWorld` routes drag deltas into `FirstPerson.lookBy()` because that battle background is rendered by `VoxelScene` with the normal placed first/third-person rig; the legacy staged `BattleCam` is retained only for non-live-world battle scenes.

`Structures.ROUND_RING` increases from 4 to 8 tiles while `ChunkMesher`'s full 12-tile ring is unchanged. The extra near belt is still carved through the established profile-driven cylinder/canopy path, so the Johto tree normalization and anti-rectangular-wall safeguards remain authoritative.

## v0.1.98 true-directional Gold walk

`lib/GoldCameraControls.lua` now consumes the unquantised camera-space vector only during ordinary on-foot free roam in the 1ST/3RD voxel rungs. It rotates that vector through `FirstPerson.moveWorld`, updates a continuous world-pixel body with axis-separated collision/wall sliding, and suppresses Gold's cardinal `heldDir` only for those normal walking frames.

The logical Gold cell changes when the body's centre crosses a 16px cell boundary. At that boundary the adapter runs the same gameplay-facing landing chain used by `World:stepBody` (trainer sight, `world.stepped`, warp, coord script, step count, encounter). Forced/special states are not reimplemented: bike/surf, currents, ice, forced doors, ledges, connections and boulder pushes transfer back to native Gold movement.

There is intentionally no `Player.moving` or `Player:walkPhase` spoof. `FirstPerson.bodyYaw` follows the actual travel bearing and external character renderers can infer animation from `player.px/player.py` displacement.

## v0.1.98 camera-mode latch and Gold movement ownership

The v0.1.96 slider could enter 1ST/3RD but AUTO camera ownership then re-read `red_3d_player`'s prior public `voxel` pipeline rung and overwrite a requested DIORAMA on the next frame. `GoldVoxelBridge` now treats direct slider/F6 input as an explicit local camera choice in AUTO/STADIUM control and keeps a runtime `cameraOverride` latch. The choice is mirrored to the selector pipeline when available, but the local Gold camera no longer depends on that mirror sticking. Explicit **CAMERA CONTROL = CHARACTER SELECTOR** ignores the latch and restores external ownership.

`GoldCameraControls` no longer stands down merely because `red_3d_player` is installed/owning camera presentation. The adapter only rotates the requested input vector by the live 1ST/3RD yaw and quantizes it to Gold's native four cardinals before writing `World.heldDir`; it never touches continuous position or animation flags. This restores view-relative walking without reviving the removed v0.1.84 free-movement controller.

## v0.1.96 Android slider input fallback

The slider remains drawn in LOVE window units. v0.1.96 adds a direct `love.touch.getTouches()` / `love.touch.getPosition()` poll inside the Gold voxel render path. It captures only contacts whose current press begins inside the slider and applies the selected camera mode before `Voxel.setLevel()` for that frame. The existing Game2 wrappers remain as a low-latency path, while polling guarantees Android delivery if another input layer bypasses those wrappers.

## v0.1.94 Gold touch-host correction

The standalone Gold bridge passes its live `Game2` owner to `FirstPerson.install(game)`, but v0.1.93 called `CamControl.install()` with no host. `CamControl` therefore required `src.core.Game` and wrapped Gen-1 touch callbacks that never run during a Gold boot. The gesture recognizer itself was correct but unreachable.

`CamControl.install(game)` now follows the same host-injection contract as `FirstPerson.install(game)`. `GoldVoxelBridge.bindGame(game)` passes the current Gold owner into it. `surveyStep()` also detects `game.world:zoomStep()` and uses that for Gold, falling back to Gen-1 only when no Gold world exists.

## v0.1.93 Gold pinch-zoom activation

The embedded `lib/CamControl.lua` already implemented the intended shared zoom input layer, including a two-finger touch recognizer, pinch slack, ThirdPerson continuous boom scaling, survey-zoom accumulation, and coordination with `FirstPerson.dropLook/reseatLook`. The standalone Gold bridge previously loaded `FirstPerson` and `GoldCameraControls` but never loaded/installed `CamControl`, so none of those pinch paths were reachable in Gold/Silver.

`lib/GoldVoxelBridge.lua` now loads `CamControl` and installs it immediately after `FirstPerson.install()`. That ordering is intentional: CamControl becomes the outer touch wrapper, recognizes two open-screen fingers, claims pinch movement before it reaches the look-drag wrapper, and forwards unrelated touches to the normal engine/Character Selector handlers. The bridge exposes `pinchZoomInstalled` / `pinchZoomError` in its diagnostics status.

## v0.1.92 seamless live-world battle start

Current Gold always enters a wild battle through `World:pushBattleTransition()`, which pushes `Gen2BattleTransition` and draws the native expanding black-circle wipe before the battle state appears. In this mod's **LIVE OVERWORLD BATTLES** mode, that wipe no longer matches the presentation because the player is not actually leaving the encounter-site world.

`lib/OverworldBattle.lua` now short-circuits the wrapped `src.world.gen2.World:pushBattleTransition()` path for ordinary wild encounters when `battle3dWorld` is enabled. The mod still snapshots/begins the live-world battle session first, but then returns `false` instead of pushing `Gen2BattleTransition`. Gold's own `World:startBattle()` already interprets a falsey transition result as "push `Gen2BattleState` immediately", so the battle UI/logic stays native while the transition screen is skipped cleanly.

Trainer battles, Safari/contest/tutorial paths, and the classic presentation used when **LIVE OVERWORLD BATTLES** is OFF still use Gold's normal transition behavior.

## v0.1.91 red_3d_player camera bridge

The Character Selector changes Gen1Recomp's public `src.render.Pipelines` level for the `voxel` pipeline. This standalone Gen-2 renderer intentionally does not register a normal drawWorld pipeline, so its private `VoxelState` previously ignored that public level and reapplied `cameraMode` every frame. `GoldVoxelBridge` now reads `Pipelines.levelLabel("voxel")` while `red_3d_player` owns camera control and maps labels containing `1ST`/`FIRST` to the private first-person rung and `3RD`/`THIRD` to the private third-person rung; every ordinary orbit/ZOOM label maps to the diorama rung. Using labels rather than fixed rung integers keeps the bridge compatible with upstream voxel ladder changes.

`FirstPerson.install` still mirrors look input into the private renderer so its placed camera remains visually synchronized, but mouse/touch look events are forwarded to the previously installed handler while external camera ownership is active. `GoldCameraControls` also checks the same ownership function after calling its inner `World:pollInput`: when Character Selector owns the camera, the adapter returns without quantizing or rewriting `heldDir`, preserving whichever Gen-2 movement layer the selector installed regardless of mod load order.

## v0.1.90 battle toggle

Gold reads the `battle3dWorld` option lazily through `OverworldBattle.enabled()`. The option now appears as **LIVE OVERWORLD BATTLES**, defaults to `true`, and cleanly returns `false` before any live-world battle compositor/model staging when disabled, so Gold's normal `BattleState` presentation remains authoritative.

## v0.1.89 Gold-only cleanup and battle compositor

Gold's in-world battle path no longer uses `BattleScene.render` for its backdrop. `OverworldBattle.update` renders the captured Gold state through the same `VoxelScene.render` path used in free roam and marks that state as a live Stadium battle so `VoxelScene` draws/casts the two Stadium models in normal world space. The battle camera therefore stays identical to the encounter camera.

Current Gold `BattleAnimView.present` assumes an opaque battle BG and fills/blits blank scanlines while applying SCX/SCY/BGP effects. With a transparent battle panel that exposed the classic white rectangle (and black outside it) during moves. The Gold shim now bypasses only that background-transform pass while a live-world shot is active; the caller still executes `drawObjects`, so Gold's OBJ move effects continue to render.

The package is also generation-trimmed: only Dex 1–251 generated sprite runtime sheets remain. Raw build-source follow/water atlases and legacy Gen-1-only startup modules are intentionally not shipped.

## v0.1.87 Gold follower / battle / movement correction

### Movement ownership restored
`lib/GoldCameraControls.lua` is back to the v0.1.80-style adapter: camera-relative intent is quantized to Gold's native cardinal `heldDir`. The continuous free-walk position layer is no longer part of this project. `lib/OverworldStadium.lua` no longer overrides player facing from a continuous body yaw and no longer temporarily sets `Player.moving=true` around `red_3d_player` draws.

### Lead-party follower
`lib/GoldPartyFollower.lua` opts into current Gen1Recomp's `src.world.gen2.Follower.setShouldSpawn()` surface. Party slot #1 is authoritative; the engine owns trail movement/map seams, while renderer metadata points the follower entity at the live party mon for Stadium model selection.

### Why v0.1.85/0.1.86 in-world battles did not appear
Current Gold pushes `src.ui.gen2.BattleState`, not `src.battle.BattleState`, and that Gen-2 screen intentionally has no `isBattle=true` marker. The old hook patched the Gen-1 class and waited for `top.isBattle`, so it never owned current Gold's actual battle UI. There was a second Lua bug in `OverworldBattle.begin`: `isGoldGame() and nil or battle` evaluates to `battle` even when Gold is true, because Lua's `and/or` idiom cannot select nil. The session therefore held the Gen-2 battle logic object rather than waiting for its BattleState screen.

v0.1.87 matches the live screen by `top.battle == session.logicBattle`, updates Stadium models through a dedicated Gen-2 adapter, and patches only the Gen-2 presentation layer: the 160x144 white field becomes transparent after a valid voxel shot exists, and each flat Pokemon picture is skipped only when its corresponding Stadium model is healthy and visible. `GoldComposeBridge` alpha-composites that native UI over the window-resolution battle-world canvas.

## v0.1.83 weather fail-safe

The v0.1.82 package contained the intended `Weather.lua` integration in `Voxel3D.lua`, but also had an accidental `VoxelScene.lua -> V.require("WeatherFX")` duplicate. The standalone Gold module loader treats a missing local module as a hard require failure, which caused `GoldVoxelBridge.install()` to fail and the compose layer to fall back to vanilla 2D. v0.1.83 removes the duplicate require/calls. Every remaining `Weather.lua` invocation is guarded with `pcall`; weather is now strictly optional presentation and cannot retire the voxel renderer.

## v0.1.82 weather/sky implementation

`lib/WeatherFX.lua` adds a lightweight atmospheric pass to the standalone Gold/Game2 voxel renderer. `lib/VoxelScene.lua` now calls it twice per frame: once immediately after `Voxel3D.beginScene()` to paint drifting cloud shapes into the already-cleared sky background, and once after the world draw to apply optional fog and rain overlays. The existing `Sky.lua` / `DayNight.lua` path is still authoritative for the sun/moon disc and day-night colouring, so this release layers weather on top of the established sky rather than replacing it.

New options:
- `weatherMode` = `auto | clear | rain | fog | rain_fog | off`
- `skyClouds` = `true | false`

## v0.1.81 packaging change

The mod manifest now sets `experimental` to `false`. Runtime/gameplay code is otherwise the v0.1.80 camera-relative-controls build.

## v0.1.81 camera-relative Gold movement

Gold's native `World:pollInput(input)` stores a world-axis `heldDir`. The first/third-person camera had already rotated visually, but that input was never rotated, producing 2D-feeling movement. `lib/GoldCameraControls.lua` wraps only the Gen-2 poll seam: after vanilla polling (so forced/downhill rules remain available), an actual player movement vector is rotated through `FirstPerson.moveWorld()` and quantised to the nearest Gold cardinal. No continuous-position replacement is used, so `Player:tryMove`, collision, connections, warps, step events, and scripted states remain engine-owned.

# v0.1.79 camera implementation notes

## Gold camera host

The embedded Dramatic Shapes package already contained `FirstPerson.lua` and `ThirdPerson.lua`, but the standalone Gold provider intentionally skipped the old Gen-1 pipeline/input installer and forced `Voxel.setLevel(1)` every frame. v0.1.79 keeps the standalone compose architecture and activates only the camera pieces needed by Gold. `GoldComposeBridge` hands the live Game2 owner to `GoldVoxelBridge`, which publishes it as `V.game`; the camera modules use `game.world` for Gold and keep `Game.overworld` as a Gen-1 fallback.

Gold free roam is treated as `game.world.map` with an empty stack. Any pushed START/text/dialog state makes `FirstPerson.onTop()` false. Look input stops at that point and relative mouse capture is released, while the existing Gold compose bridge continues drawing the UI above the voxel canvas.

## Camera selection

The new `cameraMode` option maps directly to the already-authored VoxelState levels: DIORAMA -> FULL level 1, FIRST PERSON -> level 6, THIRD PERSON -> level 7. The provider ticks `Voxel.update()` and `FirstPerson.update()` with real frame time (clamped for long stalls) before `VoxelScene.render()`. F6 changes the same mode at runtime and attempts to persist it through `mod.options:set` when that API is present; a runtime override keeps the hotkey functional when persistence is unavailable.

Third-person camera collision continues to query the active Gold map's common `inBounds` / `isWalkableCell` surface and the voxel terrain height field. First-person local-player hiding and third-person selected-skin visibility remain owned by the existing VoxelScene/Skin Selector patch, so no duplicate player renderer was added.

## Input scope

This release intentionally leaves Gold's normal grid movement and special movement logic alone. The camera reads mouse/right-stick/touch look input only while its free-roam camera is active. Mouse buttons remain mapped through the existing camera input bridge while relative mode is captured, and unclaimed mouse releases now forward to the engine instead of being swallowed.

---

# v0.1.78 implementation notes

## Root cause: current Gold tileset IDs never reached the authored profile

The tree mesh itself was not the remaining failure. Current Gen1Recomp Gold indexes generated tilesets with constants such as `TILESET_JOHTO`; `World:atlasFor()` returns that tileset record to the mod. The embedded voxel profile, however, is keyed with extraction-style names such as `TilesetJohto`. `TileShape.forMap()` and `Structures` resolve their authored rows through `tileset.id`, so a runtime id left as `TILESET_JOHTO` makes the Johto profile miss and leaves blocked scenery on the generic wall fallback.

v0.1.78 normalizes only the voxel-facing tileset record id in `GoldVoxelBridge.attachRenderer`: `TILESET_FOO_BAR` becomes `TilesetFooBar`. `map.def.tileset` stays unchanged, so Gen1Recomp continues indexing `world.tilesets` with its own native key. The original record id is retained in `_stadiumEngineTilesetId` for diagnostics. This activates the pre-existing Johto `cylinder`/`planter` tree pins and the v0.1.77 stepped tree archetype before the generic volume mesher runs.

## Earlier tree fallback work retained

## Gold outdoor tree-border correction

The tree-block artefact had two related fallbacks. First, `Structures.forMap()` shortened the synthetic forest ring only for the Gen-1 literal `def.tileset == "OVERWORLD"`. Gold outdoor maps are identified through their Gen-2 environment instead, so the repeated Gold `borderBlock` could continue past the expensive round-hull belt and reach the generic rectangular mesher. v0.1.76 detects Gold outdoors with `Map.isOutdoor(def)` and enables the forest-ring treatment only when the actual border block contains multiple tiles the active voxel profile names as `cylinder`, `planter`, or `canopy`.

Second, a cache/blockset variation can leave a real Gold tree cell on the generic blocked-cell `upright` fallback. After normal `TileShape.at()` resolution, v0.1.76 inspects only unresolved 16x16 cells in the real outdoor map body. If at least two of the four source 8x8 tiles are explicit round-tree profile tiles, only the unauthored fallback shapes in that cell are promoted to `cylinder`. Existing authored `planter`, `canopy`, building, cliff, sign, fence, and other pins remain untouched.

The promotion happens before `Structures.buildCylinders()`, so the existing pixel-carved `roundTemplate()` path claims the tree graphics and synthesizes their ground rather than allowing the volume path to build a texture-covered box. Collision is unchanged.

## v0.1.75 red_3d_player / Skin Selector bridge


`red_3d_player` already supports Gold by replacing `src.world.gen2.Player:draw()` and publishing its live ActiveRenderer as `Player.red3dPlayerRenderer`. The standalone Stadium 2 voxel renderer does not call `Player:draw()`; it captures the player as a VoxelScene pose and renders that pose directly. That is why the selector UI and saved character could work while the voxel-world player stayed on the stock trainer card.

The Stadium VoxelScene patch now gives the human player pose to `OverworldStadium.safeDrawPlayerSkin()` before the Stadium-Pokémon and sprite-card fallbacks. The bridge resolves `Player.red3dPlayerRenderer` dynamically and delegates to the selector's own `drawVoxel()` method with this renderer's `Voxel3D`, `Mat4`, and `FirstPerson` modules. The same approach is used best-effort for `drawVoxelShadow()`. No selector models or textures are copied into this package.

The bridge deliberately declines player-as-Pokémon control and Gold's fishing/bike/surf states. Those continue through the existing Stadium/native special-card paths. Because the renderer pointer is read live, selector changes and imported skins do not require a Stadium reload.

# v0.1.71 implementation notes

Current Gold's `World:tryWildEncounter()` checks `Roamers.checkEncounter()` before it reaches `Runtime.call("encounter.roll", ...)`. The v0.1.70 Wilds hook could therefore suppress ordinary table rolls yet still allow a rare invisible roaming-beast step battle. v0.1.71 wraps only `World:tryWildEncounter` and returns false when visible-only mode is active. Explicit encounter systems use other methods and are left intact.

The saved-options migration marker is `_visible_only_v171`. It is intentionally one-shot: inherited v0.1.70 `random_encounters=true` becomes false, but a player who later turns Classic Step Enc back ON is not fought by the migration on every boot.

# v0.1.70 implementation notes

## Current Gold rendering seam

Gold now exposes `render.compose` after its finished scene has been drawn into `sceneCanvas`. v0.1.70 registers one high-priority compose wrapper and uses the payload's `generation == 2` and `worldActive` flags to restrict ownership to live Gold overworld frames.

`lib/GoldComposeBridge.lua` gives the voxel provider first chance. If a voxel canvas is returned, it owns the window for that free-roam frame. If voxel is pending or fails, the compose bridge re-blits `ctx.sceneCanvas` and calls the visible-Wilds fallback renderer. If neither path has work, it delegates to the next compose hook / normal Gold present.

Frames with an active non-opaque Gold stack overlay remain voxel-owned; the bridge redraws only the stack above the voxel frame using Gold's native UI transform.

## Gold encounter adaptation

Current Gold's generated encounter data is grouped under `game.data.gen2Encounters` and is also available from the live world as `world.encounters`:

- `encounters.grass[mapId].slots.MORN|DAY|NITE`
- `encounters.grass[mapId].rates.MORN|DAY|NITE`
- `encounters.water[mapId]`

`lib/spawn_logic.lua` normalizes that structure into the Wilds per-map format before surface selection and weighted spawning. The current live Gold `daytime/tod` chooses the grass slot list.

## Why world.entities was insufficient

Gold rebuilds both `npcs` and `entities`, but its normal `World:drawPeople()` constructs the visible list from the player, `npcs`, and connection ghosts. A Wilds entity living only in `world.entities` can participate in collision/update helpers yet never be drawn by the native people pass.

`lib/GoldWildsBridge.lua` therefore owns visibility separately. It reads the embedded Wilds logic entity table, filters current-map visible wild Pokemon, and exposes the same list to:

1. the compose-time 2D fallback renderer; and
2. the voxel/Stadium entity merger.

The bridge does not permanently add roaming Pokemon to Gold's script-NPC list, avoiding trainer/talk-script semantics.

## Compose-time self-heal

`GoldWildsBridge.visibleEntities()` checks whether the Wilds logic is initialized for the current map. If not, it retries `onMapEntered` through a once-per-second self-heal path. This supplements the normal `map.entered`, `save.loaded`, and `game.ready` bootstrap listeners without running expensive initialization every frame.

## Voxel provider

`lib/GoldVoxelBridge.lua` is a provider rather than an engine patch. It prepares the embedded voxel modules, adapts the current Gold map/tileset atlas, merges player + native NPCs + Wilds roaming entities, and returns a rendered canvas to the compose bridge. A nil canvas is treated as a normal mesh-pending state and falls back to flat Gold + visible Wilds for that frame.


## 0.1.74 Gold overlay-stack correction

Current `src/core/Game2.lua` intentionally gives `render.compose` a single finished Gold scene: `worldCanvas`, `uiCanvas`, and `sceneCanvas` all reference that same texture. The v0.1.73 Gen-1-style `worldOverride` approach therefore could not preserve the Gold UI as a separate pass.

For a live overworld frame (`ctx.generation == 2` and `ctx.worldActive == true`), the bridge now owns the frame, draws the voxel canvas, and then redraws only `host.stack`. The stack is transformed exactly like Game2's live-overworld branch: `world:fitScale()` with a centered 160x144 UI. This keeps START/textbox/non-opaque overlay screens above the 3D world without reintroducing the vanilla 2D map. Game2 excludes opaque/widescreen pages before setting `worldActive`, so those screens continue through the stock full-screen renderer.

## 0.1.73 compose/UI changes

- Removed the deliberate overlay-stack 2D passthrough that made START/pause switch the overworld out of voxel mode.
- On current Gen1Recomp, successful voxel frames are installed with `Renderer:setWorldOverride()` and the hook returns to the stock compositor.
- The engine therefore keeps ownership of the UI pass, including START menus, dialogs, dynamic anchors, fades, wipes, and post-processing, while the world underneath remains voxel.
- Kept a legacy direct-draw fallback only for older experimental compose hosts that do not expose a world override seam.

## 0.1.72 voxel-only changes

- Gold door cells: use `isDoorTileCell(cx, cy)` when available; retain the Gen-1 `doorTiles` table only as fallback.
- Gold warp cells: treat `warpAt` as a method when it is one; never index a function.
- Current-map terrain is primed synchronously once per map through `ChunkMesher.get()`.
- `ChunkMesher.lastError(mapId)` distinguishes failed builds from legitimate pending async work.
- `GoldVoxelBridge` targets FULL level 1 and reports sync-build counters/errors in `voxelStatus()`.
- Wild encounter/spawn behavior was deliberately not changed in this release.



### v0.1.82 weather renderer
`Weather.paintSky` renders clouds after the day/night sky but before world depth. `Weather.paintOverlay` renders rain/fog before the 3D canvas is returned to Gold compose, so START/text UI remains clean above the weather.

## v0.2.21 - Dex 249 diagnostic isolation

The Lugia investigation is now completely side-band. `lib/LugiaGeoDump.lua` reparses only the original Dex-249 FRAGMENT for logging and never feeds values back to `StadiumFragment`, `StadiumBuild.pack`, `StadiumRig`, or `StadiumPack`. This is specifically designed to prevent another all-Pokemon regression while capturing the static transform and display-list nodes the simplified extractor currently discards.


### v0.2.67 desktop voxel recovery
A fresh Gold options block defaults native `TILT` to OFF/0. While `3D VOXEL WORLD` is enabled, that OFF value now selects the voxel renderer's normal 35-degree diorama camera rather than a literal 0-degree/flat camera. Gold TILT 15/35/50 continue to map directly to those voxel pitches; disable `3D VOXEL WORLD` for the native 2D overworld.
