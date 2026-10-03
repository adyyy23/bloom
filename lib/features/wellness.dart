import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../companion/pip.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';

// ------------------------------------------------------------------ tab

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key});
  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wellness')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BloomSpacing.md, vertical: BloomSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedPills<int>(
                  values: const [0, 1, 2, 3, 4],
                  labels: const [
                    'Sleep',
                    'Mood',
                    'Breathe',
                    'Journal',
                    'Health log'
                  ],
                  selected: _seg,
                  onChanged: (v) => setState(() => _seg = v),
                ),
              ),
            ),
            Expanded(
              child: switch (_seg) {
                0 => const _SleepTab(),
                1 => const _MoodTab(),
                2 => const _BreatheTab(),
                3 => const _JournalTab(),
                _ => const _HealthLogTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone sleep screen (linked from Today).
class SleepScreen extends StatelessWidget {
  const SleepScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: const SafeArea(child: _SleepTab(padded: true)),
    );
  }
}

// ------------------------------------------------------------------ sleep

class _SleepTab extends ConsumerStatefulWidget {
  final bool padded;
  const _SleepTab({this.padded = false});

  @override
  ConsumerState<_SleepTab> createState() => _SleepTabState();
}

class _SleepTabState extends ConsumerState<_SleepTab> {
  @override
  Widget build(BuildContext context) {
    final wellness = ref.watch(wellnessRepoProvider);
    final profile = ref.watch(profileRepoProvider).profile;
    final key = Dates.todayKey();
    final today = wellness.sleepFor(key);
    final weekKeys = Dates.weekKeys(DateTime.now());
    final avg = wellness.avgSleepHours(weekKeys);

    final duration = today == null
        ? null
        : Dates.sleepDuration(today.bedtime, today.wakeTime, today.dateKey);
    final durationHours =
        duration == null ? 0.0 : duration.inMinutes / 60.0;
    final diffMinutes = duration == null
        ? 0
        : (duration.inMinutes - (profile.sleepGoalH * 60)).round();

    return ListView(
      padding: EdgeInsets.fromLTRB(
          BloomSpacing.md, widget.padded ? BloomSpacing.sm : 0,
          BloomSpacing.md, 150),
      children: [
        BubbleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.bedtime_rounded,
                            size: 20, color: BloomColors.lavenderDeep),
                        const SizedBox(width: 8),
                        Text('Last night',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _editSleep(context, ref, today),
                    icon: Icon(
                        today == null
                            ? Icons.add_circle_outline_rounded
                            : Icons.edit_outlined,
                        size: 16),
                    label: Text(today == null ? 'Log sleep' : 'Edit'),
                  ),
                ],
              ),
              if (today == null) ...[
                const SizedBox(height: 6),
                Text('No sleep record logged yet for last night.',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                PillButton(
                  label: 'Log last night\'s sleep',
                  icon: Icons.add_rounded,
                  secondary: true,
                  onPressed: () => _editSleep(context, ref, null),
                ),
              ] else ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      Dates.formatHm(durationHours),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: diffMinutes >= 0
                            ? BloomColors.mintDeep.withOpacity(0.12)
                            : BloomColors.peachDeep.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(BloomRadii.pill),
                      ),
                      child: Text(
                        diffMinutes >= 0
                            ? '+${Dates.formatHm(diffMinutes / 60)} vs goal'
                            : '-${Dates.formatHm(diffMinutes.abs() / 60)} vs goal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: diffMinutes >= 0
                              ? BloomColors.mintDeep
                              : BloomColors.peachDeep,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.06),
                    borderRadius: BorderRadius.circular(BloomRadii.bubble),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.nightlight_round,
                              size: 14, color: BloomColors.lavenderDeep),
                          const SizedBox(width: 4),
                          Text(today.bedtime,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 14, color: BloomColors.line),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wb_sunny_rounded,
                              size: 14, color: BloomColors.peachDeep),
                          const SizedBox(width: 4),
                          Text(today.wakeTime,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                      Container(
                          width: 1, height: 16, color: BloomColors.line),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 15, color: Color(0xFFF5A623)),
                          const SizedBox(width: 3),
                          Text('${today.quality}/5',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (today.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Note: ${today.note}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Goal: ${Dates.formatHm(profile.sleepGoalH)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '7-day avg: ${avg > 0 ? Dates.formatHm(avg) : '—'}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'This week',
          subtitle: 'Daily consistency and sleep duration',
        ),
        BubbleCard(
          child: Column(
            children: [
              for (final k in weekKeys)
                _sleepRow(context, wellness.sleepFor(k), k),
            ],
          ),
        ),
        const SizedBox(height: BloomSpacing.md),
        const InfoNote(
          text:
              'Bloom records the times you enter. Sleep stages are never inferred from manual entries.',
        ),
        const SizedBox(height: 8),
        PillButton(
          label: 'Bedtime reminder',
          icon: Icons.alarm_outlined,
          secondary: true,
          onPressed: () => _bedtimeReminder(context, ref),
        ),
      ],
    );
  }

  Widget _sleepRow(BuildContext context, SleepLog? s, String key) {
    final d = Dates.parseKey(key);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              Dates.isToday(key) ? 'Today' : Dates.pretty(d),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: s == null
                ? Text('—',
                    style: Theme.of(context).textTheme.bodySmall)
                : Text(
                    '${Dates.formatDuration(Dates.sleepDuration(s.bedtime, s.wakeTime, s.dateKey))} · ${s.bedtime}–${s.wakeTime}',
                    style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (s != null)
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= s.quality
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: BloomColors.peachDeep,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _editSleep(
      BuildContext context, WidgetRef ref, SleepLog? existing) async {
    final saved = await showBubbleSheet<Object>(
      context,
      _SleepEditor(existing: existing),
    );
    if (saved == '__delete__' && existing != null) {
      await ref.read(wellnessRepoProvider).deleteSleep(existing.id);
    } else if (saved is SleepLog) {
      await ref.read(wellnessRepoProvider).saveSleep(saved);
    }
  }

  Future<void> _bedtimeReminder(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileRepoProvider).profile;
    // default: 30 min before an 11pm bedtime target
    TimeOfDay? time = const TimeOfDay(hour: 22, minute: 30);
    final picked = await showTimePicker(
        context: context, initialTime: time);
    if (picked == null) return;
    time = picked;
    final hhmm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (!NotificationService.supported) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Reminders are not supported on this platform — your bedtime is saved as a gentle in-app note instead.')));
      }
      return;
    }
    final granted =
        await NotificationService.requestPermission();
    if (!granted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Notification permission was not granted, so the reminder was not scheduled.')));
      return;
    }
    final item = ReminderItem(
      id: newId(),
      title: 'Wind down for sleep',
      body:
          'Your sleep goal is ${Dates.formatHm(profile.sleepGoalH)}. Time to start winding down.',
      time: hhmm,
      kind: 'sleep',
    );
    await ref.read(reminderRepoProvider).save(item);
    await NotificationService.scheduleReminder(item,
        showPreview:
            ref.read(settingsRepoProvider).settings.notifPreview);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bedtime reminder set for $hhmm daily.')));
    }
  }
}

class _SleepEditor extends StatefulWidget {
  final SleepLog? existing;
  const _SleepEditor({this.existing});

  @override
  State<_SleepEditor> createState() => _SleepEditorState();
}

class _SleepEditorState extends State<_SleepEditor> {
  late String _bedtime;
  late String _wake;
  late int _quality;
  late TextEditingController _note;
  late String _dateKey;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _bedtime = e?.bedtime ?? '23:00';
    _wake = e?.wakeTime ?? '07:00';
    _quality = e?.quality ?? 3;
    _note = TextEditingController(text: e?.note ?? '');
    _dateKey = e?.dateKey ?? Dates.todayKey();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dur =
        Dates.sleepDuration(_bedtime, _wake, _dateKey);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Log sleep',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('For the morning of ${Dates.pretty(Dates.parseKey(_dateKey))}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: BloomSpacing.md),
        Row(
          children: [
            Expanded(
                child: _timePick('Bedtime', _bedtime,
                    (v) => setState(() => _bedtime = v))),
            const SizedBox(width: 12),
            Expanded(
                child: _timePick('Wake time', _wake,
                    (v) => setState(() => _wake = v))),
          ],
        ),
        const SizedBox(height: BloomSpacing.sm),
        Center(
          child: Text(
            'Duration: ${Dates.formatDuration(dur)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: BloomSpacing.sm),
        Text('Sleep quality',
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 1; i <= 5; i++)
              IconButton(
                icon: Icon(i <= _quality
                    ? Icons.star
                    : Icons.star_border),
                color: BloomColors.peachDeep,
                iconSize: 32,
                onPressed: () =>
                    setState(() => _quality = i),
              ),
          ],
        ),
        TextField(
          controller: _note,
          decoration: const InputDecoration(
              hintText: 'Note (optional) — e.g. warm room'),
        ),
        const SizedBox(height: BloomSpacing.md),
        PillButton(
          label: 'Save sleep',
          expanded: true,
          onPressed: () => Navigator.of(context).pop(SleepLog(
            id: widget.existing?.id ?? newId(),
            dateKey: _dateKey,
            bedtime: _bedtime,
            wakeTime: _wake,
            quality: _quality,
            note: _note.text.trim(),
          )),
        ),
        if (widget.existing != null)
          TextButton(
            onPressed: () async {
              final ok = await askConfirm(context,
                  title: 'Delete sleep log?',
                  body: 'This entry will be removed.',
                  confirmLabel: 'Delete');
              if (ok && context.mounted) {
                Navigator.of(context).pop('__delete__');
              }
            },
            child: const Text('Delete entry'),
          ),
      ],
    );
  }

  Widget _timePick(
      String label, String value, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final parts = value.split(':');
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1])),
            );
            if (picked != null) {
              onChanged(
                  '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
            }
          },
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .inputDecorationTheme
                  .fillColor,
              borderRadius:
                  BorderRadius.circular(BloomRadii.bubble),
            ),
            child: Text(value,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- mood

const _moodTags = [
  'calm', 'grateful', 'focused', 'energized', 'happy',
  'content', 'tired', 'anxious', 'stressed', 'overwhelmed'
];

const _moodItems = [
  ('😞', 'Rough', Color(0xFFEF9A9A)),
  ('😕', 'Low', Color(0xFFFFCC80)),
  ('😐', 'Okay', Color(0xFFFFF59D)),
  ('🙂', 'Good', Color(0xFFA5D6A7)),
  ('😄', 'Great', Color(0xFF81D4FA)),
];

const _energyLabels = [
  'Drained',
  'Low',
  'Moderate',
  'Energized',
  'Peak energy',
];

class _MoodTab extends ConsumerStatefulWidget {
  const _MoodTab();
  @override
  ConsumerState<_MoodTab> createState() => _MoodTabState();
}

class _MoodTabState extends ConsumerState<_MoodTab> {
  int _mood = 4;
  int _energy = 3;
  final _tags = <String>{};
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wellness = ref.watch(wellnessRepoProvider);
    final history = wellness.moodHistory;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        BubbleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How are you feeling?',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              // 5 Mood face buttons with text labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 1; i <= 5; i++) ...[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _mood = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _mood == i
                                ? (dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.25)
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.14))
                                : (dark
                                    ? Colors.white.withOpacity(0.04)
                                    : BloomColors.surface2),
                            borderRadius:
                                BorderRadius.circular(BloomRadii.bubble),
                            border: Border.all(
                              color: _mood == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_moodItems[i - 1].$1,
                                  style: const TextStyle(fontSize: 26)),
                              const SizedBox(height: 3),
                              Text(
                                _moodItems[i - 1].$2,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: _mood == i
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                  color: _mood == i
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: BloomSpacing.md),
              // Energy level selector with descriptive label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Energy level',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: BloomColors.peachDeep.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(BloomRadii.pill),
                    ),
                    child: Text(
                      '$_energy/5 · ${_energyLabels[_energy - 1]}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BloomColors.peachDeep,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _energy.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_energy',
                onChanged: (v) => setState(() => _energy = v.round()),
              ),
              const SizedBox(height: 4),
              Text('Feelings & tags',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
              const SizedBox(height: 6),
              ChoiceChips(
                options: _moodTags,
                selected: _tags,
                onToggle: (v) => setState(() => _tags.contains(v)
                    ? _tags.remove(v)
                    : _tags.add(v)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  hintText: 'Add a personal reflection (private)...',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: BloomSpacing.md),
              PillButton(
                label: 'Save check-in',
                icon: Icons.check_circle_outline_rounded,
                expanded: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
        const SectionHeader(title: 'History'),
        if (history.isEmpty)
          Text('Your mood check-ins will appear here.',
              style: Theme.of(context).textTheme.bodySmall),
        for (final m in history.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BubbleCard(
              radius: BloomRadii.bubble,
              child: Row(
                children: [
                  Text(_moodItems[(m.mood - 1).clamp(0, 4)].$1,
                      style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Dates.relativeDay(m.dateKey)} · ${Dates.clock(m.loggedAt)}',
                          style:
                              Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Mood ${m.mood}/5 · Energy ${m.energy}/5${m.tags.isNotEmpty ? ' · ${m.tags.join(', ')}' : ''}${m.note.isNotEmpty ? '\n${m.note}' : ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => ref
                        .read(wellnessRepoProvider)
                        .deleteMood(m.id),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: BloomSpacing.md),
        const InfoNote(
          text:
              'Mood tracking is for self-reflection. It is not a diagnosis, and Pip is not a substitute for professional care.',
        ),
      ],
    );
  }

  Future<void> _save() async {
    await ref.read(wellnessRepoProvider).addMood(MoodLog(
          id: newId(),
          dateKey: Dates.todayKey(),
          mood: _mood,
          energy: _energy,
          tags: _tags.toList(),
          note: _note.text.trim(),
        ));
    setState(() {
      _tags.clear();
      _note.clear();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for checking in with yourself.')));
    }
  }
}

// ----------------------------------------------------------------- breathe

class _BreatheTab extends ConsumerWidget {
  const _BreatheTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = [
      ('Box 4-4-4-4', 'Focus & Reset', 'In 4s · hold 4s · out 4s · hold 4s', 4, 4, 4, 4),
      ('4-7-8 Relaxing', 'Deep Relaxation', 'In 4s · hold 7s · out 8s', 4, 7, 8, 0),
      ('Coherent 5-5', 'Heart Balance', 'In 5s · out 5s', 5, 0, 5, 0),
      ('4-4-6 Calm', 'Quick Relief', 'In 4s · hold 4s · out 6s', 4, 4, 6, 0),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        BubbleCard(
          child: Row(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final settings =
                      ref.watch(settingsRepoProvider).settings;
                  return PipCompanion(
                    size: 96,
                    mood: PipMood.breathing,
                    reducedMotion: settings.reducedMotion,
                  );
                },
              ),
              const SizedBox(width: BloomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Guided breathing',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Slow, rhythmic breathing signals your nervous system to rest and recover. Pip breathes along with you.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionHeader(
          title: 'Choose a pattern',
          subtitle: 'Proven cadences for calm, focus, or sleep',
        ),
        for (final p in patterns)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: BubbleCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => BreathingScreen(
                          patternName: p.$1,
                          label: p.$2,
                          inhale: p.$4,
                          hold: p.$5,
                          exhale: p.$6,
                          holdOut: p.$7,
                        ))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.$1} · ${p.$2}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(p.$3,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.play_circle_outline,
                      color: BloomColors.mintDeep, size: 28),
                ],
              ),
            ),
          ),
        const SectionHeader(title: 'Short relaxation'),
        BubbleCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => const RelaxationScreen()),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2-minute reset',
                        style: Theme.of(context).textTheme.titleSmall),
                    Text(
                        'A short guided pause with gentle prompts.',
                        style:
                            Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }
}

class BreathingScreen extends ConsumerStatefulWidget {
  final String patternName;
  final String label;
  final int inhale;
  final int hold;
  final int exhale;
  final int holdOut;
  const BreathingScreen({
    super.key,
    required this.patternName,
    required this.label,
    required this.inhale,
    required this.hold,
    required this.exhale,
    this.holdOut = 0,
  });

  @override
  ConsumerState<BreathingScreen> createState() =>
      _BreathingScreenState();
}

class _BreathingScreenState extends ConsumerState<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  int _cycles = 4;
  int _currentCycle = 0;
  bool _running = false;
  bool _done = false;
  late DateTime _startedAt;

  int get _cycleLen =>
      widget.inhale + widget.hold + widget.exhale + widget.holdOut;

  @override
  void initState() {
    super.initState();
    final total = _cycles * _cycleLen;
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: total),
    );
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        _finish();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  (String, double) _phase() {
    final total = _cycles * _cycleLen;
    final elapsed = _ctrl.value * total;
    final inCycle = elapsed % _cycleLen;

    if (inCycle < widget.inhale) {
      return ('Breathe in', (inCycle / widget.inhale).clamp(0.0, 1.0));
    } else if (inCycle < widget.inhale + widget.hold) {
      return ('Hold', 1.0);
    } else if (inCycle < widget.inhale + widget.hold + widget.exhale) {
      final outT =
          (inCycle - widget.inhale - widget.hold) / widget.exhale;
      return ('Breathe out', (1.0 - outT).clamp(0.0, 1.0));
    } else {
      return ('Hold empty', 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepoProvider).settings;
    return Scaffold(
      appBar: AppBar(title: Text('${widget.patternName} · ${widget.label}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.lg),
          child: Column(
            children: [
              if (!_running && !_done) ...[
                Text('How many cycles?',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedPills<int>(
                  values: const [3, 4, 6, 8],
                  labels: const ['3', '4', '6', '8'],
                  selected: _cycles,
                  onChanged: (v) => setState(() {
                    _cycles = v;
                    _ctrl.duration = Duration(seconds: _cycles * _cycleLen);
                  }),
                ),
                const SizedBox(height: BloomSpacing.lg),
              ],
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _ctrl,
                    builder: (context, _) {
                      final (label, breath) =
                          _running || _done ? _phase() : ('Ready', 0.0);
                      final scale = settings.reducedMotion
                          ? 1.0
                          : 0.72 + breath * 0.44;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Restorative Breathing Sphere with Glowing Halos
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer pulsing aura
                                Transform.scale(
                                  scale: scale * 1.12,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.0),
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.08),
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.18),
                                        ],
                                        stops: const [0.35, 0.75, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                // Middle glowing sphere
                                Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.25, -0.35),
                                        colors: [
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.38),
                                          Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.15),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.25),
                                          blurRadius: 26,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Center companion synchronized with breathing
                                PipCompanion(
                                  size: 110,
                                  mood: PipMood.breathing,
                                  reducedMotion:
                                      settings.reducedMotion,
                                  externalBreath: breath,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: BloomSpacing.lg),
                          // Instructional Phase Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(BloomRadii.pill),
                            ),
                            child: Text(
                              _done ? 'Well done' : label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
                            ),
                          ),
                          if (_running) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Cycle ${_currentCycle + 1} of $_cycles',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (!_running && !_done)
                PillButton(
                  label: 'Begin',
                  icon: Icons.play_arrow,
                  expanded: true,
                  onPressed: () {
                    setState(() {
                      _running = true;
                      _startedAt = DateTime.now();
                    });
                    _ctrl.forward(from: 0);
                    Timer.periodic(
                        Duration(seconds: _cycleLen), (t) {
                      if (!mounted || _done) {
                        t.cancel();
                        return;
                      }
                      setState(() => _currentCycle++);
                      if (_currentCycle >= _cycles - 1) {
                        t.cancel();
                      }
                    });
                  },
                ),
              if (_running)
                PillButton(
                  label: 'End session',
                  secondary: true,
                  expanded: true,
                  onPressed: () {
                    _ctrl.stop();
                    _finish(early: true);
                  },
                ),
              if (_done)
                PillButton(
                  label: 'Done',
                  expanded: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish({bool early = false}) async {
    if (_done) return;
    setState(() {
      _done = true;
      _running = false;
    });
    final seconds =
        DateTime.now().difference(_startedAt).inSeconds;
    await ref.read(wellnessRepoProvider).addBreathing(
          BreathingSession(
            id: newId(),
            dateKey: Dates.todayKey(),
            pattern: widget.patternName,
            cycles: _currentCycle + 1,
            durationSec: seconds,
          ),
        );
  }
}

class RelaxationScreen extends StatefulWidget {
  const RelaxationScreen({super.key});
  @override
  State<RelaxationScreen> createState() => _RelaxationScreenState();
}

class _RelaxationScreenState extends State<RelaxationScreen> {
  final _prompts = [
    'Settle in. Let your shoulders drop away from your ears.',
    'Notice three things you can hear right now.',
    'Unclench your jaw. Soften your forehead.',
    'Think of one small thing that went okay today.',
    'Breathe normally — you are doing enough.',
    'When you are ready, carry this calm with you.',
  ];
  int _i = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted && _i < _prompts.length - 1) {
        setState(() => _i++);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2-minute reset')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const PipCompanion(size: 120, mood: PipMood.breathing),
              const SizedBox(height: BloomSpacing.lg),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _prompts[_i],
                  key: ValueKey(_i),
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: BloomSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var p = 0; p < _prompts.length; p++)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p <= _i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: BloomSpacing.lg),
              PillButton(
                label: _i >= _prompts.length - 1 ? 'Done' : 'Skip ahead',
                secondary: _i < _prompts.length - 1,
                onPressed: () {
                  if (_i >= _prompts.length - 1) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() => _i++);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- journal

class _JournalTab extends ConsumerStatefulWidget {
  const _JournalTab();
  @override
  ConsumerState<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends ConsumerState<_JournalTab> {
  final _gratitudeCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _promptIndex = DateTime.now().day;

  final _prompts = const [
    'What is one small thing you are grateful for today?',
    'What made you smile or feel light recently?',
    'Who made your week a little easier or warmer?',
    'What is something kind your body let you do today?',
    'What was a peaceful moment you noticed today?',
    'What is one expectation you can gently let go of right now?',
  ];

  @override
  void dispose() {
    _gratitudeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wellness = ref.watch(wellnessRepoProvider);
    final allEntries = wellness.journalEntries;
    final prompt = _prompts[_promptIndex % _prompts.length];

    final filtered = allEntries.where((j) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final hasText = j.text.toLowerCase().contains(q);
      final hasGratitude = (j.gratitude ?? '').toLowerCase().contains(q);
      return hasText || hasGratitude;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        // 1. Thoughtful Gratitude Prompt Card
        BubbleCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.favorite_rounded,
                      size: 18, color: BloomColors.peachDeep),
                  const SizedBox(width: 8),
                  Text('Prompt of the day',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    tooltip: 'Different prompt',
                    visualDensity: VisualDensity.compact,
                    onPressed: () =>
                        setState(() => _promptIndex++),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                prompt,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _gratitudeCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Write a small gratitude note...',
                        prefixIcon: Icon(Icons.edit_rounded, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.check_rounded),
                    tooltip: 'Save gratitude',
                    onPressed: () async {
                      final text = _gratitudeCtrl.text.trim();
                      if (text.isEmpty) return;
                      await wellness.saveJournal(JournalEntry(
                        id: newId(),
                        dateKey: Dates.todayKey(),
                        gratitude: text,
                      ));
                      _gratitudeCtrl.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Saved to your private journal.')));
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: BloomSpacing.sm),

        // 2. Search Bar for Journal Entries
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search past journal reflections...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim()),
        ),

        // 3. Entries List
        SectionHeader(
          title: 'Journal reflections',
          actionLabel: '+ New entry',
          onAction: () => _editEntry(context, ref, null),
        ),
        if (filtered.isEmpty)
          BubbleCard(
            padding: const EdgeInsets.all(BloomSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 22, color: BloomColors.mintDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _searchQuery.isNotEmpty
                        ? 'No journal entries found matching "$_searchQuery".'
                        : 'A private space for your thoughts. Your words are stored strictly on this device.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          for (final j in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BubbleCard(
                radius: BloomRadii.bubble,
                onTap: () => _editEntry(context, ref, j),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${Dates.relativeDay(j.dateKey)} · ${Dates.clock(j.loggedAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          tooltip: 'Delete reflection',
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final ok = await askConfirm(
                              context,
                              title: 'Delete entry?',
                              body:
                                  'This journal entry will be permanently removed.',
                              confirmLabel: 'Delete',
                            );
                            if (ok) {
                              await wellness.deleteJournal(j.id);
                            }
                          },
                        ),
                      ],
                    ),
                    if (j.gratitude != null && j.gratitude!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.favorite_outline_rounded,
                              size: 14, color: BloomColors.peachDeep),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              j.gratitude!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: BloomColors.peachDeep,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (j.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        j.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Future<void> _editEntry(
      BuildContext context, WidgetRef ref, JournalEntry? existing) async {
    final ctrl = TextEditingController(text: existing?.text ?? '');
    final saved = await showBubbleSheet<bool>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(existing == null ? 'New journal entry' : 'Edit entry',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.sm),
          TextField(
            controller: ctrl,
            maxLines: 8,
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Write freely — this stays on your device.'),
          ),
          const SizedBox(height: BloomSpacing.md),
          PillButton(
            label: 'Save',
            expanded: true,
            onPressed: () =>
                Navigator.of(context).pop(true),
          ),
          if (existing != null)
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Delete entry'),
            ),
        ],
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (saved == null) return;
    final wellness = ref.read(wellnessRepoProvider);
    if (saved == false && existing != null) {
      await wellness.deleteJournal(existing.id);
    } else if (text.isNotEmpty) {
      await wellness.saveJournal(JournalEntry(
        id: existing?.id ?? newId(),
        dateKey: existing?.dateKey ?? Dates.todayKey(),
        loggedAt: existing?.loggedAt,
        text: text,
        gratitude: existing?.gratitude,
      ));
    }
  }
}

// -------------------------------------------------------------- health log

class _HealthLogTab extends ConsumerStatefulWidget {
  const _HealthLogTab();
  @override
  ConsumerState<_HealthLogTab> createState() => _HealthLogTabState();
}

class _HealthLogTabState extends ConsumerState<_HealthLogTab> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: BloomSpacing.md),
          child: SegmentedPills<int>(
            values: const [0, 1, 2, 3],
            labels: const ['Notes', 'Meds', 'Visits', 'Metrics'],
            selected: _seg,
            onChanged: (v) => setState(() => _seg = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: switch (_seg) {
            0 => const _NotesPane(),
            1 => const _MedsPane(),
            2 => const _VisitsPane(),
            _ => const _MetricsPane(),
          },
        ),
      ],
    );
  }
}

class _NotesPane extends ConsumerWidget {
  const _NotesPane();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(healthRepoProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const InfoNote(
          text:
              'Private notes about symptoms or how you feel. This is not a diagnosis tool.',
        ),
        const SizedBox(height: 8),
        for (final n in repo.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BubbleCard(
              radius: BloomRadii.bubble,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Dates.relativeDay(n.dateKey)} · ${Dates.clock(n.loggedAt)}${n.kind == 'symptom' ? ' · symptom' : ''}',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(n.text,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium),
                        if (n.severity != null)
                          Text('Severity: ${n.severity}/5',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () =>
                        repo.deleteNote(n.id),
                  ),
                ],
              ),
            ),
          ),
        PillButton(
          label: 'Add note or symptom',
          icon: Icons.add,
          secondary: true,
          expanded: true,
          onPressed: () => _addNote(context, ref),
        ),
      ],
    );
  }

  Future<void> _addNote(BuildContext context, WidgetRef ref) async {
    final text = TextEditingController();
    bool isSymptom = false;
    int severity = 3;
    final saved = await showBubbleSheet<bool>(
      context,
      StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New entry',
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            SwitchListTile(
              value: isSymptom,
              onChanged: (v) => setS(() => isSymptom = v),
              title: const Text('This is a symptom'),
            ),
            if (isSymptom) ...[
              Text('Severity: $severity / 5'),
              Slider(
                  value: severity.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) =>
                      setS(() => severity = v.round())),
            ],
            TextField(
              controller: text,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                  hintText: 'Describe what you notice...'),
            ),
            const SizedBox(height: BloomSpacing.md),
            PillButton(
                label: 'Save',
                expanded: true,
                onPressed: () =>
                    Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    final t = text.text.trim();
    text.dispose();
    if (saved == true && t.isNotEmpty) {
      await ref.read(healthRepoProvider).saveNote(HealthNote(
            id: newId(),
            dateKey: Dates.todayKey(),
            kind: isSymptom ? 'symptom' : 'note',
            text: t,
            severity: isSymptom ? severity : null,
          ));
    }
  }
}

class _MedsPane extends ConsumerWidget {
  const _MedsPane();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(healthRepoProvider);
    final key = Dates.todayKey();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const InfoNote(
          text:
              'Bloom tracks your schedule — it never recommends doses. Follow your prescriber\'s instructions.',
        ),
        const SizedBox(height: 8),
        for (final m in repo.meds.where((x) => x.active))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BubbleCard(
              radius: BloomRadii.bubble,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(m.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                            Text(
                                '${m.dose}${m.schedule.isNotEmpty ? ' · ${m.schedule}' : ''}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 20),
                        onPressed: () =>
                            _editMed(context, ref, m),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _medDayRow(context, ref, m, key),
                ],
              ),
            ),
          ),
        if (repo.meds.where((x) => x.active).isEmpty)
          Text('No medications tracked.',
              style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        PillButton(
          label: 'Add medication or supplement',
          icon: Icons.add,
          secondary: true,
          expanded: true,
          onPressed: () => _editMed(context, ref, null),
        ),
      ],
    );
  }

  Widget _medDayRow(
      BuildContext context, WidgetRef ref, Medication m, String key) {
    final logs =
        ref.watch(healthRepoProvider).medLogsFor(m.id, key);
    final taken = logs.any((l) => l.taken);
    final skipped = logs.any((l) => !l.taken);
    return Row(
      children: [
        Expanded(
          child: PillButton(
            label: taken ? 'Taken ✓' : 'Mark taken',
            secondary: !taken,
            onPressed: taken
                ? null
                : () =>
                    ref.read(healthRepoProvider).logMed(m.id, true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PillButton(
            label: skipped ? 'Skipped' : 'Skip',
            secondary: true,
            onPressed: skipped
                ? null
                : () =>
                    ref.read(healthRepoProvider).logMed(m.id, false),
          ),
        ),
      ],
    );
  }

  Future<void> _editMed(
      BuildContext context, WidgetRef ref, Medication? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final dose = TextEditingController(text: existing?.dose ?? '');
    final sched =
        TextEditingController(text: existing?.schedule ?? '');
    final saved = await showBubbleSheet<bool>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(existing == null ? 'Add medication' : 'Edit medication',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextField(
              controller: name,
              decoration:
                  const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(
              controller: dose,
              decoration: const InputDecoration(
                  labelText: 'Dose (as prescribed)')),
          const SizedBox(height: 8),
          TextField(
              controller: sched,
              decoration: const InputDecoration(
                  labelText: 'Schedule (e.g. Morning, Evening)')),
          const SizedBox(height: BloomSpacing.md),
          PillButton(
              label: 'Save',
              expanded: true,
              onPressed: () =>
                  Navigator.of(context).pop(true)),
          if (existing != null)
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false),
              child: const Text('Remove'),
            ),
        ],
      ),
    );
    final repo = ref.read(healthRepoProvider);
    if (saved == true && name.text.trim().isNotEmpty) {
      await repo.saveMed(Medication(
        id: existing?.id ?? newId(),
        name: name.text.trim(),
        dose: dose.text.trim(),
        schedule: sched.text.trim(),
      ));
    } else if (saved == false && existing != null) {
      await repo.deleteMed(existing.id);
    }
    name.dispose();
    dose.dispose();
    sched.dispose();
  }
}

class _VisitsPane extends ConsumerWidget {
  const _VisitsPane();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(healthRepoProvider);
    final upcoming = repo.appointments
        .where((a) => a.dateKey.compareTo(Dates.todayKey()) >= 0)
        .toList();
    final past = repo.appointments
        .where((a) => a.dateKey.compareTo(Dates.todayKey()) < 0)
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const SectionHeader(title: 'Upcoming'),
        if (upcoming.isEmpty)
          Text('No upcoming appointments.',
              style: Theme.of(context).textTheme.bodySmall),
        for (final a in upcoming) _apptCard(context, ref, a),
        if (past.isNotEmpty) ...[
          const SectionHeader(title: 'Past'),
          for (final a in past) _apptCard(context, ref, a),
        ],
        const SizedBox(height: 8),
        PillButton(
          label: 'Add appointment',
          icon: Icons.add,
          secondary: true,
          expanded: true,
          onPressed: () => _editAppt(context, ref, null),
        ),
      ],
    );
  }

  Widget _apptCard(
      BuildContext context, WidgetRef ref, Appointment a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.event_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                  Text(
                    '${Dates.pretty(Dates.parseKey(a.dateKey))}${a.time.isNotEmpty ? ' · $a.time' : ''}${a.location.isNotEmpty ? '\n${a.location}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editAppt(context, ref, a),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAppt(
      BuildContext context, WidgetRef ref, Appointment? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final loc = TextEditingController(text: existing?.location ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    DateTime date = existing == null
        ? DateTime.now()
        : Dates.parseKey(existing.dateKey);
    TimeOfDay? time;
    if (existing?.time.isNotEmpty == true) {
      final p = existing!.time.split(':');
      time = TimeOfDay(
          hour: int.tryParse(p[0]) ?? 9,
          minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
    }
    bool remind = false;
    final saved = await showBubbleSheet<bool>(
      context,
      StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(existing == null ? 'New appointment' : 'Edit appointment',
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextField(
                controller: title,
                decoration:
                    const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                        'Date: ${Dates.pretty(date)}')),
                TextButton(
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: ctx,
                      initialDate: date,
                      firstDate: DateTime.now().subtract(
                          const Duration(days: 365)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365 * 2)),
                    );
                    if (p != null) setS(() => date = p);
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                    child: Text(
                        'Time: ${time?.format(ctx) ?? '—'}')),
                TextButton(
                  onPressed: () async {
                    final p = await showTimePicker(
                        context: ctx,
                        initialTime:
                            time ?? const TimeOfDay(hour: 9, minute: 0));
                    if (p != null) setS(() => time = p);
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
            TextField(
                controller: loc,
                decoration: const InputDecoration(
                    labelText: 'Location (optional)')),
            const SizedBox(height: 8),
            TextField(
                controller: notes,
                decoration: const InputDecoration(
                    labelText: 'Notes (optional)')),
            SwitchListTile(
              value: remind,
              onChanged: (v) => setS(() => remind = v),
              title: const Text('Remind me'),
              subtitle: const Text('Local notification on the day'),
            ),
            PillButton(
                label: 'Save',
                expanded: true,
                onPressed: () =>
                    Navigator.of(ctx).pop(true)),
            if (existing != null)
              TextButton(
                onPressed: () =>
                    Navigator.of(ctx).pop(false),
                child: const Text('Delete'),
              ),
          ],
        ),
      ),
    );
    final repo = ref.read(healthRepoProvider);
    if (saved == true && title.text.trim().isNotEmpty) {
      final t = time;
      final appt = Appointment(
        id: existing?.id ?? newId(),
        title: title.text.trim(),
        dateKey: Dates.key(date),
        time: t == null
            ? ''
            : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
        location: loc.text.trim(),
        notes: notes.text.trim(),
      );
      await repo.saveAppointment(appt);
      if (remind && t != null && context.mounted) {
        if (NotificationService.supported) {
          final granted =
              await NotificationService.requestPermission();
          if (granted) {
            final item = ReminderItem(
              id: newId(),
              title: 'Appointment: ${appt.title}',
              body: '${appt.time} ${appt.location}'.trim(),
              time: appt.time,
              kind: 'custom',
            );
            await ref.read(reminderRepoProvider).save(item);
            await NotificationService.scheduleReminder(item,
                showPreview: ref
                    .read(settingsRepoProvider)
                    .settings
                    .notifPreview);
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Reminders are not supported on this platform.')));
        }
      }
    } else if (saved == false && existing != null) {
      await repo.deleteAppointment(existing.id);
    }
    title.dispose();
    loc.dispose();
    notes.dispose();
  }
}

class _MetricsPane extends ConsumerWidget {
  const _MetricsPane();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(healthRepoProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const InfoNote(
          text:
              'Your own measurements with explicit units. Bloom does not interpret readings — share them with your clinician.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Blood pressure',
                secondary: true,
                onPressed: () =>
                    _addMetric(context, ref, 'bp'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: 'Glucose',
                secondary: true,
                onPressed: () =>
                    _addMetric(context, ref, 'glucose'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: 'Other',
                secondary: true,
                onPressed: () =>
                    _addMetric(context, ref, 'other'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in repo.metrics)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BubbleCard(
              radius: BloomRadii.bubble,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(_metricTitle(m),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall),
                        Text(
                          '${Dates.relativeDay(m.dateKey)} · ${Dates.clock(m.loggedAt)}${m.note.isNotEmpty ? '\n${m.note}' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20),
                    onPressed: () =>
                        repo.deleteMetric(m.id),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _metricTitle(HealthMetric m) {
    return switch (m.kind) {
      'bp' =>
        'Blood pressure: ${m.value1.round()}/${m.value2?.round() ?? '—'} ${m.unit}',
      'glucose' => 'Glucose: ${Fmt.num(m.value1, 1)} ${m.unit}',
      _ => '${m.note.isEmpty ? 'Measurement' : m.note}: ${Fmt.num(m.value1, 1)} ${m.unit}',
    };
  }

  Future<void> _addMetric(
      BuildContext context, WidgetRef ref, String kind) async {
    final v1 = TextEditingController();
    final v2 = TextEditingController();
    final unit = TextEditingController(
        text: kind == 'bp'
            ? 'mmHg'
            : kind == 'glucose'
                ? 'mg/dL'
                : '');
    final note = TextEditingController();
    final saved = await showBubbleSheet<bool>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
              kind == 'bp'
                  ? 'Blood pressure'
                  : kind == 'glucose'
                      ? 'Blood glucose'
                      : 'Measurement',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (kind == 'bp')
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: v1,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Systolic'))),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/'),
                ),
                Expanded(
                    child: TextField(
                        controller: v2,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Diastolic'))),
              ],
            )
          else
            TextField(
                controller: v1,
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Value')),
          const SizedBox(height: 8),
          TextField(
              controller: unit,
              decoration:
                  const InputDecoration(labelText: 'Unit')),
          const SizedBox(height: 8),
          TextField(
              controller: note,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)')),
          const SizedBox(height: BloomSpacing.md),
          PillButton(
              label: 'Save',
              expanded: true,
              onPressed: () =>
                  Navigator.of(context).pop(true)),
        ],
      ),
    );
    if (saved == true) {
      final val1 = double.tryParse(v1.text);
      if (val1 == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Enter a numeric value.')));
        }
      } else {
        await ref.read(healthRepoProvider).saveMetric(
              HealthMetric(
                id: newId(),
                dateKey: Dates.todayKey(),
                kind: kind,
                value1: val1,
                value2: double.tryParse(v2.text),
                unit: unit.text.trim(),
                note: note.text.trim(),
              ),
            );
      }
    }
    v1.dispose();
    v2.dispose();
    unit.dispose();
    note.dispose();
  }
}

// --------------------------------------------------------------- check-in

/// Quick energy/soreness check-in sheet (Today quick action).
class CheckInSheet extends ConsumerStatefulWidget {
  const CheckInSheet({super.key});
  @override
  ConsumerState<CheckInSheet> createState() => _CheckInSheetState();
}

class _CheckInSheetState extends ConsumerState<CheckInSheet> {
  int _energy = 3;
  int _soreness = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Daily check-in',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('How is your body feeling today? No wrong answers.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: BloomSpacing.md),
        Text('Energy: $_energy / 5',
            style: Theme.of(context).textTheme.labelMedium),
        Slider(
            value: _energy.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) =>
                setState(() => _energy = v.round())),
        Text('Soreness: $_soreness / 5',
            style: Theme.of(context).textTheme.labelMedium),
        Slider(
            value: _soreness.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) =>
                setState(() => _soreness = v.round())),
        const SizedBox(height: BloomSpacing.sm),
        PillButton(
          label: 'Save check-in',
          expanded: true,
          onPressed: () async {
            await ref.read(wellnessRepoProvider).saveCheckIn(
                  CheckIn(
                    id: newId(),
                    dateKey: Dates.todayKey(),
                    energy: _energy,
                    soreness: _soreness,
                  ),
                );
            if (context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- motivation

class MotivationScreen extends ConsumerWidget {
  const MotivationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motivation = ref.watch(motivationRepoProvider);
    final food = ref.watch(foodRepoProvider);
    final move = ref.watch(moveRepoProvider);
    final wellness = ref.watch(wellnessRepoProvider);
    final streak = motivation.streakDays(
        food: food, move: move, wellness: wellness);

    return Scaffold(
      appBar: AppBar(title: const Text('Motivation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 40),
          children: [
            BubbleCard(
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: BloomColors.peach.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                        Icons.local_fire_department,
                        color: BloomColors.peachDeep,
                        size: 32),
                  ),
                  const SizedBox(width: BloomSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text('$streak-day streak',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall),
                        Text(
                          'Days in a row with any logged activity. Rest days are welcome — the streak simply waits for you.',
                          style:
                              Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SectionHeader(
              title: 'Challenges',
              actionLabel: 'New',
              onAction: () =>
                  _editChallenge(context, ref, null),
            ),
            if (motivation.challenges.isEmpty)
              Text(
                  'Optional friendly challenges, e.g. "Walk 5 days this week".',
                  style: Theme.of(context).textTheme.bodySmall),
            for (final c in motivation.challenges)
              _challengeCard(context, ref, c),
            const SectionHeader(title: 'Achievements'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in _achievementDefs)
                  _achievementChip(
                      context,
                      a.$1,
                      a.$2,
                      motivation.hasAchievement(a.$1)),
              ],
            ),
            const SizedBox(height: 4),
            const InfoNote(
              text:
                  'Achievements celebrate participation and consistency — never restriction, rapid changes, or over-exercise.',
            ),
            const SectionHeader(
                title: 'Pip\'s wardrobe',
                subtitle: 'Accessories unlock through gentle consistency'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final acc in kAccessories)
                  _accessoryChip(
                    context,
                    ref,
                    acc,
                    motivation.unlockedAccessories
                        .contains(acc.id),
                    motivation.activeAccessory == acc.id,
                  ),
              ],
            ),
            const SizedBox(height: BloomSpacing.md),
            Center(
              child: Consumer(
                builder: (context, ref, _) {
                  final settings =
                      ref.watch(settingsRepoProvider).settings;
                  return PipCompanion(
                    size: 130,
                    accessory: motivation.activeAccessory,
                    reducedMotion: settings.reducedMotion,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _achievementDefs = [
    ('first_meal', 'First meal logged'),
    ('week_streak', '7-day streak'),
    ('early_bird', 'Early bird'),
    ('hydrated', 'Hydration hero'),
    ('mover', 'Regular mover'),
  ];

  Widget _achievementChip(
      BuildContext context, String key, String label, bool unlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unlocked
            ? BloomColors.peach.withOpacity(0.5)
            : Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(BloomRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            unlocked
                ? Icons.emoji_events
                : Icons.lock_outline,
            size: 16,
            color: unlocked
                ? BloomColors.peachDeep
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _accessoryChip(BuildContext context, WidgetRef ref,
      Accessory acc, bool unlocked, bool active) {
    return InkWell(
      onTap: unlocked
          ? () => ref
              .read(motivationRepoProvider)
              .setActiveAccessory(acc.id)
          : null,
      borderRadius: BorderRadius.circular(BloomRadii.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context)
                  .colorScheme
                  .primary
                  .withOpacity(0.16)
              : Theme.of(context)
                  .inputDecorationTheme
                  .fillColor,
          borderRadius: BorderRadius.circular(BloomRadii.pill),
          border: active
              ? Border.all(
                  color:
                      Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? Icons.check_circle : Icons.lock_outline,
              size: 16,
              color: unlocked
                  ? BloomColors.mintDeep
                  : Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(acc.name,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium),
                Text(acc.requirement,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _challengeCard(
      BuildContext context, WidgetRef ref, Challenge c) {
    final progress = _challengeProgress(ref, c);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.name,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => ref
                      .read(motivationRepoProvider)
                      .deleteChallenge(c.id),
                ),
              ],
            ),
            Text(
              '${Dates.pretty(Dates.parseKey(c.startKey))} – ${Dates.pretty(Dates.parseKey(c.endKey))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: c.target <= 0
                    ? 0
                    : (progress / c.target).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${Fmt.num(progress, progress < 10 ? 1 : 0)} / ${Fmt.num(c.target, 0)} ${c.unit}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  double _challengeProgress(WidgetRef ref, Challenge c) {
    final keys = <String>[];
    var d = Dates.parseKey(c.startKey);
    final end = Dates.parseKey(c.endKey);
    while (!d.isAfter(end) && keys.length < 60) {
      keys.add(Dates.key(d));
      d = d.add(const Duration(days: 1));
    }
    final food = ref.read(foodRepoProvider);
    final move = ref.read(moveRepoProvider);
    final wellness = ref.read(wellnessRepoProvider);
    switch (c.type) {
      case 'walk':
        return move.weekSteps(keys).toDouble();
      case 'water':
        return keys.fold<double>(
            0, (a, k) => a + wellness.waterTotal(k));
      case 'workout':
        return keys
            .fold<int>(
                0,
                (a, k) =>
                    a +
                    move.sessionsFor(k).length +
                    move.walksFor(k).length)
            .toDouble();
      case 'sleep':
        return keys
            .where((k) => wellness.sleepFor(k) != null)
            .length
            .toDouble();
      case 'mood':
        return keys
            .fold<int>(0,
                (a, k) => a + wellness.moodFor(k).length)
            .toDouble();
      default:
        return keys
            .where((k) => food.entriesFor(k).isNotEmpty)
            .length
            .toDouble();
    }
  }

  Future<void> _editChallenge(
      BuildContext context, WidgetRef ref, Challenge? existing) async {
    final name = TextEditingController();
    String type = 'walk';
    final target = TextEditingController(text: '5');
    int days = 7;
    final saved = await showBubbleSheet<bool>(
      context,
      StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New challenge',
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextField(
                controller: name,
                decoration: const InputDecoration(
                    labelText: 'Name (e.g. Walk 5 days)')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: type,
              decoration:
                  const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                    value: 'walk', child: Text('Walking')),
                DropdownMenuItem(
                    value: 'water', child: Text('Water (ml)')),
                DropdownMenuItem(
                    value: 'workout',
                    child: Text('Workouts & walks (count)')),
                DropdownMenuItem(
                    value: 'sleep',
                    child: Text('Sleep logs (nights)')),
                DropdownMenuItem(
                    value: 'mood',
                    child: Text('Mood check-ins (count)')),
                DropdownMenuItem(
                    value: 'custom',
                    child: Text('Days with any meal logged')),
              ],
              onChanged: (v) =>
                  setS(() => type = v ?? 'walk'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                      controller: target,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Target')),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: days,
                    decoration: const InputDecoration(
                        labelText: 'Duration'),
                    items: const [
                      DropdownMenuItem(
                          value: 7, child: Text('7 days')),
                      DropdownMenuItem(
                          value: 14, child: Text('14 days')),
                      DropdownMenuItem(
                          value: 30, child: Text('30 days')),
                    ],
                    onChanged: (v) =>
                        setS(() => days = v ?? 7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: BloomSpacing.md),
            PillButton(
                label: 'Create challenge',
                expanded: true,
                onPressed: () =>
                    Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (saved == true && name.text.trim().isNotEmpty) {
      final now = DateTime.now();
      await ref.read(motivationRepoProvider).saveChallenge(
            Challenge(
              id: newId(),
              name: name.text.trim(),
              type: type,
              target: double.tryParse(target.text) ?? 1,
              unit: type == 'water'
                  ? 'ml'
                  : type == 'walk'
                      ? 'steps'
                      : '',
              startKey: Dates.key(now),
              endKey: Dates.key(
                  now.add(Duration(days: days - 1))),
            ),
          );
    }
    name.dispose();
    target.dispose();
  }
}
