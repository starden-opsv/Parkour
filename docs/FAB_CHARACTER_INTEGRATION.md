# FAB Stylized Young Boy — 3D game integration plan

## Decision

The project owner explicitly accepts converting Parkour Rush 2D into a 3D game if that is the better way to use this character. The preferred direction is now a **3D side-scrolling parkour game in Godot 4.7.2**, not rendering the model into sprite sheets by default.

Keep the side-scroller's readable lane-based gameplay, short levels, jump/slide controls, coins and restart loop. The camera follows the character from a fixed side angle; the world and character are 3D. This uses the model's rig and native animations directly and avoids a large Blender-to-sprite export pipeline.

Do not replace the entire existing level/gameplay in one unverified edit. Implement a separate vertical-slice scene first, compare it with the current prototype, and migrate gameplay systems in small, testable steps.

## Selected asset

- Store page: https://www.fab.com/listings/3035e60f-5f9c-4351-a474-a26b2c64d5e0
- Creator shown on the listing: Abubakar Aulakh.
- Formats listed: FBX, GLB/glTF, DAE, BLEND, OBJ and PBR textures.
- Animations listed by the seller: idle, walk, run, jump, talk and sit.
- Godot's documented preferred 3D exchange format is glTF 2.0 (.glb / .gltf); use a GLB export if supplied, otherwise import FBX or export from Blender to GLB.

## Licensing and repository rule

The repository is public. Do not commit the downloaded source model, original textures, FBX/BLEND/GLB files, or other standalone source assets to the public repository. Fab's Standard License permits use in a project and sharing with project collaborators, but prohibits standalone redistribution of the asset. Keep the purchased/downloaded package in a local, access-controlled folder and confirm the actual license tier shown for the purchase.

Suggested local-only location (do not commit):
`res://_licensed_assets/fab_stylized_young_boy/`

The `/_licensed_assets/` directory is ignored by Git. The public repository must remain usable without the licensed package, with clear setup instructions and a safe placeholder/fallback if the asset is absent.

## 3D vertical-slice architecture

Create a separate scene before replacing the current project entry scene:

- `scenes/3d_prototype/parkour_3d_test.tscn` — short test track with ground, one jump obstacle, one slide obstacle, a coin, lighting and fixed side camera.
- `scenes/3d_prototype/player_3d.tscn` — `CharacterBody3D`, collision shape, model pivot, imported character scene and `AnimationPlayer`/animation tree as appropriate.
- `scripts/3d_prototype/player_3d.gd` — movement state machine; ground movement along one world axis, jump on vertical axis, gravity, and slide state.
- `scripts/3d_prototype/camera_3d.gd` — fixed side camera that tracks player position without rotating around the scene.
- Keep the current 2D scenes and scripts unchanged until the vertical slice passes acceptance checks.

The game can still be a side-scroller: constrain player depth movement, lock the camera to the side, and compose obstacles on one plane. Avoid unnecessary free-roaming 3D mechanics.

## Animation mapping

| Gameplay state | Source animation / implementation | Notes |
|---|---|---|
| `idle` | Idle | Loop when stationary |
| `run` | Run | Loop during ground movement; primary gameplay state |
| `jump` | Jump | Start on jump; inspect whether it includes a complete take-off and landing |
| `fall` | Jump/air pose or authored fall | Seller does not list a dedicated fall action; inspect the actual rig |
| `land` | Jump ending or authored short landing | Seller does not list a dedicated landing action |
| `slide` | Not listed | Required gameplay animation; author a compatible slide in Blender or obtain a separately licensed matching animation |
| `walk`, `talk`, `sit` | Included source actions | Optional for first playable slice |

Use animation state transitions driven by gameplay state, not by the animation's visual pose. Collision height and slide duration must be controlled by the player state machine and collision shape, not inferred from the model's bones.

## Implementation phases

### Phase 1 — local asset verification
1. Download the package through the purchaser's Fab account.
2. Keep it in the ignored local asset folder; never commit it or put it in public artifacts.
3. Inspect the model, skeleton, materials, root motion, scale, facing direction and actual animation names in Blender or Godot.
4. Confirm the model imports and its run/jump animations play in Godot 4.7.2.

### Phase 2 — isolated 3D vertical slice
1. Add the separate 3D player and test-track scenes listed above.
2. Use `CharacterBody3D` and `CollisionShape3D` for collisions; align the capsule to the model's feet.
3. Implement keyboard controls for editor testing and reuse the project's planned touch jump/slide controls for mobile.
4. Add fixed side camera, one jumpable obstacle, one slide-under obstacle and one collectible.
5. Add a fallback placeholder so headless CI can test the scene even when the licensed model is not present.

### Phase 3 — animation and collision validation
1. Verify idle/run/jump transitions, landing, and return to run.
2. Add or create a slide animation. Until it exists, do not mark slide polish complete.
3. Confirm the collision capsule lowers during slide and restores after it; prevent standing up inside an obstacle.
4. Test repeated jump/slide input, landing at obstacle edges, death/restart and coin collection.
5. Run the Godot headless smoke test and add 3D scene/state checks.

### Phase 4 — migration decision
Only after the vertical slice is playable and stable, decide whether to migrate the complete game. If accepted, port one system at a time: player movement, obstacles, level finish, coins/score, restart/death, UI, then Android controls and export. Keep the 2D prototype available until the 3D version passes acceptance.

## Acceptance criteria

- Project imports in Godot 4.7.2 with no missing-resource errors when the local licensed asset is installed.
- The character faces and moves consistently along the side-scrolling track.
- Run/jump animations are triggered by gameplay state and do not drift away from the collision body.
- Slide lowers the collision shape and passes under a test obstacle without changing ground height.
- Coin collection, death/restart, and finish trigger correctly in the vertical slice.
- Camera stays fixed to the side and does not introduce depth movement or unwanted perspective changes.
- CI can run without the licensed asset; no marketplace source model is stored in public Git history.

## Current limitation

The actual model files are not available to this GitHub integration, so I cannot truthfully claim the model has been imported, the animation names verified, or the game converted. The current PR prepares a safe path. Runtime implementation begins after the package is present locally; meanwhile, the existing 2D prototype remains intact.
