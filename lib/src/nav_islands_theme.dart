import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_item.dart';

/// The default badge fill: legible on both the light and the dark pill.
const Color _badgeRed = Color(0xffd32f2f);

const Color _white = Color(0xffffffff);
const Color _black = Color(0xff000000);

/// The colours of one island style — the light pills of a light page, or the
/// dark pills of a dark one. A [NavIslandsThemeData] holds both and picks
/// between them per [NavIslandStyle].
@immutable
class NavIslandStyleData {
  /// Creates a style.
  const NavIslandStyleData({
    required this.pillColor,
    required this.borderColor,
    required this.iconColor,
    required this.indicatorColor,
    this.badgeColor = _badgeRed,
    this.badgeTextColor = _white,
  });

  /// Fill of the island pill.
  final Color pillColor;

  /// Hairline around the island pill.
  final Color borderColor;

  /// Default glyph colour of a chip that isn't filled or accented.
  final Color iconColor;

  /// Fill of the selection indicator sliding behind the chips.
  final Color indicatorColor;

  /// Fill of a chip's count badge. Defaults to a red that reads as "unread"
  /// on either pill; give it your own error colour to match a design system.
  final Color badgeColor;

  /// Text colour inside the badge.
  final Color badgeTextColor;

  /// The default light style: a near-white pill on a light page.
  static const NavIslandStyleData light = NavIslandStyleData(
    pillColor: _white,
    borderColor: Color(0x1f000000),
    iconColor: Color(0xde000000),
    indicatorColor: Color(0x14000000),
  );

  /// The default dark style: a charcoal pill on a dark page.
  static const NavIslandStyleData dark = NavIslandStyleData(
    pillColor: Color(0xff454545),
    borderColor: Color(0x1fffffff),
    iconColor: _white,
    indicatorColor: Color(0x1fffffff),
  );

  /// The bare style: nothing drawn. The island is a transparent slot, so the
  /// pill, its hairline and the selection wash are all fully transparent; a
  /// badge on a bare island still needs a fill, so it keeps the default red.
  static const NavIslandStyleData bare = NavIslandStyleData(
    pillColor: Color(0x00000000),
    borderColor: Color(0x00000000),
    iconColor: Color(0xde000000),
    indicatorColor: Color(0x00000000),
  );

  /// A copy with the given fields replaced.
  NavIslandStyleData copyWith({
    Color? pillColor,
    Color? borderColor,
    Color? iconColor,
    Color? indicatorColor,
    Color? badgeColor,
    Color? badgeTextColor,
  }) => NavIslandStyleData(
    pillColor: pillColor ?? this.pillColor,
    borderColor: borderColor ?? this.borderColor,
    iconColor: iconColor ?? this.iconColor,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    badgeColor: badgeColor ?? this.badgeColor,
    badgeTextColor: badgeTextColor ?? this.badgeTextColor,
  );

  @override
  bool operator ==(Object other) =>
      other is NavIslandStyleData &&
      other.pillColor == pillColor &&
      other.borderColor == borderColor &&
      other.iconColor == iconColor &&
      other.indicatorColor == indicatorColor &&
      // The badge colours belong here: a theme that differs only in them is a
      // different theme, and leaving them out let NavIslandsTheme decide
      // nothing had changed and skip the rebuild.
      other.badgeColor == badgeColor &&
      other.badgeTextColor == badgeTextColor;

  @override
  int get hashCode => Object.hash(
    pillColor,
    borderColor,
    iconColor,
    indicatorColor,
    badgeColor,
    badgeTextColor,
  );
}

/// Everything the bar needs to paint itself. The defaults stand on their own —
/// the package renders correctly with no theme at all — so a host only supplies
/// this to match its own design system.
///
/// In a Material app, build one from the [ColorScheme] and hand it to a
/// [NavIslandsTheme] above the bar.
@immutable
class NavIslandsThemeData {
  /// Creates a theme.
  const NavIslandsThemeData({
    this.light = NavIslandStyleData.light,
    this.dark = NavIslandStyleData.dark,
    this.bare = NavIslandStyleData.bare,
    this.shadowColor = _black,
    this.pressedOverlayColor = const Color(0x1f000000),
    this.actionButtonLabelStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
    ),
    this.fanLabelStyle = const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Color(0xff333333),
    ),
    this.fanPillColor = _white,
  });

  /// Colours used while a page asserts [NavIslandStyle.light].
  final NavIslandStyleData light;

  /// Colours used while a page asserts [NavIslandStyle.dark].
  final NavIslandStyleData dark;

  /// Colours used while an island is [NavIslandStyle.bare] — everything the
  /// island itself draws is transparent, so only what the item draws shows.
  final NavIslandStyleData bare;

  /// Base colour of the pill's contact and ambient shadows (alpha is applied
  /// by the bar).
  final Color shadowColor;

  /// Wash drawn over a chip while it is held down — this package's stand-in
  /// for a Material ink ripple, so it needs no Material ancestor.
  final Color pressedOverlayColor;

  /// Label style of a [NavActionButton]. Its colour is overridden per button.
  final TextStyle actionButtonLabelStyle;

  /// Label style of a quick-actions fan entry.
  final TextStyle fanLabelStyle;

  /// Pill colour behind a quick-actions fan label.
  final Color fanPillColor;

  /// The colours for [style].
  NavIslandStyleData styleFor(NavIslandStyle style) => switch (style) {
    NavIslandStyle.light => light,
    NavIslandStyle.dark => dark,
    NavIslandStyle.bare => bare,
  };

  /// A copy with the given fields replaced.
  NavIslandsThemeData copyWith({
    NavIslandStyleData? light,
    NavIslandStyleData? dark,
    NavIslandStyleData? bare,
    Color? shadowColor,
    Color? pressedOverlayColor,
    TextStyle? actionButtonLabelStyle,
    TextStyle? fanLabelStyle,
    Color? fanPillColor,
  }) => NavIslandsThemeData(
    light: light ?? this.light,
    dark: dark ?? this.dark,
    bare: bare ?? this.bare,
    shadowColor: shadowColor ?? this.shadowColor,
    pressedOverlayColor: pressedOverlayColor ?? this.pressedOverlayColor,
    actionButtonLabelStyle:
        actionButtonLabelStyle ?? this.actionButtonLabelStyle,
    fanLabelStyle: fanLabelStyle ?? this.fanLabelStyle,
    fanPillColor: fanPillColor ?? this.fanPillColor,
  );

  // Value equality so a host that rebuilds an identical theme every frame
  // doesn't force the whole bar to rebuild with it.
  @override
  bool operator ==(Object other) =>
      other is NavIslandsThemeData &&
      other.light == light &&
      other.dark == dark &&
      other.bare == bare &&
      other.shadowColor == shadowColor &&
      other.pressedOverlayColor == pressedOverlayColor &&
      other.actionButtonLabelStyle == actionButtonLabelStyle &&
      other.fanLabelStyle == fanLabelStyle &&
      other.fanPillColor == fanPillColor;

  @override
  int get hashCode => Object.hash(
    light,
    dark,
    bare,
    shadowColor,
    pressedOverlayColor,
    actionButtonLabelStyle,
    fanLabelStyle,
    fanPillColor,
  );
}

/// Supplies a [NavIslandsThemeData] to the bar. Optional — without one, the
/// defaults in [NavIslandsThemeData] apply.
class NavIslandsTheme extends InheritedWidget {
  /// Creates the theme scope.
  const NavIslandsTheme({required this.data, required super.child, super.key});

  /// The colours and text styles below this scope.
  final NavIslandsThemeData data;

  /// The nearest theme, or the defaults when there is none.
  static NavIslandsThemeData of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NavIslandsTheme>();
    return scope?.data ?? const NavIslandsThemeData();
  }

  @override
  bool updateShouldNotify(NavIslandsTheme oldWidget) => data != oldWidget.data;
}
