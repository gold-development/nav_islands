import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_item.dart';

/// Sizing tokens + the pure layout calculation for the island bottom nav. Kept
/// free of widgets so the math is unit-testable. The chip size is *computed*
/// from the available width rather than fixed.
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

  /// The bar's own height (pills + vertical breathing room), excluding the
  /// device's bottom safe-area inset. See [bottomNavOverlayHeight].
  static const double barHeight = navHeight + barPaddingY * 2;
}

/// Total vertical space the floating bar occupies over the content, including
/// the device's bottom safe-area inset. Since the bar overlays the body
/// (`Scaffold.extendBody`), scrollable pages should add this to their bottom
/// padding so their last items can scroll clear of the bar.
double bottomNavOverlayHeight(BuildContext context) =>
    BottomNavTokens.barHeight + MediaQuery.of(context).viewPadding.bottom;

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

  /// The rendered width of an item occupying [span] cells.
  double itemWidth(int span) => chipSize * span;
}

/// Computes chip size + gaps for [islands] given the bar's [availableWidth].
///
/// The chip size is the leftover width (after fixed overhead: bar padding,
/// inter-island gaps, island padding, and intra-island chip gaps) divided over
/// every cell (Σ span), clamped to [BottomNavTokens.minChip]..maxChip. On narrow
/// screens the inter-island gap tightens so the islands keep breathing room
/// before the chips have to shrink.
BottomNavMetrics computeNavMetrics(double availableWidth, NavIslands islands) {
  final interIslandGap = availableWidth < BottomNavTokens.compactWidthBreakpoint
      ? BottomNavTokens.interIslandGapCompact
      : BottomNavTokens.interIslandGap;

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
    intraGaps += BottomNavTokens.chipGap * (cells - 1);
  }

  final metrics = BottomNavMetrics(
    chipSize: BottomNavTokens.maxChip,
    chipGap: BottomNavTokens.chipGap,
    islandPaddingX: BottomNavTokens.islandPaddingX,
    interIslandGap: interIslandGap,
    navHeight: BottomNavTokens.navHeight,
  );

  if (totalCells == 0) return metrics;

  final overhead =
      BottomNavTokens.barPaddingX * 2 +
      interIslandGap * (nonEmpty.length - 1) +
      BottomNavTokens.islandPaddingX * 2 * nonEmpty.length +
      intraGaps;

  // A cell may not shrink below the touch target, so past a certain number of
  // cells the bar simply cannot hold the layout and the island overflows its
  // slot. Say so here, where the numbers are, rather than leaving a caller to
  // find an 84-pixel overflow stripe on the one phone size that shows it.
  assert(
    overhead + totalCells * BottomNavTokens.minChip <= availableWidth,
    'This layout needs '
    '${(overhead + totalCells * BottomNavTokens.minChip).round()} pt and the '
    'bar has ${availableWidth.round()}: $totalCells cells will not fit at the '
    '${BottomNavTokens.minChip.round()} pt minimum. Use fewer items, or a '
    'smaller span.',
  );

  final chip = ((availableWidth - overhead) / totalCells).clamp(
    BottomNavTokens.minChip,
    BottomNavTokens.maxChip,
  );

  return BottomNavMetrics(
    chipSize: chip,
    chipGap: BottomNavTokens.chipGap,
    islandPaddingX: BottomNavTokens.islandPaddingX,
    interIslandGap: interIslandGap,
    navHeight: BottomNavTokens.navHeight,
  );
}
