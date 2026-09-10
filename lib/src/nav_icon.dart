import 'package:flutter/widgets.dart';

/// Paints a nav glyph at [size], tinted [color].
///
/// The bar decides the colour (default, accented, white on a filled chip) and
/// the size (a fraction of the chip), so a painter should honour both rather
/// than baking in its own.
typedef NavIconPainter =
    Widget Function(BuildContext context, Color color, double size);

/// The glyph of a nav item.
///
/// [NavIcon.material] wraps a Material [IconData]. [NavIcon.custom] takes any
/// painter — an svg, a bitmap, an animation — which is what keeps this package
/// free of an image-format dependency: bring your own renderer.
///
/// ```dart
/// NavIcon.custom(
///   glyphKey: path,
///   painter: (context, color, size) => SvgPicture.asset(
///     path,
///     width: size,
///     height: size,
///     colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
///   ),
/// )
/// ```
@immutable
class NavIcon {
  /// A Material icon.
  const NavIcon.material(IconData this.data) : painter = null, glyphKey = null;

  /// A caller-painted glyph. [glyphKey] identifies it — two icons with the
  /// same key are treated as the same glyph, so a chip that keeps its glyph
  /// across a page change morphs in place instead of sliding out and back in.
  const NavIcon.custom({
    required NavIconPainter this.painter,
    required String this.glyphKey,
  }) : data = null;

  /// The Material icon, for [NavIcon.material].
  final IconData? data;

  /// The painter, for [NavIcon.custom].
  final NavIconPainter? painter;

  /// Glyph identity, for [NavIcon.custom].
  final String? glyphKey;

  /// Stable identity of this glyph, used to key morph animations.
  String get identity =>
      data != null ? 'material:${data!.codePoint}' : 'custom:$glyphKey';

  /// Paints the glyph.
  Widget build(BuildContext context, Color color, double size) {
    final painter = this.painter;
    if (painter != null) {
      return painter(context, color, size);
    }
    return Icon(data, size: size, color: color);
  }
}
