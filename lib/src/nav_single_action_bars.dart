import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_icon.dart';
import 'package:nav_islands/src/nav_islands_bar.dart';
import 'package:nav_islands/src/nav_item.dart';
import 'package:nav_islands/src/nav_override_scope.dart';

/// Island layout for a page whose only nav affordance is a single action — a
/// back arrow on a sideways page, a close button on one that slid up from the
/// bottom — in the island [slot] says: the centre by default, or the left one
/// for a back arrow where the rest of the app keeps it.
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
    this.slot = NavIslandSlot.center,
    this.alignment = NavIslandAlignment.center,
    this.style = NavIslandStyle.light,
    this.aboveKeyboard = false,
    super.key,
  });

  /// The glyph of the single chip.
  final NavIcon icon;

  /// Accessibility label of the chip.
  final String label;

  /// Runs when the chip is tapped.
  final VoidCallback onTap;

  /// Which island holds the chip.
  final NavIslandSlot slot;

  /// How the side islands align: [NavIslandAlignment.edge] puts a chip in a
  /// side [slot] on the screen edge. With a centred chip it only matters to
  /// match edge-aligned pages, so the transition between them stays still.
  final NavIslandAlignment alignment;

  /// Pill styling for the page this sits on.
  final NavIslandStyle style;

  /// Whether the chip rises above the keyboard — see
  /// [NavIslands.aboveKeyboard]. Off for a back arrow; on for a "Done" that
  /// finishes what is being typed.
  final bool aboveKeyboard;

  @override
  Widget build(BuildContext context) {
    return NavOverrideScope(
      islandsBuilder: (context) {
        final items = <NavItem>[
          NavAction(icon: icon, label: label, onTap: onTap),
        ];
        return NavIslands(
          leftAlignment: alignment,
          rightAlignment: alignment,
          style: style,
          aboveKeyboard: aboveKeyboard,
          left: slot == NavIslandSlot.left ? items : const <NavItem>[],
          center: slot == NavIslandSlot.center ? items : const <NavItem>[],
          right: slot == NavIslandSlot.right ? items : const <NavItem>[],
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
