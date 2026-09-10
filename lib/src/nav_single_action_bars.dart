import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_icon.dart';
import 'package:nav_islands/src/nav_item.dart';
import 'package:nav_islands/src/nav_override_scope.dart';

/// Island layout for a page whose only nav affordance is a single centred
/// action — a back arrow on a sideways page, a close button on one that slid
/// up from the bottom.
///
/// Renders nothing itself: the bar lives at app level, so mount this anywhere
/// in the page (a `Scaffold`'s bottom slot is a natural home) and pad
/// scrollable content with `bottomNavOverlayHeight`.
///
/// The icon and label are yours to supply, and so is [onTap] — this package
/// knows nothing about your router, so pass whatever pops the route
/// (`Navigator.of(context).pop`, `context.pop` with go_router, …).
class NavSingleActionBar extends StatelessWidget {
  /// Creates a single-action island.
  const NavSingleActionBar({
    required this.icon,
    required this.label,
    required this.onTap,
    this.alignment = NavIslandAlignment.center,
    this.style = NavIslandStyle.light,
    super.key,
  });

  /// The glyph of the single chip.
  final NavIcon icon;

  /// Accessibility label of the chip.
  final String label;

  /// Runs when the chip is tapped.
  final VoidCallback onTap;

  /// How the (empty) left island aligns — kept for layouts that mix this with
  /// edge-aligned pages so the transition between them stays still.
  final NavIslandAlignment alignment;

  /// Pill styling for the page this sits on.
  final NavIslandStyle style;

  @override
  Widget build(BuildContext context) {
    return NavOverrideScope(
      islandsBuilder: (context) => NavIslands(
        leftAlignment: alignment,
        style: style,
        center: <NavItem>[NavAction(icon: icon, label: label, onTap: onTap)],
      ),
      child: const SizedBox.shrink(),
    );
  }
}
