import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

Future<NavIslands> _asserted(
  WidgetTester tester,
  NavSingleActionBar bar,
) async {
  final controller = NavIslandsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    navHostWithNavigator(
      controller: controller,
      navigatorKey: GlobalKey<NavigatorState>(),
      home: bar,
    ),
  );
  await tester.pumpAndSettle();
  return controller.islands;
}

void main() {
  testWidgets('the chip sits in the centre island by default', (tester) async {
    final islands = await _asserted(
      tester,
      NavSingleActionBar(icon: testIcon('back'), label: 'Back', onTap: () {}),
    );
    expect(islands.center.single.label, 'Back');
    expect(islands.left, isEmpty);
    expect(islands.right, isEmpty);
  });

  testWidgets('a left slot on the edge, where back arrows go', (tester) async {
    final islands = await _asserted(
      tester,
      NavSingleActionBar(
        slot: NavIslandSlot.left,
        alignment: NavIslandAlignment.edge,
        icon: testIcon('back'),
        label: 'Back',
        onTap: () {},
      ),
    );
    expect(islands.left.single.label, 'Back');
    expect(islands.center, isEmpty);
    expect(islands.leftAlignment, NavIslandAlignment.edge);
  });

  testWidgets('or the right one', (tester) async {
    final islands = await _asserted(
      tester,
      NavSingleActionBar(
        slot: NavIslandSlot.right,
        icon: testIcon('close'),
        label: 'Close',
        onTap: () {},
      ),
    );
    expect(islands.right.single.label, 'Close');
    expect(islands.center, isEmpty);
  });
}
