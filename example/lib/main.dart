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
