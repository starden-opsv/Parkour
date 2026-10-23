# Asset and implementation audit — Cycle 02

Date: 2026-10-23  
Scope: repository inspection only; no Godot runtime was available in this tool session, so this is not a runtime test report.

## Findings from the current main branch

### Existing art

- Character animation files are already organized under `assets/character/character/`: idle, running, jumping, runningjump, falling, landing and dashing.
- The current character setup in `level_1.gd` slices these sheets into 128×128 frames and uses scale 0.48 for normal movement.
- The slide action currently reuses the `dash` animation and compresses the displayed sprite vertically to 0.36 scale. This is a functional placeholder, not a dedicated slide/crouch animation. It may look like a squashed runner rather than a convincing parkour slide.
- The background already loads seven parallax layers from `assets/background/post_soviet_city_parallax/post_soviet_city_parallax/`.
- Graffiti images exist in `assets/graffiti/`, while the current level also contains procedural mural drawing. Since the user has already reported that the generated graffiti looks poor, procedural lettering should not be expanded. A future pass should compare the actual mural asset with the generated result and prefer a deliberate, authored composition if it reads better.
- A `character.zip` archive is present at the repository root, but GitHub's text-file API cannot inspect its binary contents. Do not assume it is safe to delete or that it contains the currently used sprite sheets.

### Existing automated checks

The repository already has `.github/workflows/godot-validation.yml`. It checks expected sprite sheet dimensions and parallax paths, imports the project headlessly, starts the main scene, and runs `tests/headless_smoke.gd`. Therefore a second generic Godot CI workflow would duplicate existing coverage; future changes should improve the existing tests instead.

## Highest-value next improvements

1. **Dedicated slide animation:** inspect the source/license for the current character pack and its `readme.txt` / `license.txt`. If no slide frame exists, either find a compatible licensed pack or create a temporary slide pose from the same art style; do not pretend the dash animation is a slide.
2. **Graffiti composition:** compare the existing authored `assets/graffiti/iluha_wall_full.png` with the procedural `_draw_wildstyle_mural` result. Keep the authored asset only if the source/license permits use and the image reads well at mobile scale. Do not replace it with more procedurally generated pseudo-lettering.
3. **Touch-control clarity:** inspect the bottom-screen zones and HUD layout at common landscape phone ratios. The current touch mapping is spatial (left = jump, center = slide, right = climb), so visible labels or button shapes must match those zones.
4. **Gameplay assertions:** add headless assertions for slide hitbox height, jump count/reset, obstacle hit behavior and coin scoring where the current smoke-test harness can reliably exercise them.
5. **Provenance:** record original asset source and license beside each third-party pack. Existing sprite sheets' license file must be read before redistribution or replacing them.

## Acceptance conditions for closing this audit

- [ ] Read the current character `license.txt` and `readme.txt`.
- [ ] Verify that the source pack permits the intended commercial/non-commercial distribution.
- [ ] Review the current GitHub Actions result for `godot-validation.yml`; do not infer success from the workflow file existing.
- [ ] Capture a real Godot screenshot or device/emulator run before making visual quality claims.
- [ ] Keep the next code change focused on one verified problem and run the relevant automated checks.
