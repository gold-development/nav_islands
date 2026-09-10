import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_islands/nav_islands.dart';

import 'nav_test_harness.dart';

/// Pumps the bar for [islands] and returns the tester's tree.
Future<NavIslandsController> pumpBar(
  WidgetTester tester,
  void Function(NavIslandsController) layout,
) async {
  final controller = NavIslandsController();
  addTearDown(controller.dispose);
  layout(controller);
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
  return controller;
}

/// The island rendering with [style] — the bar builds at most one per style.
Finder islandWith(NavIslandStyle style) => find.byWidgetPredicate(
  (widget) => widget is NavIsland && widget.style == style,
);

/// The decoration of the island rendering with [style].
BoxDecoration? decorationOf(WidgetTester tester, NavIslandStyle style) {
  final container = tester.widget<AnimatedContainer>(
    find
        .descendant(
          of: islandWith(style),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return container.decoration as BoxDecoration?;
}

void main() {
  testWidgets('a bare island draws no pill, border or shadow', (tester) async {
    await pumpBar(
      tester,
      (c) => c.override(
        center: <NavItem>[dummyItem(label: 'Centre')],
        style: NavIslandStyle.bare,
      ),
    );

    final decoration = decorationOf(tester, NavIslandStyle.bare)!;
    expect(decoration.color, isNull);
    expect(decoration.border, isNull);
    // A shadow under a transparent pill is the tell that "bare" only went
    // halfway: it draws a floating smudge with nothing casting it.
    expect(decoration.boxShadow, isNull);
  });

  testWidgets('a bare island does not clip, so its item may stand taller', (
    tester,
  ) async {
    await pumpBar(
      tester,
      (c) => c.override(
        center: <NavItem>[dummyItem(label: 'Centre')],
        style: NavIslandStyle.bare,
      ),
    );

    final clip = tester.widget<ClipRRect>(
      find
          .descendant(
            of: find.byType(NavIsland),
            matching: find.byType(ClipRRect),
          )
          .first,
    );
    expect(clip.clipBehavior, Clip.none);
  });

  testWidgets('only the centre island goes bare when centerStyle says so', (
    tester,
  ) async {
    await pumpBar(
      tester,
      (c) => c.override(
        left: <NavItem>[
          NavLink(
            id: 'home',
            icon: testIcon('home'),
            label: 'Home',
            onTap: () {},
          ),
        ],
        center: <NavItem>[dummyItem(label: 'Centre')],
        style: NavIslandStyle.light,
        centerStyle: NavIslandStyle.bare,
      ),
    );

    expect(decorationOf(tester, NavIslandStyle.bare)!.color, isNull);
    // The side island keeps its pill: centerStyle is a centre-only override.
    expect(
      decorationOf(tester, NavIslandStyle.light)!.color,
      NavIslandStyleData.light.pillColor,
    );
  });

  testWidgets('a bare island draws no selection wash behind an active chip', (
    tester,
  ) async {
    await pumpBar(
      tester,
      (c) => c.override(
        center: <NavItem>[
          NavLink(id: 'sos', icon: testIcon('sos'), label: 'SOS', onTap: () {}),
        ],
        style: NavIslandStyle.bare,
        activeId: 'sos',
      ),
    );

    // The wash is the only thing the island wraps in an Opacity, so its
    // absence is the assertion — a transparent wash would still be drawn, and
    // still make the chip render its "covered" state.
    expect(
      find.descendant(
        of: islandWith(NavIslandStyle.bare),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('a bare island gives its widget the whole island height', (
    tester,
  ) async {
    // The pill is what sizes a chip; without one there is nothing to sit
    // inside, and the widget is the island.
    await pumpBar(
      tester,
      (c) => c.override(
        center: <NavItem>[dummyItem(label: 'Centre')],
        style: NavIslandStyle.bare,
      ),
    );
    final metrics = computeNavMetrics(
      800,
      const NavIslands(style: NavIslandStyle.bare),
    );
    final box = tester.widget<SizedBox>(
      find
          .descendant(
            of: islandWith(NavIslandStyle.bare),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.height, metrics.navHeight);
    expect(box.height, isNot(metrics.chipSize));
  });

  test('the badge sits inside the chip, not off its corner', () {
    // On a one-chip island the pill is a circle. A badge at the corner of the
    // chip's bounding box falls outside that circle and the island's clip
    // slices it off, so the inset is the point where the two circles touch.
    for (final chip in <double>[44, 48]) {
      final inset = badgeCornerInset(chip);
      expect(inset, greaterThan(0));
      // Tangent, not overlapping: the badge's centre sits on the chip's
      // diagonal at exactly (chipRadius - badgeRadius) from the centre.
      final badgeCentre = inset + NavBadge.diameter / 2;
      final fromCentre = (chip / 2 - badgeCentre) * math.sqrt2;
      expect(fromCentre, closeTo(chip / 2 - NavBadge.diameter / 2, 0.001));
    }
  });

  test('centerStyle survives copy and copyWith, and defaults to style', () {
    const islands = NavIslands(
      style: NavIslandStyle.dark,
      centerStyle: NavIslandStyle.bare,
    );
    expect(islands.resolvedCenterStyle, NavIslandStyle.bare);
    expect(islands.copy().centerStyle, NavIslandStyle.bare);
    expect(
      islands.copyWith(style: NavIslandStyle.light).centerStyle,
      NavIslandStyle.bare,
    );
    // Unset, the centre island is styled like the rest of the bar.
    expect(
      const NavIslands(style: NavIslandStyle.dark).resolvedCenterStyle,
      NavIslandStyle.dark,
    );
  });

  test('a theme differing only in its badge colours is a different theme', () {
    // It compared equal once, so NavIslandsTheme.updateShouldNotify decided
    // nothing had changed and the badge kept its old colour.
    const pink = Color(0xffff00ff);
    final themed = NavIslandStyleData.light.copyWith(badgeColor: pink);
    expect(themed == NavIslandStyleData.light, isFalse);
    expect(
      const NavIslandsThemeData() == NavIslandsThemeData(light: themed),
      isFalse,
    );
  });
}
