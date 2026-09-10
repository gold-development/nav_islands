## 0.1.0-beta.2

- **A count badge on a chip.** `NavLink` and `NavAction` take a `badgeCount`;
  `0` draws nothing, so a caller passes a count straight through without
  writing a conditional around the item. Capped at `NavBadge.max` (99), above
  which it reads "99+" — a busy inbox must never widen a chip past its cell.
- The badge is **decorative**: it is wrapped in `ExcludeSemantics`, because the
  chip is already labelled and a bare number read out beside it tells a
  screen-reader user nothing. Where the count matters to them, it belongs in
  the item's `label` — "Alerts, 3 unread".
- It ignores the platform text scale, for the same reason as the cap: the chip
  is a fixed cell, and a 3× badge would burst it.
- `NavIslandStyleData` gains `badgeColor` and `badgeTextColor`, defaulted to a
  red legible on both the light and the dark pill, and now carried through
  `copyWith` — which previously dropped any field added after it.
- `NavBadge` is exported, so a caller can reuse the same dot outside the bar.

## 0.1.0-beta.1

First public prerelease, extracted from a private app.

- Island bottom bar with per-page layout overrides (`NavOverrideScope`).
- Selection indicator that stretches to its destination and retracts.
- Islands that slide in/out as a unit, and chips that morph in place when a
  glyph survives a page change.
- Quick-actions fan (`ActionsFanHost`) and wide pill button
  (`NavActionButton`).
- Depends on Flutter alone: `ChangeNotifier` state, caller-supplied navigation
  callbacks, caller-painted glyphs (`NavIcon.custom`), `NavIslandsThemeData`
  colours, and press feedback drawn without Material ink.

The API is expected to move before 0.1.0 proper.
