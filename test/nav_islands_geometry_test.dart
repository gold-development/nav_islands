import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

/// A roomier bar than the default, every value different from it.
const NavIslandsGeometry _roomy = NavIslandsGeometry(
  minChip: 48,
  maxChip: 56,
  chipGap: 6,
  islandPaddingX: 6,
  navHeight: 64,
  barPaddingX: 20,
  barPaddingY: 10,
  interIslandGap: 12,
  badgeSize: 20,
  badgeRingWidth: 2,
);

void main() {
  test('the defaults are the tokens', () {
    const geometry = NavIslandsGeometry();
    expect(geometry.maxChip, BottomNavTokens.maxChip);
    expect(geometry.navHeight, BottomNavTokens.navHeight);
    expect(geometry.barHeight, BottomNavTokens.barHeight);
    expect(const NavIslandsThemeData().geometry, geometry);
  });

  test('copyWith, equality and the bar height', () {
    final geometry = const NavIslandsGeometry().copyWith(navHeight: 64);
    expect(geometry, const NavIslandsGeometry(navHeight: 64));
    expect(geometry.hashCode, const NavIslandsGeometry(navHeight: 64).hashCode);
    expect(geometry.barHeight, 64 + BottomNavTokens.barPaddingY * 2);
    expect(geometry == const NavIslandsGeometry(), isFalse);
  });

  test('computeNavMetrics follows the geometry', () {
    final islands = NavIslands(center: <NavItem>[dummyItem()]);
    final metrics = computeNavMetrics(400, islands, geometry: _roomy);
    expect(metrics.chipSize, 56);
    expect(metrics.chipGap, 6);
    expect(metrics.islandPaddingX, 6);
    expect(metrics.navHeight, 64);
    expect(metrics.interIslandGap, 12);
  });

  testWidgets('the bar is laid out with the theme\'s geometry', (tester) async {
    final controller = NavIslandsController()
      ..override(
        leftAlignment: NavIslandAlignment.edge,
        left: <NavItem>[dummyItem(label: 'L')],
        center: <NavItem>[dummyItem(label: 'C')],
      );
    addTearDown(controller.dispose);

    late double overlay;
    await tester.pumpWidget(
      navHost(
        controller: controller,
        theme: const NavIslandsThemeData(geometry: _roomy),
        child: Builder(
          builder: (context) {
            overlay = bottomNavOverlayHeight(context);
            return const Stack(
              children: <Widget>[
                Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final island = find.byType(NavIsland).first;
    expect(tester.getTopLeft(island).dx, 20);
    expect(tester.getSize(island).height, 64);
    expect(tester.getSize(find.byType(BottomNavBar)).height, 64 + 10 * 2);
    expect(overlay, _roomy.barHeight);
  });

  testWidgets('a badge takes the theme\'s size and ring', (tester) async {
    await tester.pumpWidget(
      NavIslandsTheme(
        data: const NavIslandsThemeData(geometry: _roomy),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          // Positioned, as the chip places it: unbounded, so it takes its size.
          child: Stack(
            children: <Widget>[
              Positioned(top: 0, left: 0, child: NavBadge(count: 3)),
            ],
          ),
        ),
      ),
    );
    // The test font draws every glyph a full em wide, so only the height is
    // exact; the width is at least the size, and grows with the digits.
    final size = tester.getSize(find.byType(NavBadge));
    expect(size.height, 20);
    expect(size.width, greaterThanOrEqualTo(20));
  });

  test('the badge corner inset follows the badge size', () {
    expect(badgeCornerInset(48, badgeSize: 20), lessThan(badgeCornerInset(48)));
  });
}
