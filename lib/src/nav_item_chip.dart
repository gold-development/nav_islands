import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_icon.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_item.dart';
import 'package:nav_islands/src/nav_pressable.dart';

const Color _white = Color(0xffffffff);

/// Icon size as a fraction of the chip's edge length.
const double _iconFraction = 0.7;

/// Renders a single [NavItem] as an island chip, sized from [metrics] and its
/// [NavItem.span].
///
/// - A [NavLink] is a transparent icon; the selected background is drawn by
///   the island's moving indicator (a soft accent wash), and [covered] tells
///   the icon to tint in [coveredColor] while that indicator is over it.
/// - A [NavAction] with a `tint` renders as a filled coloured circle with a
///   white icon (a compact call-to-action, e.g. the "+").
/// - [selected] is the true selection, used only for semantics.
class NavItemChip extends StatelessWidget {
  /// Creates a chip.
  const NavItemChip({
    required this.item,
    required this.metrics,
    required this.covered,
    required this.selected,
    this.style = NavIslandStyle.light,
    this.coveredColor,
    super.key,
  });

  /// The item this chip renders.
  final NavItem item;

  /// Resolved sizes for this build of the bar.
  final BottomNavMetrics metrics;

  /// Whether the island's selection indicator currently sits over this chip.
  final bool covered;

  /// Whether this chip is the island's selected item.
  final bool selected;

  /// The owning island's pill style (dark pills need light default icons).
  final NavIslandStyle style;

  /// Icon colour while the selection indicator covers this chip (the item's
  /// full accent). Falls back to the default icon colour when null.
  final Color? coveredColor;

  @override
  Widget build(BuildContext context) {
    return switch (item) {
      final NavLink link => _Chip(
        metrics: metrics,
        span: link.span,
        icon: link.icon,
        label: link.label,
        covered: covered,
        coveredColor: coveredColor,
        style: style,
        selected: selected,
        onTap: link.onTap,
      ),
      final NavAction action => _Chip(
        metrics: metrics,
        span: action.span,
        icon: action.icon,
        label: action.label,
        covered: covered,
        coveredColor: coveredColor,
        style: style,
        selected: selected,
        fill: action.tint,
        onTap: action.onTap,
      ),
      final NavWidget widget => SizedBox(
        width: metrics.itemWidth(widget.span),
        height: metrics.chipSize,
        child: widget.builder(context),
      ),
    };
  }
}

/// A tappable chip. With [fill] it's a solid coloured circle + white icon;
/// without it, a transparent icon that takes the item's accent while [covered]
/// by the selection indicator and the style's default colour otherwise.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.metrics,
    required this.span,
    required this.icon,
    required this.label,
    required this.covered,
    required this.selected,
    required this.onTap,
    this.style = NavIslandStyle.light,
    this.coveredColor,
    this.fill,
  });

  final BottomNavMetrics metrics;
  final int span;
  final NavIcon icon;
  final String label;
  final bool covered;
  final NavIslandStyle style;
  final Color? coveredColor;
  final bool selected;
  final VoidCallback onTap;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final theme = NavIslandsTheme.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final morphDuration = reduceMotion
        ? Duration.zero
        : BottomNavTokens.chipMorphDuration;
    // Filled action chips keep their white glyph; a covered link tints in its
    // full accent over the indicator's soft wash.
    final defaultIconColor = theme.styleFor(style).iconColor;
    final iconColor = fill != null
        ? _white
        : covered
        ? (coveredColor ?? defaultIconColor)
        : defaultIconColor;
    final radius = BorderRadius.circular(metrics.chipSize / 2);
    final iconSize = metrics.chipSize * _iconFraction;

    return NavPressable(
      onTap: onTap,
      borderRadius: radius,
      semanticLabel: label,
      selected: selected,
      child: SizedBox(
        width: metrics.itemWidth(span),
        height: metrics.chipSize,
        // The fill animates (and a changed glyph cross-fades) so an in-place
        // item swap — same island shape, different item on the next page —
        // morphs instead of jumping.
        child: AnimatedContainer(
          duration: morphDuration,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: fill ?? const Color(0x00000000),
            borderRadius: radius,
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: morphDuration,
              child: KeyedSubtree(
                // Keyed by glyph + island style: covered flips stay instant,
                // while a light ↔ dark style change crossfades the glyph
                // colour along with the pill morph.
                key: ValueKey<String>('${icon.identity}:$style'),
                child: icon.build(context, iconColor, iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
