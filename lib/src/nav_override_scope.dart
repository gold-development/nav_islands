import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_controller.dart';
import 'package:nav_islands/src/nav_item.dart';

/// Asserts a page's island layout while that page's route is current: applied
/// one frame after mounting (so the bar transitions from the previous page's
/// layout to this one's), re-applied whenever a navigation reset (or hot
/// reload) invalidates the bar, and rebuilt when inherited dependencies used by
/// [islandsBuilder] change (translations, theme). Once the route stops being
/// current (pop or a new push) re-assertion stops, so the next page's layout
/// can take over.
///
/// Renders nothing of its own — mount it anywhere in the page (a `Scaffold`'s
/// bottom slot is a natural home) and pad scrollable content with
/// `bottomNavOverlayHeight`.
class NavOverrideScope extends StatefulWidget {
  /// Creates the scope.
  const NavOverrideScope({
    required this.islandsBuilder,
    required this.child,
    super.key,
  });

  /// Builds the island layout each time it is (re-)applied.
  final NavIslands Function(BuildContext context) islandsBuilder;

  /// The subtree this scope wraps.
  final Widget child;

  @override
  State<NavOverrideScope> createState() => _NavOverrideScopeState();
}

class _NavOverrideScopeState extends State<NavOverrideScope> {
  NavIslandsController? _controller;
  bool _dependenciesAttached = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(force: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = NavIslandsScope.read(context);
    if (!identical(controller, _controller)) {
      _controller?.removeListener(_onControllerChanged);
      _controller = controller..addListener(_onControllerChanged);
    }

    // The first call accompanies initState, which already scheduled an apply.
    // Later calls mean something the layout depends on changed (translations
    // arriving, theme switch) — re-apply so labels/colors refresh.
    if (!_dependenciesAttached) {
      _dependenciesAttached = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(force: true));
  }

  @override
  void didUpdateWidget(NavOverrideScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The owning page rebuilt (e.g. its section selection changed) — re-apply
    // so the layout reflects the page's new state.
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply(force: true));
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// A reset invalidated the bar (navigation, hot reload). Re-assert the
  /// layout next frame if this page is still the active route; if it isn't
  /// (we're being popped or covered), let the next page take over.
  void _onControllerChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  /// Applies the layout when this page is the active route. Without [force]
  /// the apply is skipped while an override is already active — that filters
  /// out the echoes of our own notification.
  void _apply({bool force = false}) {
    if (!mounted) {
      return;
    }
    final controller = _controller;
    if (controller == null || (!force && controller.overridden)) {
      return;
    }
    if (!isRouteChainCurrent(context)) {
      return;
    }
    final islands = widget.islandsBuilder(context);
    controller.override(
      left: islands.left,
      center: islands.center,
      right: islands.right,
      leftAlignment: islands.leftAlignment,
      rightAlignment: islands.rightAlignment,
      style: islands.style,
      activeId: islands.activeId,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// True when the route enclosing [context] is current in its navigator *and*
/// every enclosing route up to the root navigator is current too.
///
/// A page inside a nested navigator (a shell route, a tab view) stays the top
/// route of *its* navigator while the shell itself is being replaced — logging
/// out, say. Checking only the innermost route made the leaving page re-assert
/// its islands over the screen that replaced it.
bool isRouteChainCurrent(BuildContext context) {
  BuildContext? current = context;
  while (current != null) {
    final route = ModalRoute.of(current);
    if (route == null) {
      return true;
    }
    if (!route.isCurrent) {
      return false;
    }
    final navigator = route.navigator;
    if (navigator == null || !navigator.mounted) {
      return true;
    }
    current = navigator.context;
  }
  return true;
}
