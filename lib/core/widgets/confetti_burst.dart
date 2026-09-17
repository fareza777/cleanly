import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ledakan confetti sekali jalan, digambar sendiri tanpa paket tambahan
/// sehingga tetap ringan dan bekerja offline.
///
/// Hormati pengaturan "kurangi animasi": bila aktif, widget ini tidak
/// menampilkan apa pun.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({
    super.key,
    this.pieces = 64,
    this.duration = const Duration(milliseconds: 2400),
    this.origin = const Alignment(0, 0.15),
    this.seed = 7,
  });

  final int pieces;
  final Duration duration;
  final Alignment origin;
  final int seed;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final List<_Piece> _pieces = _buildPieces();

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Piece> _buildPieces() {
    final random = math.Random(widget.seed);
    return [
      for (var i = 0; i < widget.pieces; i++)
        _Piece(
          // Sudut tersebar merata ke atas dengan sedikit variasi acak.
          angle: -math.pi / 2 + (random.nextDouble() - 0.5) * 2.4,
          speed: 0.55 + random.nextDouble() * 0.75,
          spin: (random.nextDouble() - 0.5) * 14,
          width: 5 + random.nextDouble() * 5,
          height: 9 + random.nextDouble() * 8,
          hueShift: random.nextDouble(),
          delay: random.nextDouble() * 0.12,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
      return const SizedBox.shrink();
    }
    final colors = context.cleanly;
    final palette = [
      colors.primary,
      colors.accent,
      colors.jade.base,
      colors.marigold.base,
      colors.sky.base,
      colors.iris.base,
      colors.blossom.base,
    ];

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _ConfettiPainter(
              progress: _controller.value,
              pieces: _pieces,
              palette: palette,
              origin: widget.origin,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.width,
    required this.height,
    required this.hueShift,
    required this.delay,
  });

  final double angle;
  final double speed;
  final double spin;
  final double width;
  final double height;
  final double hueShift;
  final double delay;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.progress,
    required this.pieces,
    required this.palette,
    required this.origin,
  });

  final double progress;
  final List<_Piece> pieces;
  final List<Color> palette;
  final Alignment origin;

  static const _gravity = 1.9;

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(
      size.width * (origin.x + 1) / 2,
      size.height * (origin.y + 1) / 2,
    );
    final scale = math.max(size.width, size.height);

    for (final piece in pieces) {
      final t = ((progress - piece.delay) / (1 - piece.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;
      // Melambat di akhir supaya potongan terasa jatuh, bukan melesat lurus.
      final eased = 1 - math.pow(1 - t, 1.7).toDouble();
      final distance = scale * piece.speed * eased;
      final dx = math.cos(piece.angle) * distance;
      final dy =
          math.sin(piece.angle) * distance + scale * 0.55 * _gravity * t * t;
      final opacity = (1 - math.pow(t, 2.6)).toDouble().clamp(0.0, 1.0);
      if (opacity <= 0.01) continue;

      final colorIndex =
          (piece.hueShift * palette.length).floor() % palette.length;
      final color = palette[colorIndex].withValues(alpha: opacity);

      canvas.save();
      canvas.translate(start.dx + dx, start.dy + dy);
      canvas.rotate(piece.spin * eased);
      final paint = Paint()..color = color;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: piece.width,
        height: piece.height * (1 - 0.35 * t),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
