import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_item.dart';
import 'package:nav_islands/src/nav_item_chip.dart';

/// A single pill in the bottom bar, holding one or more chips. Owns the pill
/// chrome (background, border, shadow) so chips stay uniform — a one-chip
/// island reads as a circle, a multi-chip island as a wide pill.
///
/// The selected chip's background is a single indicator drawn behind the chips.
/// When the selection moves, the indicator stretches toward the destination and
/// then retracts into a circle (dual-curve leading/trailing edges), and each
/// chip's icon lights up while the indicator covers it.
///
/// With [NavIslandStyle.bare] none of the chrome is drawn and nothing is
/// clipped: the island is a transparent slot whose item brings its own shape
/// and may stand taller than the pill.
class NavIsland extends StatefulWidget {
  /// Creates an island.
  const NavIsland({
    required this.items,
    required this.metrics,
    required this.activeId,
    this.style = NavIslandStyle.light,
    this.semanticLabel,
    super.key,
  });

  /// The chips in this island.
  final List<NavItem> items;

  /// Resolved sizes for this build of the bar.
  final BottomNavMetrics metrics;

  /// Pill styling asserted by the current page.
  final NavIslandStyle style;

  /// Section id used to mark the matching [NavLink] active.
  final String? activeId;

  /// Accessibility label for the island as a group.
  final String? semanticLabel;

  @override
  State<NavIsland> createState() => _NavIslandState();
}

class _NavIslandState extends State<NavIsland>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: BottomNavTokens.selectionAnimDuration,
    value: 1,
  );

  /// Currently selected chip index (null when nothing in this island is active).
  int? _selected;

  /// Endpoints of the in-flight indicator move.
  int? _from;
  int? _to;

  @override
  void initState() {
    super.initState();
    _selected = _selectedIndex(widget.items, widget.activeId);
    _from = _selected;
    _to = _selected;
  }

  @override
  void didUpdateWidget(NavIsland oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _selectedIndex(widget.items, widget.activeId);
    if (next == _selected) return;

    _from = _selected;
    _to = next;
    _selected = next;

    if (_from == null) {
      // First appearance — settle instantly, no stretch.
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static int? _selectedIndex(List<NavItem> items, String? activeId) {
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final active = switch (item) {
        final NavLink l => l.id == activeId,
        final NavAction a => a.isActive?.call() ?? false,
        NavWidget() => false,
      };
      if (active) return i;
    }
    return null;
  }

  /// Left offset of chip [index] within the island's content (padding excluded).
  double _leftOf(int index) {
    var left = 0.0;
    for (var i = 0; i < index; i++) {
      left +=
          widget.metrics.itemWidth(widget.items[i].span) +
          widget.metrics.chipGap;
    }
    return left;
  }

  Rect _rectOf(int index) {
    final m = widget.metrics;
    final width = m.itemWidth(widget.items[index].span);
    final top = (m.navHeight - m.chipSize) / 2;
    return Rect.fromLTWH(_leftOf(index), top, width, m.chipSize);
  }

  /// The indicator rectangle for the current animation frame, plus its opacity.
  (Rect?, double) _indicator() {
    if (_from == null && _to == null) return (null, 0);
    if (_from == null) return (_rectOf(_to!), 1);
    if (_to == null) {
      // Fading out after a deselect: once fully faded, drop the rect too so
      // the chip it covered stops rendering its "covered" state.
      final opacity = 1 - _controller.value;
      if (opacity <= 0) return (null, 0);
      return (_rectOf(_from!), opacity);
    }

    final f = _rectOf(_from!);
    final g = _rectOf(_to!);
    final t = _controller.value;
    final movingRight = g.left >= f.left;
    // The leading edge races ahead (easeOut); the trailing edge lags (easeIn),
    // so the pill stretches across the gap and then retracts to a circle.
    final lead = Curves.easeOut.transform(t);
    final trail = Curves.easeIn.transform(t);
    final leftT = movingRight ? trail : lead;
    final rightT = movingRight ? lead : trail;
    final left = ui.lerpDouble(f.left, g.left, leftT)!;
    final right = ui.lerpDouble(f.right, g.right, rightT)!;
    return (Rect.fromLTRB(left, f.top, right, f.bottom), 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = NavIslandsTheme.of(context);
    final palette = theme.styleFor(widget.style);
    final metrics = widget.metrics;
    final radius = BorderRadius.circular(metrics.navHeight / 2);
    final bare = widget.style == NavIslandStyle.bare;

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: ClipRRect(
        borderRadius: radius,
        // A bare island lets its item stand taller than the pill.
        clipBehavior: bare ? Clip.none : Clip.antiAlias,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final (rect, opacity) = _indicator();
            final reduceMotion = MediaQuery.of(context).disableAnimations;

            return AnimatedContainer(
              // Morph the pill chrome when a page asserts the other style
              // (light ↔ dark), in step with the chips' colour crossfade.
              duration: reduceMotion
                  ? Duration.zero
                  : BottomNavTokens.chipMorphDuration,
              curve: Curves.easeOut,
              height: metrics.navHeight,
              padding: EdgeInsets.symmetric(horizontal: metrics.islandPaddingX),
              // A solid pill with a hairline border plus a tight contact shadow
              // and a soft ambient one, so it stays defined on light page
              // backgrounds. A bare island draws none of it — not even the
              // shadow, which would otherwise show under a transparent pill.
              decoration: bare
                  ? const BoxDecoration()
                  : BoxDecoration(
                      color: palette.pillColor,
                      borderRadius: radius,
                      border: Border.all(color: palette.borderColor),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.10),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: <Widget>[
                  // No selection wash on a bare island: there is no pill for it
                  // to sit inside.
                  if (rect != null && !bare)
                    Positioned(
                      left: rect.left,
                      top: rect.top,
                      width: rect.width,
                      height: rect.height,
                      child: Opacity(
                        opacity: opacity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // A fixed neutral pill; the covered icon carries
                            // the accent colour.
                            color: palette.indicatorColor,
                            borderRadius: BorderRadius.circular(
                              metrics.chipSize / 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      for (var i = 0; i < widget.items.length; i++) ...<Widget>[
                        if (i > 0) SizedBox(width: metrics.chipGap),
                        NavItemChip(
                          item: widget.items[i],
                          metrics: metrics,
                          covered: _covers(rect, i),
                          // Active state is carried by the wash alone for
                          // now — the icon keeps its default colour.
                          style: widget.style,
                          selected: i == _selected,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Whether the indicator [rect] currently sits over chip [index]'s centre.
  bool _covers(Rect? rect, int index) {
    if (rect == null) return false;
    final r = _rectOf(index);
    final centerX = r.center.dx;
    return rect.left - 0.5 <= centerX && centerX <= rect.right + 0.5;
  }
}
