# v0.1.90 — battle-mode toggle + updater-ready repo

- Promoted the live encounter-world battle presentation to the main Mod Settings as **LIVE OVERWORLD BATTLES**.
- The setting defaults **ON**. Turning it **OFF** returns ordinary wild battles to Gold's classic battle presentation without uninstalling the mod.
- Keeps the lean Gen-2-only package layout from v0.1.89.
- Keeps the updater repository target `randyadr/Gen2-3D-Sprites`.

# v0.1.89 — live overworld battle camera + lean Gen-2 package

- Gold ordinary wild battles now render the normal frozen `VoxelScene` at the exact encounter camera instead of `BattleScene`'s separate staged camera.
- Stadium combatants are drawn and shadowed inside that normal voxel world pass.
- Live-world battles bypass the native opaque `BattleAnimView.present` / intro background transform, preventing black/white 160×144 rectangles during attacks. Native Gold battle HUD/text and animation OBJ sprites remain layered above the voxel world.
- Removed legacy Yellow/Followers-EX/Dramatic-Sky-Ride startup glue from `main.lua` and removed dead Gen-1/free-movement modules unreachable from the Gold loader.
- Removed duplicate raw follow-sprite and Pokédex-mapping source libraries.
- Removed raw water-sprite source PNGs; the compact species/form mappings and prebuilt runtime sheets remain.
- Pruned generated follower/water/silhouette sheets to National Dex 1–251 and rewrote their manifests accordingly.

# v0.1.87 — lead-party follower + real Gold in-world 3D battle fix

- Added **LEAD PARTY FOLLOWER**, enabled by default. Party slot #1 uses current Gold's native `src.world.gen2.Follower` trail and the Stadium 2 model renderer. Reordering the party updates the follower species automatically; biking/surfing hide it.
- Reverted the accidental v0.1.84 true-360/free-walk controller from this project. First/Third Person again use the proven camera-relative cardinal adapter from v0.1.80/0.1.83, preserving Gold's native grid movement.
- Removed the temporary `_stadiumFreeMoving` / `Player.moving` animation shim so `red_3d_player` and other character mods receive the real Gold movement state and own their animation decisions.
- Fixed in-world 3D wild battles to hook the actual current Gold class, `src.ui.gen2.BattleState`, instead of the Gen-1 `src.battle.BattleState`.
- Fixed a Lua nil/or bug in battle startup: `isGoldGame() and nil or battle` could never produce nil, so v0.1.85/0.1.86 stored the Gen-2 battle logic object where the renderer expected the live BattleState screen.
- The Gold battle UI now clears its full-screen white paper to transparency only while a valid 3D shot exists, and flat Pokemon pics are suppressed per side only when the Stadium 2 model is actually visible. Gold's HUDs, menus, text, move effects and battle logic stay native.
- In-world staging is deliberately scoped to ordinary wild encounters; tutorial, contest, Safari and trainer battles retain native presentation.
- Retains the v0.1.86 updater repository `randyadr/Gen2-3D-Sprites` and non-experimental packaging.

# v0.1.83 — restore voxel 3D + weather fail-safe

- Fixed v0.1.82 disabling voxel 3D because `VoxelScene.lua` tried to load an accidental duplicate `WeatherFX` module that was not part of the packaged renderer.
- Removed that duplicate path; `lib/Weather.lua` is the single weather implementation.
- Guarded weather context, sky, overlay, and invalidate calls with `pcall`, so a weather error can no longer abort the voxel renderer.
- Keeps rain, fog, moving clouds, day/night sun and moon, and all v0.1.81 camera/Pokemon/tree/menu/Skin Selector behavior.

# v0.1.82 — outdoor weather + cloud sky

- Added outdoor atmospheric rendering for the Gold voxel world.
- Added **WEATHER FX** option with `AUTO`, `CLEAR`, `RAIN`, `FOG`, `RAIN + FOG`, and `OFF`.
- Added **SKY CLOUDS** toggle for drifting cloud layers in the voxel sky.
- Rain and fog are cosmetic screen-space effects applied only to outdoor/canopy maps.
- The existing day/night sky remains in charge of the sun by day and moon by night.
- Keeps the v0.1.81 normal non-experimental packaging and all camera / renderer behavior from prior releases.

# v0.1.82

- Added Auto/Clear/Rain/Fog/Rain + Fog outdoor weather.
- Added moving pixel clouds behind the voxel world.
- Added rain streaks and drifting fog on the completed 3D scene.
- Existing day/night sun and moon remain active.
- Weather stays disabled indoors.
- Retains v0.1.81 non-experimental status and all prior fixes.

# v0.1.81 — normal non-experimental release

- Marks the mod as a normal release (`experimental: false`) so Gen1Recomp no longer requires the experimental-mod enable step after each install.
- No gameplay, camera, voxel, Pokémon, tree, pause-menu, or Skin Selector behavior was changed from v0.1.80.

# v0.1.81 — Gold camera-relative first/third-person controls

- Fixed Gold movement in THIRD PERSON and FIRST PERSON so movement rotates with the camera yaw instead of staying locked to the original 2D map axes.
- UP/W now means camera-forward, DOWN/S camera-back, and LEFT/RIGHT strafe relative to the current view.
- The rotated intent is quantised back to Gold's four legal directions before `World:movePlayer`, preserving native collision, warps, ledges, bike/downhill behavior, encounters, and scripts.
- Added a small direction hysteresis around 45-degree camera angles to stop held movement from flickering between adjacent grid directions.
- In FIRST PERSON, A-button interactions now face the nearest cardinal to the camera look direction before Gold resolves the target.
- DIORAMA and all menu/battle/script input remain vanilla.
- Retains the v0.1.79 camera modes, v0.1.78 Johto tree-profile fix, v0.1.77 all-Pokemon 3D fallback, visible pause menus, and Skin Selector compatibility.

# Changelog

## 0.1.79 - Gold first-person / third-person camera modes

- Added **3D CAMERA MODE** with `DIORAMA`, `THIRD PERSON`, and `FIRST PERSON`; DIORAMA remains the default.
- Activated the embedded FirstPerson/ThirdPerson placed-camera rig inside the standalone Gold voxel provider instead of hardcoding voxel level 1 every compose frame.
- Adapted the camera host lookup to Gold's live Game2 `world` + empty-stack free-roam model while retaining the original Gen-1 fallback.
- Added mouse, right-stick, and touch-look input hooks on the actual live Gold Game2 instance.
- Added **F6** live camera cycling: Diorama -> Third Person -> First Person -> Diorama.
- Third person keeps the existing collision-aware boom and player visibility; first person hides the local player model through VoxelScene's existing camera gate.
- Relative mouse capture now releases whenever a Gold START/text/dialog overlay opens, preserving the v0.1.74 visible pause-menu behavior.
- Kept Gold's normal movement/gameplay rules unchanged; v0.1.79 is a camera-only control addition.
- Retains v0.1.78 Johto tree-profile activation, v0.1.77 all-Pokemon 3D fallback, and v0.1.75 Skin Selector support.

## 0.1.78 - Gold tileset-profile ID bridge / tree-block root fix

- Fixed the root reason the v0.1.76/v0.1.77 Johto tree-shape changes could be bypassed on current Gold builds.
- Current Gold map definitions key outdoor tilesets as engine constants such as `TILESET_JOHTO` and `TILESET_JOHTO_MODERN`; the embedded voxel profile is keyed as `TilesetJohto` / `TilesetJohtoModern`. The Gold voxel bridge now normalizes the runtime constant to the profile spelling before terrain analysis.
- The normalization is generic for `TILESET_*` names (`TILESET_ELITE_FOUR_ROOM` -> `TilesetEliteFourRoom`, etc.), so all existing authored Gen-2 voxel profile rows can resolve instead of silently falling back to generic wall geometry.
- `map.def.tileset` is left untouched for the engine. Only the tileset record's voxel-facing `id` is normalized, and the original runtime id is retained as `_stadiumEngineTilesetId`.
- With the Johto profile now active, the existing `cylinder` / `planter` / stepped tree archetypes claim the tree cells before the generic volume mesher can turn them into rectangular texture blocks.
- Retains v0.1.77's all-Pokemon Stadium 2 3D fallback, v0.1.75 Skin Selector support, and v0.1.74 visible START/pause overlays.

## 0.1.76 - Gold tree voxel-hull fix

- Fixed Gold/Gen-2 outdoor tree borders rendering as giant rectangular blocks with tree textures wrapped across their faces.
- Gold outdoor detection now uses the Gen-2 map environment instead of relying on the old Gen-1 `OVERWORLD` tileset literal.
- The synthetic Gold border is treated as forest only when its actual `borderBlock` contains tiles the active voxel profile names as `cylinder`, `planter`, or `canopy`, so water/special borders are left alone.
- Tree-filled borders now stop at the round-hull carve belt instead of continuing into the far ring as generic upright boxes.
- Added an in-map safety pass: an unresolved 16x16 Gold outdoor cell is promoted from generic `upright` to the round tree hull only when at least half of its four source tiles are profile-authored tree art. Authored buildings, cliffs, signs, fences, proper planters/canopies, and other explicit geometry are never overwritten.
- Retains v0.1.75 Skin Selector compatibility and v0.1.74 visible START/pause overlays.

## 0.1.75 - Gold voxel Skin Selector compatibility

- Added optional compatibility with `red_3d_player` / 3D Character Selector v3.1.10.
- Gold's standalone voxel scene now checks `src.world.gen2.Player.red3dPlayerRenderer` for the selector's live ActiveRenderer instead of always drawing the stock trainer card.
- The current selector character is resolved every voxel draw, so changing skins in the pause-menu Skin Selector takes effect without restarting or hardcoding character IDs.
- Uses the selector's own `drawVoxel()` and `drawVoxelShadow()` paths, preserving its built-in/imported models, per-character scaling, accessories, animation state, and future selector-side skin changes.
- Player-as-Pokémon control remains Stadium-owned. Fishing, surfing, and bicycle states remain on Gold's special native-card fallback, matching the selector's existing Gen-2 rules.
- The compatibility path fails closed: if `red_3d_player` is absent or its renderer is unavailable, the existing voxel trainer card is unchanged.
- Added `red3dPlayerCompatStatus()` diagnostics to this mod's exports.
- Retains v0.1.74's visible START/pause overlay compositing fix.

## 0.1.74 - visible Gold pause/menu over voxel world

- Fixed the v0.1.73 regression where START opened and accepted input but its menu graphics were hidden behind the voxel frame.
- Corrected the Gen-2 compose assumption: current Gold/Game2 supplies one already-composited scene; `worldCanvas`, `uiCanvas`, and `sceneCanvas` are the same texture.
- On live Gold overworld frames, the bridge now draws the voxel canvas first and then redraws only `Game2.stack` above it.
- The overlay stack uses Gold's own `world:fitScale()` and centered 160x144 transform, matching `Game2:drawScene()` for START, text boxes, and other non-opaque map overlays.
- Corrected Game2 host detection so the bridge reads the live Gold `host.world` / `host.stack` instead of accidentally falling back to the Gen-1 Game singleton.
- Opaque/full-screen Gold pages remain vanilla-owned because Game2 marks those frames `worldActive=false`.
- Added overlay redraw diagnostics to `goldComposeStatus()`.

## 0.1.73 - keep voxel world active while paused

- Fixed START/pause menus causing the Gold overworld to fall back to the vanilla 2D renderer.
- Removed the overlay-stack passthrough from `GoldComposeBridge`.
- Current Gen1Recomp now receives the successful voxel canvas through `Renderer:setWorldOverride()` and performs its normal UI composite on top.
- Preserves menu/dialog UI, dynamic anchoring, fades, battle wipes, and engine post-processing instead of bypassing them with a whole-window direct draw.
- Added bridge diagnostics for voxel frames rendered while an overlay is open and for world-override usage.
- Retains a legacy free-roam direct-draw path for older experimental compose APIs.

## 0.1.72 - Gold voxel mesh compatibility

- Fixed the embedded terrain analyzer using the Gen-1 `map.doorTiles[...]` table on Gold; Gen 2 now uses `Map:isDoorTileCell()`.
- Fixed sealed-pocket analysis indexing Gold's `map.warpAt` method as though it were a Gen-1 table.
- Prime the current Gold map's full terrain mesh synchronously once per map so the compose renderer gets a real 3D mesh instead of depending entirely on an async pipeline cadence Gold does not own.
- Mesh-build failures are now retained and surfaced through voxel status/logging rather than looking like an endless `pending` state.
- FULL voxel mode (level 1) is now the explicit Gold target.
- No Wilds/encounter behavior changes in this release; this pass is voxel-only.

# v0.1.71 - no invisible ordinary encounters

- Changed Classic Step Enc / Random Enc default from ON to OFF.
- Added a one-shot v0.1.71 migration that turns old v0.1.70 saved Random Enc ON values OFF and clears Hidden Mons. The player can intentionally turn Classic Step Enc back ON afterward.
- Added a Gold `World:tryWildEncounter` guard so roaming-beast checks that occur before `encounter.roll` cannot create invisible ordinary step battles while visible-only mode is active.
- `encounter.roll` suppression now applies only to ordinary `kind=wild` step rolls; Sweet Scent, scripted rolls and Bug Catching Contest are preserved.
- Water Mons = Classic Enc remains an explicit opt-in exception for classic water encounters.

# v0.1.70 - Gold render.compose + visible Wilds fix

- Moved the live Gold integration to the current `render.compose` whole-window hook.
- Removed v0.1.69's dependency on patching `src.world.gen2.World:drawWorldBody()`.
- Fixed Gold encounter lookup to prefer `game.data.gen2Encounters` / `world.encounters` instead of the Gen-1 `game.data.encounters[mapId]` layout.
- Added `MORN` / `DAY` / `NITE` grass-slot selection and Gold water-table adaptation.
- Added an independent 2D roaming-Pokemon fallback pass: Gold's finished scene is preserved and Wilds sprites are drawn over it whenever voxel is unavailable/pending/failed.
- Added compose-time Wilds map-initialization self-heal with rate limiting.
- Added origin-safe fallback sprite drawing so inherited graphics transforms cannot move the Wilds layer off-screen.
- Kept visible roaming Pokemon outside Gold's persistent script-NPC list while feeding the same entities into the voxel/Stadium scene.
- Kept hidden wild behavior disabled by default for the Gold visible-roaming mode.
- Retained Stadium 2 ROM import and National Dex 1-251 pack support.
- Retained the v0.1.65 Mods -> Options crash guard.

## Known limits

- Real-GPU Gold gameplay cannot be executed in this build environment; final render behavior needs in-game verification.
- Connected-neighbor voxel stitching is conservative while the current-map Gold voxel path is proven.
- Stadium 2 move/context animation routing is still provisional.
- The user must supply their own legally obtained Stadium 2 ROM; no ROM or ROM-derived model packs are included.
