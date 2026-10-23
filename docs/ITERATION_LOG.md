# Parkour Rush 2D — Iteration log

## Working mode

This project is developed in autonomous, repeatable cycles. Each cycle runs the product, art/design, analysis, implementation and QA roles in sequence. After each complete cycle, publish the outcome and immediately continue with the next cycle in the same work session where tools and execution time permit. Do not wait for approval at intermediate stages. Keep changes small, reviewable and reversible; do not claim runtime tests or Android builds unless they were actually run.

## Cycle 01 — product and art-direction baseline

**Status:** baseline documented; implementation and runtime validation remain separate follow-up work.

### Product role

- Platform: Android, landscape-first, 2D parkour action.
- Core promise: fast, readable movement through a colorful urban rooftop course.
- The player should understand the next obstacle at a glance; visual spectacle must not hide hazards or landing surfaces.
- Keep the first level as a compact playable vertical slice rather than expanding the feature set before movement and readability are reliable.

### Art direction role

**Chosen direction:** bright stylized urban action, inspired by the readable side-on motion of *Vector* without copying its monochrome silhouette treatment.

- Player: colorful modern sportswear; strong silhouette and clear separation from the background.
- World: rooftop edges, vents, pipes, railings, maintenance boxes, construction barriers and distant city layers.
- Palette: cool blue/steel/purple urban structures; warm orange/yellow accents reserved for interactive hazards and route cues; a distinct saturated accent on the runner.
- Depth: foreground, playfield and distant skyline should be visually separable. Parallax is a later enhancement only after the base scene is stable.
- Graffiti is optional background dressing, not a primary visual system. Avoid procedural text/graffiti as a substitute for proper art assets.
- Avoid mixing pixel-art assets with smooth vector/cartoon assets in one scene unless they are deliberately unified by outlines, scale and palette.

### Asset evaluation rubric

Before integrating any pack, verify:
1. Side-on view suitable for a side-scrolling platformer (not top-down or isometric).
2. Required movement poses exist: run, jump/fall, slide/crouch, land or a plausible set that can be adapted.
3. The character and environment have compatible perspective, outline weight, detail density and scale.
4. Transparent PNG/sprite sheets are available at adequate resolution.
5. License is explicit and allows the intended project use; preserve attribution/license notes.
6. The asset can be imported and animated in Godot without relying on a proprietary editor.

### Research candidates (not yet integrated)

- **Modern City Game Kit — mimakuma:** https://mimakuma.itch.io/modern-city-game-kit  
  Free city tiles and props, rooftops, signs, traffic lights, vehicles and basic NPC animations. The creator allows commercial/non-commercial use and asks for credit. It is pixel art, so use only if the runner and level art are committed to a compatible pixel-art direction; do not mix blindly with vector art.
- **Pixel Platformer Basics — Yeon Games:** https://yeon-games.itch.io/pixel-platformer-basics  
  Free CC0 pixel-art platformer tiles and a simple player with idle/walk/jump poses plus pipes and mechanical props. Useful as a prototype kit, but not yet a strong final visual match for the desired modern-sportswear hero.
- **Vector — Nekki (reference only):** https://vector.game/  
  Reference for motion readability, obstacle rhythm and side-on parkour presentation, not an asset source and not to be copied.

**Decision:** do not download or commit a pack automatically based on name alone. The existing repo already contains `character.zip` and `backgroung.jpg`; inspect their actual contents and licensing before replacing them. A coherent pack with a usable slide animation is more valuable than a larger collection of mismatched props.

### Analyst role: requirements and acceptance criteria

- AC-01: launch screen's Start action opens the first level.
- AC-02: level runs in landscape orientation on Android and remains usable if viewport dimensions differ.
- AC-03: runner, ground and hazards have visibly distinct silhouettes.
- AC-04: every lethal/interactive obstacle can be distinguished from decoration before the player reaches it.
- AC-05: run, jump, slide and landing states must not visually overlap or hide the ground contact point.
- AC-06: touch controls have sufficiently large hit targets and do not cover the upcoming hazard area.
- AC-07: restart after failure is clear and does not require force-closing the app.
- AC-08: coins contribute to the end-of-run score, not to movement or collision behavior.
- AC-09: no asset is integrated without a recorded source and license.
- AC-10: a change is not called tested until the Godot editor/import or headless check and relevant gameplay scenario have actually been run.

### Developer role: implementation guardrails

- Keep `main.tscn` / `main.gd` as the entry screen unless there is a clear reason to refactor.
- Keep level logic in small named functions; avoid adding new mechanics while visual or collision bugs remain.
- Use exported constants or inspector properties for tunable movement values rather than scattering magic numbers.
- Prefer Godot-native nodes and resources; keep external asset files and license notes organized under `assets/`.
- Do not commit generated `.godot/`, Android build outputs, signing keys or secrets.

### Tester role: minimum smoke-test matrix

| Test | Procedure | Pass condition |
|---|---|---|
| T-01 | Open project in Godot 4.7.2 | No parse/import errors |
| T-02 | Run main scene | Start screen appears with readable title and button |
| T-03 | Press Start | Level 1 loads |
| T-04 | Test landscape viewport | HUD and controls remain visible |
| T-05 | Jump and slide near each obstacle type | Inputs trigger the intended state; collision is predictable |
| T-06 | Deliberately fail | Failure state and restart work |
| T-07 | Collect a coin and finish/fail | Score reflects collected coins |
| T-08 | Export Android debug build | Export succeeds; install/run on device or emulator is verified separately |

### Cycle 01 review / next cycle

The repository has an entry scene, level scene/script and a background/character archive, but the candidate asset licensing and actual animation coverage still need direct inspection. The next cycle should inspect the existing art files and level script, then prioritize the highest-impact gameplay/readability issue rather than adding more decorative code. If the current hero is not a real coherent sprite animation, replace it only after confirming a suitable pack and its license.
