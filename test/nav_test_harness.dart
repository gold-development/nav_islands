import 'package:flutter/widgets.dart';
import 'package:nav_islands/nav_islands.dart';

/// A glyph that needs no icon font and no image decoder, so the package's own
/// tests stay as dependency-free as the package.
NavIcon testIcon(String key, [Color? override]) => NavIcon.custom(
  glyphKey: key,
  painter: (context, color, size) => SizedBox.square(
    dimension: size,
    child: ColoredBox(color: override ?? color),
  ),
);

/// A [NavWidget] placeholder, the simplest item to fill an island with.
NavWidget dummyItem({
  int span = 1,
  String label = 'x',
  WidgetBuilder? builder,
}) {
  return NavWidget(
    label: label,
    span: span,
    builder: builder ?? (_) => const SizedBox.shrink(),
  );
}

/// The minimum tree the bar needs: a directionality, a media query, and the
/// controller scope. No `MaterialApp` — the package doesn't depend on one.
Widget navHost({
  required NavIslandsController controller,
  required Widget child,
  NavIslandsThemeData? theme,
}) {
  Widget app = WidgetsApp(
    color: const Color(0xff000000),
    builder: (context, _) => child,
  );
  if (theme != null) {
    app = NavIslandsTheme(data: theme, child: app);
  }
  // The scope sits above the app so every route built by the navigator — not
  // just the first one — can reach the controller.
  return NavIslandsScope(controller: controller, child: app);
}

/// Like [navHost] but with a real navigator, for the route-aware behaviour of
/// [NavOverrideScope].
Widget navHostWithNavigator({
  required NavIslandsController controller,
  required GlobalKey<NavigatorState> navigatorKey,
  required Widget home,
}) {
  return NavIslandsScope(
    controller: controller,
    child: WidgetsApp(
      color: const Color(0xff000000),
      navigatorKey: navigatorKey,
      pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
          PageRouteBuilder<T>(
            settings: settings,
            pageBuilder: (context, _, _) => builder(context),
          ),
      home: home,
    ),
  );
}
