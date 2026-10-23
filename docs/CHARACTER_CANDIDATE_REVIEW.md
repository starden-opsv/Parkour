# Character asset review — Parkour Rush

## Decision

**Use only the Universal Animation Library Standard pack for this character investigation.** Do not use `Imp.glb` or `Puglin.glb` as the player character or as animation-retargeting targets. Keep the existing 2D character and gameplay as the production baseline while the asset is investigated in isolation.

## Confirmed repository facts

The committed Universal Animation Library is located at `assets/Universal Animation Library[Standard]/Unreal-Godot/` and contains:

- `UAL1_Standard.glb` (~7.6 MB)
- `UAL1_Standard_RM.glb` (~7.6 MB)
- `README.txt` and `License.txt`; the license identifies CC0 1.0 Universal.
- The README describes `UAL1_Standard.glb` as the variant without baked root motion and `UAL1_Standard_RM.glb` as the variant with root motion baked into animations.

The repository also contains a separate Bestiary pack, but `Imp.glb` and `Puglin.glb` are explicitly excluded from this project decision and must not be used for the player-character experiment.

## What is not yet verified

Repository file presence and animation names do not establish that either UAL GLB contains a complete, visually usable character mesh, materials, skeleton, and animations in Godot. No claim is made here that the GLBs have been successfully inspected in the Godot editor or tested on Android.

## Investigation order

1. Inspect `UAL1_Standard.glb` in Godot 4.7.2 first.
2. Establish whether it contains a complete character mesh and materials, a skeleton/rig, animation tracks, or only animation data.
3. Record the imported scene tree, mesh and material resources, skeleton node and bone hierarchy, animation names, and clip durations.
4. If the non-root-motion file contains the complete usable character, create a separate preview scene and test idle, run, jump, landing, and crouch/slide-like motions where available.
5. Inspect `UAL1_Standard_RM.glb` only as a comparison if needed; do not combine the two variants blindly.
6. Keep all experimentation outside `main.tscn` and the existing playable 2D path until there is evidence to justify a change.
7. If the GLB does not contain a usable character mesh, identify the specific missing component before choosing a compatible character asset. Do not fall back to Imp or Puglin.

## Acceptance gate

- [ ] Imported in Godot 4.7.2 without fatal errors.
- [ ] The presence or absence of character geometry, materials, skeleton, and animation data is documented separately.
- [ ] Exact animation names and durations are recorded from the imported resource.
- [ ] A separate preview scene can display the selected character and play representative clips.
- [ ] No severe deformation, persistent floor penetration, or unintended root-motion drift.
- [ ] The existing 2D game and its validation checks remain unchanged and passing.
- [ ] Android performance/export is checked before any production adoption.
- [ ] The included CC0 license is preserved.

## Current status

**Investigation pending.** The next required evidence is the actual imported node/resource structure and visual preview of `UAL1_Standard.glb`; do not infer that it is a ready-to-use protagonist from the filename or animation list alone.
