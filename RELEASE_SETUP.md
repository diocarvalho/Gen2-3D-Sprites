## v0.4.33 Pokemon Crystal compatibility checks

1. Use a current Gen1Recomp build with Pokemon Crystal imported and selected.
2. Confirm the mod loads normally under Crystal without the `NOT THIS GAME` gate; `games = ["gen2"]` must include Crystal.
3. Enter the overworld with 3D VOXEL WORLD on and verify the current Crystal player sprite/gender choice is preserved by the voxel player card.
4. Traverse several Johto routes/towns in Crystal, let sector preloading run, restart Crystal, and confirm cached sectors restore quickly.
5. Switch to Gold or Silver and verify their sector cache warms independently rather than overwriting Crystal's map-id cache files.
6. On Android/iOS Crystal, open any mod-owned native file picker and confirm the bridge routes through the active `crystal` edition instead of `gold`.
7. Verify visible wild Pokemon, followers, Fly Your Pokemon, day/night palettes, animated tiles, battles, Kanto free roam, OPEN WORLD, WORLD OCEAN, and modern Mod Settings all still function under Crystal.
8. Battle Crystal's MYSTICALMAN/Eusine with Stadium announcer scope set to Gym/Boss and confirm announcer integration is allowed.
9. Re-test Gold and Silver for regressions; all three Gen-2 editions must share behavior except for edition-authored game data.
10. Run every bundled `tests/*.lua` before packaging.
