/// Breathing exercise screen for the Calm Attack application.
///
/// This screen provides a guided breathing exercise to help users
/// manage panic attacks through controlled breathing patterns.
/// Features a visual breathing animation and clear phase indicators.

import 'dart:math';

import 'package:flutter/material.dart';

import '../Animations/breathing_flower.dart';
import 'audio_screen.dart';
import 'finish_screen.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/botanical_background.dart';
import '../core/widgets/common_widgets.dart';
import '../core/utils/navigation_utils.dart';
import '../core/widgets/talk_button.dart';

/// The breathing exercise screen widget.
///
/// This screen displays:
/// - Breathing phase indicators (Inhale, Hold, Exhale)
/// - Current breathing instruction text
/// - Animated breathing cloud
/// - Navigation buttons for Next/Finish
class BreathingScreen extends StatefulWidget {
  /// The start time of the current session for tracking purposes
  final DateTime startTime;

  const BreathingScreen({super.key, required this.startTime});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen> {
  /// Current breathing phase text displayed to the user
  String _breathingText = BreathingConstants.inhalePhase;

  /// Updates the breathing text based on the current animation phase.
  ///
  /// This callback is called by the breathing animation to update
  /// the displayed instruction text.
  void _updateBreathingText(String text) {
    setState(() {
      _breathingText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: const TalkToBloomButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: BotanicalBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spacingMedium),

              // Breathing phase indicators
              const _BreathingPhases(),

              const SizedBox(height: AppSizes.spacingSmall),

              // Current breathing instruction
              Text(
                _breathingText,
                style: AppTextStyles.bodyLarge,
              ),

              // Flower that opens and closes with the breath
              Expanded(
                child: Center(
                  child: BreathingFlower(
                    size: min(screenSize.width * 0.8, 320),
                    callback: _updateBreathingText,
                  ),
                ),
              ),

              // Navigation buttons
              _NavigationButtons(startTime: widget.startTime),

              const SizedBox(height: AppSizes.spacingMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display the three breathing phases with their durations.
///
/// Shows a horizontal layout with:
/// - Inhale (3 seconds)
/// - Hold (3 seconds)
/// - Exhale (3 seconds)
/// Each phase is separated by vertical dividers.
class _BreathingPhases extends StatelessWidget {
  const _BreathingPhases();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
        child: const Row(
          children: [
            Expanded(
              child: _BreathingPhaseWidget(
                duration: '${BreathingConstants.inhaleSeconds}',
                phase: BreathingConstants.inhalePhase,
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _BreathingPhaseWidget(
                duration: '${BreathingConstants.holdSeconds}',
                phase: BreathingConstants.holdPhase,
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _BreathingPhaseWidget(
                duration: '${BreathingConstants.exhaleSeconds}',
                phase: BreathingConstants.exhalePhase,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual breathing phase display widget.
///
/// Shows the duration and phase name in a consistent format.
class _BreathingPhaseWidget extends StatelessWidget {
  /// Duration in seconds for this phase
  final String duration;

  /// Name of the breathing phase (INHALE, HOLD, EXHALE)
  final String phase;

  const _BreathingPhaseWidget({
    required this.duration,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          duration,
          style: AppTextStyles.bodyMedium,
        ),
        const Text(
          'Seconds',
          style: TextStyle(fontSize: 10),
        ),
        Text(
          phase,
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

/// Vertical divider for separating breathing phases.
class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return const VerticalDivider(
      color: AppColors.textPrimary,
      thickness: 2.5,
      indent: 26,
      endIndent: 15,
    );
  }
}

/// Navigation buttons for moving to next screen or finishing session.
///
/// Provides:
/// - Next button to continue to audio screen
/// - Finish Session button to end the session early
class _NavigationButtons extends StatelessWidget {
  /// The start time of the current session
  final DateTime startTime;

  const _NavigationButtons({required this.startTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Next button
        AppElevatedButton(
          text: 'Next',
          widthRatio: AppSizes.buttonWidthRatio,
          onPressed: () => _navigateToAudioScreen(context),
        ),

        // Finish Session button
        AppTextButton(
          text: 'Finish Session',
          onPressed: () => _navigateToFinishScreen(context),
        ),
      ],
    );
  }

  /// Navigates to the audio screen.
  void _navigateToAudioScreen(BuildContext context) {
    NavigationUtils.navigateToScreen(
      context,
      AudioScreen(startTime: startTime),
    );
  }

  /// Navigates to the finish screen.
  void _navigateToFinishScreen(BuildContext context) {
    NavigationUtils.navigateToScreen(
      context,
      FinishScreen(startTime: startTime),
    );
  }
}
