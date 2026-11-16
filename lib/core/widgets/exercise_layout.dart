/// Shared page layout for exercise screens.
///
/// Gives every game the same structure: a title and short instruction at
/// the top, the activity in the middle, and Next / Finish Session at the
/// bottom, all on the botanical background.
library;

import 'package:flutter/material.dart';

import '../../Pages/finish_screen.dart';
import '../constants/app_constants.dart';
import '../utils/navigation_utils.dart';
import 'botanical_background.dart';
import 'common_widgets.dart';
import 'talk_button.dart';

class ExerciseLayout extends StatelessWidget {
  /// Short title, e.g. "Pick the petals".
  final String title;

  /// One calm sentence telling the user what to do.
  final String instruction;

  /// The activity itself; it fills the space between header and buttons.
  final Widget child;

  /// When the session started, for the finish screen's time summary.
  final DateTime startTime;

  /// Builds the next exercise. When null, Next goes to the finish screen.
  final Widget Function(DateTime startTime)? nextScreen;

  const ExerciseLayout({
    super.key,
    required this.title,
    required this.instruction,
    required this.child,
    required this.startTime,
    this.nextScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const TalkToBloomButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: BotanicalBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spacingLarge),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.heading3.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppSizes.spacingXSmall),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.largePadding,
                ),
                child: Text(
                  instruction,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(child: child),
              AppElevatedButton(
                text: 'Next',
                widthRatio: AppSizes.buttonWidthRatio,
                onPressed: () => NavigationUtils.navigateToScreen(
                  context,
                  nextScreen?.call(startTime) ??
                      FinishScreen(startTime: startTime),
                ),
              ),
              AppTextButton(
                text: 'Finish Session',
                onPressed: () => NavigationUtils.navigateToScreen(
                  context,
                  FinishScreen(startTime: startTime),
                ),
              ),
              const SizedBox(height: AppSizes.spacingSmall),
            ],
          ),
        ),
      ),
    );
  }
}
