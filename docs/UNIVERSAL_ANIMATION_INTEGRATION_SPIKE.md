# Universal Animation Library — Standard Character Investigation

Status: isolated preview verified by the user in Godot 4.7.2. The Standard model and its animation clips play in the preview; integration into the playable game is still not approved.

## Goal

Validate the Standard character and define a safe animation prototype for Parkour Rush 2D without changing the production 2D scene. The opening state should show the character idling before any touch input. Once the player starts, running is the default movement. A single contextual action button may trigger slide-style animation variety.

**Explicit exclusion:** Do not use `Imp.glb` or `Puglin.glb`. Do not retarget the library onto those models. Keep the current 2D player and gameplay as the production baseline.

## Confirmed facts from Godot inspection and preview

- `UAL1_Standard.glb` and `UAL1_Standard_RM.glb` are present in the Standard animation pack.
- The included README identifies `UAL1_Standard.glb` as the non-root-motion variant.
- The README identifies `UAL1_Standard_RM.glb` as the variant with root motion baked into the animations.
- The included license states CC0 1.0 Universal.
- The local Godot inspection reported a visible mannequin mesh, two materials, a Skeleton3D with 65 bones, an AnimationPlayer, and 42 animation clips for the Standard variants.
- The user successfully launched `tests/animation_preview.tscn` and confirmed that the character's animations work.
- The preview's `Roll` clip (selected with key `0`) is the intended **slide/slide-dodge animation** for the parkour game. Do not treat `Crouch_Fwd` as the primary slide action; it remains an optional crouched movement clip for later comparison.

## Investigation sequence

1. **Protect the baseline.** Keep `main.tscn`, `level_1.tscn`, and the existing 2D player unchanged. Do not connect the experiment to the game's main scene.
2. **Import the Standard asset.** Open the project in Godot 4.7.2 and let the editor import `UAL1_Standard.glb`. Record all import errors and warnings. Do not commit generated `.godot/` cache data.
3. **Inspect the imported scene tree.** Record node names and types. Specifically establish whether the scene contains a visible mesh, materials, a Skeleton3D, an AnimationPlayer or AnimationTree, and an animation library.
4. **Inspect geometry and rig.** Record mesh/resource names, material assignments, skeleton path, bone count, and bone names/hierarchy. If no character mesh is present, state that explicitly rather than assuming the GLB is a complete protagonist.
5. **Inspect animations.** Record exact imported animation names and durations from Godot. The verified preview includes idle, walk, jog, sprint, jump start, jump, landing, crouch idle, crouch forward, and roll. Use `Roll` as the candidate slide action for the game; keep `Crouch_Fwd` as a separate optional clip, not a substitute for the requested slide.
6. **Build an isolated preview if a visible character is present.** Put the preview in a dedicated test location. Use a neutral floor and camera. Do not alter `main.tscn` or `level_1.tscn`.
7. **Evaluate motion visually.** Check pose readability, deformation, foot sliding, clipping, floor penetration, and transitions. Clip names alone are not acceptance evidence.
8. **Compare the root-motion variant only if needed.** Start with `UAL1_Standard.glb` for a game whose movement is controlled by gameplay code. Inspect the RM version separately only if there is a clear reason to compare it; avoid applying root motion twice.
9. **Test Android only after desktop inspection succeeds.** Check resource/texture sizes, material count, export success, and target-device performance before considering adoption.
10. **Write a go/no-go conclusion.** The decision must be based on imported resource evidence and a visual preview, not filename assumptions.

## Acceptance criteria

- Existing 2D gameplay and current validation checks remain unchanged.
- The imported scene tree and the presence/absence of mesh, materials, skeleton, and animation data are documented.
- Exact animation names and durations are recorded from the imported resource.
- If a complete character is present, an isolated preview can display it and play selected clips.
- No severe deformation, persistent floor penetration, or uncontrolled root motion appears in the preview.
- The experiment can be removed without affecting the playable 2D game.
- Android export and target-device performance are checked before any production adoption.
- The CC0 license file is preserved.

## Evidence to record

Include the Godot version, import warnings, imported node tree, mesh/material resource names, skeleton path and bone hierarchy, exact animation names/durations, root-motion variant tested, preview result, and go/no-go recommendation. If any of these cannot be established, record it as unknown rather than guessing.

## Proposed gameplay animation behavior

This section records the user's current design decision for the isolated prototype.

1. **Before first touch:** play `Idle`; the level can already be visible, but the player does not begin the run until the first screen tap.
2. **After first touch:** start the level and use `Jog_Fwd` or `Sprint` as the default running animation, selected to match the game's speed.
3. **Jump:** use `Jump_Start` at takeoff, `Jump` while airborne, and `Jump_Land` on landing, with transitions driven by gameplay state rather than by a random animation choice.
4. **One contextual action button:** the same touch button can select among `Crouch_Fwd` (low crouched movement) and `Roll` (the roll/slide animation shown with key `0`). To add visual variety, choose between those two eligible clips pseudo-randomly when the action is triggered.
5. **Randomness boundaries:** randomize only the visual/action variant on a valid button press. Do not randomly fire a slide/roll without player input, and do not randomize jump, landing, collision, invulnerability, hitboxes, or movement outcomes. Both variants must preserve consistent gameplay collision rules; otherwise the random choice would affect difficulty unfairly.
6. **Animation lock and recovery:** each action clip should play to a defined completion or cancel point before returning to the run animation. Exact timings and whether the action can be interrupted must be confirmed in the isolated prototype.
7. **Protect the baseline:** this is a design/prototype decision only. Keep `main.tscn`, `level_1.tscn`, and the existing 2D player unchanged until the separate prototype passes review.

## Current decision

**Preview passed; isolated integration prototype is the next step.** The Standard GLB is a complete animated mannequin and its clips play in the isolated preview. The user's proposed mapping is:
- Before first touch → `Idle`
- After start → `Jog_Fwd` or `Sprint`
- Jump → `Jump_Start` → `Jump` → `Jump_Land`
- One action button → randomly choose `Crouch_Fwd` or `Roll` on each valid press

The prototype should keep movement and collisions deterministic and separate from the cosmetic animation choice. Do not integrate into the production 2D scene until animation timing, transitions, and collision behavior have been checked. Imp/Puglin remain excluded.


## Obstacle climbing feasibility

The verified clip subset does not yet establish a dedicated climb/vault/mantle animation. Do not claim that a ready-made climbing clip exists until the full 42-clip list has been checked for names and visually previewed for suitable poses.

Recommended implementation options for the parkour prototype:
- Low obstacle: use normal jump logic if the jump trajectory clears the obstacle; this is a jump-over, not a climb.
- Medium obstacle: add or source a dedicated vault/mantle animation, or visually validate whether any existing clip can convincingly cover the motion. Drive character movement with gameplay code and avoid double-applying root motion.
- Tall obstacle: require a distinct climb/mantle animation and a clearly defined top/landing state; do not fake it with the Roll clip.
- Obstacle handling should be driven by collision/height classification and player/gameplay state. Animation must not determine collision results.

Before implementation, inspect all 42 clip names from the diagnostic output and add any plausible climb/vault clips to the preview controls for visual validation. If no suitable clip exists, record that a dedicated animation must be obtained or authored.
