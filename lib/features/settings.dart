import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../companion/pip.dart';
import '../core/export.dart';
import '../core/notifications.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/database.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'insights.dart';
import 'progress.dart';
import 'wellness.dart';

/// Profile tab: identity, goals, customization, privacy, integrations.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileRepoProvider).profile;
    final settings = ref.watch(settingsRepoProvider).settings;
    final motivation = ref.watch(motivationRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 150),
          children: [
            // 1. Profile Header with Editable Goals and Unit Toggle
            BubbleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Consumer(
                        builder: (context, ref, _) => PipCompanion(
                          size: 78,
                          accessory: motivation.activeAccessory,
                          reducedMotion: settings.reducedMotion,
                        ),
                      ),
                      const SizedBox(width: BloomSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name.isEmpty
                                  ? 'Your Bloom'
                                  : profile.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _goalLabel(profile.goal),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Edit profile & goals',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const GoalsEditorScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Interactive Unit Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.06),
                      borderRadius: BorderRadius.circular(BloomRadii.bubble),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            size: 16, color: BloomColors.mintDeep),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Units of measurement',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SegmentedPills<String>(
                          values: const ['metric', 'imperial'],
                          labels: const ['Metric (kg, km)', 'Imperial (lb, mi)'],
                          selected: profile.units,
                          onChanged: (u) {
                            profile.units = u;
                            ref.read(profileRepoProvider).save(profile);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Key Goals Snapshot Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _goalChip(
                        context,
                        'Target',
                        profile.targetKcal != null
                            ? '${profile.targetKcal!.round()} kcal'
                            : 'Auto kcal',
                        Icons.local_fire_department_rounded,
                        BloomColors.peachDeep,
                      ),
                      Container(width: 1, height: 26, color: BloomColors.line),
                      _goalChip(
                        context,
                        'Daily steps',
                        Fmt.intFmt(profile.walkGoalSteps),
                        Icons.directions_walk_rounded,
                        BloomColors.mintDeep,
                      ),
                      Container(width: 1, height: 26, color: BloomColors.line),
                      _goalChip(
                        context,
                        'Sleep goal',
                        Dates.formatHm(profile.sleepGoalH),
                        Icons.nightlight_round,
                        BloomColors.lavenderDeep,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: BloomSpacing.md),

            // 2. Companion Customization Preview Card
            BubbleCard(
              padding: const EdgeInsets.all(BloomSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: BloomColors.mintDeep.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: PipCompanion(
                        size: 52,
                        accessory: motivation.activeAccessory,
                        reducedMotion: settings.reducedMotion,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Companion preview',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          motivation.activeAccessory.isNotEmpty
                              ? 'Accessory: ${motivation.activeAccessory}'
                              : 'Standard sprout look',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PillButton(
                    label: 'Wardrobe',
                    icon: Icons.checkroom_rounded,
                    secondary: true,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MotivationScreen()),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Health & Progress
            const SectionHeader(title: 'Health & progress'),
            SettingRow(
              icon: Icons.show_chart_outlined,
              title: 'Weight & body progress',
              subtitle: profile.showWeight
                  ? 'Trends, smoothed average, photos'
                  : 'Currently hidden',
              tint: _tint(context, BloomColors.lavender, BloomColors.lavenderD),
              deep: BloomColors.lavenderDeep,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProgressScreen()),
              ),
            ),
            SettingRow(
              icon: Icons.insights_outlined,
              title: 'Insights & reports',
              subtitle: 'Weekly trends, summary charts, CSV & PDF export',
              tint: _tint(context, BloomColors.mint, BloomColors.mintD),
              deep: BloomColors.mintDeep,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const InsightsScreen()),
              ),
            ),
            SettingRow(
              icon: Icons.emoji_events_outlined,
              title: 'Motivation & challenges',
              subtitle: 'Daily streaks, achievements & Pip accessories',
              tint: _tint(context, BloomColors.peach, BloomColors.peachD),
              deep: BloomColors.peachDeep,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MotivationScreen()),
              ),
            ),
            SettingRow(
              icon: Icons.alarm_outlined,
              title: 'Reminders',
              subtitleWidget: _reminderSubtitle(),
              tint: _tint(context, BloomColors.sky, BloomColors.skyD),
              deep: BloomColors.skyDeep,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RemindersScreen()),
              ),
            ),

            // 4. Customize & Display
            const SectionHeader(title: 'Customize & display'),
            SettingRow(
              icon: Icons.dashboard_outlined,
              title: 'Today screen',
              subtitle: 'Choose which summaries appear on your home feed',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const TodayCustomizerScreen()),
              ),
            ),
            SettingRow(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              subtitle: _themeLabel(settings.themeMode),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _appearanceSheet(context, ref),
            ),
            SettingRow(
              icon: Icons.animation_outlined,
              title: 'Reduce motion',
              subtitle: settings.reducedMotion
                  ? 'On — 3D and UI animations are still'
                  : 'Off — full smooth animations',
              trailing: Switch(
                value: settings.reducedMotion,
                onChanged: (v) {
                  final s = ref.read(settingsRepoProvider).settings;
                  s.reducedMotion = v;
                  ref.read(settingsRepoProvider).save(s);
                },
              ),
            ),
            SettingRow(
              icon: Icons.pets_outlined,
              title: 'Show Pip companion',
              subtitle: settings.companionVisible
                  ? 'Pip appears on Today and floating chat button'
                  : 'Hidden',
              trailing: Switch(
                value: settings.companionVisible,
                onChanged: (v) {
                  final s = ref.read(settingsRepoProvider).settings;
                  s.companionVisible = v;
                  ref.read(settingsRepoProvider).save(s);
                },
              ),
            ),
            const SectionHeader(title: 'Privacy & security'),
            SettingRow(
              icon: Icons.fingerprint_outlined,
              title: 'Biometric app lock',
              subtitle: _lockSubtitle(),
              trailing: Switch(
                value: settings.biometricLock,
                onChanged: (v) async {
                  final s = ref
                      .read(settingsRepoProvider)
                      .settings;
                  s.biometricLock = v;
                  await ref
                      .read(settingsRepoProvider)
                      .save(s);
                  if (v && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                            content: Text(
                                'App lock enabled. You\'ll unlock with biometrics next launch.')));
                  }
                },
              ),
            ),
            SettingRow(
              icon: Icons.notifications_outlined,
              title: 'Notification previews',
              subtitle: settings.notifPreview
                  ? 'Show reminder content on lock screen'
                  : 'Hide content on lock screen',
              trailing: Switch(
                value: settings.notifPreview,
                onChanged: (v) {
                  final s = ref
                      .read(settingsRepoProvider)
                      .settings;
                  s.notifPreview = v;
                  ref
                      .read(settingsRepoProvider)
                      .save(s);
                },
              ),
            ),
            SettingRow(
              icon: Icons.download_outlined,
              title: 'Export my data',
              subtitle: 'Full backup as JSON',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportAll(context),
            ),
            SettingRow(
              icon: Icons.delete_forever_outlined,
              title: 'Delete my data',
              subtitle: 'Remove everything on this device',
              deep: BloomColors.roseDeep,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _deleteAll(context, ref),
            ),
            SettingRow(
              icon: Icons.info_outline,
              title: 'About Bloom',
              subtitle: 'How Pip works, data sources, version',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AboutScreen())),
            ),
            const SizedBox(height: BloomSpacing.md),
            Center(
              child: Text(
                'Made with care · your data never leaves this device',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _goalLabel(String goal) => switch (goal) {
        'lose' => 'Working toward weight loss',
        'gain' => 'Working toward weight gain',
        'maintain' => 'Maintaining weight',
        'fitness' => 'Building strength & fitness',
        _ => 'Building everyday habits',
      };

  Widget _goalChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
        ),
      ],
    );
  }

  String _themeLabel(String mode) => switch (mode) {
        'light' => 'Light',
        'dark' => 'Dark',
        _ => 'System',
      };

  String? _lockSubtitle() =>
      NotificationService.supported ? null : null;

  Color _tint(BuildContext context, Color light, Color dark) =>
      Theme.of(context).brightness == Brightness.dark
          ? dark
          : light;

  Widget _reminderSubtitle() {
    return Consumer(
      builder: (context, ref, _) {
        final items =
            ref.watch(reminderRepoProvider).items;
        final enabled =
            items.where((r) => r.enabled).length;
        if (!NotificationService.supported) {
          return const Text(
              'Not supported on this platform');
        }
        return Text(enabled == 0
            ? 'No active reminders'
            : '$enabled active reminder${enabled == 1 ? '' : 's'}');
      },
    );
  }

  Future<void> _appearanceSheet(
      BuildContext context, WidgetRef ref) async {
    final mode = await showBubbleSheet<String>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Appearance',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.md),
          for (final m in [
            ('system', 'System'),
            ('light', 'Light'),
            ('dark', 'Dark')
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PillButton(
                label: m.$2,
                secondary: true,
                expanded: true,
                onPressed: () =>
                    Navigator.of(context).pop(m.$1),
              ),
            ),
        ],
      ),
      scrollable: false,
    );
    if (mode != null) {
      final s = ref.read(settingsRepoProvider).settings;
      s.themeMode = mode;
      await ref.read(settingsRepoProvider).save(s);
    }
  }

  Future<void> _exportAll(BuildContext context) async {
    try {
      final data = Database.exportAll();
      final path = await ExportService.writeTextFile(
        'bloom-backup-${Dates.todayKey()}.json',
        jsonEncode(data),
      );
      await ExportService.shareFile(path,
          subject: 'Bloom backup');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _deleteAll(
      BuildContext context, WidgetRef ref) async {
    final first = await askConfirm(
      context,
      title: 'Delete all data?',
      body:
          'This removes every record on this device — meals, workouts, weight, journal, chat, everything. This cannot be undone.',
      confirmLabel: 'Delete everything',
    );
    if (!first || !context.mounted) return;
    final second = await askConfirm(
      context,
      title: 'Are you really sure?',
      body:
          'Last chance: all Bloom data on this device will be permanently deleted.',
      confirmLabel: 'Yes, delete it all',
    );
    if (!second) return;
    await Database.deleteAll();
    // Reload repos to empty state.
    ref.read(profileRepoProvider).load();
    ref.read(foodRepoProvider).load();
    ref.read(recipeRepoProvider).load();
    ref.read(planRepoProvider).load();
    ref.read(progressRepoProvider).load();
    ref.read(moveRepoProvider).load();
    ref.read(wellnessRepoProvider).load();
    ref.read(healthRepoProvider).load();
    ref.read(chatRepoProvider).load();
    ref.read(reminderRepoProvider).load();
    ref.read(motivationRepoProvider).load();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('All data deleted.')));
    }
  }
}

// ------------------------------------------------------------ goals editor

class GoalsEditorScreen extends ConsumerStatefulWidget {
  const GoalsEditorScreen({super.key});
  @override
  ConsumerState<GoalsEditorScreen> createState() =>
      _GoalsEditorScreenState();
}

class _GoalsEditorScreenState
    extends ConsumerState<GoalsEditorScreen> {
  late UserProfile _p;
  late TextEditingController _name,
      _height,
      _weight,
      _goalWeight,
      _steps,
      _water,
      _sleep,
      _kcal,
      _protein,
      _carbs,
      _fat,
      _fiber;

  @override
  void initState() {
    super.initState();
    _p = ref.read(profileRepoProvider).profile;
    final imperial = _p.units == 'imperial';
    _name = TextEditingController(text: _p.name);
    _height = TextEditingController(
        text: _p.heightCm == null
            ? ''
            : Fmt.num(
                imperial
                    ? Units.cmToIn(_p.heightCm!)
                    : _p.heightCm!,
                1));
    _weight = TextEditingController(
        text: _p.startWeightKg == null
            ? ''
            : Units.weightShort(_p.startWeightKg!, _p.units));
    _goalWeight = TextEditingController(
        text: _p.goalWeightKg == null
            ? ''
            : Units.weightShort(_p.goalWeightKg!, _p.units));
    _steps = TextEditingController(text: '${_p.walkGoalSteps}');
    _water = TextEditingController(
        text: imperial
            ? Units.mlToFloz(_p.waterGoalMl).toStringAsFixed(0)
            : (_p.waterGoalMl / 1000).toStringAsFixed(1));
    _sleep = TextEditingController(
        text: _p.sleepGoalH.toStringAsFixed(1));
    _kcal = TextEditingController(
        text: _p.targetKcal?.toStringAsFixed(0) ?? '');
    _protein = TextEditingController(
        text: _p.targetProtein?.toStringAsFixed(0) ?? '');
    _carbs = TextEditingController(
        text: _p.targetCarbs?.toStringAsFixed(0) ?? '');
    _fat = TextEditingController(
        text: _p.targetFat?.toStringAsFixed(0) ?? '');
    _fiber = TextEditingController(
        text: _p.targetFiber?.toStringAsFixed(0) ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _goalWeight.dispose();
    _steps.dispose();
    _water.dispose();
    _sleep.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imperial = _p.units == 'imperial';
    return Scaffold(
      appBar: AppBar(title: const Text('Goals & targets')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 100),
          children: [
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            SegmentedPills<String>(
              values: const ['metric', 'imperial'],
              labels: const ['Metric', 'Imperial'],
              selected: _p.units,
              onChanged: (v) =>
                  setState(() => _p.units = v),
            ),
            const SectionHeader(title: 'Goal'),
            Wrap(
              spacing: 8,
              children: [
                for (final g in [
                  'lose',
                  'gain',
                  'maintain',
                  'fitness',
                  'habits'
                ])
                  ChoiceChip(
                    label: Text(g),
                    selected: _p.goal == g,
                    onSelected: (_) =>
                        setState(() => _p.goal = g),
                  ),
              ],
            ),
            const SectionHeader(title: 'Body'),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _height,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                            labelText:
                                'Height (${imperial ? 'in' : 'cm'})'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _weight,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                            labelText:
                                'Weight (${imperial ? 'lb' : 'kg'})'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _goalWeight,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                            labelText:
                                'Goal (${imperial ? 'lb' : 'kg'})'))),
              ],
            ),
            const SectionHeader(title: 'Daily goals'),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _steps,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Steps'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _water,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: InputDecoration(
                            labelText:
                                'Water (${imperial ? 'fl oz' : 'L'})'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _sleep,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Sleep (h)'))),
              ],
            ),
            if (_p.showCalories) ...[
              SectionHeader(
                title: 'Nutrition targets',
                subtitle: _p.targetsEstimated
                    ? 'Estimated — edit freely'
                    : 'Your own numbers',
              ),
              TextField(
                  controller: _kcal,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                          decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Calories (kcal)')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _protein,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration:
                              const InputDecoration(
                                  labelText: 'Protein (g)'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _carbs,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration:
                              const InputDecoration(
                                  labelText: 'Carbs (g)'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _fat,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration:
                              const InputDecoration(
                                  labelText: 'Fat (g)'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: _fiber,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration:
                              const InputDecoration(
                                  labelText: 'Fiber (g)'))),
                ],
              ),
              const SizedBox(height: 8),
              if (_p.allowEstimatedTargets)
                PillButton(
                  label: 'Re-estimate from my details',
                  secondary: true,
                  onPressed: _reestimate,
                ),
            ],
            const SectionHeader(title: 'Visibility'),
            SwitchListTile(
              value: _p.showWeight,
              onChanged: (v) =>
                  setState(() => _p.showWeight = v),
              title: const Text('Show weight features'),
            ),
            SwitchListTile(
              value: _p.showCalories,
              onChanged: (v) =>
                  setState(() => _p.showCalories = v),
              title: const Text('Show calorie summaries'),
              subtitle: const Text(
                  'Hide for a habits-only experience'),
            ),
            const SizedBox(height: BloomSpacing.lg),
            PillButton(
              label: 'Save',
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  void _reestimate() {
    final imperial = _p.units == 'imperial';
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    if (h == null || w == null || _p.ageYears == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Enter height, weight, and birth year to re-estimate.')));
      return;
    }
    final kcal = Calc.mifflinKcal(
      weightKg: imperial ? Units.lbToKg(w) : w,
      heightCm: imperial ? Units.inToCm(h) : h,
      ageYears: _p.ageYears!,
      isFemale: _p.isFemale,
      activityLevel: _p.activityLevel,
      goal: _p.goal,
      allowEstimate: true,
    );
    if (kcal == null) return;
    final macros = Calc.macroTargets(
        kcal, imperial ? Units.lbToKg(w) : w, _p.goal);
    setState(() {
      _kcal.text = kcal.round().toString();
      _protein.text = macros['protein']!.round().toString();
      _carbs.text = macros['carbs']!.round().toString();
      _fat.text = macros['fat']!.round().toString();
      _fiber.text = macros['fiber']!.round().toString();
    });
  }

  Future<void> _save() async {
    final imperial = _p.units == 'imperial';
    _p.name = _name.text.trim();
    final h = double.tryParse(_height.text);
    final w = double.tryParse(_weight.text);
    final gw = double.tryParse(_goalWeight.text);
    _p.heightCm =
        h == null ? null : (imperial ? Units.inToCm(h) : h);
    _p.startWeightKg =
        w == null ? null : (imperial ? Units.lbToKg(w) : w);
    _p.goalWeightKg =
        gw == null ? null : (imperial ? Units.lbToKg(gw) : gw);
    _p.walkGoalSteps = int.tryParse(_steps.text) ?? _p.walkGoalSteps;
    final waterV = double.tryParse(_water.text);
    if (waterV != null && waterV > 0) {
      _p.waterGoalMl =
          imperial ? waterV * Units.mlPerFloz : waterV * 1000;
    }
    final sleepV = double.tryParse(_sleep.text);
    if (sleepV != null && sleepV > 0) {
      _p.sleepGoalH = sleepV.clamp(1, 16).toDouble();
    }
    _p.targetKcal = double.tryParse(_kcal.text);
    _p.targetProtein = double.tryParse(_protein.text);
    _p.targetCarbs = double.tryParse(_carbs.text);
    _p.targetFat = double.tryParse(_fat.text);
    _p.targetFiber = double.tryParse(_fiber.text);
    await ref.read(profileRepoProvider).save(_p);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Goals saved.')));
    }
  }
}

// -------------------------------------------------------- today customizer

class TodayCustomizerScreen extends ConsumerWidget {
  const TodayCustomizerScreen({super.key});

  static const _options = [
    ('habits', 'Habit progress', 'Daily habit checkmarks'),
    ('nutrition', 'Nutrition summary', 'Calories & macros (if enabled)'),
    ('steps', 'Steps card', 'Step count & goal'),
    ('water', 'Water card', 'Hydration progress'),
    ('sleep', 'Sleep card', 'Last night\'s sleep'),
    ('timeline', 'Timeline', 'Today\'s logged activity'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsRepoProvider).settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Today screen')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 40),
          children: [
            const InfoNote(
              text:
                  'Choose what appears on your Today screen. Bloom never shows a single "health score".',
            ),
            const SizedBox(height: 8),
            for (final o in _options)
              SwitchListTile(
                value: settings.todayWidgets.contains(o.$1),
                onChanged: (v) {
                  final s = ref
                      .read(settingsRepoProvider)
                      .settings;
                  if (v) {
                    if (!s.todayWidgets.contains(o.$1)) {
                      s.todayWidgets.add(o.$1);
                    }
                  } else {
                    s.todayWidgets.remove(o.$1);
                  }
                  ref
                      .read(settingsRepoProvider)
                      .save(s);
                },
                title: Text(o.$2),
                subtitle: Text(o.$3),
              ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- reminders

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(reminderRepoProvider);
    final items = repo.items;
    final supported = NotificationService.supported;
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 100),
          children: [
            InfoNote(
              text: supported
                  ? 'Reminders are scheduled on this device with the system notification service.'
                      '${NotificationService.permissionGranted ? '' : ' Permission has not been granted yet.'}'
                  : 'Local reminders are not supported on this platform (e.g. web preview). Your reminder list is still saved.',
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('No reminders yet.',
                  style: Theme.of(context).textTheme.bodySmall),
            for (final r in items)
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
                            Text(r.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                            Text(
                              '${r.time} · ${r.weekdays.isEmpty ? 'daily' : 'selected days'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: r.enabled,
                        onChanged: (v) async {
                          r.enabled = v;
                          await repo.save(r);
                          await _reschedule(ref, r);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 20),
                        onPressed: () async {
                          await NotificationService.cancel(
                              r.id);
                          await repo.delete(r.id);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editReminder(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add reminder'),
      ),
    );
  }

  Future<void> _reschedule(
      WidgetRef ref, ReminderItem r) async {
    if (!NotificationService.supported) return;
    if (r.enabled) {
      await NotificationService.scheduleReminder(r,
          showPreview: ref
              .read(settingsRepoProvider)
              .settings
              .notifPreview);
    } else {
      await NotificationService.cancel(r.id);
    }
  }

  Future<void> _editReminder(
      BuildContext context, WidgetRef ref, ReminderItem? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    TimeOfDay time = const TimeOfDay(hour: 9, minute: 0);
    if (existing != null) {
      final p = existing.time.split(':');
      time = TimeOfDay(
          hour: int.tryParse(p[0]) ?? 9,
          minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
    }
    final saved = await showBubbleSheet<bool>(
      context,
      StatefulBuilder(
        builder: (ctx, setS) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New reminder',
                style: Theme.of(ctx).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextField(
                controller: title,
                decoration: const InputDecoration(
                    labelText: 'Title (e.g. Drink water)')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: Text(
                        'Time: ${time.format(ctx)}',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleSmall)),
                TextButton(
                  onPressed: () async {
                    final p = await showTimePicker(
                        context: ctx, initialTime: time);
                    if (p != null) setS(() => time = p);
                  },
                  child: const Text('Change'),
                ),
              ],
            ),
            const SizedBox(height: BloomSpacing.md),
            PillButton(
                label: 'Save reminder',
                expanded: true,
                onPressed: () =>
                    Navigator.of(ctx).pop(true)),
          ],
        ),
      ),
    );
    if (saved == true && title.text.trim().isNotEmpty) {
      if (!NotificationService.supported) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Saved to your list. OS reminders are not supported on this platform.')));
        }
      } else {
        final granted =
            await NotificationService.requestPermission();
        if (!granted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Notification permission was not granted — reminder saved but not scheduled.')));
        }
      }
      final item = ReminderItem(
        id: existing?.id ?? newId(),
        title: title.text.trim(),
        time:
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      );
      await ref.read(reminderRepoProvider).save(item);
      await _reschedule(ref, item);
    }
    title.dispose();
  }
}

// ------------------------------------------------------------------- about

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About Bloom')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 40),
          children: [
            const Center(
                child: PipCompanion(size: 120, reducedMotion: true)),
            const SizedBox(height: BloomSpacing.md),
            Text('Bloom 1.0.0',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: BloomSpacing.md),
            const _AboutCard(
              title: 'About Pip',
              body:
                  'Pip is an original, hand-drawn 2D animated character rendered live with Flutter\u2019s canvas. Pip is not a 3D model and does not use pre-rendered video. Pip\u2019s body never changes with your weight, and Pip never shames missed goals.',
            ),
            const _AboutCard(
              title: 'Companion chat',
              body:
                  'Pip\u2019s chat runs in offline guided mode: scripted responses grounded in your saved records. No AI service is connected and nothing leaves your device. Pip always asks before logging anything.',
            ),
            const _AboutCard(
              title: 'Nutrition data',
              body:
                  'The food catalog uses reference values (USDA SR Legacy and Philippine Food Composition Table estimates). Entries are marked approximate where data is estimated. Nutrition targets are estimates from the Mifflin-St Jeor equation — editable, never prescriptions. Barcode scanning and photo recognition are not included in this version.',
            ),
            const _AboutCard(
              title: 'Privacy',
              body:
                  'Core logging works without an account. Everything is stored on this device in a local database. There is no cloud sync in this version. You can export or delete your data anytime from Profile.',
            ),
            const _AboutCard(
              title: 'A gentle note',
              body:
                  'Bloom is a self-care companion, not a medical device. It does not diagnose, does not recommend medication doses, and does not replace professional care. If you are struggling, please reach out to a qualified professional or a trusted person.',
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  final String title;
  final String body;
  const _AboutCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(body,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
