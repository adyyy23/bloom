import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../companion/pip.dart';
import '../companion/human_visualizer.dart';
import '../companion/human_body_mesh.dart';
import '../companion/edit_measurements_sheet.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/catalog.dart';
import 'nutrition.dart';
import 'move.dart';
import 'wellness.dart';
import 'chat.dart';

/// The opening screen: greeting, 3D human body visualizer hero stage,
/// body metrics summary, habit progress, summaries, and quick actions.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final _pip = PipController();
  bool _isGoalPreview = false;

  @override
  void dispose() {
    _pip.dispose();
    super.dispose();
  }

  Future<void> _openEditSheet(BuildContext context) async {
    await showBubbleSheet<bool>(
      context,
      const EditMeasurementsSheet(),
      scrollable: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    final settings = ref.watch(settingsRepoProvider).settings;
    final widgets = settings.todayWidgets;
    final key = Dates.todayKey();

    final food = ref.watch(foodRepoProvider);
    final move = ref.watch(moveRepoProvider);
    final wellness = ref.watch(wellnessRepoProvider);
    ref.watch(planRepoProvider);
    final motivation = ref.watch(motivationRepoProvider);

    final progress = ref.watch(progressRepoProvider);
    final avatar = ref.watch(avatarRepoProvider).config.copyWith(
          waistCm: progress.latestMeasure('waist'),
          hipCm: progress.latestMeasure('hips'),
          chestCm: progress.latestMeasure('chest'),
        );

    final latestWeight =
        progress.latest?.weightKg ?? profile.startWeightKg ?? 65.0;
    final heightCm = profile.heightCm ?? 170.0;

    final bmiResult = Calc.calculateBmi(
      weightKg: progress.latest?.weightKg ?? profile.startWeightKg,
      heightCm: profile.heightCm,
      birthYear: profile.birthYear,
      pregnancyOrNursing: profile.pregnancyOrNursing,
      specializedGuidance: profile.specializedGuidance,
    );

    final nutrition = food.dayNutrition(key);
    final steps = move.displaySteps(key);
    final water = wellness.waterTotal(key);
    final sleep = wellness.sleepFor(key);
    final streak = motivation.streakDays(
      food: food,
      move: move,
      wellness: wellness,
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. Prominent 3D Human Body Visualizer Hero Stage
            SliverToBoxAdapter(
              child: _heroStage(
                context: context,
                profile: profile,
                streak: streak,
                settings: settings,
                weightKg: latestWeight,
                heightCm: heightCm,
                avatar: avatar,
                goalWeightKg: profile.goalWeightKg,
              ),
            ),

            // 2. Concise Body Metrics & Clinical Classification Summary
            SliverToBoxAdapter(
              child: _bodyMetricsSummary(
                context: context,
                profile: profile,
                weightKg: latestWeight,
                heightCm: heightCm,
                bmiResult: bmiResult,
                latest: progress.latest,
                avatar: avatar,
              ),
            ),

            // 3. Featured Activity Panel (Powder Blue)
            SliverToBoxAdapter(child: _featuredActivityCard(context, ref)),

            // 4. Quick Action Row
            SliverToBoxAdapter(child: _quickActions(context, ref)),

            // 4. Habits Checklist
            if (widgets.contains('habits'))
              SliverToBoxAdapter(child: _habitProgress(context, ref, key)),

            // 5. Nutrition Calorie Ring
            if (widgets.contains('nutrition') && profile.showCalories)
              SliverToBoxAdapter(
                child: _nutritionCard(context, profile, nutrition),
              ),

            // 6. Stats Row (Steps, Water, Sleep)
            if (widgets.contains('steps') ||
                widgets.contains('water') ||
                widgets.contains('sleep'))
              SliverToBoxAdapter(
                child: _statsRow(
                  context,
                  ref,
                  profile,
                  widgets,
                  steps,
                  water,
                  sleep,
                ),
              ),

            // 7. Upcoming Plans
            SliverToBoxAdapter(child: _upcoming(context, ref, key, profile)),

            // 8. Logged Timeline
            if (widgets.contains('timeline'))
              SliverToBoxAdapter(child: _timeline(context, ref, key, profile)),

            // Bottom scroll padding to clear floating nav
            const SliverToBoxAdapter(child: SizedBox(height: 150)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------- hero stage

  Widget _heroStage({
    required BuildContext context,
    required UserProfile profile,
    required int streak,
    required AppSettings settings,
    required double weightKg,
    required double heightCm,
    required AvatarConfig avatar,
    double? goalWeightKg,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: dark ? BloomColors.heroPeachD : BloomColors.heroPeach,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(profile, streak),
          HumanVisualizer(
            heightCm: heightCm,
            weightKg: weightKg,
            goalWeightKg: goalWeightKg,
            config: avatar,
            isFemale: profile.isFemale,
            isGoalPreview: _isGoalPreview,
            reducedMotion: settings.reducedMotion,
            stageHeight: (MediaQuery.sizeOf(context).height * .46).clamp(
              330.0,
              430.0,
            ),
            onPreviewModeChanged: (val) => setState(() => _isGoalPreview = val),
            onEditMeasurements: () =>
                showBubbleSheet(context, const AppearanceSheet()),
          ),
          ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const SizedBox(height: 8)),
        ],
      ),
    );
  }

  Widget _header(UserProfile profile, int streak) {
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
    final name = profile.name.isEmpty ? '' : ', ${profile.name}';
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.lg,
        BloomSpacing.md,
        BloomSpacing.lg,
        BloomSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? greet : 'Hi$name',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  Dates.long(DateTime.now()),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 13.5, color: BloomColors.inkSoft),
                ),
              ],
            ),
          ),
          // Pip Companion Shortcut Pill
          InkWell(
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ChatScreen())),
            borderRadius: BorderRadius.circular(BloomRadii.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(BloomRadii.pill),
                border: Border.all(
                  color:
                      dark ? Colors.white.withOpacity(0.1) : BloomColors.line,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 18, color: BloomColors.primaryViolet),
                  SizedBox(width: 5),
                  Text(
                    'Pip',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BloomColors.primaryViolet,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Streak Badge
          InkWell(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MotivationScreen())),
            borderRadius: BorderRadius.circular(BloomRadii.pill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(BloomRadii.pill),
                border: Border.all(
                  color:
                      dark ? Colors.white.withOpacity(0.1) : BloomColors.line,
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(dark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    size: 15,
                    color: BloomColors.peachDeep,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    streak > 0 ? '$streak' : 'Rhythm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: BloomColors.peachDeep,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------- body metrics

  Widget _bodyMetricsSummary({
    required BuildContext context,
    required UserProfile profile,
    required double weightKg,
    required double heightCm,
    required BmiResult? bmiResult,
    required WeightEntry? latest,
    required AvatarConfig avatar,
  }) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('Your body, your pace', style: t.titleLarge)),
          IconButton(
              tooltip: 'Edit saved measurements',
              onPressed: () => _openEditSheet(context),
              icon: const Icon(Icons.tune_rounded)),
        ]),
        Text(
            profile.heightCm == null ||
                    (latest == null && profile.startWeightKg == null)
                ? 'Sample proportions • add measurements to personalize'
                : 'Approximate illustration • not a body scan',
            style: t.bodySmall),
        const SizedBox(height: 12),
        Wrap(spacing: 22, runSpacing: 10, children: [
          _metric(
              context,
              'Weight',
              latest == null && profile.startWeightKg == null
                  ? '—'
                  : Units.weight(weightKg, profile.units),
              latest == null
                  ? (profile.startWeightKg == null ? 'Add weight' : 'Baseline')
                  : Dates.relativeDay(latest.dateKey)),
          _metric(
              context,
              'Height',
              profile.heightCm == null
                  ? '—'
                  : Units.length(heightCm, profile.units),
              profile.heightCm == null ? 'Add height' : 'Saved height'),
          InkWell(
              onTap: () => _showBmiInfoDialog(context, bmiResult, profile),
              child: _metric(
                  context,
                  'BMI',
                  bmiResult?.bmi.toStringAsFixed(1) ?? '—',
                  bmiResult?.category ?? 'Add measurements')),
        ]),
        if (_isGoalPreview && profile.goalWeightKg != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                  'Illustrative goal: ${Units.weight(profile.goalWeightKg ?? weightKg, profile.units)}. Records above remain current. Shape is approximate, not a prediction.',
                  style: t.bodySmall)),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _metric(
      BuildContext context, String label, String value, String detail) {
    final t = Theme.of(context).textTheme;
    return Semantics(
        label: '$label: $value. $detail',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: t.labelSmall),
          Text(value,
              style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          Text(detail, style: t.bodySmall?.copyWith(fontSize: 11)),
        ]));
  }

  void _showBmiInfoDialog(
    BuildContext context,
    BmiResult? result,
    UserProfile profile,
  ) {
    showBubbleSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BloomColors.mint.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_outlined,
                  color: BloomColors.mintDeep,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'BMI Category & Body Composition',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),
          const InfoNote(
            icon: Icons.info_outline,
            text:
                'BMI is a screening measure and does not describe body composition or overall health.',
          ),
          const SizedBox(height: BloomSpacing.md),
          Text(
            'About Body Mass Index (BMI)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'BMI calculates weight relative to height squared (kg/m²). It provides a quick screening ratio for population studies, but cannot distinguish between lean muscle, bone density, and body fat distribution.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: BloomSpacing.md),
          Text(
            'WHO & CDC Adult Reference Categories',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          _bmiCategoryRow('< 18.5', 'Underweight', const Color(0xFF64B5F6)),
          _bmiCategoryRow(
            '18.5 – <25',
            'Standard range',
            const Color(0xFF81C784),
          ),
          _bmiCategoryRow('25 – <30', 'Overweight', const Color(0xFFFFB74D)),
          _bmiCategoryRow('≥ 30.0', 'Obesity', const Color(0xFFE57373)),
          const SizedBox(height: BloomSpacing.md),
          Text(
            'Special Clinical Considerations',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '• Age:  Adult categories do not apply under age 20. Growth percentiles should be used.\n'
            '• Pregnancy & Nursing: Natural weight changes are essential; BMI screening is unsuitable.\n'
            '• Athletic Training: High muscle mass often results in higher BMI without elevated adiposity.\n'
            '• Specialized Guidance: Your physician or dietitian guidance supersedes general population screening.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: BloomSpacing.lg),
          PillButton(
            label: 'Understood',
            expanded: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _bmiCategoryRow(String range, String category, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            range,
            style: const TextStyle(fontSize: 12, color: BloomColors.inkSoft),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------- featured activity card

  Widget _featuredActivityCard(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = BloomColors.primaryViolet;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: InkWell(
        onTap: () => _startWorkout(context, ref),
        borderRadius: BorderRadius.circular(BloomRadii.card),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF1E2838) : BloomColors.powderBlue,
            borderRadius: BorderRadius.circular(BloomRadii.card),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFD4E5FA),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Movement Routine',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Session 1',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: dark ? Colors.white70 : BloomColors.inkSoft,
                          ),
                        ),
                        const SizedBox(width: 8),
                        for (int i = 0; i < 7; i++)
                          Container(
                            width: 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < 3
                                  ? primary
                                  : (dark
                                      ? Colors.white24
                                      : const Color(0xFFBACAE0)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? primary.withOpacity(0.25)
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(BloomRadii.pill),
                        border: Border.all(
                          color: primary.withOpacity(0.18),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 14, color: primary),
                          const SizedBox(width: 4),
                          Text(
                            '100 rhythm points',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------- quick actions

  Widget _quickActions(BuildContext context, WidgetRef ref) {
    final actions = [
      (
        _QA('Meal', Icons.restaurant_outlined, isPrimary: true),
        () => _logMeal(context),
      ),
      (_QA('Water', Icons.water_drop_outlined), () => _addWater(context, ref)),
      (_QA('Walk', Icons.directions_walk_outlined), () => _startWalk(context)),
      (
        _QA('Workout', Icons.fitness_center_outlined),
        () => _startWorkout(context, ref),
      ),
      (_QA('Check in', Icons.spa_outlined), () => _checkIn(context, ref)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;
          if (isNarrow) {
            return SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: actions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => _buildQAItem(
                  context,
                  actions[i].$1,
                  actions[i].$2,
                  width: 70,
                ),
              ),
            );
          }
          return Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(
                  child: _buildQAItem(context, actions[i].$1, actions[i].$2),
                ),
                if (i < actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildQAItem(
    BuildContext context,
    _QA a,
    VoidCallback onTap, {
    double? width,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final primary = BloomColors.primaryViolet;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BloomRadii.bubble),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: dark
              ? (a.isPrimary
                  ? primary.withOpacity(0.20)
                  : const Color(0xFF242428))
              : (a.isPrimary ? BloomColors.paleLavender : Colors.white),
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          border: Border.all(
            color: dark
                ? (a.isPrimary
                    ? primary.withOpacity(0.4)
                    : Colors.white.withOpacity(0.08))
                : (a.isPrimary ? primary.withOpacity(0.3) : BloomColors.line),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(dark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: a.isPrimary
                    ? primary
                    : (dark
                        ? Colors.white.withOpacity(0.08)
                        : BloomColors.paleLavender.withOpacity(0.6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                a.icon,
                color: a.isPrimary ? Colors.white : primary,
                size: 19,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              a.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontSize: 11.5,
                    fontWeight: a.isPrimary ? FontWeight.w700 : FontWeight.w600,
                    color: a.isPrimary
                        ? primary
                        : (dark ? Colors.white : BloomColors.ink),
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logMeal(BuildContext context) async {
    final meal = await showBubbleSheet<String>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Which meal?',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BloomSpacing.md),
          for (final m in ['breakfast', 'lunch', 'dinner', 'snack'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PillButton(
                label: m[0].toUpperCase() + m.substring(1),
                secondary: true,
                expanded: true,
                onPressed: () => Navigator.of(context).pop(m),
              ),
            ),
        ],
      ),
      scrollable: false,
    );
    if (meal != null && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FoodSearchScreen(initialMeal: meal)),
      );
      _pip.reactToMeal(name: meal[0].toUpperCase() + meal.substring(1));
    }
  }

  Future<void> _addWater(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileRepoProvider).profile;
    final ml = await askNumber(
      context,
      title: 'Log water',
      unit: profile.units == 'imperial' ? 'fl oz' : 'ml',
      initial: profile.units == 'imperial' ? 8 : 250,
    );
    if (ml == null) return;
    final mlReal = profile.units == 'imperial' ? Units.flozToMl(ml) : ml;
    await ref.read(wellnessRepoProvider).addWater(mlReal);
    await _afterLog(ref);
    _pip.reactToWater(ml: mlReal.round());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged ${Units.volume(mlReal, profile.units)} of water',
          ),
        ),
      );
    }
  }

  void _startWalk(BuildContext context) {
    _pip.reactToWalk();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WalkScreen()));
  }

  Future<void> _startWorkout(BuildContext context, WidgetRef ref) async {
    final templates = ref.read(moveRepoProvider).templates;
    if (templates.isEmpty && context.mounted) {
      final go = await askConfirm(
        context,
        title: 'No workouts yet',
        body:
            'Create your first workout from the exercise library, or start a quick freestyle session.',
        confirmLabel: 'Browse exercises',
      );
      if (go && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ExerciseLibraryScreen()),
        );
      }
      return;
    }
    final t = await showBubbleSheet<WorkoutTemplate>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Choose a workout',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: BloomSpacing.md),
          for (final template in templates)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BubbleCard(
                onTap: () => Navigator.of(context).pop(template),
                radius: BloomRadii.bubble,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '${template.blocks.length} exercises · ~${template.estMinutes} min',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (t != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WorkoutPlayerScreen(template: t)),
      );
    }
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final ok = await showBubbleSheet<bool>(
      context,
      const CheckInSheet(),
      scrollable: false,
    );
    if (ok == true) {
      await _afterLog(ref);
      _pip.play(PipAction.wave);
    }
  }

  /// Post-log bookkeeping: streak/accessory checks + celebration.
  Future<void> _afterLog(WidgetRef ref) async {
    final newly = await ref.read(motivationRepoProvider).recordActivity(
          food: ref.read(foodRepoProvider),
          move: ref.read(moveRepoProvider),
          wellness: ref.read(wellnessRepoProvider),
        );
    if (newly.isNotEmpty && mounted) {
      _pip.play(PipAction.celebrate);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pip unlocked: ${newly.join(', ')}')),
      );
    }
  }

  // ----------------------------------------------------- habit progress

  Widget _habitProgress(BuildContext context, WidgetRef ref, String key) {
    final profile = ref.read(profileRepoProvider).profile;
    final food = ref.read(foodRepoProvider);
    final move = ref.read(moveRepoProvider);
    final wellness = ref.read(wellnessRepoProvider);

    final habits = <(String, bool)>[
      ('Ate', food.entriesFor(key).isNotEmpty),
      ('Water', wellness.waterTotal(key) >= profile.waterGoalMl * 0.5),
      ('Steps', move.displaySteps(key).value >= profile.walkGoalSteps * 0.5),
      (
        'Moved',
        move.sessionsFor(key).isNotEmpty || move.walksFor(key).isNotEmpty,
      ),
      ('Mood', wellness.moodFor(key).isNotEmpty),
    ];
    final done = habits.where((h) => h.$2).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: BubbleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Today's habits",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '$done of ${habits.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: BloomSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in habits) _HabitPill(label: h.$1, done: h.$2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------ nutrition card

  Widget _nutritionCard(
    BuildContext context,
    UserProfile profile,
    Nutrition n,
  ) {
    final target = profile.targetKcal;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: BubbleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Nutrition',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (profile.targetsEstimated)
                  Text(
                    'Estimates',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            const SizedBox(height: BloomSpacing.sm),
            Row(
              children: [
                ProgressRing(
                  progress: target == null || target <= 0 ? 0 : n.kcal / target,
                  size: 84,
                  color: scheme.primary,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${n.kcal.round()}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'kcal',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: BloomSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (target != null)
                        Text(
                          'of ${target.round()} kcal target',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      MacroBar(protein: n.protein, carbs: n.carbs, fat: n.fat),
                    ],
                  ),
                ),
              ],
            ),
            if (n.isEstimate) ...[
              const SizedBox(height: 8),
              Text(
                'Based on approximate food data.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------- stats row

  Widget _statsRow(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
    List<String> widgets,
    ({int value, String source}) steps,
    double water,
    SleepLog? sleep,
  ) {
    final cards = <Widget>[];
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (widgets.contains('steps')) {
      cards.add(
        Expanded(
          child: StatBubble(
            icon: Icons.directions_walk,
            value: Fmt.intFmt(steps.value),
            label: 'steps · ${steps.source}',
            tint: dark ? BloomColors.mintD : BloomColors.mint,
            deep: dark ? const Color(0xFF7BD0A5) : BloomColors.mintDeep,
            progress: profile.walkGoalSteps <= 0
                ? 0
                : steps.value / profile.walkGoalSteps,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const WalkScreen())),
          ),
        ),
      );
    }
    if (widgets.contains('water')) {
      cards.add(
        Expanded(
          child: StatBubble(
            icon: Icons.water_drop,
            value: Units.volume(water, profile.units),
            label: 'of ${Units.volume(profile.waterGoalMl, profile.units)}',
            tint: dark ? BloomColors.skyD : BloomColors.sky,
            deep: dark ? const Color(0xFF7FB6DD) : BloomColors.skyDeep,
            progress:
                profile.waterGoalMl <= 0 ? 0 : water / profile.waterGoalMl,
            onTap: () => _addWater(context, ref),
          ),
        ),
      );
    }
    if (widgets.contains('sleep')) {
      final dur = sleep == null
          ? null
          : Dates.sleepDuration(sleep.bedtime, sleep.wakeTime, sleep.dateKey);
      cards.add(
        Expanded(
          child: StatBubble(
            icon: Icons.bedtime_outlined,
            value: dur == null ? '—' : Dates.formatDuration(dur),
            label: sleep == null
                ? 'not logged'
                : 'goal ${Dates.formatHm(profile.sleepGoalH)}',
            tint: dark ? BloomColors.lavenderD : BloomColors.lavender,
            deep: dark ? const Color(0xFFA99AEC) : BloomColors.lavenderDeep,
            progress: dur == null || profile.sleepGoalH <= 0
                ? 0
                : dur.inMinutes / 60 / profile.sleepGoalH,
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SleepScreen())),
          ),
        ),
      );
    }
    if (cards.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------- upcoming

  Widget _upcoming(
    BuildContext context,
    WidgetRef ref,
    String key,
    UserProfile profile,
  ) {
    final plan = ref.read(planRepoProvider);
    final move = ref.read(moveRepoProvider);
    final planned = plan.planFor(key);
    final hour = DateTime.now().hour;
    final nextMeal =
        planned.where((p) => _mealHour(p.meal) >= hour).firstOrNull;
    final weekday = DateTime.now().weekday.toString();
    final scheduled = move.templates
        .where((t) => t.scheduledWeekdays.contains(weekday))
        .firstOrNull;

    if (nextMeal == null && scheduled == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Coming up',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (nextMeal != null)
            BubbleCard(
              radius: BloomRadii.bubble,
              onTap: () => _confirmPlannedMeal(context, ref, key, nextMeal),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BloomColors.peachD
                          : BloomColors.peach,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: BloomColors.peachDeep,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nextMeal.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Planned ${nextMeal.meal} · tap when you eat it',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          if (scheduled != null) ...[
            const SizedBox(height: 10),
            BubbleCard(
              radius: BloomRadii.bubble,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkoutPlayerScreen(template: scheduled),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? BloomColors.lavenderD
                          : BloomColors.lavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: BloomColors.lavenderDeep,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scheduled.name,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          'Scheduled workout · ~${scheduled.estMinutes} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  int _mealHour(String meal) => switch (meal) {
        'breakfast' => 11,
        'lunch' => 15,
        'dinner' => 21,
        _ => 23,
      };

  /// Planned meals are never auto-counted: the user confirms when eaten.
  Future<void> _confirmPlannedMeal(
    BuildContext context,
    WidgetRef ref,
    String key,
    PlannedMeal pm,
  ) async {
    final ok = await askConfirm(
      context,
      title: 'Log this meal?',
      body:
          '"${pm.name}" was planned for ${pm.meal}. Logging it adds it to today\'s food diary.',
      confirmLabel: 'Log it',
    );
    if (!ok) return;
    final recipes = ref.read(recipeRepoProvider);
    if (pm.kind == 'recipe') {
      final r = recipes.byId(pm.refId);
      if (r == null) return;
      final n = recipes.perServing(r, catalogFoods);
      final entry = FoodEntry(
        id: newId(),
        dateKey: key,
        meal: pm.meal,
        name: '${r.name} (planned)',
        recipeId: r.id,
        servingQty: pm.servings,
        servingUnit: 'serving',
        grams: pm.servings * 250, // estimate; editable after
        nutrition: n.scaled(pm.servings),
      );
      await ref.read(foodRepoProvider).addEntry(entry);
    }
    await _afterLog(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planned meal logged. Enjoy!')),
      );
    }
  }

  // ----------------------------------------------------------- timeline

  Widget _timeline(
    BuildContext context,
    WidgetRef ref,
    String key,
    UserProfile profile,
  ) {
    final items = _buildTimeline(ref, key, profile);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BloomSpacing.md,
        BloomSpacing.md,
        BloomSpacing.md,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              "Today's timeline",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          BubbleCard(
            child: items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(BloomSpacing.sm),
                    child: Text(
                      'Nothing logged yet today. Pip is saving you a sunny spot on the timeline.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        items[i],
                        if (i < items.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline(WidgetRef ref, String key, UserProfile profile) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final food = ref.read(foodRepoProvider);
    final move = ref.read(moveRepoProvider);
    final wellness = ref.read(wellnessRepoProvider);
    final out = <(DateTime, Widget)>[];

    for (final e in food.entriesFor(key)) {
      out.add((
        e.loggedAt,
        TimelineTile(
          icon: Icons.restaurant,
          tint: dark ? BloomColors.peachD : BloomColors.peach,
          deep: BloomColors.peachDeep,
          title: e.name,
          subtitle:
              '${e.meal} · ${Fmt.kcal(e.nutrition.kcal)}${e.nutrition.isEstimate ? ' (est.)' : ''}',
          time: Dates.clock(e.loggedAt),
        ),
      ));
    }
    for (final w in wellness.waterFor(key)) {
      out.add((
        w.loggedAt,
        TimelineTile(
          icon: Icons.water_drop,
          tint: dark ? BloomColors.skyD : BloomColors.sky,
          deep: BloomColors.skyDeep,
          title: 'Water',
          subtitle: Units.volume(w.ml, profile.units),
          time: Dates.clock(w.loggedAt),
        ),
      ));
    }
    for (final s in move.sessionsFor(key)) {
      out.add((
        s.completedAt,
        TimelineTile(
          icon: Icons.fitness_center,
          tint: dark ? BloomColors.lavenderD : BloomColors.lavender,
          deep: BloomColors.lavenderDeep,
          title: s.name,
          subtitle:
              'Workout · ${Dates.formatDuration(Duration(seconds: s.durationSec))}',
          time: Dates.clock(s.completedAt),
        ),
      ));
    }
    for (final w in move.walksFor(key)) {
      out.add((
        w.startedAt,
        TimelineTile(
          icon: Icons.directions_walk,
          tint: dark ? BloomColors.mintD : BloomColors.mint,
          deep: BloomColors.mintDeep,
          title: w.indoor ? 'Indoor walk' : 'Walk',
          subtitle:
              '${Dates.formatDuration(Duration(seconds: w.durationSec))} · ${Units.distance(w.distanceM, profile.units)}',
          time: Dates.clock(w.startedAt),
        ),
      ));
    }
    for (final m in wellness.moodFor(key)) {
      out.add((
        m.loggedAt,
        TimelineTile(
          icon: Icons.mood,
          tint: dark ? BloomColors.roseD : BloomColors.rose,
          deep: BloomColors.roseDeep,
          title: 'Mood check-in',
          subtitle:
              '${'●' * m.mood}${'○' * (5 - m.mood)} · energy ${m.energy}/5',
          time: Dates.clock(m.loggedAt),
        ),
      ));
    }
    final sleep = wellness.sleepFor(key);
    if (sleep != null) {
      final dur = Dates.sleepDuration(
        sleep.bedtime,
        sleep.wakeTime,
        sleep.dateKey,
      );
      out.add((
        DateTime.now().subtract(const Duration(hours: 8)),
        TimelineTile(
          icon: Icons.bedtime,
          tint: dark ? BloomColors.lavenderD : BloomColors.lavender,
          deep: BloomColors.lavenderDeep,
          title: 'Sleep',
          subtitle: '${Dates.formatDuration(dur)} · quality ${sleep.quality}/5',
          time: '${sleep.bedtime}–${sleep.wakeTime}',
        ),
      ));
    }
    out.sort((a, b) => b.$1.compareTo(a.$1));
    return out.take(12).map((e) => e.$2).toList();
  }
}

// --------------------------------------------------------------- pieces

class _QA {
  final String label;
  final IconData icon;
  final bool isPrimary;
  _QA(this.label, this.icon, {this.isPrimary = false});
}

class _HabitPill extends StatelessWidget {
  final String label;
  final bool done;
  const _HabitPill({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: done
            ? BloomColors.mint.withOpacity(0.5)
            : Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(BloomRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: done ? BloomColors.mintDeep : scheme.outline,
          ),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Curved transition flowing smoothly beneath the 3D human visualizer.
class CurvedStageDivider extends StatelessWidget {
  final Color curveColor;
  final double height;
  const CurvedStageDivider({
    super.key,
    required this.curveColor,
    this.height = 38,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _CurvedStagePainter(color: curveColor)),
    );
  }
}

class _CurvedStagePainter extends CustomPainter {
  final Color color;
  _CurvedStagePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.5, 0, size.width, size.height * 0.42)
      ..lineTo(size.width, size.height)
      ..close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CurvedStagePainter oldDelegate) =>
      oldDelegate.color != color;
}
