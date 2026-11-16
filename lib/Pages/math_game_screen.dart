/// Easy math game for the Calm Attack application.
///
/// Simple additions and subtractions with three answers to choose from.
/// Gentle problem solving draws attention to the thinking part of the
/// mind. There is no timer and no score to lose.
library;

import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/widgets/exercise_layout.dart';
import 'puzzle_game_screen.dart';

class _Question {
  final String text;
  final int answer;
  final List<int> choices;

  const _Question(this.text, this.answer, this.choices);

  factory _Question.random(Random random) {
    final add = random.nextBool();
    int a = random.nextInt(10) + 1;
    int b = random.nextInt(10) + 1;
    if (!add && b > a) {
      final swap = a;
      a = b;
      b = swap;
    }
    final answer = add ? a + b : a - b;

    // Two nearby wrong answers, never negative and never the answer.
    final choices = <int>{answer};
    while (choices.length < 3) {
      final wrong = answer + random.nextInt(5) - 2;
      if (wrong >= 0) choices.add(wrong);
    }
    final shuffled = choices.toList()..shuffle(random);
    return _Question('$a ${add ? '+' : '−'} $b', answer, shuffled);
  }
}

class MathGameScreen extends StatefulWidget {
  final DateTime startTime;

  const MathGameScreen({super.key, required this.startTime});

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen> {
  static const _praise = [
    'Nice and calm.',
    'That\'s right.',
    'Well done.',
    'You\'ve got this.',
    'Good thinking.',
  ];

  final Random _random = Random();
  late _Question _question = _Question.random(_random);
  int _solved = 0;
  int? _wrongChoice;
  String _message = 'Take your time.';

  void _choose(int value) {
    if (value == _question.answer) {
      setState(() {
        _solved++;
        _message = _praise[_random.nextInt(_praise.length)];
        _wrongChoice = null;
        _question = _Question.random(_random);
      });
    } else {
      setState(() {
        _wrongChoice = value;
        _message = 'Not quite. Try again, slowly.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExerciseLayout(
      title: 'Easy Math',
      instruction: 'Solve each one at your own pace. There is no timer.',
      startTime: widget.startTime,
      nextScreen: (start) => PuzzleGameScreen(startTime: start),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Container(
                key: ValueKey(_question.text),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Text(
                  '${_question.text} = ?',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primaryDeep,
                    fontSize: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                for (final choice in _question.choices)
                  _ChoiceButton(
                    value: choice,
                    dimmed: choice == _wrongChoice,
                    onTap: () => _choose(choice),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingLarge),
            Text(_message, style: AppTextStyles.bodyLarge),
            const SizedBox(height: AppSizes.spacingXSmall),
            Text(
              _solved == 0 ? '' : 'Solved: $_solved',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final int value;
  final bool dimmed;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.value,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dimmed ? 0.4 : 1,
      child: Material(
        color: AppColors.primary,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 76,
            child: Center(
              child: Text(
                '$value',
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textOnPrimary,
                  fontSize: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
