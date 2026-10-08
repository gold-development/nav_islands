# nav_islands

A floating **island** bottom navigation bar for Flutter.

Instead of one fixed bar owning a list of destinations, the bar is three
independent pills — left, centre, right — and **each page asserts the layout it
wants** while its route is current. The bar lives above the navigator, so it
survives navigation and animates from one page's layout to the next: islands
that empty slide out, islands that keep their shape morph in place, and the
selection indicator stretches across to its destination and retracts.

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/nav.gif" width="280" alt="Boards to Settings and its dark pills, back to Inbox, then into an item page with a single back chip"></p>

From Boards to Settings, the indicator stretches across and the pills turn
dark, because the Settings page asks for dark ones. Back on Inbox, opening an
item swaps the whole bar for one back chip: the centre and right islands slide
away, and the left island trades its search chip for a back arrow. Every picture in this README
is [the example app](#a-complete-app) on a phone, and each feature below has
its own.

## Features

- **Per-page layouts.** Each page asserts the islands it wants with a
  `NavOverrideScope`; the bar, mounted once above the navigator, animates from
  one page's layout to the next — see [Usage](#usage).
- **Three islands** — left, centre, right — each sliding in and out on its
  own. The centre island stays on the screen's axis; side islands hug it or sit
  on the screen edge (`NavIslandAlignment`).
- **Three kinds of item** — `NavLink` (a destination, lit by `activeId`),
  `NavAction` (a callback, lit by `isActive`, a filled call-to-action with
  `tint`) and `NavWidget` (anything, a `span` of cells wide) — see
  [Items](#items).
- **A moving selection indicator** that stretches across to its destination
  and retracts, with the covered glyph taking the item's `accent`.
- **Count badges** on links and actions (`badgeCount`), capped at 99+.
- **Light, dark and bare pills**, asserted per page and morphed between; a
  `bare` centre island is a button of its own, as big as the bar is tall, and
  can open a fan whose close button takes its place at its size — see
  [A centre island that is a button](#a-centre-island-that-is-a-button).
- **Any glyph**: `NavIcon.material` for icon fonts, `NavIcon.custom` to paint
  anything else — see [Custom glyphs](#custom-glyphs).
- **Wide primary buttons**: `NavActionButton` and `.secondary`, with a `busy`
  state and its own `NavSpinner` — see
  [Wide chips and primary buttons](#wide-chips-and-primary-buttons).
- **Quick actions**: `ActionsFanHost` fans labelled actions out of any chip —
  or any `NavWidget`, through `NavAnchorReporter` — found by its id, with the
  labels running towards the middle of the screen and wrapping rather than
  running off it — see [Quick actions](#quick-actions).
- **Above the keyboard**, per layout: a form's cancel and save ride on top of
  the keyboard, while a navigation bar stays behind it — see
  [Above the keyboard](#above-the-keyboard).
- **Single-action pages**: `NavSingleActionBar` for a back or close chip on its
  own, in the island of your choice — see
  [Pages with a single action](#pages-with-a-single-action).
- **Theming** through `NavIslandsTheme`: colours, text styles, shadows, the
  bar's geometry, the fan's sizes and every duration, with defaults that stand
  on their own — see [Theming](#theming).
- **Accessibility**: every chip is labelled, badges stay out of the way of
  screen readers, and "reduce motion" collapses the animations.
- **Building blocks** to make your own items match: the metrics, an island or
  chip outside the bar, the badge, the spinner, the press feedback — see
  [Building blocks](#building-blocks).
- **No dependencies**, not even Material — see below.

## No dependencies

Flutter and nothing else — not even Material:

| Concern | How |
| --- | --- |
| State | `NavIslandsController`, a plain `ChangeNotifier` |
| Navigation | Callbacks you supply — bring any router, or none |
| Glyphs | `NavIcon.custom`, painted by you (svg, bitmap, icon font, …) |
| Look and motion | `NavIslandsThemeData`, with usable defaults |
| Press feedback | Drawn by the package, so no `Material` ancestor is needed |

## Usage

The pieces below are pulled apart one at a time; [A complete app](#a-complete-app)
at the bottom is all of it in one runnable file.

Own a controller at app level and put a scope above your navigator:

```dart
final controller = NavIslandsController();

NavIslandsScope(
  controller: controller,
  child: MaterialApp(/* … */),
);
```

Mount the bar over your pages — it renders nothing while no page asserts a
layout:

```dart
Stack(
  children: [
    child,
    const Align(alignment: Alignment.bottomCenter, child: BottomNavBar()),
  ],
);
```

Invalidate the layout whenever the route changes, so the leaving page's islands
hand over to the entering page's:

```dart
router.addListener(() {
  controller.softReset();
  // Nothing asserted a layout this frame? Then no page wants a bar.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!controller.overridden) controller.reset();
  });
});
```

Then each page declares what it wants:

```dart
NavOverrideScope(
  islandsBuilder: (context) => NavIslands(
    activeId: 'overview',
    center: [
      NavLink(
        id: 'overview',
        icon: NavIcon.material(Icons.list),
        label: 'Overview',
        onTap: () {},
      ),
      NavLink(
        id: 'archive',
        icon: NavIcon.material(Icons.archive),
        label: 'Archive',
        onTap: () => context.go('/archive'),
      ),
    ],
  ),
  child: const SizedBox.shrink(),
);
```

Pages that scroll should pad their content by `bottomNavOverlayHeight(context)`
so the last row clears the floating bar.

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/home.png" width="240" alt="The Inbox page: search on the left, three sections in the centre, + on the right">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/item.png" width="240" alt="An item page: nothing but a back chip on the left edge">
</p>

Two pages, two layouts, one bar. The Inbox page asserts three islands; the
item page pushed on top of it asserts a single back chip on the left edge.
Neither page builds the bar itself — it stays mounted above the navigator and
animates between whatever the current page asks for.

### Items

- **`NavLink`** — a destination. Active when its `id` matches the layout's
  `activeId`.
- **`NavAction`** — runs a callback; active while its `isActive` says so. Give
  it a `tint` to render as a filled call-to-action circle.
- **`NavWidget`** — anything you like in a chip's place (a badge, a counter, a
  wide button — see `NavActionButton`).

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/bar_home.png" width="480" alt="Close-up of the Inbox bar"></p>

From left to right: a `NavAction` (search) alone in the left island; three
`NavLink`s in the centre, Inbox active, so the indicator sits under it, with a
`badgeCount` of 3; and a `NavAction` with a `tint` on the right, which fills
the chip as the page's call to action.

Each item declares a `span` in cells, so a wide item can claim more room — a
cell never grows past 48 pt however wide the screen, so span is the only way to
make a chip big enough for a sentence.

**What actually fits is the number of cells, not of items.** A cell will not
shrink below the 44 pt touch target, so a 320 pt phone holds six of them across
the whole bar, five once three islands are on screen and each pays for its own
padding. `kMaxNavItems` is 8, which is a cap on *items* and is more than that
width can draw: ask for more than fits and `computeNavMetrics` asserts, with
the two numbers in the message, rather than letting an island overflow its
slot.

### Custom glyphs

`NavIcon.material` covers icon fonts. For anything else, paint it yourself —
the bar hands you the colour and size it wants, and `glyphKey` tells it when
two icons are the same glyph, so a chip surviving a page change morphs in place
rather than sliding out and back in:

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/bar_compose.png" width="480" alt="Close-up of the Compose bar: Cancel, a three-dot chip, Send"></p>

The Compose page's centre chip is painted with a `CustomPainter` — three dots
in whatever colour the bar hands over. The pills either side are
`NavActionButton`s ([Wide chips and primary buttons](#wide-chips-and-primary-buttons)).

```dart
NavIcon.custom(
  glyphKey: path,
  painter: (context, color, size) => SvgPicture.asset(
    path,
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  ),
);
```

### Theming

The defaults render correctly on their own. To match your design system, wrap
the bar in a `NavIslandsTheme`. Each `NavIslandStyle` — `light`, `dark` and `bare`,
asserted per page — has its own pill, border, glyph and indicator colours:

```dart
NavIslandsTheme(
  data: NavIslandsThemeData(
    light: NavIslandStyleData(
      pillColor: scheme.surfaceContainerLowest,
      borderColor: scheme.outlineVariant,
      iconColor: scheme.onSurface,
      indicatorColor: scheme.onSurface.withValues(alpha: 0.08),
    ),
  ),
  child: /* … */,
);
```

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/dark.png" width="240" alt="The Settings page with dark pills"></p>

The Settings page asserts `style: NavIslandStyle.dark`, so its pills, borders
and glyphs take the theme's `dark` colours, and morph back to `light` on the
way out.

Beyond the colours, the theme holds the rest of the look, the geometry and the
timing, each defaulting to the package's own value (`BottomNavTokens`):

| Part | Fields |
| --- | --- |
| Text | `defaultTextStyle`, `actionButtonLabelStyle`, `fanLabelStyle`, `badgeTextStyle` |
| Shadows | `shadowColor`, or whole lists: `islandShadows`, `fanShadows`, `fanLabelShadows` |
| Quick actions fan | `fanPillColor`, `fanCircleSize`, `fanItemGap`, `fanEdgeInset`, `fanLabelMaxLines`, `fanLabelPadding`, `fanLabelRadius`, `fanLabelGap`, `fanCloseIconSize`, `fanScrimOpacity`, `fanPageShrink`, `fanPageCornerRadius` |
| Action buttons and badges | `actionButtonPadding`, `actionButtonSpinnerSize`, `badgePadding` |
| Geometry | `geometry: NavIslandsGeometry(minChip:, maxChip:, chipGap:, islandPaddingX:, navHeight:, barPaddingX:, barPaddingY:, interIslandGap:, interIslandGapCompact:, compactWidthBreakpoint:, badgeSize:, badgeRingWidth:)` |
| Motion | `motion: NavIslandsMotion(island:, selection:, chipMorph:, press:, spinnerPeriod:, fanStagger:)` — all collapse to zero under "reduce motion" |

The chip size is worked out per layout, between `minChip` and `maxChip`, from
the width the bar has. Mount the theme above the pages as well as the bar:
`bottomNavOverlayHeight` and the fan read it there.

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/theme.gif" width="240" alt="Turning on Roomy bar and Square fan in the example's Settings">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/fan_open.png" width="240" alt="The default fan: round labels, wrapping">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/fan_square.png" width="240" alt="The square fan: square labels on one line, truncated">
</p>

The example's Settings page switches the theme live. **Roomy bar** sets a
`NavIslandsGeometry` with taller pills and bigger chips, and the bar grows on
the spot. **Square fan** sets five fan fields at once: `fanLabelRadius: 6`,
`fanCircleSize: 52`, `fanScrimOpacity: 0.6`, `fanPageShrink: 0` and
`fanLabelMaxLines: 1`. The two stills compare the default fan, where a long
label wraps, with the square one, where it is cut off with an ellipsis.

```dart
NavIslandsThemeData(
  geometry: const NavIslandsGeometry(maxChip: 56, navHeight: 66),
  motion: const NavIslandsMotion(island: Duration(milliseconds: 500)),
  fanLabelRadius: 8,
)
```

### A centre island that is a button

`NavIslandStyle.bare` draws no pill at all — no fill, border, shadow or
selection wash — so the item inside brings its own shape. Assert it for the
whole bar, or for the centre island alone with `centerStyle`, which is the
usual case: two ordinary side islands and a bigger primary button between them.

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/emergency.png" width="240" alt="The Emergency page: back, a big red SOS button, call">
</p>

The example's Emergency page: ordinary side islands on the screen edges and,
between them, an SOS button half as big again as the chips — a `span: 2`
`NavWidget` in a bare centre island.

A bare island's `NavWidget` gets the bar's whole height (`navHeight` plus the
breathing room above and below), not just a pill's, and `span` cells of width.
So a button can be bigger than the chips beside it and still take taps all
over:

```dart
controller.override(
  left: <NavItem>[/* … */],
  center: <NavItem>[
    NavWidget(label: 'Send an alert', span: 2, builder: (_) => const Center(child: SosButton())),
  ],
  right: <NavItem>[/* … */],
  centerStyle: NavIslandStyle.bare,
);
```

Such a button can open a [quick-actions fan](#quick-actions) of its own: wrap
it in a `NavAnchorReporter` and pass its id as the fan's `anchorId`. The
fan's close button then takes the button's place at the button's size.

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/sos.gif" width="240" alt="Tapping SOS: three red actions rise above it, and a big close button takes its place">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/sos_fan.png" width="240" alt="The SOS fan open: Send an alert, Share my location, Call 112">
</p>

In the example, SOS opens "Send an alert", "Share my location" and "Call 112".
The cross that replaces it is as big as the SOS button was, so nothing jumps
under your thumb.

### Quick actions

`ActionsFanHost` wraps a page with a speed-dial: it scales the page down on
black, scrims it, and fans labelled actions out of a chip in the bar. You own
the `AnimationController` and the open/closed state, and the page is expected
to assert an empty layout while the fan is open so the bar slides away beneath
it.

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/fan.gif" width="240" alt="The + fan opening; Mark one unread closes it and the Inbox badge counts up">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/fan_open.png" width="240" alt="The fan open over the scaled-down page">
</p>

The `+` chip opens the fan: the page shrinks back and dims, the actions rise
one after another, and the close button takes the `+` chip's place. Tapping
"Mark one unread" closes the fan, and the Inbox badge counts up. Its label is
too long for one line, so it wraps inside its pill rather than running off the
screen.

Give the chip an id (`NavLink.id`, or `NavAction.id`) and pass it as
`anchorId`: the fan opens from that chip wherever it sits — a centre island
included — and its close button takes the chip's exact spot, at the chip's
size (never smaller than a chip, so a big raised button is swapped for an
equally big close button). The labels run
towards the middle of the screen: to the left of a chip on the right half (or
in the centre), to the right of one on the left half. A label too long for the
room left wraps inside its pill, keeping `fanEdgeInset` from the screen edge,
and is ellipsised after `fanLabelMaxLines` lines (two by default).

```dart
ActionsFanHost(
  animation: _fan,
  open: _fanOpen,
  anchorId: 'more', // the NavAction(id: 'more', …) that opens it
  closeIcon: const NavIcon.material(Icons.close),
  closeLabel: 'Close',
  closeColor: accent,
  onClose: _closeFan,
  actions: [
    FanAction(icon: NavIcon.material(Icons.attach_file), color: accent, label: 'Attach'),
  ],
  child: page,
);
```

A `NavWidget` is not a chip, so to open a fan from one, wrap what it builds in
a `NavAnchorReporter` with the id:

```dart
NavWidget(
  label: 'Tools',
  span: 2,
  builder: (context) => NavAnchorReporter(
    id: 'tools',
    controller: NavIslandsScope.read(context),
    child: NavActionButton(label: 'Tools', color: accent, onTap: openFan),
  ),
)
```

Without an `anchorId`, or when no chip with that id is on screen,
`anchorChipOffset` counts chips from the bar's right edge instead.

### Wide chips and primary buttons

A `NavWidget` can claim more than one cell with `span`. That is the room a
`NavActionButton` needs: a page's verb as a filled pill, with a muted
`.secondary` companion. A null `onTap` disables it; `busy` swaps the label for a
spinner (the package's own `NavSpinner`, or your `busyIndicator`) and blocks
taps without dimming.

```dart
right: [
  NavWidget(
    label: 'Send',
    span: 2,
    builder: (_) => NavActionButton(label: 'Send', color: accent, busy: sending, onTap: send),
  ),
],
```

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/compose.gif" width="240" alt="Compose: tapping Send turns it into a spinner and disables Cancel"></p>

Compose has Cancel (`.secondary`, `span: 2`) and Send (`span: 2`) either side
of a round chip. Tapping Send sets `busy`: the label becomes a spinner and the
button ignores taps, while Cancel gets a null `onTap` and dims.

### Above the keyboard

A bar normally stays put when the keyboard opens, which hides it — right for
navigation, which has nothing to offer while you type. A form is different:
its cancel and save belong to what is being typed. Set `aboveKeyboard` on that
layout, and the bar rides on top of the keyboard, following it frame by frame
as it slides in and out:

```dart
NavIslands(
  aboveKeyboard: true,
  left: [/* Cancel */],
  right: [/* Save */],
)
```

<p>
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/keyboard.gif" width="240" alt="Compose: the keyboard opens and Cancel and Send ride up on top of it">
  <img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/keyboard_behind.png" width="240" alt="The Inbox search: the navigation bar stays behind the keyboard">
</p>

Left, Compose asks for it: Cancel, the three-dot chip and Send stay in reach
while you type. Right, the Inbox's search doesn't: its navigation bar stays
behind the keyboard, out of the way. `NavSingleActionBar` takes
`aboveKeyboard` too, for a lone "Done".

The setting is per layout, so it comes and goes with the page that asserts it.
A `Scaffold` already makes room for the keyboard, and the page's
`bottomNavOverlayHeight` padding still clears the bar on top of it. One thing
does need help: when a field gains focus, Flutter scrolls it just clear of the
keyboard — right where the bar now sits. Give the form's fields
`bottomNavScrollPadding(context)` as their `scrollPadding`, and they stop above
the bar instead:

```dart
TextField(
  scrollPadding: bottomNavScrollPadding(context),
  // …
)
```

### Pages with a single action

`NavSingleActionBar` is the layout of a page whose only affordance is one chip —
a back arrow on a page pushed sideways, a close button on one that slid up. Like
`NavOverrideScope` it renders nothing itself; mount it in the page's bottom
slot:

```dart
bottomNavigationBar: NavSingleActionBar(
  icon: const NavIcon.material(Icons.arrow_back),
  label: 'Back',
  onTap: () => Navigator.of(context).pop(),
),
```

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/item.png" width="240" alt="An item page with a single back chip on the left edge"></p>

The example's item pages: `slot: NavIslandSlot.left` with
`alignment: NavIslandAlignment.edge`, where the rest of the app keeps its back
arrow, so the arrow doesn't move between pages.

The chip sits in the centre island by default. `slot: NavIslandSlot.left` puts
it in the left one instead — where a back arrow usually goes — and
`alignment: NavIslandAlignment.edge` on the screen edge.

### Building blocks

<p><img src="https://raw.githubusercontent.com/gold-development/nav_islands/main/doc/building_blocks.png" width="240" alt="The Building blocks page: each piece on its own"></p>

The example's Building blocks page puts each of these on screen on its own: a
badge placed with `badgeCornerInset`, the spinner, a pressable, an island and
a chip outside the bar, and a fan opened from a `NavWidget`.

- **`bottomNavOverlayHeight(context)`** — how much of the page the floating bar
  covers, for a scrolling page's bottom padding.
- **`bottomNavScrollPadding(context)`** — a `TextField.scrollPadding` that
  stops a focused field above the bar, for forms whose bar rides
  [above the keyboard](#above-the-keyboard).
- **`NavPressable`** — the package's press feedback (a wash and a selection
  haptic) without a `Material` ancestor, for your own `NavWidget`s.
- **`NavBadge`** — the count badge on its own.
- **`computeNavMetrics(width, islands, geometry:)`** — the sizes the bar
  works out for a layout (`BottomNavMetrics`), should a custom item need to
  match them. `BottomNavTokens` holds the defaults.
- **`NavIsland`** / **`NavItemChip`** — an island, or a single chip, outside
  the bar, sized by those metrics.
- **`NavSpinner`** — the small spinner a busy `NavActionButton` shows.
- **`badgeCornerInset(chipSize, badgeSize:)`** — where a badge sits on a
  round chip, tangent to it, for your own badged item.
- **`NavAnchorReporter`** — registers a widget as a fan anchor (see
  [Quick actions](#quick-actions)).
- **`NavIslandSlot`** — left, centre or right, as `NavSingleActionBar.slot`
  takes it.
- **`kMaxNavItems`** — the most items the three islands may hold together.
- **`isRouteChainCurrent(context)`** — whether a page's route, and every route
  enclosing it, is the current one.

## A complete app

Every feature above in one file:
- a three-section shell with a count badge, a search toggle, a dark section
  and a filled "+" that fans quick actions out of itself, one with a label
  long enough to wrap;
- in that dark section, switches that change the theme live: a roomier bar
  (`NavIslandsGeometry`), slow motion (`NavIslandsMotion`) and a different fan;
- a compose page with wide primary buttons, a busy state, a custom glyph and a
  fan opening from a centre chip;
- a page whose centre island is a button bigger than the chips beside it;
- a page with a single back chip on the left edge;
- a page of building blocks used on their own, with a fan opening from a
  `NavWidget`;
- and a page with no bar at all.

It is `example/lib/main.dart`, so it is analysed on every change rather than
left to rot in a readme.

```dart
import 'package:flutter/material.dart';
import 'package:nav_islands/nav_islands.dart';

void main() => runApp(const ExampleApp());

/// Section ids, matched against the layout's `activeId` to light a link up.
const String kInboxId = 'inbox';
const String kBoardsId = 'boards';
const String kSettingsId = 'settings';

/// Ids of the chips a quick-actions fan opens from (`ActionsFanHost.anchorId`).
const String kNewChipId = 'new';
const String kMoreChipId = 'more';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // One controller for the whole app: the bar outlives any single page.
  final NavIslandsController _islands = NavIslandsController();

  // What the Settings section's switches change in the theme.
  Look _look = const Look();

  @override
  void dispose() {
    _islands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The scope sits above MaterialApp so every route the navigator builds can
    // assert a layout — not just the first one.
    return NavIslandsScope(
      controller: _islands,
      child: MaterialApp(
        title: 'nav_islands',
        theme: ThemeData(
          colorSchemeSeed: const Color(0xff4f46e5),
          useMaterial3: true,
        ),
        // Every navigation invalidates the layout so the leaving page's
        // islands hand over to the entering page's.
        navigatorObservers: <NavigatorObserver>[_ResetOnNavigate(_islands)],
        builder: (context, child) {
          final scheme = Theme.of(context).colorScheme;

          // Inside MaterialApp, so the palette can be derived from the app's
          // own theme. It wraps the pages too, not just the bar: the fan,
          // NavActionButton and bottomNavOverlayHeight read it as well.
          return NavIslandsTheme(
            data: NavIslandsThemeData(
              light: NavIslandStyleData(
                pillColor: scheme.surfaceContainerLowest,
                borderColor: scheme.outlineVariant,
                iconColor: scheme.onSurface,
                indicatorColor: scheme.primary.withValues(alpha: 0.14),
                badgeColor: scheme.error,
                badgeTextColor: scheme.onError,
              ),
              // The pills a dark page asserts (see the Settings section).
              dark: const NavIslandStyleData(
                pillColor: Color(0xff2c2c2e),
                borderColor: Color(0xff3a3a3c),
                iconColor: Color(0xffe5e5ea),
                indicatorColor: Color(0x33ffffff),
                badgeColor: Color(0xffff453a),
                badgeTextColor: Color(0xffffffff),
              ),
              // Beyond colours: the bar's geometry, its timing and the fan's
              // look, each switched on from the Settings section.
              geometry: _look.roomy
                  ? const NavIslandsGeometry(
                      minChip: 48,
                      maxChip: 56,
                      navHeight: 66,
                      chipGap: 6,
                      islandPaddingX: 5,
                      barPaddingY: 12,
                      badgeSize: 18,
                    )
                  : const NavIslandsGeometry(),
              motion: _look.slow
                  ? const NavIslandsMotion(
                      island: Duration(milliseconds: 1000),
                      selection: Duration(milliseconds: 800),
                      chipMorph: Duration(milliseconds: 800),
                      press: Duration(milliseconds: 300),
                      fanStagger: 0.15,
                    )
                  : const NavIslandsMotion(),
              fanLabelRadius: _look.squareFan ? 6 : 24,
              fanCircleSize: _look.squareFan ? 52 : 60,
              fanScrimOpacity: _look.squareFan ? 0.6 : 0.35,
              fanPageShrink: _look.squareFan ? 0 : 0.08,
              fanLabelMaxLines: _look.squareFan ? 1 : 2,
            ),
            child: Stack(
              children: <Widget>[
                child ?? const SizedBox.shrink(),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: BottomNavBar(),
                ),
              ],
            ),
          );
        },
        home: LookScope(
          look: _look,
          onChanged: (look) => setState(() => _look = look),
          child: const HomePage(),
        ),
      ),
    );
  }
}

/// The theme choices the Settings section toggles.
class Look {
  const Look({this.roomy = false, this.slow = false, this.squareFan = false});

  /// A taller bar with bigger chips: `NavIslandsGeometry`.
  final bool roomy;

  /// Everything three times slower: `NavIslandsMotion`.
  final bool slow;

  /// Square labels, smaller circles, a darker scrim and no page shrink.
  final bool squareFan;

  Look copyWith({bool? roomy, bool? slow, bool? squareFan}) => Look(
    roomy: roomy ?? this.roomy,
    slow: slow ?? this.slow,
    squareFan: squareFan ?? this.squareFan,
  );
}

/// Hands the [Look] and its setter down to the home page.
class LookScope extends InheritedWidget {
  const LookScope({
    required this.look,
    required this.onChanged,
    required super.child,
    super.key,
  });

  final Look look;
  final ValueChanged<Look> onChanged;

  static LookScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LookScope>()!;

  @override
  bool updateShouldNotify(LookScope oldWidget) => look != oldWidget.look;
}

/// Invalidates the bar on every navigation.
///
/// [NavIslandsController.softReset] keeps the leaving page's islands on screen
/// while the entering page asserts its own, so the bar transitions straight
/// from one layout to the next. If nothing asserted a layout by the end of the
/// frame — a page that wants no bar at all, like [AboutPage] — empty it.
class _ResetOnNavigate extends NavigatorObserver {
  _ResetOnNavigate(this.controller);

  final NavIslandsController controller;

  void _invalidate() {
    controller.softReset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.overridden) controller.reset();
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The first route has nothing to hand over from, and is pushed while the
    // app's first frame is still being built, when notifying is not allowed.
    if (previousRoute != null) _invalidate();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();
}

void _push(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

/// The shell: three sections as [NavLink]s in the centre island, a search
/// toggle on the left, and a filled "+" on the right that opens a
/// quick-actions fan out of itself.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String _section = kInboxId;
  bool _searching = false;
  int _unread = 3;

  // The fan's animation and open state are yours to own.
  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _fanOpen = false;

  @override
  void dispose() {
    _fan.dispose();
    super.dispose();
  }

  Future<void> _openFan() async {
    setState(() => _fanOpen = true);
    await _fan.forward();
  }

  Future<void> _closeFan() async {
    await _fan.reverse();
    if (mounted) setState(() => _fanOpen = false);
  }

  /// The settings section is dark, to show the pills morphing between styles.
  bool get _dark => _section == kSettingsId;

  /// The theme switches: the bar's geometry, its timing and the fan's look
  /// change live, all from `NavIslandsThemeData`.
  Widget _buildSettings(BuildContext context) {
    final scope = LookScope.of(context);
    final look = scope.look;
    const white = TextStyle(color: Colors.white);
    const grey = TextStyle(color: Color(0xffaeaeb2));

    return ListView(
      padding: EdgeInsets.only(bottom: bottomNavOverlayHeight(context)),
      children: <Widget>[
        SwitchListTile(
          title: const Text('Roomy bar', style: white),
          subtitle: const Text(
            'NavIslandsGeometry: taller pills, bigger chips',
            style: grey,
          ),
          value: look.roomy,
          onChanged: (v) => scope.onChanged(look.copyWith(roomy: v)),
        ),
        SwitchListTile(
          title: const Text('Slow motion', style: white),
          subtitle: const Text(
            'NavIslandsMotion: every movement slower',
            style: grey,
          ),
          value: look.slow,
          onChanged: (v) => scope.onChanged(look.copyWith(slow: v)),
        ),
        SwitchListTile(
          title: const Text('Square fan', style: white),
          subtitle: const Text(
            'Fan label radius, circle size, scrim, page shrink, one line',
            style: grey,
          ),
          value: look.squareFan,
          onChanged: (v) => scope.onChanged(look.copyWith(squareFan: v)),
        ),
      ],
    );
  }

  void _select(String section) => setState(() => _section = section);

  /// The layout this page wants. Rebuilt whenever the page's state changes, so
  /// the badge, the active link and the pill style all stay in step.
  NavIslands _buildIslands(BuildContext context) {
    // While the fan is open the page asserts an empty layout, so the bar
    // slides away underneath it.
    if (_fanOpen) return const NavIslands();

    final accent = Theme.of(context).colorScheme.primary;

    return NavIslands(
      activeId: _section,
      style: _dark ? NavIslandStyle.dark : NavIslandStyle.light,
      // Side islands hug the centre by default; these sit on the screen edges.
      leftAlignment: NavIslandAlignment.edge,
      rightAlignment: NavIslandAlignment.edge,
      left: <NavItem>[
        NavAction(
          icon: const NavIcon.material(Icons.search),
          label: 'Search',
          accent: accent,
          // Lights up while the search field is open.
          isActive: () => _searching,
          onTap: () => setState(() => _searching = !_searching),
        ),
      ],
      center: <NavItem>[
        NavLink(
          id: kInboxId,
          icon: const NavIcon.material(Icons.inbox_outlined),
          // The badge is decorative, so the count belongs in the label too.
          label: _unread == 0 ? 'Inbox' : 'Inbox, $_unread unread',
          badgeCount: _unread,
          accent: accent,
          onTap: () => _select(kInboxId),
        ),
        NavLink(
          id: kBoardsId,
          icon: const NavIcon.material(Icons.dashboard_outlined),
          label: 'Boards',
          accent: accent,
          onTap: () => _select(kBoardsId),
        ),
        NavLink(
          id: kSettingsId,
          icon: const NavIcon.material(Icons.settings_outlined),
          label: 'Settings',
          accent: accent,
          onTap: () => _select(kSettingsId),
        ),
      ],
      right: <NavItem>[
        NavAction(
          // The fan below opens from this chip, found by its id.
          id: kNewChipId,
          icon: const NavIcon.material(Icons.add),
          label: 'New',
          // A tint renders the chip as a filled call-to-action circle.
          tint: accent,
          onTap: _openFan,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final page = Scaffold(
      // The bar floats over the body, so let the body run underneath it.
      extendBody: true,
      backgroundColor: _dark ? const Color(0xff222222) : null,
      appBar: AppBar(
        title: Text(switch (_section) {
          kBoardsId => 'Boards',
          kSettingsId => 'Settings',
          _ => 'Inbox',
        }),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: <Widget>[
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  filled: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          if (_dark)
            Expanded(child: _buildSettings(context))
          else
            Expanded(
              child: ListView.builder(
                // Pad by the bar's height so the last row clears it.
                padding: EdgeInsets.only(
                  bottom: bottomNavOverlayHeight(context),
                ),
                itemCount: 20,
                itemBuilder: (context, index) => ListTile(
                  title: Text(
                    '$_section item $index',
                    style: TextStyle(color: _dark ? Colors.white : null),
                  ),
                  onTap: () =>
                      _push(context, ItemPage(title: '$_section item $index')),
                ),
              ),
            ),
        ],
      ),
      // Renders nothing itself — it just asserts the layout while this route
      // is current. Any slot in the page works.
      bottomNavigationBar: NavOverrideScope(
        islandsBuilder: _buildIslands,
        child: const SizedBox.shrink(),
      ),
    );

    // The speed-dial: scales the page down on black, scrims it, and fans the
    // actions out of the "+" chip — the close button takes the chip's spot.
    return ActionsFanHost(
      animation: _fan,
      open: _fanOpen,
      anchorId: kNewChipId,
      closeIcon: const NavIcon.material(Icons.close),
      closeLabel: 'Close',
      closeColor: accent,
      onClose: _closeFan,
      actions: <FanAction>[
        FanAction(
          icon: const NavIcon.material(Icons.mark_email_unread_outlined),
          color: accent,
          // Long on purpose: a label too wide for the screen wraps in its
          // pill (fanLabelMaxLines) instead of running off the edge.
          label: 'Mark one unread, so the Inbox badge counts up',
          onTap: () => setState(() => _unread++),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.edit_outlined),
          color: accent,
          label: 'Compose',
          onTap: () => _push(context, const ComposePage()),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.sos),
          color: const Color(0xffd32f2f),
          label: 'Emergency',
          onTap: () => _push(context, const EmergencyPage()),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.widgets_outlined),
          color: const Color(0xff00897b),
          label: 'Building blocks',
          onTap: () => _push(context, const BuildingBlocksPage()),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.info_outline),
          color: const Color(0xff607d8b),
          label: 'About (no bar)',
          onTap: () => _push(context, const AboutPage()),
        ),
      ],
      child: page,
    );
  }
}

/// A pushed page with one back chip, on the left screen edge where back
/// arrows go, which replaces the home page's three islands for as long as
/// this route is on top.
class ItemPage extends StatelessWidget {
  const ItemPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        // Back is in the bar.
        automaticallyImplyLeading: false,
        title: Text(title),
      ),
      body: Center(child: Text(title)),
      bottomNavigationBar: NavSingleActionBar(
        slot: NavIslandSlot.left,
        alignment: NavIslandAlignment.edge,
        icon: const NavIcon.material(Icons.arrow_back),
        label: 'Back',
        // The package knows nothing about your router — hand it whatever pops.
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}

/// Wide chips: a [NavWidget] claims more than one cell with `span`, here to
/// hold [NavActionButton]s — a secondary "Cancel" and a primary "Send" that
/// shows a spinner while it runs. The centre "More" chip opens a fan found by
/// its id, even though it sits in the middle of the bar, and draws a custom
/// glyph through [NavIcon.custom].
class ComposePage extends StatefulWidget {
  const ComposePage({super.key});

  @override
  State<ComposePage> createState() => _ComposePageState();
}

class _ComposePageState extends State<ComposePage>
    with SingleTickerProviderStateMixin {
  bool _sending = false;

  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _fanOpen = false;

  @override
  void dispose() {
    _fan.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openFan() async {
    setState(() => _fanOpen = true);
    await _fan.forward();
  }

  Future<void> _closeFan() async {
    await _fan.reverse();
    if (mounted) setState(() => _fanOpen = false);
  }

  NavIslands _buildIslands(BuildContext context) {
    if (_fanOpen) return const NavIslands();
    final accent = Theme.of(context).colorScheme.primary;

    return NavIslands(
      leftAlignment: NavIslandAlignment.edge,
      rightAlignment: NavIslandAlignment.edge,
      // Cancel and Send belong to what is being typed, so the bar rides on
      // top of the keyboard instead of disappearing behind it.
      aboveKeyboard: true,
      left: <NavItem>[
        NavWidget(
          label: 'Cancel',
          span: 2,
          builder: (_) => NavActionButton.secondary(
            label: 'Cancel',
            // Null would disable it: it dims to half opacity.
            onTap: _sending ? null : () => Navigator.of(context).pop(),
          ),
        ),
      ],
      center: <NavItem>[
        NavAction(
          id: kMoreChipId,
          // Any glyph you can paint: the bar hands over the colour and size.
          // `glyphKey` says when two icons are the same glyph, so a chip that
          // survives a page change morphs in place.
          icon: NavIcon.custom(
            glyphKey: 'three-dots',
            painter: (context, color, size) => CustomPaint(
              size: Size.square(size),
              painter: _DotsPainter(color),
            ),
          ),
          label: 'More',
          onTap: _openFan,
        ),
      ],
      right: <NavItem>[
        NavWidget(
          label: 'Send',
          span: 2,
          builder: (_) => NavActionButton(
            label: 'Send',
            color: accent,
            // Swaps the label for NavSpinner and blocks taps, without dimming.
            busy: _sending,
            onTap: _send,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return ActionsFanHost(
      animation: _fan,
      open: _fanOpen,
      // A centre chip: counting from the right edge could not find it.
      anchorId: kMoreChipId,
      closeIcon: const NavIcon.material(Icons.close),
      closeLabel: 'Close',
      closeColor: accent,
      onClose: _closeFan,
      actions: <FanAction>[
        FanAction(
          icon: const NavIcon.material(Icons.attach_file),
          color: accent,
          label: 'Attach a file',
        ),
        FanAction(
          icon: const NavIcon.material(Icons.schedule),
          color: accent,
          label: 'Send later',
        ),
      ],
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          // Back is in the bar.
          automaticallyImplyLeading: false,
          title: const Text('Compose'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            // Scrolled into view clear of the bar on the keyboard, not
            // just of the keyboard.
            scrollPadding: bottomNavScrollPadding(context),
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Write something',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        bottomNavigationBar: NavOverrideScope(
          islandsBuilder: _buildIslands,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A custom glyph: three dots, painted in whatever colour the bar asks for.
class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final radius = size.width * 0.09;
    for (final x in <double>[0.25, 0.5, 0.75]) {
      canvas.drawCircle(Offset(size.width * x, size.height / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}

/// A centre island that is a button of its own: `centerStyle:
/// NavIslandStyle.bare` draws no pill around it, so the raised button brings
/// its own shape and stands taller than the bar, between two ordinary side
/// islands. [NavPressable] gives it the package's press feedback without a
/// Material ancestor.
class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

const String kSosChipId = 'sos';

class _EmergencyPageState extends State<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _fanOpen = false;

  @override
  void dispose() {
    _fan.dispose();
    super.dispose();
  }

  Future<void> _openFan() async {
    setState(() => _fanOpen = true);
    await _fan.forward();
  }

  Future<void> _closeFan() async {
    await _fan.reverse();
    if (mounted) setState(() => _fanOpen = false);
  }

  /// Floating above the bar, which a plain snackbar would hide behind.
  void _confirm(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, bottomNavOverlayHeight(context)),
    ),
  );

  NavIslands _buildIslands(BuildContext context) {
    if (_fanOpen) return const NavIslands();
    final size = NavIslandsTheme.of(context).geometry.maxChip * 1.5;
    return NavIslands(
      centerStyle: NavIslandStyle.bare,
      // Back on the left edge, as on every other page.
      leftAlignment: NavIslandAlignment.edge,
      rightAlignment: NavIslandAlignment.edge,
      left: <NavItem>[
        NavAction(
          icon: const NavIcon.material(Icons.arrow_back),
          label: 'Back',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
      center: <NavItem>[
        NavWidget(
          label: 'Emergency options',
          // A bare island's widget gets the bar's whole height and, with two
          // cells, the width to match: the button can be half again as big as
          // the chips beside it and still take taps all over.
          span: 2,
          builder: (barContext) => Center(
            // Registered as the fan's anchor: the fan opens from the button,
            // and its close button takes the button's place at its size.
            child: NavAnchorReporter(
              id: kSosChipId,
              controller: NavIslandsScope.read(barContext),
              child: NavPressable(
                shape: BoxShape.circle,
                semanticLabel: 'Emergency options',
                onTap: _openFan,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Color(0xffd32f2f),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(blurRadius: 12, color: Color(0x55000000)),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'SOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      right: <NavItem>[
        NavAction(
          icon: const NavIcon.material(Icons.call_outlined),
          label: 'Call',
          onTap: () {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const red = Color(0xffd32f2f);
    return ActionsFanHost(
      animation: _fan,
      open: _fanOpen,
      anchorId: kSosChipId,
      closeIcon: const NavIcon.material(Icons.close),
      closeLabel: 'Close',
      closeColor: red,
      onClose: _closeFan,
      actions: <FanAction>[
        FanAction(
          icon: const NavIcon.material(Icons.campaign_outlined),
          color: red,
          label: 'Send an alert',
          onTap: () => _confirm('Alert sent'),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.my_location),
          color: red,
          label: 'Share my location',
          onTap: () => _confirm('Location shared'),
        ),
        FanAction(
          icon: const NavIcon.material(Icons.local_phone),
          color: red,
          label: 'Call 112',
          onTap: () => _confirm('Calling 112'),
        ),
      ],
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          // Back is in the bar.
          automaticallyImplyLeading: false,
          title: const Text('Emergency'),
        ),
        body: const Center(child: Text('The centre island is a button')),
        bottomNavigationBar: NavOverrideScope(
          islandsBuilder: _buildIslands,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// The parts the bar is made of, used on their own: a [NavBadge] placed with
/// [badgeCornerInset], a [NavSpinner], a [NavPressable], an island and a chip
/// outside the bar ([NavIsland], [NavItemChip]) sized by [computeNavMetrics],
/// and [isRouteChainCurrent]. Its bar holds a custom [NavWidget] that a fan
/// opens from, registered with [NavAnchorReporter].
class BuildingBlocksPage extends StatefulWidget {
  const BuildingBlocksPage({super.key});

  @override
  State<BuildingBlocksPage> createState() => _BuildingBlocksPageState();
}

const String kPartsChipId = 'parts';

class _BuildingBlocksPageState extends State<BuildingBlocksPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  bool _fanOpen = false;

  @override
  void dispose() {
    _fan.dispose();
    super.dispose();
  }

  Future<void> _openFan() async {
    setState(() => _fanOpen = true);
    await _fan.forward();
  }

  Future<void> _closeFan() async {
    await _fan.reverse();
    if (mounted) setState(() => _fanOpen = false);
  }

  NavIslands _buildIslands(BuildContext context) {
    if (_fanOpen) return const NavIslands();
    final accent = Theme.of(context).colorScheme.primary;

    return NavIslands(
      leftAlignment: NavIslandAlignment.edge,
      rightAlignment: NavIslandAlignment.edge,
      left: <NavItem>[
        NavAction(
          icon: const NavIcon.material(Icons.arrow_back),
          label: 'Back',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
      right: <NavItem>[
        NavWidget(
          label: 'Tools',
          span: 2,
          // A NavWidget is no chip, so it registers itself as a fan anchor.
          builder: (context) => NavAnchorReporter(
            id: kPartsChipId,
            controller: NavIslandsScope.read(context),
            child: NavActionButton(
              label: 'Tools',
              color: accent,
              onTap: _openFan,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final geometry = NavIslandsTheme.of(context).geometry;
    final width = MediaQuery.sizeOf(context).width;

    // The same sums the bar does, for a layout of three links.
    final links = <NavItem>[
      for (final (id, icon) in <(String, IconData)>[
        ('a', Icons.home_outlined),
        ('b', Icons.star_outline),
        ('c', Icons.person_outline),
      ])
        NavLink(
          id: id,
          icon: NavIcon.material(icon),
          label: id,
          accent: accent,
          onTap: () {},
        ),
    ];
    final metrics = computeNavMetrics(
      width,
      NavIslands(center: links),
      geometry: geometry,
    );
    final chip = metrics.chipSize;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );

    return ActionsFanHost(
      animation: _fan,
      open: _fanOpen,
      anchorId: kPartsChipId,
      // Only used when no chip with the anchorId is on screen: counts chips
      // from the bar's right edge instead.
      anchorChipOffset: 0,
      closeIcon: const NavIcon.material(Icons.close),
      closeLabel: 'Close',
      closeColor: accent,
      onClose: _closeFan,
      actions: <FanAction>[
        FanAction(
          icon: const NavIcon.material(Icons.build_outlined),
          color: accent,
          label: 'Opened from a NavWidget',
        ),
      ],
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          // Back is in the bar.
          automaticallyImplyLeading: false,
          title: const Text('Building blocks'),
        ),
        body: ListView(
          padding: EdgeInsets.only(bottom: bottomNavOverlayHeight(context)),
          children: <Widget>[
            section(
              'NavBadge, placed with badgeCornerInset',
              SizedBox.square(
                dimension: chip,
                child: Stack(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Positioned(
                      top: badgeCornerInset(
                        chip,
                        badgeSize: geometry.badgeSize,
                      ),
                      right: badgeCornerInset(
                        chip,
                        badgeSize: geometry.badgeSize,
                      ),
                      child: const NavBadge(count: 7),
                    ),
                  ],
                ),
              ),
            ),
            section('NavSpinner', NavSpinner(color: accent, size: 24)),
            section(
              'NavPressable: press feedback without Material',
              NavPressable(
                borderRadius: BorderRadius.circular(12),
                semanticLabel: 'Press me',
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Hold me'),
                ),
              ),
            ),
            section(
              'computeNavMetrics: three links on this ${width.round()} pt '
              'screen get ${chip.round()} pt chips',
              // An island outside the bar, sized the bar's way, its first
              // link lit.
              Center(
                child: NavIsland(items: links, metrics: metrics, activeId: 'a'),
              ),
            ),
            section(
              'NavItemChip: one chip on its own',
              NavItemChip(
                item: NavAction(
                  icon: const NavIcon.material(Icons.add),
                  label: 'Add',
                  tint: accent,
                  onTap: () {},
                ),
                metrics: metrics,
                covered: false,
                selected: false,
              ),
            ),
            section(
              'isRouteChainCurrent',
              Text(
                'This page is ${isRouteChainCurrent(context) ? '' : 'not '}'
                'the current route.',
              ),
            ),
          ],
        ),
        bottomNavigationBar: NavOverrideScope(
          islandsBuilder: _buildIslands,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A page that asserts no layout at all: the navigation reset finds nothing
/// asserted by the end of the frame and empties the bar, so the islands leave.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Center(child: Text('No bar on this page')),
    );
  }
}
```

## License

MIT
