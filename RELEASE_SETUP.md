## v0.2.81 — Party leader follower rebind

Test trainer FOLLOW mode with `Followers = 1`: put Pokemon A in slot 1, walk with its follower visible, then use Gold's PARTY -> SWITCH to place Pokemon B in slot 1. The follower should change to B on the first overworld frame without a map transition/restart. Repeat with two Pokemon of the same species (preferably one shiny) to verify the object-identity dirty check. Also verify an explicit FOLLOW selection on another party slot remains slot-bound. No Stadium model cache rebuild is required.

## v0.2.80 — Gold 2D follower color fix

- Install over v0.2.79 normally. No Stadium 2 model-cache rebuild is required.
- With `3D POKéMON MODELS = OFF`, confirm the party follower uses its original colored normal/shiny sheet on land and remains colored when entering/leaving water.
- The fix is isolated to the 2D Pokemon/follower art-selection contract; DSM7 Stadium extraction and 3D models are unchanged.

## v0.2.79 — DSM7 eye/mirror sampling

Release validation must rebuild from the Stadium 2 ROM because DSM6 markers are rejected. The rebuilt marker is `DSM7 251 <md5> 1`. Check at least one symmetric/mirrored face with animated eyes, one nonzero SL/TL tile origin, one clamped material, one ordinary repeat material and one zero-mask MIRROR descriptor (which must clamp). National Dex ordering and the separate 3D Pokémon / 3D Player toggles must remain unchanged.

## v0.2.78 — DSM6 material packs + National Pokédex order

Release validation must include a fresh Stadium 2 ROM build because v0.2.78 intentionally rejects DSM4/DSM5 cache markers. The rebuilt marker is `DSM6 251 <md5> 1`. Verify at least one repeat material, one mirrored material, one clamped material, one textureless primitive and a CI4 palette-switched primitive before publishing. The custom Pokédex should list #001 upward regardless of Gold's saved/native dex mode while `CUSTOM UI / MENUS` is ON.

## v0.2.77 — Independent 3D Player / Pokémon switches

The 3D MODELS category now exposes `3D POKéMON MODELS` and `3D PLAYER MODEL` independently. The existing `stadium3dSprites` save key remains the Pokémon-model gate for backward compatibility; new `player3dModel` defaults ON and gates only the Character Selector human-player mesh.

### v0.2.76 Stadium dialogue + whole-world zoom
- Verify normal overworld/script dialogue uses the translucent glass panel while typewriter speed, A/B paging and auto text still behave exactly like Gold.
- Verify YES/NO prompts render as the matching compact selector and still return the correct answer.
- In CAMERA / DISPLAY, test OPEN WORLD ZOOM LIMIT at STANDARD/FAR/WORLD/EXTREME. WORLD should allow 8x diorama distance and EXTREME 12x without changing the 1x startup view.
- With OPEN WORLD ON, native/Character Selector ZOOM should gain one additional whole-region survey rung down to Gen1Recomp's 0.25 safety floor.

### v0.2.75 battle layout + Pokédex full-model fit
- Verify BATTLE COMMANDS at a short/wide window: PACK/DOWN must remain clearly above the footer hint with no text collision.
- Verify several wide/tall Stadium models in the Pokédex (birds, long tails, large bodies): the full animated silhouette must stay inside the 3D viewer while it turns.

### v0.2.74 automatic battle UI startup
- Verify a connected outdoor route/town seam keeps the same Wilds follower visible continuously: v0.2.74 reapplies the captured trailer during `map.entered` for a flicker-free outdoor follower handoff.

Custom Gold live battles now auto-page only their intro PromptButton text, draw the controller command panel before enabling direct shortcuts, and latch any held intro face button until release. This prevents the first unseen controller edge from immediately selecting PACK/FIGHT/PKMN/RUN.

### v0.2.73 moving follower ownership fix

Restores the embedded Wilds trailer as Gold follower slot #1. The native Gen-2 follower is now cleanup/fallback only while Wilds is active, preventing both the v0.2.71 duplicate-owner situation and v0.2.72's frozen/stale survivor regression.

### v0.2.72 Gold follower zone-transition fix

Gold follower slot #1 is now owned exclusively by the engine-native Gen-2 follower. The embedded Wilds controller reserves that slot and only creates additional trailers for follower counts above one; transition cleanup removes orphan native duplicates.

### v0.2.71 Wild Pokémon sandbox recovery

Restores the embedded Wilds runtime on current Gen1Recomp sandbox builds by moving runtime-sheet, sprite, water, follower and luminance file probes off blocked `love.filesystem` / raw `io` and onto mod/engine-owned compatibility APIs. The v0.2.70 voxel renderer and red_3d_player / 3D Character Selector coexistence path remain unchanged.

### v0.2.69 desktop voxel recovery

Desktop returns to the known-good v0.2.45 `render.compose` ownership/canvas-exit behavior. Android/iOS retain nested canvas restoration. The v0.2.68 drawWorld bridge is intentionally inactive.

## v0.2.66

- Fixes Stadium 2 ROM picker/import crashes under current Gen1Recomp sandboxing by using engine-owned picker/platform/persistence/HostShell seams.
- Android/iOS uses the engine document picker and consumes the N64 bytes directly; desktop selection uses a temporary save-directory staging file rather than raw `io.open`.

## v0.2.64

- Boot-recovery release: guarded optional installers, narrow mod-option persistence, Android-only whole-frame patch, and persistent voxel-cache quarantine.

- Fixes remaining 3D preview clipping by fitting the preview camera to the current animated Stadium pose bounds; v0.2.61 follower/settings-navigation fixes remain.

## v0.2.60

- Adds CUSTOM UI / MENUS live toggle and taller Pokédex 3D viewer.
- Native UI mode keeps non-UI voxel/Open World/model systems intact.

## v0.2.59
- UI preview framing update only: larger complete Stadium models in Pokédex/Party/battle preview panels.

**Current release: v0.2.76**

# Release / updater setup

Repository: `randyadr/Gen2-3D-Sprites`
Mod ID: `STADIUM2_OVERWORLD_MODELS`
Current version: `0.2.81`

## One-time / manual upload

1. Upload this repo's contents to the `main` branch of `randyadr/Gen2-3D-Sprites`.
2. Keep `.github/workflows/release.yml` enabled.
3. The manifest must keep `"github": "randyadr/Gen2-3D-Sprites"`.
4. The mod-index metadata lives under `mods/randyadr@STADIUM2_OVERWORLD_MODELS/` and uses `automatic_version_check: true`.

## Publishing future updates

Bump `manifest.json` and the exported version in `main.lua`, then push to `main`. The workflow builds and publishes an asset named:

`STADIUM2_OVERWORLD_MODELS-X.Y.Z.zip`

Gen1Recomp's Update / Versions flow can then discover the new GitHub Release.


### v0.2.67 desktop voxel recovery
A fresh Gold options block defaults native `TILT` to OFF/0. While `3D VOXEL WORLD` is enabled, that OFF value now selects the voxel renderer's normal 35-degree diorama camera rather than a literal 0-degree/flat camera. Gold TILT 15/35/50 continue to map directly to those voxel pitches; disable `3D VOXEL WORLD` for the native 2D overworld.


### v0.2.68 desktop Gold pipeline recovery
Current desktop Gold uses the engine-owned `render_pipelines.drawWorld` seam. This release registers and auto-activates `stadium2_gold_voxel` there while retaining `render.compose` for older/Android Gold hosts. Test both paths when publishing: current desktop must show voxel terrain with `3D VOXEL WORLD = ON`, and legacy/mobile compose must remain functional.
