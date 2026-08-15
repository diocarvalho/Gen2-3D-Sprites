## v0.2.81 — Party Leader Follower Rebind

Gold trainer FOLLOW mode now follows the **selected party slot**, not the Pokemon identity that used to occupy that slot. The default selected slot is **party slot #1**, so when PARTY -> SWITCH puts a different Pokemon at the top of the list, the visible follower changes to that Pokemon immediately. The selection fingerprint, 2D/3D sprite/model binding, shiny state, and land/water follower art are reconciled before the trailer sync. Same-species swaps are detected by party object identity as well, so two copies of the same species cannot leave the old follower cached. **No Stadium model-cache rebuild is needed for v0.2.81.**

## v0.2.80 — Full-Color Gen-2 2D Followers

Gold's 2D Pokemon follower fallback now keeps the bundled RGBA follower art in full color in every display mode. The old Wilds luminance path was a Gen-1 compatibility technique that depended on a later zone recolor shader; Gold's CGB-native world does not provide that recolor step for custom follower entities, which is why turning 3D Pokemon models OFF could expose black-and-white followers. v0.2.80 removes that stale branch for normal, shiny and submerged follower sheets and keeps the same true-color contract in party icons. **No Stadium model-cache rebuild is needed for v0.2.80.**

## v0.2.79 — Stadium 2 Symmetric Eye / Tile-Origin Fix

DSM6 restored `G_SETTILE` address modes, but Stadium 2 also relies on `G_SETTILESIZE`: SL/TL shift the render tile origin and SH/TH define the clamp window. Ignoring that state can make a symmetric face texture sample correctly on one side and pull the wrong eye/edge on the mirrored side. v0.2.79 rebuilds the local packs as **DSM7**, subtracts the real tile origin before wrap/mirror, forces clamp when the N64 mask is zero, and stores a texture variant cropped to the RDP's effective sampling window.

**Important:** DSM7 needs one more one-time rebuild from your Stadium 2 ROM. DSM6 cannot be upgraded in place because SL/TL/SH/TH were not stored. No ROM or extracted model data is shipped with the mod.

## v0.2.78 — Stadium 2 Material Recovery + Numbered Pokédex

This release upgrades the local Stadium model cache to **DSM6**. The ROM extractor now keeps the N64 material state that DSM5 discarded: palette bank, wrap/mirror/clamp addressing, coordinate masks/shifts, lighting state and neutral material tint. The fix is central and applies roster-wide rather than hard-coding the reported problem species. Textureless material pieces are also rendered for every species instead of using a Lugia-only exception.

**Important:** the first run after v0.2.78 must rebuild the Stadium packs from your own Stadium 2 ROM. DSM5 cannot be upgraded in place because the lost material bits are not present in those files. No ROM or extracted model data is shipped with the mod.

The custom Pokédex now keeps its actual row array in strict **National Dex #001–#251 order**, so the list, cursor, selected model and displayed number cannot disagree. Turning `CUSTOM UI / MENUS` OFF still returns to Gold's native NEW / OLD / A-Z Pokédex behavior.

## v0.2.77 — Independent Pokémon + Player 3D Toggles

The **3D MODELS** settings category now has two independent presentation switches. **3D POKéMON MODELS** controls Stadium 2 Pokémon only (wilds, followers, battles and model previews). **3D PLAYER MODEL** controls only the human Gold player skin supplied by `red_3d_player` / 3D Character Selector. This lets you keep all Pokémon in Stadium 3D while using Gold's normal 2D player sprite/card, or keep the 3D player while returning Pokémon to 2D.

The voxel world, 3D scenery, OPEN WORLD, camera and weather systems remain independent of both switches. Existing saves keep their old `stadium3dSprites` value as the Pokémon setting; the new player switch defaults ON.

## v0.2.76 — Stadium Dialogue + Whole-World Zoom

Ordinary Gold dialogue and YES/NO prompts now use the same translucent dark-glass visual language as the custom pause, Pokédex, party and battle interfaces. The engine's TextBox/ChoiceBox still owns substitution, typewriter speed, paging, auto text, YES/NO selection and callbacks; this release only replaces presentation while `CUSTOM UI / MENUS` is enabled.

A new **OPEN WORLD ZOOM LIMIT** setting adds four camera ceilings: **STANDARD 2.2X**, **FAR 4X**, **WORLD 8X** (default) and **EXTREME 12X**. Your game still starts at the normal 1X view, but wheel/trackpad/pinch can now pull the diorama much farther back. When OPEN WORLD is active, FAR/WORLD/EXTREME also widen Gen1Recomp's native survey ladder through `zoom.range`, adding a 0.25-scale whole-region view for native/Character Selector ZOOM compatibility.

## v0.2.75 — Battle Layout + Full Pokédex Model Framing

The controller battle-command overlay now has dedicated vertical lanes for its title, command diamond, command labels and footer, so `PACK / DOWN` cannot collide with the stick hints at the bottom of the panel.

The Pokédex/party Stadium preview camera now measures the **current animated 3D pose** and fits that pose against both the vertical and horizontal field of view. Tall portrait preview boxes therefore keep wide wings/tails and tall heads/feet completely visible instead of clipping the model at the viewer edges.

## v0.2.74 — Automatic Battle UI Startup

Connected outdoor Gold map seams now reattach preserved Wilds followers synchronously, eliminating the one-frame follower pop/flash.

The custom live Gold battle HUD now reaches the command panel without requiring a physical controller press. Ordinary battle-intro PromptButton pages auto-advance after a brief hold, and direct FIGHT / PACK / PKMN / RUN shortcuts remain disarmed until the command panel has actually been rendered at least once. A held button used during the intro is latched until release so it cannot also trigger an invisible command on the first menu frame.

## v0.2.73 — Moving Follower Ownership Fix

v0.2.72 removed the duplicate but reserved follower slot #1 for Gold's native follower even though the embedded Wilds control engine still suppresses that stock/native mover in normal FOLLOW mode. The result was exactly the reported regression: the active Wilds trailer disappeared and a stale native transition copy could remain standing in the old spot.

v0.2.73 restores the **Wilds trailer as the one authoritative moving follower on Gold**, including slot #1. Native Gold `pikachuFollower` copies are suppressed and cleaned instead of being chosen as the primary. `FOLLOWER COUNT = 1` therefore means one moving follower again, while larger counts add only intentional extra Wilds followers.

## v0.2.72 — Gold Follower Zone-Transition Fix

Gold now uses one authoritative primary follower: the engine-owned `src.world.gen2.Follower`. The embedded Wilds follower controller reserves slot #1 for that native entity instead of creating another party trailer for the same Pokémon. This prevents a second follower from being left frozen behind after changing zones/maps. Follower counts above 1 still add intentional extra Wilds trailers, and stale native duplicates are removed during transition cleanup.

## v0.2.71 — Wild Pokémon Sandbox Recovery

Current Gen1Recomp blocks raw `love.filesystem` from mod-owned Lua. The embedded Wilds runtime still used that API during runtime-sheet and sprite probes, which could abort Wilds before map initialization even while the voxel world and 3D skin selector were healthy. v0.2.71 routes those checks through `mod:read`, `mod:info`, and the engine compatibility filesystem so roaming Pokémon can spawn, walk, chase, and render in grass/bushes again.

**Current release: v0.2.81**

## v0.2.70 — Current Gen1Recomp Voxel + Character Selector Recovery

Current Gen1Recomp now sandboxes mod-owned code more strictly. v0.2.70 removes the remaining direct `love.system` dereferences from the live Gold voxel/compose bridges, restores the engine-supported Gold `render_pipelines.drawWorld` path, and keeps a deliberate `render.compose` coexistence path whenever `red_3d_player` / 3D Character Selector is installed so its skin/camera pipeline is not disabled.

## v0.2.69 — Desktop Voxel Compositor Recovery

Two independent Windows PCs reproduced the same result: the option said **3D VOXEL WORLD = ON**, but Gold stayed native 2D, while Android still rendered voxels. v0.2.69 restores the desktop canvas-exit behavior from v0.2.45, the build confirmed to render 3D on the same current PC setup.

On desktop, the **voxel scene, shadow-map pass, and anti-alias resolve** now all finish on the physical window instead of restoring an intermediate compositor canvas introduced in v0.2.58. Android/iOS keep the nested-canvas behavior because their whole-frame presentation path needs it. The experimental v0.2.68 Gold `drawWorld` pipeline is also disabled so there is only one world owner: the proven `render.compose` path. This also restores the render path used by the optional 3D Character/Skin Selector integration, which is drawn inside the voxel scene.


The 3D Pokémon viewer boxes are unchanged, but the Stadium preview camera is now much tighter and vertically re-centered. Pokémon appear substantially larger while keeping heads, feet, wings and tails inside the viewer. The same framing is used by the Pokédex, Party/Summary and battle selectors.

## v0.2.58 — Cache Safety + Android Flip + 3D Preview Overscan
- **VOXEL DISK CACHE** is now restricted to distant OPEN WORLD visuals. The map the player is actually standing/colliding on is always rebuilt from live Gold map data; a cached far map is discarded/rebuilt the moment it becomes current. Cache entries are revisioned again and incomplete terrain streams are rejected.
- **FLIP SCREEN 180 DEGREES** on Android now keeps the entire gameplay render inside the final-frame canvas: voxel scene, shadow prepass and anti-alias resolve all restore the compositor target instead of escaping to the physical screen. Touch remapping from v0.2.56 remains.
- Stadium model previews render to a larger internal overscan canvas and use a wider safety camera. The Pokédex gets extra headroom for birds/flying/extreme animations such as Pidgey without enlarging the glass UI box.



## v0.2.55 — Persistent Voxel Cache + Saved Settings + 3D Pokédex
- **VOXEL DISK CACHE** is ON by default. The first map build is unchanged; later launches can restore cached FULL voxel terrain directly, making repeated OPEN WORLD starts much faster on weaker phones.
- MOD SETTINGS now persist through Gold/Gen2's actual options writer, so toggles and choices survive a restart.
- The custom POKéDEX list and entry pages now show the highlighted seen Pokémon's live Stadium 2 3D model preview. Unseen species stay hidden and the 3D POKéMON / SPRITES toggle still controls model use.

## v0.2.54 — Native Tilt + Live Pause Backdrops
Gold/Recomp's built-in OPTIONS `TILT` setting now directly changes the voxel diorama camera pitch; the separate mod DIORAMA TILT row is removed. Pause-launched OPTIONS, POKéDEX, POKéMON, PACK, POKéGEAR, AJ/Trainer Card and SAVE keep the live voxel overworld visible behind their custom glass UI, matching MOD SETTINGS.

## v0.2.52 — direct pause MOD SETTINGS
- The Gold START/pause menu now shows **MOD SETTINGS** directly below **OPTION**.
- It opens this mod's real ManagerState options page, including 3D VOXEL WORLD, OPEN WORLD, 3D POKéMON / SPRITES, battle, camera and other settings.
- Press B/Circle from the direct settings page to return straight to the pause menu.

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

## v0.2.47 — true OPEN WORLD + voxel 3D

This build changes OPEN WORLD from a residency experiment into the literal combination requested: the large stitched Gold world and this mod's normal voxel/Stadium renderer are the **same scene**. With OPEN WORLD ON, every cardinally connected outdoor map is adapted into the shared coordinate space and requested as full voxel geometry. Internal connection seams are masked; outside edges retain the normal voxel border/apron instead of opening to empty sky. Trees, buildings, props, tall grass, flowers, NPCs and roaming/Stadium Pokemon keep using the normal 3D paths.

The renderer is also incremental and fail-soft now. A far map that is still building simply waits; all already-ready maps continue drawing in 3D. One distant tileset/atlas problem no longer makes GoldComposeBridge abandon the entire voxel frame and show the flat native overview. OPEN WORLD itself keeps the voxel provider active, so an older save cannot accidentally combine `openWorld=true` with `voxel3d=false` and get only the 2D map.

This mode is intentionally expensive. Switch OPEN WORLD OFF to go back to the normal current-map + direct-neighbour streamer and release distant meshes.


## v0.2.46 OPEN WORLD + full 3D renderer fix

v0.2.45 had a runtime regression in the new connected-map adapter: it still called the direct-neighbour urgency helper after that helper had accidentally been removed. That exception forced GoldComposeBridge onto its flat fallback, which is why OPEN WORLD could appear to change map coverage while the voxel terrain, 3D trees/grass/props and Stadium Pokemon presentation disappeared.

v0.2.46 restores that helper and keeps OPEN WORLD as a residency extension of the normal 3D scene. With OPEN WORLD ON, the complete cardinally connected map graph is still loaded/retained, but it goes through the same VoxelScene that draws voxel terrain, structures, grass, flowers, NPCs, roaming Pokemon and Stadium models. With OPEN WORLD OFF, the renderer immediately returns to current-map + direct-neighbour streaming and releases the far residency set.

The toggle is read every frame and also listens for the Mod Manager's live `mod.options_changed` event, so changing ON/OFF no longer leaves a stale full-world graph behind.

## v0.2.45 OPEN WORLD toggle

Mod Options now includes **OPEN WORLD**. It defaults **OFF** so the current streaming renderer keeps its normal performance profile. OFF loads the current Gold map and its directly connected cardinal neighbours.

Turn **OPEN WORLD = ON** to traverse the complete cardinally connected map graph from the current area. Every reachable route/town/outdoor connection is positioned in the same world coordinate space, its voxel mesh is queued in the background, and completed maps remain resident and are rendered together. This is deliberately connections-only: warp destinations such as houses, caves and other interiors are separate spaces and are not pasted into the outdoor plane.

This mode is intentionally expensive. Large connected regions can consume much more RAM, GPU memory, CPU build time and draw time. You can switch it back **OFF** live; the far-map mesh/atlas live set is then released and normal one-map-ahead streaming resumes. Direct edge destinations keep priority over far-map background jobs so nearby terrain still loads first.

## v0.2.44 BATTLE COMMANDS native-UI fallback

The **BATTLE COMMANDS** Mod Option is now a complete battle-presentation switch. **ON** keeps the custom Stadium HUD, command diamond, custom battle selectors and direct command shortcuts. **OFF** gives battle presentation and battle-menu input back to Gold, so the original Gen-2 battle screen, command box, move menu and native PACK/PKMN flow are shown instead of merely hiding the custom command panel. The 3D overworld, pause menus and other mod features are unaffected.


## v0.2.42 3D Party runtime fix + battle PKMN preview

v0.2.42 fixes the v0.2.41 party-model feature against the actual Gen1Recomp v0.1.83 runtime. `Gen2PartyMenu` and `Gen2SummaryMenu` now receive the custom 3D presentation deterministically instead of depending on the START-menu state still being detectable while their constructor runs. The live Stadium battle `PKMN` selector now also shows the highlighted party member's Stadium 2 model on the left, and the item-target party selector uses the same preview.

The preview renderer now saves/restores Voxel3D's scene bookkeeping around its temporary canvas so opening a party preview cannot steal the current overworld/battle render target. Eggs and unavailable packs still fail open to an in-theme text fallback.

## v0.2.41 3D Pokémon Party screen

Opening **POKéMON** from the custom Gold pause menu now turns the left side of the interface into a live Stadium 2 showcase for the highlighted party member. The imported model idles in place and slowly turns toward each side while the full party list, HP bars and normal Gold navigation stay on the right.

The preview card also shows the selected Pokémon's species/Dex identity, level, HP and status in the same translucent battle-menu language. Choosing **STATS** keeps that model visible and replaces Gold's summary presentation with matching STATUS/EXP, MOVES/ITEM, STATS/TRAINER and move-detail pages. Eggs get an Egg-specific card, and a missing/unbuilt Stadium 2 model gets a readable in-theme fallback rather than breaking the party menu. The preview is pause-scoped: battle party pickers, item-target party lists and scripted PartyMenu uses keep their original presentation/behavior.

This is still Gold's real `Gen2PartyMenu` underneath. STATS, SWITCH, MOVE, ITEM/MAIL, field moves, item targeting and every party mutation remain owned by Gen1Recomp; v0.2.41 only adds the 3D presentation layer and releases its preview rig when the party screen closes.


## v0.2.40 matching MODS + third-party menu bridge

- The pause-menu **MODS** row now opens a matching translucent Stadium-style **MOD MANAGER** submenu over the voxel world instead of dropping into the old white/black manager UI.
- Selecting any installed mod opens a matching detail submenu; that mod's **OPTIONS** row opens another matching submenu for its `options_schema`. This applies to every installed mod using Gen1Recomp's standard Mod Manager, not only this mod.
- Profiles, permissions, errors, apply/restart prompts and Mod Manager confirmation overlays use the same glass panels, rounded rows, white outlines and footer language.
- A pause-chain `screen.pushed` bridge also auto-skins conventional third-party list-like menus opened by mod-injected START rows. Unknown bespoke renderers are deliberately left native instead of being guessed at, but their descendants remain eligible for the bridge.
- All menu action/update/persistence logic remains engine- or third-party-owned; this release replaces presentation only.

## v0.2.39 tall pause menu + custom pause submenus

The Gold START panel now expands vertically to show the normal complete list at once instead of forcing the custom battle-style presentation into four visible rows. The common eight-entry layout fits in one panel; only unusually large lists injected by other mods scroll.

Selecting the built-in Gold entries now keeps the same **custom battle UI made by this mod** instead of falling back to white Game Boy menus. POKéDEX, POKéMON, PACK, PokéGEAR, the trainer/status card, SAVE and OPTION are pause-scoped custom overlays using the same translucent navy glass, rounded rows and bright selected outline as the in-battle custom PACK/PKMN selectors. Party/Pack action popups, Save YES/NO, Pokegear phone actions and Pokedex entry actions receive the same treatment. Gold still owns every underlying action and state transition.

A START row injected by a different mod (for example MOUNTS) still appears and works, but that mod's private screen is not force-skinned because its internal state/layout is not part of this package.


## v0.2.38 custom battle-style Gold pause menu

The replacement now targets Gold's **real Gen-2 START menu** (`src.ui.gen2.StartMenu`) — the menu with POKéDEX / POKéMON / PACK / PokéGEAR / player / SAVE / OPTION and mod-added entries such as MOUNTS. v0.2.37 mistakenly targeted the Gen-1 StartMenu path, which is why the original white Gold menu could still appear.

The Gold pause menu now uses the **same custom UI made for this mod's in-battle PACK/PKMN selectors**: the same dark translucent navy panel, thin white outline, four visible rounded rows, selected-row glow/outline, title/meta typography and battle-selector footer. MENU ACCOUNT descriptions are kept in a matching battle-message panel on the left, and the quit confirmation uses the same custom selector styling. Gold still owns the actual menu actions and input underneath.

The Android options remain unchanged: **ANDROID CAMERA SLIDER** can completely hide/release the DIORAMA/3RD/1ST strip, and **FLIP SCREEN 180 DEGREES** rotates the final composed Android frame.

## v0.2.36 Android/UI update

The mod settings now include an **ANDROID CAMERA SLIDER** toggle that fully releases the hidden slider's touch area, plus **FLIP SCREEN 180 DEGREES** for reverse-landscape Android use. v0.2.36 also introduced a custom Mod Options skin; v0.2.37 supersedes that UI target and restores normal Mod Settings while moving the Stadium treatment to the actual pause menu.


**v0.2.35 custom battle selectors:** Triangle/PKMN and Cross/PACK now stay on the live Stadium battlefield instead of opening Gold's full-screen menus. Both use the same four-row glass list style as the move picker. Party-target items remain in the custom HUD, and Ether-style single-move PP restoration gets a matching move-target list. Gold still owns the actual switch/item/catch/heal rules underneath.

## v0.2.29 — battle controller input ownership fix

**v0.2.34 battle submenu fix:** the four face-button battle commands now use Gold's own native battle-menu dispatcher instead of re-implementing PACK/PKMN in the mod. Square/X, Circle/B, Cross/A and Triangle/Y select the corresponding native menu slot and queue one synthetic GB A press. This means PACK and PKMN are opened by current Gen1Recomp's own `BattleState:update` / `Screens.push` path, and the replacement HUD fully yields while those native submenus are on screen.


The battle controller split now happens at Gen1Recomp's actual `Input` object instead of the outer Game2 callbacks. In normal live 3D battles, the **left analog stick is reserved for moving the Pokemon** and no longer becomes menu Up/Down/Left/Right. **Square/Xbox X = FIGHT, Circle/B = RUN, Cross/A = PACK, Triangle/Y = PKMN** are intercepted before they become ordinary Game Boy A/B input. On desktop, **arrow keys** are the command shortcuts while **WASD** remains Pokemon movement.

The **right stick is sampled directly by the visible `BattleCinematic` camera every frame**, so it no longer depends on the Gold path calling `CamControl.tick`.

## v0.2.28 — clear-sight live battles + controller command diamond

Live 3D battles now keep the real encounter map while automatically dissolving tall scenery that blocks either Pokemon from the active camera. Trees, walls, shrubs, fences and other tall voxel geometry in the camera-to-combatant sight corridors are dither-faded through the depth shader; ground stays opaque, and scenery outside the fight remains fully visible. This avoids replacing the route/forest with an empty arena while keeping both fighters readable.

The four-command battle menu is replaced during the `menu` phase by a compact controller-layout dock: **Square / Xbox X = FIGHT**, **Circle / Xbox B = RUN**, **Cross / Xbox A = PACK**, and **Triangle / Xbox Y = PKMN**. On PC the arrow keys mirror the same spatial layout (Left Fight, Right Run, Down Pack, Up PKMN). Opening FIGHT, PACK or PKMN hands control straight back to Gold's native move/item/party screens.

Direct Pokemon locomotion now accepts **left stick or WASD**. The **right stick controls the camera that actually renders the live battle**; v0.2.27 was still feeding those axes into the legacy staged `BattleCam`, so they could move an unused camera state without changing the visible shot.

## Direct Pokemon battle control (v0.2.27)

In live 3D Gold battles, once the player's Stadium model is on the field, the left stick moves it around the staged arena. PlayStation Square / Xbox X plays one of that species' imported Stadium 2 attack performances. This is currently a presentation-control layer: Gold still decides move damage, turns, HP, switching, items, and battle outcomes.

## v0.2.27 — Lugia Aeroblast stays in the arena

v0.2.27 keeps Lugia's original Stadium 2 model and imported skeletal attack motion, but removes the camera-stage translation that made Aeroblast launch Lugia around the live overworld battle. During Lugia attacks only, the torso/root is pinned to its bind position while wings, neck, tail, rotations, and the 3D Aeroblast effect continue to animate. No other Pokemon uses this special case, and no Stadium 2 ROM re-import is required.

## v0.2.25 — visible Gold attacks + reliable Stadium battle bridge

v0.2.25 fixes the v0.2.23 blank-attack regression. Gold move keys are resolved to their numeric move definitions before Stadium 2 skeletal animation selection, and world-space effects no longer depend on Gold keeping the same `AnimRunner` object alive until the voxel render. Gold's native OBJ attack sprites are fail-open: they are hidden only after the matching 3D effect has actually produced world-space draw calls. If the 3D effect is unavailable or late, the original Gold effect remains visible.

No Stadium 2 ROM re-import is required. The working original Lugia fix from v0.2.22 and trainer-battle live 3D staging from v0.2.23 remain intact.

## v0.2.16 — Lugia DSM5 joint-transform fix

## v0.2.21 Lugia diagnostic build

This build does **not** attempt another global Lugia decoder change. The stable v0.2.20 rendering path stays intact. To collect the data needed for the real Stadium 2 Lugia, re-select/re-import your Stadium 2 ROM once. After Dex 249 is built, look in `cache/stadium/lugia_debug/` inside the Gen1Recomp save directory and upload **both** `249_geo_dump.txt` and `249.dsm`. `UPLOAD_THESE_TWO_FILES.txt` in the same folder records the exact save-directory path.



### v0.2.20 Lugia rescue path

Lugia (National Dex 249) now intentionally bypasses the unstable ROM-derived Stadium 2 hierarchy. It is rendered by an isolated procedural 3D rescue rig instead, with world-space depth/shadows and simple battle motion. All other Pokémon continue to use the stable Stadium importer. No ROM re-import is required for 0.2.20.

Lugia is no longer repaired by guessing a compact hierarchy. The actual Stadium geo-layout joint flags are now preserved in the local model pack and replayed at runtime. Those flags choose between Stadium's separate-scale matrix path and its normal full-TRS path; DSM4 discarded them, which is why Lugia's rigid body pieces could never assemble correctly even when the pose looked compact.

**Cache format history:** v0.2.16 moved DSM4 → DSM5 for joint flags; v0.2.78 moves DSM5 → DSM6 for N64 material state; v0.2.79 moves DSM6 → DSM7 so render-tile SL/TL/SH/TH and zero-mask clamp semantics are also baked correctly. Re-import/select your Pokémon Stadium 2 ROM once after v0.2.79 so all 251 local packs are rebuilt. The mod still does not ship Stadium model data.

The v0.2.15 harder Poké Ball aim/timing/miss-flight changes and all prior camera/open-world/battle work remain.

## v0.2.15 — Lugia 3D recovery + harder Poké Ball throws

- Lugia (Dex 249) is no longer hard-forced to the 2D safety card.
- StadiumRig now probes three bind-hierarchy interpretations for Lugia: the normal Stadium chain, parent-rotation with absolute translations, and a flat model-space recovery mode. It chooses the least-invasive valid repair that removes the exploded-body span.
- Repaired Lugia stance height/floor/radius are recomputed from the selected 3D bind so the old exploded bounds cannot make the fixed model tiny or enormous.
- Lugia texture uploads force solid alpha to avoid the ghost/translucent body caused by the Stadium-2 material-alpha mismatch. The existing 2D Lugia card remains only if every 3D repair path fails.
- Poké Ball aiming is more demanding: the base hit radius is reduced, strong/high-level Pokémon shrink it further, and strong targets cycle the precision ring faster.
- NICE/GREAT/EXCELLENT thresholds are stricter. A missed throw now actually flies to the off-target world-space point instead of visually homing into the Pokémon before reporting MISS.
- L2/right-click still only aims; R2/left-click still performs the throw. Aiming alone never spends a Ball.

## v0.2.14 — 3RD/1ST trainer animation no longer needs a map transition

The 3D Character Selector trainer now starts/stops its walking animation from the exact live voxel render state on the very first map. You no longer need to cross into another map section before third-person/first-person movement animates the trainer. The movement signal remains render-only and does not alter Gold collision, scripts, warps, or native step state.

## v0.2.13 — Lugia visibility + animated 3RD/1ST trainer

Lugia/Dex 249 still refuses the corrupt ROM-derived Stadium 2 hierarchy that produced detached body pieces. The safety path is now species-specific: the voxel world draws the packaged Lugia follower art as a correctly sized, **opaque alpha-cutout world card** instead of reusing a generic roaming-NPC sprite or model scale. The renderer also resets normal blend/depth state before that card, so Lugia cannot inherit translucent attack-effect state.

The 3D Character Selector trainer now receives a render-only walking signal during true camera-relative 3RD/1ST movement. Gold's gameplay `Player.moving` state remains untouched outside the actual skin draw/shadow call, but the external character renderer sees the same walking cadence it already receives in Diorama.

## v0.2.11 — pre-contact R3/right-click Poké Ball throw + safe Lugia fallback

Overworld capture no longer waits for you to touch the roaming Pokémon. While free-roaming, **aim the camera at a visible wild Pokémon and press R3 (right-stick click) on controller or right-click on PC**. The target is chosen from the camera-facing cone and the same press starts the throw, so you can stand back and throw before contact. Normal physical contact now goes straight to Gold's ordinary wild battle. After a miss/breakout, press R3/right-click again to retry; **B** abandons capture and starts the normal battle.

The trigger is polled on Gold's fixed-step `input.step` seam rather than `world.stepped`, so it works while the player is standing still. Right-click is no longer translated to Game Boy B by the 1ST/3RD-person mouse adapter.

The Poké Ball runtime prop now uses a deterministic UV sphere with a dedicated red/white/black/button texture and corrected vertical UV orientation. This avoids the scrambled atlas/material result from feeding the supplied COLLADA UV layout through the voxel renderer's single-texture path. The supplied model files remain bundled as reference/source assets.

**Lugia (Dex 249) now fails closed to Gold's normal texture-correct sprite billboard.** The Stadium 2 import shown in the broken screenshots has displaced wing/body parts even in the decoded bind data, so merely freezing the animation preserved corrupted geometry. Until that Stadium 2 hierarchy/material decode is verified against the user's local ROM, the mod will not show the exploded blue 3D Lugia. Other species keep the normal 3D model path and runtime corruption checks.

## v0.2.08 — clean 3D send-out + Gold-powered Stadium-style attack FX

Live voxel battles no longer flash Gold's native **2D player-Pokémon battle sprite** during the first send-out when that species already has a loaded Stadium 3D model. The existing fallback remains intact: if a species has no usable 3D model, Gold's normal battle pic is still allowed to render.

The existing world-space Stadium-style attack-effects renderer is now connected to **Gold's real Gen-2 `BattleState` / `AnimRunner`**. The renderer receives the live move ID, attacker side, and animation frame, so elemental/projectile/impact effects are drawn between the two actual 3D battlers in world space and follow the battle camera. This includes beams, fire, water, electric bolts, ice, psychic/shadow energy, wind, grass, poison, rock/ground impacts and dedicated treatments for many signature moves, with extra Gen-2 aliases such as Icy Wind, Flame Wheel, Whirlpool, Mud-Slap, Rollout, Bone Rush, Fury Cutter and Cotton Spore. Zero-power moves only use a generic attack effect when they have an explicit status-specific treatment.

No proprietary Stadium effect textures are bundled; these are procedural world-space effects designed to reproduce the Stadium-style presentation while using the live Gold move data.

## v0.2.07 — no duplicate trainer sprite before live battles

When a live overworld Stadium battle begins, the **3D trainer already present in the voxel world is now the only trainer shown**. Gold's original 2D battle back-sprite is suppressed for the live voxel battle compositor, eliminating the oversized duplicate trainer artwork during the opening/send-out sequence.

This does not remove or alter the player's 3D model, battle state, send-out timing, normal Gold fallback battles, or the v0.2.06 overworld Poké Ball capture minigame.

## v0.2.06 — overworld Poké Ball capture

Visible roaming wild Pokémon can now be caught directly in the 3D overworld. Touch a battleable wild while carrying a regular **POKé BALL** to enter the capture minigame. Aim with the **mouse or controller right stick**, then throw with **A / left click / controller A / right trigger**. Press **B / right click** to skip the minigame and start the normal Gold wild battle.

The supplied `RegularPokeBall.dae` and `pokeball_DIF.png` are used for the actual world-space throw. The target ring shrinks while you aim: more accurate, better-timed throws receive NICE/GREAT/EXCELLENT quality, while a miss spends the ball without deleting the wild Pokémon. Hits use Gold's species catch-rate logic, play a 3D ball shake sequence, and successful captures go into the normal Gold party/current-box save structures.

If the selected camera is DIORAMA, capture temporarily uses the 3RD-person aiming rig and returns to DIORAMA afterward without changing your saved camera setting. 1ST/3RD capture keeps the existing selected mode.

## v0.2.05 — F6 camera switching + controller right-stick look

Desktop **F6** now reliably cycles **DIORAMA -> THIRD PERSON -> FIRST PERSON -> DIORAMA**. The mod keeps its normal Game2 key hook but also checks the physical F6 key state once per rendered voxel frame, so the camera switch still works if another wrapper consumes the key event. The two paths share one press latch and cannot double-advance.

In **THIRD PERSON** and **FIRST PERSON**, a mapped controller's **right stick** now rotates the same camera yaw/pitch used by mouse-look. The stick is sampled every frame through LÖVE's mapped `rightx/righty` axes with the existing deadzone/response curve. **Mouse-look remains enabled at the same time**; whichever device you move simply adds camera input to the same rig.

## v0.2.04 — connected maps / open-world-style route streaming

This build changes the Gold voxel renderer from **current-map-only** to a connected-world presentation. Every directly connected north/south/east/west destination is adapted into a real Gen-2 `Map` and streamed as 3D terrain while you are still standing in the current area. Walking down a route connection should therefore show the actual next route/town ahead instead of forest/void followed by a map replacement.

Neighbour maps preload in the background and are prioritized when you approach their edge. When you cross, the already-built neighbour mesh becomes the current terrain immediately and the map behind you remains visible as the new neighbour. The expanded round-tree apron is still used on genuinely unconnected edges, but is masked away underneath real connected map bodies. Adjacent Gold NPC ghosts and third-person camera collision also use the same map offsets for a more continuous handoff.

## v0.2.03 — fuller forest edge + battle camera crash fix

Outdoor maps now build **eight full border blocks / 32 tiles of round Johto trees on every side**, double the previous physical forest apron. This is real voxel geometry and keeps the free cameras from reaching the old black/empty edge nearly as soon.

The **STADIUM BATTLE CAMERA** is now guarded as an optional presentation layer. Its active-turn queue observer works on LuaJIT/LÖVE builds that only provide global `unpack`, and unexpected battle-state/animation data now falls back to the normal live-world camera instead of crashing the game.

## v0.2.02 — closer Diorama and turn-focused battle shots

**DIORAMA** can now zoom much closer. Its nearest camera-distance limit is reduced from 0.55× to **0.24×**, so Android pinch and desktop wheel/trackpad can push into a much tighter view.

The **STADIUM BATTLE CAMERA** now follows the Pokemon whose turn is actually being presented. During a move it favors the attacker heavily while keeping the opponent as the secondary subject; through the rest of that resolving turn it stays biased toward the acting side, then widens toward both Pokemon when menu control returns. Manual right-thumb/mouse camera control still temporarily overrides the automatic shot.

During live-overworld battles the player trainer is now rendered **beside and slightly behind their Pokemon**, instead of remaining on the original encounter tile where they could stand between the camera and the fight. This is visual-only and does not move Gold's real player position.

## v0.2.01 — smooth Diorama zoom + Pokemon Stadium battle camera

**DIORAMA** now has a real continuous camera-distance zoom. On Android, pinch two free fingers to move the camera smoothly in/out. On desktop, the mouse wheel or trackpad changes the same distance instead of stepping Gold's coarse survey ladder.

**STADIUM BATTLE CAMERA** defaults ON for LIVE OVERWORLD BATTLES. The camera circles the two battling Stadium models in the actual encounter world, gently moves closer during attack animations, and keeps both Pokemon framed. Drag with the Android right thumb or move the mouse during battle to take over manually; after about 2.5 seconds without camera input, the automatic orbit eases back in. The setting can be turned OFF if a fully manual/static live-world battle view is preferred.

## v0.2.00 — Android right-thumb camera and denser forest edge

Android 1ST/3RD camera look now reads the physical LOVE touch table directly instead of depending only on wrapped Game2 callbacks. Keep your left thumb on the movement pad and drag one free right-side finger to turn the camera. The same control remains active in LIVE OVERWORLD BATTLES.

The outdoor perimeter now contains an actual additional meshed border block of trees: four blocks / 16 tiles around the map instead of three blocks / 12 tiles, all using the working round Johto tree geometry.

## v0.1.99 — Android two-thumb free camera + denser perimeter trees

On Android, use the **left touch D-pad** to move and drag the **right side of the screen** with your right thumb to look around in 3RD or 1ST person. The same right-thumb camera control remains active during **LIVE OVERWORLD BATTLES**, so the encounter camera can be rotated without leaving the overworld battle presentation.

The outdoor synthetic border also now carries a deeper belt of the existing round Johto tree geometry. This fills more of the outer perimeter in wide/tall mobile views without bringing back the old rectangular tree-wall bug.

## v0.1.98 — free camera + true directional movement

In **3RD** and **1ST** camera modes, movement is now fully camera-relative and continuous: move at any angle, use diagonals, preserve analog stick/touch-dpad strength, and slide naturally along walls. **DIORAMA** keeps Gold's original four-direction grid movement.

The mod still hands special movement back to Gold: bike/surf, ice and currents, doors, ledges, boulders, map connections, scripts, warps, encounters and trainer checks stay on the native Gen-2 gameplay path. This implementation does not fake `Player.moving` or take ownership of Character Selector animation state; external character models can animate from the player's actual world displacement.

## v0.1.98 — camera slider return + correct 1ST/3RD walking

The Android camera slider can now move freely in both directions: **DIORAMA <-> 3RD <-> 1ST**. In AUTO camera control, a mode selected directly with the slider (or F6 on desktop) stays selected instead of being immediately replaced by the Character Selector's previous camera rung. Set **CAMERA CONTROL = CHARACTER SELECTOR** if you intentionally want that mod to own camera mode again.

Walking in **1ST** and **3RD** is camera-relative again even when the Character Selector model is active: forward follows the camera, back reverses, and left/right strafe. Gold still receives only its normal four grid directions, so collision, doors, ledges, warps, encounters, and scripts remain native. No continuous 360 movement or fake animation state was reintroduced.

## v0.1.96 — Android slider touch fix

The on-screen **DIORAMA / 3RD / 1ST** camera slider now reads the live Android touch contacts directly every voxel frame. This fixes the v0.1.95 case where the slider drew correctly but the Android callback chain did not deliver the drag/tap to the mod. Touches outside the slider still belong to the normal game controls, camera look, and pinch zoom.

## v0.1.94 — pinch zoom actually works on Gold

v0.1.93 had the pinch recognizer but attached it to the wrong game object. Gold/Silver uses `Game2`, not the Gen-1 `Game` singleton, so two-finger events never reached it. v0.1.94 installs the controller on the live Gold host.

**Third Person:** pinch in/out changes camera boom distance smoothly. **Diorama:** pinch changes Gold's survey zoom. **First Person:** pinch remains disabled because the camera is fixed at eye position.

## v0.1.93 — pinch-to-zoom

On phones/tablets, use **two fingers on open world space** to zoom the voxel camera. In **THIRD PERSON**, spreading the fingers pulls the camera closer and pinching pulls it farther away. In **DIORAMA / orbit** mode, the same gesture changes the voxel/survey zoom level.

The gesture does not steal touches that begin on the on-screen D-pad or buttons, and while a pinch is active it suppresses look-drag rotation so the camera does not spin while you zoom. **FIRST PERSON** keeps its fixed eye-position camera rather than applying a distance zoom. Character Selector camera ownership remains supported.

## v0.1.92 — seamless battle entry

When **LIVE OVERWORLD BATTLES** is **ON**, ordinary wild encounters no longer play Gold's black-circle battle transition. The encounter now stays in the same live voxel overworld view and pushes straight into the native Gold battle UI, so the start of battle is fully seamless instead of pretending it is changing to a separate battle scene.

If you turn **LIVE OVERWORLD BATTLES** **OFF**, Gold's classic battle transition and normal battle scene still return exactly as before.

## v0.1.91 — Character Selector camera compatibility

**CAMERA CONTROL** now defaults to **AUTO**. When `red_3d_player` / 3D Character Selector is installed, this mod follows the engine's public voxel camera state instead of forcing its own camera selection every frame. Character Selector ZOOM/orbit maps to DIORAMA, its 1ST mode maps to FIRST PERSON, and its 3RD mode maps to THIRD PERSON.

While Character Selector owns the camera, this mod also passes look input through instead of swallowing it and disables its own Gold camera-relative cardinal remapper, leaving the selector's Gen-2 movement/animation logic authoritative. Choose **THIS MOD** under CAMERA CONTROL if you want the Stadium mod's own camera option/F6 behavior instead.

## v0.1.90 — optional live overworld battle mode

The live in-world battle presentation is now a normal user-facing setting: **LIVE OVERWORLD BATTLES** defaults **ON**. Turn it **OFF** to use Gold's classic battle scene while keeping the voxel overworld, followers, weather, cameras, Stadium models, and the rest of the mod enabled.

## v0.1.89 — live overworld battles + lean Gen-2 install

- **Wild battles stay in the overworld.** The battle backdrop is now the same frozen voxel frame and camera the player was already using when the encounter began; Gold no longer changes to the mod's separate staged arena camera.
- **Attack flash fix.** While the live-world battle is active, Gold's opaque `BattleAnimView` scanline/background pass is bypassed. Gold's battle HUD, text and OBJ effect sprites remain, but the old white/black 160×144 battle paper can no longer replace the world during Tackle and similar animations.
- **Much smaller install payload.** This Gold/Silver package now contains runtime sprite sheets only for National Dex **1–251**. Duplicate raw PokeMMO/follow/water source PNG libraries and dead Gen-1 Yellow/free-movement compatibility modules were removed.
- The built-in party-slot-1 follower remains enabled by default, and the v0.1.88 Gold GBC voxel-color fix remains intact.

## v0.1.87 — lead-party follower and repaired live 3D wild battles

**LEAD PARTY FOLLOWER** now defaults ON. The first Pokemon in the party follows one tile behind the player using Gold's native Gen-2 follower path, while the voxel renderer replaces that follower with the party lead's Stadium 2 model. Reordering the party changes the follower automatically.

**IN-WORLD 3D BATTLES** is also repaired for current Gold. Ordinary wild encounters are staged at the exact encounter-site voxel terrain with Stadium 2 models while Gold's real battle HUD, text, menus, catching, switching and battle logic remain on top. The previous implementation patched the Gen-1 battle screen and also stored Gold's logic object in place of the live Gen2 BattleState, so it never reached the presentation path current Gold actually draws.

The accidental true-360/free-walk work from v0.1.84/v0.1.85 has been removed from this project. First/Third Person are back to camera-relative **Gold-native cardinal movement**, and this mod no longer fakes `Player.moving` for the 3D Character Selector.

## v0.1.83 — voxel startup regression fixed

v0.1.82 accidentally referenced a second weather module (`WeatherFX`) in addition to the packaged `Weather.lua`; that bad require could abort the Gold voxel renderer and force the normal 2D fallback. v0.1.83 removes the duplicate module path and makes all weather hooks fail-safe. **3D VOXEL WORLD remains authoritative even if weather fails.** Rain, fog, moving clouds, sun/moon, camera modes, camera-relative controls, Johto tree geometry, all-Pokemon 3D, Skin Selector compatibility, and visible pause menus are retained.

## v0.1.83 — weather, clouds, and fuller sky background

This build keeps the non-experimental packaging and adds outdoor atmospheric rendering to the Gold voxel world. New **WEATHER FX** options let you use **AUTO**, **CLEAR**, **RAIN**, **FOG**, or **RAIN + FOG**, and **SKY CLOUDS** adds drifting cloud layers behind the scene. The existing day/night sky renderer continues to supply the **sun by day** and **moon by night**. Indoors remain unchanged.

## v0.1.83 — normal release

This build is no longer flagged experimental in `manifest.json`, so it installs as a normal Gen1Recomp mod while retaining all v0.1.80 behavior.

## v0.1.83 — camera-relative Gold controls

THIRD PERSON and FIRST PERSON now steer relative to the 3D camera rather than Gold's original screen/map axes. UP/W is forward in the current view, DOWN/S is backward, and LEFT/RIGHT strafe. Gold still receives one of its native four cardinal movement directions, so doors, collisions, ledges, encounters, scripted movement, and map connections continue to use the normal Gen-2 gameplay path. In FIRST PERSON, pressing A also uses the nearest cardinal to the view direction for talking/reading/interacting. DIORAMA keeps the original controls.

# Pokemon Stadium 2 Overworld Models - Gold/Silver (Gen 2) v0.1.87

## v0.1.79 first-person + third-person Gold cameras

v0.1.79 activates the embedded free-roam camera rigs for the standalone Gold/Game2 voxel renderer. **3D CAMERA MODE** now offers **DIORAMA**, **THIRD PERSON**, and **FIRST PERSON**. The default remains DIORAMA, so upgrading keeps the proven v0.1.78 view until a different camera is selected.

- **Third Person** places the camera behind/above the player and uses the existing collision-aware boom so walls, trees, and buildings pull the camera inward rather than letting it sit inside geometry. The selected Skin Selector character remains visible.
- **First Person** places the eye at the player and hides the player's own model from the lens.
- Mouse motion, right stick, and open-screen touch drag steer the free camera. **F6** cycles `DIORAMA -> THIRD PERSON -> FIRST PERSON -> DIORAMA` while freely roaming.
- Opening START, a textbox, or another Gold overlay releases relative mouse capture and leaves the working v0.1.74 menu-over-3D compositor in charge.
- Gold's normal grid movement/gameplay rules are intentionally unchanged; this release adds camera modes, not a replacement movement system.

All v0.1.78 tree-profile fixes, v0.1.77 all-Pokemon 3D fallback behavior, and v0.1.75 Skin Selector compatibility are retained.


## v0.1.78 Gold tileset-ID bridge / actual tree-profile fix

Current Gold uses runtime tileset keys such as `TILESET_JOHTO`, while the embedded Dramatic Shapes profile uses `TilesetJohto`. Previous tree fixes were correct inside the profile/mesher but current Gold could miss that profile entirely and therefore keep drawing the same generic textured blocks. v0.1.78 fixes the bridge: before voxel terrain is analyzed, `TILESET_*` runtime names are normalized to the profile's `Tileset*` spelling.

This means the already-authored Johto tree rules (`cylinder`, two-cell `planter`, and the stepped tree archetype) now actually own those cells. The engine-facing `map.def.tileset` value is not changed. v0.1.77's all-Pokemon 3D model fix, v0.1.75 Skin Selector compatibility, and v0.1.74 pause/menu compositing remain intact.


## v0.1.76 Gold tree voxel-shape fix

Gold outdoor tree borders no longer fall through to the generic solid-volume path that produced tall rectangular blocks covered in repeated tree texture. The renderer now recognizes Gold outdoor maps from their Gen-2 environment, confirms that the repeated border block actually contains tree-profile graphics, and keeps that scenery on the existing round voxel-tree hull path.

There is also a conservative in-map fallback for changed/extracted Gold blocksets: if an otherwise-unresolved solid 16x16 cell is made mostly from tiles the active profile explicitly identifies as `cylinder`, `planter`, or `canopy`, it is promoted to a round tree hull instead of a box. Explicit/authored geometry always wins, so this does not globally round walls, houses, cliffs, fences, or signs.

This release keeps the v0.1.75 3D Character Selector bridge and the v0.1.74 visible pause/menu-over-voxel fix unchanged.

## v0.1.71 visible-only encounter fix

Normal Gold grass/cave step encounters are now **OFF by default** while Show Wild Mons is enabled. This fixes the remaining battles that could start without a Pokemon visible on the map. Upgrading from v0.1.70 automatically flips the old saved Random Enc default OFF once and also clears Hidden Mons.

The fix also guards Gold's roaming-beast path, which runs before the public `encounter.roll` hook in current Gold. With **Classic Step Enc = OFF**, ordinary automatic step battles are blocked before that path and battles come from touching/chased-by visible roaming Pokemon. Sweet Scent, fishing, Headbutt, Rock Smash, scripted encounters, and the Bug Catching Contest remain separate. `Water Mons = Classic Enc` is still an explicit opt-in to classic water encounters.


Standalone Gold/Generation-2 build for current Gen1Recomp. It combines a Gold voxel-world renderer, visible roaming wild Pokemon, and a user-supplied Pokemon Stadium 2 ROM importer for National Dex 1-251.

## v0.1.70 compose + visible-Wilds fix

The Stadium 2 importer was already reaching all 251 Pokemon, but v0.1.69 could still leave the Gold overworld completely unchanged. Two Gold-specific runtime assumptions were wrong:

1. Current Gold stores its generated encounter database in `game.data.gen2Encounters` / `world.encounters`, grouped as `grass[mapId]` and `water[mapId]`, with `MORN`, `DAY`, and `NITE` grass slots. The embedded Wilds adapter now reads that structure directly.
2. Gold's native people draw pass Y-sorts the player, `world.npcs`, and ghosts. Wilds roaming Pokemon are independent entities, so merely appending them to `world.entities` does not make them visible. v0.1.70 renders them through the current Gold `render.compose` frame hook instead.

The 2D visible-Wilds pass is deliberately independent of voxel rendering. If voxel rendering is unavailable, still building chunks, or errors on a map, v0.1.70 draws the already-finished Gold scene and overlays the roaming Pokemon sprites on it. A failed voxel frame should therefore no longer make Wilds look disabled.

The compose pass also self-heals Wilds map initialization once per second when needed. This covers event-order differences where Gold entered a map before the embedded Wilds listener was fully ready.

## v0.1.75 3D Character Selector compatibility

This build is compatible with **red_3d_player v3.1.10** in Gold's standalone voxel mode. The selector already patches Gold's normal `src.world.gen2.Player:draw()`, but the standalone voxel scene bypasses that 2D draw method entirely. v0.1.75 now detects the selector's live `Player.red3dPlayerRenderer` and calls its own `drawVoxel()` / `drawVoxelShadow()` methods for the human player pose.

The bridge resolves the selector renderer every frame, so changing characters in **Skin Selector** updates the Gold voxel-world player immediately without hardcoding the selector's character list. Built-in skins, imported skins, per-character scale, and selector-owned accessories remain owned by `red_3d_player`. Pokémon-control player modes still use Stadium models, while Gold fishing, surfing, and bicycle states continue to use their special native cards.

Install both mods normally. `red_3d_player` is an optional dependency, so this Stadium build still works by itself; when the selector is absent or its 3D renderer is unavailable, the player cleanly falls back to the normal voxel sprite card.

## Stadium 2 ROM importer

Use **Mods -> Pokemon Stadium 2 Overworld Models -> Options -> STADIUM 2 ROM FILE (GEN 2)** and choose your legally obtained Stadium 2 ROM (`.z64`, `.n64`, or `.v64`).

The ROM is not included in this mod. Extracted Nintendo model data is not shipped in this ZIP. Model packs are built locally from the ROM selected by the user.

The Stadium 2 path supports National Dex 1-251 and reads Stadium 2's separate model and skeletal-animation archives. Animation-context routing is still provisional; model import is the current priority.

## Visible roaming Pokemon

**Show Wild Mons** defaults ON. On a supported Gold encounter map, the embedded Wilds runtime:

- reads the active Gold encounter table for the current time of day,
- finds valid grass/cave/water cells from Gold's Gen-2 map predicates,
- creates visible roaming Pokemon,
- draws them as 2D fallback sprites even if voxel is not working,
- feeds the same entities into the voxel/Stadium scene so imported Stadium 2 models can replace them in 3D.

Hidden wild behavior defaults OFF in this Gen-2 build.

## Voxel world

**3D VOXEL WORLD** defaults ON. v0.1.70 no longer patches `World:drawWorldBody()` and does not depend on the old Gen-1 `drawWorld` pipeline. The embedded voxel renderer is invoked from Gold's current whole-window `render.compose` hook.

The current-map voxel scene is the first target. Connected-neighbor voxel stitching remains conservative while the Gold renderer is being proven in real gameplay.

## Install / test order

1. Remove or disable older `STADIUM2_OVERWORLD_MODELS` builds.
2. Install this ZIP and confirm the card says **v0.1.82 / GEN 2**.
3. Leave **3D VOXEL WORLD = ON** and **Show Wild Mons = ON**.
4. Start Gold and walk onto an outdoor route with grass.
5. First verify that roaming Pokemon sprites appear even if the world is still flat.
6. Then select/import the Stadium 2 ROM and test the voxel/Stadium model path.

If both voxel and roaming sprites are still absent, capture the mod error/status shown by Gen1Recomp. v0.1.70 exposes compose, voxel, and Wilds bridge status through `mod.exports` so the next failure can be isolated instead of guessed.

## Included third-party components

This standalone package incorporates compatible runtime pieces from the user-supplied Wilds of Kanto 1.12.2 and DRAMALESS_SHAPE 1.6.4 packages. Their license/permission files are retained as `WILDS_LICENSE.txt` and `DRAMALESS_LICENSE.txt`.

No Pokemon ROM is included.
## v0.1.74 pause/menu visibility fix

Opening the START/pause menu now keeps the Gold overworld in voxel mode **and** keeps the menu visible and interactive. Gold's current `render.compose` payload contains one already-composited scene (its world/UI canvas references point to the same texture), so v0.1.74 does not use the Gen-1 `worldOverride` strategy. Instead it paints the voxel frame, then redraws only Gold's active state stack at the same `world:fitScale()` / centered 160x144 transform used by `Game2:drawScene()`. Opaque/full-screen pages remain owned by Gold because `worldActive` is false for those frames.

## v0.1.72 voxel-focus fix

This release intentionally leaves the v0.1.71 Wilds/encounter behavior unchanged and focuses on the Gold voxel world. Two remaining Gen-1 map assumptions in the embedded mesh analyzer were causing Gold terrain builds to fail inside the asynchronous mesher. The current Gold map is now synchronously primed once, and a failed mesh is reported instead of silently falling back to flat 2D forever.



## v0.1.82 Weather
Use **3D WEATHER** to select Auto, Clear, Rain, Fog, or Rain + Fog. **MOVING CLOUDS** controls the background cloud layer. The day/night sky continues to show the sun and moon. Weather only appears outdoors.


### v0.2.67 desktop voxel recovery
A fresh Gold options block defaults native `TILT` to OFF/0. While `3D VOXEL WORLD` is enabled, that OFF value now selects the voxel renderer's normal 35-degree diorama camera rather than a literal 0-degree/flat camera. Gold TILT 15/35/50 continue to map directly to those voxel pitches; disable `3D VOXEL WORLD` for the native 2D overworld.
