# Release / updater setup

Repository: `randyadr/Gen2-3D-Sprites`
Mod ID: `STADIUM2_OVERWORLD_MODELS`
Current version: `0.2.15`

## One-time / manual upload

1. Upload this repo's contents to the `main` branch of `randyadr/Gen2-3D-Sprites`.
2. Keep `.github/workflows/release.yml` enabled.
3. The manifest must keep `"github": "randyadr/Gen2-3D-Sprites"`.
4. The mod-index metadata lives under `mods/randyadr@STADIUM2_OVERWORLD_MODELS/` and uses `automatic_version_check: true`.

## Publishing future updates

Bump `manifest.json` and the exported version in `main.lua`, then push to `main`. The workflow builds and publishes an asset named:

`STADIUM2_OVERWORLD_MODELS-X.Y.Z.zip`

Gen1Recomp's Update / Versions flow can then discover the new GitHub Release.
