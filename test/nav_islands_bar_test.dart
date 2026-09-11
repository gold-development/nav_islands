import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

/// The bar in the loose-height slot it lives in inside a real app, so the
/// "hugs the bottom" assertion below is meaningful.
Widget _bottomSlot(NavIslandsController controller) {
  return navHost(
    controller: controller,
    child: const Stack(
      children: <Widget>[
        Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
      ],
    ),
  );
}

/// The width a three-cell chip needs at [screenWidth], plus the island's own
/// padding: what the slot has to give it.
double metricsWidth(double screenWidth) {
  final metrics = computeNavMetrics(
    screenWidth,
    NavIslands(
      left: <NavItem>[NavWidget(label: 'x', builder: (_) => const SizedBox())],
      right: <NavItem>[
        NavWidget(label: 'w', span: 3, builder: (_) => const SizedBox()),
      ],
    ),
  );
  return metrics.itemWidth(3) + metrics.islandPaddingX * 2;
}

void main() {
  group('BottomNavBar', () {
    testWidgets('renders three islands and forwards taps', (tester) async {
      var tapped = 0;
      final controller = NavIslandsController()
        ..override(
          left: <NavItem>[dummyItem(label: 'L')],
          center: <NavItem>[
            dummyItem(
              label: 'C',
              builder: (_) => GestureDetector(
                key: const Key('center-btn'),
                onTap: () => tapped++,
                child: const SizedBox.expand(
                  child: ColoredBox(color: Color(0xffff0000)),
                ),
              ),
            ),
          ],
          right: <NavItem>[dummyItem(label: 'R')],
        );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));

      expect(find.byType(NavIsland), findsNWidgets(3));

      // The bar must hug the bottom (pill height + padding), not stretch to
      // fill the loose height its slot offers.
      expect(tester.getSize(find.byType(BottomNavBar)).height, lessThan(160));

      await tester.tap(find.byKey(const Key('center-btn')));
      await tester.pump();
      expect(tapped, 1);
    });

    testWidgets('edge alignment pushes side islands to the screen edges', (
      tester,
    ) async {
      final controller = NavIslandsController()
        ..override(
          leftAlignment: NavIslandAlignment.edge,
          rightAlignment: NavIslandAlignment.edge,
          left: <NavItem>[dummyItem(label: 'L')],
          center: <NavItem>[dummyItem(label: 'C')],
          right: <NavItem>[dummyItem(label: 'R')],
        );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));
      await tester.pumpAndSettle();

      final islands = find.byType(NavIsland);
      expect(islands, findsNWidgets(3));

      final barWidth = tester.getSize(find.byType(BottomNavBar)).width;
      final left = tester.getTopLeft(islands.at(0)).dx;
      final right = tester.getTopRight(islands.at(2)).dx;

      // Flush with the bar's horizontal padding on both sides.
      expect(left, BottomNavTokens.barPaddingX);
      expect(right, barWidth - BottomNavTokens.barPaddingX);
    });

    testWidgets('swaps islands via AnimatedSwitcher on override', (
      tester,
    ) async {
      final controller = NavIslandsController()
        ..override(center: <NavItem>[dummyItem(label: 'C')]);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));

      // One AnimatedSwitcher per slot (left / center / right).
      expect(find.byType(AnimatedSwitcher), findsNWidgets(3));
      expect(find.byType(NavIsland), findsOneWidget);

      // Clear the center and populate the right island; the switch animates.
      controller.override(
        center: <NavItem>[],
        right: <NavItem>[dummyItem(label: 'R')],
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(NavIsland), findsOneWidget);
    });

    testWidgets('moving the selection settles without error', (tester) async {
      final links = <NavItem>[
        NavLink(id: 'a', icon: testIcon('a'), label: 'A', onTap: () {}),
        NavLink(id: 'b', icon: testIcon('b'), label: 'B', onTap: () {}),
      ];
      final controller = NavIslandsController()
        ..override(activeId: 'a', center: links);
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.bySemanticsLabel('A')),
        isSemantics(isSelected: true),
      );

      // Move the selection: the indicator animates across to 'b'.
      controller.override(activeId: 'b', center: links);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120)); // mid-flight
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('B')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('A')),
        isSemantics(isSelected: false),
      );
    });

    testWidgets('a neighbour island does not jump while another leaves', (
      tester,
    ) async {
      // Right island holds a keyed "+"; center starts full then leaves. The "+"
      // must reach its final position immediately, not snap when the center
      // island's leave animation completes.
      final plus = <NavItem>[
        NavWidget(
          label: 'plus',
          builder: (_) => const SizedBox.expand(
            key: Key('plus'),
            child: ColoredBox(color: Color(0xffffa500)),
          ),
        ),
      ];
      final controller = NavIslandsController()
        ..override(
          center: <NavItem>[
            dummyItem(label: '1'),
            dummyItem(label: '2'),
          ],
          right: plus,
        );
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));
      await tester.pumpAndSettle();

      // Drop the center island; the "+" should shift left immediately and hold.
      controller.override(center: <NavItem>[], right: plus);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120)); // mid-leave
      final midX = tester.getCenter(find.byKey(const Key('plus'))).dx;
      await tester.pumpAndSettle(); // leave completes
      final endX = tester.getCenter(find.byKey(const Key('plus'))).dx;

      expect(midX, moreOrLessEquals(endX, epsilon: 0.5));
    });

    testWidgets('an uneven layout does not squeeze the bigger island', (
      tester,
    ) async {
      // One X against a three-cell chip: the side slots used to take half the
      // bar each, so the wide island was given less room than its own chips
      // needed and its row overflowed. Symmetric layouts never showed it.
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final controller = NavIslandsController()
        ..override(
          left: <NavItem>[
            NavAction(icon: testIcon('x'), label: 'x', onTap: () {}),
          ],
          right: <NavItem>[dummyItem(span: 3, label: 'wide')],
          leftAlignment: NavIslandAlignment.edge,
          rightAlignment: NavIslandAlignment.edge,
        );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        navHost(
          controller: controller,
          child: const Stack(
            children: <Widget>[
              Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(BottomNavBar));
      final wide = tester.getRect(find.byType(NavIsland).at(1));
      expect(wide.width, greaterThanOrEqualTo(metricsWidth(320)));
      expect(wide.right, lessThanOrEqualTo(bar.right + 0.01));
    });

    testWidgets('a centre island stays on the axis, however uneven the sides', (
      tester,
    ) async {
      // The sides flex by cells only while the centre is empty: an SOS button
      // drifting off centre is worse than a tight side island.
      final controller = NavIslandsController()
        ..override(
          left: <NavItem>[
            dummyItem(label: 'a'),
            dummyItem(label: 'b'),
          ],
          center: <NavItem>[dummyItem(label: 'sos')],
          right: <NavItem>[dummyItem(label: 'c')],
          leftAlignment: NavIslandAlignment.edge,
          rightAlignment: NavIslandAlignment.edge,
        );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        navHost(
          controller: controller,
          child: const Stack(
            children: <Widget>[
              Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = tester.getRect(find.byType(BottomNavBar));
      final centre = tester.getCenter(find.byType(NavIsland).at(1));
      expect(centre.dx, closeTo(bar.center.dx, 0.01));
    });

    testWidgets('renders nothing when all islands are empty', (tester) async {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_bottomSlot(controller));

      expect(find.byType(NavIsland), findsNothing);
    });

    testWidgets('the theme drives the pill colours', (tester) async {
      final controller = NavIslandsController()
        ..override(center: <NavItem>[dummyItem(label: 'C')]);
      addTearDown(controller.dispose);

      const pill = Color(0xff123456);
      await tester.pumpWidget(
        navHost(
          controller: controller,
          theme: const NavIslandsThemeData(
            light: NavIslandStyleData(
              pillColor: pill,
              borderColor: Color(0xff000000),
              iconColor: Color(0xff000000),
              indicatorColor: Color(0x11000000),
            ),
          ),
          child: const Stack(
            children: <Widget>[
              Positioned(left: 0, right: 0, bottom: 0, child: BottomNavBar()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final container = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(NavIsland),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, pill);
    });
  });
}
