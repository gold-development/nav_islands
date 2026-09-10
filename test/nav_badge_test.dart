import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

/// Pumps a single chip for [link], the way the bar builds one.
Future<void> pumpChip(WidgetTester tester, NavLink link) async {
  final metrics = computeNavMetrics(400, NavIslands(center: <NavItem>[link]));
  final controller = NavIslandsController();
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    navHost(
      controller: controller,
      child: Center(
        child: NavItemChip(
          item: link,
          metrics: metrics,
          covered: false,
          selected: false,
        ),
      ),
    ),
  );
}

NavLink badgedLink(int count) => NavLink(
  id: 'alerts',
  icon: testIcon('alerts'),
  label: 'Alerts',
  onTap: () {},
  badgeCount: count,
);

void main() {
  testWidgets('no badge at zero, so a caller needs no conditional', (
    tester,
  ) async {
    await pumpChip(tester, badgedLink(0));
    expect(find.byType(NavBadge), findsNothing);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('a count draws on the chip', (tester) async {
    await pumpChip(tester, badgedLink(3));
    expect(find.byType(NavBadge), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('caps at 99+, so a busy inbox cannot widen the chip', (
    tester,
  ) async {
    await pumpChip(tester, badgedLink(NavBadge.max));
    expect(find.text('99'), findsOneWidget);

    await pumpChip(tester, badgedLink(NavBadge.max + 1));
    expect(find.text('100'), findsNothing);
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('a negative count draws nothing rather than a minus sign', (
    tester,
  ) async {
    await pumpChip(tester, badgedLink(-1));
    expect(find.byType(NavBadge), findsNothing);
  });

  testWidgets('carries no semantics: the chip is already labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpChip(tester, badgedLink(7));
    // The chip's own label is what a screen reader announces; a bare "7"
    // beside it would say nothing useful, so the badge is excluded.
    expect(find.bySemanticsLabel('Alerts'), findsOneWidget);
    expect(find.bySemanticsLabel('7'), findsNothing);
    handle.dispose();
  });

  testWidgets('an action chip can carry one too', (tester) async {
    final action = NavAction(
      label: 'Menu',
      icon: testIcon('menu'),
      onTap: () {},
      badgeCount: 2,
    );
    final metrics = computeNavMetrics(
      400,
      NavIslands(center: <NavItem>[action]),
    );
    final controller = NavIslandsController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: Center(
          child: NavItemChip(
            item: action,
            metrics: metrics,
            covered: false,
            selected: false,
          ),
        ),
      ),
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('takes its colours from the theme, and survives a copyWith', (
    tester,
  ) async {
    const pink = Color(0xffff00ff);
    // copyWith dropping these was a real bug: a themed badge reverted to the
    // default the first time any other field was changed.
    final style = NavIslandStyleData.light.copyWith(badgeColor: pink);
    expect(style.badgeColor, pink);
    expect(style.copyWith(iconColor: pink).badgeColor, pink);
  });

  testWidgets('ignores the platform text scale, so the chip keeps its size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpChip(tester, badgedLink(9));
    final text = tester.widget<Text>(find.text('9'));
    expect(text.textScaler, TextScaler.noScaling);
  });
}
