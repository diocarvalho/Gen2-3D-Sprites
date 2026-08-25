# StadiumBattleFX 2.1.7 second-pass audit — v0.3.22

This is a file-by-file and behavior-by-behavior audit of the user-supplied `STADIUM_BATTLE_FX-2.1.7` archive against the integrated Gold/Stadium2 mod.

## Source integrity

- The uploaded archive contains **77 Lua modules** under `lib/` plus its root entry, manifest/card, MIT license, notices and two API documents.
- This project retains **77/77 source Lua modules byte-for-byte** under `lib/StadiumBattleFX217/`. No source module was silently edited or omitted.
- The source archive itself contains **no announcer WAV files**. Its announcer runtime supports a locally generated 823-clip voice pack, and this project preserves that optional path plus captions.

## Functional gaps found after v0.3.21

The first port copied all source modules and adapted the large user-facing systems, but the audit found that several important source behaviors were not yet on the active Gold execution path. v0.3.22 wires those missing behaviors into the existing Gold/Stadium2 owners:

- `effects/StadiumFxPlayer` is now the active source move-presentation adapter rather than being reference-only.
- `effects/StadiumNativeInterpreter` now drives the source native emissions for the complete move roster when **STADIUM NATIVE SCHEDULER** is ON.
- Dedicated traced source families are active, including Thunder Shock / Thunder Wave, Scratch, Sand Attack, Quick Attack, Gust, Horn, Leer, String Shot, Confusion, kick and tackle families.
- A private validated Stadium 1 cache can now build/read the source DSM7 model metadata used for **151 species × 165 moves**. Primary/impact attachment bytes are resolved against the currently animated Stadium2 actor; Gen-2-only species safely use the existing fallback anchors.
- Source native camera selector bytes and cut-delay metadata now feed the existing live battle camera instead of being reduced to only generic melee/ranged/etc. profiles.
- Source `StadiumScreenFx` borderless replay is active so authored whole-frame effects can continue into borderless margins after composition.
- Source `FailureNotice` is active as an optional on-screen fallback diagnostic.
- Source `StadiumLog` and `StadiumLogExport` are active; the options UI gains **SAVE DIAGNOSTIC SNAPSHOT**.
- The options UI gains **REBUILD STADIUM FX CACHE**, covering effect, arena, portrait, announcer and native Stadium 1 metadata caches.
- Attack-camera ownership now respects the external Battle Cinematics ownership protocol when another compatible camera mod claims the attack camera, avoiding two camera directors fighting each other.

## Source systems deliberately superseded, not missed

Several modules are intentionally retained as source/reference but are **not installed as competing runtime owners**. Activating them wholesale would remove or regress Gold-specific features already present in this project.

- **Stadium 1 model renderer / `StadiumModelProvider` / `StadiumModels`:** superseded by this project's existing Stadium 2 renderer with National Dex **001–251**, Gold battle integration, double-battle actors, overworld actors, shadows and shared animation lifecycle.
- **Embedded `stadium2/*` importer/provider:** the uploaded mod's optional Stadium 2 appearance stack is Gen-1-oriented. This project already has the Gold-aware Stadium 2 importer/DSM7 stack for 001–251, so a second model owner is intentionally not registered.
- **`BattleHost` / `BattleProviders` whole-frame provider ownership:** source effect code receives a private compatibility host that routes model attachment/hit/faint requests into the existing renderer. The source provider compositor is not allowed to replace this project's live-world battle compositor, controller HUD or Gold camera owner.
- **Portable ordinary arena themes (`StadiumArenaThemes`):** normal fights keep this project's live encounter-site overworld arena. Source Stadium 1 boss rooms remain available as the useful opt-in exception.
- **`BattleArtCompat` / PotatoVoxel / external renderer compatibility:** unnecessary inside this combined mod because the same package owns the active Stadium2 battle renderer. A small internal compatibility shim prevents external-owner probing from displacing it.
- **Source `MODEL SHADER` and model-source/provider selector rows:** they control the superseded alternate model backend, so exposing them would be misleading. This project's existing Stadium2 graphics/model settings remain authoritative.
- **`EffectCacheScreen`:** its one-time standalone cache screen is replaced by automatic cache startup plus the explicit **REBUILD STADIUM FX CACHE** action, which fits this combined mod's existing settings flow.
- **Legacy `effects/ThunderShockPlayer`:** the source's own 2.1.7 main path uses `StadiumFxPlayer`, which contains the current Thunder Shock implementation. The legacy move-84-only adapter remains embedded but is not installed separately.

## User-facing controls added by the audit

Under **BATTLE**:

- **STADIUM NATIVE SCHEDULER** — exact source scheduler/dedicated traced move renderers.
- **NATIVE ATTACH / CAMERA SYNC** — private Stadium 1 DSM7 attachment/camera metadata for Gen-1 species; safe fallback for Gen-2 species.
- **STADIUM FX FALLBACK NOTICE** — source-style on-screen fallback diagnostic.
- **REBUILD STADIUM FX CACHE** — rebuild active private Stadium FX caches.
- **SAVE DIAGNOSTIC SNAPSHOT** — source diagnostic export row.

Existing v0.3.21 toggles for the master port, cartridge layer, screen effects, attack camera/speed, hit/faint reactions, boss arenas, trainer portraits and announcer remain intact.

## Battle authority

Gold remains authoritative for move selection, accuracy, PP, damage, HP, status, switching, items, catching, AI, experience and outcomes. StadiumBattleFX remains a presentation layer. The imported source metadata is adapted onto the current Stadium2 renderer rather than writing Stadium 1 model state back into Gold's battle engine.
