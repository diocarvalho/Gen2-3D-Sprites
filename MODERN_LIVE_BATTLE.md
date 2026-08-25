# Modern Live Battle Mechanics — v0.3.20

This layer improves the feel of **LIVE OVERWORLD BATTLES** while leaving Pokémon Gold's battle engine authoritative. It does **not** change move power, accuracy, turn order, HP, PP, status, switching, catching, EXP, AI or battle outcomes.

## What changed

- **Analog locomotion:** left stick / WASD accelerates and decelerates instead of moving the Stadium model by a fixed amount every frame.
- **Camera-relative steering:** movement follows the visible Stadium battle camera.
- **Arena handling:** the player slides along the soft arena edge instead of snapping against it, stays separated from the opponent, and is gently prevented from drifting so far away that the encounter stops reading as one fight.
- **Contact attacks:** appropriate damaging moves temporarily lunge the attacking 3D model toward the target and return it to the stable battle anchor. Ranged/global/status moves stay planted.
- **Real hit reactions:** HP loss triggers visual defender knockback proportional to the damage fraction.
- **Modern camera response:** attacks tighten the FOV; real hits add decaying impact zoom and camera shake.
- **Safe ownership:** lunges and recoil exist only in render-space. Gold's battle positions and battle logic are never rewritten.

## Settings

Under **BATTLE**:

- **MODERN LIVE BATTLE MOTION** — toggles contact lunges, hit recoil and impact camera feedback.
- **BATTLE MOVEMENT FEEL** — TIGHT / MODERN / SMOOTH acceleration and stopping.
- **BATTLE IMPACT FEEDBACK** — LOW / NORMAL / HIGH knockback and camera impact strength.

The existing **STADIUM ATTACK ANIMATIONS**, **STADIUM BATTLE CAMERA**, custom battle HUD, double-battle mode and Stadium move/effect renderers continue to work with this layer.
