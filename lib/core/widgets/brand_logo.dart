import 'package:flutter/material.dart';
import 'package:municipality/core/theme/app_colors.dart';

/// The HealthPulse logo: the website's white heart-with-pulse (lucide
/// `HeartPulse`, `assets/branding/logo.svg`) on the teal -> cyan rounded
/// tile. Drawn in code so it stays sharp at any size.
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
      child: const CustomPaint(painter: BrandGlyphPainter()),
    );
  }
}

/// White heart-with-pulse stroke. [scale] is the share of the canvas the
/// 24x24 icon grid takes, centered (0.62 in the tile and launcher icon,
/// smaller in the adaptive icon foreground to stay inside its safe zone).
class BrandGlyphPainter extends CustomPainter {
  const BrandGlyphPainter({this.scale = 0.62});

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final box = size.shortestSide * scale;
    final k = box / 24;

    canvas
      ..save()
      ..translate((size.width - box) / 2, (size.height - box) / 2)
      ..scale(k);

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas
      ..drawPath(_heart, stroke)
      ..drawPath(_pulse, stroke)
      ..restore();
  }

  // lucide heart-pulse (lucide-react 0.546.0, as used by the website):
  // "M2 9.5a5.5 5.5 0 0 1 9.591-3.676.56.56 0 0 0 .818 0A5.49 5.49 0 0 1
  //  22 9.5c0 2.29-1.5 4-3 5.5l-5.492 5.313a2 2 0 0 1-3 .019L5 15
  //  c-1.5-1.5-3-3.2-3-5.5"
  static final _heart = Path()
    ..moveTo(2, 9.5)
    ..arcToPoint(const Offset(11.591, 5.824), radius: const Radius.circular(5.5))
    ..arcToPoint(
      const Offset(12.409, 5.824),
      radius: const Radius.circular(0.56),
      clockwise: false,
    )
    ..arcToPoint(const Offset(22, 9.5), radius: const Radius.circular(5.49))
    ..cubicTo(22, 11.79, 20.5, 13.5, 19, 15)
    ..lineTo(13.508, 20.313)
    ..arcToPoint(const Offset(10.508, 20.332), radius: const Radius.circular(2))
    ..lineTo(5, 15)
    ..cubicTo(3.5, 13.5, 2, 11.8, 2, 9.5);

  // "M3.22 13H9.5l.5-1 2 4.5 2-7 1.5 3.5h5.27"
  static final _pulse = Path()
    ..moveTo(3.22, 13)
    ..lineTo(9.5, 13)
    ..lineTo(10, 12)
    ..lineTo(12, 16.5)
    ..lineTo(14, 9.5)
    ..lineTo(15.5, 13)
    ..lineTo(20.77, 13);

  @override
  bool shouldRepaint(BrandGlyphPainter oldDelegate) =>
      oldDelegate.scale != scale;
}
