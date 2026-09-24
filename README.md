# nav_islands

A floating **island** bottom navigation bar for Flutter.

Instead of one fixed bar owning a list of destinations, the bar is three
independent pills — left, centre, right — and **each page asserts the layout it
wants** while its route is current. The bar lives above the navigator, so it
survives navigation and animates from one page's layout to the next: islands
that empty slide out, islands that keep their shape morph in place, and the
selection indicator stretches across to its destination and retracts.

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
  `bare` centre island is a button of its own — see
  [A centre island that is a button](#a-centre-island-that-is-a-button).
- **Any glyph**: `NavIcon.material` for icon fonts, `NavIcon.custom` to paint
  anything else — see [Custom glyphs](#custom-glyphs).
- **Wide primary buttons**: `NavActionButton` and `.secondary`, with a `busy`
  state and its own `NavSpinner` — see
  [Wide chips and primary buttons](#wide-chips-and-primary-buttons).
- **Quick actions**: `ActionsFanHost` fans labelled actions out of any chip,
  found by its id, with the labels running towards the middle of the screen —
  see [Quick actions](#quick-actions).
- **Single-action pages**: `NavSingleActionBar` for a back or close chip on its
  own — see [Pages with a single action](#pages-with-a-single-action).
- **Theming** through `NavIslandsTheme`, with defaults that stand on their own
  — see [Theming](#theming).
- **Accessibility**: every chip is labelled, badges stay out of the way of
  screen readers, and "reduce motion" collapses the animations.
- **No dependencies**, not even Material — see below.

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
black, scrims it, and fans labelled actions out of a chip in the bar. You own
the `AnimationController` and the open/closed state, and the page is expected
to assert an empty layout while the fan is open so the bar slides away beneath
it.

Give the chip an id (`NavLink.id`, or `NavAction.id`) and pass it as
`anchorId`: the fan opens from that chip wherever it sits — a centre island
included — and its close button takes the chip's exact spot. The labels run
towards the middle of the screen: to the left of a chip on the right half (or
in the centre), to the right of one on the left half.

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

### Building blocks

- **`bottomNavOverlayHeight(context)`** — how much of the page the floating bar
  covers, for a scrolling page's bottom padding.
- **`NavPressable`** — the package's press feedback (a wash and a selection
  haptic) without a `Material` ancestor, for your own `NavWidget`s.
- **`NavBadge`** — the count badge on its own.
- **`computeNavMetrics`** / **`BottomNavTokens`** — the sizing the bar uses,
  should a custom item need to match it.
- **`isRouteChainCurrent(context)`** — whether a page's route, and every route
  enclosing it, is the current one.

## A complete app

Every feature above in one file: a three-section shell with a count badge, a
search toggle, a dark section and a filled "+" that fans quick actions out of
itself; a compose page with wide primary buttons, a busy state, a custom glyph
and a fan opening from a centre chip; a page whose centre island is a raised
button; a page with a single back chip; and a page with no bar at all. It is
`example/lib/main.dart`, so it is analysed on every change rather than left to
rot in a readme.

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
          // own theme. It wraps the pages too, not just the bar: the fan and
          // NavActionButton read it as well.
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
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _invalidate();

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
          label: 'Mark one unread',
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

/// A pushed page with one centred back chip, which replaces the home page's
/// three islands for as long as this route is on top.
class ItemPage extends StatelessWidget {
  const ItemPage({required this.title, super.key});

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
        appBar: AppBar(title: const Text('Compose')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            maxLines: 8,
            decoration: InputDecoration(
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
class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  NavIslands _buildIslands(BuildContext context) {
    return NavIslands(
      centerStyle: NavIslandStyle.bare,
      left: <NavItem>[
        NavAction(
          icon: const NavIcon.material(Icons.arrow_back),
          label: 'Back',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
      center: <NavItem>[
        NavWidget(
          label: 'Send an alert',
          builder: (_) => NavPressable(
            shape: BoxShape.circle,
            semanticLabel: 'Send an alert',
            onTap: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Alert sent'))),
            child: Transform.translate(
              offset: const Offset(0, -12),
              child: Container(
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
                    fontWeight: FontWeight.w800,
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
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Emergency')),
      body: const Center(child: Text('The centre island is a button')),
      bottomNavigationBar: NavOverrideScope(
        islandsBuilder: _buildIslands,
        child: const SizedBox.shrink(),
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
