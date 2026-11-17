/// Clearly labeled button that opens the chat with Bloom, the companion.
library;

import 'package:flutter/material.dart';

import '../../Pages/companion_screen.dart';
import '../constants/app_constants.dart';
import '../utils/navigation_utils.dart';

/// Space screens leave at the top so this button never covers a title.
const double talkButtonClearance = 64;

class TalkToBloomButton extends StatelessWidget {
  const TalkToBloomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'talk-to-bloom',
      tooltip: 'Chat with Bloom, your calm companion',
      backgroundColor: AppColors.primaryDeep,
      foregroundColor: AppColors.textOnPrimary,
      elevation: 3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      onPressed: () =>
          NavigationUtils.navigateToScreen(context, const CompanionScreen()),
      icon: const Icon(Icons.chat_rounded, size: 20),
      label: const Text(
        'Talk to Bloom',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
