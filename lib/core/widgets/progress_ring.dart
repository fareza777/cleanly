import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cincin progres dengan ujung membulat. Dipakai untuk countdown sesi dan
/// ringkasan streak supaya keduanya terasa satu bahasa visual.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 220,
    this.strokeWidth = 12,
    this.color,
    this.trackColor,
    this.startAtTop = true,
  });

  /// 0–1; nilai di luar rentang dipangkas.
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? trackColor;
  final bool startAtTop;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              color: color ?? colors.primary,
              trackColor: trackColor ?? colors.surfaceMuted,
              startAtTop: startAtTop,
            ),
            child: Center(child: child),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.startAtTop,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final bool startAtTop;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final startAngle = startAtTop ? -math.pi / 2 : math.pi;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [color, Color.lerp(color, Colors.white, 0.28) ?? color],
        transform: GradientRotation(startAngle),
      ).createShader(rect);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// Bilah progres datar dengan ujung membulat, untuk daftar tugas.
class FlatProgressBar extends StatelessWidget {
  const FlatProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.color,
  });

  final double progress;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.cleanly;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => LinearProgressIndicator(
          value: value,
          minHeight: height,
          color: color ?? colors.primary,
          backgroundColor: colors.surfaceMuted,
        ),
      ),
    );
  }
}
