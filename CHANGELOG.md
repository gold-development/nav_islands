## 0.1.0-beta.4

Three fixes found by building the package into a second app, plus one the
extraction itself left behind. No API changes.

- **Fix:** `NavOverrideScope` dropped `centerStyle` on its way into the
  controller, so a page that asked for a bare centre island got a pill.
- **Fix:** a chip's badge hung off the corner of its bounding box, which on a
  one-chip island falls outside the circular pill and was sliced off by the
  island's clip. It is now tucked in to where the two circles touch
  (`badgeCornerInset`), so it reads the same on a circle and on a wide pill.
- **Fix:** `NavOverrideScope` asked only whether its own route was current. A
  page inside a nested navigator — a shell route, a tab view — stays the top
  route of *its* navigator while the shell is being replaced, so the leaving
  page re-asserted its islands over the screen that replaced it.
  `isRouteChainCurrent` walks up to the root navigator, and is exported for
  hosts that need the same answer.

## 0.1.0-beta.3

- **A bare island.** `NavIslandStyle.bare` draws no pill — no fill, border,
  shadow or selection wash — and clips nothing, so the item inside brings its
  own shape and may stand taller than the bar. For a centre island that is a
  control in its own right, like a raised primary button.
- **`centerStyle`.** `NavIslands` and `NavIslandsController.override` take a
  style for the centre island alone, falling back to `style` when unset
  (`resolvedCenterStyle`). The usual layout is two ordinary side islands with a
  bare button between them, so styling the whole bar bare was never the answer.
- `NavIslandsThemeData` gains a `bare` palette, and `styleFor` is exhaustive
  over the enum rather than "dark or else light".
- **Fix:** `NavIslandStyleData` compared equal while its badge colours differed,
  so `NavIslandsTheme.updateShouldNotify` decided nothing had changed and a
  themed badge kept the colour it was built with. Same family as the `copyWith`
  bug in beta.2: a field added to the class and to nothing else.

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
- **A runnable sample** in `example/`, mirrored into the readme: a shell with a
  badge, a search toggle, a filled call-to-action, a dark section and a pushed
  page with its own back chip.

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
