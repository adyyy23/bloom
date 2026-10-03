import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';

/// Weight and body progress: dated entries, trends with explained smoothing,
/// optional measurements and private photos, unit conversion, export.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    if (!profile.showWeight) {
      return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BloomSpacing.lg),
            child: Column(
              children: [
                const EmptyState(
                  icon: Icons.visibility_off_outlined,
                  title: 'Weight features are hidden',
                  body:
                      'You chose to hide weight tracking. Your past entries are still stored privately.',
                ),
                const SizedBox(height: BloomSpacing.md),
                PillButton(
                  label: 'Show weight features',
                  secondary: true,
                  onPressed: () {
                    final p = ref.read(profileRepoProvider).profile;
                    p.showWeight = true;
                    ref.read(profileRepoProvider).save(p);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BloomSpacing.md,
                  vertical: BloomSpacing.sm),
              child: SegmentedPills<int>(
                values: const [0, 1, 2],
                labels: const ['Weight', 'Measurements', 'Photos'],
                selected: _seg,
                onChanged: (v) => setState(() => _seg = v),
              ),
            ),
            Expanded(
              child: switch (_seg) {
                0 => const _WeightPane(),
                1 => const _MeasuresPane(),
                _ => const _PhotosPane(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- weight

class _WeightPane extends ConsumerWidget {
  const _WeightPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(progressRepoProvider);
    final profile = ref.watch(profileRepoProvider).profile;
    final weights = repo.weights;
    final latest = repo.latest;
    final goalKg = profile.goalWeightKg;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        BubbleCard(
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
                        Text('Latest',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall),
                        Text(
                          latest == null
                              ? '—'
                              : Units.weight(
                                  latest.weightKg, profile.units),
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (latest != null)
                          Text(
                            Dates.pretty(Dates.parseKey(
                                latest.dateKey)),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      PillButton(
                        label: 'Log weight',
                        icon: Icons.add,
                        onPressed: () =>
                            _logWeight(context, ref, null),
                      ),
                      const SizedBox(height: 8),
                      // Instant kg / lb toggle
                      SegmentedPills<String>(
                        values: const ['metric', 'imperial'],
                        labels: const ['kg', 'lb'],
                        selected: profile.units,
                        onChanged: (u) {
                          profile.units = u;
                          ref.read(profileRepoProvider).save(profile);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (weights.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  children: [
                    Text(
                      'Started: ${Units.weight(weights.first.weightKg, profile.units)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (goalKg != null)
                      Text(
                        'Goal: ${Units.weight(goalKg, profile.units)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: BloomColors.mintDeep,
                            ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: BloomSpacing.md),
        if (weights.length >= 2)
          _weightChart(weights: weights, profile: profile)
        else
          const InfoNote(
            text:
                'Log a couple of entries to see your trend. Day-to-day fluctuations are completely normal — the trend looks at the bigger picture.',
          ),
        const SectionHeader(title: 'Entries'),
        if (weights.isEmpty)
          Text('No entries yet.',
              style: Theme.of(context).textTheme.bodySmall),
        for (final w in weights.reversed.take(30))
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
                            Units.weight(
                                w.weightKg, profile.units),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        Text(
                          '${Dates.pretty(Dates.parseKey(w.dateKey))}${w.note.isNotEmpty ? ' · ${w.note}' : ''}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 20),
                    onPressed: () =>
                        _logWeight(context, ref, w),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20),
                    onPressed: () async {
                      final ok = await askConfirm(context,
                          title: 'Delete entry?',
                          body:
                              'This weight entry will be removed.',
                          confirmLabel: 'Delete');
                      if (ok) {
                        await repo.deleteWeight(w.id);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _weightChart(
      {required List<WeightEntry> weights,
      required UserProfile profile}) {
    final isImp = profile.units == 'imperial';
    double toUnit(double kg) => isImp ? Units.kgToLb(kg) : kg;

    final smoothed =
        Calc.movingAverage(weights.map((w) => w.weightKg).toList(), 7);
    final rawSpots = [
      for (var i = 0; i < weights.length; i++)
        FlSpot(i.toDouble(), toUnit(weights[i].weightKg))
    ];
    final smoothSpots = [
      for (var i = 0; i < weights.length; i++)
        if (smoothed[i] != null)
          FlSpot(i.toDouble(), toUnit(smoothed[i]!))
    ];
    final all = weights.map((w) => toUnit(w.weightKg)).toList();
    final minY = all.reduce((a, b) => a < b ? a : b) - (isImp ? 2 : 1);
    final maxY = all.reduce((a, b) => a > b ? a : b) + (isImp ? 2 : 1);
    return Builder(builder: (context) {
      return BubbleCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Trend',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minY.clamp(0, 10000).toDouble(),
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  titlesData:
                      const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: smoothSpots,
                      isCurved: true,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: rawSpots,
                      isCurved: false,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                      barWidth: 1.5,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) => touched
                          .map((s) => LineTooltipItem(
                                '${s.y.toStringAsFixed(1)} ${Units.weightUnit(profile.units)}\n${Dates.pretty(Dates.parseKey(weights[s.x.toInt()].dateKey))}',
                                const TextStyle(fontSize: 12),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dots are your actual entries; the bold line is a 7-day trailing average to smooth normal daily fluctuation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    });
  }

  Future<void> _logWeight(
      BuildContext context, WidgetRef ref, WeightEntry? existing) async {
    final profile = ref.read(profileRepoProvider).profile;
    final unit = Units.weightUnit(profile.units);
    final initial = existing == null
        ? (ref.read(progressRepoProvider).latest == null
            ? null
            : double.parse(Units.weightShort(
                ref.read(progressRepoProvider).latest!.weightKg,
                profile.units)))
        : double.parse(
            Units.weightShort(existing.weightKg, profile.units));
    final v = await askNumber(context,
        title: existing == null ? 'Log weight' : 'Edit weight',
        unit: unit,
        initial: initial,
        min: 20,
        max: 500);
    if (v == null) return;
    final kg =
        profile.units == 'imperial' ? Units.lbToKg(v) : v;
    final repo = ref.read(progressRepoProvider);
    if (existing == null) {
      await repo.addWeight(WeightEntry(
          id: newId(), dateKey: Dates.todayKey(), weightKg: kg));
    } else {
      existing.weightKg = kg;
      await repo.updateWeight(existing);
    }
  }
}

// ----------------------------------------------------------- measurements

const _measureTypes = [
  ('waist', 'Waist'),
  ('hips', 'Hips'),
  ('chest', 'Chest'),
  ('arm', 'Arm'),
  ('thigh', 'Thigh'),
  ('neck', 'Neck'),
];

class _MeasuresPane extends ConsumerWidget {
  const _MeasuresPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(progressRepoProvider);
    final profile = ref.watch(profileRepoProvider).profile;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const InfoNote(
          text:
              'Optional body measurements. Measure the same way each time, and remember bodies fluctuate.',
        ),
        const SizedBox(height: 8),
        for (final t in _measureTypes)
          _measureCard(context, ref, repo, profile, t.$1, t.$2),
      ],
    );
  }

  Widget _measureCard(BuildContext context, WidgetRef ref,
      ProgressRepo repo, UserProfile profile, String type, String label) {
    final list =
        repo.measures.where((m) => m.type == type).toList();
    final latest = list.isEmpty ? null : list.last;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        radius: BloomRadii.bubble,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          Theme.of(context).textTheme.titleSmall),
                  Text(
                    latest == null
                        ? 'No entries'
                        : '${Units.length(latest.valueCm, profile.units)} · ${Dates.pretty(Dates.parseKey(latest.dateKey))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            PillButton(
              label: latest == null ? 'Add' : 'Log',
              secondary: true,
              onPressed: () =>
                  _logMeasure(context, ref, profile, type, label),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logMeasure(BuildContext context, WidgetRef ref,
      UserProfile profile, String type, String label) async {
    final unit =
        profile.units == 'imperial' ? 'in' : 'cm';
    final v = await askNumber(context,
        title: '$label measurement', unit: unit, min: 10, max: 300);
    if (v == null) return;
    final cm =
        profile.units == 'imperial' ? Units.inToCm(v) : v;
    await ref.read(progressRepoProvider).addMeasure(BodyMeasure(
        id: newId(),
        dateKey: Dates.todayKey(),
        type: type,
        valueCm: cm));
  }
}

// --------------------------------------------------------------- photos

class _PhotosPane extends ConsumerWidget {
  const _PhotosPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(progressRepoProvider);
    final photos = repo.photos;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 150),
      children: [
        const InfoNote(
          icon: Icons.lock_outline,
          text:
              'Progress photos are private and stored only on this device. They never leave Bloom unless you export them.',
        ),
        const SizedBox(height: 8),
        PillButton(
          label: 'Add photo',
          icon: Icons.camera_alt_outlined,
          expanded: true,
          onPressed: () => _addPhoto(context, ref),
        ),
        const SizedBox(height: BloomSpacing.md),
        if (photos.isEmpty)
          Text('No photos yet.',
              style: Theme.of(context).textTheme.bodySmall),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: photos.length,
          itemBuilder: (ctx, i) {
            final p = photos[i];
            return InkWell(
              onTap: () => _viewPhoto(context, ref, p),
              borderRadius:
                  BorderRadius.circular(BloomRadii.card),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(BloomRadii.card),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(p.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context)
                            .inputDecorationTheme
                            .fillColor,
                        child: const Icon(
                            Icons.broken_image_outlined),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        color: Colors.black.withOpacity(0.45),
                        child: Text(
                          Dates.pretty(
                              Dates.parseKey(p.dateKey)),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addPhoto(
      BuildContext context, WidgetRef ref) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      // Copy into app storage so the record survives gallery changes.
      final dir = await getApplicationDocumentsDirectory();
      final dest =
          '${dir.path}/progress_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(dest);
      await ref.read(progressRepoProvider).addPhoto(ProgressPhoto(
            id: newId(),
            dateKey: Dates.todayKey(),
            path: dest,
          ));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not add photo: $e')));
      }
    }
  }

  Future<void> _viewPhoto(
      BuildContext context, WidgetRef ref, ProgressPhoto p) async {
    final action = await showBubbleSheet<String>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius:
                BorderRadius.circular(BloomRadii.card),
            child: Image.file(
              File(p.path),
              height: 320,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined, size: 64),
            ),
          ),
          const SizedBox(height: 8),
          Text(Dates.long(Dates.parseKey(p.dateKey))),
          const SizedBox(height: BloomSpacing.md),
          PillButton(
            label: 'Delete photo',
            secondary: true,
            expanded: true,
            onPressed: () =>
                Navigator.of(context).pop('delete'),
          ),
        ],
      ),
    );
    if (action == 'delete' && context.mounted) {
      final ok = await askConfirm(context,
          title: 'Delete photo?',
          body: 'This private photo will be removed.',
          confirmLabel: 'Delete');
      if (ok) {
        try {
          await File(p.path).delete();
        } catch (_) {}
        await ref.read(progressRepoProvider).deletePhoto(p.id);
      }
    }
  }
}
