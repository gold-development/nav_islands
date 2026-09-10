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
