# Weather FX + Steel/Fairy/Dark Types

This merged build combines Weather FX 4.6.7 with Steel/Fairy/Dark Types and
Typing Charts 2.0.1. The type-chart component is bundled into the same mod and
its preset, Steel, Dark, Fairy, and historical matchup options appear alongside
Weather FX's options. Type changes require a save and restart.

## Weather Delta Pokémon

This build registers **300 persistent weather variants** as separate species. When the optional Kanto Reforged mod is installed, it conditionally registers another **470 variants**—two for every added species from #152 through #386—for a total of 770. The supplemental variants are never loaded without Kanto Reforged.

Set **WX POKEMON** to **OFF** on Weather FX's mod-settings page to stop new
weather variants from appearing while keeping visual and battle weather active.
Already caught variants remain fully usable, so the option is safe to change
during an existing save.

Automatic updates use `MrKrisSatan/Weather-fx`. Published releases must contain this complete merged edition and use a strict three-part manifest version such as `4.9.1`; compound build suffixes can cause the launcher to detect an update but reject installation.
A normal wild encounter is always rolled first; when its base species has a
variant for the current live weather, a small second roll may substitute that
variant. Normal encounters and vanilla species are never overwritten. A caught
variant keeps its name, types, moves, stats, and variant evolution path after
the weather changes.

The default chances are common 5%, rare 3%, very rare 1%, and legendary/event
0.1%. Most entries are rare. Ditto, Eevee, Snorlax, and Dragonite families are
very rare; Articuno, Zapdos, Moltres, Mewtwo, and Mew variants use the legendary
rate. Edit the single `weatherVariants` table in `config.lua` to change these
values or disable the feature.

The complete database is in [`docs/WEATHER_VARIANTS.md`](docs/WEATHER_VARIANTS.md).

### Requested weather-name mapping

The database retains its design labels, while runtime gating uses real Weather
FX IDs. Rain/Heavy Rain/Storm, Snow/Hail/Blizzard, Wind, Sandstorm/Dust Storm,
Ashfall, Heatwave, Sunny, Fog, Smog, and related labels map directly to their
existing weather families. Composite design labels use the closest real family:
Moonlit Fog and Moonlit Rain use `HAUNTED_MIST`; Acid Rain uses `SMOG` or
`HEAVY_RAIN`; Static Storm uses `STORM`/`THUNDERSNOW`; Flood uses `HEAVY_RAIN`;
Typhoon uses `GALE`/`STORM`; Aurora uses snow/thundersnow; and Eclipse uses
`HAUNTED_MIST`/`PSYSTORM`. Seasonal entries use sunny, verdant rain, or snow.

### Debugging

The existing `weather <ID>` command forces weather. To force a registered
variant on the next successful wild encounter, use:

```text
weather variant CINDER
weather variant CHARMANDER
weather variant WX_004_CHARMANDER_CINDER
```

### Artwork and engine limitations

No ROM sprites are included. Until original artwork is supplied, each variant
inherits its base species' sprite, back sprite, palette, cry, stats, learnset,
and Pokédex text. Unique names, types, species identity, capture persistence,
and evolution targets are registered independently. The currently documented
encounter API has no variant-specific pre-battle announcement hook, so the
species' distinct displayed name identifies it without patching engine text.

> **Working on this with an AI assistant?** Point it at
> [`AGENTS.md`](AGENTS.md) first — it covers the tools in
> `tools/` and the failure modes in this engine that do not raise errors.


Weather for Pokémon. Skies change as you play, and the weather follows you
into battle — where it changes how the fight goes, not just how it looks.

Works on Red, Blue, Yellow and Gold.

---

## Install

Drop the `weather_fx` folder into your `mods/` folder, or import the
`.modpkg` through the launcher. That's it — it turns itself on.

Then open **OPTIONS** in game and set **WEATHER** to `AUTO`.

### Presentation (mod page)

On this mod’s page in the mod manager, **WX PRESENT** controls how overworld
weather is drawn:

| Setting | Behaviour |
|--------|-----------|
| **AUTO** (default) | 3D atmosphere when Dramaless Shape, Potato Voxel, or Gen2-3D-Sprites is running; otherwise original 2D overlays |
| **2D** | Always use original Weather FX rain/fog/particle overlays |
| **3D** | Prefer the voxel-pass atmosphere when a supported host is available |

Battles always use Weather FX’s own battle weather path.

### Voxel 3D (Dramaless / Potato)

With **Dramaless Shape** or **Potato Voxel** in VOXEL mode, Weather FX can draw
clouds, light shafts, rain, fog, motes and puddles inside the host depth pass
(embedded Kanto-style atmosphere, Weather FX only — other mods are not edited).
If that path is unavailable or fails, the mod falls back to 2D automatically.

Turn on **DEBUG HUD** (mod page): **SIMPLE** (readable), **FULL** (dense),
or **3D** (voxel bridge only). SIMPLE/3D include a **why:** line when rain is
missing (indoors, clear sky, ladder off, 3d-precip, …). An `|err:` on the 3D
status is the last draw error.

### AI / headless tools

```bash
python3 tools/test_mod.py      # structural + contract tests
python3 tools/run_all.py       # debug + guard + map + tests
python3 tools/runtime_hints.py "wx:3d | v3:full-atmos:DRAMALESS_SHAPE"
```

---

## What you'll see

**Eighteen kinds of weather** — clear, sun, heatwave, harsh sun, light rain,
heavy rain, primal rain, thunderstorm, gale, snow, blizzard, hail, sleet,
thundersnow, sandstorm, ashfall, strong winds and fog.

**It changes on its own.** Leave WEATHER on `AUTO` and the sky rolls
naturally — a spell lasts a few minutes, clear is common, and it shifts as
you travel. Set it to `CYCLE` to walk through every type in turn, or pick one
directly and it changes immediately.

**Some places have their own weather.** Lavender Town runs foggy, the climb
to Indigo Plateau turns to snow, the sea routes run misty. Your own choice
from the menu always wins.

**Lightning and thunder** in storms, with a softer setting if flashing images
are a problem for you.

**A day/night cycle** that tints the world — morning, day, evening, night.
After dark the weather leans toward fog and storms.

---

## What it does in battle

Whatever sky you're standing under comes into the fight with you.

| | |
| --- | --- |
| **Rain** | Water moves hit harder, Fire moves weaker. Thunder never misses |
| **Sun** | Fire moves hit harder, Water moves weaker. Thunder gets unreliable |
| **Primal rain** | Fire moves fail completely |
| **Harsh sun** | Water moves fail completely |
| **Sandstorm** | Wears down anything that isn't Rock, Ground or Steel. Rock types resist special attacks better |
| **Hail / snow** | Wears down anything that isn't Ice. Blizzard never misses |
| **Strong winds** | Flying types stop taking their usual extra damage |
| **Fog** | Everyone's accuracy drops |

**Where you fight matters too.** Bug and Grass moves hit harder in the
forest, Electric moves in the Power Plant, Ghost moves in the tower — on both
Kanto and Johto maps.

Also handled: Solar Beam's power, weather-based abilities like Swift Swim and
Sand Veil, the weather-extending rocks, and Utility Umbrella.

---

## Settings

All in **OPTIONS**, in game:

| Row | What it does |
| --- | --- |
| **WEATHER** | Off, automatic, cycling, or pick a sky yourself |
| **TIME** | The day/night cycle |
| **SEASONS** | Four seasons that lean AUTO weather (snow in winter, sun in summer) |
| **HEMISPHERE** | Northern or Southern — reverses which months are which season |
| **SEASON NOTE** | On-screen banner when the season changes |
| **INTENSITY** | How heavy the weather looks |
| **QUALITY** | Particle detail — lowers itself automatically if the frame rate dips |
| **BATTLES** | How strongly weather draws over the battle screen |
| **WX RULES** | Whether weather affects battles at all |
| **AMPLIFIED** | A stronger, non-standard version of extreme weather (off by default) |
| **LIGHTNING** | Full, soft, or off |
| **WEATHER SFX** | Rain and wind sound |
| **TORNADOES** | Rare tornado events |
| **RARE WX** | How often unusual weather shows up |
| **DEBUG HUD** | An on-screen readout, useful if something looks wrong |

There's more in `config.lua` — per-map weather, exact damage numbers, which
places get terrain bonuses. You never need to touch it.

---

## Something not working?

**Weather changes outside but battles stay dry.**
Set **WX RULES** to `ALWAYS`.

**No weather at all.**
Check **WEATHER** isn't set to `OFF`.

**A terrain bonus never seems to fire.**
Turn on **DEBUG HUD** and look at the `map:` field — it shows the map name
the game is actually using, which is what your config needs to match.

**Anything else.**
Turn on **DEBUG HUD**. The `btl` field says in plain terms why a battle has
no weather (`-!needs-ruleset`, `-!indoors`, `-!wxrules-off`, and so on).

---

## Other mods

Built to run alongside 3D and voxel mods, first-person mods, widescreen
battle mods, and Kanto-Reforged. Where Reforged already handles something —
Weather Ball, Castform, Sand Veil — this mod steps aside instead of doubling
up.

---

## Two things worth knowing

**This isn't "Gen 1 accurate", and that's deliberate.** Gen 1 has no weather
at all, and Gen 2 has only rain, sun and sandstorm. Most of what's here is
borrowed from Gen 3 through Gen 8 and brought back. The
[full reference](docs/REFERENCE.md) lists which generation each effect comes
from, if you care.

**A few battle features need a mod that adds abilities and held items.**
Castform, weather rocks and abilities like Swift Swim have nothing to attach
to in the vanilla games.

---

## Full reference

Everything else — every config key, compatibility details, how to extend it,
how it's tested — is in **[docs/REFERENCE.md](docs/REFERENCE.md)**.


## Typed Weather Residuals (4.0.0)

Weather now covers **all 15 Generation I damage types**. A typed weather deals
**1/16 of maximum HP at the end of each battle turn** to battlers that do not
have the weather's matching type. Dual-typed Pokémon are immune when either
type matches. The residual uses the same configured `residualDamage.fraction`
and `canFaint` controls as the existing hail/sandstorm system.

| Gen 1 type | Weather |
|---|---|
| Normal | Plain Front |
| Fire | Heatwave / Sun |
| Water | Rain |
| Electric | Storm |
| Grass | Verdant Rain |
| Ice | Snow / Blizzard / Hail |
| Fighting | Brawl Wind |
| Poison | Smog |
| Ground | Duststorm |
| Flying | Flockstorm / Gale |
| Psychic | Psystorm |
| Bug | Swarm |
| Rock | Sandstorm |
| Ghost | Haunted Mist |
| Dragon | Dragonstorm |

Every typed weather has a non-empty visual recipe and is rendered by both the
overworld compositor and the battle weather compositor. The visual recipes
reuse the mod's renderer-independent rain, snow, grain, fog, veil, tint,
glare, wind and lightning layers, so they work on the flat renderer and
supported world/battle presentation paths without requiring platform-specific
code.

The weather's `chipType` lives in `lib/Types.lua`. The battle residual system
resolves the active field weather back through that catalogue, so adding
another typed weather does not require adding another residual-damage branch.

## Credits

The 3D atmosphere path reuses four modules and a compatibility bridge from
**[Kanto Dynamic Weather](https://github.com/1-Camp0-1/Kanto-Dynamic-Weather)**
by **Campo (`1-Camp0-1`)**, used verbatim under the MIT License. The licence
and a notice sit beside the code in `lib/voxel_atmos/`.
