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
