# StadiumBattleFX 2.1.7 → Gen2-3D-Sprites port

Version **v0.3.28** embeds, audits, and adapts the user-supplied MIT `STADIUM_BATTLE_FX-2.1.7` source. The goal is to retain its Stadium battle research/presentation while preserving this project's Gold-specific systems.


## v0.3.28 Yellow Kanto note

v0.3.28 changes the Yellow/Kanto free-roam world layer only. StadiumBattleFX, Stadium 1 validation, the 823-clip announcer cache and v0.3.25 byte-backed announcer playback remain intentionally unchanged.

## v0.3.27 native Kanto parity note

v0.3.27 is a native Gen-2 Kanto/Johto world-renderer parity pass. StadiumBattleFX, Stadium 1 ROM validation, the 823-clip private announcer cache and the v0.3.25 byte-backed playback/test action are intentionally unchanged.


## v0.3.25 shared PC/Android announcer playback

The **STADIUM 1 / 2 ROM FILE** action keeps the existing platform picker behavior: normal desktop selection on PC and the system document picker on Android. After selection, both platforms use the same Stadium 1 validation, `StadiumAnnouncerRom.lua` extraction, 823-clip cache, and announcer event engine. v0.3.25 fixes the playback boundary by reading a persisted WAV back through the exact Gen1Recomp persistence backend that stored it and passing its bytes to LÖVE's WAV decoder; it no longer assumes a persistence-relative path belongs to `love.audio`'s filesystem namespace. **TEST STADIUM ANNOUNCER** plays clip 223 as an immediate end-to-end check. No voice recordings are bundled.

## v0.3.24 Android announcer import + playback fix

On Android, the mod's existing `STADIUM 1 / 2 ROM FILE` action continues to use the native system document picker. Stadium 2 selections keep the model/world path. Pokemon Stadium (USA) v1.0 selections are validated and then feed the battle-FX caches plus `StadiumAnnouncerRom.lua`, which traverses the cartridge's nested `S1` speech archive and incrementally decodes its 823 MORT streams to private 16 kHz mono WAV cache entries. This path is pure Lua and requires no Python, shell, desktop `mort_decoder`, ROM copy in a fixed folder, or prebuilt `assets/announcer` directory. No voice recordings are bundled in the public ZIP.

## v0.3.22 audit activation

v0.3.22 completed a second pass against every module in the supplied 2.1.7 archive. In addition to the v0.3.21 systems above, the active Gold path now uses the source `StadiumFxPlayer`, native move scheduler and dedicated traced renderers; optional Stadium 1 DSM7 attachment/camera metadata; native camera selector timing; borderless `StadiumScreenFx` replay; source fallback notice; diagnostic logging/export; and cache rebuild action. See `STADIUM_BATTLE_FX_AUDIT.md` for the complete 77/77 source inventory and the short list of alternate provider/model backends that are deliberately superseded rather than installed as conflicting owners.

## What is active

- **All 165 Gen-1 move specifications**: source move IDs/keys, Stadium dispatch/resource metadata, visual family, delivery style, impact frame, duration, body-only status and cinematic profile. Gold move IDs are adapted onto this registry.
- **Attack-effect rendering**: StadiumBattleFX's cartridge-calibrated programs are available through **STADIUM CARTRIDGE FX → AUTHENTIC ONLY**. **ALL 165** additionally enables its deterministic generic renderer. Existing depth-aware Stadium2 world effects remain the 3D layer and consume the source timing/family data.
- **Animated attachment origins**: the source expects moving attacker/impact attachment points. This port resolves those through `Stadium.attachmentWorld()` on the currently animated Stadium2 rig, then falls back to the stable battle anchors if a bone/tag is unavailable.
- **Attack-camera timelines**: melee, combo, sustained, aerial, field, status, self, explosion and ranged profiles feed the existing live-world Stadium camera; manual camera input still overrides them.
- **Hit/faint presentation**: source timing/toggles gate the Stadium2 recoil/faint presentation. Gold alone owns HP, faint state and battle outcomes.
- **Full-screen effects**: source 160×144 screen programs and a supplemental source-timed screen wash can sit behind the Gold/custom HUD.
- **Boss rooms**: with a private validated Stadium 1 cache, compatible Kanto Gym Leader Castle, Elite Four and Champion rooms can replace the live arena for those boss fights only.
- **Trainer portraits**: compatible Stadium 1 RGBA5551 portraits can replace Gold's opening trainer art when privately cached. Unsupported classes fall back to Gold art.
- **Announcer engine**: source intro/send-out/move/reaction/faint/victory/idle timing is adapted to Gold battle events. Captions are included as a voice-free fallback.

## What deliberately remains owned by this mod

StadiumBattleFX 2.1.7 also contains a complete Gen-1 Stadium model host and its own optional Stadium2 appearance stack/provider framework. Those are **not registered as competing model owners** here. Gen2-3D-Sprites already has a full 001-251 Stadium2 importer, DSM7 skeletal rigs, overworld/battle model lifecycle, shadows, double-battle actors and Gold-specific renderer bridges. Installing a second owner would regress those systems. The source files remain embedded for attribution/reference, while their timing/attachment/presentation data is adapted onto the existing renderer.

Its ordinary portable grass/cave/water/interior arenas also do not replace this project's core **LIVE OVERWORLD BATTLES** feature. ROM-derived boss rooms are the useful opt-in exception.

## Private Pokemon Stadium ROM

Authentic effect textures, boss rooms and trainer portraits require the player's own **Pokemon Stadium (USA) v1.0** ROM. Gen1Recomp's optional import validates the normalized MD5:

`ed1378bc12115f71209a77844965ba50`

No ROM, extracted Nintendo texture, arena, portrait or voice recording is distributed in this ZIP. Without the ROM, the source metadata/camera/timing systems and procedural/world-space fallbacks still work.

## Announcer audio

The uploaded/public StadiumBattleFX 2.1.7 archive is intentionally **voice-free**. Its original playback engine supports a personalized 823-clip pack (`000.wav`…`822.wav` plus `assets/announcer/voicepack.json`) built locally from the player's own Stadium cartridge image, and this port still accepts that layout. Selecting Pokemon Stadium (USA) v1.0 on either PC or Android inventories and decodes the same 823 cartridge streams directly into scoped cache storage. v0.3.25 reads those WAVs back through the same persistence backend and feeds their bytes to LÖVE for playback, so no prebuilt voice-pack directory is required and portable/mobile filesystem roots do not need to match the audio engine's relative-path root.

- **STADIUM ANNOUNCER** controls the source playback engine.
- **ANNOUNCER BATTLES** selects Gym/E4/Champion, all trainers, or all battles.
- **ANNOUNCER CAPTIONS** provides visible Stadium-style calls even when no voice pack is present.
- **TEST STADIUM ANNOUNCER** plays known spoken clip 223 immediately to verify the imported voice path.

The public v0.3.25 ZIP does not contain those WAV files.

## BATTLE settings

- STADIUM BATTLE FX 2.1.7
- STADIUM CARTRIDGE FX — AUTHENTIC ONLY / ALL 165 / OFF
- STADIUM NATIVE SCHEDULER
- NATIVE ATTACH / CAMERA SYNC
- STADIUM FX FALLBACK NOTICE
- STADIUM SCREEN WASH
- STADIUM ATTACK CAMERA FX
- STADIUM ATTACK SPEED
- ATTACK CAMERA WIDTH
- STADIUM HIT REACTIONS
- STADIUM FAINT ANIMATIONS
- STADIUM BOSS ARENAS
- STADIUM TRAINER PORTRAITS
- STADIUM ANNOUNCER
- ANNOUNCER BATTLES
- ANNOUNCER CAPTIONS

The existing **STADIUM ATTACK ANIMATIONS** setting remains the master switch for this project's imported Stadium2 skeletal attack clips; it is separate from the StadiumBattleFX VFX/camera layer.

## Attribution

The imported source is retained under `lib/StadiumBattleFX217/`. See `STADIUM_BATTLE_FX_LICENSE.txt`, `STADIUM_BATTLE_FX_THIRD_PARTY_NOTICES.md`, `STADIUM_BATTLE_FX_PRESENTATION_API.md`, and `STADIUM_BATTLE_FX_MODEL_API.md`.
