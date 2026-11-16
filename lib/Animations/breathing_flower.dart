/// Breathing flower animation for the Calm Attack application.
///
/// A flower guides the breath: its petals open while the user breathes
/// in, stay open while they hold, and fold closed again as they breathe
/// out. Everything is drawn in code to match the app's sunset theme.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// An animated breathing guide shaped like a blooming flower.
///
/// Calls [callback] with [BreathingConstants.inhalePhase],
/// [BreathingConstants.holdPhase] or [BreathingConstants.exhalePhase]
/// each time the phase changes.
class BreathingFlower extends StatefulWidget {
  /// Notified with the new phase name whenever the phase changes.
  final void Function(String) callback;

  /// Width and height of the drawing area.
  final double size;

  const BreathingFlower({
    super.key,
    required this.callback,
    this.size = 260,
  });

  @override
  State<BreathingFlower> createState() => _BreathingFlowerState();
}

class _BreathingFlowerState extends State<BreathingFlower>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bloom;
  Timer? _holdTimer;
  String _phase = BreathingConstants.inhalePhase;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.breathingCycle,
      vsync: this,
    )..addStatusListener(_handleStatus);
    _bloom = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _setPhase(BreathingConstants.holdPhase);
      _holdTimer = Timer(AppDurations.holdPhase, () {
        if (!mounted) return;
        _setPhase(BreathingConstants.exhalePhase);
        _controller.reverse();
      });
    } else if (status == AnimationStatus.dismissed) {
      _setPhase(BreathingConstants.inhalePhase);
      _controller.forward();
    }
  }

  void _setPhase(String phase) {
    setState(() => _phase = phase);
    widget.callback(phase);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Breathing flower. Current step: $_phase',
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _bloom,
            builder: (context, _) => CustomPaint(
              painter: FlowerPainter(
                bloom: _bloom.value,
                holding: _phase == BreathingConstants.holdPhase,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The app's flower character standing on a stem, gently breathing.
///
/// Used as the welcome illustration on the start screen.
class FlowerMascot extends StatefulWidget {
  /// Width of the illustration; the height is 1.35 times this.
  final double width;

  const FlowerMascot({super.key, required this.width});

  @override
  State<FlowerMascot> createState() => _FlowerMascotState();
}

class _FlowerMascotState extends State<FlowerMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
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
      label: 'A smiling flower, gently breathing',
      image: true,
      child: SizedBox(
        width: widget.width,
        height: widget.width * 1.35,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: FlowerPainter(
                // Breathe softly between mostly open and fully open.
                bloom:
                    0.62 + 0.18 * Curves.easeInOut.transform(_controller.value),
                holding: true,
                showStem: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws the flower character. The flower head sits in the top square
/// of the canvas; with [showStem], a stem and leaves fill the space below.
class FlowerPainter extends CustomPainter {
  /// 0 = closed bud, 1 = fully open.
  final double bloom;

  /// True shows open eyes and a smile; false shows calm closed eyes.
  final bool holding;

  /// Draws a stem with two leaves under the flower head.
  final bool showStem;

  FlowerPainter({
    required this.bloom,
    required this.holding,
    this.showStem = false,
  });

  static const _stem = Color(0xff8E5A5F);
  static const _leaf = Color(0xffB57A72);

  static const _glow = Color(0xffFBD9C0);
  static const _innerPetal = Color(0xffF6B8A8);
  static const _center = Color(0xffF7C59F);
  static const _cheek = Color(0xffEE9A8C);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);

    if (showStem) _drawStem(canvas, size, c, r);

    // Soft glow that grows with each breath in.
    canvas.drawCircle(
      c,
      r * (0.55 + 0.4 * bloom),
      Paint()..color = _glow.withValues(alpha: 0.35 + 0.25 * bloom),
    );

    // Outer and inner rings of petals. They lengthen and spread apart as
    // the flower opens, and turn slightly so the bloom feels alive.
    _drawPetalRing(
      canvas,
      c,
      count: 8,
      length: r * (0.42 + 0.40 * bloom),
      width: r * (0.20 + 0.14 * bloom),
      spread: 0.25 + 0.75 * bloom,
      rotation: -pi / 2 + bloom * pi / 16,
      color: AppColors.primary,
    );
    _drawPetalRing(
      canvas,
      c,
      count: 8,
      length: r * (0.34 + 0.26 * bloom),
      width: r * (0.16 + 0.10 * bloom),
      spread: 0.2 + 0.8 * bloom,
      rotation: -pi / 2 + pi / 8 - bloom * pi / 16,
      color: _innerPetal,
    );

    // Center with a calm little face.
    final centerRadius = r * (0.22 + 0.04 * bloom);
    canvas.drawCircle(c, centerRadius, Paint()..color = _center);
    _drawFace(canvas, c, centerRadius);
  }

  /// A gently curved stem from the bottom edge to the flower, with one
  /// leaf on each side.
  void _drawStem(Canvas canvas, Size size, Offset c, double r) {
    final bottom = Offset(c.dx, size.height);
    final stemPaint = Paint()
      ..color = _stem
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(bottom.dx, bottom.dy)
        ..quadraticBezierTo(
            c.dx + r * 0.12, (c.dy + bottom.dy) / 2, c.dx, c.dy),
      stemPaint,
    );

    final leafPaint = Paint()..color = _leaf;
    void leaf(Offset base, double angle, double length) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(angle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(length / 2, -length * 0.38, length, 0)
          ..quadraticBezierTo(length / 2, length * 0.38, 0, 0),
        leafPaint,
      );
      canvas.restore();
    }

    final leafY = c.dy + (bottom.dy - c.dy) * 0.68;
    leaf(Offset(c.dx + r * 0.05, leafY), -pi / 7, r * 0.5);
    leaf(Offset(c.dx + r * 0.07, leafY + r * 0.12), -6 * pi / 7, r * 0.42);
  }

  void _drawPetalRing(
    Canvas canvas,
    Offset c, {
    required int count,
    required double length,
    required double width,
    required double spread,
    required double rotation,
    required Color color,
  }) {
    final fill = Paint()..color = color;
    final vein = Paint()
      ..color = AppColors.primaryDeep.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.06
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < count; i++) {
      // When closed, petals bunch together pointing up like a bud.
      final evenAngle = rotation + i * 2 * pi / count;
      // Measure each petal's angle from "straight up", wrapped to
      // -pi..pi, so petals gather evenly on both sides when closing.
      var fromUp = (evenAngle + pi / 2) % (2 * pi);
      if (fromUp > pi) fromUp -= 2 * pi;
      final angle = -pi / 2 + fromUp * spread;

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      final petal = Path()
        ..moveTo(0, 0)
        ..cubicTo(width, length * 0.25, width * 0.8, length * 0.85, 0, length)
        ..cubicTo(-width * 0.8, length * 0.85, -width, length * 0.25, 0, 0)
        ..close();
      // Rotate so the petal points outward from the center.
      canvas.rotate(-pi / 2);
      canvas.drawPath(petal, fill);
      canvas.drawLine(
        Offset(0, length * 0.2),
        Offset(0, length * 0.75),
        vein,
      );
      canvas.restore();
    }
  }

  void _drawFace(Canvas canvas, Offset c, double radius) {
    final ink = Paint()
      ..color = AppColors.primaryDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.09
      ..strokeCap = StrokeCap.round;
    final eyeY = c.dy - radius * 0.12;
    final eyeX = radius * 0.38;

    if (holding) {
      // Open, round eyes while holding the breath.
      final eyeFill = Paint()..color = AppColors.primaryDeep;
      canvas.drawCircle(Offset(c.dx - eyeX, eyeY), radius * 0.09, eyeFill);
      canvas.drawCircle(Offset(c.dx + eyeX, eyeY), radius * 0.09, eyeFill);
    } else {
      // Relaxed, closed eyes while breathing.
      for (final dx in [-eyeX, eyeX]) {
        canvas.drawArc(
          Rect.fromCircle(
              center: Offset(c.dx + dx, eyeY), radius: radius * 0.14),
          0,
          pi,
          false,
          ink,
        );
      }
    }

    // Rosy cheeks.
    final cheek = Paint()..color = _cheek.withValues(alpha: 0.7);
    for (final dx in [-radius * 0.58, radius * 0.58]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(c.dx + dx, c.dy + radius * 0.2),
          width: radius * 0.34,
          height: radius * 0.2,
        ),
        cheek,
      );
    }

    // Mouth: a gentle smile, opening to a soft "o" while breathing out.
    final mouthCenter = Offset(c.dx, c.dy + radius * 0.3);
    if (!holding && bloom < 0.999 && bloom > 0.001) {
      canvas.drawOval(
        Rect.fromCenter(
          center: mouthCenter,
          width: radius * 0.18,
          height: radius * 0.24,
        ),
        ink,
      );
    } else {
      canvas.drawArc(
        Rect.fromCircle(
            center: mouthCenter.translate(0, -radius * 0.1),
            radius: radius * 0.16),
        0.2,
        pi - 0.4,
        false,
        ink,
      );
    }
  }

  @override
  bool shouldRepaint(FlowerPainter oldDelegate) =>
      oldDelegate.bloom != bloom ||
      oldDelegate.holding != holding ||
      oldDelegate.showStem != showStem;
}
