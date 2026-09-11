import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_icon.dart';

/// Maximum number of items allowed across the three islands combined.
const int kMaxNavItems = 8;

/// One entry in a bottom-nav island: a [NavLink] navigates / switches section, a
/// [NavAction] runs a callback (e.g. opens the actions sheet), and a [NavWidget]
/// renders a self-contained widget in place of a plain icon chip (e.g. a badge
/// or counter). Every item declares how many [span] cells it occupies so wider
/// widgets can claim 2–3 slots instead of 1.
sealed class NavItem {
  /// Creates a nav item.
  const NavItem({required this.label, this.span = 1})
    : assert(
        span >= 1 && span <= kMaxNavItems,
        'span must be between 1 and $kMaxNavItems',
      );

  /// Accessibility label, and the tooltip a host may choose to show.
  final String label;

  /// How many chip cells this item occupies in its island. 1 is a single
  /// chip; more makes a wider one, up to the whole bar.
  ///
  /// A cell never grows past [BottomNavTokens.maxChip] however much room the
  /// screen has, so span is the only way to make a chip wide enough to carry
  /// a sentence. It is bounded by [kMaxNavItems] — the bar's own cell budget
  /// — rather than by a smaller number of its own: an island holding one wide
  /// primary action is a normal thing to want, and a cap of 3 meant a label
  /// of about 130 pt, which is a couple of words.
  final int span;
}

/// A destination chip. Derives its active state by comparing [id] against the
/// bar's current section id.
class NavLink extends NavItem {
  /// Creates a destination chip.
  const NavLink({
    required this.id,
    required this.icon,
    required super.label,
    required this.onTap,
    this.accent,
    this.badgeCount = 0,
    super.span,
  });

  /// Stable id used to mark this link active (e.g. `'overview'`, `'menu'`).
  final String id;

  /// The glyph shown in the chip.
  final NavIcon icon;

  /// Runs when the chip is tapped.
  final VoidCallback onTap;

  /// Colour of the selection indicator while this link is active. Falls back to
  /// the default indicator colour when null.
  final Color? accent;

  /// Unread items behind this entry, drawn as a count on the chip. `0` draws
  /// nothing, so a caller can pass a count straight through without writing a
  /// conditional around the item.
  ///
  /// The badge is decorative: it carries no semantics of its own, because the
  /// chip is already labelled and a bare number read out beside it tells a
  /// screen-reader user nothing useful. Where the count matters to them, put it
  /// in [label] — "Alerts, 3 unread".
  final int badgeCount;
}

/// An action chip. Runs [onTap] rather than navigating; its active state comes
/// from the optional [isActive] callback (e.g. active while a sheet is open).
class NavAction extends NavItem {
  /// Creates an action chip.
  const NavAction({
    required super.label,
    required this.onTap,
    required this.icon,
    this.isActive,
    this.tint,
    this.accent,
    this.badgeCount = 0,
    super.span,
  });

  /// The glyph shown in the chip.
  final NavIcon icon;

  /// Runs when the chip is tapped.
  final VoidCallback onTap;

  /// Whether the chip currently reads as active (e.g. while its sheet is open).
  final bool Function()? isActive;

  /// Optional accent for the icon (e.g. the section-coloured add button) and for
  /// the selection indicator while this action is active. Falls back to the
  /// theme's hint colour (icon) / default indicator colour when null.
  final Color? tint;

  /// Colour of the selection indicator while this action is active (e.g. a
  /// toggle chip lighting up in its section colour), without [tint]'s filled
  /// chip styling. Falls back to [tint], then the default indicator colour.
  final Color? accent;

  /// Unread items behind this action, drawn as a count on the chip. See
  /// [NavLink.badgeCount] — same rule, including that it is decorative.
  final int badgeCount;
}

/// A self-contained widget rendered in place of a chip, for buttons too rich for
/// an icon (badge, running total, …). Sized to `chip * span`.
class NavWidget extends NavItem {
  /// Creates a widget item.
  const NavWidget({required super.label, required this.builder, super.span});

  /// Builds the widget rendered in the chip's place.
  final WidgetBuilder builder;
}

/// How a side island aligns within its half of the bar: hugging the centre
/// island (the default) or flush with its screen edge.
enum NavIslandAlignment {
  /// Hug the centre island.
  center,

  /// Sit flush with the screen edge.
  edge,
}

/// Visual style of the island pills, asserted per page like the layout
/// itself: light pills for light pages, dark pills for dark ones.
enum NavIslandStyle {
  /// Light pills, for light pages.
  light,

  /// Dark pills, for dark pages.
  dark,

  /// No pill at all: no fill, border, shadow or selection wash, and nothing
  /// clipped. For an island that is a control in its own right — a single
  /// [NavWidget] that brings its own shape and may stand taller than the pill,
  /// like a raised primary button sitting in the middle of the bar.
  bare,
}

/// The three islands of the bottom bar as one layout object — used to seed the
/// default layout re-applied on every navigation.
@immutable
class NavIslands {
  /// Creates an island layout.
  const NavIslands({
    this.left = const <NavItem>[],
    this.center = const <NavItem>[],
    this.right = const <NavItem>[],
    this.leftAlignment = NavIslandAlignment.center,
    this.rightAlignment = NavIslandAlignment.center,
    this.style = NavIslandStyle.light,
    this.centerStyle,
    this.activeId,
  });

  /// The resting layout: no islands at all.
  const NavIslands.empty()
    : left = const <NavItem>[],
      center = const <NavItem>[],
      right = const <NavItem>[],
      leftAlignment = NavIslandAlignment.center,
      rightAlignment = NavIslandAlignment.center,
      style = NavIslandStyle.light,
      centerStyle = null,
      activeId = null;

  /// Items in the left island.
  final List<NavItem> left;

  /// Items in the centre island.
  final List<NavItem> center;

  /// Items in the right island.
  final List<NavItem> right;

  /// Where the left island sits within the space left of the centre island.
  final NavIslandAlignment leftAlignment;

  /// Where the right island sits within the space right of the centre island.
  final NavIslandAlignment rightAlignment;

  /// Pill styling for the current page (light or dark chrome).
  final NavIslandStyle style;

  /// Styling of the centre island when it differs from [style] — typically
  /// [NavIslandStyle.bare] for a centre island that is a button of its own.
  /// Null inherits [style].
  final NavIslandStyle? centerStyle;

  /// Section id used to mark the matching [NavLink] active.
  final String? activeId;

  /// Total item count across all three islands — capped at [kMaxNavItems].
  int get totalItems => left.length + center.length + right.length;

  /// The style the centre island renders with ([centerStyle] or [style]).
  NavIslandStyle get resolvedCenterStyle => centerStyle ?? style;

  /// A defensive copy, so overrides can't mutate the stored layouts.
  NavIslands copy() => NavIslands(
    left: List<NavItem>.of(left),
    center: List<NavItem>.of(center),
    right: List<NavItem>.of(right),
    leftAlignment: leftAlignment,
    rightAlignment: rightAlignment,
    style: style,
    centerStyle: centerStyle,
    activeId: activeId,
  );

  /// A copy with the given fields replaced.
  NavIslands copyWith({
    List<NavItem>? left,
    List<NavItem>? center,
    List<NavItem>? right,
    NavIslandAlignment? leftAlignment,
    NavIslandAlignment? rightAlignment,
    NavIslandStyle? style,
    NavIslandStyle? centerStyle,
    String? activeId,
  }) => NavIslands(
    left: left ?? this.left,
    center: center ?? this.center,
    right: right ?? this.right,
    leftAlignment: leftAlignment ?? this.leftAlignment,
    rightAlignment: rightAlignment ?? this.rightAlignment,
    style: style ?? this.style,
    centerStyle: centerStyle ?? this.centerStyle,
    activeId: activeId ?? this.activeId,
  );
}
