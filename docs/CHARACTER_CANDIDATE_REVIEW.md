# Character candidate review — Parkour Rush

## Decision status

**Imp and Puglin remain unapproved experiments.** Keep the existing 2D character as the production baseline until the models and animation retargeting are tested in Godot. The animation library is now present in the repository, but its presence alone does not prove compatibility.

## Evidence in the repository

The committed Bestiary pack at `assets/Bestiary - Dungeon Monsters Kit[Standard]/` contains:
- `Exports/GLB (Godot-Unreal)/Imp.glb` (~9.4 MB)
- `Exports/GLB (Godot-Unreal)/Puglin.glb` (~7.9 MB)
- matching FBX exports and shared pack textures/license.
- No wolf model and no animation files in the Bestiary pack.

The committed Quaternius Universal Animation Library at `assets/Universal Animation Library[Standard]/Unreal-Godot/` contains:
- `UAL1_Standard.glb` (~7.6 MB)
- `UAL1_Standard_RM.glb` (~7.6 MB)
- `README.txt` and `License.txt`, identifying the library license as CC0 1.0 Universal.
- README explains that the `_RM` file has root motion baked into every animation; the non-`_RM` file has root motion disabled.

## Candidate assessment

| Criterion | Imp | Puglin |
|---|---|---|
| Exists in repo as GLB | Yes | Yes |
| Ready to inspect in Godot | Yes | Yes |
| Animation in Bestiary pack | No | No |
| Separate animation library committed | Yes | Yes |
| Rig/retarget compatibility verified | No | No |
| Fits an urban rooftop parkour protagonist | Unproven; fantasy creature risks clashing with the urban direction | Unproven; fantasy creature risks clashing with the urban direction |
| Approved for production | No | No |

This is a repository audit, not a claim that the models or animations have been opened and tested in the Godot editor.

## Next test sequence

1. Import the two Bestiary GLBs and the animation-library GLB in Godot 4.7.2.
2. Inspect the imported scenes for skeletons, animation names, bone hierarchy, scale, and root-motion behavior.
3. Test retargeting a small representative set: idle, run, jump, landing, and crouch/slide if available.
4. Verify poses and motion visually on both Imp and Puglin. A successful import does not prove retargeting quality.
5. Build a disposable side-view rooftop test scene. Check silhouette readability at phone size, foot sliding, deformation, clipping, collision alignment, and Android performance.
6. Only promote a model if it passes these checks. Otherwise keep the 2D baseline and seek a character asset that matches the art direction.

## Acceptance gate

- [ ] Imports in Godot 4.7.2 without errors.
- [ ] Idle/run/jump/landing/slide or convincing equivalents are available and look correct.
- [ ] No broken limbs, severe foot sliding, or visible retargeting errors.
- [ ] Collision shape remains aligned during jump and slide.
- [ ] Character is readable against the rooftop background at phone-sized view.
- [ ] Android performance is acceptable.
- [ ] License is recorded before release.

## License

The animation library's committed `License.txt` identifies CC0 1.0 Universal. Preserve the license file in the repository. Compatibility and actual in-game quality remain unverified.