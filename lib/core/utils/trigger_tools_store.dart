/// Trigger plans and facing ladders, stored only on this device.
///
/// A plan says what helps before, during and after meeting a trigger.
/// A ladder is a list of small steps for slowly facing a trigger, from
/// easiest to hardest (graded exposure, a core part of CBT for panic).
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TriggerPlan {
  final String trigger;
  final String before;
  final String during;
  final String after;

  /// A sentence the user writes to themselves, shown first in hard moments.
  final String myWords;

  const TriggerPlan({
    required this.trigger,
    this.before = '',
    this.during = '',
    this.after = '',
    this.myWords = '',
  });

  bool get isEmpty =>
      before.isEmpty && during.isEmpty && after.isEmpty && myWords.isEmpty;

  Map<String, String> toJson() => {
        'trigger': trigger,
        'before': before,
        'during': during,
        'after': after,
        'myWords': myWords,
      };

  static TriggerPlan fromJson(Map json) => TriggerPlan(
        trigger: '${json['trigger']}',
        before: '${json['before'] ?? ''}',
        during: '${json['during'] ?? ''}',
        after: '${json['after'] ?? ''}',
        myWords: '${json['myWords'] ?? ''}',
      );

  /// Starter ideas so the user never faces a blank page. They can edit
  /// or replace every line.
  static TriggerPlan suggested(String trigger) {
    final s = _suggestions[trigger];
    return TriggerPlan(
      trigger: trigger,
      before: s?[0] ??
          'Plan your time, rest well, and have a calming exercise ready.',
      during: s?[1] ??
          'Breathe 3-3-3. Name 5 things you can see. Remind yourself: this feeling peaks and passes.',
      after: s?[2] ??
          'Rest, drink some water, and note what happened in a check-in.',
      myWords:
          "I've been through this before, and it passed. It will pass again.",
    );
  }
}

const _suggestions = <String, List<String>>{
  'Enclosed space': [
    'Know where the exit is. Wear comfortable clothes.',
    'Look at a fixed point. Slow breathing. Feel your feet on the floor.',
    'Step into open air for a minute if you can.',
  ],
  'Crowd': [
    'Go at a quieter time if possible. Stand near the edge or an exit.',
    'Hold something cold or textured. Breathe out slowly, longer than in.',
    'Find a calm corner and give yourself a few quiet minutes.',
  ],
  'Driving or traffic': [
    'Plan the route, leave early, and have calm music ready.',
    'If safe, pull over. Hands on the wheel, slow breaths, name what you see.',
    'Sit for a moment before getting out. Notice that you made it.',
  ],
  'Public speaking': [
    'Practice out loud. Arrive early. Have water nearby.',
    'Pause and breathe between points. Look at one friendly face.',
    'Celebrate that you did it, whatever happened.',
  ],
  'Argument': [
    "Decide you can take a break if it gets heated.",
    'Say "I need a minute," step away and breathe.',
    'Come back to the talk only when your body feels calmer.',
  ],
  'Money worries': [
    'Set a fixed time to look at money, not late at night.',
    'Write the worry down, then breathe. One step at a time.',
    'Pick one small, doable action and leave the rest for later.',
  ],
  'Little sleep': [
    'Keep a steady bedtime. Screens off 30 minutes before.',
    'Remember that tiredness makes the body more sensitive. It is not danger.',
    'Plan a short rest or an early night.',
  ],
  'Caffeine': [
    'Try smaller amounts or switch to decaf after midday.',
    'A racing heart after coffee is caffeine, not danger. Breathe slowly.',
    'Drink water and notice how quickly it settles.',
  ],
};

class LadderStep {
  final String text;

  /// How anxious the user expects to feel, 0 to 10.
  final int expected;

  /// How anxious they actually felt after doing it, if done.
  final int? actual;

  const LadderStep({required this.text, required this.expected, this.actual});

  bool get done => actual != null;

  LadderStep withActual(int? value) =>
      LadderStep(text: text, expected: expected, actual: value);

  Map<String, dynamic> toJson() =>
      {'text': text, 'expected': expected, 'actual': actual};

  static LadderStep fromJson(Map json) => LadderStep(
        text: '${json['text']}',
        expected: json['expected'] is int ? json['expected'] as int : 5,
        actual: json['actual'] is int ? json['actual'] as int : null,
      );
}

class TriggerToolsStore {
  static const _plansKey = 'trigger_plans_v1';
  static const _laddersKey = 'trigger_ladders_v1';

  static Future<Map<String, dynamic>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> _write(String key, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<TriggerPlan?> plan(String trigger) async {
    final data = await _read(_plansKey);
    final json = data[trigger];
    return json is Map ? TriggerPlan.fromJson(json) : null;
  }

  static Future<Set<String>> triggersWithPlans() async =>
      (await _read(_plansKey)).keys.toSet();

  static Future<void> savePlan(TriggerPlan plan) async {
    final data = await _read(_plansKey);
    if (plan.isEmpty) {
      data.remove(plan.trigger);
    } else {
      data[plan.trigger] = plan.toJson();
    }
    await _write(_plansKey, data);
  }

  static Future<List<LadderStep>> ladder(String trigger) async {
    final data = await _read(_laddersKey);
    final list = data[trigger];
    if (list is! List) return [];
    return [
      for (final e in list)
        if (e is Map) LadderStep.fromJson(e)
    ];
  }

  static Future<void> saveLadder(String trigger, List<LadderStep> steps) async {
    final data = await _read(_laddersKey);
    if (steps.isEmpty) {
      data.remove(trigger);
    } else {
      data[trigger] = [for (final s in steps) s.toJson()];
    }
    await _write(_laddersKey, data);
  }
}
