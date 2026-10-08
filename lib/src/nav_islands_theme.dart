import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
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

/// How long the bar's movements take. Every duration already drops to zero
/// when the platform asks for reduced motion; these are the full-motion ones.
@immutable
class NavIslandsMotion {
  /// Creates a motion set; the defaults are the package's own.
  const NavIslandsMotion({
    this.island = BottomNavTokens.islandAnimDuration,
    this.selection = BottomNavTokens.selectionAnimDuration,
    this.chipMorph = BottomNavTokens.chipMorphDuration,
    this.press = const Duration(milliseconds: 90),
    this.spinnerPeriod = const Duration(milliseconds: 1100),
    this.fanStagger = 0.08,
  });

  /// An island's enter/leave slide and fade.
  final Duration island;

  /// The selection indicator's stretch-and-retract move between chips.
  final Duration selection;

  /// A chip morphing in place into the next page's item.
  final Duration chipMorph;

  /// The press wash fading in and out.
  final Duration press;

  /// One full turn of [NavSpinner].
  final Duration spinnerPeriod;

  /// How far into the fan's opening each further entry starts, as a fraction
  /// of the fan's own animation (0 opens them all at once).
  final double fanStagger;

  /// A copy with the given fields replaced.
  NavIslandsMotion copyWith({
    Duration? island,
    Duration? selection,
    Duration? chipMorph,
    Duration? press,
    Duration? spinnerPeriod,
    double? fanStagger,
  }) => NavIslandsMotion(
    island: island ?? this.island,
    selection: selection ?? this.selection,
    chipMorph: chipMorph ?? this.chipMorph,
    press: press ?? this.press,
    spinnerPeriod: spinnerPeriod ?? this.spinnerPeriod,
    fanStagger: fanStagger ?? this.fanStagger,
  );

  @override
  bool operator ==(Object other) =>
      other is NavIslandsMotion &&
      other.island == island &&
      other.selection == selection &&
      other.chipMorph == chipMorph &&
      other.press == press &&
      other.spinnerPeriod == spinnerPeriod &&
      other.fanStagger == fanStagger;

  @override
  int get hashCode => Object.hash(
    island,
    selection,
    chipMorph,
    press,
    spinnerPeriod,
    fanStagger,
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
    this.fanCircleSize = 60,
    this.fanItemGap = 14,
    this.fanEdgeInset = 16,
    this.fanLabelMaxLines = 2,
    this.defaultTextStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: Color(0xff333333),
    ),
    this.islandShadows,
    this.fanShadows,
    this.fanLabelShadows,
    this.fanLabelPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 9,
    ),
    this.fanLabelRadius = 24,
    this.fanLabelGap = 12,
    this.fanCloseIconSize = 28,
    this.fanScrimOpacity = 0.35,
    this.fanPageShrink = 0.08,
    this.fanPageCornerRadius = 16,
    this.actionButtonPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.actionButtonSpinnerSize = 18,
    this.badgeTextStyle = const TextStyle(
      fontWeight: FontWeight.w700,
      height: 1,
      fontSize: 10,
    ),
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 4),
    this.motion = const NavIslandsMotion(),
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

  /// Diameter of a fan entry's coloured circle; its glyph is drawn at 65% of
  /// it, the island chips' proportion.
  final double fanCircleSize;

  /// Vertical space between fan entries, and above the close button.
  final double fanItemGap;

  /// How close a fan label may come to the screen edge it runs towards. A
  /// label that would come closer wraps instead of running off.
  final double fanEdgeInset;

  /// Lines a fan label may wrap onto before it is ellipsised.
  final int fanLabelMaxLines;

  /// Base style for any text the package paints, under the bar and the fan
  /// (which sit outside the page's Material, if it has one). Its decoration is
  /// always none.
  final TextStyle defaultTextStyle;

  /// Shadows under an island pill. Null: a contact and an ambient shadow in
  /// [shadowColor].
  final List<BoxShadow>? islandShadows;

  /// Shadows under a fan entry's circle and the close button. Null: one soft
  /// shadow in [shadowColor].
  final List<BoxShadow>? fanShadows;

  /// Shadows under a fan label's pill. Null: one soft shadow in [shadowColor].
  final List<BoxShadow>? fanLabelShadows;

  /// Padding inside a fan label's pill.
  final EdgeInsets fanLabelPadding;

  /// Corner radius of a fan label's pill.
  final double fanLabelRadius;

  /// Space between a fan label and its circle.
  final double fanLabelGap;

  /// Glyph size in the fan's close button.
  final double fanCloseIconSize;

  /// Opacity of the black scrim behind an open fan.
  final double fanScrimOpacity;

  /// How much the page underneath shrinks while the fan is open (0.08 is to
  /// 92%); 0 leaves it as it is.
  final double fanPageShrink;

  /// Corner radius the page underneath takes on while the fan is open.
  final double fanPageCornerRadius;

  /// Padding around a [NavActionButton]'s label.
  final EdgeInsets actionButtonPadding;

  /// Size of a busy [NavActionButton]'s spinner.
  final double actionButtonSpinnerSize;

  /// Text style of a chip's count badge. Its colour comes from
  /// [NavIslandStyleData.badgeTextColor].
  final TextStyle badgeTextStyle;

  /// Padding inside a count badge, around a number of two digits or more.
  final EdgeInsets badgePadding;

  /// How long the bar's movements take.
  final NavIslandsMotion motion;

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
    double? fanCircleSize,
    double? fanItemGap,
    double? fanEdgeInset,
    int? fanLabelMaxLines,
    TextStyle? defaultTextStyle,
    List<BoxShadow>? islandShadows,
    List<BoxShadow>? fanShadows,
    List<BoxShadow>? fanLabelShadows,
    EdgeInsets? fanLabelPadding,
    double? fanLabelRadius,
    double? fanLabelGap,
    double? fanCloseIconSize,
    double? fanScrimOpacity,
    double? fanPageShrink,
    double? fanPageCornerRadius,
    EdgeInsets? actionButtonPadding,
    double? actionButtonSpinnerSize,
    TextStyle? badgeTextStyle,
    EdgeInsets? badgePadding,
    NavIslandsMotion? motion,
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
    fanCircleSize: fanCircleSize ?? this.fanCircleSize,
    fanItemGap: fanItemGap ?? this.fanItemGap,
    fanEdgeInset: fanEdgeInset ?? this.fanEdgeInset,
    fanLabelMaxLines: fanLabelMaxLines ?? this.fanLabelMaxLines,
    defaultTextStyle: defaultTextStyle ?? this.defaultTextStyle,
    islandShadows: islandShadows ?? this.islandShadows,
    fanShadows: fanShadows ?? this.fanShadows,
    fanLabelShadows: fanLabelShadows ?? this.fanLabelShadows,
    fanLabelPadding: fanLabelPadding ?? this.fanLabelPadding,
    fanLabelRadius: fanLabelRadius ?? this.fanLabelRadius,
    fanLabelGap: fanLabelGap ?? this.fanLabelGap,
    fanCloseIconSize: fanCloseIconSize ?? this.fanCloseIconSize,
    fanScrimOpacity: fanScrimOpacity ?? this.fanScrimOpacity,
    fanPageShrink: fanPageShrink ?? this.fanPageShrink,
    fanPageCornerRadius: fanPageCornerRadius ?? this.fanPageCornerRadius,
    actionButtonPadding: actionButtonPadding ?? this.actionButtonPadding,
    actionButtonSpinnerSize:
        actionButtonSpinnerSize ?? this.actionButtonSpinnerSize,
    badgeTextStyle: badgeTextStyle ?? this.badgeTextStyle,
    badgePadding: badgePadding ?? this.badgePadding,
    motion: motion ?? this.motion,
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
      other.fanPillColor == fanPillColor &&
      other.fanCircleSize == fanCircleSize &&
      other.fanItemGap == fanItemGap &&
      other.fanEdgeInset == fanEdgeInset &&
      other.fanLabelMaxLines == fanLabelMaxLines &&
      other.defaultTextStyle == defaultTextStyle &&
      _listEquals(other.islandShadows, islandShadows) &&
      _listEquals(other.fanShadows, fanShadows) &&
      _listEquals(other.fanLabelShadows, fanLabelShadows) &&
      other.fanLabelPadding == fanLabelPadding &&
      other.fanLabelRadius == fanLabelRadius &&
      other.fanLabelGap == fanLabelGap &&
      other.fanCloseIconSize == fanCloseIconSize &&
      other.fanScrimOpacity == fanScrimOpacity &&
      other.fanPageShrink == fanPageShrink &&
      other.fanPageCornerRadius == fanPageCornerRadius &&
      other.actionButtonPadding == actionButtonPadding &&
      other.actionButtonSpinnerSize == actionButtonSpinnerSize &&
      other.badgeTextStyle == badgeTextStyle &&
      other.badgePadding == badgePadding &&
      other.motion == motion;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    light,
    dark,
    bare,
    shadowColor,
    pressedOverlayColor,
    actionButtonLabelStyle,
    fanLabelStyle,
    fanPillColor,
    fanCircleSize,
    fanItemGap,
    fanEdgeInset,
    fanLabelMaxLines,
    defaultTextStyle,
    Object.hashAll(islandShadows ?? const <BoxShadow>[]),
    Object.hashAll(fanShadows ?? const <BoxShadow>[]),
    Object.hashAll(fanLabelShadows ?? const <BoxShadow>[]),
    fanLabelPadding,
    fanLabelRadius,
    fanLabelGap,
    fanCloseIconSize,
    fanScrimOpacity,
    fanPageShrink,
    fanPageCornerRadius,
    actionButtonPadding,
    actionButtonSpinnerSize,
    badgeTextStyle,
    badgePadding,
    motion,
  ]);
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
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
