# Gen1Recomp index / GitHub update setup

This repository is prepared for the Generation-2 mod id:

`STADIUM2_OVERWORLD_MODELS`

and intentionally uses its own release feed:

`randyadr/3D-Pokemon-Sprites-Gen2`

This keeps Gold/Silver releases separate from the existing Generation-1 `STADIUM_OVERWORLD_MODELS` update stream.

## 1. Create/upload the GitHub repository

Create `randyadr/3D-Pokemon-Sprites-Gen2` and upload the contents of this repository bundle to its `main` branch.

The mod manifest already contains:

```json
"github": "randyadr/3D-Pokemon-Sprites-Gen2"
```

## 2. First GitHub Release

The included `.github/workflows/release.yml` can publish the release automatically. For this snapshot, the expected release is:

- Tag: `v0.1.85`
- Asset: `STADIUM2_OVERWORLD_MODELS-0.1.85.zip`

The exact `<mod-id>-<version>.zip` name is important because Gen1Recomp's updater prefers that asset name.

## 3. Submit to gen1recomp-mod-index once

Copy only this folder into a fork of `bryanthaboi/gen1recomp-mod-index`:

`mods/randyadr@STADIUM2_OVERWORLD_MODELS/`

It contains only:

- `meta.json`
- `description.md`

`meta.json` has `automatic_version_check: true`, so after the index entry is merged you do not submit a PR for every version. Publish a new GitHub Release in this repository and the index refresh job follows the newest installable release.

## 4. Future versions

For v0.1.86 and later:

1. Update `manifest.json` version.
2. Commit/push the new runtime files to `main`.
3. The release workflow publishes `STADIUM2_OVERWORLD_MODELS-<version>.zip`.
4. The index tracks the new GitHub Release automatically.
