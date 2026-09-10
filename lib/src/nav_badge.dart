import 'package:flutter/widgets.dart';
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

  /// Edge length of the circle at a count of one digit.
  static const double diameter = 16;

  /// Width of the ring separating the badge from the glyph behind it.
  static const double ringWidth = 1.5;

  /// How many there are. Zero renders nothing — callers need no conditional.
  final int count;

  /// The owning island's pill style, so the ring matches the pill.
  final NavIslandStyle style;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }
    final palette = NavIslandsTheme.of(context).styleFor(style);
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: diameter,
          minHeight: diameter,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.badgeColor,
          borderRadius: const BorderRadius.all(Radius.circular(diameter / 2)),
          // The ring is the pill's own colour, so the badge reads as sitting
          // *on* the chip rather than floating over it.
          border: Border.all(color: palette.pillColor, width: ringWidth),
        ),
        child: Text(
          count > max ? '$max+' : '$count',
          textAlign: TextAlign.center,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: palette.badgeTextColor,
            fontWeight: FontWeight.w700,
            height: 1,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
