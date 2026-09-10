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
