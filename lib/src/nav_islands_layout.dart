import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_item.dart';

/// The package's default sizes and durations, and what [NavIslandsGeometry]
/// and [NavIslandsMotion] start from.
///
/// The values in effect are the theme's: `NavIslandsTheme.of(context)` has
/// `geometry` and `motion`. Read these only for the defaults.
abstract final class BottomNavTokens {
  /// Smallest a chip may shrink to — at the 44px touch target.
  static const double minChip = 44;

  /// Largest a chip grows to on wide screens. Kept below [navHeight] so chips
  /// sit inset within the pill.
  static const double maxChip = 48;

  /// Gap between chips inside one island.
  static const double chipGap = 4;

  /// Horizontal padding inside an island pill.
  static const double islandPaddingX = 4;

  /// Height of the island pills.
  static const double navHeight = 56;

  /// Horizontal padding of the whole bar (screen edge → island cluster).
  static const double barPaddingX = 14;

  /// Vertical breathing room above/below the pills.
  static const double barPaddingY = 16;

  /// Gap between islands on regular-width screens.
  static const double interIslandGap = 16;

  /// Tighter inter-island gap used on small devices.
  static const double interIslandGapCompact = 8;

  /// Below this width the compact inter-island gap kicks in.
  static const double compactWidthBreakpoint = 360;

  /// Duration of an island's enter/leave slide + fade.
  static const Duration islandAnimDuration = Duration(milliseconds: 340);

  /// Duration of the selection indicator's stretch-and-retract move.
  static const Duration selectionAnimDuration = Duration(milliseconds: 240);

  /// Duration of an in-place chip morph (fill colour / glyph change when one
  /// page's item is replaced by the next page's in the same island slot).
  static const Duration chipMorphDuration = Duration(milliseconds: 240);

  /// Edge length of a count badge at one digit.
  static const double badgeSize = 16;

  /// Width of the ring separating a badge from the glyph behind it.
  static const double badgeRingWidth = 1.5;

  /// The default bar's own height (pills + vertical breathing room),
  /// excluding the device's bottom safe-area inset. See
  /// [bottomNavOverlayHeight], which uses the theme's.
  static const double barHeight = navHeight + barPaddingY * 2;
}

/// The bar's geometry: how big the chips and pills are and how far apart,
/// part of [NavIslandsThemeData]. The chip size within [minChip]..[maxChip] is
/// worked out per layout from the width available (see [computeNavMetrics]).
@immutable
class NavIslandsGeometry {
  /// Creates a geometry; the defaults are [BottomNavTokens]'.
  const NavIslandsGeometry({
    this.minChip = BottomNavTokens.minChip,
    this.maxChip = BottomNavTokens.maxChip,
    this.chipGap = BottomNavTokens.chipGap,
    this.islandPaddingX = BottomNavTokens.islandPaddingX,
    this.navHeight = BottomNavTokens.navHeight,
    this.barPaddingX = BottomNavTokens.barPaddingX,
    this.barPaddingY = BottomNavTokens.barPaddingY,
    this.interIslandGap = BottomNavTokens.interIslandGap,
    this.interIslandGapCompact = BottomNavTokens.interIslandGapCompact,
    this.compactWidthBreakpoint = BottomNavTokens.compactWidthBreakpoint,
    this.badgeSize = BottomNavTokens.badgeSize,
    this.badgeRingWidth = BottomNavTokens.badgeRingWidth,
  }) : assert(minChip > 0, 'minChip must be positive'),
       assert(minChip <= maxChip, 'minChip may not exceed maxChip'),
       assert(maxChip <= navHeight, 'a chip must fit in the pill');

  /// Smallest a chip may shrink to. Keep it at a touch target (44–48).
  final double minChip;

  /// Largest a chip grows to on wide screens; at most [navHeight], so the
  /// chips sit inside the pill. Also the fan's close button size.
  final double maxChip;

  /// Gap between chips inside one island.
  final double chipGap;

  /// Horizontal padding inside an island pill.
  final double islandPaddingX;

  /// Height of the island pills.
  final double navHeight;

  /// Horizontal padding of the whole bar (screen edge → islands).
  final double barPaddingX;

  /// Vertical breathing room above and below the pills.
  final double barPaddingY;

  /// Gap between islands.
  final double interIslandGap;

  /// The gap between islands on a screen narrower than
  /// [compactWidthBreakpoint].
  final double interIslandGapCompact;

  /// Below this bar width the compact gap between islands applies.
  final double compactWidthBreakpoint;

  /// Edge length of a count badge at one digit; it widens for more.
  final double badgeSize;

  /// Width of the ring separating a badge from the glyph behind it.
  final double badgeRingWidth;

  /// The bar's own height (pills plus breathing room), without the device's
  /// bottom safe-area inset. See [bottomNavOverlayHeight].
  double get barHeight => navHeight + barPaddingY * 2;

  /// A copy with the given fields replaced.
  NavIslandsGeometry copyWith({
    double? minChip,
    double? maxChip,
    double? chipGap,
    double? islandPaddingX,
    double? navHeight,
    double? barPaddingX,
    double? barPaddingY,
    double? interIslandGap,
    double? interIslandGapCompact,
    double? compactWidthBreakpoint,
    double? badgeSize,
    double? badgeRingWidth,
  }) => NavIslandsGeometry(
    minChip: minChip ?? this.minChip,
    maxChip: maxChip ?? this.maxChip,
    chipGap: chipGap ?? this.chipGap,
    islandPaddingX: islandPaddingX ?? this.islandPaddingX,
    navHeight: navHeight ?? this.navHeight,
    barPaddingX: barPaddingX ?? this.barPaddingX,
    barPaddingY: barPaddingY ?? this.barPaddingY,
    interIslandGap: interIslandGap ?? this.interIslandGap,
    interIslandGapCompact: interIslandGapCompact ?? this.interIslandGapCompact,
    compactWidthBreakpoint:
        compactWidthBreakpoint ?? this.compactWidthBreakpoint,
    badgeSize: badgeSize ?? this.badgeSize,
    badgeRingWidth: badgeRingWidth ?? this.badgeRingWidth,
  );

  @override
  bool operator ==(Object other) =>
      other is NavIslandsGeometry &&
      other.minChip == minChip &&
      other.maxChip == maxChip &&
      other.chipGap == chipGap &&
      other.islandPaddingX == islandPaddingX &&
      other.navHeight == navHeight &&
      other.barPaddingX == barPaddingX &&
      other.barPaddingY == barPaddingY &&
      other.interIslandGap == interIslandGap &&
      other.interIslandGapCompact == interIslandGapCompact &&
      other.compactWidthBreakpoint == compactWidthBreakpoint &&
      other.badgeSize == badgeSize &&
      other.badgeRingWidth == badgeRingWidth;

  @override
  int get hashCode => Object.hash(
    minChip,
    maxChip,
    chipGap,
    islandPaddingX,
    navHeight,
    barPaddingX,
    barPaddingY,
    interIslandGap,
    interIslandGapCompact,
    compactWidthBreakpoint,
    badgeSize,
    badgeRingWidth,
  );
}

/// Total vertical space the floating bar occupies over the content, including
/// the device's bottom safe-area inset. Since the bar overlays the body
/// (`Scaffold.extendBody`), scrollable pages should add this to their bottom
/// padding so their last items can scroll clear of the bar.
///
/// Uses the nearest [NavIslandsTheme]'s geometry, so mount the theme above the
/// pages as well as the bar.
double bottomNavOverlayHeight(BuildContext context) =>
    NavIslandsTheme.of(context).geometry.barHeight +
    MediaQuery.of(context).viewPadding.bottom;

/// A `TextField.scrollPadding` that keeps the field being typed in clear of
/// the bar: Flutter's default 20 on every side, plus [bottomNavOverlayHeight]
/// below.
///
/// When a field gains focus, Flutter scrolls it just clear of the keyboard —
/// which is where a bar asked to ride [NavIslands.aboveKeyboard] sits, so
/// without this the field ends up under the bar. The page's scrollable needs
/// that much bottom padding too, for the field to have room to scroll up.
EdgeInsets bottomNavScrollPadding(BuildContext context) =>
    EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomNavOverlayHeight(context));

/// The resolved sizes for one build of the bar, produced by [computeNavMetrics].
@immutable
class BottomNavMetrics {
  /// Creates a resolved set of sizes.
  const BottomNavMetrics({
    required this.chipSize,
    required this.chipGap,
    required this.islandPaddingX,
    required this.interIslandGap,
    required this.navHeight,
    this.barPaddingY = BottomNavTokens.barPaddingY,
  });

  /// Edge length of a single (span == 1) chip. A span-N item is `chipSize * N`
  /// wide (see [itemWidth]).
  final double chipSize;

  /// Gap between chips inside one island.
  final double chipGap;

  /// Horizontal padding inside an island pill.
  final double islandPaddingX;

  /// Gap between islands.
  final double interIslandGap;

  /// Height of the island pills.
  final double navHeight;

  /// Breathing room above and below the pills.
  final double barPaddingY;

  /// The bar's own height: the pills plus their breathing room. A bare
  /// island's widget gets all of it.
  double get barHeight => navHeight + barPaddingY * 2;

  /// The rendered width of an item occupying [span] cells.
  double itemWidth(int span) => chipSize * span;
}

/// Computes chip size + gaps for [islands] given the bar's [availableWidth]
/// and [geometry] (the theme's, in the bar).
///
/// The chip size is the leftover width (after fixed overhead: bar padding,
/// inter-island gaps, island padding, and intra-island chip gaps) divided over
/// every cell (Σ span), clamped to [NavIslandsGeometry.minChip]..maxChip. On
/// narrow screens the inter-island gap tightens so the islands keep breathing
/// room before the chips have to shrink.
BottomNavMetrics computeNavMetrics(
  double availableWidth,
  NavIslands islands, {
  NavIslandsGeometry geometry = const NavIslandsGeometry(),
}) {
  final g = geometry;
  final interIslandGap = availableWidth < g.compactWidthBreakpoint
      ? g.interIslandGapCompact
      : g.interIslandGap;

  final nonEmpty = <List<NavItem>>[
    if (islands.left.isNotEmpty) islands.left,
    if (islands.center.isNotEmpty) islands.center,
    if (islands.right.isNotEmpty) islands.right,
  ];

  var totalCells = 0;
  var intraGaps = 0.0;
  for (final island in nonEmpty) {
    var cells = 0;
    for (final item in island) {
      cells += item.span;
    }
    totalCells += cells;
    // One gap per cell boundary, not per *item* boundary. A span-n chip is
    // drawn as one pill covering n cells and the n-1 gaps between them —
    // `itemWidth` adds them to its width — so counting only the gaps between
    // items left a span's own gaps out of the budget, and the chip size came
    // back too large by exactly that much. With a span of 5 that is 16 pt of
    // overflow, which is how it was found.
    intraGaps += g.chipGap * (cells - 1);
  }

  final metrics = BottomNavMetrics(
    chipSize: g.maxChip,
    chipGap: g.chipGap,
    islandPaddingX: g.islandPaddingX,
    interIslandGap: interIslandGap,
    navHeight: g.navHeight,
    barPaddingY: g.barPaddingY,
  );

  if (totalCells == 0) return metrics;

  final overhead =
      g.barPaddingX * 2 +
      interIslandGap * (nonEmpty.length - 1) +
      g.islandPaddingX * 2 * nonEmpty.length +
      intraGaps;

  // A cell may not shrink below the touch target, so past a certain number of
  // cells the bar simply cannot hold the layout and the island overflows its
  // slot. Say so here, where the numbers are, rather than leaving a caller to
  // find an 84-pixel overflow stripe on the one phone size that shows it.
  //
  // A zero width is no such layout: it is the first frame on some platforms,
  // before the window has a size, and the next frame lays the bar out again.
  assert(
    availableWidth <= 0 || overhead + totalCells * g.minChip <= availableWidth,
    'This layout needs '
    '${(overhead + totalCells * g.minChip).round()} pt and the '
    'bar has ${availableWidth.round()}: $totalCells cells will not fit at the '
    '${g.minChip.round()} pt minimum. Use fewer items, or a '
    'smaller span.',
  );

  final chip = ((availableWidth - overhead) / totalCells).clamp(
    g.minChip,
    g.maxChip,
  );

  return BottomNavMetrics(
    chipSize: chip,
    chipGap: g.chipGap,
    islandPaddingX: g.islandPaddingX,
    interIslandGap: interIslandGap,
    navHeight: g.navHeight,
    barPaddingY: g.barPaddingY,
  );
}
