/// My Patterns: what the user's check-ins show over time.
///
/// Gentle, cautious insights ("might be linked", never "causes"), shown
/// only once there are enough check-ins to mean something.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/checkin_store.dart';
import '../core/widgets/botanical_background.dart';
import 'checkin_screen.dart';
import 'companion_screen.dart';
import 'trigger_tools_screen.dart';

class PatternsScreen extends StatefulWidget {
  const PatternsScreen({super.key});

  @override
  State<PatternsScreen> createState() => _PatternsScreenState();
}

class _PatternsScreenState extends State<PatternsScreen> {
  /// Check-ins needed before showing trigger patterns.
  static const _minForPatterns = 5;

  List<CheckIn>? _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final items = await CheckInStore.load();
    if (mounted) setState(() => _items = items);
  }

  Future<void> _addCheckIn() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
    _reload();
  }

  Future<void> _delete(CheckIn entry) async {
    await CheckInStore.delete(entry);
    _reload();
  }

  /// Trigger -> number of check-ins it appeared in, most common first.
  List<MapEntry<String, int>> _triggerCounts(List<CheckIn> items) {
    final counts = <String, int>{};
    for (final c in items) {
      for (final t in c.triggers) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  static const _timeBuckets = ['Morning', 'Afternoon', 'Evening', 'Night'];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static String _timeBucket(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 22) return 'Evening';
    return 'Night';
  }

  Map<String, int> _byTimeOfDay(List<CheckIn> items) {
    final m = {for (final b in _timeBuckets) b: 0};
    for (final c in items) {
      m[_timeBucket(c.time)] = m[_timeBucket(c.time)]! + 1;
    }
    return m;
  }

  Map<String, int> _byWeekday(List<CheckIn> items) {
    final m = {for (final d in _weekdays) d: 0};
    for (final c in items) {
      final d = _weekdays[c.time.weekday - 1];
      m[d] = m[d]! + 1;
    }
    return m;
  }

  /// One plain sentence about the busiest time, only if it clearly stands out.
  String _whenSentence(List<CheckIn> items) {
    final byTime = _byTimeOfDay(items).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = byTime.first;
    if (top.value * 2 >= items.length && top.value >= 3) {
      return 'Many of your attacks happen in the ${top.key.toLowerCase()} '
          '(${top.value} of ${items.length}).';
    }
    return 'Your attacks are spread across the day.';
  }

  /// Pairs of triggers that were noted together at least twice.
  List<MapEntry<String, int>> _pairs(List<CheckIn> items) {
    final counts = <String, int>{};
    for (final c in items) {
      final t = c.triggers.where((x) => x != noClearTrigger).toList()..sort();
      for (var i = 0; i < t.length; i++) {
        for (var j = i + 1; j < t.length; j++) {
          final key = '${t[i]} + ${t[j]}';
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    return counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  void _openTools(String trigger) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TriggerToolsScreen(trigger: trigger)),
    );
  }

  Future<void> _pickTrigger() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final g in triggerGroups)
              for (final t in g.options)
                if (t != noClearTrigger)
                  ListTile(
                    title: Text(t),
                    subtitle: Text(g.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(t),
                  ),
          ],
        ),
      ),
    );
    if (choice != null) _openTools(choice);
  }

  void _talkToBloom(List<CheckIn> items) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanionScreen(checkInSummary: _summary(items)),
      ),
    );
  }

  double? _averageStrength(Iterable<CheckIn> items) {
    if (items.isEmpty) return null;
    return items.map((c) => c.strength).reduce((a, b) => a + b) / items.length;
  }

  String _summary(List<CheckIn> items) {
    final b = StringBuffer('Calm Attack check-ins (${items.length} total)\n\n');
    for (final e in _triggerCounts(items)) {
      b.writeln('${e.key}: ${e.value}');
    }
    b.writeln();
    for (final c in items) {
      b.write('${_formatDate(c.time)} - strength ${c.strength}/10');
      if (c.triggers.isNotEmpty) b.write(' - ${c.triggers.join(', ')}');
      if (c.note.isNotEmpty) b.write(' - "${c.note}"');
      b.writeln();
    }
    return b.toString();
  }

  Future<void> _copySummary(List<CheckIn> items) async {
    await Clipboard.setData(ClipboardData(text: _summary(items)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Summary copied. You can paste it in a message to your therapist or doctor.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryDeep,
        elevation: 0,
        title: const Text('My Patterns'),
        actions: [
          if (items != null && items.isNotEmpty)
            IconButton(
              tooltip: 'Copy a summary to share',
              onPressed: () => _copySummary(items),
              icon: const Icon(Icons.copy_rounded),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCheckIn,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add a check-in'),
      ),
      body: BotanicalBackground(
        child: SafeArea(
          top: false,
          child: items == null
              ? const Center(child: CircularProgressIndicator())
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children:
                          items.isEmpty ? [_emptyState()] : _content(items),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return _Card(
      child: Column(
        children: [
          const Icon(Icons.insights_rounded,
              size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Learn what comes before your attacks',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            'After an attack, add a quick check-in: how strong it was and '
            'anything that might have played a part. After a few, you\'ll '
            'see patterns here. Everything stays on your phone.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  List<Widget> _content(List<CheckIn> items) {
    final now = DateTime.now();
    final last30 = items.where((c) => now.difference(c.time).inDays < 30);
    final prev30 = items.where((c) {
      final d = now.difference(c.time).inDays;
      return d >= 30 && d < 60;
    });
    final avgNow = _averageStrength(last30);
    final avgBefore = _averageStrength(prev30);
    final counts = _triggerCounts(items);
    final withTriggers = counts.where((e) => e.key != noClearTrigger).toList();
    final noTriggerCount = counts
        .where((e) => e.key == noClearTrigger)
        .fold<int>(0, (sum, e) => sum + e.value);

    return [
      // Overview numbers.
      Row(
        children: [
          Expanded(child: _Stat(label: 'Check-ins', value: '${items.length}')),
          const SizedBox(width: 12),
          Expanded(
            child: _Stat(
              label: 'Last 30 days',
              value: '${last30.length}',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Stat(
              label: 'Avg. strength',
              value: avgNow == null ? '–' : avgNow.toStringAsFixed(1),
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),

      // Strength trend, only when there is something to compare.
      if (avgNow != null &&
          avgBefore != null &&
          last30.length >= 2 &&
          prev30.length >= 2)
        _Card(
          child: Text(
            avgNow < avgBefore
                ? 'Your attacks have felt milder lately: '
                    '${avgNow.toStringAsFixed(1)} on average this month, '
                    'down from ${avgBefore.toStringAsFixed(1)}. That\'s real progress.'
                : 'Average strength this month: ${avgNow.toStringAsFixed(1)} '
                    '(last month: ${avgBefore.toStringAsFixed(1)}). '
                    'Hard stretches happen. Keep being kind to yourself.',
            style: AppTextStyles.bodyMedium,
          ),
        ),

      // Trigger patterns.
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Possible triggers', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            if (items.length < _minForPatterns)
              Text(
                'Add ${_minForPatterns - items.length} more check-in'
                '${_minForPatterns - items.length == 1 ? '' : 's'} '
                'to start seeing patterns.',
                style: AppTextStyles.bodyMedium,
              )
            else ...[
              if (withTriggers.isEmpty)
                Text('No triggers noted so far.',
                    style: AppTextStyles.bodyMedium)
              else ...[
                Text(
                  '"${withTriggers.first.key}" came up in '
                  '${withTriggers.first.value} of ${items.length} check-ins. '
                  'It might be linked to your attacks.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                for (final e in withTriggers.take(6))
                  _TriggerBar(
                    label: e.key,
                    count: e.value,
                    total: items.length,
                    onTap: () => _openTools(e.key),
                  ),
                Text(
                  'Tap a trigger to make a plan or practise facing it.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (noTriggerCount > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '$noTriggerCount had no clear trigger. That\'s common: '
                  'panic attacks can come out of the blue.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),

      // Deeper patterns, once there is enough to mean something.
      if (items.length >= _minForPatterns) ...[
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('When attacks happen', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Text(
                _whenSentence(items),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              _ColumnChart(values: _byTimeOfDay(items)),
              const SizedBox(height: 16),
              _ColumnChart(values: _byWeekday(items)),
            ],
          ),
        ),
        if (_pairs(items).isNotEmpty)
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Triggers that come together',
                    style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                for (final p in _pairs(items).take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${p.key} together: ${p.value} times',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                Text(
                  'Sometimes it\'s the combination, like a stressful day '
                  'after little sleep, that matters most.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
      ],

      // Tools for any trigger, available from the first day.
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prepare for a trigger', style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            Text(
              'Make a plan for before, during and after, or practise '
              'facing it one small step at a time.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickTrigger,
              icon: const Icon(Icons.shield_moon_outlined),
              label: const Text('Choose a trigger'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDeep,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),

      // Talk it through with Bloom.
      _Card(
        color: AppColors.primaryDeep,
        child: Row(
          children: [
            const Icon(Icons.chat_rounded, color: AppColors.textOnPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Talk it through with Bloom. Bloom will read your '
                'check-ins and help you make sense of them.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _talkToBloom(items),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.textOnPrimary,
                foregroundColor: AppColors.primaryDeep,
              ),
              child: const Text('Start'),
            ),
          ],
        ),
      ),

      // Gentle guidance on avoidance.
      _Card(
        color: AppColors.surfaceSoft,
        child: Text(
          'Knowing your triggers helps you prepare. Avoiding every trigger '
          'can make fear stronger over time, though. A therapist or doctor '
          'can help you decide which ones to avoid and which to slowly '
          'face. You can share your check-ins with them using the copy '
          'button at the top.',
          style: AppTextStyles.bodySmall.copyWith(height: 1.5),
        ),
      ),

      // History.
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text('Recent check-ins', style: AppTextStyles.heading3),
      ),
      for (final c in items.take(30))
        _Card(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceSoft,
                child: Text(
                  '${c.strength}',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(c.time),
                        style: AppTextStyles.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    if (c.triggers.isNotEmpty)
                      Text(c.triggers.join(' · '),
                          style: AppTextStyles.bodySmall),
                    if (c.note.isNotEmpty)
                      Text('"${c.note}"',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          )),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete this check-in',
                onPressed: () => _delete(c),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
    ];
  }
}

String _formatDate(DateTime t) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '${t.day} ${months[t.month - 1]} ${t.year}, $h:$m';
}

class _Card extends StatelessWidget {
  final Widget child;
  final Color? color;

  const _Card({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primaryDeep,
              )),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}

/// Simple column chart: one labeled column per bucket.
class _ColumnChart extends StatelessWidget {
  final Map<String, int> values;

  const _ColumnChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final highest = values.values.fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final e in values.entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('${e.value}', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 2),
                    Container(
                      height: highest == 0 ? 0 : 60 * e.value / highest,
                      decoration: BoxDecoration(
                        color: e.value == highest && highest > 0
                            ? AppColors.primary
                            : AppColors.accentPeach,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      e.key,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TriggerBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final VoidCallback? onTap;

  const _TriggerBar({
    required this.label,
    required this.count,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
                Text('$count', style: AppTextStyles.bodyMedium),
                if (onTap != null)
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: count / total,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
