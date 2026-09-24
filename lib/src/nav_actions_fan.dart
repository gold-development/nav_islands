import 'package:flutter/widgets.dart';
import 'package:nav_islands/src/nav_default_text_style.dart';
import 'package:nav_islands/src/nav_icon.dart';
import 'package:nav_islands/src/nav_islands_controller.dart';
import 'package:nav_islands/src/nav_item.dart';
import 'package:nav_islands/src/nav_islands_layout.dart';
import 'package:nav_islands/src/nav_islands_theme.dart';
import 'package:nav_islands/src/nav_pressable.dart';

const Color _white = Color(0xffffffff);
const Color _black = Color(0xff000000);

/// Corner rounding the page shrinks to while the fan is open.
const double _pageCornerRadius = 16;

/// One entry of an [ActionsFanHost] fan: a labelled, coloured action.
@immutable
class FanAction {
  /// Creates a fan entry.
  const FanAction({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
  });

  /// The glyph shown in the coloured circle.
  final NavIcon icon;

  /// Fill of the circle.
  final Color color;

  /// Text on the pill beside the circle.
  final String label;

  /// Invoked after the fan has closed. Null for not-yet-wired placeholders.
  final VoidCallback? onTap;
}

/// Hosts a page and its quick-actions speed-dial: scales the page down on
/// black while the fan is open, shows a scrim, and fans the [actions] out of
/// the island bar's anchor chip.
///
/// The caller owns the [animation] controller and the open/close state; the
/// hosting page is expected to assert an empty island layout while [open], so
/// the bar slides away underneath the fan.
class ActionsFanHost extends StatelessWidget {
  /// Creates the host.
  const ActionsFanHost({
    required this.animation,
    required this.open,
    required this.actions,
    required this.closeIcon,
    required this.closeLabel,
    required this.closeColor,
    required this.onClose,
    required this.child,
    this.anchorId,
    this.anchorChipOffset = 0,
    super.key,
  });

  /// Drives the open/close transition, 0 → 1.
  final Animation<double> animation;

  /// Whether the fan is showing.
  final bool open;

  /// The actions, top to bottom.
  final List<FanAction> actions;

  /// Glyph of the close button sitting on the anchor chip's spot.
  final NavIcon closeIcon;

  /// Accessibility label of the close button.
  final String closeLabel;

  /// Colour of the close button.
  final Color closeColor;

  /// The id of the chip the fan opens from ([NavLink.id] or [NavAction.id]),
  /// wherever it sits in the bar — a centre island included. The close button
  /// takes the chip's exact spot.
  ///
  /// Needs the bar and this host under the same [NavIslandsScope]. When null,
  /// or when no chip with that id is on screen, the fan falls back to
  /// [anchorChipOffset].
  final String? anchorId;

  /// How many chips from the bar's right edge the fan anchors over (0 = the
  /// right-most chip), when there is no [anchorId] to find it by.
  final int anchorChipOffset;

  /// Closes the fan.
  final VoidCallback onClose;

  /// The page underneath.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final t = animation.value;
            return ColoredBox(
              color: _black,
              child: Transform.scale(
                scale: 1 - 0.08 * t,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_pageCornerRadius * t),
                  child: child,
                ),
              ),
            );
          },
          child: child,
        ),
        if (open)
          _ActionsFan(
            animation: animation,
            actions: actions,
            closeIcon: closeIcon,
            closeLabel: closeLabel,
            closeColor: closeColor,
            anchorId: anchorId,
            anchorChipOffset: anchorChipOffset,
            onClose: onClose,
          ),
      ],
    );
  }
}

/// The fan itself: scrim, staggered action pills, and the close button.
class _ActionsFan extends StatefulWidget {
  static const double _circleSize = 60;
  static const double _itemGap = 14;

  const _ActionsFan({
    required this.animation,
    required this.actions,
    required this.closeIcon,
    required this.closeLabel,
    required this.closeColor,
    required this.anchorId,
    required this.anchorChipOffset,
    required this.onClose,
  });

  final Animation<double> animation;
  final List<FanAction> actions;
  final NavIcon closeIcon;
  final String closeLabel;
  final Color closeColor;
  final String? anchorId;
  final int anchorChipOffset;
  final VoidCallback onClose;

  /// Progress of the item at [delayIndex] (0 = first to appear), staggering
  /// the raw controller value.
  static double _staggered(double t, int delayIndex) {
    final start = delayIndex * 0.08;
    return ((t - start) / (1 - start)).clamp(0.0, 1.0);
  }

  @override
  State<_ActionsFan> createState() => _ActionsFanState();
}

class _ActionsFanState extends State<_ActionsFan> {
  /// The anchor chip's global rect, taken once as the fan opens. Read then,
  /// and only then: the host asserts an empty layout while the fan is open,
  /// so from the next frame on the chip slides away — and the fan must not
  /// follow it.
  Rect? _anchor;

  @override
  void initState() {
    super.initState();
    final id = widget.anchorId;
    if (id != null) {
      _anchor = NavIslandsScope.maybeRead(context)?.anchorOf(id);
    }
  }

  /// Where the fan sits within a host of [size]: the close button's centre on
  /// the anchor, and the labels on whichever side has the room.
  _FanPlacement _placement(BuildContext context, Size size) {
    const half = BottomNavTokens.maxChip / 2;
    final anchor = _anchor;
    // The host stack, laid out and painted before the fan opened, so its
    // global position is known.
    final host = context.findAncestorRenderObjectOfType<RenderBox>();
    if (anchor != null && host != null && host.hasSize) {
      final centre = host.globalToLocal(anchor.center);
      final bottom = size.height - centre.dy - half;
      // Labels run towards the middle of the screen: to the left of a chip on
      // the right half (the centre included), to the right of one on the
      // left half — where they would otherwise run off the edge.
      if (centre.dx < size.width / 2) {
        return _FanPlacement.labelsRight(
          left: centre.dx - half,
          bottom: bottom,
        );
      }
      return _FanPlacement.labelsLeft(
        right: size.width - centre.dx - half,
        bottom: bottom,
      );
    }
    // No chip to find: count chips from the bar's right edge instead — the
    // bar's edge insets plus the chip's centring within the pill, shifted
    // left per chip offset.
    return _FanPlacement.labelsLeft(
      right:
          BottomNavTokens.barPaddingX +
          BottomNavTokens.islandPaddingX +
          widget.anchorChipOffset *
              (BottomNavTokens.maxChip + BottomNavTokens.chipGap),
      bottom:
          MediaQuery.viewPaddingOf(context).bottom +
          BottomNavTokens.barPaddingY +
          (BottomNavTokens.navHeight - BottomNavTokens.maxChip) / 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    final actions = widget.actions;
    final onClose = widget.onClose;

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) => _buildFan(
          animation,
          actions,
          onClose,
          _placement(context, constraints.biggest),
        ),
      ),
    );
  }

  Widget _buildFan(
    Animation<double> animation,
    List<FanAction> actions,
    VoidCallback onClose,
    _FanPlacement placement,
  ) {
    final closeIcon = widget.closeIcon;
    final closeLabel = widget.closeLabel;
    final closeColor = widget.closeColor;

    return NavDefaultTextStyle(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;

          return Stack(
            children: <Widget>[
              // Scrim: tap anywhere to close.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose,
                  child: ColoredBox(color: _black.withValues(alpha: 0.35 * t)),
                ),
              ),
              Positioned(
                left: placement.left,
                right: placement.right,
                bottom: placement.bottom,
                child: Column(
                  // The circles line up above the close button, on the side
                  // away from the labels.
                  crossAxisAlignment: placement.labelsOnRight
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (final (index, action) in actions.indexed) ...[
                      _FanItem(
                        action: action,
                        labelOnRight: placement.labelsOnRight,
                        // Bottom-most pill pops first.
                        progress: _ActionsFan._staggered(
                          t,
                          actions.length - 1 - index,
                        ),
                        onClose: onClose,
                      ),
                      const SizedBox(height: _ActionsFan._itemGap),
                    ],
                    _FanCloseButton(
                      progress: t,
                      icon: closeIcon,
                      label: closeLabel,
                      color: closeColor,
                      onTap: onClose,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Where an open fan sits: exactly one of [left] and [right] is set, the side
/// it is pinned to, and the labels run away from that side.
class _FanPlacement {
  const _FanPlacement.labelsLeft({
    required double this.right,
    required this.bottom,
  }) : left = null,
       labelsOnRight = false;

  const _FanPlacement.labelsRight({
    required double this.left,
    required this.bottom,
  }) : right = null,
       labelsOnRight = true;

  final double? left;
  final double? right;
  final double bottom;
  final bool labelsOnRight;
}

class _FanItem extends StatelessWidget {
  const _FanItem({
    required this.action,
    required this.labelOnRight,
    required this.progress,
    required this.onClose,
  });

  final FanAction action;
  final bool labelOnRight;
  final double progress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = NavIslandsTheme.of(context);
    final eased = Curves.easeOutBack.transform(progress);

    return Opacity(
      opacity: Curves.easeOut.transform(progress),
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 24),
        child: NavPressable(
          semanticLabel: action.label,
          onTap: () {
            onClose();
            action.onTap?.call();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            // Mirrored for a fan opening from the left half: circle first, so
            // the label runs towards the middle of the screen.
            textDirection: labelOnRight ? TextDirection.rtl : TextDirection.ltr,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: theme.fanPillColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(action.label, style: theme.fanLabelStyle),
              ),
              const SizedBox(width: 12),
              Container(
                width: _ActionsFan._circleSize,
                height: _ActionsFan._circleSize,
                decoration: BoxDecoration(
                  color: action.color,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  // Match the island chips' glyph proportion (~65%).
                  child: action.icon.build(
                    context,
                    _white,
                    _ActionsFan._circleSize * 0.65,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The close button sitting exactly where the anchor chip was.
class _FanCloseButton extends StatelessWidget {
  const _FanCloseButton({
    required this.progress,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final double progress;
  final NavIcon icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = NavIslandsTheme.of(context);
    final eased = Curves.easeOut.transform(progress);

    return Opacity(
      opacity: eased,
      // Quarter-turn in as it appears, giving the plus-to-cross feel.
      child: Transform.rotate(
        angle: (1 - eased) * -0.785,
        child: NavPressable(
          onTap: onTap,
          shape: BoxShape.circle,
          semanticLabel: label,
          child: Container(
            width: BottomNavTokens.maxChip,
            height: BottomNavTokens.maxChip,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: icon.build(context, _white, 28)),
          ),
        ),
      ),
    );
  }
}
