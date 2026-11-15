import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// The HealthPulse logo: white pulse line (`assets/branding/logo.svg`) on the
/// teal -> cyan rounded tile. Drawn in code so it stays sharp at any size.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.size = 96, this.glow = 0});

  final double size;

  /// 0..1, strength of the soft teal glow behind the tile.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        // Same corner ratio as the generated splash / icon PNGs.
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          if (glow > 0)
            BoxShadow(
              color: AppColors.teal500.withValues(alpha: 0.45 * glow),
              blurRadius: size * 0.5 * glow,
              spreadRadius: size * 0.04 * glow,
            ),
        ],
      ),
      child: CustomPaint(painter: _PulsePainter()),
    );
  }
}

class _PulsePainter extends CustomPainter {
  // logo.svg: viewBox 0 0 24 24, path "M22 12h-4l-3 9L9 3l-3 9H2".
  static const _points = [
    Offset(22, 12),
    Offset(18, 12),
    Offset(15, 21),
    Offset(9, 3),
    Offset(6, 12),
    Offset(2, 12),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Pulse occupies 62% of the tile, centered (matches the PNG assets).
    final box = size.width * 0.62;
    final origin = (size.width - box) / 2;
    final k = box / 24;

    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(origin + _points[i].dx * k, origin + _points[i].dy * k);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * k
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) => false;
}
