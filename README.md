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

### Items

- **`NavLink`** — a destination. Active when its `id` matches the layout's
  `activeId`.
- **`NavAction`** — runs a callback; active while its `isActive` says so. Give
  it a `tint` to render as a filled call-to-action circle.
- **`NavWidget`** — anything you like in a chip's place (a badge, a counter, a
  wide button — see `NavActionButton`).

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

### A centre island that is a button

`NavIslandStyle.bare` draws no pill at all — no fill, border, shadow or
selection wash — and clips nothing, so the item inside brings its own shape and
may stand taller than the bar. Assert it for the whole bar, or for the centre
island alone with `centerStyle`, which is the usual case: two ordinary side
islands and a raised primary button between them.

```dart
controller.override(
  left: <NavItem>[/* … */],
  center: <NavItem>[NavWidget(label: 'Emergency', builder: (_) => const SosButton())],
  right: <NavItem>[/* … */],
  centerStyle: NavIslandStyle.bare,
);
```

### Quick actions

`ActionsFanHost` wraps a page with a speed-dial: it scales the page down on
black, scrims it, and fans labelled actions out of the bar's anchor chip. You
own the `AnimationController` and the open/closed state, and the page is
expected to assert an empty layout while the fan is open so the bar slides away
beneath it.

## A complete app

Everything above in one file — a three-section shell with a count badge, a
search toggle, a filled call-to-action, a dark section, and a pushed page that
asserts its own back chip. It is `example/lib/main.dart`, so it is analysed on
every change rather than left to rot in a readme.

```dart
import 'package:flutter/material.dart';
import 'package:nav_islands/nav_islands.dart';

void main() => runApp(const ExampleApp());

/// Section ids, matched against the layout's `activeId` to light a link up.
const String kInboxId = 'inbox';
const String kBoardsId = 'boards';
const String kSettingsId = 'settings';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  // One controller for the whole app: the bar outlives any single page.
  final NavIslandsController _islands = NavIslandsController();

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
          // own theme. It wraps the pages too, not just the bar.
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
        home: const HomePage(),
      ),
    );
  }
}

/// Invalidates the bar on every navigation.
///
/// [NavIslandsController.softReset] keeps the leaving page's islands on screen
/// while the entering page asserts its own, so the bar transitions straight
/// from one layout to the next. If nothing asserted a layout by the end of the
/// frame — a page that wants no bar at all — empty it.
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
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _section = kInboxId;
  bool _searching = false;
  int _unread = 3;

  /// The settings section is dark, to show the pills morphing between styles.
  bool get _dark => _section == kSettingsId;

  void _select(String section) => setState(() => _section = section);

  /// The layout this page wants. Rebuilt whenever the page's state changes, so
  /// the badge, the active link and the pill style all stay in step.
  NavIslands _buildIslands(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return NavIslands(
      activeId: _section,
      style: _dark ? NavIslandStyle.dark : NavIslandStyle.light,
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
          icon: const NavIcon.material(Icons.add),
          label: 'New item',
          // A tint renders the chip as a filled call-to-action circle.
          tint: accent,
          onTap: () => setState(() => _unread++),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
          Expanded(
            child: ListView.builder(
              // Pad by the bar's height so the last row clears it.
              padding: EdgeInsets.only(bottom: bottomNavOverlayHeight(context)),
              itemCount: 20,
              itemBuilder: (context, index) => ListTile(
                title: Text(
                  '$_section item $index',
                  style: TextStyle(color: _dark ? Colors.white : null),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DetailPage(title: '$_section item $index'),
                  ),
                ),
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
  }
}

/// A pushed page, asserting a layout of its own: one centred back chip, which
/// replaces the home page's three islands for as long as this route is on top.
class DetailPage extends StatelessWidget {
  const DetailPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
      bottomNavigationBar: NavSingleActionBar(
        icon: const NavIcon.material(Icons.arrow_back),
        label: 'Back',
        // The package knows nothing about your router — hand it whatever pops.
        onTap: () => Navigator.of(context).pop(),
      ),
    );
  }
}
```

## License

MIT
