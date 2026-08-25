# Embedded Weather FX 4.10 visual port

Source supplied for this integration: Weather FX 4.10.0 (`weather_fx_v4.10.0_variant_toggle.zip`).

This project embeds the source/assets under `weatherfx/`, but intentionally installs only overworld weather state and presentation: weather selection/fronts, seasons/time weighting, 2D particles/fog/tints, lightning, splashes, weather sound and the Stadium2-compatible voxel atmosphere.

Not installed from the upstream package:
- Steel/Fairy/Dark type-chart changes
- Weather/Delta Pokémon species registration
- Encounter substitution/injection
- Tornado player warps
- Weather battle-rule mutations/rulesets
- Weather Pokegear card

The project continues to own those gameplay systems itself.

## Third-party notice

`weatherfx/lib/voxel_atmos/CinematicAtmos.lua`, `DistantWorld.lua`,
`HorizonApron.lua`, `WeatherSetting.lua` and related Kanto compatibility
material originate from Kanto Dynamic Weather by Campo (`1-Camp0-1`).
The original MIT licence and notice are preserved beside those files:
`weatherfx/lib/voxel_atmos/LICENSE-kanto-dynamic-weather` and `NOTICE.md`.

## Embedded-host isolation

The embedded runtime stores its persistent weather clock under the parent mod's
`weatherFx.*` save prefix, so Weather FX's standalone keys (`id`, `left`,
`fronts`) cannot collide with follower, mount, renderer, or other save state.
The embedded config also forces encounter/variant/tornado/battle-rule/Pokegear
mutations off even if a standalone Weather FX config enables them.

Weather weighting follows the Stadium2 host's Gold/day-night clock. Weather
FX's separate full-screen time-of-day grade is disabled so it does not stack a
second night tint over the existing voxel lighting.
