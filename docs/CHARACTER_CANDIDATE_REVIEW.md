# Character candidate review — Parkour Rush 2D

## Decision status

**Do not replace the current playable character with Imp or Puglin yet.** Keep the existing 2D character as the production baseline and treat the two Bestiary models as unapproved experiments.

## Evidence in the repository

The committed pack at `assets/Bestiary - Dungeon Monsters Kit[Standard]/` contains:
- `Exports/GLB (Godot-Unreal)/Imp.glb` (~9.4 MB)
- `Exports/GLB (Godot-Unreal)/Puglin.glb` (~7.9 MB)
- matching FBX exports and shared pack textures/license.
- No wolf model and no animation files were found in the committed pack tree.

## Candidate assessment

| Criterion | Imp | Puglin |
|---|---|---|
| Exists in repo as GLB | Yes | Yes |
| Ready to inspect in Godot | Yes, GLB is the native-friendly option | Yes, GLB is the native-friendly option |
| Animation included in this pack | Not evidenced; no animation files present | Not evidenced; no animation files present |
| Fits an urban rooftop parkour protagonist | Unproven; fantasy dungeon creature is a strong art-direction mismatch risk | Unproven; fantasy dungeon creature is a strong art-direction mismatch risk |
| Safe to make the production character now | No | No |

This is a repository-and-art-direction assessment, not a claim that the meshes or rigs have been tested in the Godot editor. The GitHub connector exposes the filenames and sizes but does not let this review inspect the models in a running Godot scene.

## Recommended next step

1. Keep the current 2D character as the fallback; do not pivot the game to 3D just to use these models.
2. In Godot, import each GLB and verify that the skeleton exists and whether animation tracks are embedded.
3. If the models are rigged but unanimated, test a small sample of the free Quaternius Universal Animation Library clips. Do not assume retargeting works until the skeleton mapping and motion are inspected.
4. Test both candidates in a simple side-view rooftop scene at actual gameplay scale. Judge silhouette readability, jump/landing/slide pose readability, clipping, and mobile performance.
5. Promote one only if it passes the checks. Otherwise reject both and continue with a stylized 2D runner character consistent with the existing project.

## Acceptance gate

A candidate is approved only when all of the following are verified:
- [ ] Imports in the project's Godot 4.7.2 version without errors.
- [ ] Idle/run/jump/landing/slide (or convincing equivalents) play without broken limbs or foot sliding.
- [ ] Collision shape stays aligned during jump and slide.
- [ ] Silhouette remains readable against the current city background at phone-sized view.
- [ ] Performance is acceptable on an Android device.
- [ ] License and attribution requirements are recorded before release.

## Animation sources to test

- [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) — free Standard option, CC0 as described by the publisher.
- [Quaternius Universal Animation Library 2](https://quaternius.itch.io/universal-animation-library-2) — free Standard option, CC0 as described by the publisher.

These are test candidates only. Compatibility with Imp or Puglin is **not verified**.