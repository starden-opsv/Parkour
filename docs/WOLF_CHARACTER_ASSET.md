# Wolf character asset — Parkour Rush

## Selected asset

- Pack: [Bestiary — Dungeon Monsters Kit](https://quaternius.com/packs/bestiarydungeonmonsterskit.html)
- Free download: [Quaternius on itch.io](https://quaternius.itch.io/bestiary-dungeon-monsters-kit) — select **Download Now** and the **Standard** ZIP; no payment is required.
- License: Quaternius Asset License (QAL), as stated on the pack page. Review the current license before shipping.
- Formats listed by the author: FBX, GLB/glTF, Blender.
- The pack includes rigged humanoid monsters but does not include animations.

## Free animation source

- [Universal Animation Library](https://quaternius.itch.io/universal-animation-library) — Standard download is free (pay-what-you-want, choose $0) and CC0.
- [Universal Animation Library 2](https://quaternius.itch.io/universal-animation-library-2) — separate free Standard download, CC0; includes additional movement and parkour clips.
- Both libraries target humanoid rigs and support retargeting, but each clip must be tested on the wolf model. Quadruped-specific motion may not retarget naturally to a humanoid skeleton.

## Local import location

Place the downloaded wolf model under `res://_licensed_assets/quaternius_bestiary_wolf/` and keep the original ZIP outside the repository. The project `.gitignore` intentionally excludes `/_licensed_assets/` so marketplace/source archives are not accidentally committed.

Import the model into Godot 4.7.2, inspect its skeleton and animation tracks, then test retargeting with the free Standard animation clips. Required prototype checks: idle, run, jump, landing, slide/crouch, collision capsule alignment, and side-camera readability.

## Repository status

This document records the selected source and import plan. The actual model binary is not committed yet: it must first be downloaded from the official source and its files checked. Do not treat the character as integrated until the in-engine test passes.