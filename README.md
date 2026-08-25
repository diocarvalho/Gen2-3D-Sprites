## v0.4.33 — First-class Pokemon Crystal compatibility

Current Gen1Recomp now supports **Pokemon Crystal** as a sixth game. Crystal remains Generation 2, but upstream gives it its own `crystal` engine lineage and its own ROM/cache/save identity rather than treating it as Gold/Silver data. This mod now follows that distinction directly.

- Gold, Silver, and Crystal all pass the same generation-2 runtime gate.
- Mobile native file-picker routing follows the active edition, including Crystal.
- Persistent voxel sector meshes are stored under separate `gold/`, `silver/`, and `crystal/` cache namespaces so identically named maps cannot overwrite each other's prebuilt mesh files.
- Runtime exports report the active host version and Gen-2 engine lineage for compatibility diagnostics.
- Crystal's live Gen-2 player sprite path remains authoritative, so the voxel card follows the engine-selected Chris/Kris sprite rather than hard-coding a Gold trainer asset.
- Crystal's MYSTICALMAN/Eusine class is included in the Stadium announcer's boss/trainer scope.
- v0.4.32 Kanto OPEN WORLD / WORLD OCEAN, v0.4.31 sector preloading, the modern phone/PC settings UI, and all prior voxel optimizations remain intact.

Version: v0.4.33

## v0.4.31 — Persistent sector preloading

This release extends the voxel persistent-cache warmer beyond Kanto. Nearby prepared **Johto sectors are now derived into the disk cache before the player reaches them**, prioritizing direct connections and then progressively warming farther sectors already present in the active connection radius. The preload jobs build BODY geometry without creating resident GPU meshes, so future crossings/revisits can restore cached vertex data instead of rerunning the expensive terrain derivation.

The queue is deliberately bounded: desktop can keep several sectors cooking ahead, while Android/iOS keeps only one or two background sectors pending depending on build mode. During visible gameplay, cache-only jobs use the tiny interactive slice so preload work does not take the full idle build budget away from movement. Kanto retains its existing dedicated whole-region cache cooker.

Version: v0.4.31

## v0.4.25 — Pidgeotto flight-safe animation loop

Pidgeotto's overworld flight now uses only **non-combat Stadium animation contexts**. The previous motion-scoring fix searched every authored clip and could select a battle attack simply because attacks contain the strongest skeletal motion. v0.4.25 removes that full-animation scan.

Dex 17 now evaluates only `idle_alt`, `idle_return`, and `entrance_alt`, rejects any candidate that resolves to the same animation index as an attack/struggle/faint/flinch/reaction context, and also rejects combat-labelled clips. If a compatible cache has no distinct safe alternate, Pidgeotto falls back to its ordinary idle rather than ever looping an attack in the sky. Airborne playback is restored to the authored 1.0× cadence.

The v0.4.24 PC/phone icon-grid Mod Settings UI, announcer changes, denser Kanto wilds/flyers, and voxel optimizations are retained.

Version: v0.4.25

## v0.4.24 — Restored Mod Settings app grid on PC and phones

The **MOD SETTINGS icon app grid is restored as the permanent primary root UI**. v0.4.23's crash guard could replace the entire grid with Gen1Recomp's native flat options list whenever any custom drawing call failed, which made the icon homescreen appear to have been removed. v0.4.24 no longer does that.

The normal glass grid remains the first renderer. If a PC/mobile LÖVE backend rejects a cosmetic graphics operation, the menu now switches to a deliberately simple **compatibility icon grid** that keeps the same category rows, supplied PNG artwork, focus, D-pad navigation, and phone tap hitboxes. It does **not** rebuild into the old flat list. The portable `push()` fix, responsive **5×3 landscape / 3×5 portrait** phone layout, direct `input.pointer` icon taps, and touch BACK support from v0.4.23 are retained.

The Pidgeotto airborne-animation fix, Stadium announcer changes, denser Kanto wilds/flyers, borderless enlarged icons, and voxel performance work are unchanged.

Version: v0.4.24

## v0.4.23 — Crash-safe PC/phone Mod Settings + Pidgeotto flap fix

This release hardens the custom **MOD SETTINGS** root instead of letting a custom renderer failure take down the whole mod manager. The Stadium grid is still used normally, but its root build, input, pointer handling, and high-resolution draw path are now protected. The reset/vector transform path also no longer depends on the newer `love.graphics.push("all")` form; it uses portable `push()` instead. If a PC/LÖVE graphics backend rejects the custom presentation, that options session immediately falls back to Gen1Recomp's native flat ManagerState option rows and stays there rather than rebuilding the failing grid on the next update. A fresh reopen retries the custom UI.

Phone builds now use a responsive full-surface category grid rather than the desktop right drawer: **5×3 in landscape** and **3×5 in portrait**. Direct icon taps and the on-screen BACK target use Gen1Recomp's supported `input.pointer` hook, while the normal mobile D-pad/A/B controls continue to work. The pointer bridge understands both OS-window coordinates and GameViewport-local coordinates for low-resolution game canvases.

Pidgeotto's airborne Stadium animation is also fixed at the point where it was still being lost. A Fly Your Pokémon mount previously selected the flight clip and then ran the ground locomotion bridge later in the same frame, overwriting the flap. All airborne presentations now bypass ground gait selection. Dex 17 also scores the actual authored Stadium skeletal clips (including species-specific animations not reachable through generic context names) and selects the strongest usable rotation motion while airborne, then restores idle/bind pose on landing.

The v0.4.22 announcer and denser Kanto wild/flyer changes are retained.

Version: v0.4.23

## v0.4.22 — Stadium announcer + denser Kanto wilds and flyers

This release fixes the remaining Stadium announcer playback seam in current Gen1Recomp sandboxes. The ROM-generated WAV path no longer directly dereferences the blocked `love.filesystem` namespace; FileData is now an optional protected fast path, with the existing in-memory PCM `SoundData` decoder used safely when filesystem access is sandboxed. The announcer also keeps working under the default **GYM / ELITE 4 / CHAMPION** scope for Gold/Johto boss classes that do not have a dedicated Stadium 1 entrance sentence: those fights now receive the reusable Stadium species, move, damage, faint, and result calls instead of being rejected wholesale.

Kanto is more alive as well. Yellow encounter maps now target roughly five or more visible grass Pokemon and three or more visible water Pokemon when space allows, with deterministic retries so occupied cells no longer silently reduce the requested population. The hard caps remain bounded at ten grass and five water bodies per source map before distance culling.

Ambient sky Pokemon now run inside the Yellow/Kanto excursion too. A lightweight Kanto ambience view exposes the current Yellow map, player coordinates, and encounter table without ticking the Kanto runtime twice; the Gold voxel bridge appends those presentation-only flyers to Kanto's actor list. At NORMAL density Kanto targets about four to five flyers on the medium performance tier, while LOW still stays conservative. The v0.4.21 Pidgeotto airborne animation override applies to these Kanto flyers automatically.

Version: v0.4.22

## v0.4.21 — Pidgeotto airborne Stadium animation fix

Pidgeotto now uses visible authored skeletal motion whenever its Stadium model is actually airborne in the overworld. The renderer prefers Pidgeotto's alternate standby clip and safely falls back through other real Stadium motion only if the alternate context aliases the motionless primary idle.

The override is intentionally Dex-17-only: other flying Pokémon keep their existing authored idle/wing loops. It applies to both presentation-only ambient sky Pidgeotto and Pidgeotto used by **Fly Your Pokémon**, and the normal idle is restored when the mount leaves flight mode. No procedural wing bones or fake model deformation were added.

Version: v0.4.21

## v0.4.20 — Larger borderless Mod Settings icons

This release cleans up the MOD SETTINGS homescreen presentation. Category artwork is no longer nested inside an extra semi-transparent rounded-square icon well; the supplied PNG artwork now defines its own silhouette directly. The icon area is larger and each image is drawn at nearly the full available size, so the category art is much easier to read without the double-border / padded look.

The selected category still uses the existing full-cell focus card and outline, so controller/keyboard focus remains obvious. Labels, setting counts, navigation, all twelve bundled PNG category icons, and the RESET ALL vector fallback are otherwise unchanged. v0.4.18 voxel hot-path optimizations remain intact.

Version: v0.4.20

## v0.4.19 — Remaining Mod Settings PNG icons

This release finishes the MOD SETTINGS homescreen icon set by bundling the six newly supplied PNG icons for the remaining non-reset categories. The existing PNG-backed icons for **UI**, **PERF/GFX**, **WORLD**, **WEATHR/FX**, **CAMERA/DISPLAY**, and **BATTLE** are unchanged, and the new assets now cover **3D MODELS**, **FLY PKMN**, **WILD PKMN**, **FOLLOW BEHAVE**, **DEV TOOLS**, and **OTHER**.

The icon loader now treats those six categories exactly like the earlier custom icon set: it reads the PNG bytes from the packaged mod archive through `mod:read()`, decodes them into LOVE image data, caches the resulting image objects, and scales them into the homescreen icon wells. **RESET ALL** intentionally remains on the existing vector fallback so the reset affordance still renders even if a packaged image is ever missing.

All v0.4.18 voxel-renderer and mesher optimizations are preserved as-is. This update is focused on completing the mod-settings category art, not changing renderer behavior.

Version: v0.4.19
## v0.4.17 — Broad performance optimization pass

This release targets frame-time and hitch complaints across both 3D and 2D play. **PERFORMANCE PRESET now defaults to AUTO / RECOMMENDED** for new installs. AUTO measures the cost of the actual voxel draw (before the FPS limiter sleeps) and slowly moves between LOW, MEDIUM and HIGH with strong hysteresis: it drops quality quickly when the renderer is consuming too much of the target frame budget, and only climbs after several seconds of stable headroom. AUTO never rewrites the player's individual graphics rows.

The fixed presets are cheaper too. MEDIUM keeps 55% internal resolution, blob shadows and fast sky reflections but now uses one-ring Kanto prefetch and the smooth mesh-build budget. HIGH keeps 75% resolution and real sun shadows but no longer enables FULL SSR automatically; FULL SSR remains available in ULTRA or CUSTOM. Off-screen terrain/detail/figure/actor culling is tighter, cooperative mesh slices are shorter, HIGH shadow maps refresh at 30 Hz while moving, and LOW shadow maps at 20 Hz. Stationary shadow maps still reuse their cache without rerendering.

Visible Wilds AI and render-only ambient sky Pokémon now update at a performance-tier cadence instead of blindly following presentation FPS (LOW 20 Hz, MEDIUM 30 Hz, HIGH 45 Hz, ULTRA 60 Hz). Ambient sky Pokémon do **zero steering/animation work in native 2D mode**, where they cannot be rendered anyway. Their count is also capped more conservatively on LOW/MEDIUM. Weather FX AUTO now starts at MEDIUM rather than HIGH, then uses its existing governor to climb if the machine has headroom.

Version: v0.4.17

## v0.4.16 — Native 2D mode is first-class

**3D VOXEL WORLD = OFF now means real Gold/Silver native 2D**, not a temporary fallback waiting for another mod subsystem to turn 3D back on. The switch is now the sole overworld-renderer master gate: OPEN WORLD remains only a remembered residency preference, first/third-person camera ownership is released immediately, relative mouse/free-move state is cleared, Gold's native grid movement and zoom are left authoritative, Weather FX returns to its normal 2D presentation, and the 3D shoulder-capture layer stands down while visible wild Pokémon continue through their normal 2D battle/catching path.

The compose bridge also protects 2D from **other active `drawWorld` pipelines**. When native 2D is selected, it redraws Gold's authoritative world while temporarily suspending any active world-pipeline levels only for that draw, then restores those live levels without rewriting another mod's saved preference. This prevents a companion 3D/player pipeline or a stale same-frame voxel canvas from leaking through after the player explicitly selected 2D. Custom pause/submenu UI can still sit over the live native 2D world.

Battle presentation remains independent: players can use a native 2D overworld with Stadium-style 3D battles if **3D BATTLE WORLD** is enabled, or turn that battle option off for native battle presentation too. The detached Yellow/Kanto excursion is the one explicit limitation because that foreign region is supplied by this mod rather than Gold's native map renderer; while 2D is active, Kanto entry is refused instead of silently forcing voxels on, and turning 3D off during an excursion safely returns to Johto.

Version: v0.4.16

## v0.4.15 — Right-side homescreen MOD SETTINGS

This release keeps every MOD SETTINGS category on a single screen, but changes the presentation to match the **right-side pause drawer** instead of a centered full-screen panel. The category root is now a compact glass panel docked to the **right side** of the screen with a **4×4 homescreen-style app grid**: icon-first cells, labels underneath, tighter spacing, and a smaller overall footprint so the game world remains visible on the left.

Navigation and settings behavior are unchanged: Left/Right moves columns, Up/Down moves rows, A opens, B returns, and the category pages still use Gen1Recomp's real ManagerState option rows underneath the modern skin. This keeps persistence, conditional rows, editors, OTHER, RESET ALL, and live CUSTOM UI switching intact.

Version: v0.4.15

## v0.4.14 — All MOD SETTINGS categories on one page

The modern MOD SETTINGS root now fits **all 13 current tiles on one screen** using a compact **4-column × 4-row grid**. There is no category paging anymore: the eleven named categories, OTHER, and RESET ALL are all visible together, with only three unused grid cells. Card padding and gutters are tighter so the icons stay grouped rather than spreading across oversized menu cards.

Navigation stays spatial: Left/Right moves across four columns, Up/Down moves by one grid row and wraps within the same column, A opens the selected category, and B returns normally. The six supplied PNG icons still load through the packaged-mod `mod:read()` path, and the remaining categories keep their scalable fallback icons.

Version: v0.4.14

## v0.4.13 — Compact 3×2 MOD SETTINGS grid

The modern MOD SETTINGS root is now a **compact 3-column × 2-row tile grid** per page instead of six long 2-column rows. Cards are narrower, panel padding is reduced, horizontal/vertical gutters are only a few pixels, and each category uses a centered larger icon with its name and setting count directly underneath. This removes the large unused text area visible in v0.4.12 and pulls all six page icons much closer together.

The supplied custom PNG icons still load through the packaged-mod `mod:read()` path. Navigation remains spatial and paged: Left/Right moves across three columns, Up/Down moves between the two rows/pages, A opens, and B returns to the exact tile.

Version: v0.4.13

## v0.4.12 — Packaged custom icon loader fix

The six supplied MOD SETTINGS PNG icons now load through the mod archive's real `mod:read()` API and are decoded as `ByteData -> ImageData -> Image`. v0.4.11 bundled the files correctly but tried to open them as ordinary game-relative paths, so a packaged `.zip` could not see them and silently fell back to the old vector category glyphs.

The first grid page now uses the supplied artwork for **UI / MENUS**, **PERFORMANCE / GRAPHICS**, **WORLD**, **WEATHER FX**, **CAMERA / DISPLAY**, and **BATTLE**. Remaining categories still use the existing fallback icons until custom art is supplied for them.

Version: v0.4.12

## v0.4.11 — Custom icon pack for MOD SETTINGS

This build keeps the modern glass/card MOD SETTINGS grid from v0.4.10 but replaces six of the root category glyphs with bundled high-resolution PNG icons provided for the mod UI. The **BATTLE**, **CAMERA / DISPLAY**, **PERFORMANCE / GRAPHICS**, **UI / MENUS**, **WEATHER FX**, and **WORLD** tiles now use the supplied artwork directly, while the remaining categories keep the existing scalable fallback icons.

Navigation and settings behavior are unchanged: Left/Right moves columns, Up/Down moves rows/pages, A opens, B returns, and the category pages still use Gen1Recomp's real ManagerState option rows underneath the modern skin. This keeps persistence, conditional rows, editors, OTHER, RESET ALL, and live CUSTOM UI switching intact.

Version: v0.4.11

## v0.4.09 — iPhone orientation hardening + independent OPEN WORLD

This release makes iOS orientation **native-only by default**. With **IPHONE ORIENTATION FIX** enabled, the mod requests the same normal iPhone mask used by the app (`Portrait`, `LandscapeLeft`, `LandscapeRight`) through SDL, then leaves framebuffer and touch rotation to UIKit/SDL. The old automatic `landscapeFlipped` 180-degree compositor is gone; only the explicitly enabled **IPHONE FORCE 180** emergency switch can rotate the final frame. Current Gen1Recomp also gained iOS support in `src.core.Orientation` in dev commit `8c0d0ace...`, and the mod uses that path as a fallback when direct SDL hinting is unavailable.

**OPEN WORLD is now independent from the renderer master switch.** Turning **3D VOXEL WORLD** OFF keeps Gold/Silver in native 2D even when OPEN WORLD remains ON. OPEN WORLD simply remembers the expanded residency choice and resumes it if voxels are turned back on later. The detached Yellow/Kanto excursion still promotes its own renderer because that foreign-region world is supplied by this mod.

## v0.4.08 — Icon-grid Mod Settings

This release redesigns **this mod's MOD SETTINGS root** as a large **2×3 paged category grid** instead of another long text list. Every category has a purpose-drawn icon and compact two-line tile label, while the selected tile shows the full category name and option count above the grid. Keyboard/D-pad/controller navigation is spatial (Left/Right between columns, Up/Down between rows and across pages), A opens the category, and B returns normally. Mobile touch controls drive the same mapped navigation with much larger visual targets.

The individual category pages still use Gen1Recomp's native `ManagerState:buildOptionRows()` output, so toggles, choices, number/text inputs, conditional visibility, persistence, `mod.options_changed`, category-back behavior, live CUSTOM UI OFF→ON switching, and RESET DEFAULTS keep their existing behavior. Unknown future options automatically appear in an **OTHER** tile, and **RESET ALL** has its own grid tile.

Version: v0.4.09

## v0.4.07 — FPS / third-person right-stick stability

This release fixes the reported controller case where a voxel **FIRST PERSON / THIRD PERSON** view could show the native 2D Gold/Silver world only while the right stick was held to look around. Right-stick look is now explicitly camera-mode neutral, so it cannot transiently switch the selected free-camera mode. The sun-shadow pass also reuses its last valid map while the stick is moving and treats a failed optional refresh as a shadow-only failure rather than a reason to abandon the 3D frame.

Version: v0.4.07

## v0.4.06 — Third-person player billboard scale fix

This release fixes the screenshot-confirmed **giant 2D trainer billboard** that could appear in voxel **THIRD PERSON**, especially when the camera boom was short or compressed near scenery. The player card now gets a presentation-only scale based on the live third-person camera distance, so its apparent size stays bounded instead of ballooning toward the camera. Nearby NPCs, terrain, props and normal perspective are unchanged.

The same player-only scale is used by the visible card, the occlusion ghost and both shadow paths so the fix cannot leave an oversized silhouette or shadow behind. Higher-resolution custom player sheets are normalized to the native 16-pixel trainer footprint for this third-person presentation only. The v0.4.04 walking-frame fix remains active, and the v0.4.05 clean **no-PokeDoom/FPS-addon** state is retained.

Version: v0.4.06

## v0.4.05 — Clean Gold/Silver build

The integrated FPS addon has been removed completely. This release keeps the v0.4.04 Gold/Silver, Pokédex, mobile UI, iPhone orientation, live CUSTOM UI switching, controller DIORAMA zoom, and 2D voxel-player animation fixes without its code, assets, settings, import controls, hooks, save-state handlers, or manifest conflict.

Version: v0.4.05

## v0.4.04 — Silver + mobile/UI/controller compatibility pass

This release promotes the standalone Stadium2 package from Gold-first compatibility to **Gold/Silver edition-aware Gen-2 support** on current Gen1Recomp. The active Silver edition now flows through the mobile file-picker bridge instead of being hard-wired to Gold. The custom Pokédex entry action list follows its vertical presentation with **Up/Down** navigation, custom Stadium menus use a larger touch-readable scale on Android/iPhone, CUSTOM UI can be switched OFF and back ON without leaving the same pause session stuck in the flat options list, controller stick-click zoom now works in **DIORAMA**, and the default 2D Gen-2 trainer card now takes its live Gold/Silver walk phase in voxel mode.

iOS orientation is native-first on current Gen1Recomp: UIKit/SDL already owns Landscape Left/Right, so the old mod-side second 180-degree rotation is suppressed. An **IPHONE FORCE 180** emergency option remains available for unusual legacy/sideload builds.

Version: v0.4.04


## v0.4.01 — Yellow Summer Beach House / Surfing Pikachu

Yellow's Route 19 Summer Beach House is now functional inside Kanto free roam. Bring a Pikachu in Gold's real party that knows SURF, talk to the Surfin' Dude, and the current Gen1Recomp Surfing Pikachu minigame launches directly. The high score is stored in the companion Kanto namespace rather than permanently adding a Yellow-only field to Gold's native save, while Yellow's first-ask/repeat-ask and per-visit printer behavior are preserved.

Version: v0.4.01

## v0.4.00 — Kanto Pokemon Center healing + full void-tree belt

Kanto Pokemon Center nurses now heal Gold's real party even when the imported Yellow cache does not expose a `nurse=true` text-pointer marker. Outdoor Yellow/Kanto map void around the playable body is also filled with authored Kanto tree crowns; water edges remain water and the synthetic trees use round tree geometry rather than wall prisms.

Version: v0.4.00

## v0.3.99 — Final authored Yellow TM-gift sweep

The last two uncovered standalone Yellow TM gifts are now bridged safely into Gold: Celadon Mart 3F COUNTER and Cinnabar Lab METRONOME. Their Gen-1 TM numbers do not mean the same moves in Gen 2, so both are persistent Kanto-local one-use machine credits using Yellow compatibility instead of corrupting Gold's TM pocket.

Version: v0.3.99

## v0.3.98 — Early Route 22 rival / Yellow Eevee evolution parity

The Yellow rival's Eevee route is now stateful from Oak's Lab forward. A Lab win starts the Flareon branch, a Lab loss starts the Vaporeon branch, and defeating the optional first Route 22 rival before Brock promotes only the Flareon branch to Jolteon. Later rival encounters use that persisted route.

Version: v0.3.98

## v0.3.97 — Remaining standalone Kanto reward parity

This release closes three authored reward gaps: the Celadon Diner Coin Case, Route 12 Gate 2F TM39 Swift, and Silph Co. 2F's Yellow TM36 Selfdestruct. Cross-generation TM rewards are resolved by move meaning; Selfdestruct has no safe Gold TM-number mapping, so it uses the persistent Kanto-local single-use machine-credit bridge.

Version: v0.3.97

## v0.3.96 — Saffron Copycat / Yellow TM31 MIMIC parity

v0.3.96 restores Copycat's Yellow one-time POKE DOLL trade without corrupting Gold's TM numbering. Trading one POKE DOLL records Yellow's TM31 reward as a persistent Kanto-local single-use MIMIC machine credit. The credit uses Yellow's original species TM/HM compatibility and Gold's native move-learning screen, while Gold's unrelated TM31 never enters the PACK. Canceling or choosing an incompatible Pokemon preserves the credit for a later retry.

Version: v0.3.96

## v0.3.91 — Safari rewards and Yellow field-HM badge parity

v0.3.91 restores the missing Safari Zone/Fuchsia progression rewards against Gold's real inventory while keeping Yellow-only GOLD TEETH in the companion Kanto namespace. The Secret House now awards Gold's real SURF HM, the Warden consumes the teeth and awards Gold's real STRENGTH HM with Yellow's retry-on-full-PACK behavior, and Kanto field HMs use Yellow's own badge requirements instead of Johto's badge table.

## v0.3.90 — Rival progression and Cerulean Cave postgame

v0.3.90 connects more of Yellow's recurring Rival story to the Gold-owned Kanto runtime. The Cerulean bridge, Pokemon Tower 2F, and Route 22 League warm-up now use Yellow's authored trigger coordinates and party-number rules while Gold remains the battle/save authority. Rival actors are script-hidden until the encounter starts and leave persistently afterward.

The postgame gate is also real now: before the companion Kanto Hall of Fame, Cerulean Cave's Super Nerd is guaranteed visible and the cave warp itself is blocked as a safety net. After the Kanto League/Hall-of-Fame completion from v0.3.89, that guard disappears and Cerulean Cave/Mewtwo becomes the proper postgame destination, matching Yellow's Hall-of-Fame object toggle.

Version: v0.3.91

## v0.3.89 — Yellow Pokemon League now completes inside Gold

v0.3.89 extends the Kanto excursion through its full League ending. Lorelei, Bruno, Agatha and Lance now use the imported Yellow rosters in Gold's battle engine, while their room exits and Lance entrance physically follow Yellow's authored block swaps. Once the player enters Lorelei's room the challenge is forward-only; blacking out resets the run instead of leaving defeated Elite Four members behind.

After Lance, the Yellow `RIVAL3` Champion fight runs through Gold as well. Winning records the active Gold party in Gen1Recomp's native Gen-2 Hall of Fame core and presents the native Gold Hall of Fame induction screen. The companion restores any prior Gold `spawnAfterChampion` value afterward, so the parallel Kanto campaign cannot steal Gold's own post-credit continue state. The temporary League run then resets for rematches and returns the Kanto excursion to Pallet Town.

Version: v0.3.89

## v0.3.78 Kanto uses Johto color at the correct layers

The latest screenshots exposed two separate problems that previous palette passes were conflating. First, the Kanto player was being rebuilt from Yellow `SPRITE_RED` and colored from the same Gold-synced map ramp used as a fallback for terrain, so the character visually blended into walls/ground instead of looking like the native Johto player. Second, the exact shade-population transfer added in v0.3.76/77 was inventing checker/dither pixels on paths and noisy walls.

v0.3.78 fixes both at the source. The visible Kanto player now reuses Gold's live player `SpriteRenderer`, including native `PAL_OW_RED`, time-of-day/color-mode object palette and bike/player sheet. The world stays on the v0.3.77 frequency-locked Johto material families, but Kanto/native-Kanto 2bpp shade positions are no longer redistributed. Each native shade is simply recolored through the selected Johto PalMap ramp, exactly separating OBJ character color from BG world material color.

This keeps the good magenta roof/facade/foliage direction without the synthetic black/brown checker field. Kanto geometry, collision, map art and native Gen-2 Kanto donor textures remain authoritative.

Projection revision: `g2-johto-colors-378-r1`

Version: v0.3.78

## v0.3.75 Kanto keeps its art while matching Johto's color balance

v0.3.74 proved that copying an actual Johto donor tile's 2bpp pixels was the wrong abstraction: it transferred the donor's spatial brick/stripe/roof pattern onto unrelated Kanto surfaces. v0.3.75 keeps the scene-aware donor selection from v0.3.73/74, including Cherrygrove for towns and Route 29 for routes, but transfers only **color identity and shade balance**.

Kanto/native-Kanto texture pixels remain in their original positions. Each material still resolves to an actual scene-used Johto PalMap slot, then a four-shade histogram matcher adjusts Kanto's light/mid/dark usage toward the selected Johto donor tile without moving a single texel. Roof/facade role separation remains active, so the magenta civic roof family stays Johto-like while walls, paths, foliage and trim keep Kanto's own readable patterns instead of becoming giant pink bands. The projection revision is bumped to `g2-johto-colors-375-r1`, forcing the broken v0.3.74 projected materials to rebuild.

Version: v0.3.75

## v0.3.71 Kanto scripted-reward / Gold state parity

v0.3.71 continues the Kanto-correctness pass by promoting ordinary reward interactions that were still presentation-only inside `KantoDialogue`. The active Gold save can now actually receive Celadon's level-25 Eevee, Silph's level-15 Lapras, one level-30 Fighting Dojo prize, and the ¥500 level-5 Magikarp; all Pokemon use the real Gen-2 party/current-box/Pokedex/OT path and one-time Kanto-local completion is written only after storage succeeds.

The same bridge now owns Oak's 10/30/50-caught rewards (Gold HM05 Flash, Itemfinder, and EXP.SHARE as the semantic successor to EXP.ALL), Mr. Psychic's Gold TM29 Psychic, Route 16's Gold HM02 Fly, and Celadon rooftop vending machines at ¥200/¥300/¥350. Bag and money changes are atomic, so full storage or a full PACK cannot consume a reward or charge the player. The Dojo preserves the one-prize rule and physical ball state.

Cross-generation safety stays strict: Copycat's Gen-1 TM31 Mimic and the thirsty girl's old TM13/TM48/TM49 exchanges are not remapped by number because those numbers mean different moves in Gen 2. No Red/Yellow story/cutscene VM is enabled and Gold remains authoritative for Pokemon, items and money. Upstream Gen1Recomp `dev` is still 9713977755fb87f3a7cc336d5a841cf3f3b15e31, unchanged from v0.3.70.

Version: v0.3.71

## v0.3.70 Kanto Yellow starter-gift / Gold ownership parity

v0.3.70 closes another real Kanto gameplay gap rather than adding presentation-only content. Melanie in Cerulean, Damian on Route 24, and Officer Jenny in Vermilion are now owned by the Gold/Kanto service layer before `KantoDialogue` can suppress their `give_pokemon` commands. Melanie remains Pikachu-specific and requires happiness 147+, Damian offers Charmander directly, and Jenny requires the Kanto Thunder Badge earned from Lt. Surge. Each successful reward is level 10 and uses Gen 2's gift happiness of 120.

Gold remains authoritative for the actual Pokemon records. A gift is created only when party/current-box storage is available, receives the Gold player's OT/ID, enters the real party or current box, and updates Gold's Pokédex. The Kanto-local completion bit is written only after storage succeeds, so a full save cannot consume a starter. Melanie's separate Bulbasaur object is hidden immediately and repaired on later map entry if an upgraded save already has the completion event. No Yellow story flags are copied into Gold and no Yellow cutscene/story VM is enabled.

The shared Gold storage path also now uses current Gen1Recomp's `Mon.stampOT` for non-traded Kanto catches/prizes/gifts when available; in-game trades remain foreign-OT. This release was compatibility-checked against Gen1Recomp `dev` 9713977755fb87f3a7cc336d5a841cf3f3b15e31 (2026-08-19), 18 commits beyond the prior checkpoint. v0.3.69 Bike Voucher/Bicycle, v0.3.68 Saffron/Museum, v0.3.67 iPhone orientation and all earlier Kanto world/performance contracts remain intact.

Version: v0.3.70

## v0.3.69 Kanto Bike Voucher / Bicycle service parity

v0.3.69 continues the Kanto-correctness work with the missing Vermilion Fan Club -> Cerulean Bike Shop service chain. The Fan Club chairman is now a real Kanto gameplay action instead of dialogue-only presentation: NO skips the story and leaves the reward unclaimed, YES tells the authored story and awards one BIKE VOUCHER. Because Gold/Silver normally has no BIKE_VOUCHER item definition, the voucher is held in Kanto-local service state while still honoring Gold's real KEY_ITEM pocket capacity; a host that does define BIKE_VOUCHER uses the real Bag item instead. A full pocket leaves both the reward and Kanto completion bit untouched so the player can retry. Once served, the chairman uses his final reminiscence and cannot duplicate the voucher.

The Bike Shop now recognizes that held Kanto voucher (or a physical BIKE_VOUCHER on compatible/injected hosts), attempts to add Gold's real BICYCLE first, and only consumes voucher possession after that add succeeds. A full key-item pocket therefore preserves the voucher exactly like retail `jr nc, .BagFull`; success persists the Kanto-local completion bit and Gold's existing Kanto Bicycle field action can use the newly owned BICYCLE immediately. Saves that already contain a physical BIKE_VOUCHER or BICYCLE are migrated instead of minting duplicates.

The no-voucher shop path also keeps the authored impossible ¥1,000,000 BICYCLE/CANCEL pitch: selecting BICYCLE yields the can't-afford line without changing Gold money/items, while CANCEL exits directly. No Yellow story/cutscene VM is enabled. v0.3.68 Saffron/Museum parity, v0.3.67 iPhone orientation correction, Android logical-canvas sizing, third-person Character Selector behavior and all earlier Kanto no-lag/world contracts remain intact.

Version: v0.3.69

## v0.3.68 Kanto Saffron / Pewter Museum physical-service parity

v0.3.68 returns to Kanto world correctness. The four Saffron gate houses now run Yellow's authored physical access rule instead of behaving like ordinary interiors: stepping onto each guard trigger without access either hands over the first available Gold-owned drink in retail order (FRESH WATER, SODA POP, LEMONADE) and opens all four gates, or shows the road-closed message and pushes the player one cell back in the correct axis. Direct guard talk shares the same Gold inventory authority.

Pewter Museum now owns its real ¥50 admission rope. Crossing (9,4)/(10,4) without admission calls the clerk; declining or lacking money pushes the player south, while paying deducts exactly ¥50 from Gold and persists the Kanto-local ticket flag. The second scientist also performs the real one-time OLD AMBER transaction: Gold's bag receives the item, bag-full refusal leaves completion untouched, and the museum display disappears immediately and stays hidden on later visits/upgrades.

These are deliberately story-free physical/service ports. Gold remains authoritative for money/items, Kanto persists only foreign-region access/completion state, and no Yellow cutscene/story VM is enabled. v0.3.67's iPhone orientation correction and all v0.3.58-v0.3.66 Kanto no-lag work remain intact.

Version: v0.3.68

## v0.3.67 iPhone landscape orientation correction

v0.3.67 fixes the reported upside-down iPhone presentation without blindly rotating every Apple device. Gen1Recomp's bundled LÖVE runtime exposes the current display orientation as `landscape` or `landscapeflipped`; the mod now watches that signal on iOS and applies the existing whole-frame 180-degree compositor only for `landscapeflipped`. Normal landscape remains native.

The correction happens around the entire Game2 frame, after the voxel world, Gold HUD, menus, battle UI, overlays and touch controls have rendered. Touch coordinates and movement deltas are transformed by the same 180-degree mapping, so what the player taps continues to match what they see. A new **IPHONE ORIENTATION FIX** toggle defaults ON and can be disabled for an iOS build/device that already handles both landscape sides correctly. Android retains its existing manual **FLIP SCREEN 180 DEGREES** behavior unchanged.

This release does not change the v0.3.48 Gold logical drawWorld sizing contract or any Kanto visual/performance setting. v0.3.66 and the earlier no-lag work remain intact.

Version: v0.3.67

## v0.3.66 Kanto steady-frame proxy / neighbor no-lag hot paths

v0.3.66 continues the no-quality-cut Kanto performance work in the remaining presentation-rate bookkeeping. v0.3.65 made the connected-route descriptor tables persistent, but the runtime still walked every neighbor each rendered frame to recalculate seam urgency/directional prefetch and repeatedly re-resolved the visible Kanto trainer sprite/card.

The neighbor dynamic decision is now keyed by the exact completed player cell and world-travel vector. If neither changed, the prior `urgent` / `prefetch` booleans remain authoritative and the connected list is not traversed at all. When the vector does change, the movement direction is normalized once and each second-ring descriptor uses a root-to-neighbor unit vector cached when that descriptor was built. Root/radius/sector identity changes still invalidate the cache immediately.

The Kanto player proxy now keeps its resolved card/SpriteRenderer until map, Bicycle state, Gold palette, custom-skin ownership or source SpriteRenderer identity changes. The optional custom-player `active()` callback also uses the established trusted-callback pattern: one protected validation per function identity, direct calls afterward, automatic revalidation on replacement.

No voxel resolution, draw distance, route coverage, NPC/Pokemon visibility, terrain detail, water, shadows, collision, warps, third-person animation, Character Selector behavior, Android framing or Gold save/gameplay authority are reduced.

Version: v0.3.66

## v0.3.65 Kanto connected-neighbor / bridge no-lag hot paths

v0.3.65 continues the no-quality-cut Kanto performance work in the presentation-frame path. The connected Kanto sector graph was already solved/cached, but every rendered frame still cleared the neighbor arrays, scrubbed pooled descriptor tables, copied map/offset/depth fields back into them and rebuilt the direct-neighbor array. The runtime now retains that neighborhood view while the root map, Kanto radius and cached sector-record identity are unchanged.

Only the two values that actually depend on live travel are updated at presentation rate: seam urgency and directional prefetch. Actor candidate invalidation remains separate, so NPC/Pokemon movement cannot make terrain-neighborhood bookkeeping churn. GoldVoxelBridge also validates the bundled Kanto `excursionState` helper once per function identity and then leaves the protected-call path on steady frames. A replaced helper automatically receives a fresh protected probe.

No voxel resolution, draw distance, route coverage, NPC/Pokemon visibility, terrain detail, water, shadows, collision, warps, third-person animation, Android framing or Gold save/gameplay authority are reduced.

Version: v0.3.65

## v0.3.64 Kanto idle-tick / trainer hot-path no-lag caching

v0.3.64 continues the no-quality-cut Kanto performance work in the code that still ran every rendered frame and every trainer-heavy landing. Idle frames now advance the wander timer first and return before resolving the current map/NPC list when no mover exists and no AI decision is due. NPCs already mid-step interpolate directly from the maintained mover list, so smooth actor motion remains render-rate while idle maps stop paying actor-discovery cost.

The stable Gold state-stack callback and Love RNG callback are each protected only on a newly seen object/function identity and then use direct calls until identity changes. Trainer sight also tests facing/alignment before consulting persistence or headers; immutable trainer win IDs and headers are cached on the imported object, eliminating repeated string construction and table resolution on trainer-heavy routes.

No voxel resolution, draw distance, NPC/Pokemon visibility, water/shadows, terrain detail, third-person animation, collision/warp semantics, Android framing or Gold gameplay authority are reduced.

Version: v0.3.64

## v0.3.63 Kanto position-checkpoint no-lag hot path

v0.3.63 continues the no-quality-cut Kanto performance work by removing save-bridge churn from ordinary movement. Previous builds created a fresh position table, deep-copied LAST_MAP state and called `mod.save:set` on every completed Kanto cell. The runtime now keeps one reusable position snapshot plus one reusable LAST_MAP snapshot and updates those in place.

Uninterrupted walking/third-person travel writes a durable checkpoint every eight changed cells instead of every cell. The visit-local snapshot is still current after every landing, and menus/overlays, route seams, warps, Fly, Surf/Bicycle state changes, relocations, dungeon falls, Kanto entry and RETURN TO JOHTO force an exact checkpoint immediately. At normal walking speed the batching window is only a small travel interval, while the repeated table allocation/deep-copy/save-bridge spike is removed from seven of every eight cells.

No voxel resolution, draw distance, NPC/Pokemon visibility, water/shadows, terrain detail, third-person animation, collision/warp semantics or Gold gameplay authority are reduced.

Version: v0.3.63

## v0.3.62 Kanto completed-step / warp no-lag hot paths

v0.3.62 continues the no-quality-cut Kanto performance work in the completed-cell landing path. Ordinary cells now probe the private Gen-1 map's O(1) warp index once and skip warp resolution, pad/hole tile reads and ExtraWarpCheck work entirely when no authored warp exists under the player. This removes repeated special-warp bookkeeping from normal walking across routes, towns, caves and interiors.

Warp bounce suppression now stores `(map, x, y)` as scalar excursion fields instead of allocating a `"map:x:y"` string on every warp destination and every later comparison. The legacy string field remains accepted for compatibility, but normal runtime uses a boolean sentinel plus scalars. Classic step-encounter enablement is cached for the active Kanto visit and re-armed while an overlay/menu is open, so a changed option is observed when gameplay resumes without crossing the mod-options bridge on every landing. Surf passability also reads the cached collision tile once instead of separately rechecking walkable/water membership.

No voxel resolution, draw distance, actor visibility, water/shadows, third-person animation, collision rules, warp semantics, encounters or world geometry are reduced.

Version: v0.3.62

## v0.3.61 Kanto collision/step no-lag hot-path caching

v0.3.61 continues the no-quality-cut Kanto performance work in the movement/collision layer. The private Gen-1 map adapter now caches the collision tile for each authored cell, so repeated walkability, water, grass, warp, elevation and ledge queries reuse one tile result instead of decoding the same block/tile position several times per rendered frame. Dynamic Cut/door/poster/trash-puzzle restamps invalidate only the affected 2x2 collision cells through `ForeignGen1Map:setBlock`, preserving live geometry correctness.

Continuous FIRST/THIRD PERSON movement also bypasses `pcall` for passability and elevation-pair reads on the trusted private Kanto map class. The Gold timer/input callbacks are defensively probed once per runtime object/function and then called directly until identity changes. Immutable Yellow ledge rows and ExtraWarpCheck carpet metadata are pre-indexed into the existing field index, removing held-collision list scans. None of these changes reduce voxel detail, draw distance, actor visibility, water/shadows, animation or route/world fidelity.

Version: v0.3.61

## v0.3.60 Kanto actor/AI no-lag caching

v0.3.60 continues the no-quality-cut Kanto performance work at the actor/AI layer. NPC role membership is now indexed once per authoritative map actor list, so trainer sight and wanderer selection no longer rescan every NPC looking for trainer/wander flags. Only NPCs that are actually mid-step are visited each render tick for interpolation.

The visible actor candidate set is cached while the player remains in the same Kanto cell. Any actor cell/list mutation increments a generation counter and invalidates that view immediately; route changes and actor-distance/radius changes also miss the cache. Connected-map candidates retain a one-cell safety margin while VoxelScene keeps the final camera-space cull authoritative, so no actor visibility distance or draw quality is reduced.

TwinRegionWorld also hands GoldVoxelBridge its already-built reusable depth-1 neighbor array directly, and VoxelScene/Kanto frame pools scrub unused tail records when actor/water/neighbor counts shrink so old route references do not stay pinned merely for allocation reuse.

Version: v0.3.60

## v0.3.59 Kanto movement-time no-lag / prefetch + palette hot-path performance

KANTO FREE ROAM gets a second **no-quality-cut performance pass**, focused on the work that still happened while the player/camera was moving through an already-loaded region. Voxel resolution, connected-route terrain, draw distance, NPC/Pokemon visibility, water, shadows, grass/flowers and third-person Character Selector animation all keep their existing fidelity.

The voxel prefetch path now reuses Kanto's live-residency set, neighbor-visibility flags, terrain/water readiness arrays and detail-ready arrays instead of recreating them every frame. Shared-body Kanto also skips the open-world FULL seam-mask/placement builder completely because those synthetic apron masks are not consumed by BODY-only Kanto terrain. Neighbor visibility is calculated once per frame, and world/detail/actor culling paddings plus expanded camera bounds are calculated once and reused by every actor/map test.

A separate periodic hitch was Gold material polling. The previous Kanto bridge throttled full Gold palette-profile analysis to four checks per second, but each check still walked the Johto PalMap several times and serialized the complete eight-palette signature. v0.3.59 first checks cheap daytime/color-mode/palette-set/PalMap identities; full profile analysis only runs when one of those inputs actually changes.

ChunkMesher now snapshots live residency into its own reusable two-generation buffers, so VoxelScene can safely wipe/reuse its caller scratch set without corrupting previous-neighborhood retention. Kanto's sector cache also uses nested scalar keys and its actor cell index uses packed numeric keys, eliminating two more movement-time string-allocation paths. RETURN TO JOHTO still scrubs every Kanto prefetch/mesh reference.

Version: v0.3.59

## v0.3.58 Kanto no-lag frame pacing / low-GC performance

KANTO FREE ROAM now has a dedicated **steady-frame performance path**. It does not lower graphics quality: terrain meshes, voxel detail, connected-route visibility, actors, water, shadows, flowers/grass and the third-person player model all keep their existing fidelity. Instead, v0.3.58 removes Kanto-only allocation churn and stops future-map preparation from stealing time from the map currently being played.

The Kanto renderer now reuses one scrubbed frame-state plus pooled neighbor/entity/ghost/pose/water scratch records. Stable neighbor transforms and ocean descriptors are cached, and the tiny forced-bike hot check no longer builds a string each frame. This substantially reduces garbage creation during ordinary walking, camera movement and idle rendering.

Background work is also frame-paced. If the current sector is cold it still gets the normal urgent build budget so a warp can recover quickly. Once that sector is drawable, connected-neighbor/prefetch meshing and disk-cache warming run in short cooperative slices. Visible gameplay never prepares arbitrary far-away Yellow atlases just to fill a future cache; whole-region warming is deferred until gameplay is covered by an overlay/menu. RETURN TO JOHTO releases all of these reusable Kanto references before unload.

Version: v0.3.58

## v0.3.57 Kanto Pokemon Tower purified-zone parity

KANTO FREE ROAM now restores **Pokemon Tower 5F's purified healing zone** as a real Gen-2-backed field behavior. The four authored Yellow cells—`(10,8)`, `(11,8)`, `(10,9)`, `(11,9)`—heal the player's actual Gold party the first time the player enters the pad, suppress encounters for every landing while the player remains on it, clear when the player steps off, and heal again on a fresh entry.

The companion does not import `EVENT_IN_PURIFIED_ZONE` into Gold. The latch is presentation-local Kanto state, while the heal itself goes through Gold's native party authority. The visual sequence follows the Yellow map script: white fade out, two `Delay3` holds, white fade in, then the imported purified-zone text. RETURN TO JOHTO clears the temporary latch so resuming Kanto on the pad starts a fresh visit cleanly.

This is a physical map-script parity improvement only: no Pokemon Tower story progression, ghost/Marowak cutscene VM, Gold coordinates, Android framing, Character Selector animation or Kanto collision ownership is replaced.

Version: v0.3.57

## v0.3.56 Kanto THIRD PERSON transition/state isolation

KANTO FREE ROAM now keeps **all Character Selector presentation state tied to the visible Kanto player**, not to whatever the hidden Johto player happens to be doing underneath. This closes two follow-on issues from the v0.3.55 animation fix.

Kanto Bicycle/Surf/Fishing state now decides whether the 3D trainer model is eligible. A hidden Johto bike/surf/fishing state can no longer hide the Kanto model, and mounting the Bicycle or Surfing in Kanto correctly returns to the authored special player card instead of drawing the humanoid mesh on top. Kanto also keeps its own retained third-person body yaw and previous-world sample, so a Johto render between Kanto passes cannot twist or reset the Kanto model's travel-facing.

The first Kanto model frame rebases that sample at the current Kanto position, avoiding a false cross-region movement vector. Explicit stationary Kanto facing changes used by interactions/warps rotate the model to the authored direction, while ordinary camera orbit continues to leave the last travel-facing intact. Every temporary Character Selector field is restored on the real Gold player after rendering.

No graphics quality, collision, Kanto gameplay rules, Android framing or Johto Character Selector behavior is reduced or replaced.

Version: v0.3.56

## v0.3.55 Kanto THIRD PERSON player-model animation fix

KANTO FREE ROAM now refreshes the **3D Character Selector skeletal animation frame from the visible Kanto player** before the model's shadow/main voxel draw. Current Character Selector caches locomotion in `beginVoxelFrame()` and later `drawVoxel()` consumes that cached `voxelFrameKey`; Kanto previously called the draw directly without owning that preparation step, so the model could translate through Kanto while its rig kept the hidden Johto player's idle pose.

The bridge still keeps the original Gold player object identity for selected skins/accessories, but temporarily mirrors the Kanto proxy's movement state during animation preparation: moving/facing, native-looking 16-frame step progress/target, actual Kanto movement-vector magnitude for walk/run blends, and Kanto ledge-hop/jump state. Every gameplay-facing field is restored immediately afterward. Johto's normal Character Selector pipeline is unchanged. Older selector builds that do not expose `beginVoxelFrame()` get a safe stale-cache invalidation fallback.

This is a rendering/animation fix only: Kanto collision, movement authority, Gold save state, camera behavior and Android logical-frame sizing are unchanged.

Version: v0.3.55

## v0.3.54 Kanto dialogue presentation + actor spatial indexing

KANTO FREE ROAM keeps the v0.3.53 comprehensive NPC/sign dialogue bridge, but now preserves an important presentation detail that the first sandbox pass intentionally dropped: **safe dialogue audio timing**. Current Gen1Recomp pet-NPC handlers such as Pewter's Nidoran use `play_cry` immediately before `show_text`; the command arms the TextBox so the cry plays at the cartridge's text-completion beat and, where authored, the box still waits for A/B afterward. v0.3.54 allows only that clone-local `play_cry` command through the sandbox and forwards a sanitized TextBox `auto.sound/delay/wait` contract to the real Kanto UI. Battles, warps, story screens, movement, save mutation and arbitrary callbacks remain blocked.

The Kanto actor hot path is also indexed. NPC and roaming/static Pokémon cell queries no longer scan an entire map actor array on each collision, interaction, Strength push or trainer sight check. `lib/KantoSpatial.lua` builds per-map cell buckets once and updates them immediately when a wandering NPC changes cells, a trainer walks up, a boulder moves/falls, a roaming Pokémon enters battle, a static Pokémon is restored after running, an item/guard disappears, or a map actor cache is invalidated. Duplicate-cell buckets preserve the old `except` semantics, so the optimization does not change collision ownership.

No render distance, voxel detail, model fidelity or animation quality is reduced.

Version: v0.3.54

## v0.3.53 complete Kanto NPC dialogue

KANTO FREE ROAM no longer drops every Yellow `text_asm` interaction. The generated pointer cache intentionally marks those entries as scripted instead of embedding their spoken line, so v0.3.52 and earlier could leave many perfectly visible NPCs silent. v0.3.53 resolves the corresponding hand-ported Gen1Recomp talk handler and replays only its **dialogue presentation** through the Kanto UI.

The dialogue bridge is detached from Gold/Silver state: it receives a deep-cloned save, a fake Kanto overworld, and a Yellow `GameVersion` facade. Text boxes, YES/NO prompts, and list menus are captured and replayed normally, while battles, warps, scripted movement, screens, audio side effects, object changes, and other story/cutscene commands are suppressed. Dedicated Kanto-safe handlers (trainers, marts, Centers, PCs, rods, trades, Safari, Game Corner, CARD KEY, etc.) still run first, so working gameplay interactions are not replaced with a read-only preview.

Plain extracted NPC text still uses the fast path. `text_asm` uses the new bridge, Yellow-only script modules override the Gold host where necessary (including Yellow Oaks Lab), and an old/incomplete cache with a missing `text_pointers` row gets a final registry lookup. If upstream truly has no recoverable spoken line, the object displays a harmless `...` instead of swallowing A. A region-build audit records plain/scripted/service/missing-pointer counts and runtime diagnostics record handled, recovered, suppressed, fallback, and error totals.

Version: v0.3.53

## v0.3.52 Kanto Game Corner entrance + field-index parity

KANTO FREE ROAM now restores the **physical Rocket Hideout entrance in Celadon Game Corner** without enabling Yellow story progression. The companion reads the extracted `field.gameCornerPoster` record, keeps the authored entrance block closed until the poster switch is used, persists `EVENT_FOUND_ROCKET_HIDEOUT` in Kanto-local physical state, and opens the live block for both collision and voxel rendering. Repeating the interaction does not rebuild an already-open chunk.

The Rocket guarding that poster is also physical state now: once beaten he no longer remains as a solid blocker, and saves that already defeated him before v0.3.52 are migrated on entry. This mirrors the useful world result—access to the poster—without importing his Yellow walk-away/cutscene script.

For performance, the region's immutable field index now also covers **spinner-arrow coordinates and badge-gate checkpoints/rows**. Viridian Gym/Rocket Hideout spinners and Route 22/23 badge checks therefore use direct lookups while preserving the extracted movement, badge, row-width and failure-text rules. No render quality or voxel detail is reduced.

Version: v0.3.52

## v0.3.51 Kanto elevation + Bicycle parity

KANTO FREE ROAM now applies Gen1Recomp's extracted **tile-pair collision** layer in addition to ordinary destination-tile passability. This restores cave/forest elevation edges where both adjacent cells can be walkable on their own but the authored transition between their tile ids is forbidden. The same rule is used by DIORAMA/grid movement and the continuous FIRST/THIRD PERSON body, with land and surfing pair tables kept separate.

The **KANTO FIELD** menu now includes BICYCLE when Gold owns one. Mounting is allowed on the extracted Gen1 bike-riding tilesets and the Route 23 / Indigo Plateau map exceptions; forced Cycling Road refuses dismount until its gate clears the forced-bike lock. Leaving the forced stretch no longer kicks the rider off automatically—you can remain mounted and dismount normally afterward.

For performance, those immutable field rules are indexed once when the Kanto region is built: elevation pairs, bike allowlists, dark maps, Cycling Road slope/clear maps and force-bike cells all use direct lookups in the hot movement path. This does not lower voxel/model/render quality.

Version: v0.3.51

## v0.3.50 Kanto Cycling Road + optimization

KANTO FREE ROAM now follows the extracted Gen1 `field.forcedMovement` data for the Cycling Road instead of treating Routes 16-18 as ordinary terrain. The authored force-bike tiles silently mount the bicycle when Gold owns one, Route 17 rolls downhill while idle, held **A/B** brakes the roll, and an actual held direction wins. Downhill uses bike-speed movement while Route 17 steering stays at normal step timing. SURF is refused while the forced-bike flag is active.

This pass also reduces Kanto runtime overhead without lowering visual quality. The companion keeps a visit-local write-through cache for its own door/trainer/boulder/event tables instead of repeatedly crossing `mod.save`, and dynamic multi-block restamps are batched so a Silph floor with several door changes refreshes its voxel chunk once rather than once per door. Cut block changes share the same refresh path. The cache is discarded when entering/leaving Kanto so a new/replaced save cannot inherit stale state.

The Route 16/18 gate clear maps also end the companion's forced-bike presentation. Native Gen1 can keep the bike mounted there, but this companion still has no standalone Kanto Bicycle item action; clearing both flags prevents trapping the user in a forced movement mode while preserving the physical Cycling Road segment itself.

Version: v0.3.50

## v0.3.49 Kanto dynamic interiors + physical event parity

This pass returns to Kanto world reconstruction after the Android framing repair. KANTO FREE ROAM now owns a small **story-free physical event store** for geometry that Yellow normally changes from map scripts, without executing Yellow cutscene/story ASM or writing those flags into the Gold save.

Silph Co 2F-11F now stamps its authored closed door blocks before collision/meshing sees the map. Using Gold's `CARD_KEY` on a matching locked door opens only that door and persists the exact Yellow unlock event, including the special 11F block. Rocket Hideout B1F now begins with its lift gate barred and opens as soon as the guard event is earned; Yellow B4F deliberately remains open because Yellow has no B4F gate callback. Existing pre-v0.3.49 Kanto trainer wins are migrated through extracted trainer-header events so upgrading does not re-lock a gate already earned.

Vermilion Gym's fifteen trash cans are live too. The first-lock roll, second-lock adjacency selection, wrong-can relock/reroll, solved-door block `(2,2) -> 5`, and the cartridge's zero-mask/underflow-to-can-0 bug are reproduced from the extracted field rules. The solved geometry persists in the Kanto companion state.

Version: v0.3.49

## v0.3.48 Android Gold/Kanto giant-zoom fix

The remaining Android zoom was not a Kanto camera-distance problem. Gold's current `World:drawPipeline()` draws the returned pipeline image directly in **logical scene units**, while v0.3.47 normalized every Android frame to the **physical framebuffer** contract used by Gen1's `Renderer.worldOverride`. On a HiDPI phone that makes a 2x/2.75x source get drawn 1:1 into a logical-sized Gold scene, so only the upper-left portion is visible and the world looks hugely zoomed.

v0.3.48 makes output sizing generation-aware: Gold/Gen2 returns the exact logical drawWorld dimensions supplied by Game2; Gen1 retains physical framebuffer/TouchSkin normalization. Internal GRAPHICS RESOLUTION still scales privately and is restored to the host-required size before presentation. Kanto warp, ledge and route-edge work from v0.3.45-v0.3.46 is unchanged.

## v0.3.47 Android framing fix

The Android Kanto/voxel view now follows the exact drawable rectangle used by current Gen1Recomp instead of treating the entire phone framebuffer as gameplay. On mobile skins, Gen1Recomp can reserve part of the framebuffer for touch controls; v0.3.47 renders the 3D world only into the remaining `TouchSkin.viewport` area and returns a correctly normalized full-frame pipeline canvas. This fixes the heavily zoomed/cropped appearance that could occur when Kanto's smaller world view was projected over the full phone surface.

The same normalization also makes the PC/mobile internal **GRAPHICS RESOLUTION** presets safe on the official `drawWorld` path: a 55% scene is upscaled into the correct gameplay rectangle before the engine's 1:1 worldOverride composite. Android camera slider, right-look and DIORAMA pinch now share the same drawable geometry. v0.3.46 ledges/route-edge fixes and v0.3.45 warp/interior fixes are unchanged.

Version: v0.3.47

## v0.3.46 Kanto ledges + route-edge parity

This pass continues Kanto world reconstruction. Yellow's extracted `field.ledges` table is now live in KANTO FREE ROAM: matching one-way cliffs perform a real two-cell hop in grid/DIORAMA, authored forced movement, and FIRST/THIRD PERSON. If the landing crosses a connected outdoor seam, the destination is solved with the authored route offset rather than being refused. The Kanto player proxy also exposes the hop arc as vertical sprite lift so the 3D trainer rises over the ledge instead of sliding across it.

Connected-route handoffs are stricter too. A shifted route connection only accepts cells inside its actual overlap strip; coordinates outside the overlap are rejected instead of being clamped into a destination corner. This keeps v0.3.45's neighbour collision/Surf checks while removing another source of bad Kanto edge landings and softlock-shaped corner snaps.

Version: v0.3.46

## v0.3.45 Kanto warp + interior parity

This pass keeps the v0.3.44 viewport/THIRD PERSON fixes and returns to Kanto world correctness. The private Yellow `ForeignGen1Map` adapter now mirrors current Gen1Recomp's width-based warp/sign indexing, border-extended water/door/warp queries, connection/sign surface, and FACILITY/CAVERN/INTERIOR warp-pad/hole classification.

Completed Kanto steps now run the same second warp arm as current Gen1Recomp: after an ordinary door/warp-tile arrival check, a non-door warp square may fire `ExtraWarpCheck` when the facing direction is still held or when Kanto forced movement owns the step. This repairs carpet/edge-style interior transitions that could otherwise leave the player standing on an inert warp coordinate.

Story/cutscene ASM remains disabled. The one documented physical dungeon fall that is gameplay geometry rather than story progression is restored directly: Yellow Victory Road 3F cell `(23,15)` falls to Victory Road 2F `(22,16)`.

Version: v0.3.45

## v0.3.44 current Gen1Recomp viewport compatibility

This release keeps v0.3.43's THIRD PERSON animation and Kanto frame-pacing fixes, and adds compatibility with current Gen1Recomp's optional `GameViewport` layout layer. Voxel render sizing, Kanto camera centering, internal render resolution, Android camera-slider input, direct right-thumb look and DIORAMA pinch now stay in the game-local viewport instead of assuming the entire OS window belongs to gameplay. Older hosts without `GameViewport` retain the previous whole-window behavior.

Version: v0.3.44

## v0.3.43 THIRD PERSON animation + Kanto frame pacing

THIRD PERSON continuous movement now feeds Gold's native 0/1 walk phase into the captured player pose, so custom six-frame player sheets and Character Selector/`red_3d_player` skins animate like they do in DIORAMA even though true-direction movement intentionally keeps the gameplay `Player.moving` flag false. The external 3D-skin bridge also mirrors a temporary native 16-frame `progress/target/stepFrames` state around the renderer call and restores every gameplay field immediately afterward.

Kanto shared-world promotion no longer synchronously builds an unused FULL/apron mesh whenever the current Yellow map changes. A connected sector reuses its persistent BODY mesh; a genuinely cold direct warp queues an urgent BODY upload cooperatively. Persistent cache-only cooking is now motion-aware: while the player is moving it receives about a 0.5-1.5 ms desktop slice instead of the old 22-35 ms BALANCED/FAST visible-frame slice, and visible idle cooking is capped at 3-10 ms. Covered/menu frames remain the aggressive PC warm-up window. The Kanto disk warmer also latches complete instead of rescanning the entire region every render frame after all sectors are prepared.

Version: v0.3.43

## v0.3.42 shared-world Kanto outdoor rendering

Kanto outdoor maps now render as one stitched Gen-2 voxel world component using authored BODY chunks only. Connected Pallet/town/route bodies share the solved world coordinates and no longer receive a separate 32-tile synthetic rock/tree apron per map. This removes the repeated border belts seen in wide Kanto views, lowers mesh residency/build work, and makes the existing persistent BODY cache the primary Kanto terrain cache. v0.3.41 viewport centering/canonical spawn, Gen-2 palette/material projection, and custom-player anchoring remain intact.

## v0.3.40 canonical Pallet entry + stricter native Gen-2 colors/textures

KANTO FREE ROAM no longer guesses which Pallet warp to use when a Yellow cache exposes opaque/numeric destination ids. Yellow's canonical Red-house doorway is fixed at cell `(5,5)`, so entry is now restricted to the immediate authored land cells around `(5,6)` instead of widening into the rest of the town. Every Kanto position record older than entry revision 340 -- including v0.3.39 -- is migrated once back to Pallet on first entry, so an already-stamped tree-belt position is repaired without clearing the save. Pallet resumes are also rejected if they resolve to a warp/NPC, border-filler block, water/door/structure presentation tile, or a cell disconnected from the canonical landing.

The Gen-2 projector now treats generic surface donors as **pure-use only**. A Gold/Silver graphics tile that appears anywhere inside a blocked/tree/roof/structure collision cell can no longer be reused as Yellow walkable ground merely because the same 8x8 art also appears in a walkable quadrant. This removes the worst ground-to-tree/roof substitutions. When a texture match is accepted, its pixels are now resolved directly through that exact donor tile's native PalMap slot and 2bpp shade, rather than passing through a broad semantic color fallback. Unique Yellow silhouettes remain only where no safe Gen-2 texture exists.

The presentation/cache revisions are `g2-native-340-r1` and `g2vx-340-r1`, so Kanto sectors generated by earlier projection rules rebuild once and then return to normal persistent-cache hits. The v0.3.38 arbitrary custom-player anchor fix remains unchanged.

Version: v0.3.40

## v0.3.39 Kanto entry hardening + exact Gen-2 materials/colors

KANTO FREE ROAM now performs a one-time migration of every pre-v0.3.39 Pallet resume instead of trying to recognize one legacy bad coordinate. The landing is rebuilt from Pallet's authored Red's-house warp, and future Pallet resumes must stay inside the same connected walkable component and may not occupy a warp/NPC cell. This closes the remaining right-side/tree-pocket spawn variants.

The Gen-2 projection is also stricter and more native. Donor graphics are classified with Gold/Silver's real COLL_* semantics **plus** the authored voxel profile, so tree/fence/sign/roof/ledge/wall/stair/furniture/prop graphics can no longer be mistaken for generic ground just because their 16px collision cell is walkable. Same-shape Kanto-to-Gen2 matches are projected more aggressively, and 2bpp shade selection now uses the exact GoldColorAtlas rounding while keeping the donor tile's exact PalMap slot.

The persistent sector cache moves to a new geometry revision and signs the synthetic projected tileset/donor/revision. Old v0.3.32-v0.3.38 Kanto meshes are therefore rebuilt once instead of resurrecting stale pre-projection trees/walls. Completed v0.3.39 sectors remain persistent normally after that first rebuild.

Version: v0.3.39

## v0.3.38 Gen-2-native Kanto projection + custom player anchor

Yellow remains Kanto's map/gameplay source, but its presentation is no longer just Yellow art recolored with a broad Johto profile. Each Kanto map first looks for the same map in Gold/Silver and uses that native Gen-2 tileset/palette as its presentation donor; outdoor fallbacks prefer `TilesetKanto`, interiors prefer a matching Gen-2 tileset, and Johto is the final safe donor. Matched Yellow tiles inherit the donor's real texture, exact PalMap slot and remapped voxel shape metadata (ground/grass/water/tree/fence/ledge/door/structure). Generic surfaces are projected aggressively; unique Kanto landmarks keep their Yellow silhouette while taking the nearest Gen-2 material palette. Yellow collision, warps, NPCs, encounters, Cut/Strength state and story-free gameplay remain authoritative.

Custom player voxel cards now use the sprite definition's real `frameWidth`, `frameHeight`, `anchorX` and `anchorY`; the old fixed 16x16/x=8 assumption could draw wider skins such as Sonic to the left of the real player body. The fix applies in both Johto and Kanto and does not move collision/gameplay coordinates.

Version: v0.3.38

## v0.3.37 Kanto Pallet spawn repair

KANTO FREE ROAM now derives its Pallet landing from the authored Red's-house/front-door warp even when the Yellow cache stores destination IDs opaquely. The old v0.3.36 map-dimension fallback that could place the player in the right-side trees is removed, the landing rejects warp/NPC cells, and the exact persisted bad spawn is migrated automatically on entry.

Version: v0.3.37

## v0.3.35 Kanto second-region systems

Kanto now keeps its own Pokemon Center respawn/Teleport point, preserves the hidden Johto return location across Kanto whiteouts, exposes Gold-authorized `KANTO FIELD` FLASH/DIG/TELEPORT, renders Rock Tunnel darkness, runs extracted Yellow spinner arrows, collects hidden coins into Gold's Coin Case counter, and enforces Route 22/23 badge gates from Gold's Kanto badges. v0.3.34 Seafoam/Fly/hidden interactions remain intact. Current Yellow imports are recommended because these systems consume current `data/generated/field.lua`.

Version: v0.3.35


## v0.3.33 — Kanto field moves + trainer/NPC world behavior

- Yellow Kanto now supports **CUT** against Yellow's authored OVERWORLD/GYM cut tiles and `field.cutTreeSwaps`, but the user/eligibility authority is Gold/Silver: a Gold party member must know CUT and the Johto **HIVE** badge must be owned. Cut block changes persist in the Kanto mod-save namespace.
- A Cut mutation calls the live voxel mesher's in-place refresh path, keeping the stale sector visible while the changed map rebuilds and invalidating that map's persistent sector-cache signature.
- Yellow `SPRITE_BOULDER` objects now support **STRENGTH** using Gold's party and Johto **PLAIN** badge authority. Activated Strength allows safe one-cell pushes; boulder positions persist across Kanto visits and cannot push onto walls, water-only cells, warps, Pokemon or other actors.
- Trainer headers now drive automatic **trainer sight**: undefeated trainers engage in their forward-facing line up to the extracted inclusive range and move adjacent before Gold's existing scripted battle takes ownership. Gym leaders and trainer win persistence continue through the v0.3.28 Gold battle bridge.
- Current Yellow map caches store stationary object facing in the object `range` field (`SPRITE_FACING_*`), not in `movement`. Kanto now decodes that shape correctly, fixing many NPC/trainer facing directions.
- Authored Yellow `WALK` NPCs now roam within their source movement range, animate between cells and avoid the player, Pokemon, actors, walls and warp cells.
- v0.3.32 persistent sector caching/cooking, v0.3.31 hard region residency/streaming, v0.3.30 true-direction movement + Johto visuals and v0.3.29 camera correction remain intact.

**Not faked in this release:** Seafoam's special boulder-hole/current cascade still requires its extracted hole/event wiring; ordinary Strength boulders work, but special hole drops remain reserved for the dedicated Seafoam pass.


## v0.3.32 — Persistent sector cache + PC warm-up

- **PERSISTENT SECTOR CACHE** is rebuilt and ON by default. It stores the final raw voxel BODY/FULL terrain meshes through Gen1Recomp's persistence backend, so a repeat visit skips the expensive map-structure and geometry derivation pass.
- Yellow Kanto now background-cooks every outdoor BODY sector into that cache without keeping those far meshes resident on the GPU. Real visible terrain always has priority.
- On desktop, cache-only jobs get a much larger idle CPU budget than mobile. `MESH BUILD RATE = FAST LOAD` makes the cooker more aggressive.
- Direct and movement-predicted Kanto neighbors preload both cached BODY and exact FULL seam geometry before visibility, so a first visit has a ready stand-in and later visits normally restore from disk instead of rebuilding.
- Cache entries validate geometry revision, complete map tiles, tileset/UV layout, slot, seam masks and binary byte counts; metadata is committed last. Bad/stale/interrupted cache files become safe misses instead of rendering corrupt terrain.
- Hard Johto/Kanto unloading from v0.3.31 remains: returning to Johto cancels unfinished Kanto warm jobs and releases Kanto render resources, but finished sector files remain on disk for the next Kanto session.


## v0.3.31 — Kanto predictive streaming + hard region residency

- Johto and Yellow Kanto no longer stay render-resident together. While in Johto, the foreign Yellow graph is not progressively materialized beside Gold. Entering/leaving Kanto is a hard voxel-residency boundary, so the previous region's mesh/structure neighbourhood is evicted immediately instead of keeping one whole prior neighbourhood warm.
- RETURN TO JOHTO now releases Kanto's private decoded terrain atlases, sprite ImageData/images, foreign map adapters, NPC/Pokemon presentation caches and sector cache while preserving the lightweight imported Yellow source tables plus persistent position/items/trainers/Gym state.
- Kanto's directly connected sectors now request a cheap body mesh while still offscreen. Second-ring sectors are predictively prefetched when they lie ahead of the current movement vector. This lets nearby terrain finish building while the player is standing still instead of only starting once the camera/player walks into it.
- Far neighbour maps are distance-rejected before `entitiesForMap()` runs, avoiding needless NPC sheet decoding and ambient Stadium Pokemon creation for sectors that cannot contribute to the current view.
- Kanto sector BFS results are cached per root/radius and the Gold/Johto palette-profile poll is throttled to four checks per second instead of rebuilding semantic profile work at presentation FPS.
- A Kanto tile that safely pattern-matches a real Johto donor now uses that donor tile's exact Gen-2 PalMap slot as well as its Johto pixels. Unique Kanto art still uses the semantic fallback, improving color accuracy without mangling landmarks.
- v0.3.30 true directional Kanto movement, v0.3.29 rendered-world camera collision, v0.3.28 story-free Yellow gameplay and v0.3.25 Stadium announcer playback remain intact.

## v0.3.30 — Kanto true movement + Johto visual match

- Yellow-derived Kanto FIRST/THIRD PERSON movement is now true 360-degree camera-relative movement: analog magnitude, diagonals, circular collision and wall sliding instead of final cardinal quantization. DIORAMA and SURF deliberately keep the safe grid mover, matching Johto's special-state behavior.
- Kanto no longer uses Yellow-authored palette families. It resolves a canonical Johto outdoor palette profile and applies the same Gold/Silver semantic slots to Kanto water, grass, ground, doors and structures.
- A guarded Johto texture-donor pass compares Kanto 8x8 source patterns only against donor tiles in the same semantic class. Close matches use the actual Johto tile pattern; unique Kanto landmarks keep their own source art.
- v0.3.29 Kanto camera-context correction, v0.3.28 story-free Yellow gameplay, v0.3.27 native Kanto parity and v0.3.25 Stadium announcer playback remain intact.

**v0.3.28 Yellow Kanto free-roam core:** the imported Pokemon Yellow region is now treated as a persistent second-region runtime inside Gold/Silver instead of a Pallet-only visual excursion. The Kanto renderer preserves Yellow's authored town/route/cave/interior palette families instead of borrowing the hidden Johto map's palette. NPCs and signs resolve the current Gen1Recomp `text_pointers.lua` tables, while `text_asm` story/cutscene entries remain deliberately disabled. Yellow trainers and all eight Gym Leaders use Gold's Gen-2 battle runtime and the Gold party; Gym victories populate Gold's actual Kanto badge store. Yellow item pickups, trainer wins, static Pokemon outcomes and the last Kanto position persist across RETURN TO JOHTO. Yellow Marts feed Gold's bag/economy, Pokemon Centers call Gold's own full-party heal routine, PCs open Gold storage, roaming/classic encounters feed Gold catching, and Gold SURF can traverse Yellow water. This is a free-roam conversion, not Yellow story progression. Re-import Yellow with a current Gen1Recomp build if an older cache does not contain `text_pointers.lua` / `trainer_headers.lua`.


**v0.3.27 native Gen-2 Kanto parity:** this pass removes the remaining renderer behavior that was granted by the literal Johto tileset name instead of by Gen-2 artwork/metadata. Kanto trees now use the same authored stepped-crown hull path as Johto through per-tileset `tree_crown` metadata; explicit `tree_art` drives forest-border/apron inference; and per-cell source-art checks keep boulders, cut trees, urns and other round collision props from being misclassified as full trees. Shared Gen-2 hop-lip/ledge and collision-class shaping remains region-neutral, while Kanto deliberately keeps its own tile IDs instead of copying Johto's metatile vocabulary. The conservative Kanto framed-building fallback also expands from house-sized candidates to landmark-sized facades (up to 40×32 source tiles) while retaining the same complete base-frame, recognized roof-cap, real-door and exact-template-first guards. This retains all v0.3.26 Kanto building/seam/warp repairs and the v0.3.25 Stadium 1 announcer playback path.

**v0.3.26 Kanto repair:** this pass targets both Kantos in the project. Gold's native Gen-2 `TilesetKanto` now keeps a conservative set of unmistakable roof tiles top-facing and can derive full voxel buildings from Kanto's real roof/base/door frame when a one-off facade does not match the exact house/Mart/Gym/Lab catalogue. Exact templates still win first. The optional Yellow companion-region Kanto also repairs stale one-way/reversed map seams, includes `PLATEAU` maps in the outside graph, follows Gen1Recomp-style arrival/collision/edge warp behavior and `LAST_MAP` memory, rejects malformed warp destinations instead of dropping the player into a map center, and automatically recovers invalid excursion coordinates back to Pallet Town.


**v0.3.25 Stadium announcer playback fix:** the Stadium 1 importer remains one shared PC/Android flow. ROM-derived WAVs are persisted through Gen1Recomp's normal persistence backend, but playback no longer assumes those files are visible by the same relative path to `love.audio`. The announcer now reads each WAV back through the exact backend that stored it and feeds the bytes directly to LÖVE as WAV data. A new **TEST STADIUM ANNOUNCER** action plays Brock's known clip 223 immediately after import, so voice playback can be checked without entering a battle. Re-import Pokemon Stadium (USA) v1.0 once after installing v0.3.25.

**v0.3.22 StadiumBattleFX completeness audit:** a second file-by-file audit found that v0.3.21 had preserved all 77 source Lua modules but had not yet routed several of the original 2.1.7 behaviors into Gold's active battle path. The exact source `StadiumFxPlayer`/native scheduler and dedicated traced move families are now active; an optional private Stadium 1 cache supplies the original 151×165 attachment/camera metadata; native camera selectors/cut timing drive the existing live battle camera; source borderless screen-FX replay, fallback notices, logging/diagnostic export and cache rebuild actions are wired. The audit also documents the few source model/provider/importer components deliberately superseded by this mod's richer Gold-aware 001–251 Stadium2 renderer/live-world battle architecture rather than installing conflicting owners. See `STADIUM_BATTLE_FX_AUDIT.md`.


**v0.3.21 StadiumBattleFX 2.1.7 port:** the supplied MIT StadiumBattleFX source is now embedded and adapted to Gold's existing Stadium2/live-world battle stack. The full 165-move source timing/dispatch roster feeds attack presentation, source-calibrated cartridge/procedural overlays can be enabled, effects can follow live Stadium2 model attachments, source attack-camera stages are merged into the existing camera, and optional hit/faint reactions, Stadium 1 boss rooms, trainer portraits, announcer routing and captions are available under **BATTLE**. A privately imported Pokemon Stadium (USA) v1.0 ROM unlocks the ROM-derived effect/arena/portrait caches. The public source ZIP contains no announcer WAVs, so audible calls require a locally built personal voice pack; captions work without one. See `STADIUM_BATTLE_FX_PORT.md`.

**v0.3.20 modern live-battle mechanics:** LIVE OVERWORLD BATTLES now feel less like a turn-based model standing on a movable marker. Left-stick/WASD control has analog acceleration/deceleration, soft arena-edge sliding and a combat tether; contact attacks visibly lunge toward the target and return; real HP damage produces visual knockback; and the Stadium camera follows those temporary combat positions with attack FOV, impact zoom and damage-scaled shake. Gold still decides every real battle rule and HP change. Configure **BATTLE → MODERN LIVE BATTLE MOTION**, **BATTLE MOVEMENT FEEL**, and **BATTLE IMPACT FEEDBACK**.

**v0.3.17 airborne 3D-player continuity:** crossing a connected map while flying no longer lets Gold's destination-map `CheckUpdatePlayerSprite` replace the active Character Selector 3D trainer with a Surf/Bike/stock 2D card. Flight now keeps Gold's underlying player state NORMAL while airborne and explicitly keeps the 3D rider presentation active through both ordinary and unrestricted connection handoffs.

**v0.3.16 unrestricted route flight + living skies:** physical free flight no longer checks whether the destination map was previously visited. If an outdoor map has a normal Gold connection, crossing that edge while airborne loads it just like any other connected route, including unexplored areas. The old DISCOVERY GATES setting has been removed because physical flight should not behave like a fast-travel unlock list.

Outdoor voxel maps can now also contain a small number of **ambient flying Pokémon**. They are not arbitrary global spawns: the system prefers airborne species from the current map's encounter data, then connected routes, and only then falls back to conservative location/time pools (forest, coast, mountain, ruins, cold areas, towns, day/night). They are render-only Stadium/voxel entities with no collision, battle, encounter-RNG or gameplay-entity ownership, and their sun shadows are disabled for performance. Configure them under **FLY YOUR POKéMON → AMBIENT SKY POKéMON / SKY POKéMON DENSITY**.

**v0.3.15 flight control fix:** v0.3.14 captured the correct controller vector during Gold's `world:pollInput()` call, but Gold calls that seam *before* `world:step()`, and the v0.3.14 `stepBody` guard reset the copied vector to `0,0` before Flight consumed it. v0.3.15 removes that fragile handoff completely. While airborne, Gold's normal ground/free-walk intent is suppressed and Fly Your Pokemon reads the live engine left-stick/D-pad state directly once per logic tick. FIRST/THIRD PERSON steering remains camera-relative; DIORAMA steering is map-relative. Releasing the stick stops immediately, direction changes apply on the same tick, and Circle/B keeps the proven v0.3.13 crash-safe landing path.

**v0.3.14 flight steering fix:** v0.3.13 solved the controller/landing crash but accidentally short-circuited `GoldCameraControls:pollInput`, which is the owner that converts the current D-pad/left-stick into a camera-relative world vector. That left its previous continuous-movement intent alive, so flight could keep replaying the last direction (commonly straight forward) while new steering appeared dead. Flight now lets GoldCameraControls sample the current stick every logic tick, copies that fresh vector into the air solver, clears GoldCameraControls' own movement fields before its free-move tail can act, and moves the flying player exactly once after the native world body. Releasing the stick produces a zero vector, so there is no auto-forward. D-pad, analog left stick, camera-relative steering, map-edge flight and existing flight speed/boost remain active. Circle/B LAND and all v0.3.13 crash isolation are unchanged.

**v0.3.13 landing crash isolation:** the remaining global `love.gamepadpressed`/`gamepadreleased` flight bridge is gone. Circle/B now reaches Gold normally, is translated to logical GB **B**, then is intercepted at the documented `input.step` seam before `Input:step` or `World:step`. LAND is committed there as a minimal state change: no live world-method restoration, no Stadium-carrier retag/delete/park operation, no option-file write, no SDL land-button poll and no controller vibration occur in the landing frame. The carrier simply stops being submitted to the voxel renderer. This removes the remaining conflict points with ControllerLayout, BattleControllerUI, CamControl, PerformanceRuntime, Gold interaction and SDL haptics while keeping PlayStation **Circle** / Xbox **B** / Switch **B** (or keyboard **H**) as LAND. Cross/A, Square/X, Triangle/Y, START and SELECT remain quarantined while airborne.
For this crash-isolation build, controller LAND completes only over solid walkable ground; over water it stays airborne and shows **LAND OVER SOLID GROUND** instead of mixing flight teardown with Gold's Surf state in the same input transition. Use the Pokémon **SWIM** action for water traversal.


## v0.3.02 — Fly is now an actual Mod Settings gameplay option

- **FLY = ON/OFF** directly starts/stops free-flight riding.
- **FLYING POKéMON** selects AUTO or a supported eligible flying party Pokémon.
- The setting and H/X shortcut stay synchronized, so Mod Settings reflects whether Flight is active.

This release replaces external flight-mod ownership with a native **Fly Your Pokemon** system inside this package. Flight uses **H** (or the optional controller mount shortcut), Ground Ride uses **G or J / controller Y**, **M** cycles eligible party mounts, and **Page Up/Page Down or R2/L2** controls manual altitude. First/third-person voxel cameras get continuous free-flight movement while the ordinary camera keeps Gold's native grid/connection flow.

Supported public feature set includes Flight, Ground Ride, Visible Surf, species rosters for Gen 1+2, Fly/Surf + badge gates, story/landing safety plus unrestricted connected-map exploration, altitude and vertical-speed controls, Flight Boost, Ground Gallop + HUD, reverse ledge jumps, Suicune amphibious land/water travel, optional air encounters against visible roaming Pokemon, rider/follower visibility, mount cries/rumble, map-music or quiet-flight behavior, 2D/Stadium renderer selection, realistic sizing and per-species size overrides. Stadium mounts keep their imported skeletal animation and receive mounted whole-model pitch/bank/buoyancy transforms.

The active Dramatic Sky Ride compatibility/ownership paths have been removed; this mod now owns mounted movement and rendering itself. No external mount mod or external music is bundled or required.

## v0.3.00 — Transparent HP/EXP HUD paper fix

This release is rebuilt directly from the verified v0.2.98 baseline. **TRANSPARENT BATTLE UI BG** now removes the remaining white pixels baked into Gold's HP/EXP HUD tile sheets, so custom/live battle backdrops show through behind and below the bars while the black borders, text, colored HP/EXP fills, custom player-sprite system, and v0.2.98 picker behavior remain intact.

### v0.2.98 — Animated custom player + transparent battle UI

Adds **3D MODELS → CUSTOM PLAYER SPRITE** and **PLAYER SPRITE SHEET**. The picker accepts PNG/JPEG/BMP on desktop and Android/iOS, stores the chosen image under a fresh revisioned save-backed filename, and hot-swaps the live Gold player without a restart. The animation sheet is one vertical strip of six equal frames in this order: **Stand Down, Stand Up, Stand Left, Walk Down, Walk Up, Walk Left**. Gold automatically mirrors left for right-facing and uses its native step cadence, so turns, walking, bike-speed movement and ledge-jump offsets remain synchronized. PNG alpha is preserved and is recommended. When the custom player is active it takes visual priority over the Character Selector 3D human model while leaving Stadium Pokémon models untouched.

Adds **BATTLE → TRANSPARENT BATTLE UI BG**, enabled by default. It removes opaque white paper fills behind Gold's battle HUD/message/command boxes while keeping the full battle backdrop, text, borders, HP/EXP presentation, Pokémon/models and translucent attack flashes. Turn it OFF to restore the cartridge-style white UI paper. This works both over LIVE OVERWORLD BATTLES and over a selected custom 2D battle background.

The three mobile file consumers — Stadium 2 ROM, custom battle background and custom player sprite — now use mutually exclusive pending markers around Gen1Recomp's shared native staging filename so one picker cannot steal another pick. The v0.2.97 revisioned battle-background replacement fix remains included. No DSM7 rebuild is required.

## v0.2.97 — Battle background replacement fix

Fixes the v0.2.96 case where a selected PNG could remain stuck after choosing another image. Every successful pick gets a fresh revisioned internal filename, the new image is decoded before it becomes active, and the old JPG/PNG/BMP is removed only after the replacement is confirmed. **A/Confirm or Right** chooses/replaces the image and **Left** restores Gold's default white battle background.

The custom image replaces the white 160x144 paper behind Gold's native 2D battle sprites. **LIVE OVERWORLD BATTLES** continues to use the real voxel encounter scene and automatically takes priority; turn that option OFF when you want the custom classic battle background visible. The Android/iOS picker uses a separate pending marker so its shared native staging filename cannot collide with Stadium 2 ROM import.

## v0.2.95 — Johto-colored Kanto + Kanto 3D model/player fixes

Kanto keeps Pokemon Yellow map/collision/object/trainer/encounter data, but its terrain now uses the **same active eight-slot Johto/Gold background palette profile**. Yellow water, grass, walkable ground and structures are mapped to matching live Johto palette roles rather than being flattened through one averaged tint.

Kanto roaming/authored Pokemon now remain eligible for the installed **Stadium 2 3D model pack** even if a 2D follower sheet cannot be generated. The Kanto player proxy also feeds its actual Kanto position, facing and animation clock into the selected **3D Character Selector** skin only while rendering, so walking animation and body direction no longer stay stuck on the hidden Johto player. FIRST/THIRD PERSON movement in Kanto is camera-relative like Johto.

## v0.2.86 — Performance Presets + Perimeter Ocean + Yellow Gyms

v0.2.86 keeps every existing Stadium/voxel/Kanto feature and targets the lag introduced by the larger twin-region world. **MOD SETTINGS → PERFORMANCE / GRAPHICS** now has LOW, MEDIUM, HIGH, ULTRA and CUSTOM presets plus PC-style resolution, shadow, reflection, draw-distance, Kanto-prefetch and mesh-build controls. MEDIUM is the default; ULTRA restores the maximum presentation.

**WORLD OCEAN is now coastline-only.** Water is generated as perimeter strips outside Gold/Kanto land rather than a huge reflective plane underneath the whole world, and an offscreen coastline is skipped before the reflection pass. Kanto survey maps and voxel meshes now stream progressively/cull by view instead of keeping every distant region hot.

The Yellow excursion also passes the **original Gold player** into `red_3d_player` / 3D Character Selector while using the Kanto pose, so selected/imported skins stay active after KANTO FREE ROAM. Authored Pokemon Yellow trainers can now be challenged by interacting with them: their Yellow party/levels are converted into Gold's supported trainer-battle runtime, including the eight Yellow Gym Leaders. Victories are stored in this mod's own bucket. **Yellow story/cutscene progression is still not run**, so the Gold save remains the authority.

## v0.2.84 — Kanto + Pallet Runtime Fix

v0.2.83's Kanto loader was accidentally asking Gold's Gen2Compat `src.world.Map` alias to classify imported Gen-1 maps. That alias correctly understands Gold collision/environment records, but an inactive Red/Blue/Yellow map uses Gen-1 `OVERWORLD`/tile-list semantics, so the entire Kanto graph was rejected before rendering. v0.2.84 uses a private Gen-1 map adapter instead and hardens inactive-cache reads.

**GEN-1 KANTO REGION is now a standalone toggle.** You no longer have to enable OPEN WORLD separately. Turning Kanto ON temporarily promotes full-world voxel residency, places imported Gen-1 Kanto east/right of Gold, and unlocks the extended survey zoom without changing your saved OPEN WORLD preference. **KANTO FREE ROAM** now uses that corrected loader and lands outside Red's house near Oak's Lab; **RETURN TO JOHTO** still reveals the untouched Gold position. No Stadium DSM7 cache rebuild is required.

## v0.2.83 — Pallet Town Teleport Excursion

Gold's START menu now includes **KANTO FREE ROAM**. It opens the imported Gen-1 Kanto terrain specifically at **PALLET TOWN**, selecting a walkable tile immediately outside `REDS_HOUSE_1F` so Red's house and Professor Oak's Lab are in the starting neighborhood. While there, the same row becomes **RETURN TO JOHTO**.

The excursion is deliberately presentation-local: Gold's real map/player/save coordinate remains untouched underneath. Outdoor Gen-1 movement uses the imported Red/Blue/Yellow map collision and connected-map graph, while Gen-1 NPC scripts, interiors, encounters and save-state are not merged into Gold. Returning therefore restores the exact Gold world position instead of converting the save between games. The v0.2.82 WORLD OCEAN / GEN-1 KANTO REGION survey toggles remain independent.

## v0.2.82 — Twin-Region Ocean World

OPEN WORLD can now become a **two-region survey world**. **WORLD OCEAN** adds reflective sea beneath and around the stitched Gold voxel terrain. **GEN-1 KANTO REGION** independently loads the outdoor map graph from an already imported Pokémon Red, Blue or Yellow Gen1Recomp cache and places that Kanto region to the **east/right** of the Gold world, separated by a short ocean gap. The Gen-1 copy is visual voxel terrain in v0.2.82; Gold still owns the live player, collision, scripts, NPCs and warps. Foreign runtime IDs are namespaced, so shared names such as `ROUTE_1` never collide with Gold's mesh caches. Both new features default OFF and can be toggled independently.

To see both regions together: enable **OPEN WORLD**, enable **WORLD OCEAN**, enable **GEN-1 KANTO REGION**, and use **OPEN WORLD ZOOM LIMIT = TWIN 16X** or **ATLAS 24X** for the widest two-region survey. If the Gen-1 region does not appear, import a legal Red/Blue/Yellow ROM once in Gen1Recomp so its generated cache exists.

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

**Current release: v0.3.18**

### Weather FX 4.10 is now built in (v0.3.18)

The old hand-built **3D WEATHER** / **MOVING CLOUDS** system has been replaced. This package now embeds Weather FX 4.10's overworld weather presentation directly into the Stadium2/voxel renderer.

Open **MOD SETTINGS → WEATHER FX**. `WEATHER FX = AUTO` uses Weather FX's regional fronts and location-aware spell system; `CYCLE / SHOWCASE` rotates through visible conditions quickly; any named weather pins that exact condition. `WX PRESENT = AUTO` is recommended: rain/fog/cloud atmosphere is drawn inside the 3D scene when the Stadium voxel host is active, while snow/hail/sand/ash keep Weather FX's screen-space particles where its 3D backend has no world-space particle equivalent. The same system supplies lightning, splashes, rain/thunder/wind audio, seasons and time-of-day weighting.

This embedded port deliberately does **not** install Weather FX's unrelated Steel/Fairy/Dark type changes, Delta/weather-form species, wild encounter substitutions, tornado player warps or battle-rule mutations. Existing battle mechanics, encounter ownership, flight, followers and Stadium systems remain this mod's own.

Weather FX source is vendored under `weatherfx/`. The Kanto Dynamic Weather atmosphere files by Campo (`1-Camp0-1`) retain their MIT licence and notice under `weatherfx/lib/voxel_atmos/`.


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
Use **WEATHER FX** to select OFF, AUTO, CYCLE / SHOWCASE, or one of Weather FX's named conditions. **WX PRESENT** chooses AUTO/3D/2D presentation; AUTO is recommended. Weather FX owns clouds, precipitation, fog, lightning and weather audio. Normal precipitation stays outdoors; optional indoor tint keeps storm ambience without rain falling through roofs.


### v0.2.67 desktop voxel recovery
A fresh Gold options block defaults native `TILT` to OFF/0. While `3D VOXEL WORLD` is enabled, that OFF value now selects the voxel renderer's normal 35-degree diorama camera rather than a literal 0-degree/flat camera. Gold TILT 15/35/50 continue to map directly to those voxel pitches; disable `3D VOXEL WORLD` for the native 2D overworld.
### Voxel performance + frame pacing (v0.3.05)

`PERFORMANCE / GRAPHICS` now includes **FRAME RATE LIMIT** (30/45/60/90/120/144/UNLIMITED). The default 60 FPS cap limits presentation work only; Gold's game simulation and audio timing stay unchanged. This is especially useful on 120-165 Hz PCs/phones where rendering extra voxel frames costs substantially more CPU/GPU without changing gameplay.

The voxel path also avoids work that does not improve the visible picture: steady frames no longer double-pump asynchronous mesh construction, LOW shadows update from their cache on alternating frames, SKY/FAST water skips a world-reflection copy it does not sample, and actors/decorative neighbor passes outside a conservative camera apron are not submitted. Terrain and water keep a wider streaming apron so OPEN WORLD remains visually continuous. HIGH/SOFT shadows and FULL SSR remain available for users who prefer maximum effects.

Under `UI / MENUS`, **L1/R1 GAME SPEED** defaults to OFF. Leave it OFF to prevent L1/R1 (PlayStation) or LB/RB (Xbox/Switch) from accidentally changing Gold's game-speed multiplier; turn it ON to restore Gen1Recomp's normal shoulder-speed shortcuts. L2/R2 are not blocked.

### Party FLY / SWIM and follower spacing (v0.3.04)

Open PARTY, choose a supported Pokemon, and use **FLY** to ride it in free flight or **SWIM** to enter the water on it. Follower behavior also has separate **Player-Follower Gap** and **Pokemon-Pokemon Gap** settings (1-4 tiles). Cross-map follower handoffs reject stale far-away positions and safely rebuild the line at the player instead of teleporting a follower to the opposite edge.

