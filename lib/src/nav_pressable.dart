import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';

/// How quickly the press wash fades in and out.
const Duration _pressDuration = Duration(milliseconds: 90);

/// A tappable surface with this package's own press feedback: a wash over the
/// child while it is held, plus a selection haptic on tap.
///
/// This is what stands in for Material's ink ripple — it keeps the bar usable
/// in apps that don't ship Material at all, and it needs no [Material]
/// ancestor, which matters because the bar and the actions fan render outside
/// the owning page's subtree.
class NavPressable extends StatefulWidget {
  /// Creates a pressable surface.
  const NavPressable({
    required this.onTap,
    required this.child,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.overlayColor,
    this.semanticLabel,
    this.selected = false,
    super.key,
  });

  /// Runs on tap. A null callback disables both the gesture and the feedback.
  final VoidCallback? onTap;

  /// Corner rounding of the wash, for [BoxShape.rectangle].
  final BorderRadius? borderRadius;

  /// Shape of the wash.
  final BoxShape shape;

  /// Wash colour. Falls back to [NavIslandsThemeData.pressedOverlayColor].
  final Color? overlayColor;

  /// Accessibility label; also marks this a button to screen readers.
  final String? semanticLabel;

  /// Reported to screen readers as the selected state.
  final bool selected;

  /// The surface being pressed.
  final Widget child;

  @override
  State<NavPressable> createState() => _NavPressableState();
}

class _NavPressableState extends State<NavPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final overlay =
        widget.overlayColor ?? NavIslandsTheme.of(context).pressedOverlayColor;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Semantics(
      button: widget.semanticLabel != null,
      enabled: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _pressed ? 1 : 0,
                  duration: reduceMotion ? Duration.zero : _pressDuration,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: overlay,
                      shape: widget.shape,
                      borderRadius: widget.shape == BoxShape.rectangle
                          ? widget.borderRadius
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
