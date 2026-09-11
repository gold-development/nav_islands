import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

/// The style the framework falls back to when text is painted with no Material
/// ancestor and nothing else supplies a default: a yellow double underline.
/// The package is mounted above the page, so this is what its labels inherited
/// until they were given a default of their own.
TextStyle _resolvedStyleOf(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return richText.text.style!;
}

void main() {
  testWidgets('a fan label is not painted with the error underline', (
    tester,
  ) async {
    final controller = NavIslandsController();
    addTearDown(controller.dispose);
    final animation = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 1),
    )..value = 1;
    addTearDown(animation.dispose);

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

    final style = _resolvedStyleOf(tester, 'Nieuwe klant');
    expect(style.decoration, TextDecoration.none);
  });

  testWidgets('an action button label is not either', (tester) async {
    final controller = NavIslandsController()
      ..override(
        center: <NavItem>[
          dummyItem(
            label: 'Opslaan',
            builder: (_) => NavActionButton(
              label: 'Opslaan',
              color: const Color(0xff006699),
              onTap: () {},
            ),
          ),
        ],
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

    expect(_resolvedStyleOf(tester, 'Opslaan').decoration, TextDecoration.none);
  });
}
