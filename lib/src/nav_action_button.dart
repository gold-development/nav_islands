import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_pressable.dart';
import 'package:nav_islands/src/nav_spinner.dart';

const Color _white = Color(0xffffffff);

/// A page's primary verb rendered as a wide filled pill in a nav island.
///
/// Pair it with a [NavWidget] of span 2–3 — the island sizes the widget to
/// `chipSize * span`, and this fills whatever box it is given. Disabled (a null
/// [onTap]) dims to half opacity.
///
/// Renders outside the owning page's subtree, so everything it needs must be
/// passed in rather than read from an inherited widget of that page.
class NavActionButton extends StatelessWidget {
  /// A muted grey, for secondary verbs (cancel).
  static const Color secondaryColor = Color(0xffe0e1e2);

  /// Label colour that reads on [secondaryColor].
  static const Color secondaryLabelColor = Color(0x99000000);

  /// Creates a primary action button.
  const NavActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.labelColor = _white,
    this.busy = false,
    this.busyIndicator,
    super.key,
  });

  /// The muted companion to a primary button: same shape, grey fill.
  const NavActionButton.secondary({
    required this.label,
    required this.onTap,
    this.busy = false,
    this.busyIndicator,
    super.key,
  }) : color = secondaryColor,
       labelColor = secondaryLabelColor;

  /// The verb shown on the pill.
  final String label;

  /// Pill fill.
  final Color color;

  /// Label colour on top of [color].
  final Color labelColor;

  /// Null disables the button.
  final VoidCallback? onTap;

  /// Swaps the label for a progress indicator and blocks taps, without dimming
  /// — the action is running, not unavailable.
  final bool busy;

  /// Shown in place of the label while [busy]. Defaults to a small spinner
  /// drawn by this package; pass your own (a Material
  /// `CircularProgressIndicator`, say) to match the rest of your app.
  final Widget? busyIndicator;

  @override
  Widget build(BuildContext context) {
    final theme = NavIslandsTheme.of(context);
    final enabled = onTap != null && !busy;

    return Opacity(
      opacity: onTap != null ? 1 : 0.5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1000),
        child: ColoredBox(
          color: color,
          child: NavPressable(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(1000),
            semanticLabel: label,
            child: Center(
              child: busy
                  ? (busyIndicator ?? NavSpinner(color: labelColor, size: 18))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.actionButtonLabelStyle.copyWith(
                          color: labelColor,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
