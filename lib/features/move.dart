import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/repositories.dart';

// ------------------------------------------------------------------ tab

class MoveScreen extends ConsumerStatefulWidget {
  const MoveScreen({super.key});
  @override
  ConsumerState<MoveScreen> createState() => _MoveScreenState();
}

class _MoveScreenState extends ConsumerState<MoveScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Move')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BloomSpacing.md, vertical: BloomSpacing.sm),
              child: SegmentedPills<int>(
                values: const [0, 1],
                labels: const ['Workouts', 'Walking'],
                selected: _seg,
                onChanged: (v) => setState(() => _seg = v),
              ),
            ),
            Expanded(
              child: _seg == 0 ? const _WorkoutsTab() : const _WalkingTab(),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- workouts

class _StarterWorkoutData {
  final String title;
  final int estMinutes;
  final String equipment;
  final String level;
  final String description;
  final List<(String, String, int)> exercises; // (id, name, repsOrSec)
  final IconData icon;

  const _StarterWorkoutData({
    required this.title,
    required this.estMinutes,
    required this.equipment,
    required this.level,
    required this.description,
    required this.exercises,
    required this.icon,
  });

  WorkoutTemplate toTemplate() {
    return WorkoutTemplate(
      id: newId(),
      name: title,
      level: level.toLowerCase(),
      estMinutes: estMinutes,
      blocks: [
        for (final e in exercises)
          WorkoutBlock(
            exerciseId: e.$1,
            exerciseName: e.$2,
            sets: [
              WorkoutSet(reps: e.$3.toDouble()),
              WorkoutSet(reps: e.$3.toDouble()),
              WorkoutSet(reps: e.$3.toDouble()),
            ],
            restSec: 45,
          ),
      ],
    );
  }
}

const _kStarterWorkouts = [
  _StarterWorkoutData(
    title: 'Beginner Full Body',
    estMinutes: 25,
    equipment: 'Bodyweight',
    level: 'Beginner',
    description: 'Foundational strength focusing on major movement patterns.',
    exercises: [
      ('push_up', 'Push-Up', 10),
      ('bodyweight_squat', 'Bodyweight Squat', 15),
      ('glute_bridge', 'Glute Bridge', 15),
      ('plank', 'Plank', 30),
    ],
    icon: Icons.accessibility_new_rounded,
  ),
  _StarterWorkoutData(
    title: 'Core Basics',
    estMinutes: 15,
    equipment: 'Mat only',
    level: 'Beginner',
    description: 'Build abdominal stability and protect your lower back.',
    exercises: [
      ('plank', 'Plank', 30),
      ('dead_bug', 'Dead Bug', 12),
      ('bicycle_crunch', 'Bicycle Crunch', 15),
    ],
    icon: Icons.fitness_center_rounded,
  ),
  _StarterWorkoutData(
    title: 'Quick Stretch & Mobility',
    estMinutes: 12,
    equipment: 'No equipment',
    level: 'All levels',
    description: 'Release tension in tight hips, shoulders, and spine.',
    exercises: [
      ('childs_pose', "Child's Pose", 45),
      ('cobra_pose', 'Cobra Pose', 30),
      ('figure_four_glute_stretch', 'Figure-4 Glute Stretch', 30),
    ],
    icon: Icons.self_improvement_rounded,
  ),
];

// --------------------------------------------------------------- workouts

class _WorkoutsTab extends ConsumerWidget {
  const _WorkoutsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final move = ref.watch(moveRepoProvider);
    final weekday = DateTime.now().weekday.toString();
    final scheduled =
        move.templates.where((t) => t.scheduledWeekdays.contains(weekday));
    final bests = move.personalBests();

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        // 1. Friendly Hero Introduction Card
        _MoveHeroCard(
          onCreateWorkout: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
          ),
        ),
        const SizedBox(height: BloomSpacing.md),

        // 2. Distinctly Separated Exercise Library and Freestyle Cards
        const _WorkoutModesSection(),
        const SizedBox(height: BloomSpacing.sm),

        // 3. Scheduled Workouts (if any)
        if (scheduled.isNotEmpty) ...[
          const SectionHeader(title: 'Scheduled today'),
          for (final t in scheduled)
            _TemplateCard(template: t, scheduled: true),
        ],

        // 4. My Workouts
        SectionHeader(
          title: 'My workouts',
          actionLabel: 'Create',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WorkoutBuilderScreen()),
          ),
        ),
        if (move.templates.isEmpty)
          BubbleCard(
            padding: const EdgeInsets.symmetric(
                horizontal: BloomSpacing.md, vertical: BloomSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 22, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No custom workouts saved yet. Pick a starter routine below or build your own.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          for (final t in move.templates) _TemplateCard(template: t),

        const SizedBox(height: BloomSpacing.sm),

        // 5. Categorized Starter Routines with Duration, Equipment, and Difficulty Tags
        const SectionHeader(
          title: 'Starter routines',
          subtitle: 'Ready-to-go workouts with guided movements',
        ),
        for (final starter in _kStarterWorkouts)
          _StarterWorkoutCard(starter: starter),

        // 6. Personal Bests
        if (bests.isNotEmpty) ...[
          const SectionHeader(title: 'Personal bests'),
          BubbleCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in bests.values.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 18, color: BloomColors.peachDeep),
                        const SizedBox(width: 8),
                        Expanded(child: Text(b)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],

        // 7. Workout History
        SectionHeader(
          title: 'History',
          actionLabel: move.sessions.isEmpty ? null : 'See all',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const WorkoutHistoryScreen()),
          ),
        ),
        if (move.sessions.isEmpty)
          Text('Finished workouts will appear here.',
              style: Theme.of(context).textTheme.bodySmall)
        else
          for (final s in move.sessions.take(3)) _SessionTile(session: s),
      ],
    );
  }
}

/// Friendly, compact hero introduction card at the top of Move
class _MoveHeroCard extends StatelessWidget {
  final VoidCallback onCreateWorkout;
  const _MoveHeroCard({required this.onCreateWorkout});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(BloomSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BloomRadii.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [
                  BloomColors.lavenderD.withOpacity(0.35),
                  BloomColors.peachD.withOpacity(0.25),
                ]
              : [
                  BloomColors.lavender.withOpacity(0.7),
                  BloomColors.peach.withOpacity(0.55),
                ],
        ),
        border: Border.all(
          color: dark
              ? Colors.white.withOpacity(0.08)
              : BloomColors.lavenderDeep.withOpacity(0.18),
          width: 0.8,
        ),
        boxShadow: BloomShadows.soft(context),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Move with intention',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build custom strength routines, follow starter workouts, or log open freestyle sessions at your pace.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.8),
                      ),
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: '+ Create workout',
                  icon: Icons.add,
                  onPressed: onCreateWorkout,
                ),
              ],
            ),
          ),
          const SizedBox(width: BloomSpacing.md),
          const ClayDumbbellIllustration(size: 64),
        ],
      ),
    );
  }
}

/// Distinctly separates Exercise Library from Freestyle workouts
class _WorkoutModesSection extends StatelessWidget {
  const _WorkoutModesSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Exercise Library Card
        Expanded(
          child: BubbleCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
            ),
            padding: const EdgeInsets.all(BloomSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BloomColors.mintDeep.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.library_books_rounded,
                          size: 18, color: BloomColors.mintDeep),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exercise Library',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '30+ moves with form cues, muscles & tips.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Browse moves',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Freestyle Workout Card
        Expanded(
          child: BubbleCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutPlayerScreen()),
            ),
            padding: const EdgeInsets.all(BloomSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BloomColors.lavenderDeep.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_rounded,
                          size: 18, color: BloomColors.lavenderDeep),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Freestyle',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'No pre-set plan. Track exercises as you train.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.25,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Start open',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded,
                        size: 13, color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Starter workout routine card with distinct duration, equipment, and difficulty tags
class _StarterWorkoutCard extends ConsumerWidget {
  final _StarterWorkoutData starter;
  const _StarterWorkoutCard({required this.starter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        onTap: () {
          final t = starter.toTemplate();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => WorkoutPlayerScreen(template: t)),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(starter.icon,
                      color: Theme.of(context).colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(starter.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(starter.description,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Tags row: Duration, Equipment, Difficulty
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _TagPill(
                  icon: Icons.schedule_rounded,
                  label: '~${starter.estMinutes} min',
                  bgColor: dark
                      ? BloomColors.skyD.withOpacity(0.25)
                      : BloomColors.sky.withOpacity(0.55),
                  textColor: BloomColors.skyDeep,
                ),
                _TagPill(
                  icon: Icons.fitness_center_rounded,
                  label: starter.equipment,
                  bgColor: dark
                      ? BloomColors.lavenderD.withOpacity(0.25)
                      : BloomColors.lavender.withOpacity(0.55),
                  textColor: BloomColors.lavenderDeep,
                ),
                _TagPill(
                  icon: Icons.speed_rounded,
                  label: starter.level,
                  bgColor: dark
                      ? BloomColors.mintD.withOpacity(0.25)
                      : BloomColors.mint.withOpacity(0.55),
                  textColor: BloomColors.mintDeep,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Exercise preview
            Text(
              starter.exercises.map((e) => e.$2).join(' · '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final t = starter.toTemplate();
                    await ref.read(moveRepoProvider).saveTemplate(t);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Saved "${starter.title}" to My workouts!')),
                      );
                    }
                  },
                  icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                  label: const Text('Save'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final t = starter.toTemplate();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => WorkoutPlayerScreen(template: t)),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Start'),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Clean tag pill for tags (duration, equipment, difficulty)
class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  const _TagPill({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BloomRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final WorkoutTemplate template;
  final bool scheduled;
  const _TemplateCard({required this.template, this.scheduled = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => WorkoutPlayerScreen(template: template))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: scheduled
                        ? BloomColors.peach.withOpacity(0.6)
                        : Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: scheduled
                        ? BloomColors.peachDeep
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        '${template.blocks.length} exercises · ${template.blocks.map((b) => b.exerciseName).take(3).join(', ')}${template.blocks.length > 3 ? '…' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              WorkoutBuilderScreen(existing: template)));
                    } else if (v == 'delete') {
                      final ok = await askConfirm(context,
                          title: 'Delete workout?',
                          body:
                              '"${template.name}" will be removed. Past sessions stay in history.',
                          confirmLabel: 'Delete');
                      if (ok) {
                        await ref
                            .read(moveRepoProvider)
                            .deleteTemplate(template.id);
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tags row: Duration & Level
            Wrap(
              spacing: 6,
              children: [
                _TagPill(
                  icon: Icons.schedule_rounded,
                  label: '~${template.estMinutes} min',
                  bgColor: dark
                      ? BloomColors.skyD.withOpacity(0.25)
                      : BloomColors.sky.withOpacity(0.55),
                  textColor: BloomColors.skyDeep,
                ),
                _TagPill(
                  icon: Icons.speed_rounded,
                  label: template.level.isNotEmpty ? template.level : 'Custom',
                  bgColor: dark
                      ? BloomColors.lavenderD.withOpacity(0.25)
                      : BloomColors.lavender.withOpacity(0.55),
                  textColor: BloomColors.lavenderDeep,
                ),
                if (scheduled)
                  _TagPill(
                    icon: Icons.today_rounded,
                    label: 'Scheduled today',
                    bgColor: dark
                        ? BloomColors.peachD.withOpacity(0.25)
                        : BloomColors.peach.withOpacity(0.55),
                    textColor: BloomColors.peachDeep,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  final WorkoutSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.name,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                  Text(
                    '${Dates.relativeDay(session.dateKey)} · ${Dates.formatDuration(Duration(seconds: session.durationSec))}${session.kcalEstimate != null ? ' · ~${session.kcalEstimate!.round()} kcal (est.)' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                final ok = await askConfirm(context,
                    title: 'Delete session?',
                    body: 'This workout record will be removed.',
                    confirmLabel: 'Delete');
                if (ok) {
                  await ref
                      .read(moveRepoProvider)
                      .deleteSession(session.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(moveRepoProvider).sessions;
    return Scaffold(
      appBar: AppBar(title: const Text('Workout history')),
      body: SafeArea(
        child: sessions.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(BloomSpacing.lg),
                child: EmptyState(
                  icon: Icons.history_outlined,
                  title: 'No workouts yet',
                  body: 'Your finished sessions will live here.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(BloomSpacing.md,
                    BloomSpacing.sm, BloomSpacing.md, 40),
                itemCount: sessions.length,
                itemBuilder: (ctx, i) =>
                    _SessionTile(session: sessions[i]),
              ),
      ),
    );
  }
}

// -------------------------------------------------------- exercise library

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  final bool picking;
  const ExerciseLibraryScreen({super.key, this.picking = false});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState
    extends ConsumerState<ExerciseLibraryScreen> {
  String _query = '';
  String? _muscle;
  String? _equipment;
  String? _type;

  @override
  Widget build(BuildContext context) {
    final list = catalogExercises.where((e) {
      if (_query.isNotEmpty &&
          !e.name.toLowerCase().contains(_query.toLowerCase())) {
        return false;
      }
      if (_muscle != null && !e.muscles.contains(_muscle)) return false;
      if (_equipment != null && !e.equipment.contains(_equipment)) {
        return false;
      }
      if (_type != null && e.type != _type) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.picking ? 'Pick exercises' : 'Exercise library')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search exercises',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            _filters(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(BloomSpacing.md, 0,
                    BloomSpacing.md, 100),
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final e = list[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: BubbleCard(
                      radius: BloomRadii.bubble,
                      onTap: () => widget.picking
                          ? Navigator.of(context).pop(e)
                          : _showDetail(context, e),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(e.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall),
                                const SizedBox(height: 2),
                                Text(
                                  '${e.muscles.join(' · ')} · ${e.difficulty}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _typeTint(context, e.type),
                              borderRadius: BorderRadius.circular(
                                  BloomRadii.pill),
                            ),
                            child: Text(e.type,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontSize: 12)),
                          ),
                          if (widget.picking)
                            const Icon(Icons.add_circle_outline),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    final muscles = [
      'chest', 'back', 'shoulders', 'arms', 'core', 'glutes',
      'quadriceps', 'hamstrings', 'full body'
    ];
    final equipment = [
      'bodyweight', 'dumbbell', 'resistance band', 'kettlebell'
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.symmetric(horizontal: BloomSpacing.md),
      child: Row(
        children: [
          _fChip('All muscles', _muscle == null,
              () => setState(() => _muscle = null)),
          for (final m in muscles)
            _fChip(m, _muscle == m,
                () => setState(() => _muscle = _muscle == m ? null : m)),
          _fChip('Any equipment', _equipment == null,
              () => setState(() => _equipment = null)),
          for (final e in equipment)
            _fChip(e, _equipment == e,
                () => setState(
                    () => _equipment = _equipment == e ? null : e)),
          for (final t in ['strength', 'cardio', 'mobility', 'stretch'])
            _fChip(t, _type == t,
                () => setState(() => _type = _type == t ? null : t)),
        ],
      ),
    );
  }

  Widget _fChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap()),
    );
  }

  Color _typeTint(BuildContext context, String type) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return switch (type) {
      'strength' => dark ? BloomColors.lavenderD : BloomColors.lavender,
      'cardio' => dark ? BloomColors.peachD : BloomColors.peach,
      'mobility' => dark ? BloomColors.mintD : BloomColors.mint,
      _ => dark ? BloomColors.skyD : BloomColors.sky,
    };
  }

  void _showDetail(BuildContext context, CatalogExercise e) {
    showBubbleSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
              '${e.muscles.join(' · ')}\n${e.equipment.join(' · ')} · ${e.difficulty} · ${e.type}',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: BloomSpacing.md),
          Text('How to do it',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(e.instructions,
              style: Theme.of(context).textTheme.bodyMedium),
          if (e.tips.isNotEmpty) ...[
            const SizedBox(height: BloomSpacing.sm),
            InfoNote(text: 'Tip: ${e.tips}', icon: Icons.lightbulb_outline),
          ],
          const SizedBox(height: BloomSpacing.sm),
          const InfoNote(
            text:
                'Demonstrations are text-guided in this version. Stop if anything hurts — discomfort is information, not failure.',
            icon: Icons.favorite_outline,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------- workout builder

class WorkoutBuilderScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? existing;
  const WorkoutBuilderScreen({super.key, this.existing});

  @override
  ConsumerState<WorkoutBuilderScreen> createState() =>
      _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState
    extends ConsumerState<WorkoutBuilderScreen> {
  late TextEditingController _name;
  String _level = 'beginner';
  final _blocks = <WorkoutBlock>[];
  final _weekdays = <String>{};

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _level = e?.level ?? 'beginner';
    if (e != null) {
      _blocks.addAll(e.blocks.map((b) => WorkoutBlock(
            exerciseId: b.exerciseId,
            exerciseName: b.exerciseName,
            sets: b.sets
                .map((s) => WorkoutSet(
                    reps: s.reps,
                    weightKg: s.weightKg,
                    durationSec: s.durationSec,
                    rpe: s.rpe))
                .toList(),
            restSec: b.restSec,
          )));
      _weekdays.addAll(e.scheduledWeekdays);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.existing == null
              ? 'New workout'
              : 'Edit workout')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 120),
          children: [
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Workout name')),
            const SizedBox(height: BloomSpacing.sm),
            Text('Level',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            SegmentedPills<String>(
              values: const ['beginner', 'intermediate', 'advanced'],
              labels: const ['Beginner', 'Intermediate', 'Advanced'],
              selected: _level,
              onChanged: (v) => setState(() => _level = v),
            ),
            const SectionHeader(title: 'Exercises'),
            if (_blocks.isEmpty)
              Text('No exercises yet — add your first below.',
                  style: Theme.of(context).textTheme.bodySmall),
            for (var i = 0; i < _blocks.length; i++)
              _BlockEditor(
                block: _blocks[i],
                onChanged: () => setState(() {}),
                onRemove: () =>
                    setState(() => _blocks.removeAt(i)),
                onMoveUp: i == 0
                    ? null
                    : () => setState(() {
                          final b = _blocks.removeAt(i);
                          _blocks.insert(i - 1, b);
                        }),
              ),
            const SizedBox(height: 8),
            PillButton(
              label: 'Add exercise',
              icon: Icons.add,
              secondary: true,
              onPressed: _addExercise,
            ),
            const SectionHeader(
                title: 'Weekly schedule',
                subtitle: 'Optional — shows up on those days'),
            Wrap(
              spacing: 8,
              children: [
                for (var d = 1; d <= 7; d++)
                  ChoiceChip(
                    label: Text(
                        ['M', 'T', 'W', 'T', 'F', 'S', 'S'][d - 1]),
                    selected: _weekdays.contains('$d'),
                    onSelected: (_) => setState(() {
                      final k = '$d';
                      _weekdays.contains(k)
                          ? _weekdays.remove(k)
                          : _weekdays.add(k);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: BloomSpacing.lg),
            PillButton(
              label: 'Save workout',
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addExercise() async {
    final e = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(
          builder: (_) =>
              const ExerciseLibraryScreen(picking: true)),
    );
    if (e == null) return;
    setState(() => _blocks.add(WorkoutBlock(
          exerciseId: e.id,
          exerciseName: e.name,
          sets: [WorkoutSet(reps: 10)],
        )));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name your workout first.')));
      return;
    }
    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one exercise.')));
      return;
    }
    final t = WorkoutTemplate(
      id: widget.existing?.id ?? newId(),
      name: _name.text.trim(),
      level: _level,
      estMinutes: (_blocks.length * 5).clamp(5, 180),
      blocks: _blocks,
      scheduledWeekdays: _weekdays.toList(),
    );
    await ref.read(moveRepoProvider).saveTemplate(t);
    if (mounted) Navigator.of(context).pop();
  }
}

class _BlockEditor extends StatefulWidget {
  final WorkoutBlock block;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  const _BlockEditor({
    required this.block,
    required this.onChanged,
    required this.onRemove,
    this.onMoveUp,
  });

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  @override
  Widget build(BuildContext context) {
    final b = widget.block;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(b.exerciseName,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                ),
                if (widget.onMoveUp != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed: widget.onMoveUp,
                  ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            for (var i = 0; i < b.sets.length; i++)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                        width: 52,
                        child: Text('Set ${i + 1}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall)),
                    Expanded(
                        child: _setField('reps', b.sets[i].reps,
                            (v) => b.sets[i].reps = v)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: _setField('kg', b.sets[i].weightKg,
                            (v) => b.sets[i].weightKg = v)),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: b.sets.length <= 1
                          ? null
                          : () => setState(() {
                                b.sets.removeAt(i);
                                widget.onChanged();
                              }),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Set'),
                  onPressed: () => setState(() {
                    b.sets.add(WorkoutSet(reps: 10));
                    widget.onChanged();
                  }),
                ),
                const Spacer(),
                Text('Rest',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 6),
                DropdownButton<int>(
                  value: b.restSec,
                  items: const [30, 45, 60, 90, 120, 180]
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text('${s}s')))
                      .toList(),
                  onChanged: (v) => setState(() {
                    if (v != null) {
                      b.restSec = v;
                      widget.onChanged();
                    }
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _setField(
      String label, double? value, ValueChanged<double?> onChanged) {
    final ctrl = TextEditingController(
        text: value == null ? '' : Fmt.num(value, 1));
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
          labelText: label, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
      onChanged: (v) => onChanged(double.tryParse(v)),
    );
  }
}

// ---------------------------------------------------------- workout player

class WorkoutPlayerScreen extends ConsumerStatefulWidget {
  final WorkoutTemplate? template;
  const WorkoutPlayerScreen({super.key, this.template});

  @override
  ConsumerState<WorkoutPlayerScreen> createState() =>
      _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState
    extends ConsumerState<WorkoutPlayerScreen> {
  late List<WorkoutBlock> _blocks;
  late String _name;
  late DateTime _startedAt;
  Timer? _ticker;
  int _elapsed = 0;
  bool _paused = false;
  int _pausedAccum = 0;
  DateTime? _pausedAt;
  int _restLeft = 0;
  Timer? _restTimer;
  final _doneSets = <String>{}; // blockIdx:setIdx

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    final t = widget.template;
    _name = t?.name ?? 'Freestyle session';
    _blocks = (t?.blocks ?? [])
        .map((b) => WorkoutBlock(
              exerciseId: b.exerciseId,
              exerciseName: b.exerciseName,
              sets: b.sets
                  .map((s) => WorkoutSet(
                      reps: s.reps,
                      weightKg: s.weightKg,
                      durationSec: s.durationSec))
                  .toList(),
              restSec: b.restSec,
            ))
        .toList();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) {
        setState(() => _elapsed =
            DateTime.now().difference(_startedAt).inSeconds -
                _pausedAccum);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_name),
        actions: [
          TextButton(
            onPressed: _finish,
            child: const Text('Finish'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 120),
          children: [
            _timerCard(),
            if (_restLeft > 0) _restCard(),
            const SectionHeader(title: 'Exercises'),
            for (var bi = 0; bi < _blocks.length; bi++)
              _playerBlock(bi),
            const SizedBox(height: 8),
            PillButton(
              label: 'Add exercise',
              icon: Icons.add,
              secondary: true,
              onPressed: _addExercise,
            ),
            const SizedBox(height: BloomSpacing.md),
            const InfoNote(
              text:
                  'Calorie burn shown at the end is an approximation and stays separate from your food budget.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _timerCard() {
    return BubbleCard(
      child: Row(
        children: [
          ProgressRing(
            progress: 0,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
            center: Text(
              Dates.formatDuration(Duration(seconds: _elapsed)),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: BloomSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_paused ? 'Paused' : 'In progress',
                    style: Theme.of(context).textTheme.titleSmall),
                Text('Timer keeps true time even if the app goes to the background.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton.filled(
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: () {
              setState(() {
                if (_paused) {
                  if (_pausedAt != null) {
                    _pausedAccum += DateTime.now()
                        .difference(_pausedAt!)
                        .inSeconds;
                  }
                  _paused = false;
                } else {
                  _pausedAt = DateTime.now();
                  _paused = true;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _restCard() {
    return Padding(
      padding: const EdgeInsets.only(top: BloomSpacing.md),
      child: BubbleCard(
        color: Theme.of(context).brightness == Brightness.dark
            ? BloomColors.skyD
            : BloomColors.sky,
        child: Row(
          children: [
            const Icon(Icons.hourglass_bottom,
                color: BloomColors.skyDeep, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rest',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text('$_restLeft s — breathe easy',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 26)),
                ],
              ),
            ),
            TextButton(
                onPressed: _skipRest, child: const Text('Skip')),
          ],
        ),
      ),
    );
  }

  Widget _playerBlock(int bi) {
    final b = _blocks[bi];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(b.exerciseName,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall)),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: () => _showExerciseInfo(b.exerciseId),
                ),
              ],
            ),
            for (var si = 0; si < b.sets.length; si++)
              _setRow(bi, si),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Set'),
                  onPressed: () => setState(
                      () => b.sets.add(WorkoutSet(reps: 10))),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.hourglass_empty, size: 16),
                  label: Text('Rest ${b.restSec}s'),
                  onPressed: () => _startRest(b.restSec),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _setRow(int bi, int si) {
    final key = '$bi:$si';
    final done = _doneSets.contains(key);
    final set = _blocks[bi].sets[si];
    return InkWell(
      onTap: () => setState(() {
        done ? _doneSets.remove(key) : _doneSets.add(key);
      }),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done
                  ? BloomColors.mintDeep
                  : Theme.of(context).colorScheme.outline,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text('Set ${si + 1}',
                style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            SizedBox(
              width: 64,
              child: TextField(
                controller: TextEditingController(
                    text: set.reps == null
                        ? ''
                        : Fmt.num(set.reps!, 1)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'reps',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8)),
                onChanged: (v) =>
                    set.reps = double.tryParse(v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: TextField(
                controller: TextEditingController(
                    text: set.weightKg == null
                        ? ''
                        : Fmt.num(set.weightKg!, 1)),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'kg',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8)),
                onChanged: (v) =>
                    set.weightKg = double.tryParse(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExerciseInfo(String exerciseId) {
    final e = findExercise(exerciseId);
    if (e == null) return;
    showBubbleSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(e.name,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(e.instructions),
          if (e.tips.isNotEmpty) ...[
            const SizedBox(height: 8),
            InfoNote(text: 'Tip: ${e.tips}'),
          ],
        ],
      ),
    );
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    setState(() => _restLeft = seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _restLeft--;
        if (_restLeft <= 0) t.cancel();
      });
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restLeft = 0);
  }

  Future<void> _addExercise() async {
    final e = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(
          builder: (_) =>
              const ExerciseLibraryScreen(picking: true)),
    );
    if (e == null) return;
    setState(() => _blocks.add(WorkoutBlock(
          exerciseId: e.id,
          exerciseName: e.name,
          sets: [WorkoutSet(reps: 10)],
        )));
  }

  Future<void> _finish() async {
    final ok = await askConfirm(
      context,
      title: 'Finish workout?',
      body:
          'This saves ${_doneSets.length} completed set${_doneSets.length == 1 ? '' : 's'} to your history.',
      confirmLabel: 'Finish',
    );
    if (!ok) return;
    final profile = ref.read(profileRepoProvider).profile;
    final minutes = _elapsed / 60;
    // Approximate burn: ~4.5 kcal/min at 70 kg, scaled. Labeled approximate.
    final weight = profile.startWeightKg ?? 70;
    final kcal = minutes * 4.5 * (weight / 70);
    final session = WorkoutSession(
      id: newId(),
      dateKey: Dates.key(_startedAt),
      name: _name,
      templateId: widget.template?.id,
      blocks: _blocks,
      durationSec: _elapsed,
      kcalEstimate: kcal,
      completedAt: DateTime.now(),
    );
    await ref.read(moveRepoProvider).addSession(session);
    await ref.read(motivationRepoProvider).recordActivity(
          food: ref.read(foodRepoProvider),
          move: ref.read(moveRepoProvider),
          wellness: ref.read(wellnessRepoProvider),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Workout saved — ${Dates.formatDuration(Duration(seconds: _elapsed))} · ~${kcal.round()} kcal (est.)')));
    }
  }
}

// ---------------------------------------------------------------- walking

class _WalkingTab extends ConsumerWidget {
  const _WalkingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final move = ref.watch(moveRepoProvider);
    final profile = ref.watch(profileRepoProvider).profile;
    final key = Dates.todayKey();
    final steps = move.displaySteps(key);
    final weekKeys = Dates.weekKeys(DateTime.now());
    final active = move.activeWalk;

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        // 1. Dedicated Walking Hero Card with Clay Sneaker Illustration
        _DedicatedWalkingCard(
          steps: steps.value,
          goalSteps: profile.walkGoalSteps,
          source: steps.source,
          units: profile.units,
        ),
        const SizedBox(height: BloomSpacing.md),

        // 2. Start-Session Controls
        if (active != null)
          _ActiveWalkCard(walk: active)
        else
          PillButton(
            label: 'Start a walk',
            icon: Icons.directions_walk_rounded,
            expanded: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalkScreen()),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Quick log steps',
                icon: Icons.add_circle_outline_rounded,
                secondary: true,
                onPressed: () => _logSteps(context, ref),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PillButton(
                label: 'Add past walk',
                icon: Icons.history_rounded,
                secondary: true,
                onPressed: () => _manualWalk(context, ref),
              ),
            ),
          ],
        ),

        // 3. This Week's Step History
        const SectionHeader(
          title: 'This week',
          subtitle: 'Daily consistency towards your step target',
        ),
        BubbleCard(
          child: Column(
            children: [
              for (final k in weekKeys)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          Dates.isToday(k)
                              ? 'Today'
                              : Dates.pretty(Dates.parseKey(k)),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: Dates.isToday(k)
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: profile.walkGoalSteps <= 0
                                ? 0
                                : (move.displaySteps(k).value /
                                        profile.walkGoalSteps)
                                    .clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor:
                                BloomColors.mintDeep.withOpacity(0.14),
                            valueColor: const AlwaysStoppedAnimation(
                                BloomColors.mintDeep),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 68,
                        child: Text(
                          Fmt.intFmt(move.displaySteps(k).value),
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // 4. Walk History
        const SectionHeader(
          title: 'Walk history',
          subtitle: 'Completed outdoor and indoor walking workouts',
        ),
        if (move.walks.isEmpty)
          BubbleCard(
            padding: const EdgeInsets.all(BloomSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.directions_walk_rounded,
                    size: 24, color: BloomColors.mintDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No walking sessions recorded yet. Start a walk above to track time, pace, and route distance.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          )
        else
          for (final w in move.walks.take(8)) _WalkTile(walk: w),
      ],
    );
  }

  Future<void> _logSteps(BuildContext context, WidgetRef ref) async {
    final v = await askNumber(
      context,
      title: 'Steps today',
      unit: 'steps',
      initial: ref
          .read(moveRepoProvider)
          .displaySteps(Dates.todayKey())
          .value
          .toDouble(),
    );
    if (v == null) return;
    await ref
        .read(moveRepoProvider)
        .setSteps(Dates.todayKey(), v.round(), 'manual');
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged ${Fmt.intFmt(v.round())} steps')));
    }
  }

  Future<void> _manualWalk(BuildContext context, WidgetRef ref) async {
    final minutes = await askNumber(context,
        title: 'Walk duration', unit: 'minutes', initial: 30);
    if (minutes == null || !context.mounted) return;
    final steps = await askNumber(context,
        title: 'Steps (optional)', unit: 'steps', initial: 0);
    final now = DateTime.now();
    final w = WalkSession(
      id: newId(),
      dateKey: Dates.todayKey(),
      startedAt: now.subtract(Duration(minutes: minutes.round())),
      endedAt: now,
      durationSec: (minutes * 60).round(),
      steps: (steps ?? 0).round(),
      distanceM: (steps ?? 0) * 0.762,
      source: 'manual',
      note: 'Manual entry',
    );
    await ref.read(moveRepoProvider).addManualWalk(w);
    await ref.read(motivationRepoProvider).recordActivity(
          food: ref.read(foodRepoProvider),
          move: ref.read(moveRepoProvider),
          wellness: ref.read(wellnessRepoProvider),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Walk logged.')));
    }
  }
}

/// Dedicated, premium walking progress hero card with clay sneaker
class _DedicatedWalkingCard extends StatelessWidget {
  final int steps;
  final int goalSteps;
  final String source;
  final String units;

  const _DedicatedWalkingCard({
    required this.steps,
    required this.goalSteps,
    required this.source,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        goalSteps <= 0 ? 0.0 : (steps / goalSteps).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    final estMeters = steps * 0.762;
    final estDistance = Units.distance(estMeters, units);
    final estActiveMin = (steps / 105).round();
    final remaining = goalSteps - steps;

    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Progress ring with step count
              ProgressRing(
                progress: progress,
                size: 88,
                strokeWidth: 9,
                color: BloomColors.mintDeep,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Fmt.intFmt(steps),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                    ),
                    Text(
                      '$pct%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BloomColors.mintDeep,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BloomSpacing.md),
              // Middle & Right: Sneaker illustration & key stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Daily Steps',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const ClaySneakerIllustration(size: 48),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Goal: ${Fmt.intFmt(goalSteps)} steps',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      remaining > 0
                          ? '${Fmt.intFmt(remaining)} steps left to hit goal'
                          : '🎉 Goal completed!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: remaining > 0
                                ? Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7)
                                : BloomColors.mintDeep,
                            fontWeight: remaining > 0
                                ? FontWeight.normal
                                : FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Horizontal stats row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(BloomRadii.bubble),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem(context, 'Distance', estDistance, Icons.straighten_rounded),
                Container(
                  width: 1,
                  height: 24,
                  color: BloomColors.line.withOpacity(0.6),
                ),
                _statItem(context, 'Active time', '~$estActiveMin min', Icons.timer_outlined),
                Container(
                  width: 1,
                  height: 24,
                  color: BloomColors.line.withOpacity(0.6),
                ),
                _statItem(context, 'Source', source, Icons.check_circle_outline_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: BloomColors.mintDeep),
            const SizedBox(width: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.65),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
        ),
      ],
    );
  }
}

class _ActiveWalkCard extends ConsumerWidget {
  final WalkSession walk;
  const _ActiveWalkCard({required this.walk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BubbleCard(
      color: Theme.of(context).brightness == Brightness.dark
          ? BloomColors.mintD
          : BloomColors.mint,
      child: Row(
        children: [
          const Icon(Icons.directions_walk_rounded,
              color: BloomColors.mintDeep, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Walk in progress — tap to continue tracking',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          PillButton(
            label: 'Resume',
            secondary: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WalkScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkTile extends ConsumerWidget {
  final WalkSession walk;
  const _WalkTile({required this.walk});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileRepoProvider).profile;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: BloomColors.mintDeep.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.directions_walk_rounded,
                  color: BloomColors.mintDeep, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        Dates.relativeDay(walk.dateKey),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dark
                              ? BloomColors.mintD.withOpacity(0.3)
                              : BloomColors.mint.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(BloomRadii.pill),
                        ),
                        child: Text(
                          walk.indoor ? 'Indoor' : 'Outdoor',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: BloomColors.mintDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${Dates.formatDuration(Duration(seconds: walk.durationSec))}'
                    '${walk.steps > 0 ? ' · ${Fmt.intFmt(walk.steps)} steps' : ''}'
                    '${walk.distanceM > 0 ? ' · ${Units.distance(walk.distanceM, profile.units)}' : ''}'
                    '${walk.distanceM > 0 && walk.durationSec > 0 ? ' · ${Units.pace(walk.distanceM, walk.durationSec, profile.units)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete walk',
              onPressed: () async {
                final ok = await askConfirm(
                  context,
                  title: 'Delete walk?',
                  body: 'This walk record will be removed from your history.',
                  confirmLabel: 'Delete',
                );
                if (ok) {
                  await ref.read(moveRepoProvider).deleteWalk(walk.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ walk screen

class WalkScreen extends ConsumerStatefulWidget {
  const WalkScreen({super.key});

  @override
  ConsumerState<WalkScreen> createState() => _WalkScreenState();
}

class _WalkScreenState extends ConsumerState<WalkScreen> {
  Timer? _ticker;
  int _elapsed = 0;
  bool _paused = false;
  bool _indoor = false;
  WalkSession? _walk;

  @override
  void initState() {
    super.initState();
    _walk = ref.read(moveRepoProvider).activeWalk;
    if (_walk != null) _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _walk == null) return;
      if (!_paused) {
        setState(() => _elapsed =
            ref.read(moveRepoProvider).liveElapsed(_walk!));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Walk')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BloomSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProgressRing(
                      progress: 0,
                      size: 190,
                      color: BloomColors.mintDeep,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            Dates.formatDuration(
                                Duration(seconds: _elapsed)),
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall,
                          ),
                          Text(
                            _walk == null
                                ? 'ready'
                                : _paused
                                    ? 'paused'
                                    : 'walking',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: BloomSpacing.lg),
                    if (_walk == null) ...[
                      SegmentedPills<bool>(
                        values: const [false, true],
                        labels: const ['Outdoor', 'Indoor'],
                        selected: _indoor,
                        onChanged: (v) =>
                            setState(() => _indoor = v),
                      ),
                      const SizedBox(height: BloomSpacing.sm),
                      const InfoNote(
                        text:
                            'GPS route tracking is opt-in and not enabled in this version — distance is estimated from your steps at the end.',
                      ),
                    ] else ...[
                      Text(
                        'Started ${Dates.clock(_walk!.startedAt)}${_walk!.indoor ? ' · indoor' : ''}',
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (_walk == null)
                PillButton(
                  label: 'Start walk',
                  icon: Icons.play_arrow,
                  expanded: true,
                  onPressed: _start,
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: PillButton(
                        label: _paused ? 'Resume' : 'Pause',
                        icon: _paused
                            ? Icons.play_arrow
                            : Icons.pause,
                        secondary: true,
                        onPressed: _togglePause,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PillButton(
                        label: 'Finish',
                        icon: Icons.stop,
                        onPressed: _finish,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    final w =
        await ref.read(moveRepoProvider).startWalk(indoor: _indoor);
    setState(() {
      _walk = w;
      _elapsed = 0;
      _paused = false;
    });
    _startTicker();
  }

  Future<void> _togglePause() async {
    if (_walk == null) return;
    if (_paused) {
      await ref.read(moveRepoProvider).resumeWalk(_walk!.id);
    } else {
      await ref.read(moveRepoProvider).pauseWalk(_walk!.id);
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _finish() async {
    if (_walk == null) return;
    final profile = ref.read(profileRepoProvider).profile;
    final steps = await askNumber(context,
        title: 'How many steps?',
        unit: 'steps',
        initial: (_elapsed / 60 * 110).roundToDouble());
    if (steps == null) return;
    // Estimate distance from steps (~0.75 m/step), labeled as estimate.
    final distanceM = steps * 0.75;
    final finished = await ref
        .read(moveRepoProvider)
        .finishWalk(_walk!.id, steps: steps.round(), distanceM: distanceM);
    await ref.read(motivationRepoProvider).recordActivity(
          food: ref.read(foodRepoProvider),
          move: ref.read(moveRepoProvider),
          wellness: ref.read(wellnessRepoProvider),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Walk saved — ${Dates.formatDuration(Duration(seconds: finished?.durationSec ?? 0))} · ~${Units.distance(distanceM, profile.units)} (est.)')));
    }
  }
}
