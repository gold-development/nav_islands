# nav_islands

A floating **island** bottom navigation bar for Flutter.

Instead of one fixed bar owning a list of destinations, the bar is three
independent pills — left, centre, right — and **each page asserts the layout it
wants** while its route is current. The bar lives above the navigator, so it
survives navigation and animates from one page's layout to the next: islands
that empty slide out, islands that keep their shape morph in place, and the
selection indicator stretches across to its destination and retracts.

## No dependencies

Flutter and nothing else — not even Material:

| Concern | How |
| --- | --- |
| State | `NavIslandsController`, a plain `ChangeNotifier` |
| Navigation | Callbacks you supply — bring any router, or none |
| Glyphs | `NavIcon.custom`, painted by you (svg, bitmap, icon font, …) |
| Colours | `NavIslandsThemeData`, with usable defaults |
| Press feedback | Drawn by the package, so no `Material` ancestor is needed |

## Usage

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

### Items

- **`NavLink`** — a destination. Active when its `id` matches the layout's
  `activeId`.
- **`NavAction`** — runs a callback; active while its `isActive` says so. Give
  it a `tint` to render as a filled call-to-action circle.
- **`NavWidget`** — anything you like in a chip's place (a badge, a counter, a
  wide button — see `NavActionButton`).

Each item declares a `span` of 1–3 cells, so wide items can claim more room.
A layout may hold at most 8 items across all three islands.

### Custom glyphs

`NavIcon.material` covers icon fonts. For anything else, paint it yourself —
the bar hands you the colour and size it wants, and `glyphKey` tells it when
two icons are the same glyph, so a chip surviving a page change morphs in place
rather than sliding out and back in:

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
the bar in a `NavIslandsTheme`. Each `NavIslandStyle` — `light` and `dark`,
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

### Quick actions

`ActionsFanHost` wraps a page with a speed-dial: it scales the page down on
black, scrims it, and fans labelled actions out of the bar's anchor chip. You
own the `AnimationController` and the open/closed state, and the page is
expected to assert an empty layout while the fan is open so the bar slides away
beneath it.

## License

MIT
