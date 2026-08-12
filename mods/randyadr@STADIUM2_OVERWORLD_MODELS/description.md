# Pokemon Stadium 2 Overworld Models - Gold/Silver

A standalone Gen1Recomp Gold/Silver (Generation 2) 3D presentation mod. It renders the overworld as a voxel scene, imports Pokemon Stadium 2 models locally from the player's own compatible ROM, and integrates visible roaming Pokemon into the same 3D world.

## Features

- Gold/Silver voxel overworld with authored Johto tree geometry.
- Pokemon Stadium 2 overworld models for National Dex 1-251 using a user-supplied ROM.
- Visible roaming wild Pokemon.
- Diorama, third-person, and first-person camera modes.
- Camera-relative Gold controls.
- Outdoor weather, clouds, day/night sky, sun, and moon.
- In-world 3D battle presentation while preserving Gold's native battle logic and UI.
- Optional 3D Character Selector / Skin Selector integration.
- Gold START/text overlays remain visible above the voxel scene.

No Nintendo ROM or extracted Stadium 2 model archive is distributed with the mod.

## Install

1. Download `STADIUM2_OVERWORLD_MODELS-X.Y.Z.zip` from GitHub Releases.
2. In Gen1Recomp, open **MODS > Import mod .zip**.
3. Enable the mod and start Pokemon Gold or Silver.
4. Choose a legally obtained compatible Stadium 2 ROM from the mod's options if you want Stadium models.

Once installed, Gen1Recomp's **Update** and **Versions** flow reads releases from the GitHub repository declared by the mod manifest.

## Compatibility

- Mod API 2.
- Gold/Silver / Generation 2 only.
- Non-experimental content-profile mod.
- Optional integrations include Followers EX, PokePCFollowers Voxel Merge, Dramatic Sky Ride, and red_3d_player.
- Conflicts with the separate Gen-1 `STADIUM_OVERWORLD_MODELS` package so both generation-specific renderers do not own the same session.
