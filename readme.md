# CycleMagic

EasyNuke provides universal commands for casting single target and area of effect BLM, WHM, SCH, and GEO nukes.

## commands

### change element: //cma ele `X`

This will change the current active element to a different one. `X` can be one of these:
- `fire`, `wind`, `thunder`, `ice`, `water`, `earth`,`light`,`dark`
  - sets the active element directly
- `next`, `prev`
  - change active element to the next or previous in the above order
- `temp`
  - cycle the temporary element for `c-` spells below
  - resets back to the active element after a short while
- `show`
  - prints a message with the current active element

### cast a spell: //cma `type` `level` `target`

This will cast a spell based on the current active element.

`type` can be one of:
- `nuke`, `ancient`
  - will cast the single target nuke to match the element
- `nukega`, `nukera`
  - BLM and GEO AOE spells
- `cnuke`, `cancient`, `cnukega`, `cnukera`
  - uses a temporary element for these spells, without changing the active element
  - cycle the temporary element with `//cma ele temp`
- `helix`, `storm`
  - SCH spells
- `chain`
  - first and second Immanence spells to chain, which can be bursted by the active element

`level` will be the spell level number (e.g. 3 for `Water III`), unless you are casting `chain`, in which case it will be 1 or 2 for the first and second spell in the chain. This defaults to `1`.

`target` can be any standard target of a spell. (e.g. `<stnpc>` or `valaineral`). This defaults to `<me>` for storm, and `<t>` for all other spells.