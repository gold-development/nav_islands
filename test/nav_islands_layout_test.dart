import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  group('computeNavMetrics', () {
    test('clamps chip to maxChip when there is plenty of room', () {
      final islands = NavIslands(
        center: <NavItem>[dummyItem(), dummyItem(), dummyItem()],
      );
      final m = computeNavMetrics(400, islands);
      expect(m.chipSize, BottomNavTokens.maxChip);
    });

    test('shrinks chip toward minChip when crowded', () {
      final islands = NavIslands(
        center: <NavItem>[for (var i = 0; i < 8; i++) dummyItem(label: '$i')],
      );
      final m = computeNavMetrics(320, islands);
      expect(m.chipSize, BottomNavTokens.minChip);
    });

    test('uses a tighter inter-island gap on small devices', () {
      final islands = NavIslands(
        left: <NavItem>[dummyItem()],
        center: <NavItem>[dummyItem()],
        right: <NavItem>[dummyItem()],
      );
      expect(
        computeNavMetrics(400, islands).interIslandGap,
        BottomNavTokens.interIslandGap,
      );
      expect(
        computeNavMetrics(350, islands).interIslandGap,
        BottomNavTokens.interIslandGapCompact,
      );
    });

    test('an item spans multiple cells', () {
      final m = computeNavMetrics(
        400,
        NavIslands(center: <NavItem>[dummyItem()]),
      );
      expect(m.itemWidth(2), m.chipSize * 2);
      expect(m.itemWidth(3), m.chipSize * 3);
    });

    test('an empty layout still yields usable metrics', () {
      final m = computeNavMetrics(400, const NavIslands.empty());
      expect(m.chipSize, BottomNavTokens.maxChip);
    });
  });
}
