## v0.2.22 - Dex 249 textureless-body fix

The user-supplied `249.dsm` and `249_geo_dump.txt` falsified the previous hierarchy hypothesis. All 75 extracted joints use flags `0x01`, there are no Lugia-local `0x20`/`0x21` display-list transform nodes, and the stable bind transform produces a coherent silhouette. The missing visual mass was primitive 0: `tex=-1`, 647 vertices, 1,758 indices, spanning 38 bones. `StadiumRig:draw()` skipped parts whose `StadiumPack.image()` returned nil, so this untextured lit body never reached Voxel3D. Dex 249 now maps only the 0xFFFF texture sentinel to a cached opaque 1x1 white image. The shared extractor/rig remains untouched.

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
