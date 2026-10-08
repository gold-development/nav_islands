import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

const double _keyboard = 300;

/// The bar at the bottom of an 800-high screen whose keyboard is [keyboard]
/// tall, showing [islands]; returns the bottom edge of the chip's pill.
Future<double> _chipBottom(
  WidgetTester tester,
  NavIslands islands, {
  double keyboard = _keyboard,
}) async {
  final controller = NavIslandsController();
  addTearDown(controller.dispose);
  controller.override(left: islands.left, aboveKeyboard: islands.aboveKeyboard);
  await tester.pumpWidget(
    navHost(
      controller: controller,
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          viewInsets: EdgeInsets.only(bottom: keyboard),
        ),
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: BottomNavBar(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getBottomLeft(find.byType(NavIsland)).dy;
}

void main() {
  final save = NavAction(icon: testIcon('save'), label: 'Save', onTap: () {});

  testWidgets('a bar stays behind the keyboard by default', (tester) async {
    final open = await _chipBottom(tester, NavIslands(left: [save]));
    final closed = await _chipBottom(
      tester,
      NavIslands(left: [save]),
      keyboard: 0,
    );
    expect(open, closed);
  });

  testWidgets('aboveKeyboard lifts it by the keyboard height', (tester) async {
    final open = await _chipBottom(
      tester,
      NavIslands(left: [save], aboveKeyboard: true),
    );
    final closed = await _chipBottom(
      tester,
      NavIslands(left: [save], aboveKeyboard: true),
      keyboard: 0,
    );
    expect(closed - open, _keyboard);
  });

  testWidgets('a NavOverrideScope passes it on', (tester) async {
    final controller = NavIslandsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHostWithNavigator(
        controller: controller,
        navigatorKey: GlobalKey<NavigatorState>(),
        home: NavOverrideScope(
          islandsBuilder: (_) => NavIslands(left: [save], aboveKeyboard: true),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.islands.aboveKeyboard, isTrue);
  });

  testWidgets('bottomNavScrollPadding clears the bar', (tester) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            padding = bottomNavScrollPadding(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    const bar = NavIslandsGeometry();
    expect(
      padding,
      const EdgeInsets.fromLTRB(20, 20, 20, 20 + 0) +
          EdgeInsets.only(bottom: bar.barHeight),
    );
  });
}
