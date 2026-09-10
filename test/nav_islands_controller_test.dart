import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  group('NavIslandsController', () {
    test('override applies and reset empties the bar', () {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);
      expect(controller.islands.totalItems, 0);
      expect(controller.overridden, isFalse);

      controller.override(
        center: <NavItem>[
          dummyItem(label: 'b'),
          dummyItem(label: 'c'),
        ],
      );
      expect(controller.islands.center.length, 2);
      expect(controller.overridden, isTrue);

      controller.reset();
      expect(controller.islands.totalItems, 0);
      expect(controller.overridden, isFalse);
    });

    test('rejects an override with more than 8 items', () {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);
      expect(
        () => controller.override(
          center: <NavItem>[for (var i = 0; i < 9; i++) dummyItem()],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('an override replaces the previous layout wholesale', () {
      final controller = NavIslandsController()
        ..override(left: <NavItem>[for (var i = 0; i < 5; i++) dummyItem()]);
      addTearDown(controller.dispose);

      controller.override(
        center: <NavItem>[for (var i = 0; i < 4; i++) dummyItem()],
      );
      // The unset left island does not leak through from the previous layout.
      expect(controller.islands.left, isEmpty);
      expect(controller.islands.center.length, 4);
    });

    test('softReset keeps the islands on screen but clears the override', () {
      final controller = NavIslandsController()
        ..override(center: <NavItem>[dummyItem(label: 'b')]);
      addTearDown(controller.dispose);

      controller.softReset();
      expect(controller.islands.center.single.label, 'b');
      expect(controller.overridden, isFalse);
    });

    test('every mutation notifies listeners', () {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller
        ..override(center: <NavItem>[dummyItem()])
        ..softReset()
        ..reset();

      expect(notifications, 3);
    });
  });
}
