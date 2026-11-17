/// All exercises in one place.
///
/// Lets the user jump straight to any exercise instead of going through
/// the full guided sequence.
library;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/wallpaper_service.dart';
import '../core/widgets/botanical_background.dart';
import 'audio_screen.dart';
import 'breathing_screen.dart';
import 'bubble_pop_game_screen.dart';
import 'companion_screen.dart';
import 'line_trace_screen.dart';
import 'math_game_screen.dart';
import 'patterns_screen.dart';
import 'petal_game_screen.dart';
import 'puzzle_game_screen.dart';
import 'smell_screen.dart';

class _Exercise {
  final String name;
  final String hint;
  final IconData icon;
  final Widget Function(DateTime start)? open;

  /// Runs instead of opening a screen, e.g. setting the wallpaper.
  final Future<void> Function(BuildContext context)? action;

  const _Exercise(this.name, this.hint, this.icon, this.open, {this.action});
}

/// Only on Android: opens the preview for the calm live wallpaper.
final _wallpaper = _Exercise(
  'Calm Wallpaper',
  'Breathing flower on your home screen',
  Icons.wallpaper_rounded,
  null,
  action: (context) async {
    final opened = await CalmWallpaper.openPreview();
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Open your phone\'s wallpaper settings and choose '
          '"Calm Attack" under live wallpapers.',
        ),
      ));
    }
  },
);

final _exercises = <_Exercise>[
  _Exercise('Breathing', 'Breathe with the flower', Icons.air_rounded,
      (s) => BreathingScreen(startTime: s)),
  _Exercise('Calm Sounds', 'Rain, waves, birds and more',
      Icons.music_note_rounded, (s) => AudioScreen(startTime: s)),
  _Exercise('Scents', 'Imagine a pleasant smell', Icons.local_florist_outlined,
      (s) => SmellScreen(startTime: s)),
  _Exercise('Bubbles', 'Pop them in order', Icons.bubble_chart_outlined,
      (s) => BubblePopGameScreen(startTime: s)),
  _Exercise('Petals', 'Pick petals one by one', Icons.filter_vintage_outlined,
      (s) => PetalGameScreen(startTime: s)),
  _Exercise('Trace a Line', 'Follow the dots slowly', Icons.gesture_rounded,
      (s) => LineTraceScreen(startTime: s)),
  _Exercise('Easy Math', 'Simple sums, no timer', Icons.calculate_outlined,
      (s) => MathGameScreen(startTime: s)),
  _Exercise('Puzzle', 'Put the picture together', Icons.extension_outlined,
      (s) => PuzzleGameScreen(startTime: s)),
  _Exercise('My Patterns', 'Learn your possible triggers',
      Icons.insights_rounded, (_) => const PatternsScreen()),
  _Exercise('Talk to Bloom', 'Your calm AI companion', Icons.chat_rounded,
      (_) => const CompanionScreen()),
];

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // One session time for everything opened from here.
    final start = DateTime.now();
    final items = [..._exercises, if (CalmWallpaper.isSupported) _wallpaper];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDeep,
        elevation: 0,
        title: const Text('All Exercises'),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          top: false,
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSizes.mediumPadding),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              final isChat = e.name == 'Talk to Bloom';
              return Material(
                color: isChat
                    ? AppColors.primaryDeep
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(22),
                elevation: 1,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => e.action != null
                      ? e.action!(context)
                      : NavigationUtils.navigateToScreen(
                          context,
                          e.open!(start),
                        ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isChat
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppColors.surfaceSoft,
                          child: Icon(
                            e.icon,
                            size: 30,
                            color: isChat
                                ? AppColors.textOnPrimary
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          e.name,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isChat
                                ? AppColors.textOnPrimary
                                : AppColors.primaryDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.hint,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isChat
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
