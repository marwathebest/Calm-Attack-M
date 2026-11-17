/// Optional check-in after an attack: how strong it was and what might
/// have set it off. Quick taps, no typing needed, and skipping is fine.
library;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/checkin_store.dart';
import '../core/widgets/botanical_background.dart';
import 'patterns_screen.dart';

class CheckInScreen extends StatefulWidget {
  /// Minutes spent in the session that just ended, if known.
  final int? sessionMinutes;

  const CheckInScreen({super.key, this.sessionMinutes});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  double _strength = 5;
  final Set<String> _triggers = {};
  final TextEditingController _note = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _toggle(String trigger) {
    setState(() {
      if (_triggers.contains(trigger)) {
        _triggers.remove(trigger);
      } else if (trigger == noClearTrigger) {
        // "No clear trigger" replaces any other choice.
        _triggers
          ..clear()
          ..add(trigger);
      } else {
        _triggers
          ..remove(noClearTrigger)
          ..add(trigger);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await CheckInStore.add(CheckIn(
      time: DateTime.now(),
      strength: _strength.round(),
      minutes: widget.sessionMinutes,
      triggers: _triggers.toList(),
      note: _note.text.trim(),
    ));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PatternsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDeep,
        elevation: 0,
        title: const Text('What Happened?'),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.mediumPadding),
                children: [
                  Text(
                    'This is optional and stays on your phone. '
                    'Over time it can show what tends to come before an attack.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingLarge),
                  _Section(
                    title: 'How strong was it?',
                    child: Column(
                      children: [
                        Slider(
                          value: _strength,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${_strength.round()}',
                          activeColor: AppColors.primary,
                          inactiveColor: AppColors.surfaceSoft,
                          onChanged: (v) => setState(() => _strength = v),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Mild', style: AppTextStyles.bodySmall),
                            Text(
                              '${_strength.round()} / 10',
                              style: AppTextStyles.bodyLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDeep,
                              ),
                            ),
                            Text('Very strong', style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  for (final group in triggerGroups)
                    _Section(
                      title: group.title == 'Places'
                          ? 'Anything that might have played a part?\n${group.title}'
                          : group.title,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in group.options)
                            FilterChip(
                              label: Text(t),
                              selected: _triggers.contains(t),
                              onSelected: (_) => _toggle(t),
                              selectedColor: AppColors.accentPeach,
                              checkmarkColor: AppColors.primaryDeep,
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.surfaceSoft,
                              ),
                            ),
                        ],
                      ),
                    ),
                  _Section(
                    title: 'A note for yourself (optional)',
                    child: TextField(
                      controller: _note,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'What was happening, what helped…',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingMedium),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(52),
                      textStyle: AppTextStyles.buttonMedium,
                    ),
                    child: const Text('Save'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
