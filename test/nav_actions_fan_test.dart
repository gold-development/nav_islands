import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  testWidgets('a long label wraps inside the screen instead of running off', (
    tester,
  ) async {
    // A narrow phone.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = NavIslandsController();
    addTearDown(controller.dispose);
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    )..value = 1;
    addTearDown(animation.dispose);

    const long = 'Offerte vaste aanneemsom maken, met nog wat extra woorden';
    await tester.pumpWidget(
      navHost(
        controller: controller,
        child: ActionsFanHost(
          animation: animation,
          open: true,
          closeIcon: testIcon('close'),
          closeLabel: 'Sluiten',
          closeColor: const Color(0xffff9900),
          onClose: () {},
          actions: <FanAction>[
            FanAction(
              icon: testIcon('quotation'),
              color: const Color(0xffad1457),
              label: long,
              onTap: () {},
            ),
            FanAction(
              icon: testIcon('customer'),
              color: const Color(0xff7b1fa2),
              label: 'Nieuwe klant',
              onTap: () {},
            ),
          ],
          child: const SizedBox.expand(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final label = tester.getRect(find.text(long));
    expect(label.left, greaterThanOrEqualTo(16));
    expect(label.right, lessThanOrEqualTo(360));
    // It took a second line rather than being cut to one.
    final short = tester.getRect(find.text('Nieuwe klant'));
    expect(label.height, greaterThan(short.height * 1.5));
  });

  testWidgets('the edge inset and label lines come from the theme', (
    tester,
  ) async {
    const long =
        'Een label dat zo lang is dat het op een smal scherm niet op één, '
        'twee of zelfs drie regels past zonder te worden afgekapt';
    await _pumpFan(
      tester,
      theme: const NavIslandsThemeData(fanEdgeInset: 40, fanLabelMaxLines: 1),
      label: long,
    );
    final label = tester.getRect(find.text(long));
    expect(label.left, greaterThanOrEqualTo(40));
    final text = tester.widget<Text>(find.text(long));
    expect(text.maxLines, 1);
  });

  testWidgets('the circle size comes from the theme', (tester) async {
    await _pumpFan(
      tester,
      theme: const NavIslandsThemeData(fanCircleSize: 72),
      label: 'Nieuwe klant',
    );
    final circle = find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).color ==
              const Color(0xffad1457),
    );
    expect(tester.getSize(circle), const Size(72, 72));
  });

  test('themes with the same values are equal', () {
    const a = NavIslandsThemeData(
      fanShadows: [BoxShadow(blurRadius: 3)],
      motion: NavIslandsMotion(press: Duration(milliseconds: 50)),
    );
    final b = const NavIslandsThemeData().copyWith(
      fanShadows: [const BoxShadow(blurRadius: 3)],
      motion: const NavIslandsMotion().copyWith(
        press: const Duration(milliseconds: 50),
      ),
    );
    expect(b, a);
    expect(b.hashCode, a.hashCode);
    expect(a == const NavIslandsThemeData(), isFalse);
  });
}

// A fan of one entry under [theme], fully open, on a narrow phone.
Future<void> _pumpFan(
  WidgetTester tester, {
  required NavIslandsThemeData theme,
  required String label,
}) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = NavIslandsController();
  addTearDown(controller.dispose);
  final animation = AnimationController(
    vsync: const TestVSync(),
    duration: const Duration(milliseconds: 1),
  )..value = 1;
  addTearDown(animation.dispose);

  await tester.pumpWidget(
    NavIslandsTheme(
      data: theme,
      child: navHost(
        controller: controller,
        child: ActionsFanHost(
          animation: animation,
          open: true,
          closeIcon: testIcon('close'),
          closeLabel: 'Sluiten',
          closeColor: const Color(0xffff9900),
          onClose: () {},
          actions: <FanAction>[
            FanAction(
              icon: testIcon('quotation'),
              color: const Color(0xffad1457),
              label: label,
              onTap: () {},
            ),
          ],
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
  await tester.pump();
}
