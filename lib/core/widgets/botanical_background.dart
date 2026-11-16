/// Botanical background for the Calm Attack application.
///
/// Draws a soft, repeating pattern of leaf sprigs and small flowers
/// behind a screen's content. Everything is drawn in code, so it stays
/// sharp on every screen size and needs no image files.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Fills its area with the app background color and a repeating
/// plant pattern, then shows [child] on top.
class BotanicalBackground extends StatelessWidget {
  /// Content shown above the pattern.
  final Widget child;

  /// Base color behind the pattern. Defaults to [AppColors.background].
  /// Pass [Colors.transparent] to draw the pattern over something else,
  /// such as a gradient.
  final Color? color;

  /// Color of leaves and stems.
  final Color? leafColor;

  /// Color of flower petals.
  final Color? flowerColor;

  const BotanicalBackground({
    super.key,
    required this.child,
    this.color,
    this.leafColor,
    this.flowerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color ?? AppColors.background),
        RepaintBoundary(
          child: CustomPaint(
            painter: BotanicalPatternPainter(
              leafColor:
                  leafColor ?? AppColors.accentCoral.withValues(alpha: 0.16),
              flowerColor:
                  flowerColor ?? AppColors.primary.withValues(alpha: 0.13),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Paints a grid of tiles; each tile holds either a leaf sprig or a
/// small five-petal flower, turned a little differently so the pattern
/// feels hand-placed rather than mechanical.
class BotanicalPatternPainter extends CustomPainter {
  final Color leafColor;
  final Color flowerColor;

  /// Size of one pattern tile in logical pixels.
  final double tileSize;

  BotanicalPatternPainter({
    required this.leafColor,
    required this.flowerColor,
    this.tileSize = 92,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final stemPaint = Paint()
      ..color = leafColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final petalPaint = Paint()..color = flowerColor;
    final centerPaint = Paint()
      ..color = flowerColor.withValues(
        alpha: (flowerColor.a * 1.8).clamp(0.0, 1.0),
      );

    final cols = (size.width / tileSize).ceil() + 1;
    final rows = (size.height / tileSize).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        // Shift every other row by half a tile for a staggered layout.
        final offsetX = (row.isOdd ? tileSize / 2 : 0) + col * tileSize;
        final center = Offset(offsetX, row * tileSize + tileSize / 2);
        // A fixed, position-based angle so the pattern never jumps
        // between rebuilds.
        final angle = ((row * 7 + col * 13) % 12) * (pi / 6);

        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        if ((row + col).isEven) {
          _drawSprig(canvas, stemPaint, leafPaint);
        } else {
          _drawFlower(canvas, petalPaint, centerPaint);
        }
        canvas.restore();
      }
    }
  }

  /// A curved stem with three pairs of leaves and one leaf at the tip.
  void _drawSprig(Canvas canvas, Paint stemPaint, Paint leafPaint) {
    const length = 34.0;
    final stem = Path()
      ..moveTo(0, length / 2)
      ..quadraticBezierTo(6, 0, 0, -length / 2);
    canvas.drawPath(stem, stemPaint);

    for (var i = 0; i < 3; i++) {
      final y = length / 2 - 8 - i * 9.0;
      final leafSize = 9.0 - i * 1.5;
      _drawLeaf(canvas, leafPaint, Offset(3, y), -pi / 4, leafSize);
      _drawLeaf(canvas, leafPaint, Offset(3, y), -3 * pi / 4, leafSize);
    }
    _drawLeaf(canvas, leafPaint, const Offset(0, -length / 2), -pi / 2, 7);
  }

  /// One pointed leaf starting at [base] and growing toward [angle].
  void _drawLeaf(
    Canvas canvas,
    Paint paint,
    Offset base,
    double angle,
    double length,
  ) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final leaf = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(length * 0.5, -length * 0.42, length, 0)
      ..quadraticBezierTo(length * 0.5, length * 0.42, 0, 0)
      ..close();
    canvas.drawPath(leaf, paint);
    canvas.restore();
  }

  /// A small flower with five rounded petals and a darker center.
  void _drawFlower(Canvas canvas, Paint petalPaint, Paint centerPaint) {
    const petals = 5;
    const petalDistance = 6.5;
    for (var i = 0; i < petals; i++) {
      final a = i * 2 * pi / petals;
      canvas.save();
      canvas.rotate(a);
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(0, -petalDistance),
          width: 8,
          height: 11,
        ),
        petalPaint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, 3.2, centerPaint);
  }

  @override
  bool shouldRepaint(BotanicalPatternPainter oldDelegate) =>
      oldDelegate.leafColor != leafColor ||
      oldDelegate.flowerColor != flowerColor ||
      oldDelegate.tileSize != tileSize;
}
