# Backlog — Parkour Rush 2D

## P0 — Wall climb / ledge climb (required)
- [ ] Implement a real wall-climb action: the character reaches up, grabs the top edge, pulls their torso upward, brings a leg onto the ledge, shifts their body over the lip, and stands on the top surface.
- [ ] Inspect all 42 clips in Universal Animation Library Standard for a dedicated climb / mantle / ledge-grab animation; validate candidates visually, not by clip name alone.
- [ ] If the library has no suitable animation, obtain or author a compatible animation for the existing Standard skeleton and document its source/license.
- [ ] Keep gameplay collision and reachability deterministic and separate from animation playback.
- [ ] Add tests for unreachable/tall walls, valid ledges, repeated input during a climb, and landing on the top.
- [ ] Review the current visual prototype. The temporary Jump_Start → Jump → Jump_Land sequence is only a motion placeholder; it is not accepted as the final hand-grab/pull-up animation.
- [ ] Do not use Imp.glb or Puglin.glb; do not substitute Roll for climbing.
- [ ] Do not change production 2D gameplay until the climb animation and gameplay behavior pass review.

## P1 — Animation integration
- [ ] Finish the animation inventory for UAL1_Standard.glb and visually test plausible climb/mantle clips.
- [ ] Verify animation transitions, character scale/orientation, floor contact, and Android performance.
