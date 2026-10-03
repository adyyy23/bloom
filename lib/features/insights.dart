import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/export.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';

/// Insights: real calculations from saved records with week/month filters,
/// sufficient-data empty states, and CSV/PDF export.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _days = 7;

  List<String> get _keys => Dates.lastNDays(_days)
      .map((d) => Dates.key(d))
      .toList();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    final food = ref.watch(foodRepoProvider);
    final move = ref.watch(moveRepoProvider);
    final wellness = ref.watch(wellnessRepoProvider);
    final progress = ref.watch(progressRepoProvider);
    final keys = _keys;

    final kcal = keys.map((k) => food.dayNutrition(k).kcal).toList();
    final hasNutrition = kcal.any((v) => v > 0);
    final steps = keys.map((k) => move.displaySteps(k).value.toDouble()).toList();
    final hasSteps = steps.any((v) => v > 0);
    final water = keys.map((k) => wellness.waterTotal(k)).toList();
    final hasWater = water.any((v) => v > 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 40),
          children: [
            SegmentedPills<int>(
              values: const [7, 30],
              labels: const ['Week', 'Month'],
              selected: _days,
              onChanged: (v) => setState(() => _days = v),
            ),
            const SizedBox(height: BloomSpacing.sm),
            if (profile.showCalories) ...[
              const SectionHeader(title: 'Calories'),
              hasNutrition
                  ? _BarCard(
                      values: kcal,
                      keys: keys,
                      color: Theme.of(context).colorScheme.primary,
                      unit: 'kcal',
                      avgLabel:
                          'Average: ${(kcal.reduce((a, b) => a + b) / kcal.length).round()} kcal/day',
                    )
                  : const _EmptyChart(
                      text:
                          'Log some meals to see your calorie trend.'),
            ],
            const SectionHeader(title: 'Steps'),
            hasSteps
                ? _BarCard(
                    values: steps,
                    keys: keys,
                    color: BloomColors.mintDeep,
                    unit: 'steps',
                    avgLabel:
                        'Average: ${Fmt.intFmt((steps.reduce((a, b) => a + b) / steps.length).round())} steps/day',
                  )
                : const _EmptyChart(
                    text: 'Log steps or walks to see your movement trend.'),
            const SectionHeader(title: 'Macros (avg/day)'),
            _macroAverages(context, food, keys),
            if (profile.showWeight) ...[
              const SectionHeader(title: 'Weight trend'),
              _weightChart(context, progress, profile),
            ],
            const SectionHeader(title: 'Workouts & walks'),
            _activitySummary(context, move, keys),
            const SectionHeader(title: 'Sleep & hydration'),
            _sleepHydration(context, wellness, profile, keys, hasWater),
            const SectionHeader(title: 'Mood'),
            _moodSummary(context, wellness),
            const SectionHeader(
              title: 'Export',
              subtitle: 'Your data, in your hands',
            ),
            _exportButtons(context, ref),
            const SizedBox(height: BloomSpacing.md),
            const InfoNote(
              text:
                  'Trends are computed from your saved records. When two things move together, that does not prove one caused the other.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroAverages(
      BuildContext context, FoodRepo food, List<String> keys) {
    double p = 0, c = 0, f = 0, days = 0;
    for (final k in keys) {
      final n = food.dayNutrition(k);
      if (n.kcal <= 0) continue;
      p += n.protein;
      c += n.carbs;
      f += n.fat;
      days++;
    }
    if (days == 0) {
      return const _EmptyChart(
          text: 'Log meals to see macro averages.');
    }
    return BubbleCard(
      child: MacroBar(
          protein: p / days, carbs: c / days, fat: f / days),
    );
  }

  Widget _weightChart(BuildContext context, ProgressRepo progress,
      UserProfile profile) {
    final weights = progress.weights;
    if (weights.length < 2) {
      return const _EmptyChart(
          text:
              'Log at least two weights to see a trend. Fluctuations are normal — the line uses a gentle 7-day smoothing.');
    }
    final smoothed = progress.trendSmoothed();
    final spots = <FlSpot>[];
    for (var i = 0; i < weights.length; i++) {
      final v = smoothed[i];
      if (v != null) spots.add(FlSpot(i.toDouble(), v));
    }
    final all = weights.map((w) => w.weightKg).toList();
    final min =
        (all.reduce((a, b) => a < b ? a : b) - 1).clamp(0, 1000).toDouble();
    final max = all.reduce((a, b) => a > b ? a : b) + 1;
    final change = all.last - all.first;
    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            child: LineChart(
              LineChartData(
                minY: min,
                maxY: max,
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color:
                        Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'From ${Units.weight(all.first, profile.units)} to ${Units.weight(all.last, profile.units)} '
            '(${change >= 0 ? '+' : ''}${Units.weightShort(change.abs(), profile.units)} ${Units.weightUnit(profile.units)}${change >= 0 ? '' : ' less'} overall). '
            'Smoothed with a 7-day trailing average of your actual entries.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _activitySummary(
      BuildContext context, MoveRepo move, List<String> keys) {
    var sessions = 0, walks = 0, minutes = 0;
    for (final k in keys) {
      sessions += move.sessionsFor(k).length;
      final ws = move.walksFor(k);
      walks += ws.length;
      minutes += ws.fold(0, (a, w) => a + w.durationSec) ~/ 60;
      minutes +=
          move.sessionsFor(k).fold(0, (a, s) => a + s.durationSec) ~/ 60;
    }
    final total = sessions + walks;
    if (total == 0) {
      return const _EmptyChart(
          text: 'Finish a workout or walk to see activity here.');
    }
    return BubbleCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(context, '$sessions', 'workouts'),
          _stat(context, '$walks', 'walks'),
          _stat(context, '$minutes', 'active min'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _sleepHydration(
      BuildContext context,
      WellnessRepo wellness,
      UserProfile profile,
      List<String> keys,
      bool hasWater) {
    final avgSleep = wellness.avgSleepHours(keys);
    final avgWater = hasWater
        ? waterAvg(wellness, keys)
        : 0.0;
    return BubbleCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.bedtime_outlined,
                  color: BloomColors.lavenderDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  avgSleep > 0
                      ? 'Avg sleep: ${Dates.formatHm(avgSleep)} (goal ${Dates.formatHm(profile.sleepGoalH)})'
                      : 'No sleep logged in this period.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.water_drop_outlined,
                  color: BloomColors.skyDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasWater
                      ? 'Avg water: ${Units.volume(avgWater, profile.units)}/day'
                      : 'No water logged in this period.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double waterAvg(WellnessRepo wellness, List<String> keys) {
    var total = 0.0;
    var days = 0;
    for (final k in keys) {
      final v = wellness.waterTotal(k);
      if (v > 0) {
        total += v;
        days++;
      }
    }
    return days == 0 ? 0 : total / days;
  }

  Widget _moodSummary(
      BuildContext context, WellnessRepo wellness) {
    final history = wellness.moodHistory.take(30).toList();
    if (history.isEmpty) {
      return const _EmptyChart(
          text: 'Mood check-ins will chart here.');
    }
    final avgMood =
        history.map((m) => m.mood).reduce((a, b) => a + b) /
            history.length;
    final avgEnergy =
        history.map((m) => m.energy).reduce((a, b) => a + b) /
            history.length;
    final tagCounts = <String, int>{};
    for (final m in history) {
      for (final t in m.tags) {
        tagCounts[t] = (tagCounts[t] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Average mood ${avgMood.toStringAsFixed(1)}/5 · energy ${avgEnergy.toStringAsFixed(1)}/5 across ${history.length} check-ins.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (topTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                for (final t in topTags.take(6))
                  Chip(label: Text('${t.key} ×${t.value}')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _exportButtons(BuildContext context, WidgetRef ref) {
    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PillButton(
            label: 'Export food log (CSV)',
            icon: Icons.download_outlined,
            secondary: true,
            expanded: true,
            onPressed: () => _exportFoodCsv(context, ref),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Export weights (CSV)',
            icon: Icons.download_outlined,
            secondary: true,
            expanded: true,
            onPressed: () => _exportWeightCsv(context, ref),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Export workouts (CSV)',
            icon: Icons.download_outlined,
            secondary: true,
            expanded: true,
            onPressed: () => _exportWorkoutCsv(context, ref),
          ),
          const SizedBox(height: 8),
          PillButton(
            label: 'Summary report (PDF)',
            icon: Icons.picture_as_pdf_outlined,
            expanded: true,
            onPressed: () => _exportPdf(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCsv(
      BuildContext context, String filename, List<String> headers, List<List<String>> rows) async {
    try {
      final path =
          await ExportService.writeCsv(filename, headers, rows);
      await ExportService.shareFile(path, subject: 'Bloom export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _exportFoodCsv(BuildContext context, WidgetRef ref) async {
    final entries = ref.read(foodRepoProvider).entries;
    await _shareCsv(
      context,
      'bloom-food.csv',
      ['date', 'meal', 'food', 'serving', 'grams', 'kcal', 'protein_g', 'carbs_g', 'fat_g', 'fiber_g', 'source', 'estimate'],
      [
        for (final e in entries)
          [
            e.dateKey, e.meal, e.name,
            '${Fmt.num(e.servingQty, 1)} ${e.servingUnit}',
            e.grams.toStringAsFixed(0),
            e.nutrition.kcal.toStringAsFixed(0),
            e.nutrition.protein.toStringAsFixed(1),
            e.nutrition.carbs.toStringAsFixed(1),
            e.nutrition.fat.toStringAsFixed(1),
            e.nutrition.fiber.toStringAsFixed(1),
            e.nutrition.source,
            e.nutrition.isEstimate ? 'yes' : 'no',
          ],
      ],
    );
  }

  Future<void> _exportWeightCsv(BuildContext context, WidgetRef ref) async {
    final weights = ref.read(progressRepoProvider).weights;
    await _shareCsv(
      context,
      'bloom-weight.csv',
      ['date', 'weight_kg', 'note'],
      [
        for (final w in weights)
          [w.dateKey, w.weightKg.toStringAsFixed(2), w.note],
      ],
    );
  }

  Future<void> _exportWorkoutCsv(BuildContext context, WidgetRef ref) async {
    final sessions = ref.read(moveRepoProvider).sessions;
    await _shareCsv(
      context,
      'bloom-workouts.csv',
      ['date', 'name', 'duration_min', 'sets_done', 'kcal_estimate'],
      [
        for (final s in sessions)
          [
            s.dateKey,
            s.name,
            (s.durationSec / 60).toStringAsFixed(1),
            '${s.blocks.fold(0, (a, b) => a + b.sets.length)}',
            s.kcalEstimate?.toStringAsFixed(0) ?? '',
          ],
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileRepoProvider).profile;
    final food = ref.read(foodRepoProvider);
    final move = ref.read(moveRepoProvider);
    final wellness = ref.read(wellnessRepoProvider);
    final progress = ref.read(progressRepoProvider);
    final keys = _keys;
    final facts = <(String, String)>[
      ('Period', '${Dates.pretty(Dates.parseKey(keys.first))} – ${Dates.pretty(Dates.parseKey(keys.last))}'),
      (
        'Nutrition',
        () {
          final ks = keys.where((k) => food.dayNutrition(k).kcal > 0).toList();
          if (ks.isEmpty) return 'No meals logged.';
          final avg = ks.map((k) => food.dayNutrition(k).kcal).reduce((a, b) => a + b) / ks.length;
          return 'Average ${avg.round()} kcal/day across ${ks.length} logged days.';
        }(),
      ),
      (
        'Steps',
        () {
          final total = move.weekSteps(keys);
          return '${Fmt.intFmt(total)} total steps in period.';
        }(),
      ),
      (
        'Activity',
        () {
          var n = 0;
          for (final k in keys) {
            n += move.sessionsFor(k).length + move.walksFor(k).length;
          }
          return '$n workouts/walks logged.';
        }(),
      ),
      (
        'Sleep',
        () {
          final avg = wellness.avgSleepHours(keys);
          return avg > 0 ? 'Average ${Dates.formatHm(avg)} per night.' : 'No sleep logged.';
        }(),
      ),
      (
        'Weight',
        () {
          if (!profile.showWeight || progress.weights.length < 2) {
            return 'Not enough data.';
          }
          final all = progress.weights.map((w) => w.weightKg).toList();
          return 'From ${Units.weight(all.first, profile.units)} to ${Units.weight(all.last, profile.units)}.';
        }(),
      ),
    ];
    try {
      final path = await ExportService.buildSummaryPdf(
        title: 'Bloom summary',
        facts: facts,
        generatedNote:
            'Generated ${Dates.long(DateTime.now())} from records on this device.',
      );
      await ExportService.shareFile(path, subject: 'Bloom summary');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF export failed: $e')));
      }
    }
  }
}

class _BarCard extends StatelessWidget {
  final List<double> values;
  final List<String> keys;
  final Color color;
  final String unit;
  final String avgLabel;
  const _BarCard({
    required this.values,
    required this.keys,
    required this.color,
    required this.unit,
    required this.avgLabel,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = values.reduce((a, b) => a > b ? a : b);
    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                maxY: maxV * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= keys.length) {
                          return const SizedBox.shrink();
                        }
                        // label every nth to avoid crowding
                        final step =
                            (keys.length / 7).ceil().clamp(1, 7);
                        if (i % step != 0 && i != keys.length - 1) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding:
                              const EdgeInsets.only(top: 4),
                          child: Text(
                            '${Dates.parseKey(keys[i]).day}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < values.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: values[i],
                          color: color.withOpacity(0.85),
                          width: values.length > 14 ? 6 : 12,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(avgLabel,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart({required this.text});

  @override
  Widget build(BuildContext context) {
    return BubbleCard(
      child: Padding(
        padding: const EdgeInsets.all(BloomSpacing.sm),
        child: Text(text,
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
