## 3D rider survives connection crossings (v0.3.17)

While free flight is active, the mod now owns the human-player presentation across every Gold map connection. Gold still runs its normal map-entry `CheckUpdatePlayerSprite`, but a destination edge that looks like water or a forced-bike map can no longer leave the rider in SURF/BIKE state and suppress Character Selector's 3D model. Flight normalizes the underlying Gold state back to NORMAL, tags the real player as the active 3D flight rider, and clears that tag on landing. This applies to normal connections and the unrestricted v0.3.16 fallback used for unexplored areas.

## Unrestricted connected-map flight + ambient skies (v0.3.16)

Free Flight no longer treats discovery history as an airspace permission list. The `tryConnection` flight fallback loads a valid connected destination even when `reachedMaps[target]` is false, so a rider can physically cross into unexplored outdoor routes/cities. Indoor/cave takeoff restrictions and safe ground landing are unchanged.

`AMBIENT SKY POKéMON` adds lightweight presentation-only air traffic to outdoor voxel maps. Species selection prefers the live map/neighbor encounter tables and then uses conservative map-class + time-of-day pools; legendary species are blocked. The flyers never enter Gold gameplay entity arrays, never collide or start battles, and do not cast Stadium sun shadows. `SKY POKéMON DENSITY` caps the visible count.

## Flight steering direct-input fix (v0.3.15)

Gold/Game2 promotes input in this order: `input.step` -> `Input:step()` -> `world:pollInput()` -> `world:step()`. v0.3.14 captured the correct vector in `world:pollInput()`, then reset that copy at the start of the guarded `stepBody`, so the air solver always received `0,0`.

v0.3.15 removes the temporary-vector handoff. While Flight owns the player, Gold's normal `heldDir` / `_stadiumFree*` movement state is kept empty and the air solver samples the live `Input.stickAxis` / held D-pad state directly through `FirstPerson.moveVector()` once per logic tick. FIRST/THIRD PERSON rotate that vector through the current camera yaw; DIORAMA maps it directly to world north/south/east/west. The safe Circle/B landing path from v0.3.13 is unchanged.

## Flight steering restore (v0.3.14)

v0.3.13 made LAND stable but also bypassed `GoldCameraControls:pollInput` while airborne. That module is not just normal walking: in 1ST/3RD camera modes it is the owner that turns the current left stick/D-pad into a camera-relative world-space vector. Skipping it froze the previous `_stadiumFreeIntentX/Z`; its continuous-move tail could then replay that old direction forever, which is why Flight appeared to auto-fly straight ahead while the stick did nothing.

v0.3.14 keeps the two movement owners separated. GoldCameraControls is allowed to **sample** the current D-pad/left stick and calculate the fresh camera-relative vector, Fly Your Pokemon copies that vector, immediately clears GoldCameraControls' movement fields, and then the air solver performs one movement update after the native Gold world body. No fresh vector means `0,0`, so releasing the stick stops movement instead of reusing the last direction. Circle/B landing still uses the v0.3.13 safe pre-world-step state transition and the face-button crash quarantine is unchanged.

## Landing crash isolation (v0.3.13)

Controller LAND is now intentionally boring. PlayStation **Circle**, Xbox **B** and Switch **B** are translated by the normal controller-layout layer into logical GB **B**. At `input.step`, Fly Your Pokemon removes that queued edge before Gold can promote it, then commits the landing before `World:step` starts. The landing frame does not touch the global LÖVE controller callback, does not restore world wrappers, does not mutate/delete/retag the Stadium carrier, does not poll SDL for the held LAND button, does not persist options, and does not rumble the controller. The Stadium carrier is presentation-only and simply stops being submitted by `GoldVoxelBridge` when `mountRenderActive` becomes false.

This is specifically designed to avoid conflicts with ControllerLayout, BattleControllerUI, CamControl, PerformanceRuntime, Gold's interaction path, renderer iteration and SDL haptics. Keyboard **H** uses the same queued safe landing request.

For v0.3.13, LAND is intentionally limited to solid walkable ground. Pressing LAND over water refuses with **LAND OVER SOLID GROUND** rather than changing Gold's Surf/player state during the same crash-sensitive transition. Use **SWIM** from the Pokémon action menu to enter visible Surf.

## Flight input quarantine + render-only Stadium carrier (v0.3.12)

**Cross/A is no longer a landing button.** While flying, LAND is **PlayStation Circle / Xbox B / Switch B** (the selected controller layout's cancel button), or keyboard **H**. The airborne Gold interact wrapper now consumes confirm without calling dismount, all LAND requests stay deferred to the post-world-step tail, and the Stadium carrier is parked/hidden rather than removed from the live entity list.

Visible Surf now normalizes a stale Surf state as soon as a completed shoreline step is actually on land. The 3D Character Selector player is allowed to render on that land cell immediately, so leaving the water no longer strands the player as Gold's non-animated 2D surf/normal card.

## Controller landing crash fix (v0.3.09)

While flying, **PlayStation Cross / Xbox A / Switch A** still requests LAND, but the controller callback no longer tears down the Stadium mount immediately. The press is consumed and landing is completed at the end of Gold's next world logic step, after entity/player iteration. Keyboard **H** uses the same deferred landing path.

## Landing and Stadium mount rendering (v0.3.08)

While flying, **PlayStation Cross / Xbox A / Switch A** is LAND. The button is handled directly by the mount system, including while the mount is moving, so it does not fall through to Gold's normal interact queue. Keyboard **H** still toggles Flight.

AUTO/STADIUM mount rendering no longer depends on a 2D follower sprite. If the selected Pokemon has a valid imported Stadium model, the mount can be created and rendered directly from its species identity; 2D art is only the fallback/forced-2D path.

# Fly Your Pokemon — v0.3.02

Built into STADIUM2_OVERWORLD_MODELS; no separate flight mod is required.

## Mod Settings flight control

Open **Mod Settings -> FLY YOUR POKéMON**. The first two rows are now the actual flight controls:

- **FLY = ON** — mounts the selected eligible party Pokémon and enters free flight. Switch it OFF to land/dismount.
- **FLYING POKéMON** — AUTO or a specific supported flying species from your party.

You can therefore use flight entirely from Mod Settings; the shortcuts below are optional.

### v0.3.12 controller-conflict fix
Flight no longer owns `Game2:gamepadpressed` directly. The mod now blocks airborne face/menu presses at the top-level LÖVE callback and scrubs any A/B/START/SELECT edge again at `input.step` before Gold promotes it. This makes the safety independent of transparent stack states and of wrapper order between CamControl, PerformanceRuntime, BattleControllerUI and ControllerLayout. Circle/B queues LAND; Cross/A, Square/X, Triangle/Y, START and SELECT are inert until Flight ends.

### v0.3.11 crash fix
The Stadium flight mount is no longer part of Gold's gameplay entity array. It is fed directly into the voxel renderer by `GoldVoxelBridge`, while the 2D fallback is drawn from the player wrapper. This prevents Gold interaction scans from treating the synthetic Stadium carrier as an NPC. While Flight owns the overworld, face-button presses/releases are isolated from Gold: Circle/B lands; Cross/A, Square/X and Triangle/Y are inert until the player is back on the ground.


## Controls

- Flight: `H`; optional west-face controller shortcut (Square / Xbox X / Switch Y) when **CONTROLLER MOUNT SHORTCUTS** is enabled
- Land while flying: PlayStation **Circle**, Xbox **B**, Switch **B**, or keyboard `H`
- Ground Ride: `G` / `J`; optional north-face controller shortcut when **CONTROLLER MOUNT SHORTCUTS** is enabled
- Cycle eligible mount: `M`
- Altitude: `Page Up` / `Page Down`, or `R2` / `L2`
- Flight Boost / Ground Gallop: hold `Shift`

## Flight mounts (16)
Charizard, Pidgeot, Fearow, Golbat, Aerodactyl, Articuno, Zapdos, Moltres, Dragonair, Dragonite, Noctowl, Crobat, Xatu, Skarmory, Lugia, Ho-Oh.

## Ground mounts (17)
Arcanine, Rapidash, Dodrio, Rhyhorn, Rhydon, Kangaskhan, Tauros, Snorlax, Meganium, Girafarig, Ursaring, Donphan, Stantler, Raikou, Entei, Suicune, Tyranitar.

## Visible Surf mounts (8)
Blastoise, Tentacruel, Gyarados, Lapras, Feraligatr, Mantine, Kingdra, Lugia.

Suicune Ground Ride can cross water after normal Surf progression is available.

## Settings

Open Mod Settings -> **FLY YOUR POKéMON**. SIMPLE exposes the core controls. ADVANCED exposes progression gates, feedback, boost/gallop, air encounters, renderer choice and size controls. Set SIZE OVERRIDES to EDIT to reveal one scale row for every supported mount species.

The Stadium option uses only models generated locally from the user's own legally obtained Stadium 2 ROM/cache. The 2D path uses this mod's active follower-style sprite provider.
## Party action menu

Supported Pokemon now expose ride actions directly in Gold's Pokemon action list:

- **FLY** mounts the selected flying Pokemon and enters free overworld flight. This replaces that Pokemon's vanilla FLY row inside the action list so the label always means ride/fly in this mod.
- **SWIM** mounts the selected water Pokemon and enters Gold's normal Surf movement when you are standing at the shore and facing water.
- Lugia and any future Pokemon present in both rosters can show both actions.

The existing **REQUIRE FLY** and **BADGE CHECKS** settings still control progression. SWIM requires the selected Pokemon to know SURF; BADGE CHECKS controls the Fog Badge requirement.

