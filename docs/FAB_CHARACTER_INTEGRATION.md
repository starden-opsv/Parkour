# FAB Stylized Young Boy — integration plan

## Selected asset

- Store page: https://www.fab.com/listings/3035e60f-5f9c-4351-a474-a26b2c64d5e0
- Creator shown on the listing: Abubakar Aulakh.
- Formats listed: FBX, GLB/glTF, DAE, BLEND, OBJ and PBR textures.
- Animations listed by the seller: idle, walk, run, jump, talk and sit.
- This game is currently a 2D side-scroller in Godot 4.7.2. The asset is a rigged 3D character, so it must not be dropped into the existing AnimatedSprite2D pipeline as if it were a 2D sprite sheet.

## Licensing and repository rule

The repository is public. Do not commit the downloaded source model, original textures, FBX/BLEND/GLB files, or exported source animation frames to this public repository. Fab's standard license permits use in a project and sharing with project collaborators, but prohibits standalone redistribution of the asset. Keep the purchased/downloaded package in a local, access-controlled folder and confirm the actual license tier shown for the purchase.

Suggested local-only location (do not commit):
`res://_licensed_assets/fab_stylized_young_boy/`

The project must remain buildable from the public repository without the licensed package. Add the local asset directory to `.gitignore` before copying any files into it.

## Chosen rendering path

Keep the gameplay and collision logic 2D. Render the rigged character from Blender into 2D sprite sheets with a consistent side-facing camera, orthographic projection, transparent background, fixed frame size, and fixed ground baseline. Import the resulting game-use frames into Godot as AnimatedSprite2D animations. This preserves the current 2D gameplay, hitboxes, mobile controls and level logic.

Do not replace the gameplay with CharacterBody3D or change the project to a 3D renderer.

## Animation mapping

| Godot animation | Source animation / action | Notes |
|---|---|---|
| `idle` | Idle | Loop |
| `run` | Run | Loop; main gameplay locomotion |
| `jump` | Jump | One-shot; trigger when jump begins |
| `fall` | Run/Jump pose or a separately authored fall action | Seller does not list a fall animation; inspect the downloaded rig before mapping |
| `land` | Jump end / landing pose | Seller does not list a separate landing animation; inspect and author/derive a short landing sequence if needed |
| `slide` | Not included in the listed set | Must be authored in Blender or replaced with a suitable licensed animation; do not fake a full slide by merely squashing the sprite |
| `talk`, `sit`, `walk` | Included source actions | Optional; not required for the first gameplay pass |

## Import and acceptance checklist

1. Download the package only through the purchaser's Fab account and read the actual license selected at checkout.
2. Keep the original package outside version control. Do not put it in a public commit, public release, Git LFS pointer, or public artifact.
3. Inspect the model's forward axis, rig, scale, materials, and animation names in Blender before building an export.
4. Render side-facing PNG sequences with transparency and identical dimensions for each frame. Keep the character's feet on a consistent baseline; avoid camera movement and per-animation scale changes.
5. Export at least `idle`, `run`, `jump`, `fall`, `land`, and `slide`. The final three actions may require Blender editing because they are not all listed as included animations.
6. Import the exported, game-use frames into `assets/character/fab_boy/` only after the license and redistribution implications for those derived frames have been checked. Keep source model files out of the public repository.
7. Add a separate Godot `SpriteFrames` resource and preview scene first; do not replace the current character until all required animations and collision alignment pass.
8. Verify the existing 2D hitboxes separately from the rendered character. Art dimensions must not silently alter jump, slide, obstacle or ground collision behavior.
9. Run the existing headless smoke test and add checks for required animation names, frame counts, and slide baseline before switching the level to the new character.

## Current limitation

The store page confirms a rigged 3D model and lists idle, walk, run, jump, talk and sit. It does not list a dedicated fall, landing or slide action. The actual model files are not available to this GitHub integration, so animation export and visual validation cannot be truthfully marked complete yet. This document records the safe integration path; it is not evidence that the asset has already been downloaded or animated in-game.
