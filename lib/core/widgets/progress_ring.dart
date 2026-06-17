import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A circular progress ring with a track and a gradient sweep, plus an
/// optional centered child (e.g. a percentage). Purely presentational.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    required this.color2,
    this.size = 64,
    this.stroke = 7,
    this.trackColor,
    this.child,
  });

  /// 0.0 - 1.0
  final double value;
  final Color color;
  final Color color2;
  final double size;
  final double stroke;
  final Color? trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          value: value.clamp(0.0, 1.0),
          color: color,
          color2: color2,
          stroke: stroke,
          trackColor: trackColor ??
              Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.16),
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.color2,
    required this.stroke,
    required this.trackColor,
  });

  final double value;
  final Color color;
  final Color color2;
  final double stroke;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (value <= 0) return;

    final sweep = 2 * math.pi * value;
    const start = -math.pi / 2;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + 2 * math.pi,
        colors: [color, color2, color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      start,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.color != color ||
      old.color2 != color2 ||
      old.stroke != stroke ||
      old.trackColor != trackColor;
}
