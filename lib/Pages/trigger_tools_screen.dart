/// Tools for one trigger: a personal plan and a facing ladder.
library;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/trigger_tools_store.dart';
import '../core/widgets/botanical_background.dart';

class TriggerToolsScreen extends StatelessWidget {
  final String trigger;

  const TriggerToolsScreen({super.key, required this.trigger});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primaryDeep,
          elevation: 0,
          title: Text(trigger),
          bottom: const TabBar(
            labelColor: AppColors.primaryDeep,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.shield_moon_outlined), text: 'My plan'),
              Tab(
                  icon: Icon(Icons.stairs_outlined),
                  text: 'Face it step by step'),
            ],
          ),
        ),
        body: BotanicalBackground(
          child: TabBarView(
            children: [
              _PlanTab(trigger: trigger),
              _LadderTab(trigger: trigger),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Plan

class _PlanTab extends StatefulWidget {
  final String trigger;

  const _PlanTab({required this.trigger});

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  final _myWords = TextEditingController();
  final _before = TextEditingController();
  final _during = TextEditingController();
  final _after = TextEditingController();
  bool _loaded = false;
  bool _isSuggestion = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await TriggerToolsStore.plan(widget.trigger);
    final plan = saved ?? TriggerPlan.suggested(widget.trigger);
    if (!mounted) return;
    setState(() {
      _myWords.text = plan.myWords;
      _before.text = plan.before;
      _during.text = plan.during;
      _after.text = plan.after;
      _isSuggestion = saved == null;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await TriggerToolsStore.savePlan(TriggerPlan(
      trigger: widget.trigger,
      myWords: _myWords.text.trim(),
      before: _before.text.trim(),
      during: _during.text.trim(),
      after: _after.text.trim(),
    ));
    if (!mounted) return;
    setState(() => _isSuggestion = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plan saved on your phone.')),
    );
  }

  @override
  void dispose() {
    for (final c in [_myWords, _before, _during, _after]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return _Body(
      children: [
        if (_isSuggestion)
          _Note(
            'These are starter ideas. Change anything so it sounds like you, '
            'then save.',
          ),
        _Field(
          label: 'Words to myself',
          hint: 'What do you want to hear in that moment?',
          icon: Icons.favorite_border,
          controller: _myWords,
        ),
        _Field(
          label: 'Before',
          hint: 'How can you prepare?',
          icon: Icons.wb_twilight,
          controller: _before,
        ),
        _Field(
          label: 'During',
          hint: 'What helps when it starts?',
          icon: Icons.air_rounded,
          controller: _during,
        ),
        _Field(
          label: 'After',
          hint: 'How will you look after yourself?',
          icon: Icons.spa_outlined,
          controller: _after,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check),
          label: const Text('Save my plan'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Facing ladder

/// Example steps for common triggers; the user can add their own instead.
const _exampleSteps = <String, List<(String, int)>>{
  'Crowd': [
    ('Walk past a busy café without going in', 3),
    ('Sit in a café for 10 minutes at a quiet time', 4),
    ('Visit a shop at a busier time for 15 minutes', 6),
    ('Spend 30 minutes in a busy mall', 8),
  ],
  'Enclosed space': [
    ('Sit in a small room with the door open for 5 minutes', 2),
    ('Sit with the door closed for 5 minutes', 4),
    ('Take the lift one floor with someone you trust', 6),
    ('Take the lift several floors alone', 8),
  ],
  'Public speaking': [
    ('Read a paragraph out loud alone', 2),
    ('Record yourself speaking for 1 minute', 3),
    ('Speak for 2 minutes in front of a friend', 5),
    ('Share an idea in a small meeting or class', 7),
  ],
  'Driving or traffic': [
    ('Sit in the parked car for 5 minutes', 2),
    ('Drive around a quiet street', 4),
    ('Drive a short route at a calm time', 6),
    ('Drive a short route at a busier time', 8),
  ],
};

class _LadderTab extends StatefulWidget {
  final String trigger;

  const _LadderTab({required this.trigger});

  @override
  State<_LadderTab> createState() => _LadderTabState();
}

class _LadderTabState extends State<_LadderTab> {
  List<LadderStep>? _steps;

  @override
  void initState() {
    super.initState();
    TriggerToolsStore.ladder(widget.trigger).then((s) {
      if (mounted) setState(() => _steps = _sorted(s));
    });
  }

  List<LadderStep> _sorted(List<LadderStep> s) =>
      [...s]..sort((a, b) => a.expected.compareTo(b.expected));

  Future<void> _update(List<LadderStep> steps) async {
    final sorted = _sorted(steps);
    setState(() => _steps = sorted);
    await TriggerToolsStore.saveLadder(widget.trigger, sorted);
  }

  Future<void> _addStep() async {
    final text = TextEditingController();
    double expected = 4;
    final result = await showDialog<LadderStep>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Add a small step'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: text,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Something a little uncomfortable, not scary',
                ),
              ),
              const SizedBox(height: 16),
              Text('How anxious do you expect to feel? '
                  '${expected.round()} / 10'),
              Slider(
                value: expected,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: AppColors.primary,
                onChanged: (v) => setDialog(() => expected = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (text.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  LadderStep(
                      text: text.text.trim(), expected: expected.round()),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    text.dispose();
    if (result != null) await _update([...?_steps, result]);
  }

  Future<void> _markDone(int index) async {
    final step = _steps![index];
    double felt = step.expected.toDouble();
    final value = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Well done for trying'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How anxious did you actually feel? ${felt.round()} / 10'),
              Slider(
                value: felt,
                min: 0,
                max: 10,
                divisions: 10,
                activeColor: AppColors.primary,
                onChanged: (v) => setDialog(() => felt = v),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, felt.round()),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (value == null) return;
    final steps = [..._steps!];
    steps[index] = step.withActual(value);
    await _update(steps);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(value < step.expected
          ? 'It was easier than you expected. Your brain is learning it\'s safe.'
          : 'You did something hard. Repeating it usually makes it easier.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    if (steps == null) return const Center(child: CircularProgressIndicator());
    final examples = _exampleSteps[widget.trigger];
    final done = steps.where((s) => s.done).length;

    return _Body(
      children: [
        _Note(
          'Facing a fear slowly teaches your body it\'s safe. Start with the '
          'easiest step, stay until the anxiety drops a little, and repeat it '
          'before moving up. Skip anything that feels too much. For big '
          'fears, it\'s best to do this with a therapist.',
        ),
        if (steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$done of ${steps.length} steps done',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ),
          ),
        for (var i = 0; i < steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: steps[i].done
                  ? AppColors.surfaceSoft
                  : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    steps[i].done ? AppColors.primary : AppColors.surfaceSoft,
                foregroundColor: steps[i].done
                    ? AppColors.textOnPrimary
                    : AppColors.primaryDeep,
                child:
                    steps[i].done ? const Icon(Icons.check) : Text('${i + 1}'),
              ),
              title: Text(steps[i].text),
              subtitle: Text(steps[i].done
                  ? 'Expected ${steps[i].expected}/10, felt ${steps[i].actual}/10'
                  : 'Expected ${steps[i].expected}/10'),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'done') _markDone(i);
                  if (action == 'delete') {
                    _update([...steps]..removeAt(i));
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'done',
                    child: Text(steps[i].done ? 'Did it again' : 'I did it'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Remove')),
                ],
              ),
              onTap: () => _markDone(i),
            ),
          ),
        if (steps.isEmpty && examples != null)
          OutlinedButton.icon(
            onPressed: () => _update([
              for (final (t, e) in examples) LadderStep(text: t, expected: e),
            ]),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: const Text('Start with example steps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryDeep,
              side: const BorderSide(color: AppColors.primary),
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _addStep,
          icon: const Icon(Icons.add),
          label: const Text('Add my own step'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(50),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces

class _Body extends StatelessWidget {
  final List<Widget> children;

  const _Body({required this.children});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.mediumPadding),
          children: children,
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final String text;

  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: AppTextStyles.bodySmall.copyWith(height: 1.5)),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;

  const _Field({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
