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
