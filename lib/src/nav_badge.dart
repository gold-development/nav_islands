import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_item.dart';

/// The little count on a nav chip — unread items behind that section.
///
/// It carries **no semantics of its own**: the chip is already labelled, and a
/// bare number read out beside it tells a screen-reader user nothing useful.
/// If the count matters to them, put it in the item's `label`.
///
/// The count is capped at [max] so a busy inbox never widens the chip past its
/// cell; beyond that it reads "99+".
///
/// Colours come from [NavIslandStyleData.badgeColor] and
/// [NavIslandStyleData.badgeTextColor], and the ring around it from the pill
/// it sits on, so the badge stays legible on a light or a dark island without
/// the caller passing anything.
class NavBadge extends StatelessWidget {
  /// Creates a badge.
  const NavBadge({
    required this.count,
    this.style = NavIslandStyle.light,
    super.key,
  });

  /// Largest number rendered as itself; above this the badge reads "99+".
  static const int max = 99;

  /// The default edge length of the circle at a count of one digit; the
  /// theme's `geometry.badgeSize` is the one in effect.
  static const double diameter = BottomNavTokens.badgeSize;

  /// The default ring width; the theme's `geometry.badgeRingWidth` is the one
  /// in effect.
  static const double ringWidth = BottomNavTokens.badgeRingWidth;

  /// How many there are. Zero renders nothing — callers need no conditional.
  final int count;

  /// The owning island's pill style, so the ring matches the pill.
  final NavIslandStyle style;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final theme = NavIslandsTheme.of(context);
    final palette = theme.styleFor(style);
    final size = theme.geometry.badgeSize;
    return ExcludeSemantics(
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: theme.badgePadding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.badgeColor,
          borderRadius: BorderRadius.all(Radius.circular(size / 2)),
          // The ring is the pill's own colour, so the badge reads as sitting
          // *on* the chip rather than floating over it.
          border: Border.all(
            color: palette.pillColor,
            width: theme.geometry.badgeRingWidth,
          ),
        ),
        child: Text(
          count > max ? '$max+' : '$count',
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: theme.badgeTextStyle.copyWith(color: palette.badgeTextColor),
        ),
      ),
    );
  }
}
