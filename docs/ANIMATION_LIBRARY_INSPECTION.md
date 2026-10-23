# Animation library inspection — iteration 3

Date: 2026-10-24

## Verified repository facts

- The Universal Animation Library is committed under `assets/Universal Animation Library[Standard]/`.
- The Godot/Unreal export folder contains `UAL1_Standard.glb` and `UAL1_Standard_RM.glb`.
- The accompanying README distinguishes the two variants: the `_RM` variant has root motion baked into animations; the non-RM variant has root motion disabled.
- The accompanying license file declares CC0 1.0 Universal.
- The current candidate character files are `Imp.glb` and `Puglin.glb` from the Bestiary — Dungeon Monsters Kit. The pack does not contain a wolf model.
- GitHub Actions run [40029823785](https://github.com/starden-opsv/Parkour/actions/runs/40029823785) completed successfully. Its ten steps passed, including asset-presence checks, Godot 4.7.2 resource import, main-scene startup, and headless smoke tests.

## What this does and does not prove

The successful CI run proves that the checked-in project and resources pass the automated checks currently configured. The asset-presence check only verifies that the GLB files exist and are non-empty. It does **not** prove that the animation GLBs contain a compatible skeleton, that they retarget to Imp or Puglin, or that the resulting poses look correct in-game.

The README and license are source-document evidence for root-motion variants and licensing. They are not evidence of skeleton compatibility.

## Next validation gate

1. Inspect both GLB files in Godot 4.7.2 and record imported scene roots, skeleton hierarchy, animation names, and durations.
2. Import Imp and Puglin in the same Godot version and record their skeleton hierarchies.
3. Compare skeletons and determine whether retargeting is supported without destructive rig changes.
4. If a compatible path exists, make a disposable test scene outside the playable game and test idle/run/jump/fall/landing/slide.
5. Compare root-motion and in-place variants. For a side-scrolling platformer, prefer in-place animation unless root motion is deliberately reconciled with game movement.
6. Measure Android export/import cost and visual quality before approving integration.

## Decision

**Do not integrate the animation library into the playable game yet.** Keep the current 2D baseline and treat 3D character animation as an isolated compatibility spike. The next meaningful acceptance result must include actual Godot-imported skeleton and animation data plus visual pose validation, not just file checks.
