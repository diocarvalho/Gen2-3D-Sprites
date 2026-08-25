# v0.4.33 — First-class Pokemon Crystal compatibility

- Targets current Gen1Recomp where `games = ["gen2"]` expands to Gold, Silver, and Crystal.
- Adds Crystal to the sandbox-safe Android/iOS native picker bridge and routes picker requests to the active Gen-2 edition.
- Namespaces the persistent voxel mesh cache by active game (`gold`, `silver`, `crystal`) and includes the edition in mesh signatures, preventing cross-edition sector-cache thrash for maps sharing the same symbolic id.
- Exposes `hostVersion`, `hostEngine`, and `crystalCompatible` in the mod runtime diagnostics.
- Updates current runtime/user-facing host wording from Gold/Silver-only to Gold/Silver/Crystal or generic Gen-2 authority where appropriate.
- Includes Crystal's `MYSTICALMAN` / Eusine trainer class in Stadium announcer boss-scope detection.
- Keeps the current engine-owned player sprite authoritative, which preserves Crystal's Chris/Kris selection in the voxel card path.
- Retains v0.4.32 Kanto OPEN WORLD + WORLD OCEAN, v0.4.31 persistent sector preloading, and all earlier UI/announcer/voxel work.
- Version advances from v0.4.32 to v0.4.33.

# v0.4.31 — Persistent sector preloading

- Adds automatic persistent BODY-cache preloading for nearby native-Johto sectors.
- Prioritizes directly connected sectors, then second/third-ring prepared sectors, so likely travel destinations are cached first.
- Uses cache-only mesh derivation: sectors are written to persistent storage without keeping far GPU meshes resident.
- Bounds the preload queue by platform/build mode: phones remain conservative while desktop can cook farther ahead.
- Marks all visible Gold world frames interactive for cache-only pacing, preventing background preload work from taking the larger idle slice during movement.
- Keeps Kanto on its existing dedicated whole-region cache warmer rather than double-scheduling it.
- Adds Johto/Kanto warm-pending counters to voxel disk-cache status and `tests/sector_disk_preload_parity.lua`.
- Retains the v0.4.30 UI text-size slider and all previous Pidgeotto, app-grid, announcer/Kanto, and voxel optimizations.
- Version advances from v0.4.30 to v0.4.31.

# v0.4.25 — Pidgeotto flight-safe loop fix

- Removes the Dex-17 full animation-table scan that could choose a high-motion Stadium battle attack as the overworld flight loop.
- Restricts Pidgeotto airborne selection to `idle_alt`, `idle_return`, and `entrance_alt`.
- Rejects candidate animation indices that alias attack, struggle, faint, flinch, or reaction contexts, plus clips carrying combat labels.
- Falls back to ordinary idle if no distinct non-combat alternate exists; an attack animation is never used as a flight fallback.
- Restores the airborne clip playback rate to the authored 1.0× cadence.
- Retains v0.4.24's restored PC/phone Mod Settings icon grid and all earlier announcer/Kanto/voxel changes.
- Version advances from v0.4.24 to v0.4.25.

# v0.4.24 — Restore the Mod Settings icon app grid

- Keeps the **MOD SETTINGS homescreen-style category grid with icons** as the root UI on both PC and phone builds.
- Removes v0.4.23's behavior that converted a custom-renderer error into Gen1Recomp's native flat options list.
- Adds a compatibility **icon-grid renderer** that uses guarded, older/simple LOVE graphics calls if the full glass renderer fails.
- Preserves all thirteen category/root rows, all twelve bundled PNG category icons, the RESET vector fallback, selection state, controller/keyboard navigation, and exact-category return behavior during degraded rendering.
- Retains the responsive **5×3 phone landscape / 3×5 phone portrait** layout, `input.pointer` direct icon taps, and touch BACK target.
- Keeps v0.4.23's portable `love.graphics.push()` handling and Pidgeotto airborne animation fix.
- Updates the PC/phone crash regression so a synthetic graphics failure must remain in the icon grid and must never call native ManagerState drawing.
- Complete test suite remains 68 tests.
- Version advances from v0.4.23 to v0.4.24.

# v0.4.23 — Crash-safe PC/phone Mod Settings + Pidgeotto flap fix

- Wraps the custom MOD SETTINGS root build/input/draw paths so a renderer or backend exception cannot crash ManagerState.
- Removes the `love.graphics.push("all")` dependency from the grid/reset-vector transform path and uses the older portable `push()` form, covering PC/mobile LÖVE builds that reject the stack-type argument.
- Falls back to Gen1Recomp's native flat option rows for the current options session after a custom-grid failure and prevents the failed grid from being rebuilt every frame.
- Replaces direct `Game`/`Game2.touchpressed` replacement with Gen1Recomp's supported `input.pointer` hook, preserving mobile TouchControls ownership.
- Adds a full-surface phone layout: 5×3 category grid in landscape and 3×5 in portrait, with orientation-matched D-pad navigation, direct icon taps, and a touch BACK target.
- Handles both OS-window pointer coordinates and GameViewport-local coordinates when the menu is drawn into a low-resolution game target.
- Fixes Fly Your Pokémon Pidgeotto having its selected airborne clip overwritten by the ground locomotion bridge later in the same frame.
- Makes all airborne Stadium presentations bypass ground gait selection.
- For Dex 17, scores real Stadium skeletal track motion and scans species-specific authored animations when the generic context slots do not expose a visible flap.
- Keeps static-safe Pidgeotto models eligible for the airborne-only alternate clip and restores bind/idle state after landing.
- Adds `tests/custom_ui_pc_phone_crash_parity.lua` and expands the Pidgeotto regression coverage; complete suite is now 68 tests.
- Retains v0.4.22 announcer, Kanto wild-population, and Kanto ambient-flyer changes.
- Version advances from v0.4.22 to v0.4.23.

# v0.4.22 — Stadium announcer + denser Kanto wilds and flyers

- Fixes the remaining current-Gen1Recomp announcer playback failure: the in-memory WAV loader no longer directly touches sandbox-blocked `love.filesystem`; FileData lookup is protected and PCM `SoundData` remains the cross-platform fallback.
- Prepares each voice source for one-shot full-volume playback and keeps the existing persisted 823-WAV ROM cache compatible.
- Under the default **GYM / ELITE 4 / CHAMPION** scope, Gold/Johto boss battles without a Stadium 1-specific intro now still enter the announcer engine and receive reusable species/move/damage/faint/result voice calls.
- Raises Yellow/Kanto visible encounter population from the old common two-body result to a five-body grass / three-body water baseline when map capacity allows, scaling modestly with encounter rate and map size.
- Raises per-map Kanto caps to ten visible grass Pokemon and five water Pokemon, while retaining cell-capacity and distance culling safeguards.
- Retries deterministic Kanto spawn cells when NPCs/static Pokemon occupy a selected position, preventing silent population loss from hash collisions.
- Adds a lightweight `TwinRegionWorld.ambientFlyerWorld()` view so AmbientFlyers uses the real current Yellow map/encounter table without double-ticking the Kanto runtime.
- Bridges ambient sky Pokemon into Kanto's excursion actor list; NORMAL Kanto sky density now targets roughly four to five flyers on medium performance, with lower caps on LOW.
- Keeps v0.4.21's Pidgeotto authored airborne animation routing for the newly visible Kanto sky population.
- Adds announcer sandbox, Kanto visible-population, and Kanto ambient-flyer regression coverage; complete suite is now 67 tests.
- Version advances from v0.4.21 to v0.4.22.

# v0.4.21 — Pidgeotto airborne Stadium animation fix

- Fixes Dex 17 Pidgeotto looking frozen while moving through the 3D overworld sky.
- Adds an airborne-only Stadium clip override that prefers Pidgeotto's authored `idle_alt` motion, then safely falls back to `struggle` / `attack_default` only when necessary.
- Rejects alternate context names that resolve to the same primary idle animation, preventing a false fix when Stadium routing aliases two slots.
- Applies the fix to both ambient flying Pidgeotto and Pidgeotto used by **Fly Your Pokémon**.
- Restores the ordinary idle automatically when the mount leaves flight mode; all other flying species keep their existing animation routing.
- Adds `tests/pidgeotto_airborne_animation_parity.lua`; complete suite is now 64 tests.
- Version advances from v0.4.20 to v0.4.21.

# v0.4.20 — Larger borderless Mod Settings icons

- Removes the per-icon translucent rounded-square well from the MOD SETTINGS 4x4 homescreen grid.
- Increases the icon allocation from the old 70% inner-art scale to 96% of a larger icon area, making both raster and fallback icons substantially bigger.
- Tightens the vertical spacing between icon artwork and labels so the larger art still fits cleanly in each app cell.
- Keeps the selected app's full-cell highlight/outline, all twelve bundled PNG icons, RESET ALL vector fallback, navigation, and option behavior unchanged.
- Updates `tests/custom_ui_icon_grid_parity.lua` to reject reliance on per-icon well geometry while preserving packaged-icon coverage.
- Retains v0.4.19 menu icon assets and v0.4.18 voxel hot-path optimizations.
- Version advances from v0.4.19 to v0.4.20.

# v0.4.19 — Remaining Mod Settings PNG icons

- Uses the six newly supplied PNG icons for the remaining non-reset MOD SETTINGS root categories.
- Adds bundled raster assets for **3D MODELS**, **FLY PKMN**, **WILD PKMN**, **FOLLOW BEHAVE**, **DEV TOOLS**, and **OTHER**.
- Keeps the existing PNG icons for **UI**, **PERF/GFX**, **WORLD**, **WEATHR/FX**, **CAMERA/DISPLAY**, and **BATTLE**.
- Leaves **RESET ALL** on the vector fallback renderer so the reset affordance still has a guaranteed icon path.
- Extends `tests/custom_ui_icon_grid_parity.lua` so the packaged icon loader now verifies all twelve bundled PNG category icons on the single-page grid.
- Retains v0.4.18 voxel hot-path optimizations unchanged.
- Version advances from v0.4.18 to v0.4.19.
# v0.4.17 — Performance optimization pass

- Adds **AUTO / RECOMMENDED** to PERFORMANCE PRESET and makes it the new-install default. AUTO measures real voxel draw cost before frame-limiter sleep, starts at MEDIUM, demotes after sustained expensive draws, and only promotes after a long stable-headroom dwell.
- AUTO is runtime-only: it does not spam option writes or rewrite CUSTOM child rows. Switching presets or toggling the voxel renderer resets the governor cleanly.
- MEDIUM keeps 55% internal render resolution/blob shadows/sky reflections but reduces Kanto background prefetch from 2 rings to 1 and uses the SMOOTH mesh-build policy.
- HIGH keeps 75% internal resolution and real sun shadows but uses the fast SKY reflection path; FULL SSR is reserved for ULTRA/CUSTOM.
- Tightens off-screen world/detail/figure/actor culling and reduces actor prefilter radius, cutting OPEN WORLD/Stadium draw submissions without changing collision or gameplay records.
- Shortens cooperative mesh-build slices to reduce main-thread hitches while routes/sectors warm in the background.
- Real shadow maps refresh less often while moving: HIGH at 30 Hz, LOW at 20 Hz; stationary signature caching remains unchanged.
- Visible Wilds AI now ticks by performance tier (20/30/45/60 Hz for LOW/MEDIUM/HIGH/ULTRA) instead of running every presentation frame.
- Ambient sky Pokémon use the same tiered cadence, cap their count on LOW/MEDIUM, and perform zero update work while native 2D mode is active.
- Weather FX AUTO now starts at MEDIUM on every platform and climbs to HIGH only after its existing governor confirms headroom, avoiding a first-seconds particle spike on phones/integrated GPUs.
- Adds `tests/performance_optimization_parity.lua`; complete suite is now 62 tests.
- Version advances from v0.4.16 to v0.4.17.

# v0.4.16 — Native Gold/Silver 2D compatibility pass

- Makes **3D VOXEL WORLD** the sole master switch for the overworld renderer. OFF is now a supported first-class native Gold/Silver 2D mode rather than a fallback state.
- OPEN WORLD can remain enabled as a remembered 3D residency preference, but it cannot activate voxels or extend survey zoom while the master switch is OFF.
- On a live switch to 2D, releases first/third-person camera ownership, relative mouse capture, camera-relative continuous movement, stale body yaw/blend state, and the local voxel level. Booting directly into 2D runs the same cleanup.
- Native 2D compose now redraws Gold's authoritative world before custom menu overlays and visible-wild fallback sprites, so pause/submenu presentation stays modern without requiring a voxel backdrop.
- Temporarily suspends active **companion `drawWorld` pipelines only during the native-world redraw**, then restores their exact live levels without writing their options. This prevents Character Selector/other world pipelines or stale same-frame voxel output from defeating the explicit 2D choice.
- Weather FX now asks whether this host's 3D renderer is actually active; a dormant installed voxel host no longer suppresses 2D precipitation/fog presentation.
- OPEN WORLD zoom extensions stand down in 2D, leaving Gold's native zoom controls/range authoritative.
- The 3D shoulder capture minigame stands down in 2D; visible wild Pokémon continue through normal 2D battles and catching.
- Detached Yellow/Kanto free roam no longer auto-promotes 3D. Entry is refused with a clear message while native 2D is selected, and disabling 3D during a Kanto excursion returns safely to Johto.
- Exposes `mod.exports.world3DEnabled()` so companion mods can distinguish **installed** from **actually rendering in 3D**.
- Keeps 3D battle presentation independent, allowing a native 2D overworld with optional Stadium-style battles.
- Adds `tests/two_d_mode_parity.lua` and `tests/two_d_compose_runtime_parity.lua`; complete suite is now 61 tests.
- Version advances from v0.4.15 to v0.4.16.

# v0.4.15 — Right-side homescreen Mod Settings

- Reworks the single-page MOD SETTINGS root so it docks to the **right side** of the screen instead of occupying a centered, near-fullscreen overlay.
- Keeps all categories visible at once in a compact **4x4 homescreen-style app grid** with icon-first cells, labels beneath each icon, and a selected-app highlight.
- Shrinks the panel footprint so the left side of the paused game remains visible, matching the general feel of the pause menu drawer.
- Retains the bundled custom PNG icons for UI, Performance, World, Weather, Camera, and Battle, with fallback icons for the remaining categories.
- Footer now reports the total as **APPS** to match the phone-homescreen presentation.
- Keeps v0.4.14's single-page category availability, v0.4.12 packaged icon loader fix, v0.4.09 iPhone orientation fix, and OPEN WORLD renderer decoupling.
- Version advances from v0.4.14 to v0.4.15.

# v0.4.14 — Single-page 4×4 MOD SETTINGS grid

- Fits all 13 current root tiles on one screen using a compact **4 columns × 4 rows** layout.
- Removes category page switching and replaces the old page counter with a simple `13 CATEGORIES` footer indicator.
- Tightens panel padding, card gutters, card radius, and icon spacing so the full grid remains dense and readable.
- Left/Right moves across four columns; Up/Down moves by one row of four and wraps within the same column.
- Keeps the six packaged custom PNG icons, vector fallbacks for the remaining categories, exact-tile return behavior, modern category pages, iPhone orientation hardening, and OPEN WORLD renderer independence.
- Version advances from v0.4.13 to v0.4.14.

# v0.4.13 — Compact 3×2 icon grid

- Changes each six-category page from 2 columns × 3 rows to a denser **3 columns × 2 rows** layout.
- Shrinks the outer glass panel, header/footer padding, and category-card gutters so the menu no longer wastes most of the screen on empty card width.
- Centers and enlarges each category icon, with the category name and setting count directly below it.
- Keeps the six supplied raster PNG icons and the packaged `mod:read()` loader fix from v0.4.12.
- Keeps spatial controller/keyboard/touch navigation, exact-tile return behavior, modern category pages, iPhone orientation hardening, and OPEN WORLD renderer independence.
- Version advances from v0.4.12 to v0.4.13.

# v0.4.12 — Packaged custom icon loader fix

- Fixes v0.4.11 still showing the old category glyphs in installed `.zip` builds.
- Loads the six supplied PNG assets through `mod:read()` instead of treating `assets/...` as game-root filesystem paths.
- Decodes packaged bytes through LOVE `ByteData -> ImageData -> Image`, matching the mod's existing sandbox-safe PNG loaders.
- Keeps direct-path loading only as an unpacked/development fallback.
- Adds regression coverage proving page 1 decodes and draws all six supplied raster icons.
- Keeps v0.4.10 modern glass cards, v0.4.09 iPhone orientation hardening, and OPEN WORLD renderer independence.
- Version advances from v0.4.11 to v0.4.12.

# v0.4.11 — Custom PNG icon pack for Mod Settings

- Keeps the v0.4.10 modern glass/card MOD SETTINGS root but swaps six category tiles to bundled PNG artwork supplied for the menu redesign.
- Uses the supplied icons for **BATTLE**, **CAMERA / DISPLAY**, **PERFORMANCE / GRAPHICS**, **UI / MENUS**, **WEATHER FX**, and **WORLD**.
- Remaining categories continue to use the existing scalable fallback icon renderer so no category loses an icon if a custom asset is missing.
- Adds `assets/menu/mod_settings_icons/` and loads those images lazily/cached through LOVE at draw time.
- Keeps the same 2x3 paged grid navigation, option persistence, modern category pages, v0.4.09 iPhone orientation fix, and OPEN WORLD renderer decoupling.
- Version advances from v0.4.10 to v0.4.11.

# v0.4.10 — Modern NEW-UI icon-grid Mod Settings

- Replaces the v0.4.08 icon grid's retro 160×144 `Font.drawBox` presentation with the same translucent navy glass, rounded cards, scalable typography and selected-card treatment used by the CUSTOM UI pause/mod menus.
- Keeps the existing 2×3 paged category model and spatial Left/Right/Up/Down navigation; this is a presentation correction, not a settings-storage rewrite.
- Category icons remain vector-drawn but now scale cleanly with the card size instead of being fixed 14-pixel glyphs.
- Uses the existing mobile short-dimension scale helper so phone landscape keeps large readable cards and text.
- The selected category's full title and option count are shown in the modern header; each card also shows its setting count.
- Category pages continue through the already-modern Mod Manager skin and Gen1Recomp `ManagerState:buildOptionRows()` path, so persistence, conditional visibility, editors, live CUSTOM UI switching, OTHER and RESET ALL behavior stay intact.
- Updates `tests/custom_ui_icon_grid_parity.lua` to reject retro `Font.drawBox` tiles and verify the modern scalable renderer.
- Keeps every v0.4.09 iPhone orientation and OPEN WORLD renderer fix.
- Version advances from v0.4.09 to v0.4.10.

# v0.4.09 — iPhone native orientation + OPEN WORLD renderer decoupling

- Fixes the iPhone upside-down report at the mod layer without guessing from unrelated engine features: **IPHONE ORIENTATION FIX** now explicitly requests the normal iPhone orientation mask (`Portrait + LandscapeLeft + LandscapeRight`) through both SDL3 and SDL2 hint names.
- Removes automatic iOS whole-frame 180-degree correction entirely. `landscapeFlipped` is now diagnostic only; UIKit/SDL owns framebuffer rotation, touch rotation and safe-area orientation.
- Uses current Gen1Recomp's iOS-aware `src.core.Orientation.apply("landscape")` as a guarded fallback if direct SDL hinting is unavailable. This matches the engine fix added in dev commit `8c0d0ace4d8e132c8bbe00c55d0f71f3711b6838` on 2026-08-21.
- Keeps **IPHONE FORCE 180** as an explicit emergency-only fallback; it is the only iOS path that can post-rotate the finished frame.
- Fixes **OPEN WORLD forcing voxels back ON**. `3D VOXEL WORLD` is again the renderer master switch; OPEN WORLD only remembers/changes voxel residency and waits inertly while Gold/Silver native 2D is selected.
- The detached Yellow/Kanto excursion remains the compatibility exception because that region is owned by this mod rather than Gold's native map renderer.
- Adds `tests/open_world_voxel_master_switch_parity.lua` and upgrades `tests/ios_orientation_flip_parity.lua` for the native orientation-mask behavior.
- Keeps v0.4.08 icon-grid settings and every v0.4.07 renderer-stability fix.
- Version advances from v0.4.08 to v0.4.09.

# v0.4.08 — Icon-grid Mod Settings

- Replaces this mod's long category-root list with a **2×3 paged icon grid**.
- Adds purpose-drawn icons for UI/Menus, Performance/GFX, World, Weather, Camera/Display, Battle, 3D Models, Fly/PKMN, Wild/PKMN, Followers/Behavior, Developer Tools, OTHER and RESET ALL.
- Adds spatial controller/keyboard navigation: Left/Right moves columns, Up/Down moves rows and crosses pages, A opens, B returns.
- Keeps category submenus on Gen1Recomp's native option-row builder/persistence path.
- Preserves live CUSTOM UI OFF→ON rebuilding, category cursor restore, conditional rows, option events and defaults.
- Unknown future settings remain reachable through an automatic OTHER tile.
- Adds `tests/custom_ui_icon_grid_parity.lua`.
- Version advances from v0.4.07 to v0.4.08.

# v0.4.07 — FPS / third-person right-stick 3D stability fix

- Fixes the reported case where holding the controller **right stick** to look around in FPS/THIRD PERSON could temporarily expose Gold/Silver's native 2D world until the stick returned to center.
- Treats active right-stick look as camera ownership, not a camera-mode request: a transient external pipeline/selector read cannot replace an already-selected FIRST/THIRD mode while that look input is being consumed.
- Stops rebuilding the optional sun shadow map on every analog-look sample when a valid map already exists. The last valid sun map is reused while the stick moves and refreshed once the camera settles.
- Isolates both shadow-pass startup and caster/draw failures. A bad optional shadow refresh now unwinds its GPU state and lets the same main Voxel3D frame continue instead of bubbling out to the engine's native 2D fallback.
- Adds diagnostic counters for camera-mode stick holds, shadow-look deferrals and shadow-refresh failures.
- Adds `tests/fps_right_stick_3d_stability_parity.lua`.
- Keeps v0.4.06 player-billboard sizing, v0.4.05 clean no-PokeDoom state, and all Gold/Silver/mobile/UI/controller fixes.
- No terrain geometry change; persistent voxel cache revision remains unchanged.
- Version advances from v0.4.06 to v0.4.07.

# v0.4.06 — Third-person player billboard scale fix

- Fixes the screenshot-confirmed oversized 2D player trainer in voxel **THIRD PERSON**.
- Adds a player-only apparent-size compensation tied to the actual third-person camera boom length; the normal 48px boom uses a 0.75 native-card presentation scale, shorter collision-compressed booms shrink proportionally, and distant views never enlarge the authored sprite above 1.0x.
- Normalizes taller/high-resolution custom player sheets against the native 16px trainer footprint for third-person billboard presentation, without changing their source art or normal 2D rendering.
- Applies the same transform to the solid player card, occlusion ghost, sun-shadow caster and fallback/blob shadow so all player presentation layers remain registered.
- Leaves NPCs, Pokemon, terrain, props, camera FOV and world perspective unchanged.
- Keeps the v0.4.04 Gold/Silver/mobile/UI/controller/player-walk fixes and the v0.4.05 complete removal of the FPS addon.
- Adds `tests/third_person_player_billboard_scale_parity.lua`.
- No Kanto terrain geometry change; persistent voxel cache revision remains unchanged.
- Version advances from v0.4.05 to v0.4.06.

# v0.4.05 — Clean Gold/Silver build

- Removes the previously integrated FPS addon completely: runtime modules, menu/settings rows, import controls, native WAD/PK3 helpers, HUD/weapons/enemies/items/effects, movement overrides, assets, tests, exports and save-state hooks are no longer part of this package.
- Removes the standalone-addon conflict from `manifest.json`; the Stadium2 mod no longer knows about or depends on that addon.
- Restores the ordinary Stadium/Gold continuous movement speed path in Johto and Kanto by deleting the addon's absolute-momentum compatibility branch.
- Retains every v0.4.04 Silver/mobile/UI/controller/player-animation fix.
- No Kanto terrain geometry change; persistent voxel cache revision remains unchanged.
- Version advances from v0.4.04 to v0.4.05.

# v0.4.04 — Silver + mobile/UI/controller compatibility

- Adds edition-aware **Pokemon Silver** support on current Gen1Recomp. The runtime remains generation-scoped, while the mobile picker bridge now follows the active `gold`/`silver` edition and includes Silver in its ready state.
- Fixes the custom Gen-2 Pokédex entry action list: its vertical PAGE / AREA / CRY / PRNT menu now responds to **UP/DOWN** (LEFT/RIGHT remain a native compatibility shortcut).
- Adds a shared phone-aware Stadium UI scale policy. Android/iOS menu/text layouts keep the desktop baseline but gain a touch-readable logical short-side floor instead of shrinking to tiny desktop-window proportions.
- Fixes live CUSTOM UI switching. Turning the custom UI OFF and back ON inside the same Mod Settings session rebuilds the categorized root immediately; no unpause/re-pause is required to escape the flat long list.
- Fixes iPhone upside-down behavior on current hosts by trusting UIKit/SDL's native LandscapeLeft/LandscapeRight transform and removing the old double 180-degree rotation. Adds **IPHONE FORCE 180** as an explicit legacy escape hatch.
- Controller **left-stick click / right-stick click** now zoom DIORAMA out/in through the same `DioramaZoom` service used by wheel/pinch.
- Fixes the 2D Gen-2 player card sliding without leg animation in voxel mode: the voxel pose now refreshes from Gold/Silver `Player:walkPhase()`, uses distance-driven cadence for continuous movement, and repairs missing player `walker` metadata only on the player sprite.
- Adds four new regression files and expands the release suite from 52 to **56/56** passing tests.
- No Kanto terrain geometry change; persistent voxel cache revision remains unchanged.
- Version advances from v0.4.03 to v0.4.04.


# v0.4.01 — Yellow Summer Beach House / Surfing Pikachu parity

- Restored the Yellow-only Summer Beach House as a real Kanto gameplay service instead of a dialogue-only sandbox interaction.
- The Surfin' Dude now checks Gold's authoritative party for a PIKACHU that actually knows SURF, matching Yellow's eligibility rule.
- Saying YES launches Gen1Recomp's current engine-owned `src.ui.SurfingMinigame`; the mod does not duplicate or fork the minigame physics/UI.
- Surfing high score is bridged into the engine screen from Kanto-local persistence and copied back on completion, then Gold's pre-existing `save.surfingHighScore` value is restored exactly.
- Yellow's per-map-load `surfinDudeAsked` / `surfedThisVisit` behavior is restored: the short repeat prompt and printer access last only for the current Beach House visit.
- Beach House Pikachu cry, Surf-capable poster variants, and the high-score printer now route through the direct safe handler.
- Added `lib/KantoSummerBeach.lua` so the already-large `TwinRegionWorld.lua` stays below Lua's 200-local main-chunk limit.
- Added `tests/kanto_surfing_pikachu_parity.lua`; full regression result is 51/51 test files passing under Lua 5.4.
- No geometry changes; persistent voxel geometry cache remains `g2vx-400-r1`.

# v0.4.00 — Kanto Pokemon Center healing + full void-tree belt

- Kanto Pokemon Center nurses now heal Gold's authoritative party even when the imported Yellow cache omitted the optional `nurse=true` text-pointer marker.
- Nurse routing is center-scoped and recognizes Nurse sprite/text identities before generic dialogue handling can swallow the interaction.
- Healing still prefers Gen1Recomp's native party healer and retains the compatibility fallback.
- Every outdoor private Yellow/Kanto off-body non-water apron cell is now filled with Kanto's authored pale tree crown instead of empty/white void.
- Coastal/water edges still extend as water first, so the new tree fill does not overwrite ocean boundaries.
- Synthetic Kanto void trees are forced to round tree geometry, never giant rectangular wall prisms.
- Geometry cache bumped to `g2vx-400-r1`.
- Preserves all earlier Kanto progression, reward, color, and purple/pink-block fixes.

# v0.3.99 — Final authored Yellow TM-gift sweep

- Restored Celadon Mart 3F's one-time Yellow TM18 COUNTER gift.
- Restored Cinnabar Lab Metronome Room's one-time Yellow TM35 METRONOME gift.
- Gold's TM18 and TM35 teach unrelated moves, so neither numeric Gold TM is inserted into the PACK.
- Both rewards use persistent Kanto-local single-use machine credits and Yellow's original species TM/HM compatibility.
- Failed/canceled/incompatible teaching preserves the credit; successful teaching consumes only the local machine credit while the original Yellow receive event remains permanent.
- Preserves the v0.3.92 purple/pink mesh removal and every later gameplay parity fix.
- Geometry cache remains `g2vx-392-r1`; no geometry changes in this release.

# v0.3.98 — Early Route 22 rival / Yellow Eevee evolution parity

- Restored Yellow's optional first Route 22 rival battle at the authored trigger cells, using RIVAL1 party 2.
- Oak's Lab rival result now persists the real Yellow Eevee branch: player win -> Flareon route; player loss -> Vaporeon route.
- Winning the optional first Route 22 battle promotes only the Flareon route to Jolteon, exactly matching Yellow.
- Obtaining the Boulder Badge permanently skips the optional early Route 22 encounter and leaves the existing Flareon/Vaporeon route intact.
- Pokemon Tower, late Route 22, and Champion rival party formulas now consume the persisted route instead of depending on the historical Jolteon fallback.
- Existing older saves without the new history still retain the prior Jolteon fallback for compatibility.
- Geometry cache remains `g2vx-392-r1`; this is gameplay/state parity only.

# v0.3.97 — Remaining standalone Kanto reward parity

- Restored the Celadon Diner Gym Guide's one-time COIN CASE gift as Gold's real key item.
- Restored the Route 12 Gate 2F girl's TM39 SWIFT gift, resolved by move semantics rather than trusting a cross-generation TM number.
- Restored Silph Co. 2F's Yellow TM36 SELFDESTRUCT reward as a persistent Kanto-local single-use machine credit.
- Gold's unrelated TM36 is never inserted into the PACK.
- SELFDESTRUCT uses Yellow's original species TM/HM compatibility and Gold's native move-learning flow.
- Failed/canceled teaching keeps the local credit; successful teaching consumes only that credit while the Yellow received-TM event stays permanent.
- Preserves v0.3.92's purple/pink block removal and all later Kanto parity work.

# v0.3.96 — Saffron Copycat / Yellow TM31 MIMIC parity

- Restored Copycat's one-time POKE DOLL trade in COPYCATS_HOUSE_2F.
- One POKE DOLL is consumed only when the Yellow reward state is created.
- Yellow TM31 MIMIC is represented as a persistent Kanto-local single-use machine credit.
- The credit uses Yellow's original species TM/HM compatibility and teaches MIMIC through Gold's move-learning flow.
- Gold's unrelated TM31 is never inserted into the PACK.
- A canceled or incompatible teach attempt preserves the MIMIC credit for later.
- After the credit is used, Copycat remains permanently in her post-reward explanation state.
- Preserves v0.3.92's purple/pink block removal and every later Kanto parity fix.

# v0.3.95 — Celadon rooftop Yellow-TM parity

- Restored all three Celadon Mart rooftop drink-girl rewards.
- Fresh Water earns Yellow TM13 ICE BEAM, Soda Pop earns Yellow TM48 ROCK SLIDE, and Lemonade earns Yellow TM49 TRI ATTACK.
- These are not mapped by TM number into Gold: those numbers teach unrelated moves in Gen 2.
- Each reward is represented as a persistent Kanto-local, one-use machine credit and teaches the exact Yellow move using the imported Yellow species `tmhm` compatibility table.
- The drink is consumed before the reward, matching Yellow. Canceling or failing to choose a compatible Pokémon leaves the earned machine credit intact for a later retry.
- No foreign TM id is injected into Gold's PACK.
- Preserves the v0.3.92 purple/pink block removal and every earlier Kanto parity system.

# v0.3.94 — Cerulean robbery aftermath parity

- Completed the physical Cerulean City aftermath that v0.3.93's TM28 return did not yet reconstruct.
- Before TM28 is returned: Rocket thief visible, Guard 1 hidden, Guard 2 visible.
- After TM28 is successfully returned: Rocket thief hidden, Guard 1 visible, Guard 2 hidden, matching Yellow's `CeruleanHideRocket` object swap.
- The actor swap is rebuilt from persistent Kanto state every time Cerulean City loads, including older saves.
- Cerulean's robbed-house Fishing Guru now checks Gold's actual TM28/DIG inventory instead of a detached Yellow bag.
- Cerulean Rocket victory explicitly persists `EVENT_BEAT_CERULEAN_ROCKET_THIEF` so the TM-return phase cannot be lost if trainer-header metadata is incomplete.

# v0.3.93 — Cerulean stolen-TM progression parity

- Restored the Cerulean Rocket thief's post-battle TM return as real Gold state.
- After `EVENT_BEAT_CERULEAN_ROCKET_THIEF`, talking to the thief returns Gold's real TM28 DIG.
- A full PACK does not consume the one-time reward or remove the thief; the player can retry, matching Yellow's flow.
- The thief disappears only after TM28 is successfully accepted, and the completion is persisted in Kanto-local event state.
- Preserves v0.3.92's giant purple/pink mesh removal and all earlier Kanto systems.

# v0.3.92 — Kanto purple/pink block removal

- Removed the giant purple/pink rectangular mesh artifacts shown in Kanto; they are removed, not recolored.
- Disabled heuristic whole-building inference on the private Yellow/Kanto adapter. Exact authored Kanto building templates remain active.
- Large imported-Kanto structural leftovers with substantial roof texture evidence are now flattened to synthesized local ground instead of being emitted as upright cuboids.
- Bumped the voxel geometry cache to `g2vx-392-r1` so old purple/pink meshes cannot survive from disk.

# v0.3.91 — Kanto Safari/Fuchsia HM progression parity

- Safari Zone West GOLD TEETH are now a Kanto-local key item; they never leak into Gold/Silver's inventory namespace.
- The Warden now consumes GOLD TEETH, persists EVENT_GAVE_GOLD_TEETH, awards Gold's real STRENGTH HM by move semantics, and retries HM04 after a full PACK without requiring another teeth pickup.
- The Safari Secret House now awards Gold's real SURF HM by move semantics, persists EVENT_GOT_HM03, retries safely after a full PACK, and never duplicates an already-owned unique HM.
- Yellow Kanto field moves now use the retail Yellow badge table: FLASH=BOULDER, CUT=CASCADE, FLY=THUNDER, STRENGTH=RAINBOW, SURF=SOUL. Johto Fog/Storm/etc. badges can no longer bypass or block the companion Kanto progression.
- Added `lib/KantoSafariProgress.lua` and `tests/kanto_safari_fieldmove_parity.lua`.
- Regression: 43/43 Kanto/mobile test files pass.

# v0.3.90 — Kanto rival progression / Cerulean Cave postgame parity

- Restored the scripted Cerulean City bridge Rival encounter on Yellow's authored `(20,6)` / `(21,6)` trigger cells. The bridge now runs `OPP_RIVAL1` party 3 through Gold's trainer battle system, then the Rival leaves persistently instead of remaining as a stray map actor.
- Restored Pokemon Tower 2F's Rival encounter on `(15,5)` / `(14,6)`. Its party is selected with Yellow's `wRivalStarter + 1` rule and the actor disappears after the completed fight.
- Restored Route 22's late League warm-up Rival on `(29,4)` / `(29,5)`. It only activates after all eight companion Kanto badges are owned and uses Yellow's `OPP_RIVAL2` `wRivalStarter + 7` party selection.
- Added a dedicated rival visibility migration: the three script-revealed Rival actors stay hidden during ordinary roaming, are force-revealed only when their encounter starts, and remain hidden after victory or on upgraded saves whose event already completed.
- Restored the actual Yellow Cerulean Cave postgame gate. Before the companion Kanto Hall of Fame, the Super Nerd at `(4,12)` is force-visible and the Cerulean City -> Cerulean Cave 1F warp is independently blocked so collision/free-move edge cases cannot bypass him.
- Completing the v0.3.89 Kanto Hall of Fame now drives the same physical result as Yellow's Hall-of-Fame tail: the Cerulean Cave guard disappears and the cave/Mewtwo route opens.
- Kept v0.3.89 League/Hall-of-Fame behavior, v0.3.88 Silph/Saffron liberation, v0.3.87 Bill/S.S. Anne, the v0.3.82 mesh cleanup, and v0.3.78 color separation intact.

# v0.3.89 — Kanto Pokemon League / Hall of Fame parity

- Restored Yellow's complete Elite Four run inside the Kanto excursion. Lorelei, Bruno, Agatha and Lance keep their imported Yellow parties/money/names while Gold's native trainer battle engine owns the fight. Gold Elite/Champion presentation classes are used only for compatible battle art/music/AI.
- Restored the authored room geometry: Lorelei and Bruno swap block `$24 -> $05` at `(2,0)`, Agatha swaps `$3b -> $0e`, and Lance's two entrance blocks swap `$31/$32 -> $72/$73` only after the player has crossed into the room proper.
- Entering Lorelei from Indigo Plateau starts a forward-only League run. Retreat warps back into the previous room are suppressed until a blackout or Hall of Fame completion resets the run, matching Yellow's don't-run-away progression without executing its map ASM.
- Elite Four wins now have run-scoped persistence. A blackout clears the four boss trainer-win rows and physical events so a failed challenge cannot resume halfway through; Hall of Fame completion also resets the run for a clean rematch.
- Restored the Yellow Champion Rival as `OPP_RIVAL3`. Party selection uses Yellow's 1=Jolteon / 2=Flareon / 3=Vaporeon starter enum through a dedicated Kanto key, defaulting safely to party 1 on older saves that never recorded the rival evolution path.
- Champion victory now enters Gold's native `src.core.gen2.HallOfFame` record and `src.ui.gen2.HallOfFame` induction animation. The companion preserves any pre-existing Gold `spawnAfterChampion` byte so this parallel Yellow League cannot hijack an unrelated Gold continue.
- After the Hall of Fame animation the temporary League events reset and the player returns safely to Pallet Town; the Kanto Hall-of-Fame completion bit and Gold Hall-of-Fame history remain permanent.
- Added `KantoLeague.lua` and `kanto_league_hall_of_fame_parity.lua` coverage for exact gate blocks, Elite presentation aliases, forward-only progression, blackout/rematch reset, Champion party selection, Hall-of-Fame bookkeeping and Gold spawn isolation.

# v0.3.88 — Kanto Silph Co / Saffron liberation parity

- Restored Silph Co 11F Jessie/James and Giovanni as Gold-owned Yellow trainer battles, with global Rocket cleanup and Saffron civilian restoration after Giovanni.
- Fixed Giovanni's class reuse so only `VIRIDIAN_GYM` can award Earth Badge; Rocket Hideout and Silph Giovanni remain story bosses.
- Restored the President's one-time retry-safe real Gold MASTER BALL reward.

# v0.3.87 — Kanto Bill / S.S. Anne mainline parity

- Restored Bill's Yellow transformation sequence as persistent Kanto progression: talking to Pokemon-form Bill arms the Cell Separator, the hidden PC completes the transformation, Bill returns to human form, and the S.S. Ticket reward becomes available immediately. Leaving before using the machine resets the abandoned attempt like Yellow.
- Added a dedicated Kanto-local `S_S_TICKET` bit. Gold also has an S.S. Ticket for its own ship content, so the Yellow ticket deliberately does not enter or satisfy Gold's native same-named inventory state.
- Restored Vermilion's S.S. Anne ticket checkpoint at the authored harbor tile. A native Gold ticket alone cannot pass the Yellow guard; the Kanto ticket flashes once and permits entry. After departure the checkpoint reports that the ship has sailed.
- Restored the S.S. Anne 2F rival trigger at Yellow's two authored approach cells. It reveals the hidden rival, runs Yellow's `OPP_RIVAL2` party 1 through Gold's trainer battle engine, persists the win, then removes the rival and delivers the Cut-master hint.
- Restored the seasick Captain progression. Rubbing his back gives Gold's real HM01/CUT through the semantic item bridge, sets the Yellow HM event only after a successful grant, supports retry if the bag cannot accept it, and never duplicates an HM Gold already owns.
- Restored S.S. Anne departure after obtaining HM01 and walking back off the ship: the local ship-left event persists, the lower dock ship blocks become water, the ship entrance is disabled, and the player is returned to Vermilion.
- Added migration/object-state handling for Bill's Pokemon/human forms and the hidden S.S. Anne rival so save upgrades land on the correct visible actors.
- Added `kanto_bill_ssanne_parity.lua` regression coverage for ticket isolation, Bill reset/completion, harbor gate, Rival2 party selection, HM01 reward, and dock departure.
- Preserves v0.3.86 Power Plant/static encounters, v0.3.85 Mansion/Victory Road puzzles, v0.3.84 Rocket/Tower/Flute progression, and v0.3.78 Johto-matched Kanto colors.

# v0.3.86 — Kanto static-encounter / Power Plant parity

- Fixed Power Plant's eight Voltorb/Electrode traps: an object whose authored sprite is `SPRITE_POKE_BALL` now stays a Poke Ball in the overworld even when its payload is a Pokemon. The species/model is revealed only when the player interacts, matching Yellow's trap presentation.
- Static encounters now present the safe imported Yellow text body before the Gold battle when available (`Bzzzt!` for Power Plant traps, legendary cries/text such as Zapdos/Mewtwo), while older caches without that text still start the battle instead of becoming inert.
- Generalized touched-static removal across both `npcCache` and `pokemonCache`, so trap balls and visible legendary models cannot remain underneath the battle screen.
- A blackout now invalidates both presentation caches and rebuilds the authored actor for a retry; win/catch/run continue to consume the one-off object persistently.
- Fixed a raw-object fallback leak: once a static Pokemon is persistently cleared, `objectAt` cannot rediscover the authored map object after its presentation entity is gone.
- Added direct fallback interaction for authored static Pokemon when an older/partial sprite cache cannot build the overworld Pokemon model.
- Added `kanto_static_encounter_parity.lua` regression coverage for disguised Voltorb/Electrode, Yellow reveal text, Gold battle level/species, blackout retry, Mewtwo catch persistence, and cleared-object fallback suppression.
- Preserves v0.3.85 Pokemon Mansion/Victory Road dungeon puzzles, v0.3.84 Rocket/Tower/Flute progression, v0.3.83 item/fossil parity, and v0.3.78 Johto-matched color separation.

# v0.3.82 — Strict private-Kanto building proof

- Fixed the path v0.3.81 missed: false-positive Kanto rectangles could already be claimed by the adaptive building detector before orphan-volume cleanup ran, so their giant pink meshes survived.
- Private Yellow/Kanto adaptive buildings now require the literal Kanto exterior door pair (`0B/0C`). Generic warp/script cells returned by `isDoorTileCell` no longer count as building proof on the foreign adapter.
- Added facade-density validation: a private-Kanto adaptive candidate must contain multiple rows of known facade/window/door vocabulary and enough facade tiles for its width.
- Restored a conservative house-sized inference window for private Kanto (24x20 tiles). Large landmarks must come from explicit building templates instead of self-inferred rectangles; native Gen-2 Kanto retains the wider 40x32 search.
- Fixed the v0.3.81 cleanup bug itself: skipping `buildVolume` did not remove an upright region because `ChunkMesher` falls back to the shape class height when no run exists. Rejected roof-only regions are now explicitly claimed as synthesized local ground (`S.skip` + ground replacement), so there is no upright fallback and no flat magenta roof patch left behind.
- Bumped geometry cache revision to `g2vx-382-r1` so any pink false-positive mesh cached by v0.3.81 is rebuilt.

# v0.3.81 — Kanto pink roof-prism cleanup

- Fixed the remaining screenshot-confirmed giant pink roof blocks in the private Yellow/Kanto excursion. These were roof-only leftover structural regions that escaped the real Kanto building pass and then got turned into generic rectangular prisms by the fallback volume builder.
- Added a conservative orphan-roof filter for foreign `TilesetKanto` maps: a region is skipped by the volume builder when it is dominated by Kanto roof-cap tiles but contains no Kanto facade vocabulary, no Kanto base-course vocabulary, and no literal door pair.
- This leaves those false-positive regions flat instead of standing them up as huge pink blocks, while preserving actual Kanto buildings that still carry their normal frame/door evidence.
- Bumped the geometry cache revision to `g2vx-381-r1` so stale pink prism meshes are rebuilt automatically.

# v0.3.80 — Kanto water-mesh source fix

- Fixed the actual source of the giant green rectangular meshes over Kanto water. The private Yellow map adapter could let a projected/authored tree or structure shape outrank Yellow's cell-level water classification, creating standing solid geometry on Surf cells. Foreign Kanto water cells now resolve to the flat water class before projected solid pins can win.
- Fixed Kanto's 3D off-map apron at water-facing edges. The shared Gen-1 2D renderer normally repeats a global tree-wall border around every OVERWORLD map; in a tilted voxel camera that tree filler becomes the huge green walls seen above coastal/canal water. Kanto water edges now extend with a real water tile/class instead.
- The tree-ring cleanup in `ChunkMesher` now preserves explicitly generated Kanto water apron cells instead of deleting them with unclaimed tree filler.
- Hardened synthetic Gen-2 geometry projection so flat Kanto material categories (`water`, `shore`, `ground`, `grass`) can take Johto colors but can never be promoted into standing donor wall/tree/prop classes.
- Restored the normal reflective water path; v0.3.79's reflection disable was only a diagnostic workaround and was not the cause.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-380-r1` and persistent voxel geometry cache revision to `g2vx-380-r1`, forcing stale pre-fix Kanto water meshes to rebuild.
- Preserves v0.3.78's corrected Johto color separation and native Gold player palette.

# v0.3.79 — Kanto water overdraw / reflection cleanup

- Fixed the screenshot-confirmed Kanto water regression where green shoreline/tree/building voxel geometry could appear above lakes/canals. The problem was in the reflective Kanto water pass, not in the world palette work from v0.3.78.
- Gen-1 excursion maps now force native/plain water rendering (depth-writing animated water, no reflected world copy) so Kanto water cannot pull reflected shoreline geometry up over the surface.
- Johto keeps the existing reflective water renderer; only prefixed `__GEN1__` excursion maps take the defensive plain-water path.
- Preserves the v0.3.78 player/world color separation fix, Johto material ramps, native Gold player palette, Kanto geometry, and existing water/ocean behavior outside the Kanto excursion.

# v0.3.78 — Native Gold player + clean Johto material ramps

- Fixed the screenshot-confirmed layer mix-up: the Kanto excursion player no longer uses Yellow `SPRITE_RED` recolored through the Kanto/map color path. It now reuses the active Gold player's live `SpriteRenderer`, so Chris keeps the exact `PAL_OW_RED` object palette, time-of-day treatment, COLOR-mode treatment, transparency and current bike/player-sheet state that he has in Johto.
- Removed visible use of the v0.3.76/0.3.77 exact shade-population transfer. That transfer created synthetic Bayer/checker texture on paths and noisy speckling on walls by splitting one native shade into several target shades.
- Kanto/native-Gen-2-Kanto texel positions and 2bpp shade indices are authoritative again. The selected material family still comes from the frequency-locked Johto scene (`CHERRYGROVE_CITY` for towns/cities, `ROUTE_29` for routes with cross-scene family supplementation), but each source shade maps directly through that Johto PalMap ramp.
- Preserves the v0.3.77 material-family lock, roof/facade separation, exact Gold day/night/color-mode palette profile, Kanto geometry/collision, and native Gen-2 Kanto geometry donors.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-378-r1` and scene color cache namespace to `color378`, forcing every dithered v0.3.77 projected atlas to rebuild.
- Expanded regressions so a flat Kanto material cannot gain donor histogram checker shades and the default Kanto player must keep the live Gold `SpriteRenderer` identity even when Yellow player-card metadata exists.

# v0.3.77 — Johto material-family lock

- Replaced per-Kanto-tile color authority with one stable Johto material family per semantic category, eliminating the remaining "some good, some bad" drift between neighbouring roofs, facades, paths, foliage, signs, fences and generic structures.
- Material-family selection is weighted by how often a Johto tile is actually placed in the donor map, not by the number of unique tile ids. Rare alternate roof/facade palettes can no longer outvote the colors that visually dominate Cherrygrove or Route 29.
- Every Kanto source tile is categorized before donor matching, closing the fallback leak where uncommon trim/facade tiles could bypass Johto style and land on a generic structure slot.
- Route 29 remains route-terrain authority and Cherrygrove remains town/city authority; missing outdoor families are filled from the other canonical Johto scene (then New Bark) without overriding the primary scene.
- Kanto/native-Kanto texture positions remain intact; Johto supplies palette family and representative shade population only. No Johto tile pixels are pasted onto Kanto.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-377-r1` and the scene-color cache key to `color377`, forcing all older projected material atlases to rebuild.
- Added frequency-lock, supplement-merge and per-tile-conflict regressions; all 33 bundled Kanto/mobile test files pass.

# v0.3.76 — Exact Johto shade-population parity

- Fixed the remaining yellow-heavy Kanto surfaces that v0.3.75 could not remove. The old four-entry shade map moved every pixel of a Kanto shade together; a wall that was 80% one pale shade therefore stayed 80% one pale Johto color even when the matched Johto wall used several shades.
- Added a deterministic per-tile 64-pixel shade transfer. The matched Johto tile contributes its exact counts of shades 1/2/3/4; Kanto/native-Kanto pixels are ordered by their original luminance and split across those target counts.
- Equal-shade ties use a fixed 8x8 Bayer rank, so the transfer is stable and distributed instead of producing row bands or frame-random noise. The donor's spatial brick/stripe/roof pixels are still never copied.
- Exact scene-used PalMap slot selection, Cherrygrove town donor, Route 29 route donor, roof/facade role restriction, Kanto geometry/collision, day/night and Gold color-mode behavior are retained.
- Added a regression proving a completely flat Kanto shade can become the donor's exact 16/16/16/16 four-shade population, which was impossible in v0.3.75, while the existing anti-v0.3.74 spatial-pattern test still passes.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-376-r1` so every older approximate color projection is rebuilt.

# v0.3.75 — Johto shade-balance parity without donor texture projection

- Fixed the screenshot-confirmed v0.3.74 regression where exact Johto donor tile pixels were pasted across unrelated Kanto surfaces, producing huge pink stripes/bands on buildings and terrain.
- Kanto/native-Kanto surface texture layout is authoritative again; Johto is COLOR authority only.
- Retained scene-aware donors (`CHERRYGROVE_CITY` for Kanto towns/cities, `ROUTE_29` for Kanto routes), exact scene-used PalMap slots, roof/facade role separation, and multi-slot Johto material identity.
- Added per-tile four-shade histogram matching: Kanto's 2bpp light/mid/dark indices are quantile-matched to the selected Johto donor material, preserving spatial detail while matching Johto contrast balance.
- Added a regression that gives Kanto a left/right shade pattern and Johto a top/bottom pattern; the result must stay left/right, proving donor texels are never pasted.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-375-r1` so every v0.3.74 projected material is rebuilt.

# v0.3.73 — Screenshot-driven Johto city material parity

- Fixed the mismatch visible in the supplied side-by-side screenshots: Johto uses a bright magenta/pink civic roof family with stronger foliage/material contrast, while Kanto v0.3.72 could still choose muted brown/olive slots from unused tiles elsewhere in `TILESET_JOHTO`.
- Outdoor Kanto towns/cities now prefer `CHERRYGROVE_CITY` as the Johto color scene; Kanto routes prefer `ROUTE_29`, with New Bark retained only as a fallback. Geometry donors remain unchanged.
- Color-slot selection is now constrained by the tiles the selected Johto donor MAP actually uses instead of searching the entire Johto tileset indiscriminately.
- Added building-template color roles: roof courses and facade courses are distinguished even though both are collision-class `structure`. Kanto roofs therefore inherit the donor town's actual Johto roof palette slot, while facades inherit its facade slot.
- Generic ground/grass/water/tree/fence/sign material behavior remains day/night and display-mode synchronized with Gold; only color-role authority changed.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-373-r1` so v0.3.72 projected material caches cannot preserve the old brown/olive choices.
- Expanded `tests/kanto_johto_voxel_color_parity.lua` with city-vs-route donor selection, used-map tile filtering, roof/facade role separation and projection-revision checks.

# v0.3.72 — Kanto voxel colors match Johto material authority

- Split Kanto's Gen-2 presentation donor into independent GEOMETRY and COLOR donors. Native Gen-2 Kanto can still supply shapes/textures where it best matches the Yellow-authored map, while outdoor color authority now comes from `TILESET_JOHTO` with `NEW_BARK_TOWN` preferred.
- Kanto terrain, grass, water, doors/warps and structures now select PalMap slots from the nearest same-material Johto donor tile instead of reusing the geometry donor's Kanto palette slot.
- Matched geometry keeps the donor's 2bpp shade pattern but recolors that shade through the Johto slot/ramp, so voxel material contrast and day/night/color-mode changes follow Johto without replacing Kanto landmarks or collision/layout data.
- Unmatched/unique Kanto art still falls back to Johto semantic ground/water/grass/door/structure slots, preserving recognizable Kanto silhouettes rather than forcing arbitrary Johto textures.
- Bumped `KantoGen2Style.PROJECTION_REV` to `g2-johto-colors-372-r1`, forcing persistent voxel/material cache misses for older projections so pre-v0.3.72 colors cannot leak into upgraded sessions.
- Added runtime diagnostics for separate Kanto geometry and color donors and `tests/kanto_johto_voxel_color_parity.lua`, including a pure check that Pallet geometry can remain Kanto while its visible palette slot is sourced from Johto.
- Gen1Recomp `dev` remains `9713977755fb87f3a7cc336d5a841cf3f3b15e31` (2026-08-19); no host API rebase was required.

# v0.3.71 — Kanto scripted-reward / Gold state parity

- Promoted the next batch of classic Kanto reward interactions out of the detached dialogue sandbox so they mutate the active Gold save without enabling Red/Yellow story ASM.
- Celadon Mansion now gives the authored level-25 EEVEE as a Gen-2 gift (happiness 120, player OT/ID, real party/current-box storage and Gold Pokedex ownership) and persistently hides the claimed ball.
- Silph Co. 7F now gives one level-15 LAPRAS with storage-full retry safety; Fighting Dojo now previews HITMONLEE/HITMONCHAN as seen after the Karate Master, gives exactly one level-30 choice, hides only the selected ball and preserves the other ball's greedy refusal.
- Mt. Moon's salesman now performs the authored ¥500 level-5 MAGIKARP sale. Decline, insufficient money and full storage never charge or consume completion; money moves only after Gold accepts the Pokemon.
- Oak's aides now use the exact 10/30/50 caught thresholds and award safe Gold equivalents: HM05 FLASH, ITEMFINDER, and EXP.SHARE as the semantic Gen-2 successor to EXP.ALL. Mixed `caught`/legacy `owned` Pokedex tables count as a union.
- Mr. Psychic gives Gold's TM29 PSYCHIC once; the Route 16 hidden-house girl gives Gold's HM02 FLY once. Item events are written only after the real Gold Bag accepts the reward.
- Celadon rooftop vending machines now sell FRESH WATER ¥200, SODA POP ¥300 and LEMONADE ¥350 against Gold money/Bag state, adding the drink before deducting money so a full PACK cannot charge the player.
- Deliberately does not reinterpret Gen-1-only TM numbering: Copycat's TM31 MIMIC and the thirsty girl's TM13/TM48/TM49 exchanges remain sandboxed until they can be translated by move semantics without silently giving the wrong Gen-2 TM.
- Added `lib/KantoRewards.lua` and `tests/kanto_scripted_rewards_parity.lua`; all 29 Kanto regression files plus Android Gold sizing/worldOverride and iOS orientation regressions pass.
- Compatibility remains on Gen1Recomp `dev` 9713977755fb87f3a7cc336d5a841cf3f3b15e31 (2026-08-19); upstream did not move from the v0.3.70 checkpoint.

# v0.3.70 — Kanto Yellow starter-gift / Gold ownership parity

- Promoted Yellow's three Kanto starter sidequests out of the detached dialogue-only sandbox into dedicated Gold-owned gameplay services.
- Cerulean Melanie now follows the authored Pikachu-specific friendship gate: below 147 happiness she only gives the intro; at 147+ she offers one level-10 BULBASAUR. A compatibility `save.pikachuHappiness` bridge is honored when present; normal Gold reads actual party PIKACHU happiness and never substitutes another lead.
- Route 24 Damian now offers one level-10 CHARMANDER with the original decline/retry and after-gift branches.
- Vermilion Officer Jenny now requires Gold's actually earned Kanto THUNDER badge before offering one level-10 SQUIRTLE, preserving decline/retry and after-gift behavior.
- All three gifts are created as Gen-2 gift Pokemon with happiness 120, stamped with the Gold player's OT/ID, stored through the real party/current-box path, and marked seen/caught in Gold's Pokedex.
- Completion is atomic: party+current-box full, build failure, or store failure leaves the Kanto event clear so the player can retry and can never lose a one-time starter.
- Melanie's separate BULBASAUR object hides immediately on success and map-entry migration repairs stale visible objects on upgraded saves that already hold the completion event.
- `storeGoldMon` now uses Gen1Recomp's current `Mon.stampOT` for non-traded Kanto catches/prizes/gifts when available, while traded Pokemon keep their foreign OT.
- Added `lib/KantoStarterGifts.lua` and `tests/kanto_yellow_starter_gifts_parity.lua`; Bike Voucher, civic, NPC-dialogue, dynamic-interior and poster/badge regressions remain green.
- Checked against current Gen1Recomp `dev` 9713977755fb87f3a7cc336d5a841cf3f3b15e31 (2026-08-19), 18 commits beyond the previous v0.3.69 checkpoint. No Yellow story/cutscene VM is enabled.

# v0.3.69 — Kanto Bike Voucher / Bicycle service parity

- Promoted `POKEMON_FAN_CLUB` chairman interaction out of the dialogue-only sandbox into a story-free gameplay service backed by Gold inventory.
- Restored the original chairman YES/NO branch: NO gives nothing and leaves the service retryable; YES tells the story, gives exactly one BIKE VOUCHER, then explains it.
- Gold key-item-pocket refusal is authoritative. On normal Gen-2 hosts, BIKE_VOUCHER is represented as Kanto-local held service state (because Gold has no native voucher item) but still checks the real KEY_ITEM pocket capacity; compatible hosts that define BIKE_VOUCHER use the real Bag item. A full pocket does not set completion.
- Promoted `BIKE_SHOP` clerk interaction into a real service. Existing BICYCLE ownership uses the post-sale line; a BIKE VOUCHER is exchanged atomically by adding BICYCLE first and consuming the voucher only after success.
- Preserved the no-voucher retail path as the authored impossible ¥1,000,000 BICYCLE/CANCEL menu; browsing cannot spend Gold money or sell a bike.
- Existing physical BIKE_VOUCHER/BICYCLE ownership backfills only Kanto-local completion bits, preventing duplicate cross-region rewards without writing Yellow story flags into Gold.
- Added `kanto_bike_voucher_parity.lua` covering decline/retry, bag-full, successful gift/exchange, atomic voucher spending, migration, impossible sale/cancel behavior and dispatcher ownership.
- Kept v0.3.68 Saffron/Museum physical parity, v0.3.67 iPhone orientation correction and all previous Kanto rendering/movement/performance contracts unchanged.

# v0.3.68 — Kanto Saffron / Pewter Museum physical-service parity

- Restores all four Yellow Saffron gate-house trigger arrays: Route 5 `(3,3)/(4,3)`, Route 6 `(3,2)/(4,2)`, Route 7 `(3,3)/(3,4)`, and Route 8 `(2,3)/(2,4)`.
- Without access, the guard consumes the first Gold-owned drink in retail order `FRESH_WATER`, `SODA_POP`, `LEMONADE`; one drink opens the shared Saffron event for all four gates.
- If no drink exists, the authored road-closed interaction consumes the landing and queues one-cell pushback on the correct horizontal/vertical axis. Direct guard talk uses the same inventory/event authority.
- Restores Pewter Museum's ¥50 rope gate on `(9,4)/(10,4)`: decline/insufficient funds push south, successful admission deducts exactly ¥50 from Gold and persists a Kanto-local ticket event.
- Restores the Museum scientist's one-time OLD AMBER gift using Gold's real Bag API; bag-full refusal does not set completion. Success hides the `MUSEUM1F_OLD_AMBER` display and invalidates live/spatial actor caches immediately.
- Adds map-entry migration so an already-completed Old Amber event hides a stale display after upgrading without running Yellow ASM.
- Added `lib/KantoCivic.lua` plus `tests/kanto_civic_access_parity.lua`.
- No Yellow story/cutscene VM, rendering-quality setting, Kanto geometry/collision rule, Character Selector path, Android framing, iOS orientation correction, or battle renderer changed.

# v0.3.67 — iPhone landscape orientation correction

- Extends the existing whole-frame mobile presentation wrapper to iOS while leaving desktop untouched and preserving Android's historical manual `screenFlip` option.
- Uses LÖVE's live `love.window.getDisplayOrientation()` signal and auto-corrects only `landscapeflipped`; normal `landscape` is never rotated.
- Rotates the complete Game2 frame 180 degrees after world, HUD, menus, battle UI, overlays and touch controls are composed, so Kanto/Johto presentation stays coherent.
- Applies the inverse 180-degree transform to iOS touch points and deltas, keeping virtual buttons, menus and camera gestures aligned with the corrected picture.
- Adds enabled-by-default `IPHONE ORIENTATION FIX`; disabling it restores fully native iOS orientation handling for devices/builds that do not need the workaround.
- Validates stable option/orientation callbacks once per identity and leaves `pcall` afterward, avoiding new protected-call overhead on steady mobile frames.
- Added `tests/ios_orientation_flip_parity.lua`; Android logical-canvas/worldOverride contracts remain unchanged.
- No voxel resolution, draw distance, terrain, actors, water, shadows, collision/warp semantics, Character Selector behavior, battle renderer or assets changed.

# v0.3.66 — Kanto steady-frame proxy / neighbor no-lag hot paths

- Caches the connected-neighbor `urgent` / directional `prefetch` result by exact completed player cell plus world-travel vector, so idle and steady-direction presentation frames skip the whole neighbor-dynamic loop.
- Precomputes each second-ring root-to-neighbor unit vector when the connected descriptor is built; directional prefetch no longer normalizes immutable map geometry every frame, with a one-time fallback for hot-reloaded legacy descriptors.
- Keeps the existing v0.3.65 descriptor/direct-neighbor identities and invalidates the dynamic key automatically whenever root map, Kanto radius or sector-record identity changes.
- Caches the visible Kanto player proxy sprite/card by map, Bicycle state, Gold palette key, custom-skin ownership and source SpriteRenderer identity instead of re-entering Yellow sprite/palette lookup every presentation frame.
- Validates the optional custom-player `active()` callback once per picker/function identity and calls it directly on later frames; function replacement automatically re-arms protected validation.
- Reuses the already-computed dark-map answer inside `excursionState` rather than querying the immutable field index twice in the same frame.
- Added `tests/kanto_steady_proxy_neighbor_hotpath_parity.lua`.
- No voxel resolution, draw distance, terrain, actors, water, shadows, collision/warp semantics, Character Selector animation/state ownership, Android sizing, battle renderer or assets changed.

# v0.3.65 — Kanto connected-neighbor / bridge no-lag hot paths

- Keeps the current Kanto connected-sector neighbor descriptor array intact while `(root map, Kanto radius, sector-record identity)` is unchanged instead of clearing/scrubbing/refilling every presentation frame.
- Keeps the direct-neighbor array intact with the same cache key, so Gold third-person collision and bridge handoff reuse the exact same table identity across steady frames.
- Only `urgent` and directional `prefetch` are refreshed per frame; map refs, offsets, depth, parent and direction are rebuilt only when the root/radius/region actually changes.
- Actor-view invalidation is deliberately independent, so moving/despawning NPCs do not force terrain-neighborhood descriptor rebuilds.
- GoldVoxelBridge validates the bundled `TwinRegionWorld.excursionState` helper once per function identity and calls it directly on later Kanto frames; replacing the helper automatically re-arms one protected validation.
- Added `tests/kanto_neighbor_bridge_hotpath_parity.lua`.
- No voxel resolution, draw distance, terrain, actors, water, shadows, collision/warp semantics, Character Selector, Android sizing, battle renderer or assets changed.

# v0.3.64 — Kanto idle-tick / trainer hot-path no-lag caching

- Idle Kanto frames now advance the NPC wander clock before resolving the current map/NPC list; if no actor is moving and the 0.70s wander decision is not due, the frame touches no map/entity tables.
- Active NPC interpolation reads the already-maintained tiny mover list directly from `KantoSpatial.peekRoles`; completing a move removes it from that list without rebuilding the authoritative NPC list.
- Gold overlay-stack ownership is defensively validated once per stack/method identity and then uses a direct `stack:top()` call instead of a protected call every rendered Kanto frame.
- Love RNG ownership for classic step encounters is likewise validated once per function identity and then called directly for rate/slot rolls.
- Trainer persistent win IDs and immutable trainer headers are cached on their imported object records instead of rebuilding strings/resolving headers on repeated Kanto landings.
- Trainer sight now performs the cheap facing/alignment test before touching trainer persistence/header data, so unrelated trainers on busy routes generate no trainer-ID/header work.
- Added `tests/kanto_idle_tick_hotpath_parity.lua` and `KantoSpatial.peekRoles`.
- No graphics-quality, draw-distance, actor-visibility, collision/warp, Character Selector, Android-size, battle-renderer or asset changes.

# v0.3.63 — Kanto position-checkpoint no-lag hot path

- Reuses one Kanto position snapshot and one nested LAST_MAP snapshot instead of allocating a new table and deep-copying LAST_MAP on every crossed cell.
- Ordinary travel checkpoints are coalesced in eight-cell batches, removing seven out of eight mod-save bridge calls during uninterrupted movement while keeping the in-process snapshot current every cell.
- Menus/overlays flush any pending position once, and existing explicit transitions (warps, Fly, Surf/Bicycle changes, dungeon falls, relocation and RETURN TO JOHTO) remain immediate durable checkpoints.
- Grid and continuous-body outdoor route seams force an exact checkpoint at the destination before ordinary landing work continues.
- Unchanged forced checkpoints are no-ops, so opening/holding an overlay cannot repeatedly rewrite the same save-slot position.
- Added `tests/kanto_position_checkpoint_parity.lua`.
- No graphics-quality, draw-distance, actor-visibility, collision/warp, Character Selector, Android-size, battle-renderer or asset changes.

# v0.3.62 — Kanto completed-step / warp no-lag hot paths

- Ordinary Kanto cell landings now check the map's O(1) warp index once and completely skip `resolveWarp`, pad/hole tile reads and ExtraWarpCheck work when no authored warp occupies that cell.
- Warp bounce suppression uses scalar `(map, x, y)` excursion fields instead of allocating/comparing `"map:x:y"` strings on normal runtime paths; the legacy string field remains compatible for older tests/integrations.
- Classic step-encounter enablement is cached for steady gameplay and invalidated while menus/overlays are open, so setting changes are picked up on resume without a mod-options bridge call on every landing.
- `ForeignGen1Map:isPassableCell` now reads one cached collision tile and checks walkable/water membership directly, eliminating duplicate Surf-path tile work.
- Removed a duplicate `sourceMapId` assignment in step finalization.
- Added `tests/kanto_step_landing_hotpath_parity.lua`.
- No graphics-quality, draw-distance, actor-visibility, warp/collision-rule, Android-size, Character Selector, battle-renderer or asset changes.

# v0.3.61 — Kanto collision/step no-lag hot paths

- Added an in-bounds collision-cell tile cache to `ForeignGen1Map`; repeated collision/water/grass/warp/elevation queries now reuse decoded tile ids.
- `setBlock` invalidates exactly the four collision cells covered by the changed Gen-1 block, so live Cut/door/poster/trash-puzzle restamps remain correct without flushing the whole map cache.
- Trusted Kanto `passable` and tile-pair/elevation checks now call the private map adapter directly instead of paying protected-call overhead on continuous movement.
- Timer and Gold input callback identities are validated once and then use direct calls until the runtime object/function changes.
- `fieldIndex` now pre-indexes Yellow ledge rules and ExtraWarpCheck warp-carpet metadata for O(1) held-collision checks.
- Added `tests/kanto_collision_hotpath_cache_parity.lua`.
- No graphics-quality, draw-distance, actor-visibility, collision-rule, Android-size, Character Selector, battle-renderer or asset changes.

# v0.3.60 — Kanto actor/AI no-lag caching

- Cached immutable per-map NPC role lists for trainers and wanderers instead of filtering the complete NPC list on repeated trainer-sight/AI checks.
- Maintains a tiny active-mover list so render-rate NPC interpolation visits only NPCs that are currently moving.
- Added actor-generation invalidation and a cell/radius keyed actor-view cache; steady movement within one cell reuses the same Kanto current/neighbor candidate arrays while any actor movement/despawn/list change invalidates immediately.
- Neighbor actor candidate caching uses a one-cell safety margin; VoxelScene remains the final camera-space cull, so actor draw distance/visibility quality is unchanged.
- Reuses TwinRegionWorld's direct-neighbor array in GoldVoxelBridge instead of allocating/refiltering a second table every Kanto frame.
- Reuses one overlay-covered result and one FirstPerson method snapshot per Kanto tick rather than repeating protected lookups.
- Scrubs unused Kanto frame/voxel pool tails when counts shrink, preserving table reuse without retaining actors/maps/meshes from the previous route.
- Added direct-neighbor handoff, actor-role/generation, actor-view and pooled-reference regressions; all prior Kanto and Android contracts remain green.

# v0.3.59 — Kanto movement-time no-lag / prefetch + palette hot paths

- **No visual-quality reductions:** keeps the v0.3.58 voxel geometry, draw distance, connected-world terrain, actors/models, water, shadows, grass/flowers and Character Selector animation.
- **Reusable voxel prefetch state:** Kanto reuses the live map set, neighbor visibility flags, neighbor terrain/water readiness and detail-ready arrays instead of allocating those containers every visible frame.
- **Shared-body dead-work removal:** Kanto's BODY-only stitched world no longer constructs `openWorldFullMasks` placement/mask graphs that are only meaningful to FULL/apron meshes.
- **One culling setup per frame:** `VoxelScene._prepareCullView` resolves Quality world/detail/actor padding once and caches the expanded view bounds; every neighbor/actor check reads those values directly instead of repeatedly calling Quality through `pcall`.
- **One neighbor visibility test per frame:** residency and mesh-request passes share the same visibility result rather than repeating identical camera/bounds math.
- **Stable residency ownership:** `ChunkMesher.setLive` copies membership into two reusable internal sets. Reusing/wiping Kanto's caller live dictionary cannot mutate previous-neighborhood history or cause premature route eviction.
- **Cheap Gold palette polling:** `GoldColorAtlas.worldPaletteInputs` exposes daytime, color mode, palette-set identity and PalMap identity without scanning the PalMap. `TwinRegionWorld.syncGoldPalette` now runs the full multi-pass `worldPaletteProfile` only when one of those cheap inputs changes, removing the old periodic PalMap/key-serialization spike.
- **Smaller movement hot paths:** Kanto actor spatial cells use packed numeric keys instead of `"x:y"` strings, and connected-sector cache lookups use nested `sourceId -> radius` keys instead of constructing `"map|radius"` every frame.
- **Hard unload preserved:** `KantoFrameCache.release` now also clears the new live/prefetch/terrain readiness scratch so RETURN TO JOHTO cannot pin Kanto meshes. `VoxelScene` uses a scalar global sentinel rather than retaining the scratch table.
- Added regressions: `kanto_voxel_prefetch_low_gc_parity.lua`, `kanto_live_residency_snapshot_parity.lua`, `kanto_palette_poll_parity.lua`; expanded frame/voxel scratch tests.

# v0.3.58 — Kanto no-lag frame pacing / low-GC performance

- **No visual-quality cuts:** this pass keeps the same voxel terrain, actor/model detail, draw distance, water, shadows, flowers/grass, Character Selector animation and Kanto gameplay rules. The improvement comes from eliminating redundant CPU work and allocation churn.
- **Reusable Kanto render frame:** `lib/KantoFrameCache.lua` owns reusable render-state, neighbor, entity, ghost, ocean and voxel-scratch buffers. Steady Kanto frames no longer rebuild those short-lived Lua table graphs every draw, reducing garbage-collector pressure and frame spikes.
- **Pooled actor/water pose records:** `VoxelScene` reuses Kanto actor pose rows, water draw rows, cull/context records and atlas lookup scratch. Neighbor translation matrices are cached on stable neighbor records rather than recreated repeatedly across terrain/water/grass/flower/shadow passes.
- **Visible-only cache preparation:** while Kanto gameplay is visible, disk-cache warming may only touch the current map and already-prepared connected neighbors. It no longer prepares/colorizes arbitrary far-away Yellow maps on an active gameplay frame. Whole-region cooking remains available while a menu/covering overlay is up.
- **Current-sector-first meshing:** when the current Kanto body is missing, it retains the normal urgent mesh budget. Once current terrain is drawable, neighbor/prefetch mesh work receives short cooperative Kanto-visible slices, preventing background terrain preparation from consuming a large part of a frame.
- **Idle frames are protected too:** cache-only warmers now receive the visible-gameplay throttle on every Kanto frame, not only while the player is moving. Standing still can no longer invite a several-millisecond background-cache burst.
- **Zero-allocation forced-bike hot check:** the per-frame `map:x:y` key construction is replaced by scalar map/x/y tracking.
- **Hard residency boundary preserved:** RETURN TO JOHTO releases all reusable Kanto frame references before region/GPU unload, so the low-GC cache cannot pin Yellow maps, actors, textures or matrices in memory.
- **Diagnostics:** `Twin.status()` and GoldVoxelBridge expose frame-cache reuse/ocean-cache counters plus visible cache/mesh throttling counts.
- **Regressions:** added `kanto_render_frame_cache_parity.lua`, `kanto_voxel_frame_scratch_parity.lua`, `kanto_mesh_pacing_parity.lua` and `kanto_cache_warm_visibility_parity.lua`.
- Retains v0.3.57 Tower purified-zone parity, v0.3.56 third-person state isolation, v0.3.55 Kanto player animation and every earlier collision/warp/elevation/Cycling Road/Seafoam rule.

# v0.3.57 — Kanto Pokemon Tower purified-zone parity

- **Pokemon Tower 5F purified pad restored:** the authored 2x2 zone at `(10,8)`, `(11,8)`, `(10,9)`, `(11,9)` now works in KANTO FREE ROAM.
- **Gold party authority:** entering the zone heals the real Gold party once per entry; the normal `world:healParty()` path is preferred, so HP, status and PP stay owned by Gen 2 rather than a copied Yellow party.
- **Encounter suppression:** every completed landing while inside the purified zone is consumed before roaming/classic step encounters, mirroring Yellow's `BIT_NO_BATTLES`. Stepping off clears the visit-local latch and re-entering heals again.
- **Story-free presentation:** the heal keeps Yellow's white palette sequence—24-frame fade out, `Delay3` twice, 24-frame fade in—then displays `_PokemonTower5FPurifiedZoneText` from the imported cache with a ROM-free fallback.
- **Cross-region resume:** RETURN TO JOHTO clears the temporary Tower latch; resuming Kanto directly on the pad is treated as a fresh visit and activates the heal/no-battle rule immediately.
- **Older-host healing improved:** the compatibility fallback now prefers Gen1Recomp's canonical `Pokemon.heal`, restoring move PP (including PP Up bonuses) as well as HP/status.
- **Diagnostics:** `Twin.status()` exposes Tower purified heals, occupied-pad steps, active latch and entry count.
- **Regression:** added `tests/kanto_tower_purified_zone_parity.lua`, covering exact coordinates, latch semantics, real Gold heal call, encounter-blocking return behavior, white-fade timing and extracted text.
- Retains v0.3.56 third-person state isolation, v0.3.55 skeletal animation, v0.3.54 dialogue/spatial indexing, v0.3.52 Game Corner geometry, v0.3.51 elevation/Bicycle and v0.3.48 Android logical framing.

# v0.3.56 — Kanto third-person transition/state isolation

- **Visible Kanto special-card ownership:** Kanto Character Selector eligibility now reads the presentation-local Kanto proxy instead of the still-resident Johto `playerState`. Hidden Johto Surf/Bike/Fishing can no longer make the Kanto 3D trainer disappear, and Kanto Bicycle/Surf correctly hands rendering back to the authored special card instead of layering the humanoid mesh over it.
- **Hidden fishing leak closed:** the Kanto proxy explicitly pins `fishing=false` so its `__index` fallback cannot inherit a Johto fishing pose from the real Gold player.
- **Independent third-person travel yaw:** Character Selector's retained `red3dFreeBodyYaw`, `red3dLastWorldX/Z` and projected yaw are mirrored into Kanto-local proxy state for Kanto render calls, then the original Johto fields are restored. Hidden Johto rendering between Kanto shadow/main passes can no longer contaminate the Kanto body's orientation.
- **Cross-region yaw rebase:** the first Kanto model frame seeds its previous-world sample at the current Kanto position, preventing the Johto-to-Kanto coordinate discontinuity from being interpreted as a giant movement vector.
- **Idle interaction/warp facing:** a real Kanto facing change while stationary updates the retained 3D body yaw and rebases the travel sample. Camera orbit alone leaves Kanto facing unchanged, so the model still retains travel-facing normally.
- **Special-state draw isolation:** render-only Surf/Bike/Fishing fields are mirrored to Character Selector during Kanto preparation/draw and restored immediately afterward, just like v0.3.55 movement/jump fields.
- **Regression:** added `tests/kanto_third_person_transition_parity.lua` covering hidden-Johto special-state rejection, Kanto Bicycle/Surf/Fishing handoff, yaw/sample isolation across intervening Johto draws, first-frame rebasing, idle turn-in-place and exact Gold-field restoration.
- Retains v0.3.55 Kanto skeletal-frame animation ownership, v0.3.54 dialogue/spatial indexing, v0.3.53 dialogue coverage, v0.3.52 Game Corner geometry, v0.3.51 elevation/Bicycle, v0.3.50 optimization and v0.3.48 Android logical framing.

# v0.3.55 — Kanto third-person player animation cache fix

- **Character Selector voxel-frame ownership fixed in Kanto:** current Character Selector prepares its skeleton in `Renderer:beginVoxelFrame()` and `drawVoxel()` / `drawVoxelShadow()` consume the cached `voxelFrameKey`. Kanto manually delegated the draw but did not refresh that cache, so the visible Kanto body could move while reusing the hidden Johto player's idle skeleton.
- **Kanto proxy now prepares the model animation frame:** immediately before Kanto shadow/main model rendering, the bridge refreshes Character Selector's cached voxel animation using the visible Kanto presentation proxy while retaining the real Gold player object identity needed for selected skins/accessories.
- **Walk/run blend parity:** Kanto's live movement vector is mirrored render-only into `red3dMoveStickX/Y` + `red3dAnalogMoveActive`, allowing imported rigs that use Character Selector's analogue magnitude to choose and blend their authored walk/run clips correctly.
- **Ledge/jump animation parity:** Kanto hop/jump state is mirrored render-only for the selector frame so compatible character rigs can play their authored jump pose while the Kanto world still owns physical movement/lift.
- **Same-frame cache protection:** shadow/reflection/main passes reuse one prepared Kanto frame, but if another selector/Johto pass overwrites `voxelFrameKey` during that scene frame the Kanto bridge detects the foreign key and reclaims the correct pose before drawing.
- **Legacy Character Selector fallback:** older selector builds without `beginVoxelFrame()` have stale voxel-frame/upload keys invalidated so their position-aware `animationState()` path can animate from Kanto movement instead of a frozen Johto cache.
- **Render-only isolation:** every Gold player field temporarily exposed to the selector is restored immediately after frame preparation/draw. Johto Character Selector animation remains owned by its native pipeline.
- **Regression:** added `tests/kanto_third_person_player_animation_parity.lua` covering moving/facing/progress/target/analogue/jump mirroring, gameplay-state restoration, same-frame reuse, foreign-cache overwrite recovery, legacy fallback and Johto non-interference.
- Retains v0.3.54 dialogue-audio/actor-spatial fixes, v0.3.53 comprehensive dialogue, v0.3.52 Game Corner geometry, v0.3.51 elevation/Bicycle, v0.3.50 optimization and v0.3.48 Android logical framing.

# v0.3.54 — Kanto dialogue presentation + actor spatial indexing

- **Authentic pet-NPC cry timing:** `play_cry` is now a permitted dialogue-control command inside the detached Yellow sandbox. Its pending cry is carried into the real Kanto TextBox through a sanitized `auto.sound/delay/wait` presentation contract, restoring cases such as Pewter Nidoran / Viridian Spearow without exposing Gold story state.
- **Sandbox boundary stays narrow:** only safe TextBox audio presentation crosses out. Arbitrary `auto.tick`/`auto.onOverlap`, battles, warps, screens, scripted movement and real save/world mutation remain suppressed.
- **Per-cell NPC index:** Kanto NPC collision/interaction lookup now uses per-map cell buckets instead of scanning the entire cached NPC list on each query.
- **Per-cell Pokémon index:** roaming/static Pokémon occupancy and interaction lookup uses the same direct cell strategy.
- **Live index maintenance:** wandering NPC movement, trainer sight approaches, Strength boulder pushes, Seafoam boulder drops, roaming Pokémon battle removal, static-Pokémon restore, item pickup and Game Corner guard disappearance all update or invalidate the correct index immediately.
- **Duplicate-cell correctness:** buckets retain multiple actors and preserve `except` handling, so an ignored mover cannot hide a second blocker sharing its cell.
- **Diagnostics:** `Twin.status()` exposes NPC/Pokémon spatial index builds/hits/moves plus dialogue presentation-audio count.
- **Regression:** expanded `tests/kanto_npc_dialogue_parity.lua` for `play_cry` TextBox timing and added `tests/kanto_actor_spatial_parity.lua` for build/reuse, move, remove, duplicate/except and invalidation semantics.
- Retains v0.3.53 comprehensive NPC/sign dialogue, v0.3.52 Game Corner physical entrance, v0.3.51 elevation/Bicycle parity, v0.3.50 optimization, v0.3.49 interiors and v0.3.48 Android logical framing.

# v0.3.53 — Complete Kanto NPC dialogue bridge

- **`text_asm` NPCs no longer go mute:** v0.3.52 deliberately rejected every generated pointer carrying `asm=true`. v0.3.53 resolves the engine's hand-ported map talk handler and presents its dialogue instead.
- **Detached Yellow dialogue sandbox:** the handler receives a cloned Gold save plus a fake Kanto overworld; `GameVersion` is temporarily Yellow. TextBox, YES/NO and ListMenu presentation is replayed through the real Kanto UI, while the real Gold save/world never enters the handler.
- **Story/cutscene safety remains:** battle/warp/teleport/blackout/Hall-of-Fame commands halt the sandbox; other unsafe commands, custom screens/states, scripted movement and audio side effects are suppressed. Save flag writes are allowed only on the detached clone so branching within one conversation remains coherent.
- **Yellow-specific talk overrides:** Yellow Oaks Lab and Yellow-only gifts/Jessie-James/beach/old-man modules are explicitly available even though the owning game is Gold/Silver; shared map scripts continue through the current engine registry.
- **Incomplete-cache recovery:** a visible NPC/sign whose `text_pointers` row is absent gets a direct engine registry lookup and extracted-label fallback. The final non-muting fallback is `...`, so pressing A on a text-bearing object never silently fails.
- **Existing safe gameplay handlers keep precedence:** trainers, items, marts, Centers, PCs, Cable Club notice, Safari, Game Corner, rods, trades, CARD KEY, Cut/Strength and other Kanto-owned interactions are unchanged.
- **Dialogue audit/diagnostics:** region build records counts for NPC/sign text, plain lines, scripted lines, services and missing pointers; runtime counters expose sandbox sessions, handled/recovered interactions, suppressed commands/states, fallbacks and errors.
- **Regression:** added `tests/kanto_npc_dialogue_parity.lua`, covering function handlers, row scripts, chained boxes, YES/NO, Yellow-only override priority, detached save state, battle-like state suppression, extracted fallback, missing-handler fallback and audit accounting.
- Retains v0.3.52 Game Corner physical entrance, v0.3.51 elevation/Bicycle parity, v0.3.50 optimization, v0.3.49 interiors, v0.3.48 Android logical framing, v0.3.46 ledges/route edges and v0.3.45 warps.

# v0.3.52 — Kanto Game Corner entrance + indexed spinner/badge rules

- **Celadon Game Corner Rocket entrance restored:** the story-free Kanto runtime now consumes extracted `field.gameCornerPoster`. Before discovery, block `(8,2)` is physically closed as `$2a`; using the authored poster interaction sets `EVENT_FOUND_ROCKET_HIDEOUT`, plays the switch/open cues when the host exposes them, and swaps the live block to `$43` with one voxel refresh. Re-entry/restamp reads the persisted event so collision and rendering agree.
- **Poster guard no longer becomes a permanent blocker:** defeating the Game Corner Rocket persists a Kanto-local hidden-object state so the poster can be reached. Existing v0.3.51 saves migrate a prior `yellowTrainerWinsV1` win into that hidden state on Game Corner entry; no Yellow exit/cutscene VM is enabled.
- **Indexed spinner arrows:** immutable `field.spinners` coordinates are compiled into the region field index. Viridian Gym and Rocket Hideout spinner landing checks use direct cell lookup, preserve authored forced-move lists, and play the Arrow Tiles cue when available.
- **Indexed badge gates:** Route 22 exact checkpoint cells and Route 23 northbound guard rows are compiled into direct lookups, preserving badge/fail-text/max-X semantics while removing repeated per-step scans of extracted guard arrays.
- **Geometry refresh stays coalesced:** the poster entrance uses the same centralized block-refresh path as v0.3.49-v0.3.51 dynamic Kanto geometry, so repeated interactions/restamps do not rebuild an unchanged voxel chunk.
- **Regression:** added `tests/kanto_poster_spinner_badge_index_parity.lua`, covering closed/open poster geometry, persistence, one-refresh behavior, no duplicate SFX/rebuild on repeat use, old-save Rocket migration, spinner indexing and both badge-gate index shapes.
- Retains v0.3.51 elevation/Bicycle parity, v0.3.50 state/chunk optimization, v0.3.49 dynamic interiors, v0.3.48 Android logical framing, v0.3.46 ledges/route edges and v0.3.45 warp/interior parity.

# v0.3.51 — Kanto elevation collisions + manual Bicycle + field-rule indexing

- **Gen-1 elevation/tile-pair collision parity:** Kanto now consumes extracted `field.tilePairs.land/water`. A destination can be individually walkable yet still reject the authored source/destination tile pair, matching current Gen1Recomp cave/forest elevation edges. Pair matching is symmetric and walking/surfing use their own tables.
- **All Kanto movement modes agree:** DIORAMA/grid checks tile-pair barriers before ordinary occupancy/arrival; FIRST/THIRD PERSON checks pair boundaries before circular wall sliding so free movement cannot slip through an elevation edge that grid movement blocks.
- **Manual BICYCLE restored:** KANTO FIELD exposes BICYCLE / GET OFF BICYCLE when Gold owns the item. Riding follows extracted `field.bikeRiding` (authored rideable tilesets plus Route 23 / Indigo Plateau exceptions), refuses indoor/disallowed mounts, and never creates a Yellow inventory item.
- **Correct Cycling Road lock semantics:** while `forcedBike` is armed the player cannot dismount. Route 16/18 gate clear maps now clear only the forced lock; an already-mounted rider stays on the bike and may dismount manually afterward, matching the native status-bit split.
- **Immutable field-rule index:** Kanto builds one region-local lookup for tile pairs, bicycle maps/tilesets, dark maps, Route 17 slope membership, forced-bike clear maps and force-bike cells. Hot movement checks no longer rescan extracted arrays every frame/step.
- **Diagnostics/regression:** added tile-pair/free-body block counters, Bicycle mount/dismount counters and `kantoFieldIndexBuilds`, plus `tests/kanto_elevation_bicycle_parity.lua`. The v0.3.50 Cycling/optimization regression was updated for the correct gate-mounted behavior.
- Retains v0.3.50 state/chunk optimization, v0.3.49 dynamic interiors, v0.3.48 Android logical framing, v0.3.46 ledges/route edges and v0.3.45 warp/interior parity.

# v0.3.50 — Kanto Cycling Road + state/chunk optimization

- **Cycling Road physical parity:** KANTO FREE ROAM now consumes extracted `field.forcedMovement` instead of hard-coding route cells. Route 16/18 force-bike tiles silently mount the BICYCLE when Gold owns one, arm the forced-bike state, and refuse SURF while that state is active.
- **Route 17 downhill/brake behavior:** an idle bike rolls south automatically; held A or B brakes continuously; a held direction wins over the automatic roll. Downhill keeps bike-speed movement while Route 17 steering uses normal walking-step timing, matching the current Gen1Recomp rule.
- **Gate-safe companion behavior:** entering the authored Route 16/18 gate clear maps releases the companion's forced-bike presentation so Kanto cannot strand the player in a bike-only state before a manual Kanto Bicycle action exists.
- **Visit-local Kanto state cache:** repeated reads of door events, trainer wins, boulder state and other mod-owned Kanto tables now use a write-through/read-through cache for the active excursion, cutting repeated `mod.save` bridge calls on Android and desktop. The cache is invalidated on Kanto enter/return.
- **Batched voxel geometry refresh:** multi-door restamps (notably Silph Co) apply all changed blocks first and invalidate/rebuild that map's voxel chunk once. A four-door floor now causes one chunk refresh instead of four; Cut block updates use the same centralized refresh path.
- **Diagnostics/regression:** added Cycling Road and optimization counters plus `tests/kanto_cycling_optimization_parity.lua`, covering cached state reads, one-refresh multi-door batching, force-bike mounting/refusal, downhill roll, A/B braking and directional override.
- Retains v0.3.49 dynamic interiors, v0.3.48 Android logical framing, v0.3.46 ledges/route edges and v0.3.45 warp/interior parity.

# v0.3.49 — Kanto dynamic interiors + physical events

- **Silph Co physical doors:** Kanto now applies the current extracted `field.cardKeyDoors.closedDoors` rows before collision and voxel meshing. Floors 2F-11F start with the authored closed blocks until their exact per-door event is set.
- **Story-free CARD KEY use:** interacting with a matching Silph locked door checks Gold's `CARD_KEY`, persists the corresponding Yellow door event in mod save, swaps only that block, and refreshes the live voxel chunk. No Yellow story/cutscene VM is enabled.
- **Rocket Hideout lift parity:** Yellow B1F uses the retail guard-gated `$54 -> $0e` lift doorway; Yellow B4F remains open because Yellow removed that callback and Jessie & James do not set the Red/Blue guard flags.
- **Upgrade-safe trainer events:** pre-v0.3.49 `yellowTrainerWinsV1` records are migrated through extracted trainer-header events, preventing already-earned physical gates from re-locking after update.
- **Vermilion Gym:** the 15-can first/second lock puzzle now drives the physical motorized door. Wrong second cans re-lock and re-roll immediately, and the retail `mask AND random` zero-result bug correctly sends the second switch to can 0.
- **Regression:** `tests/kanto_dynamic_interior_parity.lua` covers Silph per-door state, CARD KEY interaction, Yellow Rocket version behavior, trainer-event migration, Vermilion success/reset behavior and the retail selector bug.
- v0.3.48 Android Gold logical framing, v0.3.46 Kanto ledges/route edges and v0.3.45 warp/interior parity remain intact.

# v0.3.48 — Android Gold logical drawWorld sizing

- **Actual Android zoom root cause fixed:** current Gold `World:drawPipeline()` draws a mod's returned world canvas directly at `(0,0)`. v0.3.47 incorrectly returned a physical framebuffer-sized canvas on HiDPI Android, so a 2x/2.75x phone showed only the upper-left logical portion and looked massively zoomed/cropped.
- **Generation-aware output contract:** Gold/Gen2 now renders and returns exactly the logical `ctx.width`/`ctx.height` scene size. Gen1 keeps the physical-framebuffer `Renderer.worldOverride` normalization introduced in v0.3.47.
- **Internal graphics resolution stays private:** LOW/MEDIUM/custom resolution still renders smaller internally, then normalizes back to the correct Gold logical scene dimensions.
- **Regression:** `tests/android_gold_pipeline_size_parity.lua` simulates a 1000x600 logical Gold scene on a 2750x1650 Android framebuffer and verifies 55% rendering normalizes 550x330 back to 1000x600 instead of 2750x1650.
- v0.3.47 TouchSkin/Gen1 compatibility, v0.3.46 Kanto ledges/route edges and v0.3.45 warp/interior fixes remain in the tree.

# v0.3.47 — Android TouchSkin framing + worldOverride normalization

- **Fixed Android zoom/cropping:** current Gen1Recomp first resolves the full `GameViewport`, then `Renderer.displayMetrics()` applies `TouchSkin.viewport(pw, ph)` and treats only that smaller physical rectangle as the gameplay drawable. The voxel renderer now mirrors that exact ordering instead of stretching the smaller world view across the full phone framebuffer.
- **Full-frame pipeline contract:** `VoxelScene` renders only the TouchSkin gameplay rectangle (at the selected internal graphics-resolution factor), then `GoldVoxelBridge` places/upscales it into a full physical framebuffer canvas before returning it. This matches current `Renderer:endFrame()` worldOverride's 1:1 framebuffer contract and also fixes LOW/MEDIUM internal-resolution canvases being returned smaller than the compositor expects.
- **Camera/view authority:** official `drawWorld` `ctx.vw/vh` now wins over cached Gold world view dimensions, avoiding one-frame stale framing after Android rotation/viewport changes.
- **Android input alignment:** camera slider, direct right-thumb look and DIORAMA pinch use the same TouchSkin gameplay rectangle for placement, bounds and sensitivity while Gen1Recomp `TouchControls` are still hit-tested first in raw OS-window space.
- **Compatibility shim:** `EngineViewportCompat` now exposes TouchSkin-aware physical/logical drawable rectangles, render geometry and drawable-local touch conversion while preserving historical whole-window fallback on older hosts.
- **Regression:** added `tests/android_viewport_parity.lua`, including a 2000x1200 phone / 1600x900 gameplay-drawable fixture, 55% internal-resolution normalization and full-frame worldOverride placement checks.
- Retains v0.3.46 Kanto ledges/route-edge parity, v0.3.45 Kanto warp/interior parity, and all earlier Kanto reconstruction fixes.

# v0.3.46 — Kanto ledges + exact route-edge overlap

- **Yellow-authored ledges in Kanto free roam:** the companion runtime now consumes `field.ledges` directly, including tileset/facing/input/standing/ledge tile rules. Valid ledges perform the original one-way two-cell hop instead of behaving like ordinary blocked scenery.
- **Route-seam ledge landings:** ledges whose second cell is on a connected map now resolve through the authored connection offset. This covers the same important vanilla shapes as current Gen1Recomp, including Route 4 -> Route 3 and the final Route 17 -> Route 18 Cycling Road drop.
- **FIRST/THIRD PERSON ledge support:** continuous movement gives ledges first refusal when the collision body reaches the authored cliff. The body re-anchors for the two-cell hop and the Kanto player proxy exposes a vertical arc/hop flag, so the voxel renderer lifts the trainer instead of sliding through the cliff. Grid/DIORAMA and authored forced movement use the same ledge resolver.
- **Exact connection overlap:** shifted route edges no longer clamp an out-of-overlap source coordinate into the destination map's corner. Such crossings are rejected, preserving the real connected strip and preventing corner snaps/stranding while retaining v0.3.45 neighbour collision and Surf checks.
- **Diagnostics/regression:** added `yellowLedgeHops`, `yellowLedgeSeamHops`, and `kantoConnectionEdgeRejects`, plus `tests/kanto_ledge_route_parity.lua` covering in-map hops, a Route-4-equivalent seam hop, and non-overlap rejection.
- Retains v0.3.45 Kanto warp/interior parity, v0.3.44 GameViewport compatibility, and v0.3.43 THIRD PERSON/Kanto performance behavior.

# v0.3.45 — Kanto warp + interior parity

- **Current Gen1 map-adapter parity:** Kanto's private Yellow map object now uses the source map's real cell width for warp/sign keys and exposes `signAtCell`, `connection`, `warpPadOrHoleAt`, and the current FACILITY/CAVERN/INTERIOR stale-cache pad/hole fallback table. Water/door/warp/counter tile reads now preserve Gen1Recomp's border-extension behavior where the engine does.
- **Completed-step ExtraWarpCheck:** after the ordinary door/warp-tile arrival test, Kanto now performs the non-door collision/extra-warp test when the facing direction is still held or authored forced movement owns the landing. Current `field.warpCarpets` rules are honored; old caches keep the engine's edge-facing fallback.
- **Victory Road physical hole:** story-free Kanto now restores the walkable Yellow Victory Road 3F hole at `(23,15)`, landing on Victory Road 2F `(22,16)`, without enabling Yellow story/cutscene ASM.
- **Warp diagnostics:** status now counts held/forced extra-warp arrivals, pad transitions, hole transitions, and physical dungeon falls.
- **Regression coverage:** `tests/kanto_warp_parity.lua` verifies current pad/hole IDs, width-based lookup, held-direction carpet warping, and Victory Road's physical fall.
- Retains v0.3.44 GameViewport compatibility and v0.3.43 THIRD PERSON/Kanto frame-pacing behavior.

# v0.3.44 — current Gen1Recomp viewport compatibility

- Added a guarded `EngineViewportCompat` bridge so newer Gen1Recomp `GameViewport` layouts provide game-local logical and pixel dimensions without making the mod require that module on older hosts.
- Voxel camera/render fallbacks now honor explicit `ctx.vw/vh` first, then the active game viewport, instead of silently falling back to the entire OS window.
- Android camera-slider, direct right-thumb look and DIORAMA pinch polling now convert raw physical touch coordinates through `GameViewport.toLocal()` and ignore touches outside the gameplay viewport.
- TouchControls hit-testing intentionally stays in raw OS-window coordinates because current Gen1Recomp draws the touch pad after viewport composition as window chrome.
- `GoldPipelineBridge` now preserves explicit pixel metrics from the render-pipeline context instead of assuming logical dimensions are also physical dimensions.
- Bridge diagnostics now expose viewport availability/active state and conversion counters.
- Retains v0.3.43 THIRD PERSON custom-player animation repair, Character Selector motion-state bridge, shared-world BODY promotion and motion-aware Kanto cache warming.

# v0.3.43 — THIRD PERSON animation + Kanto stutter fix

- Continuous FIRST/THIRD movement now repairs the captured player pose to Gold's native 0/1 walk cadence before any sprite/model renderer consumes it. This fixes custom six-frame trainer sheets that animated in DIORAMA but stayed on the stand frame in THIRD PERSON because free movement correctly leaves gameplay `Player.moving` false.
- Kanto's excursion proxy now implements the same 16-frame 0/1 `Player:walkPhase()` contract as current Gen1Recomp instead of returning 1/2.
- The optional Character Selector/`red_3d_player` bridge now temporarily mirrors native `progress`, `targetX/targetY`, `stepFrames`, visual movement vector and animation distance during `drawVoxel`, then restores the real Gold player fields. Skins that key animation from step progress now receive the same motion state as DIORAMA without exposing fake movement to gameplay.
- Fixed a v0.3.42 shared-world hitch: current-map promotion no longer synchronously constructs a FULL bordered/apron mesh that Kanto never draws. Connected/cached BODY meshes promote directly; cold maps queue an urgent persistent-cache-first BODY build cooperatively.
- Persistent cache warming is now motion-aware. Desktop background warmers receive only ~0.5-1.5 ms while the player moves and 3-10 ms during visible idle play instead of the old 22-35 ms BALANCED/FAST slices; aggressive budgets remain available when the world is covered by a menu/loading presentation.
- Once the Kanto disk warmer has scanned the full region with nothing left to queue, it latches complete instead of rescanning every render frame.
- v0.3.42 shared-world BODY rendering, v0.3.41 viewport centering/spawn, native Gen-2 Kanto projection and the custom-player anchor fix remain intact.

# v0.3.40 — Canonical Pallet landing + stricter native Gen-2 surfaces

- KANTO FREE ROAM now treats Yellow's Red-house doorway `(5,5)` as canonical and only chooses the immediate authored landing cells around `(5,6)`. Opaque/numeric warp destinations no longer fall back to another Pallet warp or a town-wide nearest-walkable search.
- Every persisted Kanto position with revision below 340, including positions already stamped by v0.3.39 under a neighboring map id, is discarded once and rebuilt from the canonical Pallet landing on the next Kanto entry. Gameplay progress keys are untouched. The corrected cell is immediately persisted as revision 340.
- Pallet entry/resume validation now rejects warp/NPC cells, map border-filler blocks, and source tiles whose projected material is water/door/structure. `excursionState()` repeats the guard while Pallet is active so corrupted coordinates cannot survive into rendering.
- Gen-2 donor surface classification is now conservative/pure-use: an unpinned donor tile must be used exclusively by one surface collision family before it can become ground/grass/water/door. Any mixed blocked/structure use removes it from generic surface replacement, preventing reused tree/roof/fence art from being painted across walkable Yellow terrain.
- Accepted donor texture pixels now resolve directly through the donor tile's exact Gold/Silver PalMap slot and exact 2bpp shade before they enter the Kanto atlas. Unmatched unique Kanto art keeps the nearest safe donor slot fallback.
- Bumped Kanto projection revision to `g2-native-340-r1` and persistent mesh geometry revision to `g2vx-340-r1`; old projected sectors rebuild once and cannot be revived from stale disk geometry.
- Retains the v0.3.38 arbitrary custom-player frame/anchor correction plus all v0.3.29-v0.3.39 Kanto gameplay, camera, movement, streaming and cache work.

# v0.3.39 — Kanto entry hardening + exact Gen-2 material projection

- Replaced the narrow v0.3.37 Pallet saved-position migration with a revisioned migration: every pre-339 Pallet resume is rebuilt once from the authored Red's-house landing and immediately persisted as revision 339.
- Pallet resumes now have to be in the same connected walkable component as the canonical landing, and warp/NPC cells are rejected. This catches disconnected scenery/tree pockets even when their locally-nearest cell is technically walkable.
- Fixed a persistent-cache invalidation hole introduced by the v0.3.38 shape projection. `VoxelDiskCache` now uses geometry revision `g2vx-339-r2` and includes the synthetic projected tileset id, native donor id and projection revision in the body signature, so old Yellow/Gen-2 geometry cannot be revived after a presentation-shape change.
- Gen-2 donor classification now combines real Gold/Silver `COLL_*` semantics with authored voxel-profile shape pins. A donor tree/fence/sign/roof/ledge/wall/stair/furniture/prop tile cannot be classified as generic ground merely because its shared 16px collision cell is walkable.
- Shape-compatible donor families are matched more aggressively (tree-to-tree, fence-to-fence, roof-to-roof, ledge-to-ledge, etc.) while broad structure fallback stays guarded. This increases actual Gen-2 texture coverage without turning walkable terrain into scenery.
- Kanto color conversion now uses the same exact 2bpp shade-index rounding as `GoldColorAtlas` while retaining each matched/nearest donor tile's exact Gen-2 PalMap slot.
- Retains v0.3.38 arbitrary custom-player frame/anchor alignment, v0.3.37 Pallet authored-warp entry, and all earlier Kanto gameplay/streaming/cache systems.

# v0.3.38 — Gen-2-native Kanto projection + custom player anchor

- Reworked Yellow-backed Kanto presentation around a per-map **native Gen-2 donor**. If Gold/Silver has the same map id, that exact map supplies the palette/tileset context; otherwise outdoor Kanto prefers native `TilesetKanto`, interiors choose a matching Gen-2 family, and Johto is the fallback.
- Generic Yellow ground/grass/water/shore surfaces now always take the nearest donor texture in the same semantic class. Doors and structures use guarded matching so unique Kanto landmarks are not randomly replaced.
- Matched tiles use the donor tile's **exact Gen-2 PalMap slot**. Even an unmatched unique Kanto structure now uses the nearest same-material donor's PalMap slot while retaining its own pixels.
- Gen-2 donor material classes are derived from the donor blockset's real `COLL_*` cells through Gen2 `Permissions` (walkable/grass/water/warp/solid), not Gen-1-style walkable tile lists.
- Added runtime synthetic voxel profiles that remap native Gen-2 authored shape metadata onto matching Yellow tile ids. Trees, fences/posts, ledges, water, ground and related metadata therefore follow the same voxel construction rules as their Gold/Silver donor without rewriting Yellow gameplay tiles/collision. Source Kanto building templates remain available for unique layouts.
- Fixed custom player alignment in voxel mode: `SpriteBillboards` now honors arbitrary `frameWidth`, `frameHeight`, `anchorX` and `anchorY`. The old fixed 16x16/x=8 card pivot could render wider custom characters (including Sonic-style skins) left/right of the actual player/collision body.
- Retains v0.3.37 Pallet spawn recovery, v0.3.36 Safari/fishing/Game Corner/trades, v0.3.35 field/respawn rules, v0.3.34 Seafoam/Fly, v0.3.33 Cut/Strength/trainer sight/NPC roaming, v0.3.32 persistent sector cache, v0.3.31 hard residency/streaming, v0.3.30 analog movement and v0.3.29 camera correction.

# v0.3.37 — Kanto Pallet spawn repair

- Fixed KANTO FREE ROAM spawning around Pallet Town's right-side trees when the imported Yellow cache exposes opaque/numeric warp destinations. v0.3.36 incorrectly fell back to `def.width/def.height`, mixing 32px map-block dimensions with 16px player-cell coordinates.
- Pallet entry now resolves Red's-house warp by destination name when available, otherwise uses Pallet's first authored warp/coordinate, with canonical `(5,5)` only as a final compatibility fallback.
- The actual landing searches south of the door first and refuses warp cells or occupied NPC cells before widening around the door.
- Added a one-way resume repair for the exact v0.3.36 dimension-derived Pallet position, and the validated entry point is persisted immediately so an existing bad save is corrected on the first v0.3.37 Kanto entry.
- Retains v0.3.36 Safari/fishing/Game Corner/trades and all earlier Kanto movement, camera, streaming, caching, Johto-visual and field-system work.

# v0.3.35 — Kanto second-region field systems

- Added a Kanto-local Pokemon Center spawn (`yellowHealPointV1`). Entering/healing at a Yellow Center remembers a safe non-warp cell plus the matching LAST_MAP exterior without overwriting Gold's native `blackoutMap`.
- Kanto battle losses now keep the visible player in Kanto, heal through Gold's real party state, and respawn at the last Kanto Center (Pallet fallback if none exists). KANTO FREE ROAM snapshots the hidden Johto map/cell; RETURN TO JOHTO restores that anchor if Gold's native whiteout moved it, while retaining money/party/save consequences.
- Added `KANTO FIELD` to the START menu. Gold/Silver party + badge authority drives FLASH in extracted Yellow dark maps, DIG back to the remembered Kanto cave exterior, and TELEPORT to the Kanto Center point.
- Rock Tunnel darkness now multiplies the live voxel lighting instead of replacing palettes/meshes; FLASH removes the multiplier immediately, so no sector rebuild/cache invalidation is needed.
- Activated extracted Yellow spinner-arrow movement (`field.spinners`) through the same forced-movement runner used by Seafoam currents.
- Added persistent hidden Game Corner coins through Gold's Coin Case / coin counter.
- Activated Route 22/23 physical badge gates from `field.badgeGates`; progression checks Gold's real Kanto badge store and does not execute Yellow story ASM.
- Retains v0.3.34 Seafoam/Fly/hidden-event behavior and all v0.3.29-v0.3.33 camera, movement, streaming, cache and Kanto gameplay work.

# v0.3.34 — Kanto Seafoam + Fly + Hidden Events

- Added data-driven Seafoam Islands boulder-hole progression from current Yellow `field.seafoam`: Strength can push authored boulders into extracted holes, hide the source rock, reveal/persist the lower-floor rock at its authored landing cell, and set a Kanto-local event without mutating Gold story flags.
- Added Seafoam current playback from extracted RLE movement lists. Currents run through the normal Kanto grid mover so collision, warps and sector ownership remain authoritative; plugging the required boulders disables them persistently.
- Added `KANTO FLY` to the START menu while Kanto free roam is active. It requires a Gold/Silver party member with FLY plus the STORM Badge, tracks visited Yellow Fly towns, uses Yellow `field.flyWarps` landing coordinates, and excludes route-center/dungeon escape fly spots.
- Added safe, non-story Yellow hidden interactions from `field.lua`: hidden items feed Gold's real Bag and persist as taken; hidden PC tiles open Gold's PC; trash cans respond; Gym statues show leader/winner status from Gold's Kanto badges.
- Retains v0.3.33 Cut/Strength/trainer sight/WALK NPC behavior and all v0.3.29-v0.3.32 camera, movement, streaming and persistent-cache work.

# v0.3.33 — Kanto field moves, trainer sight and living NPCs

- Added Yellow-authored Cut block swaps in Kanto with Gold/Silver party + HIVE badge authority. Cut changes persist in the Kanto namespace and use `ChunkMesher.refresh` so voxel terrain rebuilds in place and stale disk-cache signatures are invalidated.
- Added Gold-authorized Strength activation with PLAIN badge gating for Yellow `SPRITE_BOULDER` actors. Ordinary boulders push one safe cell at a time and persist their Kanto positions across visits.
- Added Yellow trainer-header sight engagement: forward-facing, inclusive extracted range, blocked by walls/actors, then trainer walk-up to the adjacent cell before the existing Gold scripted battle bridge.
- Fixed current Yellow object facing import: `STAY` objects now read `SPRITE_FACING_*` from the extractor's `range` field, with older movement-encoded cache shapes still accepted.
- Added bounded roaming for authored Yellow `WALK` NPCs with interpolated steps and collision/warp/Pokemon/player avoidance.
- Strength resets on Kanto map handoffs/warps/region exit, while persistent boulder positions remain.
- Seafoam's special boulder-hole/current cascade is intentionally not approximated by the ordinary pusher; it remains queued for a data-driven pass using the already-extracted Seafoam wiring.
- Retains v0.3.32 persistent sector caching/background cooking, v0.3.31 hard region residency/palette precision, v0.3.30 true movement, v0.3.29 camera correction, v0.3.28 story-free Yellow gameplay and v0.3.25 announcer playback.

# v0.3.32 — Persistent sector cache + aggressive Kanto cooker

- Rebuilt the formerly disabled voxel disk cache around `EngineCompat.fs()` / Gen1Recomp persistence routing instead of direct mod `love.filesystem` access.
- BODY and FULL terrain/water vertex streams are revision/map/tile/UV/seam-mask signed, byte-count validated, and commit metadata is written last so interrupted/stale entries are always misses.
- Cache hits skip `Structures` + `runGeometry` and cooperatively upload raw vertices in chunks. Freshly built terrain lands in the scene before auxiliary grass/figures and before cache writing.
- Added cache-only Kanto warming jobs: every Yellow outdoor BODY sector can be derived and persisted without allocating a GPU mesh. Real visible terrain jobs always preempt warmers.
- Desktop cache-only work gets a substantially larger idle CPU slice than mobile, so a PC can fill the Kanto sector cache quickly while the active scene remains playable.
- Direct/predicted Kanto sectors now request BODY plus their exact FULL seam-masked mesh while still offscreen. Cached BODY can appear immediately while FULL finishes ahead of the camera, reducing first-visit pop as well as repeat-visit delay.
- RETURN TO JOHTO still cancels unfinished Kanto warmers and unloads Kanto render residency; completed persistent sector files stay on disk for future Kanto visits.
- Retains v0.3.31 hard region residency/palette precision, v0.3.30 true-direction movement, v0.3.29 camera correction, v0.3.28 Kanto gameplay and v0.3.25 announcer playback.

# v0.3.31 — Kanto predictive streaming, hard residency and palette precision

- Split Johto and Yellow Kanto into hard render-residency domains. Kanto is no longer progressively attached to Gold while the player is in Johto; region switches force immediate previous-region voxel cache eviction.
- RETURN TO JOHTO releases Kanto private decoded atlases, sprite images/ImageData, foreign map adapters, NPC/Pokemon presentation caches and sector cache while retaining imported Yellow source/gameplay data and persistent Kanto progress.
- Added offscreen direct-neighbour body-mesh prefetch plus movement-direction second-ring prefetch so adjacent terrain can finish before the player reaches the seam.
- Moved neighbour actor distance rejection ahead of `entitiesForMap`, preventing far sectors from decoding NPC sheets or constructing ambient Stadium Pokemon until they are actually near the player.
- Cached Kanto sector topology and reduced Gold palette-profile polling from every render frame to at most four checks per second.
- Johto donor texture matches now inherit the donor tile's exact Gen-2 PalMap slot, fixing the remaining v0.3.30 mismatch where Johto-looking pixels could still be shaded by a broad Kanto semantic slot.
- Retains v0.3.30 true-direction movement, v0.3.29 Kanto camera correction, v0.3.28 free-roam systems and v0.3.25 announcer playback.

# v0.3.30 — Kanto true directional movement + Johto texture/palette integration

- Replaced the Yellow/Kanto excursion's final four-direction quantization in FIRST/THIRD PERSON with a continuous 360-degree camera-relative body matching Johto's 16px scale, 5.5px collision radius and 1px/60Hz walking speed. Analog magnitude and diagonals are preserved, with axis-separated wall sliding.
- Kanto cell ownership still changes at 16px boundaries and continues to drive persistent position, arrival warps, roaming/static Pokemon contact and optional classic encounter rolls. Connected-map seams and collision/edge warps remain explicit handoffs instead of allowing the free body outside a map.
- DIORAMA and SURF retain grid movement, matching Johto's existing special-state handoff rather than reimplementing Surf physics.
- Restored Gold/Johto as the Kanto color authority. A canonical Johto outdoor map supplies the eight-slot Gold palette profile so Kanto does not inherit Yellow-authored town/cave tints or a hidden native-Kanto/interior palette.
- Added guarded Johto texture donors. Kanto 8x8 tiles are pattern-matched only against Johto tiles in the same semantic class (water/shore/grass/ground/door/structure); safe matches use the real Johto pattern, while unmatched/unique Kanto landmark art is preserved.
- Retains v0.3.29 rendered-map third-person camera collision, all v0.3.28 Yellow free-roam gameplay systems, v0.3.27 Kanto renderer parity, and v0.3.25 announcer playback.

## v0.3.28 — Yellow Kanto free-roam conversion

- Restored Yellow-authored Kanto palette families; Kanto no longer inherits the hidden Johto map's active tint.
- Fixed Yellow NPC/sign interaction by loading `text_pointers.lua` and resolving object/sign `TEXT_*` constants to their extracted text labels. `text_asm` story/cutscene handlers are explicitly not executed.
- Loaded `trainer_headers.lua` for battle/after-battle trainer dialogue. Yellow trainers and all eight Gym Leaders continue through Gold's Gen-2 battle runtime; Gym wins now populate Gold's real Kanto badge store.
- Added persistent Yellow free-roam position, item pickups, trainer wins and one-off/static Pokemon outcomes. RETURN TO JOHTO preserves the hidden Gold world and KANTO FREE ROAM resumes Kanto where it was left.
- Yellow item objects now add compatible items through Gold's four-pocket `Bag`; Yellow Marts open the Gen-2 Mart UI with compatible Yellow stock; Pokemon Centers call Gold's `World:healParty`; PCs prefer Gold's `World:openPc`.
- Added Gold SURF traversal on Yellow water using Gold's party move and Fog Badge eligibility; returning to land dismounts automatically.
- Visible and classic Yellow encounters still feed Gold wild battles/catching. Static Yellow map Pokemon now persist after capture/defeat and return if the player runs.
- Retains v0.3.27 native Kanto renderer parity and v0.3.25 Stadium 1 announcer playback.

## v0.3.27 — Native Gen-2 Kanto parity

- Removed the last runtime geometry branch that selected higher-quality behavior by the literal `TilesetJohto` / `TilesetJohtoModern` name.
- Added profile-driven `tree_crown` metadata so native Gold Kanto trees use the same authored stepped-crown hull machinery as Johto trees.
- Added per-cell source-art checks and separate round-template cache signatures, so boulders, cut trees, urns and other collision-derived cylinders cannot accidentally inherit tree crowns.
- Added explicit `tree_art` metadata for Kanto, Johto and Johto Modern forest-border/apron inference; older profiles retain the former cylinder/planter/canopy fallback.
- Kept Kanto's own tile IDs and collision/art vocabulary rather than cloning Johto IDs onto Kanto. Shared Gen-2 hop-lip and collision-class shaping remains region-neutral.
- Expanded the conservative adaptive Kanto building scan from 24×16 to 40×32 source tiles so larger one-off city landmarks can be recovered when they use the verified Kanto roof/base/door frame; exact templates still claim first.
- Retained the v0.3.26 native-Kanto building recovery and companion-Kanto seam/warp repairs.
- Stadium 1 announcer import/cache/playback remains unchanged from the v0.3.25 fix.

## v0.3.26

- Substantial Kanto repair pass covering both Gold's native Gen-2 Kanto and the optional Yellow companion-region Kanto.
- Native `TilesetKanto` now has a conservative roof-only fallback so unmistakable pitched/slate roof art remains top-facing even when a landmark is not in the exact building catalogue.
- Added a Kanto-only adaptive framed-building path: after exact templates have first claim, an unclaimed facade with Kanto's real base frame, roof cap and a real door is modeled from its own map tiles with the existing sprite-to-voxel building pipeline. This fixes one-off facade/window/sign variants without inventing map-specific dimensions.
- Yellow companion Kanto now repairs missing reciprocal surface connections and reversed offsets in stale imported caches while preserving conflicting authored edges as warnings.
- Yellow `PLATEAU` maps now participate in outside/LAST_MAP semantics and the stitched surface graph.
- Yellow excursion warps now distinguish arrival, collision and edge triggers; remember the last outside map for `LAST_MAP`; require valid destination warp coordinates; and no longer fall back to arbitrary map-center coordinates.
- Added safe Pallet recovery for invalid companion-Kanto excursion positions and new Kanto seam/warp diagnostics.
- Retains the v0.3.25 shared PC/Android Stadium 1 announcer importer/playback fix and TEST STADIUM ANNOUNCER action.

## v0.3.25

- Fixed the remaining Stadium announcer no-voice path on both PC and Android: persisted announcer WAVs are now read back through the same Gen1Recomp persistence backend that saved them, then supplied to LÖVE as in-memory WAV/FileData instead of assuming a relative disk path is visible to the audio engine.
- Kept one shared Stadium 1 importer/extractor/playback implementation for PC and Android; only the platform file picker differs.
- Added **TEST STADIUM ANNOUNCER** to Mod Settings. After a successful Stadium 1 import it immediately plays known spoken clip 223, providing a direct end-to-end voice test without requiring a battle.
- Audio playback now treats `Source:play()` returning `false` as a real failure instead of marking the clip active merely because the Lua call did not throw.
- The existing 823-clip ROM extraction, Stadium 2 importer, and native Android/desktop picker flows remain intact.

## v0.3.24

- Fixed Android Stadium announcer imports that could report READY but produce no audible voice.
- ROM-derived announcer WAVs now use Gen1Recomp's persistence filesystem instead of binary `mod.storage` records.
- Every generated WAV is read back after writing; the final cache is accepted only after clips 000, 223, and 822 validate and clip 223 successfully opens through the audio engine.
- Old v0.3.23 ROM-cache markers are ignored, so installing this version and re-importing Stadium 1 performs a clean verified rebuild.
- The Android system Files picker and Stadium 2 model/world import flow are unchanged.

## v0.3.23

- Extended the existing Android Storage Access Framework / Files picker instead of adding a desktop-only builder: the same **STADIUM 1 / 2 ROM FILE** row accepts either Stadium 2 or Pokemon Stadium (USA) v1.0.
- Stadium 2 selections retain the v0.3.22 001-251 model/world importer unchanged. Stadium 1 USA v1.0 selections are recognized before that path and routed into StadiumBattleFX validation/caches.
- Added an Android-safe pure-Lua Stadium 1 speech archive reader and MORT decoder. It inventories the cartridge's nested `S1` archive and incrementally converts all **823** 16 kHz announcer streams to private cached WAV data without Python, shell commands or the desktop `mort_decoder` executable.
- Announcer extraction advances in small frame budgets during normal updates and reports `S1 VOICE ###/823` in the ROM option row to avoid one long blocking decode on mobile.
- A rejected/wrong Stadium 1 selection now has its own error path and does not mark an existing Stadium 2 model cache failed.
- No ROM bytes or announcer recordings are shipped; voice audio is derived only from the player's selected legally obtained Stadium 1 image and stored in mod-scoped cache storage.
- Preserves all v0.3.22 StadiumBattleFX audit behavior and prior Stadium2/weather/flight/follower/live-battle systems.

## v0.3.22

- Completed a second-pass file/behavior audit against the full user-supplied **StadiumBattleFX 2.1.7** archive. All **77/77** source Lua modules remain embedded byte-for-byte; v0.3.21's copy was complete, but the audit found important source behaviors that were copied without being on Gold's active execution path.
- Activated the source `effects/StadiumFxPlayer` and `effects/StadiumNativeInterpreter` for exact source-timed move emissions, including the dedicated traced Thunder Shock/Thunder Wave, Scratch, Sand Attack, Quick Attack, Gust, Horn, Leer, String Shot, Confusion, kick and tackle render paths.
- Added **STADIUM NATIVE SCHEDULER** to independently enable/disable the exact native scheduler while retaining the lighter cartridge/generic overlay fallback.
- Added optional source Stadium 1 **DSM7 native metadata** cache support. With the player's validated private Stadium 1 ROM, Gen-1 species now use the source 151×165 move attachment bytes and native move-camera selector/cut-delay metadata; Gen-2-only species keep the existing Stadium2 fallback anchors/camera profiles.
- Native source attachment requests resolve against the currently animated Stadium2 actor instead of installing the uploaded mod's competing Stadium1 model host.
- Activated source `StadiumScreenFx.present` borderless replay, `FailureNotice`, `StadiumLog` and `StadiumLogExport`; added **STADIUM FX FALLBACK NOTICE**, **REBUILD STADIUM FX CACHE** and **SAVE DIAGNOSTIC SNAPSHOT** controls.
- Added attack-camera ownership negotiation so a compatible external Battle Cinematics camera can claim the attack-camera role without two directors fighting each other.
- Documented the source systems deliberately **superseded rather than missed**: its alternate Stadium1 model/provider stack, embedded Gen1-oriented Stadium2 importer, provider-owned whole-frame compositor, ordinary portable arena themes and external BattleArt/PotatoVoxel compatibility. Those would conflict with or regress this project's Gold-aware 001–251 Stadium2 renderer, double battles, live encounter-world arenas and controller HUD; source boss rooms/effects/metadata remain active where useful.
- The uploaded/public 2.1.7 source remains voice-free. The complete announcer engine/captions and optional locally generated 823-clip voice-pack path remain preserved.
- Added `stadiumBattleFxAudit()` and `stadiumBattleFxRebuild()` exports for diagnostics/integration.
- Preserves v0.3.20 modern live-battle motion and all v0.3.21 weather/flight/follower/controller/render systems; Gold remains authoritative for battle rules and HP.

## v0.3.21

- Ported the battle-presentation systems from the user-supplied MIT **StadiumBattleFX 2.1.7** source into this Gold/Stadium2 mod without replacing Gold's battle engine or the existing full Gen-2 Stadium 2 model owner. The original source tree and license/notices are retained under `lib/StadiumBattleFX217/` plus the root attribution files.
- Integrated the complete **165-move source roster**: Stadium dispatch metadata, move-specific visual/delivery families, source-calibrated duration/impact timing, body-only flags, attachment requests and melee/combo/ranged/sustained/aerial/field/status/self/explosion cinematic profiles now feed the Gold live-battle presentation.
- Added **STADIUM CARTRIDGE FX**. AUTHENTIC ONLY renders the source's cartridge-calibrated prominent-move programs; ALL 165 additionally enables its deterministic generic renderer for the complete roster; OFF leaves this mod's existing depth-aware world-space effect layer alone.
- Added an optional private **Pokemon Stadium (USA) v1.0** import (`ed1378bc12115f71209a77844965ba50`). When present, StadiumBattleFX locally builds the ROM-derived effect texture, Gym Leader Castle/Elite Four/Champion arena and trainer-portrait caches. No Stadium 1 ROM bytes or extracted cache are shipped.
- Adapted StadiumBattleFX's animated origin/impact attachment concept to the already-loaded Stadium 2 skeletal actors through `Stadium.attachmentWorld`, so effect anchors follow live animated model matrices instead of installing the source mod's competing Gen-1 model host.
- Integrated source attack-camera staging into the existing Stadium battle camera, with windup/travel/impact/recovery subject changes, orbit/width cues and existing manual-camera priority.
- Integrated toggleable source-driven hit reactions and faint animations while preserving Gold HP/faint authority and v0.3.20 render-only knockback.
- Added optional ROM-derived **STADIUM BOSS ARENAS** for compatible Kanto Gym Leader Castle rooms plus Elite Four/Champion rooms. Ordinary fights remain in this mod's live overworld arena rather than replacing its core encounter-world feature.
- Added optional ROM-derived **STADIUM TRAINER PORTRAITS** for compatible source classes. Unsupported Gold-only trainer classes safely keep their normal Gold art.
- Ported StadiumBattleFX's announcer event/timing engine and added **ANNOUNCER BATTLES** scope plus **ANNOUNCER CAPTIONS**. The public 2.1.7 source ZIP is intentionally voice-free, so audible Stadium calls require the user's own locally built 823-clip `assets/announcer` pack; no voice recordings are redistributed here.
- Added BATTLE toggles for the master source port, cartridge layer, screen wash, attack camera, attack speed, camera width, hit reactions, faint animations, boss arenas, trainer portraits, announcer, announcer scope and captions.
- Preserves v0.3.20 modern live-battle motion, controller HUD, double battles, battle transparency/backgrounds, Weather FX, flight, ambient sky Pokemon, followers, performance controls and all existing Stadium2 overworld systems.

## v0.3.20

- Upgraded **modern live Stadium battles** without replacing Gold's actual turn/damage/HP/PP/status/switch/item/catch logic. The new layer is presentation and direct-control only.
- Direct Pokémon movement now uses true analog acceleration/deceleration instead of fixed per-frame translation. Camera-relative left-stick/WASD control has soft stopping, faster reversal, configurable TIGHT/MODERN/SMOOTH feel, arena-wall sliding and a loose combat tether so the fight cannot drift apart.
- Contact-style damaging moves now visibly close distance with a short render-only lunge, commit the attacker during the performance, then return to the stable manual-control anchor. Projectile/status/global moves do not fake contact movement.
- Real HP loss now drives defender knockback scaled by damage fraction. This is visual only: the battle position used by Gold never changes.
- The Stadium battle camera follows temporary lunge/recoil positions, narrows FOV during active attacks, adds damage-scaled impact zoom and deterministic camera shake, then eases back to the menu/inter-turn frame.
- Added **MODERN LIVE BATTLE MOTION**, **BATTLE MOVEMENT FEEL**, and **BATTLE IMPACT FEEDBACK** under the BATTLE settings category.
- Double-battle partner anchors remain independent; the selected partner can still be moved without dragging the other Pokémon.
- Preserves v0.3.19 Weather FX integration, v0.3.17 flight seam 3D-player continuity, v0.3.13+ crash-safe landing, ambient sky Pokémon, custom battle UI and existing Stadium skeletal/effect renderers.

## v0.3.18

- Replaced the old `lib/Weather.lua` four-mode CLEAR/RAIN/FOG/RAIN+FOG renderer with an embedded **Weather FX 4.10.0 visual/weather-state port**.
- Added Weather FX regional fronts and the full selectable weather catalogue: clear/sun/heatwave/harsh sun, light/heavy/primal rain, storm/gale, snow/blizzard/hail/sleet/thundersnow, sand/dust/ash, strong winds/flock/swarm, haunted mist/dragon/brawl/plain/verdant fronts, smog/fog/psystorm.
- Weather FX now drives the Stadium2 voxel atmosphere in 3D: cloud decks, weather sky grading, depth-aware rain/fog, light shafts/motes and its wet/puddle presentation. Weather types the 3D backend does not draw as world-space particles (snow, hail, sand, ash) retain Weather FX's 2D particle layer instead of falling back to the removed legacy renderer.
- Added Weather FX lightning, splashes, rain/thunder/wind audio, automatic spell timing, Johto-aware fronts, time-of-day weighting and seasons.
- Added a dedicated **WEATHER FX** settings category. `WEATHER FX` replaces the old `3D WEATHER` row and `MOVING CLOUDS` has been removed because Weather FX owns cloud presentation.
- This is intentionally a **visual/weather-state port**. Weather FX's bundled Steel/Fairy/Dark type registry changes, Delta/weather-form Pokémon, wild encounter substitutions, tornado warps and battle-rule mutations are vendored for source attribution/compatibility but are **not installed** into this package.
- Preserves v0.3.17 flight seam 3D-player continuity, v0.3.16 ambient flying Pokémon/unrestricted connected flight, crash-safe Circle/B landing, visible Surf, battle presentation and all existing Stadium/voxel systems.
- Preserved `weatherfx/lib/voxel_atmos/LICENSE-kanto-dynamic-weather` and `NOTICE.md` with the vendored Campo Kanto Dynamic Weather atmosphere code.

## v0.3.17

- Fixed the 3D player turning into Gold's non-animated 2D trainer card after flying across an unrestricted/unvisited map connection.
- Gold `setMap()` always runs `CheckUpdatePlayerSprite`; destination edge cells can temporarily force SURF or BIKE even though Fly Your Pokemon still owns movement. Flight now normalizes those temporary map-entry player states back to NORMAL while airborne.
- Added an explicit `_flyYourPokemonFlight3D` rider-presentation marker and taught the Character Selector/Stadium bridge to ignore Gold's temporary Surf/Bike special-card suppression only while flight is actually active.
- The fix applies to both native seamless connections and the v0.3.16 unrestricted fallback used for previously inaccessible/unvisited connected areas.
- Landing clears the flight presentation marker, so normal Surf/Bike behavior still uses its intended player presentation afterward.
- Preserves v0.3.16 ambient sky Pokemon, unrestricted connected flight, v0.3.15 direct steering, and the crash-safe Circle/B landing path.

## v0.3.16

- Removed the free-flight discovery lock. Physical Flight now crosses normal outdoor map connections whether or not the destination has been visited before; the old `mountDiscoveryGates` / `AREA NOT VISITED` path is gone. This changes only connected overworld traversal, not indoor/cave takeoff rules or landing safety.
- Added **AMBIENT SKY POKéMON** (default ON) and **SKY POKéMON DENSITY** (LOW/NORMAL/HIGH) under Fly Your Pokémon settings.
- Ambient flyers are location-aware rather than globally random: the system prefers flying/airborne species found in the current map's encounter data, borrows from directly connected routes when needed, then uses conservative forest, mountain, coast, ruins, cold-area, town and route pools with day/night weighting. Legendaries are explicitly excluded.
- Ambient flyers are presentation-only: they never enter Gold's `world.entities`/`world.npcs`, never collide, never trigger battles, never alter encounter RNG, and are merged only into the voxel/Stadium render scene.
- Ambient flyers use Stadium 2 models when available, drift/turn/bob at varied altitudes, and have sun-shadow casting disabled to keep the feature light on the voxel renderer. NORMAL density is intentionally small (usually 2, sometimes 3 on large maps).
- Preserves v0.3.15 direct live-input flight steering, v0.3.13+ controller crash isolation / Circle-B landing, visible Surf, followers, battle systems, FPS controls and voxel performance changes.

## v0.3.15

- Fixed v0.3.14 flight steering being completely unresponsive. Gold's fixed-step order calls `world:pollInput()` before `world:step()`; v0.3.14 copied the fresh stick vector in the first seam and then reset it at the start of the second seam before Flight used it.
- Flight no longer depends on GoldCameraControls' temporary `_stadiumFreeIntentX/Z` fields. Airborne `World:pollInput` now suppresses Gold's ground movement owner, while the flight solver reads `FirstPerson.moveVector()` / the live engine Input table directly once per logic tick.
- FIRST/THIRD PERSON keep camera-relative analog/D-pad steering. DIORAMA now has explicit map-relative flight steering instead of silently requiring a free-camera rung.
- Releasing the stick yields an immediate zero vector; changing direction is consumed on the same tick. GoldCameraControls' stale continuous-walk fields are cleared before and after the flight tick, so there is no auto-forward or double movement.
- Circle/B LAND, controller face-button quarantine, render-only Stadium mount handling, and the v0.3.13 crash-isolation path are unchanged.

## v0.3.14
- Fixed the v0.3.13 regression where flight could keep moving forward and ignore new D-pad/left-stick steering.
- Root cause: FlyYourPokemon returned before `GoldCameraControls` could refresh `_stadiumFreeIntentX/Z`, while GoldCameraControls' `stepBody` tail continued replaying the stale vector from before takeoff.
- Flight now allows GoldCameraControls to sample the live input and perform its camera-relative conversion, copies that fresh world-space vector, then clears all Gold continuous-movement ownership fields before its movement tail runs.
- The air solver now runs exactly once from the guarded `World:stepBody` tail using the captured vector. `Player:update` no longer performs a second/conditional free-flight move.
- A logic tick with no fresh steering input is explicitly zero movement, preventing stale auto-forward.
- `FirstPerson.driving()` (camera engaged + overworld owns controls) is now the preferred free-flight input gate, preventing movement behind menus/overlays.
- Circle/B LAND, the v0.3.13 pre-world-step landing transition, face-button quarantine, Stadium render-only carrier, Visible Surf and the 3D player restore remain unchanged.

## v0.3.13

- Reworked the flight landing path after Circle/B could still crash in v0.3.12. The remaining global `love.gamepadpressed` / `love.gamepadreleased` wrapper has been removed; flight no longer owns a callback above Gen1Recomp's controller stack.
- Circle/B is now detected only from Gold's queued logical `b` action at `input.step`. The edge is removed before `Input:step`, then landing is committed before `World:step` begins.
- LAND is now a minimal state transition. It no longer restores monkey-patched world methods, parks/retags the Stadium carrier, writes options to disk, polls `isGamepadDown` for the landing button, or calls controller/mobile vibration in the crash-sensitive landing frame.
- Water LAND is temporarily fail-closed in this crash-isolation release: Circle/B over water keeps flight active and reports `LAND OVER SOLID GROUND`; the Pokémon SWIM action remains the supported path into visible Surf.
- `GoldVoxelBridge` now submits the presentation-only Stadium mount only while `mountRenderActive` is true. Landing turns that flag off, so the 3D mount disappears without mutating or deleting the carrier table while renderer/world code may still hold references.
- Any v0.3.09-v0.3.12 post-world landing bridge is disabled on hot reload, and any v0.3.12 global LÖVE gamepad bridge is neutralized into a transparent pass-through. A full process restart is still recommended when replacing an older build so stale hook closures cannot survive.
- Preserves v0.3.10 swim-to-shore 3D-player restoration, v0.3.11 render-only mount ownership, v0.3.12 fixed-step input quarantine, battle transparency/backgrounds, controller layouts, F6 camera, followers, FPS controls and voxel performance changes.

## v0.3.12
- Removed `FlyYourPokemon` from the `Game2:gamepadpressed` / `gamepadreleased` wrapper chain. The previous stack-dependent `flightInputOwned()` gate could fall through whenever another transparent/custom state sat above the overworld, allowing Cross/A back into Gold/BattleControllerUI despite the flight guard.
- Added a stable top-level LÖVE gamepad bridge. While Flight is active it swallows face buttons plus START/SELECT before `SwitchDiagnostics`, Game2, CamControl, PerformanceRuntime or BattleControllerUI can see them. Circle/B still only queues the deferred LAND request; matching releases are swallowed with their press.
- Added a second fixed-step quarantine on `input.step` before `Input:step`: A/B/START/SELECT queued state is cleared before Gold can promote it, and the cleanup runs both before and after other input-step hooks so synthetic injected edges cannot leak through either.
- Controller mount shortcuts are polled from mapped gamepads instead of requiring another Game2 callback wrapper. D-pad/left-stick movement, right-stick camera and L2/R2 altitude remain outside the quarantine.
- Preserves the v0.3.11 render-only Stadium carrier and v0.3.10 Visible Surf -> shore 3D-player restoration.

## v0.3.11
- Fixed the persistent controller crash while flying at its gameplay/render boundary. The Stadium mount carrier is now presentation-only and is **never inserted into Gold's `world.entities` list**; `GoldVoxelBridge` already merges it directly into the voxel scene. This prevents `World:interact` and other Gold entity scans from treating the synthetic carrier as a real NPC.
- Hard-isolated airborne controller face buttons from Gold's input queue. Circle/B remains the dedicated deferred LAND input; Cross/A, Square/X and Triangle/Y do not become gameplay/interact edges while Flight owns the overworld. Matching face-button releases are swallowed as well.
- Flight interaction guards, Stadium carrier creation and rider sync are armed immediately at takeoff instead of waiting for a later `Player:update`.
- Added session-reset cleanup for legacy v0.3.08-v0.3.10 mount carriers that may survive a hot reload in `world.entities`.
- Preserves v0.3.10 Visible Surf -> shore restoration of the Character Selector 3D player.

## v0.3.10
- Removed Cross/A from the flight landing path. LAND now uses PlayStation Circle / Xbox B / Switch B (or keyboard H).
- Removed the last synchronous `M.land()` call from Gold's airborne interact wrapper; confirm is consumed safely while flying.
- Landing now parks/hides and reuses the Stadium carrier instead of deleting it from the live Gold entity array during the world tick.
- Fixed Visible Surf -> shore restore: stale Surf state is normalized on completed land steps and Character Selector's 3D player becomes eligible immediately.

## v0.3.09
- Fixed the remaining **Cross / A LAND crash**. Controller confirm no longer dismantles the flight/Stadium mount from inside LÖVE's `gamepadpressed` callback. It only queues a landing request there, swallows the confirm so Gold never receives an interact press, and performs the actual safe-landing / mount teardown from the Gen-2 post-world-step compatibility tail after player/entity iteration is finished.
- Keyboard **H** uses the same deferred landing path while already airborne.
- Kept the v0.3.08 direct Stadium flight-mount carrier/rendering behavior unchanged.

## v0.3.08
- Fixed **LAND** on controllers: while Flight owns the overworld, the selected layout's normal confirm button (PlayStation Cross / Xbox A / Switch A) lands directly and is swallowed before Gold can queue an A/interact edge. Landing is available even while the mount is moving.
- Hardened landing/dismount cleanup: movement/interact guards unwind immediately, Stadium mount tags are released safely, and provider/render cleanup errors are contained instead of crashing the game.
- Fixed invisible Stadium flight mounts: AUTO/STADIUM no longer requires a 2D follower sprite to exist before creating the mount. A species-tagged Stadium carrier is created directly from the selected party Pokemon, so an imported Stadium model can render beneath the rider even when the 2D mount-art provider has no matching sheet.
- Updated the mounted HUD hint to show the active controller family's confirm button as LAND.

## v0.3.06
- Grounded normal land followers in the 3D renderer so species whose 2D follower art uses a hover offset (notably Gyarados and other serpentine/levitating sprites) no longer become physically elevated in the voxel world. Genuine ledge hops and water bobbing still keep lift.
- Added simple Fly/Swim progression toggles directly to FLY YOUR POKéMON: REQUIRE FLY MOVE, REQUIRE SURF MOVE, and REQUIRE BADGES.
- Added BATTLE -> STADIUM ATTACK ANIMATIONS (default ON) and gated the imported Stadium skeletal move-performance bridge through it.
- Added UI / MENUS -> FPS COUNTER.
- Added BLOB / FAST shadows and made LOW/MEDIUM performance presets use them. This draws soft contact shadows under actors without rendering the entire world a second time from the sun, cutting a major GPU/CPU cost while avoiding coarse shadow-map artifacts. Existing LOW/HIGH/SOFT real sun-shadow modes remain selectable.

## v0.3.05
- Added **FRAME RATE LIMIT** under PERFORMANCE / GRAPHICS: 30 / 45 / 60 / 90 / 120 / 144 FPS or UNLIMITED. The cap is presentation-only, so Gold's fixed-step gameplay speed, movement and music are unchanged. Default is 60 FPS to avoid wasting voxel CPU/GPU work on high-refresh displays.
- Added **L1/R1 GAME SPEED** under UI / MENUS, default OFF. OFF swallows PlayStation L1/R1 and Xbox/Switch LB/RB before Gen1Recomp's built-in shoulder fast-forward handler; ON restores the original behavior. L2/R2 trigger controls are unaffected.
- Optimized steady voxel rendering without deleting visual features: cooperative terrain meshing now gets one normal build slice per visible frame instead of two, with an emergency second slice only while the current terrain is still cold/missing.
- LOW shadow quality now reuses its real shadow map for alternating presentation frames (30 Hz shadow updates at 60 FPS), cutting roughly half of the moving shadow-pass work while HIGH/SOFT still update every frame and standing scenes remain fully cached.
- **SKY / FAST** water no longer copies the entire rendered scene or re-renders characters into a reflection texture that its shader never samples; **FULL SSR** keeps the complete world-reflection path.
- Added conservative camera culling for off-screen dynamic actors, authored figures and far-neighbor grass/flowers/shadow detail while keeping connected terrain/water residency broader so OPEN WORLD does not expose empty voids.
- Tightened asynchronous mesh-build time slices to reduce route-transition/camera hitching on phones, handhelds and integrated GPUs.
- Preserves v0.3.04 FLY/SWIM party actions, follower spacing and zone-transition fixes, plus the existing controller-layout, F6-camera, render-resolution, battle-background/transparency and animated custom-player systems.

## v0.3.04
- Added **FLY** directly to a supported Pokemon's PARTY action list. It starts free overworld flight on that selected Pokemon instead of opening the vanilla Fly destination map.
- Added **SWIM** directly to supported Surf mounts in the same PARTY action list. It starts Gold's native water movement with that selected Pokemon as the visible mount.
- Fixed seamless-zone follower handoff reusing a stale/out-of-range trailer position and sending a follower to the opposite side of the next map. Invalid convoys now safely respawn under the player and trail back out.
- Added **Player-Follower Gap** and **Pokemon-Pokemon Gap** (1-4 walked tiles) under FOLLOWERS / BEHAVIOR. Spacing follows the player's actual walked path around corners.

## v0.3.02
- Fixed the missing actual Flight control in Mod Settings. **FLY YOUR POKéMON** now begins with **FLY = OFF/ON**; switching it ON mounts an eligible party flyer and enters free-flight gameplay, while OFF performs a safe landing/dismount.
- Added **FLYING POKéMON = AUTO / species** so the player can choose the flying mount directly from Mod Settings instead of relying on the M hotkey.
- H/controller-X Flight activation now mirrors the same persisted Flight switch, and a Flight request made while the settings menu is busy is deferred until gameplay resumes.
- v0.3.01 mount systems and the v0.3.00 battle-transparency/custom-background/custom-player changes remain intact.

## v0.3.01
- Added built-in **Fly Your Pokemon** ownership: Flight, Ground Ride and Visible Surf without loading Dramatic Sky Ride.
- Added the documented 16-flight / 17-ground / 8-surf Gen-1/Gen-2 mount rosters, Fly/Surf + Johto badge gates, outdoor/story/discovery/landing safety, first/third-person continuous free flight, altitude controls, Flight Boost, Ground Gallop, reverse ledges and Suicune amphibious travel.
- Added optional air encounters against this mod's visible roaming Pokemon, rider/follower visibility, mount cries/rumble, flight-music behavior, mount hints/altitude/gallop HUD, 2D-vs-Stadium mount rendering, realistic scale and per-species size overrides.
- Stadium mount entities now use this mod's own Pokemon metadata and whole-model flight/ground/surf motion transforms; active Dramatic Sky Ride compatibility aliases/ownership paths were removed.
- Keeps the v0.3.00 transparent battle UI and all v0.2.98+ custom image/player picker fixes unchanged.

## v0.3.00

- Rebuilt from the verified v0.2.98 baseline after the v0.2.99 packaging regression.
- Fixed **TRANSPARENT BATTLE UI BG** so Gold's opaque shade-0 pixels inside the HP-bar, EXP-bar, and HUD-border tile sheets are alpha-keyed while the option is ON. This removes the remaining white strips behind and below the HP UI without erasing black borders, labels, colored HP/EXP fills, text, sprites, models, or effects.
- Preserves the v0.2.98 custom animated player-sprite system, custom 2D battle-background picker, Android picker isolation, and all other v0.2.98 behavior.

## v0.2.98

- Added **CUSTOM PLAYER SPRITE** plus **PLAYER SPRITE SHEET** under 3D MODELS. The PC/Android/iOS picker accepts PNG/JPEG/BMP and feeds a six-frame animated sheet into Gold's native player `SpriteRenderer` so facing, walk cadence, bike steps, ledge offsets and voxel-card poses stay synchronized.
- Custom player sheets use a vertical six-frame layout: Stand Down, Stand Up, Stand Left, Walk Down, Walk Up, Walk Left. Right is mirrored automatically. PNG alpha is preserved and recommended. The chosen sheet hot-swaps live and a disabled/reset option restores the latest engine-requested normal player sprite.
- Custom-player replacements use fresh revisioned filenames and are validated before commit, so malformed/replaced images cannot resurrect stale PNG textures or destroy the currently working sheet.
- Added **TRANSPARENT BATTLE UI BG** under BATTLE, default ON. It removes opaque white battle-UI paper fills while preserving the actual battle backdrop, borders/text, HP/EXP UI, models/sprites and translucent battle effects. OFF restores Gold's white cartridge-style UI paper.
- Stadium 2 ROM, battle-background and custom-player mobile pickers now mutually yield through feature-specific pending markers around the shared `picked_rom.gb` native staging file.
- Retains the v0.2.97 revisioned custom battle-background fix. No DSM7 rebuild is required.

## v0.2.97

- Fixed custom 2D battle backgrounds getting stuck on a previously selected PNG. Replacements now use a fresh revisioned filename and commit only after the new image decodes successfully.

- Added **2D BATTLE BACKGROUND** under the BATTLE category. **A/Confirm or Right** opens a native PC/Android file picker; **Left** restores Gold's default white battle background.
- Supports custom **PNG, JPEG, and BMP** images copied into the engine save directory, with image signature/size/decoder validation and no permanent arbitrary host-path access.
- Custom images replace only the classic Gold 160x144 battle paper behind native 2D battle sprites. **LIVE OVERWORLD BATTLES** continues to use the captured voxel encounter world and takes priority automatically.
- Android/iOS reuses Gen1Recomp's engine-owned document picker safely. A dedicated pending marker prevents its shared `picked_rom.gb` staging file from ever being mistaken for a Stadium 2 ROM; canceled mobile picks self-clear after the app resumes.

## v0.2.95
- **Kanto now uses the active Johto palette slots, not a Yellow/averaged tint.** The Yellow 2bpp atlas is recolored from the same eight active Gold background palettes using semantic water/grass/ground/door/structure slot mapping.
- **Kanto Pokemon keep Stadium 2 model eligibility even if their generated 2D runtime sheet is missing.** Model-only roaming/authored Pokemon entities remain in the scene and are rescued by the Stadium renderer from their explicit Dex identity.
- **Kanto 3D Character Selector animation/facing fixed.** The visible Kanto proxy temporarily mirrors its px/py, facing, step flip and animation clock onto the original Gold player only during the selector draw/shadow call, then restores the Johto player immediately.
- **FIRST/THIRD PERSON Kanto controls are camera-relative.** Left-stick intent is rotated by the live camera yaw before the final Gen-1 grid-step direction is chosen, fixing forward/back/left/right after orbiting the camera.
- VoxelScene pose capture now carries Kanto visual-moving/animation-distance state so external 3D player skins actually play their walking animation.
- No DSM7 model-cache rebuild is required.

## v0.2.92
- Passed pause-menu layout width to the custom Spotify Stadium renderer so it can size its metadata area correctly.
- Works with Spotify Stadium Edition v0.1.11 for smaller album art plus Artist / Album / Song scrolling text in the bottom-left.

## 0.2.86

- **Major no-feature-cut performance pass.** Added a PC-style `PERFORMANCE PRESET` with LOW / MEDIUM / HIGH / ULTRA / CUSTOM plus individual 3D render resolution, shadow quality, water reflections, world draw distance, Kanto sector prefetch and mesh-build-rate controls. MEDIUM is the new default. Presets only change quality/residency budgets; voxel terrain, Kanto, ocean, NPCs, Pokemon, weather, battles and 3D models remain available.
- **Real internal 3D resolution scaling.** The voxel/depth/weather/water scene now renders at 40/55/75/100% before the existing Gold compose bridge scales it to the window, substantially reducing GPU fill cost on high-DPI/mobile displays without shrinking UI or changing collision/camera coverage.
- **Far-world and actor culling.** OPEN WORLD/Kanto maps well outside the camera no longer consume terrain/grass/water/shadow draw calls; distant Kanto NPCs/Pokemon skip presentation work while their collision/trainer records remain live and stream back automatically. Yellow survey atlases are decoded progressively and capped by draw-distance policy instead of synchronously materializing the entire region at toggle-on.
- **WORLD OCEAN is perimeter-only.** The old giant under-land plane is replaced by four coastline strips around each visible land component. Ocean is no longer drawn under Gold/Kanto land, still fills the sea gap between regions, and an offscreen coastline no longer starts the reflection/depth pass.
- **Kanto Character Selector bridge hardened.** Pallet/Kanto player proxies now pass the original Gold player object to `red_3d_player` / 3D Character Selector while retaining the Kanto pose/coordinates, so imported/renamed/accessory skins remain selector-owned during the Yellow excursion.
- **Pokemon Yellow trainer and Gym battles.** Interacting with authored Yellow trainer objects builds the real Yellow ROM party/levels and launches it through Gold's supported Gen-2 `World:startScriptedBattle` path against the player's Gold party. Brock, Misty, Lt. Surge, Erika, Koga, Sabrina, Blaine and Giovanni are recognized as Gym fights; wins persist in this mod's own save bucket. Generic Yellow trainers work through the same bridge. Plain NPC text may display, but Yellow story/cutscene/progression scripts remain intentionally disabled.
- No Stadium DSM7 model-cache rebuild is required.

## 0.2.84

- Fixed **GEN-1 KANTO REGION** and **PALLET TELEPORT** being inert on Gold. Gen1Recomp's Gen2Compat intentionally aliases a mod-side `require("src.world.Map")` to Gold's Gen-2 Map class; v0.2.83 accidentally used that alias to classify inactive Red/Blue/Yellow map records, so every Gen-1 `OVERWORLD` map was rejected as non-outdoor before the region could render.
- `TwinRegionWorld` now uses a private Gen-1 tile-map adapter for inactive caches, preserving Gen-1 tile IDs, walkable/water/grass/door semantics and connection placement without touching Gold's live Map class.
- Inactive Red/Blue/Yellow cache reads now temporarily clear/restore `CacheFs.prefix` and invoke the engine's idempotent legacy Red-cache migration before probing, preventing `gold/red/...` double-prefix misses and supporting older Red imports.
- **GEN-1 KANTO REGION is now truly independent.** Turning it ON temporarily promotes voxel residency to the full stitched world even when `OPEN WORLD` is OFF. The saved OPEN WORLD preference is not changed.
- **PALLET TELEPORT** uses the corrected same region loader, so it can resolve `PALLET_TOWN` / `REDS_HOUSE_1F`, enter the outdoor Gen-1 excursion and return to the untouched Johto position normally.
- No Stadium model-cache rebuild is required.

## 0.2.83

- Added **PALLET TELEPORT** to Gold's START menu. The destination is resolved from the imported Gen-1 `PALLET_TOWN` map by finding the warp to `REDS_HOUSE_1F`, then choosing a nearby walkable outdoor cell, rather than hard-coding one ROM-specific coordinate.
- While teleported, the Stadium renderer re-roots on the imported Gen-1 outdoor Kanto graph and a presentation-local player proxy can walk its real Gen-1 collision cells and connection seams. Gold's live player/map/save location is never overwritten.
- The START row changes to **RETURN TO JOHTO**, which drops the excursion and immediately reveals the exact Gold location/state left underneath.
- Gold movement and interaction are suppressed while the Kanto excursion is active so the hidden Johto player cannot walk into NPCs/warps from the same directional/A input.
- Exposed `twinRegionWorld`, `teleportToPalletTown`, `returnToJohto`, `togglePalletTeleport`, and `palletTeleportStatus` for companion mods such as Dramatic Sky Ride.
- No Stadium model-cache rebuild is required.

## 0.2.82

- Added **WORLD OCEAN**: an independent toggle that places one reflective low water plane beneath/around the rendered Gold voxel world. It expands to the complete stitched bounds in OPEN WORLD and sits below native map water so rivers/lakes keep their own surfaces.
- Added **GEN-1 KANTO REGION**: an independent OPEN WORLD toggle that auto-detects an already imported Red/Blue/Yellow Gen-1 cache, reconstructs its authentic outdoor cardinal connection graph, namespaces every foreign runtime map id, and places the whole visual region east/right of Gold across a 384-world-pixel ocean gap. Gold remains the collision/script/NPC/warp authority in this first twin-region release.
- Gen-1 terrain uses the inactive cache's real generated tileset atlas when the host can decode cached PNG bytes directly; a semantic true-color atlas is a fail-safe fallback rather than allowing the Gold renderer to fail. Foreign maps share the existing ChunkMesher/VoxelScene/Structures stack instead of installing a competing world pipeline.
- Extended the existing OPEN WORLD ZOOM LIMIT with **TWIN 16X** and **ATLAS 24X** ceilings so the doubled Gold + Gen-1 survey layout can actually fit into a pulled-back diorama view; startup remains 1x and the existing 2.2x/4x/8x/12x choices remain unchanged.
- Updated against current Gen1Recomp `dev` `3588a5f3fe00efffc92ad0ed037a6224f4db55a1`, including its current versioned `CacheFs` layout and Gen-1 cardinal connection placement rules.

## 0.2.81
- **Party leader swaps now replace the visible follower immediately.** Trainer FOLLOW mode is bound to the selected party slot (slot 1 by default) instead of following the old Pokemon fingerprint through a PARTY -> SWITCH reorder. The persistent follower selection is reconciled before trailer/2D/3D/water sprite sync, so the first frame after a party swap uses the new leader.
- **Same-species leader swaps are no longer missed.** Trailer composition now compares the actual party-mon object as well as species, so swapping between two copies of the same species (including shiny/non-shiny copies) rebuilds the follower correctly.
- Keeps v0.2.80 full-color 2D followers, v0.2.79 DSM7 Stadium texture sampling, National Dex ordering, independent Pokemon/player 3D toggles, seamless transitions, Wilds roaming spawns, and Character Selector coexistence. No Stadium model-cache rebuild is required.

## 0.2.80
- **Fixes black-and-white 2D Pokemon followers in Gold.** The embedded Wilds follower provider was still converting the bundled RGBA follower sheets into Gen-1 luminance ramps outside ADVANCED/RED++ mode. Gold is CGB-native and has no later Gen-1 zone recolor pass for those custom entities, so the follower stayed grayscale. v0.2.80 always serves the original full-color Gen-2 follower art.
- **Land, shiny and submerged followers use the same color-safe path.** Normal/shiny land sheets and normal/shiny submerged water sheets all stay `trueColor=true`, including sprite refreshes while entering/leaving water.
- **Party follower icons follow the resolved sprite contract instead of the old RED++ gate.** This prevents the menu icon path from reintroducing the same grayscale behavior. No Stadium DSM cache rebuild is required for this release.
- Keeps v0.2.79 DSM7 eye/mirror sampling, v0.2.78 National Dex ordering and v0.2.77 independent Pokemon/player 3D switches.

## 0.2.79
- **Fixes the remaining one-sided eye/face texture corruption.** Stadium material extraction now reads render-tile `G_SETTILESIZE` in addition to `G_SETTILE`: SL/TL are subtracted from incoming S/T before addressing, SH/TH define the clamp window, and a zero mask forces clamp exactly like the N64 RDP. This targets symmetric/mirrored eye materials where one eye could look correct while the opposite side sampled the wrong texels.
- **DSM7 sampler-window packs.** Each material now gets a texture variant cropped to the effective RDP sampling span, so a smaller N64 mask/clamp window no longer stretches the full decoded image across that span in LOVE. Animated eye textures use the same material window. DSM6 caches are intentionally rebuilt once because they did not retain the tile-size/origin state.
- Keeps v0.2.78 National Dex #001-#251 ordering and all v0.2.77 independent Pokémon/player 3D switches.

## 0.2.78
- **Stadium 2 material/texture extraction is upgraded to DSM6.** Per-primitive N64 render-tile state now survives the ROM build: CI palette bank, S/T wrap vs mirror vs clamp, mask period, coordinate shift, lighting mode and a neutral material tint. This targets the reported texture corruption across Arbok, Clefairy, Parasect, Machoke/Machamp, Dodrio, Grimer/Muk, Shellder, Gastly, Voltorb/Electrode, Koffing/Weezing, Tangela, Jynx, Ditto, Moltres and the listed Gen-2 roster without species-by-species texture hacks.
- **Material display-list parsing is no longer capped at 16 commands.** The extractor follows bounded nested material DLs and uses the final render tile, fixing materials whose CI palette/address state lives later in the list. UVs now honor N64 tile shifts and mask periods before normalization.
- **Untextured Stadium primitives are generalized.** The old Dex-249-only solid-white rescue is now a real neutral material path for every species; unlit vertex-color primitives retain a representative RGBA tint instead of being skipped or misread as surface normals.
- **Custom Pokédex rows are locked to National Dex number order.** The backing `screen.rows` order is #001 through #251, so selection/index/model preview and visible numbers all agree even when Gold's native mode would otherwise be NEW/Johto or A-Z. Native UI OFF keeps Gold's original sort modes untouched.
- **One-time cache rebuild required.** DSM4/DSM5 packs are intentionally rejected because the missing material bits were discarded at extraction time; selecting/retaining the Stadium 2 ROM rebuilds all 251 DSM6 packs once.
- Keeps v0.2.77 independent Pokémon/player model switches and all v0.2.76-and-earlier UI, zoom, follower, roaming-Wilds, voxel and Character Selector fixes.

## 0.2.77
- **3D Pokémon and the human player are now separate switches.** `3D POKéMON MODELS` keeps control of Stadium 2 Pokémon geometry only: roaming/wild Pokémon, followers, live-battle combatants and Pokédex/Party/battle previews.
- **New `3D PLAYER MODEL` option.** ON lets `red_3d_player` / 3D Character Selector render its selected Gold skin inside the voxel scene; OFF forces only the human player back to Gold's 2D trainer card without touching Pokémon models, voxel scenery or OPEN WORLD.
- **All four combinations are supported.** Pokémon ON / Player OFF, Pokémon OFF / Player ON, both ON and both OFF each have independent render and shadow ownership. Existing saved `stadium3dSprites` values remain the Pokémon-model setting, while the new player switch defaults ON for backward-compatible visuals.
- Keeps v0.2.76 custom dialogue/zoom, v0.2.75 Pokédex framing, v0.2.74 battle/follower startup fixes, roaming Wilds and current Character Selector camera coexistence.

## 0.2.76
- **Gold dialogue now matches the custom Stadium UI.** Ordinary `src.render.TextBox` dialogue renders as a bottom-docked translucent navy glass panel with rounded border, responsive modern text, preserved two-line/typewriter paging, and a matching A/B continue hint. `CUSTOM UI / MENUS = OFF` still restores the untouched native Gold textbox.
- **YES/NO prompts receive the same glass treatment.** `src.ui.ChoiceBox` keeps its native selection/answer timing but draws as a compact matching two-row selector, including prompts stacked over dialogue.
- **OPEN WORLD zoom range is now selectable.** New `OPEN WORLD ZOOM LIMIT` choices are STANDARD 2.2X, FAR 4X, WORLD 8X (default), and EXTREME 12X. Startup stays at 1X; wheel/trackpad/pinch simply gain more room to pull back.
- **Native/Character Selector survey zoom can see the whole stitched region too.** While OPEN WORLD is ON and the zoom limit is above STANDARD, the engine's official `zoom.range` hook unlocks one additional sub-1 survey rung; Gen1Recomp's own hard safety floor keeps it at 0.25 scale.
- Keeps v0.2.75 battle-command layout and full Pokédex model framing, v0.2.74 battle/follower startup fixes, roaming Wilds, voxel terrain and Character Selector coexistence.

## 0.2.75
- **Battle command overlay spacing is now collision-free.** The command panel reserves separate header, command-diamond, label/key and footer lanes; PACK/DOWN no longer overlaps the LEFT STICK MOVE / RIGHT STICK CAMERA hint on shorter or wider windows. Icon and font sizing now scale from the panel body instead of independently from the full window height.
- **Pokédex Stadium previews now auto-fit the current animated mesh.** `StadiumRig` exposes read-only posed mesh bounds and `PartyModelPreview` frames from those live bounds after animation/anchoring instead of only bind-pose `worldHeight/worldRadius`.
- **Preview fitting now respects horizontal FOV.** Portrait/tall Pokédex canvases have a narrower horizontal field of view; v0.2.75 computes both horizontal and vertical perspective fits, includes model depth, and aims at the posed mesh centre so wings, tails, heads and feet remain inside the viewer.
- Keeps v0.2.74 automatic battle UI startup + seamless outdoor follower handoff, v0.2.73 moving follower ownership, v0.2.71 roaming-Wilds recovery and v0.2.70 voxel/Character Selector coexistence.

## 0.2.74
- **Battle command UI now appears before it can accept direct input.** The custom Gold battle controller panel is not armed until it has completed a real draw pass, closing the phase-change/render gap where a face button could select FIGHT/PACK/PKMN/RUN while the panel was still invisible.
- **Ordinary battle intros advance to the command panel automatically.** While CUSTOM UI / BATTLE COMMANDS owns a normal Gold fight, only the intro PromptButton pages are auto-confirmed after a short presentation hold. Tutorial/contest flows and every later battle prompt remain native/manual.
- **Held intro buttons can no longer double-fire as commands.** A mapped face button forwarded to Gold to page intro text is latched in the polling fallback until physical release, so the same A/Cross press cannot become PACK after `phase` flips to `menu`.
- **Outdoor follower zone handoffs are now synchronous and seamless.** Gold rebuilds the destination NPC/entity lists before `map.entered`; v0.2.74 reattaches and translates the exact preserved Wilds trailer objects inside that event instead of one update later, eliminating the one-render-frame disappear/reappear flash at connected outdoor map seams.
- Keeps v0.2.73 moving follower ownership, v0.2.71 roaming-Wilds sandbox recovery, v0.2.70 voxel/Character Selector coexistence, Stadium battles and OPEN WORLD.

## 0.2.73
- **Fixes the v0.2.72 follower regression where the remaining follower stopped moving.** The embedded Wilds trailer mover is restored as the authoritative Gold follower for slot #1, so the visible follower uses the same per-frame trail engine that already survives doors, warps, and zone connections.
- **Removes the wrong follower instead of the moving one.** Gold's engine-native `pikachuFollower` is suppressed while embedded Wilds is active, and any stale native copies left by older transitions are removed from both NPC/update and entity/draw lists. Wilds `pokepcTrailer` followers are never touched by that cleanup.
- **Follower count semantics are restored.** `FOLLOWER COUNT = 1` produces one moving Wilds follower; higher counts add the requested additional Wilds followers. Yellow's stock-Pikachu exception remains unchanged in the shared Wilds code.
- **LEAD PARTY FOLLOWER is now a real master gate for the Wilds party trail.** Turning it OFF removes the party trailers instead of only disabling the now-fallback native Gold follower.
- Keeps v0.2.71 roaming-wild sandbox recovery plus v0.2.70 voxel/3D Character Selector coexistence.

## 0.2.72
- **Fixes follower duplication after entering a new map/zone.** Gold's engine-owned `src.world.gen2.Follower` is now the single owner of follower slot #1. The embedded Wilds controller no longer creates a second `party_trailer` for the same selected Pokémon on Gold.
- **Extra followers still work intentionally.** `FOLLOWER COUNT = 1` means one native Gold follower; counts above 1 add only the additional Wilds trailers behind it.
- **Transition cleanup guard.** If an older/racing transition leaves multiple native `pikachuFollower` entities in the live Gold world, the bridge keeps the engine's current/newest follower and removes the orphan copies from both update and draw lists.
- **Follower selection remains live.** The native Gold follower now honors the embedded Wilds active FOLLOW selection when available, falling back to party slot #1 during early boot.
- Keeps v0.2.71 roaming-wild sandbox recovery plus v0.2.70 voxel/3D Character Selector coexistence.

## 0.2.71
- **Restores visible wild Pokémon on current Gen1Recomp sandbox builds.** The embedded Wilds runtime still probed `love.filesystem` while registering its Gen-2 runtime sheets; current sandboxes throw on that access, so Wilds aborted before map initialization and no Pokémon could spawn in grass/bushes.
- **Sandbox-safe Wilds asset discovery.** Runtime sheets, land sprite providers, water sprite reads, sprite resolution, follower submerged checks, and luminance-cache checks now use `mod:read` / `mod:info` plus the engine-owned compatibility filesystem instead of dereferencing blocked `love.filesystem` or raw `io`.
- Keeps v0.2.70 voxel rendering, 3D Character Selector coexistence, Stadium 2 models, OPEN WORLD, wild behavior/battles, water/cave spawns and 2D fallbacks.

## 0.2.70
- **Restores voxel/3D rendering on current Gen1Recomp sandbox builds.** The August 14 engine sandbox throws on direct `love.system` access; both GoldVoxelBridge and GoldComposeBridge still dereferenced it before their old `pcall`, which could retire the renderer before a voxel frame was produced. Platform detection now uses the engine-owned `src.core.Platform` seam first and keeps legacy LÖVE access entirely inside `pcall`.
- **Re-enables the official Gold `render_pipelines.drawWorld` world pass.** Current Gen1Recomp serves the supported Gold pipeline context; `stadium2_gold_voxel` is registered again and `render.compose` remains a live fallback rather than the only renderer.
- **3D Character Selector / `red_3d_player` coexistence is explicit.** Gen1Recomp permits one active world `drawWorld` pipeline, while the selector uses its public `voxel` pipeline levels for ZOOM/1ST/3RD. When the selector is installed this mod intentionally keeps its own drawWorld pipeline OFF and uses the compose path, preserving the selector pipeline while `OverworldStadium` continues drawing the selector's selected skin through `red3dPlayerRenderer:drawVoxel`.
- **Live 3D battle platform detection is sandbox-safe too.** `OverworldBattle` no longer dereferences `love.system` directly when checking iOS, preventing a later battle transition from hitting the same sandbox fault after free-roam voxels recover.
- Keeps v0.2.69 desktop/mobile canvas-exit split, v0.2.67 safe diorama pitch, v0.2.66 live terrain mesher, v0.2.65 sandbox-safe Stadium ROM import, 2D fallback, OPEN WORLD, battles, followers and custom settings/UI.

## 0.2.69
- **Desktop voxel compositor rollback to the confirmed-working v0.2.45 behavior.** v0.2.58 changed all three GPU pass exits — `Voxel3D`, `ShadowMap`, and `AntiAlias` — to restore whichever canvas invoked them. That nesting is required on Android/iOS, but on current desktop Gold the restored intermediate compositor can subsequently present the native 2D scene over the voxel output. Desktop now exits all three passes to the physical window exactly like v0.2.45; mobile retains caller-canvas restoration.
- **Removed the v0.2.68 experimental Gold `drawWorld` handoff from active runtime.** Multiple Windows PCs still remained 2D with that path, so v0.2.69 uses the single proven `render.compose` world owner instead of competing world-renderer paths.
- Keeps v0.2.67's safe 35-degree fresh-install diorama default, v0.2.66's live v0.2.45 terrain mesher, v0.2.65 Stadium ROM import protection, 2D follower fix, settings navigation, custom UI toggle, battles and OPEN WORLD.

## 0.2.68
- **Restores voxel terrain on current desktop Gen1Recomp.** Gold now has an engine-owned `render_pipelines` `drawWorld` world-pass seam; the mod was still relying only on the older `render.compose` replacement path. v0.2.68 registers `stadium2_gold_voxel` as a real Gold world pipeline and activates it automatically whenever `3D VOXEL WORLD` (or OPEN WORLD) is enabled.
- Keeps `render.compose` as a compatibility fallback. Older Gold hosts/Android builds that do not consume `drawWorld` continue using the proven compose renderer. On current hosts the compose bridge detects that the world pipeline already rendered and does not run `VoxelScene` twice.
- Pipeline output is forced to the logical window size expected by Gold's world compositor, while the legacy compose path keeps its existing HiDPI handling. The pipeline returns `nil` on a transient renderer failure so Gen1Recomp can safely fall back to native 2D for that frame instead of crashing.
- Keeps v0.2.67 camera behavior, v0.2.66 live v0.2.45 mesher, v0.2.65 Stadium ROM import compatibility, follower/settings fixes, custom UI, battles and OPEN WORLD.

## 0.2.67
- Fixes desktop/fresh-install voxel world appearing permanently 2D even while `3D VOXEL WORLD` is ON. Gold's own default options set `TILT = OFF` (level 0); v0.2.54+ incorrectly mapped that native OFF value to a literal 0-degree voxel camera. While voxel mode is enabled, native TILT OFF now uses the normal 35-degree diorama pitch. Explicit native TILT 15/35/50 remain 15/35/50. Turning `3D VOXEL WORLD` OFF is still the real native-2D switch.
- Keeps the v0.2.66 live v0.2.45 terrain mesher and the v0.2.65 Stadium ROM import crash protections.
## v0.2.66

- Restored the known-working v0.2.45 live `ChunkMesher` implementation for current/neighbor voxel terrain.
- Removed `VoxelDiskCache` from the live mesher dependency path; persistent disk-cache I/O remains disabled.
- Keeps v0.2.65 Stadium ROM import compatibility and all later UI/follower/settings/Open World features.

## v0.2.66
- **Fixed Stadium ROM import crash on current Gen1Recomp:** current mod sandboxes reject direct `love.system`, `love.filesystem`, and raw `io` access. The Stadium picker/import pipeline now routes platform detection through engine `Platform`, persistence through `SaveData.persistenceFs`, and desktop process/file staging through engine `HostShell`.
- **Android/iOS picker is engine-owned:** the mod no longer calls the blocked native picker itself. It asks Gen1Recomp's `RomImporter` to open the platform document picker, watches the engine-delivered `picked_rom.gb`, validates N64 byte-order magic, and feeds the bytes directly to the Stadium 2 importer. The picked N64 ROM is never sent through the Game Boy extraction pipeline by this mod.
- **Desktop import is sandbox-safe too:** `.z64/.n64/.v64` file dialogs run through engine `HostShell`; the selected absolute path is copied into a temporary save-directory staging file and read through the engine persistence filesystem, with no mod `io.open`.
- Stadium install/cache-pack/debug-file I/O now shares the same engine persistence seam. Picker, file-read, importer, and loading-screen transitions are guarded so an unavailable platform service reports failure instead of crashing Gold.
- Keeps all v0.2.64 boot-recovery protections, the disk-cache quarantine, v0.2.61 2D follower/settings-navigation fixes, CUSTOM UI toggle, OPEN WORLD, and current Stadium 2 renderer.

## v0.2.64
- **Boot recovery:** v0.2.45 was confirmed to boot on the same install while later builds crashed at Play, so all post-v0.2.45 optional presentation/settings installers are now guarded. A broken optional helper logs and disables itself instead of aborting Gold's boot.
- **Settings persistence narrowed:** removes the v0.2.55/v0.2.56 global `ManagerState:persistOptions` override. Only this mod's changed option key is mirrored to the loader's top-level `modOptions` bucket; other mods, profiles, enable/disable state, and Gold's option table are left engine-owned.
- **Android flip boot isolation:** the whole-frame `Game2:draw` wrapper is installed only when the engine reports Android. Desktop boots no longer receive an Android-only Game2 monkey patch, and platform detection is protected against sandboxed `love.system` access.
- **Voxel disk-cache quarantine:** persistent disk-cache reads/writes are disabled for this recovery release after the cache was reproduced causing incomplete/misaligned world visuals. The normal in-memory `ChunkMesher` cache still works and OPEN WORLD remains available.
- Keeps the v0.2.61 species-correct 2D followers, categorized settings with cursor return, custom/native UI toggle, and existing battle/3D systems.

## v0.2.62
- Fixed the remaining 3D Pokémon viewer clipping at its source: PartyModelPreview now measures the **current skinned animation pose** and frames the camera from those real vertex bounds instead of relying on bind-pose `worldHeight/worldRadius`.
- The preview camera centers on the actual posed model and fits both horizontal and vertical FOV with a safety margin, so flying/tall Pokémon such as Pidgey stay completely visible without simply shrinking them or moving the UI panel again.
- The same posed-bounds framing is shared by Pokédex, Party/Summary and battle selection previews. v0.2.61's 2D follower and settings-folder return fixes are retained.

## v0.2.61
- Fixed Gold's 2D party follower fallback: the engine-owned follower starts from a Charmander placeholder registered for content-freeze safety, but is now rebound after spawn to the actual lead Pokémon's bundled normal/shiny follower sheet. This specifically fixes **3D POKéMON / SPRITES = OFF** users seeing every follower as Charmander.
- Made the Pokédex 3D preview panel dramatically taller by moving its top edge upward while preserving the v0.2.59 close model framing and the existing panel width.
- Categorized MOD SETTINGS now remembers the root category cursor and scroll position; B/Circle from a category returns to the folder that was just opened instead of jumping to the top.

## v0.2.60
- Added **CUSTOM UI / MENUS** in Mod Settings. ON keeps the Stadium-style pause, Gold submenu, Mod Manager and live-battle UI. OFF yields those screens and battle input back to Gold/Gen1Recomp's native menu renderers while keeping voxel/Open World/weather/model features active.
- CUSTOM UI is live: menu draw/input ownership checks the option at runtime. The direct MOD SETTINGS pause shortcut hides while native UI is selected; use MODS -> this mod -> OPTIONS to turn it back on.
- The custom Pokédex model viewer keeps the same width but is substantially taller, preserving v0.2.59's larger full-model camera framing.

## v0.2.59
- Retuned the shared Stadium 2 UI preview camera so Pokémon are significantly larger again without cutting off the top/bottom of the model.
- Keeps the larger internal render canvas from v0.2.58, but replaces the excessive camera pull-back with tighter framing and a higher look target that shifts tall/flying Pokémon downward inside the same viewer box.
- Applies to Pokédex, Party/Summary and battle PKMN/item-target previews. UI box sizes are unchanged.
- Retains v0.2.58 disk-cache safety and Android whole-frame 180-degree flip fixes.

## v0.2.58
- Disk-cache safety: persistent FULL meshes are never used as the authoritative current/collision map. Cache remains active for far OPEN WORLD maps; entering one drops the disk copy and rebuilds it from live map data. New `g2vx-058-r1` / VXM2 cache revision rejects old and incomplete entries.
- Android 180-degree gameplay fix: Voxel3D, ShadowMap and AntiAlias now restore the canvas that invoked them. The full-frame flip can therefore capture voxel gameplay instead of rotating a black canvas while the world escaped to the physical screen.
- 3D preview framing: PartyModelPreview supports internal overscan options, renders at higher internal resolution, increases camera safety bounds, and the Pokédex requests extra vertical framing so animated models are not cut off.

## v0.2.55
- Added **VOXEL DISK CACHE** (default ON). FULL voxel terrain/water meshes are written to a versioned save-folder cache after their first build. On later launches, OPEN WORLD can upload those cached vertex streams directly instead of rerunning Structures + terrain meshing for every map. Small grass/flower/furniture auxiliary meshes still warm in the background. Best-effort cache caps are ~1 GiB mobile / ~3 GiB desktop with old entries pruned.
- Fixed Gen-2 MOD SETTINGS persistence: ManagerState writes are now bridged to Game2's real `persistOptions()` writer, so this mod's toggles/choices survive restart instead of only changing the live session.
- Added Stadium 2 **3D Pokédex previews** to the custom POKéDEX list and entry pages. Moving the cursor changes the live model; unseen species remain hidden, the 3D POKéMON / SPRITES toggle is respected, and missing model packs fall back safely.
- Keeps v0.2.54 native OPTIONS TILT behavior and live voxel-overworld pause-menu backdrops unchanged.

## v0.2.54
- Gold/Recomp's real `OPTION -> TILT` row now controls the voxel DIORAMA camera pitch directly: OFF=0°, then 15° / 35° / 50°. The duplicate mod-level DIORAMA TILT row was removed so there is one authoritative tilt control.
- Pause-launched custom OPTIONS, POKéDEX, POKéMON, PACK, POKéGEAR, Trainer Card/AJ and SAVE screens now force the same live voxel-overworld backdrop path used by MOD SETTINGS instead of inheriting Gold's black/full-screen widescreen surround.
- Changing native TILT while OPTIONS is open updates the 3D world behind the glass panel, making pitch changes visually distinct from ZOOM distance changes.
- Existing Open World, 3D POKéMON / SPRITES toggle, battle shortcut safety/remapping, direct MOD SETTINGS pause row and Android features remain intact.

## v0.2.52
- Adds **MOD SETTINGS** directly to Gold's main pause menu immediately underneath **OPTION**.
- Selecting it jumps straight into this mod's existing Mod Manager options page; it does not create a second settings system.
- The matching Stadium/glass Mod Options presentation is preserved, and B returns directly to the pause menu instead of detouring through MODS -> mod detail.

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

## v0.2.48
- OPEN WORLD void-fill fix: stitched outdoor apron gaps that still appeared as white rectangular holes are now backfilled with nearby round-tree border art, so those blank areas render as matching forest instead of open void.
- Keeps the same open-world + voxel/3D renderer combination from v0.2.47; this only changes how unfilled outdoor edge gaps are synthesized.

# Changelog

## 0.2.47
- Reworks OPEN WORLD into a true combined open-world + voxel/3D renderer. `OPEN WORLD = ON` now keeps the voxel provider active even if an older save has the separate voxel toggle off, preventing the stitched native-2D overview seen in v0.2.46.
- Every connected map is requested as a **full** voxel mesh in OPEN WORLD, not a body-only neighbour mesh. Each map masks its own cardinal seams while preserving the normal 32-tile outside voxel apron, so a world-scale camera does not reveal empty sky/void around the connected region.
- Distant maps warm incrementally. Only maps with drawable terrain participate in figures, grass, flowers, shadows and terrain passes; a map still building or a bad far-map atlas can no longer crash the entire VoxelScene and force Gold's flat renderer for the frame.
- Adds static-atlas fallback per distant map if animated atlas creation fails. The current map and every healthy loaded map stay fully 3D.
- OPEN WORLD OFF still returns to the original current-map + direct-neighbour streaming residency and releases far meshes.

## 0.2.46
- Fixes the v0.2.45 OPEN WORLD runtime regression that could drop the Gold voxel renderer into its flat fallback. The direct-neighbour urgency helper was accidentally removed while the open-world graph still called it; this is restored and regression-tested.
- OPEN WORLD now explicitly extends the same existing VoxelScene instead of replacing it: current-map voxel terrain, 3D trees/buildings/props, tall grass/flowers, native NPCs, visible roaming Pokemon and Stadium models all stay active while connected maps are kept resident.
- Fixes the live OPEN WORLD toggle path. Mod Manager option changes immediately invalidate the connected-map/adapted-map caches; OFF then returns to the original current-map + direct-neighbour residency set and forces far mesh cleanup through the existing VoxelScene live-set transition.
- Diagnostics now report `openWorldMaps = 0` when the option is OFF instead of counting normal streaming neighbours as open-world residency.

## 0.2.45
- Adds **OPEN WORLD** to this mod's Options, default **OFF**.
- OFF preserves the existing performance-friendly voxel residency model: current map plus only directly connected cardinal neighbours.
- ON breadth-first traverses Gold's entire cardinal connection graph from the current map, solves every connected map into one shared coordinate space, queues every far map as a cooperative background voxel build, keeps completed meshes/animated atlases resident, and draws the connected region as one continuous world. Warp-only interiors/buildings are intentionally not glued into the outdoor plane.
- Direct destinations remain the only urgent build jobs, so turning OPEN WORLD on cannot starve the map under the player while the farther region loads.
- Turning OPEN WORLD back OFF shrinks the live set immediately; `ChunkMesher` releases far GPU/CPU meshes and the bridge drops its adapted far-map wrappers.
- Current-map border masks and third-person collision still inspect only first-ring neighbours, preventing the full region size from multiplying per-tile mesh work or camera collision scans.
- Adds OPEN WORLD diagnostics to `voxelStatus()` (`openWorldMaps`, loaded/pending counts, graph root/builds/fallbacks). A graph-build failure safely falls back to normal direct-neighbour streaming for that frame.

## 0.2.44
- Changes **BATTLE COMMANDS** from a visibility-only toggle into a full battle-UI mode switch.
- **ON** keeps the custom Stadium battle HUD, command diamond, move selector and custom live-battle PKMN/PACK overlays.
- **OFF** makes `BattleControllerUI` relinquish both render ownership and its battle-input interception, so `GoldComposeBridge` falls through to Gold's original Gen-2 battle canvas and native menu controls.
- Toggling OFF while a custom battle selector is open clears/releases that temporary overlay safely before Gold resumes ownership.

## 0.2.42
- Fixed the 3D party presentation on Gen1Recomp v0.1.83 by making `Gen2PartyMenu` and `Gen2SummaryMenu` use the custom party skin directly instead of relying on pause-stack constructor timing.
- Added the animated Stadium 2 model preview to the custom live-battle `PKMN` selector and battle item-target party selector.
- Added Voxel3D scene-state snapshot/restore support so temporary party preview canvases do not clobber the active overworld/battle renderer state.
- The party preview now keeps its currently selected Stadium pack hot while open and releases the temporary actor when the battle overlay closes.

## 0.2.41

- Upgrades the pause-launched custom **POKéMON party screen** with a live animated Stadium 2 model preview for the currently highlighted party member.
- Extends the same 3D presentation into **STATS / Summary**: status/EXP, held item + moves, trainer/base stats, and move-detail pages use the custom glass UI while the selected Stadium 2 model remains visible.
- The selected model plays its imported idle animation and performs a slow showroom turn while the right-side party list remains fully usable. Static-safe Stadium 2 meshes are accepted for this UI preview even when a species has no trusted idle clip.
- Adds a matching left-side model card with species/Dex identity, level, HP, status and a large HP bar; Eggs and unavailable model packs get a clean in-theme fallback instead of a broken/blank viewport.
- Keeps all PartyMenu behavior engine-owned: switching, STATS, MOVE, ITEM/MAIL, field moves, item targeting and battle-created party screens are unchanged. Only pause-scoped presentation receives the 3D preview.
- Adds `lib/PartyModelPreview.lua`, which renders the selected model into its own transparent Voxel3D canvas and restores the caller's render target/camera state after every preview frame. The preview rig is released when the party screen closes.

## 0.2.40

- Replaces the pause-launched Mod Manager presentation with the same Stadium battle-style glass UI used by the custom START, PACK and POKéMON menus.
- MODS -> installed mod -> detail -> OPTIONS is now a real matching submenu chain, including all mods that expose Gen1Recomp `options_schema` rows.
- Restyles Mod Manager profiles, permissions, errors, apply/restart and confirm/notice overlays without replacing any manager actions or persistence logic.
- Adds a conservative pause-chain auto-skin bridge for third-party list-like screens pushed by mod-injected START-menu rows; bespoke/unrecognized renderers fall back to their native draw path.
- Fixes the stale `modOptionsBattleStyle` export so it now points at the active all-mod menu skin instead of an undefined old module name.

## 0.2.39

- The custom Stadium-style Gold pause panel now grows vertically to show the full ordinary START-menu row set at once. The common eight-row POKéDEX / POKéMON / PACK / PokéGEAR / player / injected-row / SAVE / OPTION layout no longer uses the old four-row scrolling window. If another mod injects more rows than the physical screen can fit, the renderer falls back to a readable cursor-following window.
- Added `lib/GoldSubmenuBattleStyle.lua`. When Gold opens a built-in screen directly from `src.ui.gen2.StartMenu`, POKéDEX, POKéMON, PACK, PokéGEAR, Trainer Card, SAVE and OPTION now use the same custom translucent navy glass / rounded row / white selected-outline language as the mod's custom battle PACK/PKMN selectors.
- The submenu patch is presentation-only and pause-scoped: Gold still owns Party/Pack actions, Pokegear calls/radio/map state, Pokedex state, Save writes and Options persistence. The same classes opened from battles, field-item scripts, Fly and other engine flows keep their native presentation.
- Party and PACK action submenus, PACK throw/yes-no overlays, Pokegear phone actions, Pokedex entry actions and Save confirmation are also drawn with matching custom selector panels.
- Pause-launched modern submenus are transparent overlays so the voxel overworld stays visible behind them; the hidden underlying START panel is suppressed while a submenu is on top.
- Hook-injected START rows such as MOUNTS remain supported by the pause list. Their own external screen is left to the mod that owns that row because this package cannot safely assume another mod's private submenu structure.

## 0.2.38

- Fixed the pause-menu target again: v0.2.38 patches **`src.ui.gen2.StartMenu`**, which is the actual Gold menu shown in-game with POKéDEX / POKéMON / PACK / PokéGEAR / player / MOUNTS or mod-hook rows / SAVE / OPTION. v0.2.37 had incorrectly wrapped the Gen-1 `src.ui.StartMenu`, so Gold could still show its original white menu.
- The replacement now deliberately copies the **custom battle selectors made by this mod**, not Gold's original battle UI: identical dark translucent panel color, white outline, four-row selector geometry, row fill/highlight values, title/meta sizing, and battle-selector footer treatment from `BattleControllerUI`.
- Gold's MENU ACCOUNT description remains visible as a matching battle-message panel on the left. Quit confirmation is also rendered in the same custom selector style.
- Gold still owns unlocking, item ordering, `ui.start_menu.items` hook rows, cursor state, navigation, selection, sounds, save/options actions and Start/B closing; only `StartMenu:draw()` is replaced, with native drawing retained as an error fallback.

## 0.2.37

- Corrected the v0.2.36 UI target: the **in-game START / pause menu** is now the menu replaced with the modern Stadium battle-style presentation.
- The pause menu keeps Gen1Recomp's native `StartMenu`/`Menu` behavior underneath, including POKéDEX/POKéMON/ITEM/player card/SAVE/OPTION/LINK/MODS/QUIT actions, cursor persistence, scrolling, sounds, mod-inserted rows, and B/START close behavior.
- The modern pause renderer uses the same dark translucent rounded panels, white hairline borders, highlighted rows and full-window presentation as this mod's live battle command/selectors, while leaving the voxel world visible behind a light dim veil.
- Safari Zone step and Safari Ball counters are preserved in the modern pause-menu header.
- Removed the v0.2.36 custom Mod Manager Options-page skin; Mod Settings are back to Gen1Recomp's normal presentation. The **ANDROID CAMERA SLIDER** and **FLIP SCREEN 180 DEGREES** options themselves remain.

## 0.2.36

- Added **ANDROID CAMERA SLIDER** to the mod settings. OFF removes the DIORAMA/3RD/1ST bar and its touch capture, so that top-screen area is usable by normal look/pinch input.
- Added **FLIP SCREEN 180 DEGREES** for Android reverse-landscape use. The transform wraps the final `render.compose` chain so the voxel world, battle HUD, Gold menus, and 2D fallbacks rotate together.
- Replaced this mod's stock tiny Mod Manager Options renderer with the same dark rounded translucent panel/list language used by the v0.2.35 Stadium battle UI while retaining Gen1Recomp's normal option navigation and persistence.

# v0.2.35 — Stadium-style PKMN / PACK battle selectors

- Replaces Gold's full-screen battle PKMN menu with a Stadium-style four-row scrolling glass selector drawn directly over the live 3D battlefield.
- Replaces Gold's full-screen Battle Pack with the same custom list language: four visible item rows, scrolling, quantities, pocket labels and disabled-in-battle marking.
- Party-target items (heals, status cures, Revives, Ether/Elixer family) stay in the custom HUD. Single-move PP items get a matching four-move target selector.
- Valid Pokémon switches still call Gold `BattleState:submit({kind="switch"})`; items still use Gold `useItem` / `applyPartyItem`, so battle rules, inventory consumption, catch logic and turn costs remain upstream-owned.
- FIGHT and RUN keep the proven native A-dispatch path from v0.2.34.
- Matching upstream snapshot: `bryanthaboi/gen1recomp` `dev` commit `f6a035947f7593baad6a9afca3b1157bfc76004a` (2026-08-13).

# v0.2.34 — native battle-command dispatch for PACK / PKMN

- Square/FIGHT, Circle/RUN, Cross/PACK and Triangle/PKMN now select Gold's native 2x2 battle-menu cursor slot and enqueue one synthetic Game Boy A edge instead of re-implementing command behavior inside the mod.
- PACK and PKMN therefore execute through current Gen1Recomp `src/ui/gen2/BattleState.lua` itself, which owns `Screens.push(..., "Gen2PackMenu")` and `Screens.push(..., "Gen2PartyMenu")`.
- The replacement controller HUD now returns `false` from `BattleControllerUI.owns()` during `phase == "submenu"`, so a pushed native Pack/Party screen cannot be covered by the scene HUD.
- Matching upstream target checked against `bryanthaboi/gen1recomp` `dev` head `941181d31c817525e690bd771649be19f70f1319`; the only change since the previous checked head was launcher/save/mod-target work, not Gen-2 battle input/menu files.

# v0.2.33 — Triangle/Y PKMN battle shortcut fix

- Fixes Triangle / Xbox Y doing nothing on the live 3D battle command screen.
- BattleControllerUI now resolves input against the exact `OverworldBattle.battle()` BattleState when `Game2.stack:top()` is not the battle screen, matching the reliable scene-HUD lookup introduced in v0.2.32.
- Once Gold pushes the native party or item submenu (`phase == "submenu"`), the mod immediately releases input ownership so normal party/item D-pad, stick and A/B controls work unchanged.
- Adds a retained `lastShortcutError` diagnostic instead of silently losing a shortcut exception inside `pcall`.
- Targeted against `bryanthaboi/gen1recomp` `dev` at commit `9ceb1a8940a553cefdab5333ee817877bf1c1538` (2026-08-13).

# v0.2.32 — HUD on the actual scene canvas + low ledges preserved

- Moves the full controller-native battle HUD into the live `VoxelScene.render()` canvas immediately before `endScene()`. If the 3D battle world/Pokemon are visible, the replacement HP panels, messages, command diamond, and move panel now share that guaranteed visible canvas.
- GoldComposeBridge detects that the scene already owns the HUD and no longer double-draws it; the older compositor/native UI paths remain only as fail-open fallbacks.
- Keeps the face-button controls: Square/Xbox X FIGHT, Circle/B RUN, Cross/A PACK, Triangle/Y PKMN; left stick moves the Pokemon and right stick controls the live battle camera.
- Raises the live battle obstruction cutout floor from 2.5 to 8.5 world units so low jump ledges, border fences, curbs and short retaining edges remain visible. Only taller blocking geometry is eligible for clearing.
- Retains the v0.2.31 Lugia safeguards, Stadium rendering, battle effects, capture systems and open-world work.

# v0.2.32

- Restores the controller-layout battle command UI in the full live-3D battle replacement.
- Resolves the HUD against the exact `OverworldBattle.battle()` BattleState that VoxelScene is rendering instead of relying only on `Game2.stack:top()`.
- Makes the BATTLE COMMANDS panel larger and more obvious, with Square/Fight, Circle/Run, Cross/Pack and Triangle/PKMN laid out like the controller face.
- Keeps the command panel visible across Gold's brief `resolving -> menu` fixed-step seam so it cannot blink/disappear while the battle is waiting for input. Inputs still activate only in the real `menu` phase.
- PACK/PKMN and other pushed screens remain native and are not covered by the replacement HUD.
- Retains v0.2.30 live VoxelScene tree/bush/wall obstruction clearing, direct Pokemon movement, right-stick battle camera, Lugia safeguards and Stadium battle work.

# v0.2.29

- Fixed battle input ownership at `src.core.Input`, where Gen1Recomp actually converts the analog left stick into GB D-pad directions. During normal live 3D battles the analog left stick is now swallowed from native menu input and remains available to direct Pokemon locomotion.
- Controller face commands now intercept the physical SDL buttons before GamepadMap converts them into GB A/B: Square/Xbox X = FIGHT, Circle/B = RUN, Cross/A = PACK, Triangle/Y = PKMN. Matching releases are swallowed safely after phase changes.
- Added frame-level physical face-button polling as a fallback for controller stacks/wrappers that miss `gamepadpressed`.
- WASD is reserved for direct Pokemon locomotion during the live battle screen; arrow keys remain the PC controller-diamond command shortcuts.
- Right-stick camera control is now polled inside `BattleCinematic.frame`, the exact camera producing the visible Gold live-battle shot, eliminating the previous unreachable `CamControl.tick` path.
- Retains v0.2.28 battle occlusion dissolve, controller UI, trainer-battle support, 3D effects, direct Pokemon control and all Lugia body/root-motion safeguards.

# v0.2.28

- Added a smart battle-visibility dissolve: tall terrain fragments in either camera-to-Pokemon sight corridor, plus a softer combat bubble, are dither-discarded while the ground remains solid. This keeps encounter-site scenery without letting trees/walls/shrubs hide the fight.
- Replaced the native four-command box in live 3D battle menu phase with a controller-diamond overlay and restores the 3D world underneath the old opaque command/text region before drawing it.
- Controller main-menu shortcuts: Square/Xbox X = FIGHT, Circle/Xbox B = RUN, Cross/Xbox A = PACK, Triangle/Xbox Y = PKMN.
- PC arrow-key shortcuts mirror the same diamond: Left = FIGHT, Right = RUN, Down = PACK, Up = PKMN.
- Added WASD movement for the directly controlled Pokemon while preserving left-stick movement.
- Fixed live-battle right-stick camera control: axes now feed `BattleCinematic.manualLook`, the camera that actually renders Gold live-world battles, instead of the legacy `BattleCam` state.
- Square manual Stadium clip polling no longer steals the command menu or move list; those phases keep their UI/confirm ownership.
- Gold remains authoritative for turns, move legality, HP, switching, items and outcomes.

# v0.2.27

- Added direct control of the player's active Stadium 2 Pokemon during Gold live-world battles.
- Left stick moves the 3D Pokemon camera-relative inside a bounded battle arena.
- PlayStation Square / Xbox X (SDL gamepad `x`) triggers real imported Stadium 2 skeletal attack performances. Repeated presses cycle safe non-idle clips for the current species.
- The battle camera treats direct-control mode as player-active and follows the controlled Pokemon.
- Direct movement is presentation-only: Gold remains authoritative for HP, turns, moves, switching, items, catches and battle outcomes.
- Control waits until the player's 3D Pokemon has completed its entrance and is actually visible; trainer intro/tutorial/faint states are not hijacked.
- Lugia retains the v0.2.22 untextured-body material fix and v0.2.26 attack-root pinning/safe-clip exclusions.

# v0.2.26 — Lugia world-space attack root lock

- Fixed Lugia still flying across the screen during Aeroblast even after excluding the two most extreme imported Stadium 2 clips.
- The problem is stage/root motion rather than the now-correct Lugia mesh: Stadium authored the performance for a camera that follows Lugia, while the Gen1Recomp live battle camera is fixed in the overworld.
- During Dex 249 attack states only, the runtime now pins Lugia's torso/root node (diagnostic bone[2], runtime bone #3) to the exact position that node occupies in the bind pose.
- The correction translates the entire posed skeleton by one shared delta, so the imported Stadium clip still animates Lugia's rotations, wings, neck, tail, eyes, and local body motion; only bulk travel across the stage is removed.
- Normal idle/entrance/hit/faint anchoring is unchanged, and no other species uses the new exact torso pin.
- No DSM/cache format change and no Stadium 2 ROM re-import are required.
- Retains v0.2.24's fail-open 3D attack-effect bridge, v0.2.23 trainer-battle support/Horde removal, and the v0.2.22 original Lugia body/material fix.

# v0.2.25 — restore visible attacks + reliable Gold→Stadium move bridge

- Fixed the v0.2.23 regression where Gold's native OBJ attack sprites could be suppressed even when the world-space 3D effect never became visible.
- Gold move identifiers are now resolved through the live Gen-2 Battle object to the move definition's numeric `index` before selecting a Stadium 2 skeletal clip. Symbolic keys such as `FLAMETHROWER` no longer fall through the numeric selector.
- Stadium 2 skeletal attacks use their own per-move token instead of depending on the lifetime/identity of Gold's `AnimRunner`, so a runner swap to the damage/after-animation cannot cancel the 3D Pokémon motion.
- World-space 3D move effects are latched for a short presentation window independent of `AnimRunner` replacement. The adapter carries the already-resolved move definition rather than guessing how `game.data.moves` is keyed.
- Gold's original OBJ/sprite move layer is now **fail-open**: it remains visible until the matching 3D effect has issued real world-space draw calls for two frames. If the 3D renderer is unavailable, late, or throws, Gold's original attack effect remains instead of producing a blank attack.
- Retains v0.2.23 trainer-battle live 3D staging and Horde-code removal, plus the working v0.2.22 original Stadium 2 Lugia body/material fix.
- No Stadium 2 ROM re-import is required.

# v0.2.21

- Added a **Dex-249-only Stadium 2 diagnostic exporter**. It is side-band and does not alter normal model extraction, DSM bytes, rigging, or rendering for any Pokemon.
- Re-importing Stadium 2 now writes `cache/stadium/lugia_debug/249_geo_dump.txt`, containing Lugia's raw geo-layout command walk, graph/call depth, joint flags, static transform nodes, local display-list transforms, material references, attachment tags, display-list vertex/triangle summaries, extracted bone table, and primitive skin ownership/bounds.
- The same import also copies the generated Lugia pack to `cache/stadium/lugia_debug/249.dsm` and writes `UPLOAD_THESE_TWO_FILES.txt` with the save-directory location.
- The v0.2.20 procedural 3D Lugia remains the runtime safety model while the original Stadium 2 Dex-249 model is diagnosed. The shared Stadium importer/rig path is intentionally unchanged.

## v0.2.16 — exact Stadium joint transform flags / Lugia rebuild

## 0.2.20

- Changed strategy for Lugia completely: Dex 249 no longer loads the repeatedly broken Stadium 2 `249.dsm` hierarchy.
- Added `lib/LugiaRescue.lua`, an isolated procedural 3D Lugia with a pale body, broad hand-like wings/fingers, long tail, blue dorsal plates, eyes/irises, legs/feet, world-space depth and real shadow casting.
- Added simple procedural Lugia idle, entrance, attack, hit and faint motion so the rescue model is not a frozen prop in battle.
- Kept the entire v0.2.19 Stadium importer/cache/rig path unchanged for Dex 1-248 and 250-251. The Lugia rescue path never calls `StadiumPack.load(249)`, so future Dex-249 work cannot corrupt or invalidate the rest of the roster.
- Kept the species-correct 2D Lugia card only as a final GPU/mesh-construction fallback if the procedural 3D rescue rig itself cannot be created.
- No Stadium 2 ROM re-import is required for this release.

- Replaced the Dex-249 compactness/hierarchy guessing with a format-level fix.
- New `DSM5` packs preserve geo command `0x1D`'s raw joint flags for every bone.
- Runtime pose code now follows the source renderer's mixed transform modes: the separate accumulated-scale stack for mode 0 and full local TRS matrix propagation for mode 1. Camera-facing mode bits remain attached and use a stable world-space fallback basis.
- Offline bind/stance measurement uses the same flag-aware transform rules, so Lugia's height/floor/radius are measured from the same assembly that is rendered.
- Old `DSM4` caches are intentionally invalidated. Re-import the user-supplied Stadium 2 ROM once to rebuild `DSM5`; this is required because DSM4 did not contain the missing flags and they cannot be recovered from that cache.
- Retains v0.2.15's harder strength-scaled Poké Ball aiming and stricter throw grades.

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
