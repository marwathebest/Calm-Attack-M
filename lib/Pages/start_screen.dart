/// Start screen for the Calm Attack application.
///
/// This screen serves as the main entry point where users begin their
/// panic attack management session. It provides a welcoming interface
/// with clear call-to-action to start the breathing exercise.

import 'dart:math';

import 'package:flutter/material.dart';

import '../Animations/breathing_flower.dart';

import 'breathing_screen.dart';
import '../core/constants/app_constants.dart';
import '../core/widgets/botanical_background.dart';
import '../core/widgets/common_widgets.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/session_utils.dart';
import '../core/widgets/talk_button.dart';

/// The start screen widget that welcomes users and initiates sessions.
///
/// This screen displays:
/// - A welcoming panic attack question
/// - App branding image
/// - Get Started button to begin the session
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      floatingActionButton: const TalkToBloomButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: BotanicalBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                // At least screen height, so the content stays centered
                // vertically, while still scrolling on very small screens.
                constraints: BoxConstraints(
                  minHeight: max(0, constraints.maxHeight - 64),
                ),
                child: Center(
                  child: ConstrainedBox(
                    // Keep the layout comfortable on tablets and the web.
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: AppSizes.spacingMedium),

                        // Main welcome message
                        ScreenHeader(
                          title: 'Are you having a\nPanic Attack?',
                          titleStyle: AppTextStyles.heading1.copyWith(
                            color: AppColors.primaryDeep,
                          ),
                        ),

                        const SizedBox(height: AppSizes.spacingMedium),

                        // The app's flower character, gently breathing
                        FlowerMascot(
                          width: min(
                            screenSize.width > 600
                                ? 260.0
                                : screenSize.width * 0.5,
                            screenSize.height * 0.28,
                          ),
                        ),

                        const SizedBox(height: AppSizes.spacingLarge * 2),

                        // Get Started button
                        _buildGetStartedButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the Get Started button with session initialization.
  ///
  /// When pressed, this button:
  /// 1. Creates a new session start time
  /// 2. Navigates to the breathing screen
  /// 3. Passes the session start time for tracking
  Widget _buildGetStartedButton(BuildContext context) {
    return AppElevatedButton(
      text: 'Get Started',
      backgroundColor: AppColors.primaryDeep,
      onPressed: () => _handleGetStarted(context),
    );
  }

  /// Handles the Get Started button press.
  ///
  /// Creates a new session and navigates to the breathing screen.
  void _handleGetStarted(BuildContext context) {
    final startTime = SessionUtils.createSessionStart();

    NavigationUtils.navigateToScreen(
      context,
      BreathingScreen(startTime: startTime),
    );
  }
}
