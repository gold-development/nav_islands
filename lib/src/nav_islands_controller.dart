import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_item.dart';

/// Holds the three bottom-nav islands (left / center / right). Every page
/// asserts its own layout via a [NavOverrideScope] while its route is current.
///
/// Navigation should call [softReset]: the bar keeps showing the leaving page's
/// islands while the entering page asserts its layout, so the state jumps
/// directly from one layout to the next — islands that empty animate out,
/// islands that keep their shape morph in place. Only when no page asserts a
/// layout (pages with their own in-scaffold bar) does a hard [reset] empty the
/// bar.
///
/// A plain [ChangeNotifier], so the package imposes no state-management
/// choice on its host: own one at app level and hand it to a
/// [NavIslandsScope].
class NavIslandsController extends ChangeNotifier {
  NavIslands _islands = const NavIslands.empty();
  bool _overridden = false;

  /// The islands currently on screen.
  NavIslands get islands => _islands;

  /// True while the current layout is a page override rather than the empty
  /// resting state (set by [override], cleared by [reset] / [softReset]).
  bool get overridden => _overridden;

  /// Empty the bar immediately, discarding the current page's islands (used
  /// when the bar should visibly leave, e.g. while a quick-actions sheet is
  /// open or when the current page brings its own in-scaffold bar).
  void reset() {
    _overridden = false;
    _islands = const NavIslands.empty();
    notifyListeners();
  }

  /// Mark the current layout stale without changing what's on screen: re-emits
  /// the same islands so every mounted [NavOverrideScope] gets notified and the
  /// scope whose route is (or becomes) current re-asserts its layout — letting
  /// the bar transition straight from the old page's islands to the new one's.
  /// The caller is responsible for falling back to [reset] if no page asserts
  /// a layout by the end of the frame.
  void softReset() {
    _overridden = false;
    _islands = _islands.copy();
    notifyListeners();
  }

  /// Set the islands for the current page, replacing the previous page's
  /// layout wholesale (unset islands become empty — nothing leaks through from
  /// the layout that was on screen before).
  void override({
    List<NavItem>? left,
    List<NavItem>? center,
    List<NavItem>? right,
    NavIslandAlignment? leftAlignment,
    NavIslandAlignment? rightAlignment,
    NavIslandStyle? style,
    NavIslandStyle? centerStyle,
    String? activeId,
  }) {
    final next = NavIslands(
      left: left ?? const <NavItem>[],
      center: center ?? const <NavItem>[],
      right: right ?? const <NavItem>[],
      leftAlignment: leftAlignment ?? NavIslandAlignment.center,
      rightAlignment: rightAlignment ?? NavIslandAlignment.center,
      style: style ?? NavIslandStyle.light,
      centerStyle: centerStyle,
      activeId: activeId,
    );
    assert(
      next.totalItems <= kMaxNavItems,
      'A bottom nav supports at most $kMaxNavItems items across all islands '
      '(got ${next.totalItems}).',
    );
    _overridden = true;
    _islands = next;
    notifyListeners();
  }
}

/// Provides the [NavIslandsController] to the bar and to every page that
/// asserts a layout. Mount it above both — typically around the app's whole
/// navigator.
class NavIslandsScope extends InheritedNotifier<NavIslandsController> {
  /// Creates the scope.
  const NavIslandsScope({
    required NavIslandsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The controller, subscribing the caller to layout changes.
  static NavIslandsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavIslandsScope>();
    assert(scope != null, 'No NavIslandsScope found in the widget tree');
    return scope!.notifier!;
  }

  /// The controller, without subscribing to layout changes — for callers that
  /// only push layouts (see [NavOverrideScope]).
  static NavIslandsController read(BuildContext context) {
    final scope =
        context
                .getElementForInheritedWidgetOfExactType<NavIslandsScope>()
                ?.widget
            as NavIslandsScope?;
    assert(scope != null, 'No NavIslandsScope found in the widget tree');
    return scope!.notifier!;
  }
}
