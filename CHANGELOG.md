## v0.2.15 — Lugia 3D hierarchy recovery and capture difficulty

- Removed the unconditional Dex-249 2D fallback in `StadiumMon`.
- Added a cache-safe Lugia hierarchy probe in `StadiumRig` with normal, absolute-translation, and flat bind modes; the selected repaired bind is held static until Stadium 2 battle-animation routing is verified.
- Recomputed Lugia stance metrics from the repaired bind and forced its uploaded Stadium textures to opaque alpha.
- Kept the species-correct 2D Lugia card only as a last-resort failure path.
- Reduced the capture hit radius from 20.5% to 14.5% of the smaller screen dimension, with a strength-scaled floor down to 8.2%.
- Increased precision-ring speed for stronger Pokémon and tightened throw grades to 0.55 NICE / 0.75 GREAT / 0.91 EXCELLENT.
- Ball flight now uses the actual screen-space aim error to create a world-space impact point, so misses visibly miss.

## v0.2.14 — third-person animation from frame 1

- Fixed the 3D Character Selector trainer staying on its idle animation in 3RD/1ST until the first map transition.
- `GoldVoxelBridge.makeState()` now carries the exact live free-movement animation state into every rendered voxel frame.
- `VoxelScene` stamps that movement state onto the captured player pose, and `OverworldStadium` consumes the pose-local bit before consulting any compatibility/global world facade.
- The external 3D trainer still receives `moving=true` only during its draw/shadow call; Gold gameplay/collision/script state is restored immediately.
- Existing v0.2.13 Lugia fallback and v0.2.12 capture controls/resistance are retained.

# v0.2.13 — opaque Lugia fallback + 3RD/1ST player animation bridge

- Dex 249 still rejects the known-corrupt Stadium 2 hierarchy instead of rendering detached body/wing chunks, but its emergency presentation now uses the packaged **Lugia-specific follower sheet** in 3D world space rather than whatever generic NPC sprite happened to be attached to the roaming entity.
- Lugia's emergency card explicitly restores normal alpha blending, depth writes, and full draw alpha before rendering, preventing it from inheriting translucent/additive Stadium effect state.
- Lugia fallback size is controlled independently from the legendary 3D model scale, so the flat safety card is no longer blown up by model-oriented scaling.
- True camera-relative 3RD/1ST movement now publishes a **render-only visual walking bit** whenever continuous px/py movement actually occurs.
- The red_3d_player / 3D Character Selector bridge temporarily exposes `Player.moving=true` and walk phase 1 only during the external skin draw/shadow call, then restores Gold's real gameplay fields immediately. This lets walking animations run in 3RD/1ST without changing collision, scripts, warps, or Gold's grid-step state.
- Retains all v0.2.12 two-stage capture controls and stat/level capture resistance.

# v0.2.11 — pre-contact capture controls + Poké Ball UV fix + Lugia fail-safe

- Capture is now **manual before contact**. Normal collision/contact with a roaming Pokémon starts Gold's regular wild battle instead of opening the minigame.
- **R3 / right-stick click** on a mapped controller and **right mouse click** on PC are the primary overworld throw controls. Aim first, press once, and the chosen visible Pokémon in the camera cone receives the throw.
- Manual capture polling moved from `world.stepped` to Gold's fixed-step `input.step` hook, so a stationary player can throw without taking another map step.
- Right mouse is no longer mapped to Game Boy B by the 1ST/3RD-person mouse adapter; inside capture, **B** remains the explicit normal-battle fallback.
- The runtime Poké Ball now uses a deterministic UV sphere plus a dedicated red/white/black/button texture, with the V coordinate corrected so the red hemisphere is actually on top.
- Lugia/Dex 249 no longer renders the known-bad Stadium 2 decoded geometry. It deliberately returns to the normal Gold texture-correct sprite billboard until the Stadium 2 hierarchy/material decode is verified, preventing the detached blue wing/body chunks from appearing.
- Retains all v0.2.10 multi-Ball catch/storage behavior, Gold catch-rate integration, world-space battle FX, map streaming, cameras and forest extensions.

# v0.2.08 — remove player send-out sprite + activate Gold 3D attack effects

- Suppresses the remaining native 2D player-Pokémon back-pic during live 3D send-out when a usable Stadium model is already loaded.
- Preserves Gold's native battle-pic fallback for species whose 3D model cannot load.
- Adapts Gold's Gen-2 `BattleState:animForMove` / `AnimRunner` fields into the existing world-space Stadium effect renderer.
- 3D effects now receive the real move ID, attacker side and animation frame during Gold live-world battles.
- Enables world-space fire, water, electric, ice, psychic, poison, grass, wind, ghost/dark, dragon, rock/ground and physical-impact families in Gold.
- Adds tailored Gen-2 aliases for Icy Wind, Flame Wheel, Whirlpool, Mud-Slap, Rollout, Bone Rush, Fury Cutter and Cotton Spore.
- Prevents unknown zero-power/status moves from incorrectly firing generic damaging projectiles.
- Keeps all v0.2.07 trainer cleanup, v0.2.06 overworld capture, camera, connected-map and forest-edge changes.

# v0.2.07 — remove duplicate 2D trainer battle-intro sprite

- Live overworld Stadium battles no longer draw Gold's native **2D player trainer back-pic** during the opening/send-out phase. The 3D trainer already standing in the voxel scene remains visible, so the battle no longer shows a giant duplicate trainer sprite over the world.
- The suppression is scoped to the live voxel/Stadium battle compositor. Normal non-voxel/fallback Gold battle presentation is unchanged.
- Pokémon battle subjects are still owned by the Stadium/voxel replacement path, and Gold's actual `showPlayerTrainer` / send-out battle state continues to advance normally; only the duplicate draw is removed.
- Retains v0.2.06 overworld Poké Ball capture, v0.2.05 camera input reliability, v0.2.04 connected-map streaming, and the existing battle-camera safety fixes.

# v0.2.06 — overworld 3D Poké Ball capture minigame

- Visible battleable roaming wild Pokémon now open an **in-world capture minigame** on contact when the player has a regular POKé BALL and safe party/box storage. Safari/special/unsupported cases fall through to the unchanged normal Gold battle path.
- Uses the supplied `RegularPokeBall.dae` geometry and `pokeball_DIF.png` texture as a real world-space 3D prop. The supplied FBX and BRDF mask assets are bundled alongside it.
- Capture temporarily uses 3RD-person aiming when entered from DIORAMA without changing the saved camera choice. Existing 1ST/3RD modes stay as selected.
- **Mouse and controller right stick remain live while aiming.** Throw with A, left click, controller A, or right trigger. Press B/right click to abandon the minigame and start the normal wild battle.
- A screen-centred reticle plus a shrinking target ring grade throws as HIT / NICE / GREAT / EXCELLENT. Misses consume the ball and leave the wild Pokémon present.
- Hits use Gold's own Gen-2 catch-rate calculation with species catch rate; minigame accuracy/timing maps to an overworld weakening/quality bonus rather than replacing species difficulty.
- The ball flies in a 3D arc, lands at the Pokémon, then performs an in-world shake sequence. Breakouts restore the target so another ball can be thrown.
- Successful catches create a normal Gen-2 Pokémon, stamp player OT/ID, update seen/caught Pokédex flags, and place the Pokémon in the party or current box using Gold's existing save structures.
- If the player runs out of regular Poké Balls during the minigame, the encounter safely falls back to the normal battle rather than trapping the player.
- Retains v0.2.05 F6/right-stick camera reliability and all v0.2.04 open-world connected-map streaming changes.

# v0.2.05 — reliable F6 + controller right-stick camera

- Desktop **F6** now has a frame-polled fallback in addition to the existing Game2 key callback. If another engine/mod wrapper replaces or consumes `Game2:keypressed`, one physical F6 press still advances **DIORAMA -> 3RD -> 1ST -> DIORAMA**. A shared latch prevents the callback and poll from double-cycling the same press.
- **3RD PERSON** and **1ST PERSON** now poll mapped SDL/LÖVE controller `rightx/righty` every frame, so the right stick controls yaw/pitch even when `gamepadaxis` events are intercepted elsewhere.
- Mouse-look is unchanged and feeds the same yaw/pitch state, so controller right-stick and mouse can both be used during the same 3RD/1ST session.
- Existing raw/unmapped joystick event handling, Android right-thumb look, camera-relative movement, connected-map streaming, 32-tile forest apron, and crash-safe battle camera are retained.

# v0.2.04 — connected-map open-world streaming

- Gold/Silver voxel mode now renders the **directly connected map one full area ahead in every available cardinal direction** instead of discarding Gold's connected-map records at the 3D bridge. Routes and towns therefore exist as real 3D terrain before the player crosses their connection.
- Added a Gen-2 neighbour adapter that builds real `src.world.gen2.Map` objects from Gold's connection definitions while leaving Gold's native movement, collision and map-transition logic authoritative.
- Neighbor body meshes begin preloading in the background as soon as the current map is rendered. When the player gets within eight cells of a connected edge, that destination is promoted to the urgent mesh-build slice so fast movement is less likely to outrun streaming.
- Crossing onto a map that was already rendered as a neighbour now **reuses the warm body/full mesh immediately**, avoiding the old unnecessary synchronous rebuild at the connection seam.
- The current map's 32-tile round-tree forest apron is now built with connected-map masks from the first frame, so synthetic perimeter trees do not grow through the real next route/town. Unconnected edges keep the no-void forest extension from v0.2.03.
- Gold neighbour NPC ghosts are handed to the voxel scene with the same adapted map/offsets, allowing characters on the next connected area to appear before crossing where Gold exposes them.
- Third-person camera collision can resolve against the adapted connected maps, preventing the boom from treating a valid route connection as an imaginary end-of-world wall. Gold follower seam checks also receive the adapted `nb.map` objects through the native neighbour records.
- Retains the v0.2.03 crash-safe Stadium battle camera and 32-tile round-tree scenery apron.

# v0.2.03 — no-void forest apron + crash-safe battle camera

- Doubled the real outdoor voxel forest apron from four border blocks / 16 tiles to **eight border blocks / 32 tiles on every side**. The entire expanded apron stays on the round Johto tree-hull path, pushing visible black/empty map-edge void much farther beyond normal diorama, third-person, first-person, and live-battle views.
- Fixed a v0.2.02 active-turn camera crash on LuaJIT/LÖVE targets where `table.unpack` is unavailable by using a Lua 5.1/5.2-compatible return helper around Gold's `BattleState:advanceQueue()` observer.
- Hardened the Stadium battle camera against engine-state differences: animation/arena fields are validated and the optional cinematic camera now fails back to the ordinary live-world camera instead of crashing gameplay if an unexpected battle-state shape is encountered.
- Retains v0.2.02 close Diorama zoom, active-turn battle framing, trainer sideline placement, manual camera takeover, directional movement, Character Selector compatibility, and Stadium 2 models.

# v0.2.02 — closer Diorama + active-turn Stadium camera

- Extended continuous **DIORAMA** zoom-in from 0.55× camera distance down to 0.24×, allowing a much tighter tabletop/close view while keeping the existing 2.20× zoom-out limit.
- Smart live-world battle camera now identifies the active attacking side from Gold's real battle animation/queue state and holds a shoulder-style shot favoring that Pokemon through its resolving turn.
- During attack animation the acting Pokemon receives roughly 82% of the focus weighting; between turns the camera eases back toward the two-Pokemon midpoint and slow orbit.
- Player trainer is visually repositioned beside and slightly behind the player's Pokemon during live-world battles so the trainer no longer stands in the combat line. The real Gold player coordinate/gameplay state is unchanged.
- Manual right-thumb/mouse battle camera takeover and automatic-resume behavior from v0.2.01 are retained.

# v0.2.01 — diorama zoom + Stadium-style battle camera

- Added smooth continuous **DIORAMA ZOOM**. Android pinch changes the actual voxel camera distance; desktop wheel/trackpad zoom uses the same continuous value.
- Added **STADIUM BATTLE CAMERA**, enabled by default for LIVE OVERWORLD BATTLES.
- The live battle camera is a real placed camera orbiting the midpoint between both Stadium models, not a fake turn of the player's first/third-person camera.
- Camera orbit is slow during menus, slightly faster while resolving, and eases closer during active attack animations.
- Android right-thumb drag and desktop mouse movement temporarily take over the cinematic battle camera; automatic orbit resumes smoothly after a 2.5-second idle window.
- Turning STADIUM BATTLE CAMERA OFF keeps the existing live-overworld battle presentation without the automatic orbit.

# v0.2.00 — Android camera input + real forest perimeter fix

- Replaced the unreliable callback-only Android right-thumb camera path with direct `love.touch.getTouches/getPosition` polling, the same class of fallback that made the camera-mode slider reliable on affected Android builds.
- Right-side free touches now steer the live `FirstPerson` yaw/pitch in both 1ST and 3RD person while the left overlay controls remain available for movement.
- Live-overworld battles use the same direct right-thumb look poll, so Gold's BattleState being on the stack no longer disables camera steering.
- `CamControl.battleLive()` no longer requires legacy `BattleCam.steerable` for a Gold `liveWorld` shot.
- Expanded the actual outdoor voxel mesh perimeter from three border blocks (12 tiles) to four border blocks (16 tiles), and models the full perimeter as round Johto tree hulls. v0.1.99 only widened a hull cutoff inside the old mesh and could therefore look unchanged.

# v0.1.99 — Android split-thumb camera + fuller tree perimeter

- Android 1ST/3RD free-roam camera look now claims only the open **right side** of the screen; the left touch/D-pad remains dedicated to movement.
- LIVE OVERWORLD BATTLES now steer the same live voxel yaw/pitch with the right thumb instead of sending drags to the unused staged `BattleCam`.
- Desktop mouse battle look follows the same live-world camera path; F6 behaviour is unchanged.
- Outdoor synthetic tree perimeter hull coverage grows from 4 to 8 tiles (two to four Gen-2 cells deep), filling wide-camera map edges with more real round-tree geometry while staying inside the existing 12-tile mesh ring.
- Keeps v0.1.98 true directional/free movement and does not add fake animation flags.

# v0.1.98 — true directional free movement

- FIRST PERSON and THIRD PERSON now use intentional camera-relative **360-degree free movement** instead of quantising walking back to four Gold directions.
- Analog stick/touch-dpad magnitude is preserved, keyboard diagonals are normalized, and the player wall-slides around blocked geometry with a small circular footprint.
- The body bearing follows actual travel continuously while the logical `cellX/cellY` advances only when the free body crosses a cell boundary.
- Gold's trainer checks, `world.stepped`, warps, coord scripts, step counter and wild encounters are replayed on those real cell crossings.
- Ledges, map connections, boulder pushes, ice/currents/doors, biking, surfing, scripts and cutscenes hand back to Gold's native mover.
- DIORAMA remains ordinary Gold cardinal/grid movement.
- This release deliberately does **not** restore the old `_stadiumFreeMoving` / fake `Player:walkPhase` animation shim; external character renderers see the real `px/py` displacement instead.

# v0.1.98 — reversible camera slider + camera-relative walking

- Fixed Android **3RD/1ST -> DIORAMA** switching. An explicit slider/F6 choice now stays authoritative in CAMERA CONTROL = AUTO instead of being overwritten on the next frame by Character Selector's previous public camera rung.
- CAMERA CONTROL = CHARACTER SELECTOR still explicitly hands camera ownership back to `red_3d_player`.
- Restored camera-relative Gold movement while `red_3d_player` is active: in 1ST/3RD, UP is camera-forward, DOWN is back, and LEFT/RIGHT strafe relative to the view.
- Movement remains Gold-native/cardinal only. This does **not** restore the removed true-360/free-walk controller and does not spoof `Player.moving` or character animation state.

# v0.1.96 — Android camera slider input fix

- Fixed the visible Android DIORAMA / 3RD / 1ST slider not responding to touches.
- The slider now polls LOVE's live Android touch contacts every rendered voxel frame as a fallback instead of depending only on wrapped `Game2:touchpressed/touchmoved` callbacks.
- A touch is captured only when it begins inside the top camera slider; D-pad/buttons, look drag, and pinch gestures elsewhere remain untouched.
- Camera changes apply before the same frame's voxel camera level is resolved, so the thumb and actual camera switch together.

# v0.1.94 — Gold pinch-zoom host fix

- Fixed pinch-to-zoom doing nothing on Gold. v0.1.93 installed `CamControl` on Gen-1 `src.core.Game`; Gold uses a separate `Game2` service owner, so its touch events never reached the pinch recognizer.
- `CamControl.install(game)` now accepts and wraps the live Gold host, matching `FirstPerson.install(game)`.
- Diorama pinch now calls Gold's live `world:zoomStep()` instead of the Gen-1 `Game:zoomStep()` path.
- Third-person pinch now updates `ThirdPerson.zoomGoal` from actual Gold touch events.
- Touch callback varargs are preserved when forwarding to Gold.

# v0.1.93 — voxel pinch zoom

- Activated the renderer's existing two-finger **pinch-to-zoom** controller for Gold/Silver voxel mode.
- **Third Person:** spreading/pinching smoothly changes the camera boom distance.
- **Diorama / orbit:** pinch gestures step Gold's survey/voxel zoom in either direction.
- While a two-finger pinch is active, the gesture is claimed by zoom so it does not simultaneously rotate the first/third-person look camera.
- Touches on the virtual D-pad/buttons remain owned by the normal touch controls.
- Character Selector camera ownership from v0.1.91 remains intact; the private Gold renderer follows the selected camera mode and pinch changes the rendered voxel camera rather than forcing a different mode.
- First Person intentionally has no distance zoom because the camera is located at the player's eye position.

# v0.1.92 — seamless live-overworld battle entry

- When **LIVE OVERWORLD BATTLES** is ON, ordinary wild encounters now skip Gold's native `Gen2BattleTransition` screen entirely.
- Removes the expanding black-circle / battle-wipe effect at encounter start, because the fight now stays in the same encounter-site voxel world instead of transitioning to a different scene.
- Gold still keeps its native battle UI, logic, catching, switching, and post-battle flow; only the transition screen is skipped for this one seamless mode.
- If **LIVE OVERWORLD BATTLES** is OFF, Gold's classic battle transition and classic battle presentation are unchanged.

# v0.1.91 — Character Selector camera ownership fix

- Added **CAMERA CONTROL** with `AUTO`, `THIS MOD`, and `CHARACTER SELECTOR`.
- `AUTO` detects `red_3d_player` and mirrors the public Gen1Recomp `voxel` pipeline state into this standalone Gold renderer.
- Character Selector `1ST` / `3RD` camera selections now drive the matching private Gold voxel camera instead of being overwritten every frame.
- Mouse/touch look input is forwarded while the selector owns the camera rather than being swallowed by this mod's private camera hook.
- This mod's Gold camera-relative cardinal movement rewrite now stands down while Character Selector owns camera control, preventing it from overriding the selector's Gen-2 directional movement.
- F6 only cycles this mod's camera while **THIS MOD** owns camera control.
- Keeps the lean v0.1.90 package and optional **LIVE OVERWORLD BATTLES** toggle.

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
