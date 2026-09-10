import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A small indeterminate spinner, drawn here rather than borrowed from
/// Material so a busy [NavActionButton] needs no Material ancestor. Hosts that
/// have their own progress indicator can pass it instead.
class NavSpinner extends StatefulWidget {
  /// Creates a spinner.
  const NavSpinner({
    required this.color,
    this.size = 18,
    this.strokeWidth = 2.5,
    super.key,
  });

  /// Arc colour.
  final Color color;

  /// Edge length of the square the arc is drawn in.
  final double size;

  /// Thickness of the arc.
  final double strokeWidth;

  @override
  State<NavSpinner> createState() => _NavSpinnerState();
}

class _NavSpinnerState extends State<NavSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SpinnerPainter(
            turns: _controller.value,
            color: widget.color,
            strokeWidth: widget.strokeWidth,
          ),
        ),
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  const _SpinnerPainter({
    required this.turns,
    required this.color,
    required this.strokeWidth,
  });

  final double turns;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Offset.zero & size;
    canvas.drawArc(
      rect.deflate(strokeWidth / 2),
      turns * 2 * math.pi,
      // Three-quarters of the circle, the familiar indeterminate arc.
      1.5 * math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.turns != turns ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}
