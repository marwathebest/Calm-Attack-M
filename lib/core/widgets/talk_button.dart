/// Small floating button that opens the chat with Bloom, the companion.
library;

import 'package:flutter/material.dart';

import '../../Pages/companion_screen.dart';
import '../constants/app_constants.dart';
import '../utils/navigation_utils.dart';

class TalkToBloomButton extends StatelessWidget {
  const TalkToBloomButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'talk-to-bloom',
      tooltip: 'Talk to Bloom',
      backgroundColor: AppColors.surfaceSoft,
      foregroundColor: AppColors.primaryDeep,
      elevation: 2,
      onPressed: () =>
          NavigationUtils.navigateToScreen(context, const CompanionScreen()),
      child: const Icon(Icons.chat_bubble_outline_rounded),
    );
  }
}
