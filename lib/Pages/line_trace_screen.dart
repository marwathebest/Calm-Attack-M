/// Line tracing game for the Calm Attack application.
///
/// A soft dotted path is shown and the user follows it slowly with a
/// finger. The traced part fills in with color, and a glowing dot shows
/// where to go next. Slow, steady movement keeps attention in the moment.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/exercise_layout.dart';
import 'math_game_screen.dart';

/// A shape to trace, as a function from 0..1 to a point in a unit square.
class _TraceShape {
  final String name;
  final Offset Function(double t) at;

  const _TraceShape(this.name, this.at);
}

final _shapes = <_TraceShape>[
  _TraceShape('Gentle wave', (t) {
    return Offset(0.05 + 0.9 * t, 0.5 + 0.28 * sin(t * 3 * pi));
  }),
  _TraceShape('Infinity loop', (t) {
    final a = t * 2 * pi;
    final d = 1 + sin(a) * sin(a);
    return Offset(0.5 + 0.42 * cos(a) / d, 0.5 + 0.42 * sin(a) * cos(a) / d);
  }),
  _TraceShape('Spiral', (t) {
    final a = t * 5 * pi;
    final r = 0.05 + 0.4 * t;
    return Offset(0.5 + r * cos(a), 0.5 + r * sin(a));
  }),
  _TraceShape('Hills', (t) {
    return Offset(0.05 + 0.9 * t, 0.62 - 0.3 * sin(t * 2 * pi).abs());
  }),
];

class LineTraceScreen extends StatefulWidget {
  final DateTime startTime;

  const LineTraceScreen({super.key, required this.startTime});

  @override
  State<LineTraceScreen> createState() => _LineTraceScreenState();
}

class _LineTraceScreenState extends State<LineTraceScreen> {
  static const _samples = 160;

  int _shapeIndex = 0;

  /// How many sample points have been traced so far.
  int _progress = 0;

  Size _area = Size.zero;
  List<Offset> _points = const [];

  bool get _done => _progress >= _samples - 1;

  void _layout(Size area) {
    if (area == _area && _points.isNotEmpty) return;
    _area = area;
    final shape = _shapes[_shapeIndex];
    _points = List.generate(_samples, (i) {
      final p = shape.at(i / (_samples - 1));
      return Offset(p.dx * area.width, p.dy * area.height);
    });
  }

  void _onDrag(Offset position) {
    if (_done) return;
    // Accept the finger if it is close to one of the next few points;
    // looking a little ahead lets a steady finger move smoothly.
    final tolerance = _area.shortestSide * 0.09;
    for (var i = _progress; i < min(_progress + 10, _samples); i++) {
      if ((_points[i] - position).distance < tolerance) {
        setState(() => _progress = i + 1);
        return;
      }
    }
  }

  void _nextShape() {
    setState(() {
      _shapeIndex = (_shapeIndex + 1) % _shapes.length;
      _progress = 0;
      _points = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseLayout(
      title: 'Trace the Line',
      instruction: 'Follow the dots slowly with your finger. There is no rush.',
      startTime: widget.startTime,
      nextScreen: (start) => MathGameScreen(startTime: start),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.mediumPadding),
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _layout(constraints.biggest);
                  return GestureDetector(
                    onPanStart: (d) => _onDrag(d.localPosition),
                    onPanUpdate: (d) => _onDrag(d.localPosition),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: CustomPaint(
                        size: constraints.biggest,
                        painter: _TracePainter(
                          points: _points,
                          progress: _progress,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            SizedBox(
              height: 40,
              child: _done
                  ? TextButton.icon(
                      onPressed: _nextShape,
                      icon: const Icon(Icons.gesture),
                      label: const Text('Lovely. Try another shape'),
                    )
                  : Text(
                      _shapes[_shapeIndex].name,
                      style: AppTextStyles.bodyMedium,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TracePainter extends CustomPainter {
  final List<Offset> points;
  final int progress;

  _TracePainter({required this.points, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final unit = size.shortestSide;

    // Untraced guide: soft dots along the whole path.
    final dot = Paint()..color = AppColors.accentPeach;
    for (var i = progress; i < points.length; i += 3) {
      canvas.drawCircle(points[i], unit * 0.012, dot);
    }

    // Traced part: a smooth rose line.
    if (progress > 1) {
      final traced = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < progress; i++) {
        traced.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(
        traced,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = unit * 0.035
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Start marker, then a glowing dot showing where to go next.
    if (progress < points.length) {
      final next = points[progress];
      canvas.drawCircle(
        next,
        unit * 0.06,
        Paint()..color = AppColors.primary.withValues(alpha: 0.18),
      );
      canvas.drawCircle(next, unit * 0.028, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(_TracePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.points != points;
}
