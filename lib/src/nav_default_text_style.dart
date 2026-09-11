import 'package:flutter/widgets.dart';

/// A sane ambient text style for anything this package paints.
///
/// The bar and the actions fan are mounted above the page rather than inside
/// it, which puts them outside any Material ancestor. The ambient
/// [DefaultTextStyle] there is the framework's error style, which paints a
/// yellow double underline under every label — the package depends on
/// `widgets.dart` alone and will not pull in Material just to inherit a
/// reasonable default, so it supplies one itself.
///
/// Item styles merge over this, and a style that leaves `decoration` null — as
/// every style in this package and every consumer override of them does —
/// inherits the [TextDecoration.none] below instead of the underline.
///
/// Deliberately not exported: hosts get this by using the bar or the fan.
class NavDefaultTextStyle extends StatelessWidget {
  /// Creates the wrapper.
  const NavDefaultTextStyle({required this.child, super.key});

  /// The subtree to supply a default style to.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        decoration: TextDecoration.none,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: Color(0xff333333),
      ),
      child: child,
    );
  }
}
