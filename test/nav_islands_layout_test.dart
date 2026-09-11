import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  test('a span-n chip pays for the gaps inside it', () {
    // Counting only the gaps *between* items left a span's own gaps out of the
    // budget, so the chip came back too large and the island overflowed its
    // slot: 16 pt for a span of 5, which is how it was found.
    final one = NavIslands(
      right: <NavItem>[
        NavWidget(label: 'wide', span: 5, builder: (_) => const SizedBox()),
      ],
    );
    final metrics = computeNavMetrics(390, one);
    const barPaddingX = 14.0, islandPaddingX = 4.0;
    final used = barPaddingX * 2 + islandPaddingX * 2 + metrics.itemWidth(5);
    expect(used, lessThanOrEqualTo(390));
  });

  test('a layout too wide for the bar says so instead of overflowing', () {
    // Five cells plus an X is more than a 320 pt phone can hold at the 44 pt
    // minimum, and it used to draw off the edge of the screen.
    final tooWide = NavIslands(
      left: <NavItem>[
        NavLink(id: 'x', icon: testIcon('x'), label: 'x', onTap: () {}),
      ],
      right: <NavItem>[
        NavWidget(label: 'wide', span: 5, builder: (_) => const SizedBox()),
      ],
    );
    expect(
      () => computeNavMetrics(320, tooWide),
      throwsA(isA<AssertionError>()),
    );
  });

  test('a span may reach the whole bar, so a chip can carry a sentence', () {
    // The cap used to be 3, which is about 130 pt — a couple of words. A cell
    // never grows past maxChip however wide the screen, so span is the only
    // way to make room for a sentence.
    final wide = NavIslands(
      left: <NavItem>[
        NavLink(id: 'x', icon: testIcon('x'), label: 'x', onTap: () {}),
      ],
      right: <NavItem>[
        NavWidget(label: 'wide', span: 5, builder: (_) => const SizedBox()),
      ],
    );
    final metrics = computeNavMetrics(390, wide);
    expect(metrics.itemWidth(5), greaterThan(metrics.itemWidth(3)));
    // and the bar's own budget still holds
    expect(wide.totalItems, lessThanOrEqualTo(kMaxNavItems));
  });

  group('computeNavMetrics', () {
    test('clamps chip to maxChip when there is plenty of room', () {
      final islands = NavIslands(
        center: <NavItem>[dummyItem(), dummyItem(), dummyItem()],
      );
      final m = computeNavMetrics(400, islands);
      expect(m.chipSize, BottomNavTokens.maxChip);
    });

    test('shrinks chip toward minChip when crowded', () {
      // Six cells is exactly what a 320 pt phone holds at the 44 pt minimum.
      // `kMaxNavItems` is 8, which does *not* fit at that width — see the
      // note in the changelog; this asserts the real limit, not the nominal
      // one.
      final islands = NavIslands(
        center: <NavItem>[for (var i = 0; i < 6; i++) dummyItem(label: '$i')],
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
