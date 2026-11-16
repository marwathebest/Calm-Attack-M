/// Smell imagination screen for the Calm Attack application.
///
/// The user swipes through cards of pleasant scents (flowers, fruit, herbs
/// and warm kitchen smells), each with a drawn illustration and a short
/// prompt to imagine it while breathing in slowly through the nose.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/exercise_layout.dart';
import 'bubble_pop_game_screen.dart';

enum _Scent { rose, jasmine, lavender, lemon, orange, mint, coffee, bread }

class _ScentInfo {
  final _Scent kind;
  final String name;
  final String prompt;

  const _ScentInfo(this.kind, this.name, this.prompt);
}

const _scents = [
  _ScentInfo(_Scent.rose, 'Rose',
      'Bring a soft rose close. Notice its sweet, gentle scent.'),
  _ScentInfo(_Scent.jasmine, 'Jasmine',
      'Imagine white jasmine on a warm evening, light and fresh.'),
  _ScentInfo(_Scent.lavender, 'Lavender',
      'Rub a lavender sprig between your fingers and breathe it in.'),
  _ScentInfo(
      _Scent.lemon, 'Lemon', 'Picture a lemon cut in half, bright and zesty.'),
  _ScentInfo(_Scent.orange, 'Orange',
      'Peel an orange slowly. Smell the sweet mist from the peel.'),
  _ScentInfo(_Scent.mint, 'Fresh Mint',
      'Crush a few mint leaves and feel the cool, clean smell.'),
  _ScentInfo(_Scent.coffee, 'Coffee',
      'Hold a warm cup of coffee and breathe in the rich steam.'),
  _ScentInfo(_Scent.bread, 'Fresh Bread',
      'Imagine bread just out of the oven, warm and golden.'),
];

class SmellScreen extends StatefulWidget {
  final DateTime startTime;

  const SmellScreen({super.key, required this.startTime});

  @override
  State<SmellScreen> createState() => _SmellScreenState();
}

class _SmellScreenState extends State<SmellScreen> {
  final PageController _pages = PageController(viewportFraction: 0.82);
  int _current = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    _pages.animateToPage(
      index.clamp(0, _scents.length - 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseLayout(
      title: 'Imagine a Scent',
      instruction: 'Breathe in slowly through your nose. '
          'Or smell anything pleasant near you.',
      startTime: widget.startTime,
      nextScreen: (start) => BubblePopGameScreen(startTime: start),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spacingSmall),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: _scents.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (context, i) => _ScentCard(info: _scents[i]),
            ),
          ),
          const SizedBox(height: AppSizes.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Previous scent',
                onPressed: _current > 0 ? () => _goTo(_current - 1) : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.primaryDeep,
              ),
              for (var i = 0; i < _scents.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _current ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _current
                        ? AppColors.primary
                        : AppColors.accentPeach,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              IconButton(
                tooltip: 'Next scent',
                onPressed: _current < _scents.length - 1
                    ? () => _goTo(_current + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.primaryDeep,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScentCard extends StatelessWidget {
  final _ScentInfo info;

  const _ScentCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.surfaceSoft, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.mediumPadding),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Semantics(
                      label: info.name,
                      image: true,
                      child: CustomPaint(painter: _ScentPainter(info.kind)),
                    ),
                  ),
                ),
              ),
              Text(
                info.name,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXSmall),
              Text(
                info.prompt,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Draws each scent as a simple, flat illustration in a unit square.
class _ScentPainter extends CustomPainter {
  final _Scent kind;

  _ScentPainter(this.kind);

  static const _leaf = Color(0xff7FA27A);
  static const _leafDark = Color(0xff5E8160);
  static const _stem = Color(0xff6F8F68);

  late double _u;
  late Canvas _c;

  Offset _p(double x, double y) => Offset(x * _u, y * _u);
  Paint _fill(Color c) => Paint()..color = c;

  void _leafShape(Offset base, double angle, double length, Color color) {
    _c.save();
    _c.translate(base.dx, base.dy);
    _c.rotate(angle);
    final l = length * _u;
    _c.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(l / 2, -l * 0.42, l, 0)
        ..quadraticBezierTo(l / 2, l * 0.42, 0, 0),
      _fill(color),
    );
    _c.restore();
  }

  void _stemLine(Offset a, Offset b, Offset control) {
    _c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy),
      Paint()
        ..color = _stem
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.025 * _u
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _u = size.shortestSide;
    // Soft round backdrop.
    canvas.drawCircle(_p(0.5, 0.5), 0.46 * _u, _fill(const Color(0xffFFEDE3)));
    switch (kind) {
      case _Scent.rose:
        _rose();
      case _Scent.jasmine:
        _jasmine();
      case _Scent.lavender:
        _lavender();
      case _Scent.lemon:
        _citrus(const Color(0xffF4D35E), const Color(0xffFBEBA4));
      case _Scent.orange:
        _citrus(const Color(0xffF29E4C), const Color(0xffF9C98A));
      case _Scent.mint:
        _mint();
      case _Scent.coffee:
        _coffee();
      case _Scent.bread:
        _bread();
    }
  }

  void _rose() {
    _stemLine(_p(0.5, 0.9), _p(0.5, 0.45), _p(0.46, 0.7));
    _leafShape(_p(0.49, 0.7), -pi / 5, 0.2, _leaf);
    _leafShape(_p(0.5, 0.78), -4 * pi / 5, 0.17, _leafDark);
    const outer = Color(0xffD45D79);
    const mid = Color(0xffE47A92);
    const inner = Color(0xffC2456A);
    _c.drawCircle(_p(0.5, 0.38), 0.19 * _u, _fill(outer));
    _c.drawOval(
        Rect.fromCenter(
            center: _p(0.5, 0.36), width: 0.3 * _u, height: 0.25 * _u),
        _fill(mid));
    // Swirl of inner petals.
    final swirl = Paint()
      ..color = inner
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * _u
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i <= 60; i++) {
      final t = i / 60;
      final a = t * 3.2 * pi;
      final r = 0.02 + 0.09 * t;
      final pt = _p(0.5 + r * cos(a), 0.35 + r * 0.8 * sin(a));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    _c.drawPath(path, swirl);
  }

  void _jasmine() {
    _leafShape(_p(0.5, 0.62), pi / 7, 0.3, _leaf);
    _leafShape(_p(0.5, 0.62), 6 * pi / 7, 0.28, _leafDark);
    void flower(Offset c, double s) {
      for (var i = 0; i < 5; i++) {
        _c.save();
        _c.translate(c.dx, c.dy);
        _c.rotate(i * 2 * pi / 5);
        _c.drawOval(
          Rect.fromCenter(
              center: Offset(0, -0.075 * s * _u),
              width: 0.075 * s * _u,
              height: 0.13 * s * _u),
          _fill(Colors.white),
        );
        _c.restore();
      }
      _c.drawCircle(c, 0.025 * s * _u, _fill(const Color(0xffF4D35E)));
    }

    flower(_p(0.38, 0.4), 1.15);
    flower(_p(0.64, 0.36), 1.0);
    flower(_p(0.55, 0.6), 0.9);
  }

  void _lavender() {
    const purple = Color(0xff9B84C9);
    const light = Color(0xffB9A6DE);
    for (final (x, tilt) in [(0.38, -0.12), (0.5, 0.0), (0.62, 0.12)]) {
      final top = _p(x + tilt * 0.6, 0.18);
      _stemLine(_p(0.5, 0.9), top, _p(x, 0.6));
      for (var i = 0; i < 7; i++) {
        final t = i / 6;
        final c = Offset.lerp(top, _p(x + tilt * 0.25, 0.48), t)!;
        final r = (0.035 - t * 0.01) * _u;
        _c.drawOval(
            Rect.fromCenter(
                center: c.translate(-r * 0.6, 0),
                width: r * 1.6,
                height: r * 2),
            _fill(i.isEven ? purple : light));
        _c.drawOval(
            Rect.fromCenter(
                center: c.translate(r * 0.6, 0), width: r * 1.6, height: r * 2),
            _fill(i.isEven ? light : purple));
      }
    }
    // A ribbon tying the bunch.
    _c.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: _p(0.5, 0.74), width: 0.14 * _u, height: 0.05 * _u),
          Radius.circular(0.02 * _u)),
      _fill(AppColors.primary),
    );
  }

  /// A whole citrus fruit with a slice in front.
  void _citrus(Color peel, Color flesh) {
    _c.drawCircle(_p(0.42, 0.42), 0.22 * _u, _fill(peel));
    _leafShape(_p(0.45, 0.21), -pi / 4, 0.16, _leaf);
    // Slice.
    final c = _p(0.64, 0.64);
    _c.drawCircle(c, 0.18 * _u, _fill(peel));
    _c.drawCircle(c, 0.155 * _u, _fill(Colors.white));
    _c.drawCircle(c, 0.14 * _u, _fill(flesh));
    final seg = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.012 * _u;
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      _c.drawLine(c, c + Offset(cos(a), sin(a)) * 0.14 * _u, seg);
    }
    _c.drawCircle(c, 0.02 * _u, _fill(Colors.white));
  }

  void _mint() {
    _stemLine(_p(0.5, 0.9), _p(0.5, 0.2), _p(0.53, 0.55));
    for (var i = 0; i < 4; i++) {
      final y = 0.75 - i * 0.15;
      final len = 0.26 - i * 0.04;
      final color = i.isEven ? _leaf : _leafDark;
      _leafShape(_p(0.51, y), -pi / 6, len, color);
      _leafShape(_p(0.51, y + 0.03), -5 * pi / 6, len, color);
    }
    _leafShape(_p(0.5, 0.22), -pi / 2, 0.1, _leaf);
  }

  void _coffee() {
    const cup = Color(0xffFFFFFF);
    const coffee = Color(0xff7A4E3A);
    // Saucer.
    _c.drawOval(
        Rect.fromCenter(
            center: _p(0.5, 0.78), width: 0.62 * _u, height: 0.12 * _u),
        _fill(AppColors.accentPeach));
    // Cup body.
    final body = Path()
      ..moveTo(_p(0.27, 0.45).dx, _p(0.27, 0.45).dy)
      ..lineTo(_p(0.73, 0.45).dx, _p(0.73, 0.45).dy)
      ..quadraticBezierTo(_p(0.72, 0.76).dx, _p(0.72, 0.76).dy,
          _p(0.5, 0.77).dx, _p(0.5, 0.77).dy)
      ..quadraticBezierTo(_p(0.28, 0.76).dx, _p(0.28, 0.76).dy,
          _p(0.27, 0.45).dx, _p(0.27, 0.45).dy);
    _c.drawPath(body, _fill(cup));
    // Handle.
    _c.drawArc(
      Rect.fromCenter(
          center: _p(0.74, 0.57), width: 0.16 * _u, height: 0.16 * _u),
      -pi / 2,
      pi,
      false,
      Paint()
        ..color = cup
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.04 * _u,
    );
    _c.drawOval(
        Rect.fromCenter(
            center: _p(0.5, 0.45), width: 0.46 * _u, height: 0.08 * _u),
        _fill(coffee));
    // Steam.
    final steam = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * _u
      ..strokeCap = StrokeCap.round;
    for (final x in [0.42, 0.5, 0.58]) {
      final path = Path()..moveTo(_p(x, 0.38).dx, _p(x, 0.38).dy);
      path.cubicTo(
          _p(x - 0.05, 0.31).dx,
          _p(x - 0.05, 0.31).dy,
          _p(x + 0.05, 0.25).dx,
          _p(x + 0.05, 0.25).dy,
          _p(x, 0.17).dx,
          _p(x, 0.17).dy);
      _c.drawPath(path, steam);
    }
  }

  void _bread() {
    const crust = Color(0xffD9965B);
    const top = Color(0xffE8B07A);
    final loaf = RRect.fromRectAndCorners(
      Rect.fromLTWH(0.18 * _u, 0.38 * _u, 0.64 * _u, 0.34 * _u),
      topLeft: Radius.circular(0.2 * _u),
      topRight: Radius.circular(0.2 * _u),
      bottomLeft: Radius.circular(0.05 * _u),
      bottomRight: Radius.circular(0.05 * _u),
    );
    _c.drawRRect(loaf, _fill(crust));
    _c.drawOval(
        Rect.fromCenter(
            center: _p(0.5, 0.45), width: 0.58 * _u, height: 0.16 * _u),
        _fill(top));
    final cut = Paint()
      ..color = crust
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022 * _u
      ..strokeCap = StrokeCap.round;
    for (final x in [0.34, 0.5, 0.66]) {
      _c.drawLine(_p(x - 0.05, 0.48), _p(x + 0.05, 0.41), cut);
    }
    // Warm steam above the loaf.
    final steam = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.02 * _u
      ..strokeCap = StrokeCap.round;
    for (final x in [0.4, 0.6]) {
      final path = Path()..moveTo(_p(x, 0.33).dx, _p(x, 0.33).dy);
      path.cubicTo(
          _p(x - 0.04, 0.27).dx,
          _p(x - 0.04, 0.27).dy,
          _p(x + 0.04, 0.22).dx,
          _p(x + 0.04, 0.22).dy,
          _p(x, 0.15).dx,
          _p(x, 0.15).dy);
      _c.drawPath(path, steam);
    }
  }

  @override
  bool shouldRepaint(_ScentPainter oldDelegate) => oldDelegate.kind != kind;
}
