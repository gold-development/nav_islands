import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  testWidgets('link chip paints its glyph, reports selection, forwards tap', (
    tester,
  ) async {
    var tapped = 0;
    final link = NavLink(
      id: 'overview',
      icon: testIcon('overview'),
      label: 'Overzicht',
      onTap: () => tapped++,
    );

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
            covered: true,
            selected: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A link whose id matches activeId exposes selected: true via Semantics.
    expect(
      tester.getSemantics(find.bySemanticsLabel('Overzicht')),
      isSemantics(isSelected: true, isButton: true),
    );

    await tester.tap(find.bySemanticsLabel('Overzicht'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('a held chip shows the press wash and lets it go', (
    tester,
  ) async {
    final controller = NavIslandsController();
    addTearDown(controller.dispose);

    final action = NavAction(
      icon: testIcon('search'),
      label: 'Zoeken',
      onTap: () {},
    );
    final metrics = computeNavMetrics(
      400,
      NavIslands(center: <NavItem>[action]),
    );

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

    double washOpacity() => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(NavPressable),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    expect(washOpacity(), 0);

    final gesture = await tester.press(find.bySemanticsLabel('Zoeken'));
    await tester.pump();
    expect(washOpacity(), 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(washOpacity(), 0);
  });

  testWidgets('a NavWidget item renders its own builder', (tester) async {
    final controller = NavIslandsController();
    addTearDown(controller.dispose);

    final item = dummyItem(
      label: 'custom',
      builder: (_) => const SizedBox.expand(
        key: Key('custom'),
        child: ColoredBox(color: Color(0xff00ff00)),
      ),
    );
    final metrics = computeNavMetrics(400, NavIslands(center: <NavItem>[item]));

    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: Center(
          child: NavItemChip(
            item: item,
            metrics: metrics,
            covered: false,
            selected: false,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('custom')), findsOneWidget);
  });
}
