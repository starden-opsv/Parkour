# Universal Animation Library — Standard Character Investigation

Status: isolated preview verified by the user in Godot 4.7.2. The Standard model and its animation clips play in the preview; integration into the playable game is still not approved.

## Goal

Determine whether `assets/Universal Animation Library[Standard]/Unreal-Godot/UAL1_Standard.glb` contains a complete, usable character or only a rig/animation resource, and whether its supplied animations are suitable for an isolated parkour prototype.

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

## Current decision

**Preview passed; production integration remains gated.** The Standard GLB is a complete animated mannequin and its clips play in the isolated preview. For the planned parkour controls, the mapping to test first is:
- Idle state → `Idle`
- Walking → `Walk`
- Running → `Jog_Fwd` or `Sprint` depending on game speed
- Jump takeoff → `Jump_Start`
- Airborne → `Jump`
- Landing → `Jump_Land`
- Slide → `Roll` (the clip previewed with key `0`)
- Optional crouched movement → `Crouch_Fwd`

The next stage is to test animation timing and transitions in a separate integration prototype. Keep the existing 2D gameplay as the production baseline until that prototype passes review. Imp/Puglin remain excluded.
