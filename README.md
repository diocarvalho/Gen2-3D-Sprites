* **v0.1.91 – Character Selector camera integration**

  * New `CAMERA CONTROL` setting: AUTO / THIS MOD / CHARACTER SELECTOR.
  * Character Selector's 1ST/3RD modes can directly control the Gold voxel camera.
  * Mouse/touch camera input works while Character Selector owns the camera.

* **v0.1.92 – Seamless overworld battles**

  * Wild battles can begin directly in the 3D overworld.
  * Removes Gold's normal expanding-circle battle transition when Live Overworld Battles is enabled.
  * Battle UI, catching, switching, moves, and normal Gold battle logic remain intact.

* **v0.1.93 – Touch pinch zoom**

  * Two-finger pinch-to-zoom added.
  * Third Person pinch changes camera distance.
  * Diorama pinch changes the voxel/orbit zoom.
  * Pinching doesn't interfere with camera rotation or virtual controls.

* **v0.1.94 – Improved Gold pinch-zoom support**

  * Pinch zoom connected directly to Gold's `Game2` controls.
  * Diorama and Third Person zoom now use Gold's actual live touch events.

* **v0.1.96 – Android camera-mode slider**

  * Android DIORAMA / 3RD / 1ST camera slider made directly touch-responsive.
  * Camera mode changes immediately during the same rendered frame.

* **v0.1.98 – True 360-degree movement**

  * FIRST PERSON and THIRD PERSON gain real camera-relative free movement.
  * Movement is no longer restricted to four directions.
  * Analog stick magnitude is preserved.
  * Keyboard diagonals are normalized.
  * Player can wall-slide around obstacles.
  * Character body rotates continuously toward movement direction.
  * Gold's encounters, scripts, trainers, steps, and map events still activate when crossing tiles.
  * Special movement like ledges, surfing, biking, ice, currents, doors, and scripted sequences falls back to Gold's native movement system.

* **v0.1.99 – Split-thumb Android controls**

  * Left thumb remains dedicated to movement.
  * Right side of the screen controls camera look.
  * Right-thumb camera steering also works during live overworld battles.
  * Desktop mouse battle camera uses the same live-world camera system.
  * Larger round-tree perimeter around maps.

* **v0.2.00 – Direct Android camera input**

  * Android camera movement now polls touches directly for much more reliable right-thumb aiming.
  * Works in FIRST PERSON, THIRD PERSON, and live overworld battles.
  * Actual 3D forest/map perimeter increased to 16 tiles.

* **v0.2.01 – Continuous Diorama zoom**

  * Smooth continuous Diorama camera zoom.
  * Android uses pinch.
  * Desktop uses mouse wheel/trackpad.

* **v0.2.01 – Stadium-style battle camera**

  * New automatic **STADIUM BATTLE CAMERA**.
  * Camera orbits around both 3D Pokémon during overworld battles.
  * Changes speed depending on whether you're choosing commands or attacks are occurring.
  * Moves closer during attack animations.
  * Player can temporarily manually control it with mouse/right thumb.
  * Automatic camera resumes after manual input stops.
  * Can be disabled separately from Live Overworld Battles.

* **v0.2.02 – Active-Pokémon cinematic camera**

  * Camera detects which Pokémon is currently attacking.
  * Uses a shoulder-style shot favoring the active Pokémon.
  * Smoothly returns toward the battle midpoint between turns.
  * Player trainer is repositioned beside/behind the player's Pokémon instead of standing in the combat line.
  * Much closer Diorama zoom available, down to roughly 0.24× camera distance.

* **v0.2.03 – Much larger outdoor world border**

  * Outdoor forest scenery extends **32 tiles beyond the map on every side**.
  * Greatly reduces visible black/empty space outside Gold's normal map boundaries.

* **v0.2.04 – Connected-map open-world streaming**

  * One entire connected map can now render ahead in every available direction.
  * Routes and towns exist in 3D before you cross into them.
  * Neighboring map meshes preload in the background.
  * Nearby connected maps receive priority loading.
  * Already-loaded maps are reused when crossing boundaries instead of rebuilding.
  * Trees no longer incorrectly fill areas where a real connected route/town exists.
  * Neighboring-map NPCs can appear before crossing when Gold provides their data.
  * Third-person camera collision understands neighboring maps instead of treating the edge as the end of the world.

* **v0.2.05 – Full controller right-stick camera**

  * FIRST PERSON and THIRD PERSON continuously poll controller right stick for yaw/pitch.
  * Controller camera works even if normal controller-axis events are intercepted by another mod.
  * Mouse and controller camera input can both be used.
  * F6 reliably cycles DIORAMA → 3RD → 1ST → DIORAMA.

* **v0.2.06 – 3D overworld Pokémon capture minigame**

  * Major new Pokémon-GO/Stadium-style overworld catching system.
  * Uses an actual **3D Poké Ball model**.
  * Aim directly at roaming Pokémon.
  * Screen reticle and shrinking timing ring.
  * Throw ratings:

    * HIT
    * NICE
    * GREAT
    * EXCELLENT
  * Poké Ball physically flies through the 3D world.
  * Ball performs an in-world shake sequence.
  * Pokémon can break out and remain available for another attempt.
  * Missing consumes the Poké Ball without removing the Pokémon.
  * Uses Gold's real Gen-2 species catch rates.
  * Successfully caught Pokémon become normal Gold Pokémon.
  * Correct player OT/ID is assigned.
  * Pokédex seen/caught flags update.
  * Pokémon goes into the party or current PC box.
  * Running out of Poké Balls safely falls back to a regular battle.

* **v0.2.07 – Cleaner 3D battle presentation**

  * Removes Gold's giant duplicate 2D trainer back sprite when the real 3D trainer is already standing in the overworld battle scene.

* **v0.2.08 – 3D Pokémon attack effects**

  * Gold's actual move animations are connected to the Stadium world-space effect renderer.
  * Effects know the real move, attacker, and animation frame.
  * Added 3D effect families for:

    * Fire
    * Water
    * Electric
    * Ice
    * Psychic
    * Poison
    * Grass
    * Wind
    * Ghost/Dark
    * Dragon
    * Rock/Ground
    * Physical impacts
  * Special mappings added for Gen-2 moves including Icy Wind, Flame Wheel, Whirlpool, Mud-Slap, Rollout, Bone Rush, Fury Cutter, and Cotton Spore.
  * Removes the remaining native 2D player-Pokémon back sprite when a working Stadium model is available.

* **v0.2.10 – Multi-Ball capture/storage improvements**

  * Changelog references expanded multi-Ball catch/storage behavior.
  * Overworld capture continues to use Gold's actual catching and storage systems.

* **v0.2.11 – Throw Pokémon Balls before contact**

  * You no longer have to physically touch a roaming Pokémon to start the capture system.
  * Normal contact starts a regular wild battle again.
  * **R3/right-stick click** on controller throws at a targeted overworld Pokémon.
  * **Right mouse button** is the primary PC overworld throw input.
  * You can throw while standing completely still.
  * New properly UV-mapped red/white/black 3D Poké Ball.
  * Aiming selects a visible Pokémon inside the camera cone.

* **v0.2.12 – Expanded capture difficulty system**

  * Changelog references new **two-stage capture controls**.
  * Pokémon stats/level now affect capture resistance rather than every Pokémon behaving equally.

* **v0.2.13 – Animated 3D Character Selector player**

  * 3D Character Selector skins can receive a visual walking state during true 3RD/1ST free movement.
  * Walking animation works without modifying Gold's real collision/script/movement state.
  * Added a Lugia-specific emergency 2D-in-3D fallback instead of a generic NPC sprite when its Stadium model cannot safely render.

* **v0.2.14 – Player animation immediately after loading**

  * 3D Character Selector walking animation now works from the **first frame**.
  * No longer requires changing maps before the 3D trainer begins animating properly.

* **v0.2.15 – Lugia 3D model recovery**

  * Lugia no longer automatically falls back to 2D.
  * New hierarchy-repair system tries multiple Stadium 2 bind methods to reconstruct Lugia correctly.
  * Lugia stance/scaling data recalculated from the repaired model.
  * Lugia Stadium textures forced to proper opaque rendering.
  * Species-specific 2D Lugia remains only as a last-resort fallback.

* **v0.2.15 – Harder/more accurate overworld catching**

  * Smaller Pokémon hit area.
  * Stronger Pokémon can have an even smaller target.
  * Timing ring moves faster for stronger Pokémon.
  * NICE/GREAT/EXCELLENT timing requirements are stricter.
  * Your actual aiming error determines the Poké Ball's impact position.
  * A missed throw now **visibly flies past/misses the Pokémon** instead of always landing at its location.
