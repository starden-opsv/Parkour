# Universal Animation Library Integration Spike

Status: planned against repository assets; not yet imported or executed in Godot.

## Goal

Determine whether the Universal Animation Library can be used with the committed Bestiary Imp/Puglin models in Godot 4.7.2 without damaging the existing 2D gameplay build. Do not replace the current 2D player or switch the game to 3D during this spike.

## Confirmed repository facts

- Animation files are under `assets/Universal Animation Library[Standard]/Unreal-Godot/`.
- `UAL1_Standard.glb` is the non-root-motion variant according to the included README.
- `UAL1_Standard_RM.glb` has root motion baked into its animations according to the included README.
- The included license states CC0 1.0 Universal.
- The candidate character files currently committed are `Imp.glb` and `Puglin.glb`.
- Repository inspection alone does not establish that the animation skeleton matches either character, that the files import correctly in Godot, or that the clips are suitable for parkour.

## Spike sequence

1. **Keep the current game stable.** Run the existing Godot validation workflow and record its result before adding any 3D scene to the main game.
2. **Import without modifying gameplay.** Open the project with Godot 4.7.2 and let the editor import both animation GLBs and both character GLBs. Check the Output panel for import errors/warnings. Do not commit generated `.godot/` cache data.
3. **Inspect animation source.** In Godot's Import/Scene view, record the imported node tree, skeleton node(s), animation names, duration, and whether clips contain root motion. Do not guess clip names before reading the imported AnimationPlayer/AnimationLibrary.
4. **Inspect candidate rigs.** For Imp and Puglin separately, record the skeleton path and bone count. Compare bone names/hierarchy against the animation source. Matching bone count alone is not sufficient evidence of compatibility.
5. **Retarget only if needed.** If skeletons differ, use Godot's supported SkeletonProfileHumanoid/retarget workflow only if the source and target rigs are actually humanoid and map cleanly. The Imp/Puglin body proportions may make some motions unusable; reject bad deformations rather than forcing a retarget.
6. **Build an isolated preview scene.** Create a temporary test scene under a dedicated test folder; do not wire it into `main.tscn` or `level_1.tscn`. Display one model, a neutral floor, lighting, and a simple camera. Keep preview scene mobile-friendly and separate from the 2D game.
7. **Evaluate clips visually.** Test idle, locomotion/run, jump/takeoff, airborne/fall, landing, and low/slide-like pose if the library contains them. Inspect foot sliding, root drift, limb twisting, clipping, pose readability, and whether transitions are possible. A clip name alone does not qualify it.
8. **Compare root-motion variants.** For an endless runner where gameplay controls world speed, start evaluation with `UAL1_Standard.glb` (root motion disabled) to avoid animation moving the character independently of game logic. Compare the RM version only if there is a specific design need and root motion can be extracted/controlled deliberately.
9. **Test performance/export.** Only after visual acceptance, run the headless CI checks and a real Android export/device test. GLB file size is not the same as runtime memory or GPU cost; inspect texture sizes/material count and test on target hardware.
10. **Make a go/no-go decision.** Keep the existing 2D sprite character unless a 3D preview clearly improves the game's art direction, animation readability, mobile performance, and implementation effort.

## Acceptance criteria

- Existing `main.tscn`, `level_1.tscn`, and current 2D animation smoke tests still pass unchanged.
- Both source GLBs import without fatal errors in the chosen Godot version.
- A test scene can instantiate the selected character and play selected clips without missing resources.
- A written mapping records exact source animation names and target actions.
- Run, jump, fall, and landing are visually readable; no severe skeleton deformation or persistent floor penetration.
- Character motion is controlled by gameplay code; root motion is not accidentally double-applied.
- Android export succeeds and target-device performance is acceptable before adoption.
- The 3D experiment is isolated and can be deleted without affecting the current game.

## Required evidence before adoption

Attach to the review (as notes, not necessarily screenshots): Godot version, import warnings, animation names/durations, skeleton node paths, retarget mappings if any, selected root-motion variant, tested device/export result, and final go/no-go recommendation.

## Current decision

**No-go for integration into the playable game until the spike passes.** This is a verification gate, not a rejection of the library. Preserve the current 2D game as the shipping baseline and evaluate the 3D character/animation as a separate prototype.
