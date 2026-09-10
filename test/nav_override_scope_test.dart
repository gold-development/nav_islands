import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

void main() {
  group('NavOverrideScope', () {
    testWidgets('each page asserts its islands; pop returns the previous', (
      tester,
    ) async {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        navHostWithNavigator(
          controller: controller,
          navigatorKey: navKey,
          home: NavOverrideScope(
            islandsBuilder: (context) =>
                NavIslands(center: <NavItem>[dummyItem(label: 'home')]),
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The home page asserted its layout one frame after mounting.
      expect(controller.islands.center.single.label, 'home');

      // Push a page with its own layout; the navigation reset empties the bar
      // and the new page asserts its islands.
      navKey.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => NavOverrideScope(
            islandsBuilder: (context) =>
                NavIslands(center: <NavItem>[dummyItem(label: 'close')]),
            child: const SizedBox(),
          ),
        ),
      );
      controller.reset(); // the router listener fires on navigation
      await tester.pumpAndSettle();
      expect(controller.islands.center.single.label, 'close');

      // A spurious reset (hot reload) while the page is current: the layout
      // must come back on its own.
      controller.reset();
      await tester.pumpAndSettle();
      expect(controller.islands.center.single.label, 'close');

      // Pop + the navigation reset: the home page's islands return.
      navKey.currentState!.pop();
      controller.reset();
      await tester.pumpAndSettle();
      expect(controller.islands.center.single.label, 'home');
    });

    testWidgets('a page in a nested navigator stops when its shell is covered', (
      tester,
    ) async {
      // A page inside a shell route stays the top route of *its* navigator
      // while the shell itself is replaced — logging out, say. Checking only
      // the innermost route let the leaving page re-assert its islands over
      // the screen that replaced it.
      final controller = NavIslandsController();
      addTearDown(controller.dispose);

      final rootKey = GlobalKey<NavigatorState>();
      final shellKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        navHostWithNavigator(
          controller: controller,
          navigatorKey: rootKey,
          home: Navigator(
            key: shellKey,
            onGenerateRoute: (settings) => PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (context, _, _) => NavOverrideScope(
                islandsBuilder: (context) =>
                    NavIslands(center: <NavItem>[dummyItem(label: 'inside')]),
                child: const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.islands.center.single.label, 'inside');

      // Cover the whole shell from the ROOT navigator. The inner page is still
      // the top route of the shell's navigator, so only walking the chain
      // upward can tell that it is no longer on screen.
      rootKey.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => const SizedBox(),
        ),
      );
      controller.reset();
      await tester.pumpAndSettle();
      expect(controller.islands.totalItems, 0);
    });

    testWidgets('a covered page stops asserting its layout', (tester) async {
      final controller = NavIslandsController();
      addTearDown(controller.dispose);

      final navKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        navHostWithNavigator(
          controller: controller,
          navigatorKey: navKey,
          home: NavOverrideScope(
            islandsBuilder: (context) =>
                NavIslands(center: <NavItem>[dummyItem(label: 'home')]),
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Push a page that asserts nothing at all.
      navKey.currentState!.push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, _) => const SizedBox(),
        ),
      );
      controller.reset();
      await tester.pumpAndSettle();

      // The home page is no longer current, so the bar stays empty rather than
      // the covered page re-asserting over the new one.
      expect(controller.islands.totalItems, 0);
    });
  });
}
