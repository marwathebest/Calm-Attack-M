/// After-attack check-ins, stored only on this device.
///
/// Each check-in records when an attack happened, how strong it was, how
/// long the session took and any possible triggers. Nothing is sent
/// anywhere; the user can copy a summary to share with a professional.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A group of trigger choices shown together on the check-in screen.
class TriggerGroup {
  final String title;
  final List<String> options;

  const TriggerGroup(this.title, this.options);
}

/// Shown when the user can't point to anything. Some panic attacks come
/// without a clear trigger, and that is common.
const noClearTrigger = 'No clear trigger';

const triggerGroups = [
  TriggerGroup('Places', [
    'Enclosed space',
    'Crowd',
    'Driving or traffic',
    'Away from home',
  ]),
  TriggerGroup('Situations', [
    'Public speaking',
    'Argument',
    'Money worries',
    'Work or study stress',
    'Health worries',
    'Being alone',
    'Bad news',
  ]),
  TriggerGroup('Body', [
    'Little sleep',
    'Caffeine',
    'Hungry',
    'Feeling unwell',
  ]),
  TriggerGroup('Other', [noClearTrigger]),
];

class CheckIn {
  final DateTime time;

  /// How strong the attack felt, 1 to 10.
  final int strength;

  /// Minutes spent in the calming session, if known.
  final int? minutes;

  final List<String> triggers;
  final String note;

  const CheckIn({
    required this.time,
    required this.strength,
    required this.triggers,
    this.minutes,
    this.note = '',
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'strength': strength,
        'minutes': minutes,
        'triggers': triggers,
        'note': note,
      };

  static CheckIn? fromJson(Object? json) {
    if (json is! Map) return null;
    final time = DateTime.tryParse('${json['time']}');
    final strength = json['strength'];
    if (time == null || strength is! int) return null;
    return CheckIn(
      time: time,
      strength: strength,
      minutes: json['minutes'] is int ? json['minutes'] as int : null,
      triggers: [
        for (final t in (json['triggers'] as List? ?? const [])) '$t',
      ],
      note: '${json['note'] ?? ''}',
    );
  }
}

class CheckInStore {
  static const _key = 'checkins_v1';

  /// All check-ins, newest first.
  static Future<List<CheckIn>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      final items = [
        for (final e in list) CheckIn.fromJson(e),
      ].whereType<CheckIn>().toList()
        ..sort((a, b) => b.time.compareTo(a.time));
      return items;
    } catch (_) {
      return [];
    }
  }

  static Future<void> add(CheckIn entry) async {
    final items = await load();
    items.insert(0, entry);
    await _save(items);
  }

  static Future<void> delete(CheckIn entry) async {
    final items = await load();
    items.removeWhere((e) => e.time == entry.time);
    await _save(items);
  }

  static Future<void> _save(List<CheckIn> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final e in items) e.toJson()]),
    );
  }
}
