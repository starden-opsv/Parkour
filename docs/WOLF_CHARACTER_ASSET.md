# Character asset investigation — Parkour Rush

## Outcome

The wolf is **not present** in the repository's committed Bestiary pack. The actual GLB files present are **Imp** and **Puglin**. See [Character candidate review](CHARACTER_CANDIDATE_REVIEW.md) for the current decision gate.

## Pack source

- [Bestiary — Dungeon Monsters Kit](https://quaternius.com/packs/bestiarydungeonmonsterskit.html)
- [Free Standard download](https://quaternius.itch.io/bestiary-dungeon-monsters-kit)
- Pack license file committed in the repository: `assets/Bestiary - Dungeon Monsters Kit[Standard]/License_Standard.txt`

## Files already committed

- `assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Imp.glb`
- `assets/Bestiary - Dungeon Monsters Kit[Standard]/Exports/GLB (Godot-Unreal)/Puglin.glb`
- Matching FBX files and textures are also committed.
- The repository tree contains no wolf model and no animation files inside this pack.

## Free animation test sources

- [Universal Animation Library](https://quaternius.itch.io/universal-animation-library)
- [Universal Animation Library 2](https://quaternius.itch.io/universal-animation-library-2)

The publishers offer free Standard downloads and identify these animation libraries as CC0. **Compatibility with Imp or Puglin has not been verified.** Retargeting must be tested in Godot before the models can be accepted as playable characters.

## Import/test procedure

1. Import the committed GLB files directly from the pack's `Exports/GLB (Godot-Unreal)` directory.
2. Inspect each imported scene for skeletons and embedded animation tracks.
3. If no suitable clips are embedded, test animation retargeting with the libraries above.
4. Test idle, run, jump, landing and slide/crouch in a side-view city scene.
5. Reject either model if poses are unreadable at mobile scale, rig deformation is poor, collision alignment fails, or the fantasy style clashes with the urban parkour direction.

Do not describe the wolf as selected or integrated until the actual wolf file is found and passes these checks.