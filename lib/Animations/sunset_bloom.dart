/// Sunset bloom illustration for the Calm Attack application.
///
/// A calm scene drawn in code: a setting sun behind soft hills, with
/// flowers that slowly sway in front. Used on the finish screen to mark
/// the end of a session.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// A square illustration of a sunset with gently swaying flowers.
class SunsetBloom extends StatefulWidget {
  /// Width and height of the illustration.
  final double size;

  const SunsetBloom({super.key, required this.size});

  @override
  State<SunsetBloom> createState() => _SunsetBloomState();
}

class _SunsetBloomState extends State<SunsetBloom>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'A sunset over soft hills with flowers swaying',
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _SunsetBloomPainter(
              sway: Curves.easeInOut.transform(_controller.value) * 2 - 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SunsetBloomPainter extends CustomPainter {
  /// Sway amount from -1 to 1.
  final double sway;

  _SunsetBloomPainter({required this.sway});

  static const _sky = Color(0xffFFE3D3);
  static const _sun = Color(0xffF7C59F);
  static const _sunGlow = Color(0xffFBD9C0);
  static const _hillBack = Color(0xffF2B5A6);
  static const _hillFront = Color(0xffE59A92);
  static const _stem = Color(0xff8E5A5F);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Rounded sky card.
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.18),
    );
    canvas.save();
    canvas.clipRRect(card);
    canvas.drawRRect(card, Paint()..color = _sky);

    // Sun with two soft rings.
    final sunCenter = Offset(w * 0.5, h * 0.58);
    canvas.drawCircle(sunCenter, w * 0.34, Paint()..color = _sunGlow);
    canvas.drawCircle(
      sunCenter,
      w * 0.26,
      Paint()..color = _sun.withValues(alpha: 0.7),
    );
    canvas.drawCircle(sunCenter, w * 0.19, Paint()..color = _sun);

    // Two birds.
    final birdPaint = Paint()
      ..color = AppColors.primaryDeep.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.011
      ..strokeCap = StrokeCap.round;
    _drawBird(canvas, birdPaint, Offset(w * 0.24, h * 0.24), w * 0.05);
    _drawBird(canvas, birdPaint, Offset(w * 0.34, h * 0.18), w * 0.035);

    // Back and front hills.
    final back = Path()
      ..moveTo(0, h * 0.70)
      ..quadraticBezierTo(w * 0.3, h * 0.56, w * 0.6, h * 0.68)
      ..quadraticBezierTo(w * 0.85, h * 0.76, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(back, Paint()..color = _hillBack);

    final front = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.45, h * 0.70, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(front, Paint()..color = _hillFront);

    // Swaying flowers in front.
    _drawFlower(canvas, size, Offset(w * 0.18, h * 0.92), h * 0.30, 0.9,
        AppColors.primary);
    _drawFlower(canvas, size, Offset(w * 0.30, h * 0.94), h * 0.20, -0.6,
        AppColors.accentCoral);
    _drawFlower(canvas, size, Offset(w * 0.78, h * 0.93), h * 0.26, -0.8,
        AppColors.primary);
    _drawFlower(canvas, size, Offset(w * 0.88, h * 0.95), h * 0.16, 0.5,
        AppColors.accentPeach);

    canvas.restore();
  }

  void _drawBird(Canvas canvas, Paint paint, Offset c, double span) {
    final path = Path()
      ..moveTo(c.dx - span, c.dy)
      ..quadraticBezierTo(c.dx - span / 2, c.dy - span * 0.6, c.dx, c.dy)
      ..quadraticBezierTo(
          c.dx + span / 2, c.dy - span * 0.6, c.dx + span, c.dy);
    canvas.drawPath(path, paint);
  }

  /// A stem with one leaf and a round flower head at the top.
  /// [phase] gives each flower its own sway direction and strength.
  void _drawFlower(
    Canvas canvas,
    Size size,
    Offset base,
    double height,
    double phase,
    Color petalColor,
  ) {
    final w = size.width;
    final tip = Offset(base.dx + sway * phase * w * 0.035, base.dy - height);
    final control = Offset(base.dx + phase * w * 0.03, base.dy - height / 2);

    final stemPaint = Paint()
      ..color = _stem
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
    canvas.drawPath(stem, stemPaint);

    // Leaf halfway up the stem.
    final leafBase = Offset(
      (base.dx + control.dx) / 2,
      base.dy - height * 0.4,
    );
    canvas.save();
    canvas.translate(leafBase.dx, leafBase.dy);
    canvas.rotate(phase > 0 ? -pi / 5 : -4 * pi / 5);
    final leafLength = w * 0.07;
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(leafLength / 2, -leafLength * 0.4, leafLength, 0)
      ..quadraticBezierTo(leafLength / 2, leafLength * 0.4, 0, 0);
    canvas.drawPath(leaf, Paint()..color = _stem.withValues(alpha: 0.8));
    canvas.restore();

    // Flower head: six petals and a warm center.
    final petalRadius = w * 0.032;
    final petalPaint = Paint()..color = petalColor;
    for (var i = 0; i < 6; i++) {
      final a = i * pi / 3 + sway * 0.15;
      canvas.drawCircle(
        tip + Offset(cos(a), sin(a)) * petalRadius * 1.1,
        petalRadius,
        petalPaint,
      );
    }
    canvas.drawCircle(tip, petalRadius * 0.8, Paint()..color = _sun);
  }

  @override
  bool shouldRepaint(_SunsetBloomPainter oldDelegate) =>
      oldDelegate.sway != sway;
}
