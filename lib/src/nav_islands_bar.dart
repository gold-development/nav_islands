import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_island.dart';
import 'package:nav_islands/src/nav_islands_controller.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
import 'package:nav_islands/src/nav_item.dart';

/// The three positions an island can occupy in the bar.
enum NavIslandSlot {
  /// The left island.
  left,

  /// The centre island, which stays screen-centred.
  center,

  /// The right island.
  right,
}

/// The island bottom bar. Reads the three islands (and the active section id)
/// from the nearest [NavIslandsScope] and lays them out left / center / right,
/// keeping the center island screen-centered no matter what the sides contain:
/// the side slots are [Expanded] and hug the center, so the center stays put
/// even when a side island appears or leaves.
///
/// Each island enters/leaves as a whole unit with a directional slide + fade
/// (left from the left, center from the bottom, right from the right).
///
/// Mount it once at app level, floating over the router's pages, so island
/// changes animate across navigations; its background is transparent so only
/// the island pills are visible.
class BottomNavBar extends StatelessWidget {
  /// Creates the bar.
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final islands = NavIslandsScope.of(context).islands;
    if (islands.totalItems == 0) return const SizedBox.shrink();
    final activeId = islands.activeId;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: BottomNavTokens.barPaddingX,
          vertical: BottomNavTokens.barPaddingY,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final metrics = computeNavMetrics(constraints.maxWidth, islands);

            // Side islands hug the centre island by default; a slot marked
            // NavIslandAlignment.edge sits flush with its screen edge.
            final leftAlignment =
                islands.leftAlignment == NavIslandAlignment.edge
                ? Alignment.centerLeft
                : Alignment.centerRight;
            final rightAlignment =
                islands.rightAlignment == NavIslandAlignment.edge
                ? Alignment.centerRight
                : Alignment.centerLeft;

            // Bound the row to the pill height so the Expanded/Align side
            // slots can't stretch it to the full (loose) height the host's
            // bottom slot offers — otherwise the islands end up vertically
            // centered on screen instead of sitting at the bottom.
            return SizedBox(
              height: metrics.navHeight,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Align(
                      alignment: leftAlignment,
                      child: _IslandSlot(
                        slot: NavIslandSlot.left,
                        items: islands.left,
                        metrics: metrics,
                        style: islands.style,
                        activeId: activeId,
                        enterOffset: const Offset(-2, 0),
                        alignment: leftAlignment,
                      ),
                    ),
                  ),
                  _IslandSlot(
                    slot: NavIslandSlot.center,
                    items: islands.center,
                    metrics: metrics,
                    style: islands.style,
                    activeId: activeId,
                    enterOffset: const Offset(0, 2),
                    alignment: Alignment.center,
                    semanticLabel: 'Primary',
                    padding: EdgeInsets.symmetric(
                      horizontal: metrics.interIslandGap,
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: rightAlignment,
                      child: _IslandSlot(
                        slot: NavIslandSlot.right,
                        items: islands.right,
                        metrics: metrics,
                        style: islands.style,
                        activeId: activeId,
                        enterOffset: const Offset(2, 0),
                        alignment: rightAlignment,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One island position. Wraps its island in an [AnimatedSwitcher] so that when
/// the island appears, disappears, or its contents change, it slides in from
/// [enterOffset] (and leaves back out the same way) while cross-fading. Honours
/// the platform "reduce motion" setting by collapsing the duration.
class _IslandSlot extends StatelessWidget {
  const _IslandSlot({
    required this.slot,
    required this.items,
    required this.metrics,
    required this.style,
    required this.activeId,
    required this.enterOffset,
    required this.alignment,
    this.semanticLabel,
    this.padding = EdgeInsets.zero,
  });

  final NavIslandSlot slot;
  final List<NavItem> items;
  final BottomNavMetrics metrics;
  final NavIslandStyle style;
  final String? activeId;

  /// Off-screen start/end position, as a fraction of the child size (e.g.
  /// `Offset(-2, 0)` = translate -200% on X).
  final Offset enterOffset;

  /// Alignment used to stack the entering/leaving children during a swap.
  final Alignment alignment;
  final String? semanticLabel;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    // Key by the island's *glyphs*: an island whose icons survive a page
    // change morphs in place (e.g. an add button changing colour between
    // sections — same glyph, new colour), while an island whose buttons
    // actually change (different icons, kinds, or layout) plays the
    // directional slide in/out.
    final Widget child;
    if (items.isEmpty) {
      child = SizedBox.shrink(key: ValueKey<String>('empty:${slot.name}'));
    } else {
      final signature = items
          .map(
            (i) => switch (i) {
              final NavLink link => 'link:${link.icon.identity}:${i.span}',
              final NavAction action =>
                'action:${action.icon.identity}:${i.span}',
              final NavWidget widget => 'widget:${widget.label}:${i.span}',
            },
          )
          .join('|');
      child = Padding(
        key: ValueKey<String>('island:${slot.name}:$signature'),
        padding: padding,
        child: NavIsland(
          items: items,
          metrics: metrics,
          style: style,
          activeId: activeId,
          semanticLabel: semanticLabel,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: reduceMotion
          ? Duration.zero
          : BottomNavTokens.islandAnimDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: enterOffset,
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        clipBehavior: Clip.none,
        alignment: alignment,
        children: <Widget>[
          // Only the current child sizes the slot. Leaving children overlay at
          // their intrinsic width (via OverflowBox) without contributing to
          // layout, so the row doesn't reflow — and neighbours don't jump — when
          // a leaving island is finally removed at the end of its animation.
          for (final child in previousChildren)
            Positioned.fill(
              child: OverflowBox(
                alignment: alignment,
                minWidth: 0,
                maxWidth: double.infinity,
                child: child,
              ),
            ),
          ?currentChild,
        ],
      ),
      child: child,
    );
  }
}
