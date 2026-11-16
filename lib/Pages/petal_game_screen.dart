/// Flower petals game for the Calm Attack application.
///
/// The user picks petals off a flower one at a time. Each petal drifts
/// slowly down and fades, which invites slow, deliberate taps. When the
/// flower is bare, a new one grows.
library;

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/audio_utils.dart';
import '../core/widgets/exercise_layout.dart';
import 'line_trace_screen.dart';

class PetalGameScreen extends StatefulWidget {
  final DateTime startTime;

  const PetalGameScreen({super.key, required this.startTime});

  @override
  State<PetalGameScreen> createState() => _PetalGameScreenState();
}

class _PetalGameScreenState extends State<PetalGameScreen> {
  static const _petalCount = 10;

  /// Petal colors cycle through the sunset palette, one set per flower.
  static const _flowerColors = [
    AppColors.primary,
    AppColors.accentCoral,
    Color(0xffD98BA0),
  ];

  final AudioPlayer _audioPlayer = AudioPlayer();
  final List<bool> _picked = List.filled(_petalCount, false);
  int _flowerNumber = 0;

  int get _petalsLeft => _picked.where((p) => !p).length;

  @override
  void dispose() {
    AudioUtils.disposeAudioPlayer(_audioPlayer);
    super.dispose();
  }

  void _pickPetal(int index) {
    if (_picked[index]) return;
    AudioUtils.playRandomSound(_audioPlayer, AppAudio.popSounds);
    setState(() => _picked[index] = true);
  }

  void _growNewFlower() {
    setState(() {
      _picked.fillRange(0, _petalCount, false);
      _flowerNumber++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _petalsLeft == 0;
    return ExerciseLayout(
      title: 'Pick the Petals',
      instruction: 'Tap one petal at a time and watch it float away.',
      startTime: widget.startTime,
      nextScreen: (start) => LineTraceScreen(startTime: start),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              min(constraints.maxWidth * 0.85, constraints.maxHeight * 0.8);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox.square(
                dimension: size,
                child: _Flower(
                  // A new key replaces the whole flower so it grows fresh.
                  key: ValueKey(_flowerNumber),
                  size: size,
                  picked: _picked,
                  petalColor:
                      _flowerColors[_flowerNumber % _flowerColors.length],
                  onPetalTap: _pickPetal,
                ),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: done
                    ? TextButton.icon(
                        key: const ValueKey('grow'),
                        onPressed: _growNewFlower,
                        icon: const Icon(Icons.local_florist_outlined),
                        label: const Text('Well done. Grow a new flower'),
                      )
                    : Text(
                        '$_petalsLeft petals left',
                        key: const ValueKey('count'),
                        style: AppTextStyles.bodyMedium,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Flower extends StatelessWidget {
  final double size;
  final List<bool> picked;
  final Color petalColor;
  final void Function(int index) onPetalTap;

  const _Flower({
    super.key,
    required this.size,
    required this.picked,
    required this.petalColor,
    required this.onPetalTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = size / 2;
    final petalLength = size * 0.36;
    final petalWidth = size * 0.17;
    final count = picked.length;

    return TweenAnimationBuilder<double>(
      // The flower gently grows in when it first appears.
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, grow, child) =>
          Transform.scale(scale: grow, child: child),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < count; i++)
            Positioned(
              left: center - petalWidth / 2,
              top: center - petalLength,
              width: petalWidth,
              height: petalLength,
              child: Transform.rotate(
                angle: i * 2 * pi / count,
                alignment: Alignment.bottomCenter,
                child: _Petal(
                  picked: picked[i],
                  color: petalColor,
                  // Alternate the fall direction for a natural drift.
                  driftRight: i.isEven,
                  onTap: () => onPetalTap(i),
                ),
              ),
            ),
          Positioned(
            left: center - size * 0.13,
            top: center - size * 0.13,
            width: size * 0.26,
            height: size * 0.26,
            child: const CustomPaint(painter: _FlowerCenterPainter()),
          ),
        ],
      ),
    );
  }
}

/// One petal. When picked, it slides away from the flower, spins a little
/// and fades out over a couple of seconds.
class _Petal extends StatelessWidget {
  final bool picked;
  final Color color;
  final bool driftRight;
  final VoidCallback onTap;

  const _Petal({
    required this.picked,
    required this.color,
    required this.driftRight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: picked ? 1 : 0),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeIn,
      builder: (context, t, child) {
        if (t >= 1) return const SizedBox.shrink();
        return Opacity(
          opacity: 1 - t,
          child: Transform.translate(
            offset: Offset((driftRight ? 1 : -1) * t * 40, -t * 160),
            child: Transform.rotate(
              angle: (driftRight ? 1 : -1) * t * pi * 0.8,
              child: child,
            ),
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(painter: _PetalPainter(color)),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final Color color;

  _PetalPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final petal = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(-w * 0.15, h * 0.7, w * 0.05, h * 0.05, w / 2, 0)
      ..cubicTo(w * 0.95, h * 0.05, w * 1.15, h * 0.7, w / 2, h)
      ..close();
    canvas.drawPath(petal, Paint()..color = color);
    canvas.drawLine(
      Offset(w / 2, h * 0.85),
      Offset(w / 2, h * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = w * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_PetalPainter oldDelegate) => oldDelegate.color != color;
}

class _FlowerCenterPainter extends CustomPainter {
  const _FlowerCenterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xffF7C59F));
    // Little seed dots.
    final dot = Paint()..color = AppColors.primaryDeep.withValues(alpha: 0.25);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r * 0.55, r * 0.07, dot);
    }
    canvas.drawCircle(c, r * 0.12, dot);
  }

  @override
  bool shouldRepaint(_FlowerCenterPainter oldDelegate) => false;
}
