import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../core/utils.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'human_body_mesh.dart';
import 'human_visualizer.dart';

/// Appearance transactions never write to profile, weight or measurement logs.
class AppearanceSheet extends ConsumerStatefulWidget {
  const AppearanceSheet({super.key});
  @override
  ConsumerState<AppearanceSheet> createState() => _AppearanceSheetState();
}

class _AppearanceSheetState extends ConsumerState<AppearanceSheet> {
  late AvatarConfig draft;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    draft = ref.read(avatarRepoProvider).config;
  }

  Widget choices<T>(
    String title,
    List<T> values,
    T selected,
    ValueChanged<T> change,
  ) {
    String label(T v) {
      final name = (v as Enum).name.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      );
      return name[0].toUpperCase() + name.substring(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final v in values)
              ChoiceChip(
                label: Text(label(v)),
                selected: v == selected,
                onSelected: saving ? null : (_) => setState(() => change(v)),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileRepoProvider).profile;
    final progress = ref.watch(progressRepoProvider);
    final settings = ref.watch(settingsRepoProvider).settings;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Make it yours',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
        const Text(
          'Appearance only. Your measurements and records stay separate.',
        ),
        Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? BloomColors.heroPeachD
                : BloomColors.heroPeach,
            borderRadius: BorderRadius.circular(24),
          ),
          child: HumanVisualizer(
            stageHeight: 300,
            heightCm: p.heightCm ?? 170,
            weightKg: progress.latest?.weightKg ?? p.startWeightKg ?? 65,
            reducedMotion: settings.reducedMotion,
            config: draft.copyWith(
              waistCm: progress.latestMeasure('waist'),
              hipCm: progress.latestMeasure('hips'),
              chestCm: progress.latestMeasure('chest'),
            ),
          ),
        ),
        choices(
          'Face',
          FacePreset.values,
          draft.facePreset,
          (v) => draft = draft.copyWith(facePreset: v),
        ),
        choices(
          'Skin tone',
          SkinTone.values,
          draft.skinTone,
          (v) => draft = draft.copyWith(skinTone: v),
        ),
        choices(
          'Hair',
          HairStyle.values,
          draft.hairStyle,
          (v) => draft = draft.copyWith(hairStyle: v),
        ),
        choices(
          'Hair color',
          HairColor.values,
          draft.hairColor,
          (v) => draft = draft.copyWith(hairColor: v),
        ),
        choices(
          'Exercise clothing',
          ClothingStyle.values,
          draft.clothingStyle,
          (v) => draft = draft.copyWith(clothingStyle: v),
        ),
        choices(
          'Clothing color',
          ClothingColor.values,
          draft.clothingColor,
          (v) => draft = draft.copyWith(clothingColor: v),
        ),
        choices(
          'Illustrative frame',
          BodyFrame.values,
          draft.frame,
          (v) => draft = draft.copyWith(frame: v),
        ),
        choices(
          'Accessory',
          AvatarAccessory.values,
          draft.accessory,
          (v) => draft = draft.copyWith(accessory: v),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 8,
          children: [
            TextButton(
              onPressed: saving
                  ? null
                  : () => setState(() => draft = const AvatarConfig()),
              child: const Text('Reset appearance'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() => saving = true);
                      try {
                        await ref.read(avatarRepoProvider).save(draft);
                        if (mounted) Navigator.pop(context, true);
                      } catch (_) {
                        if (mounted) {
                          setState(() => saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not save appearance. Please retry.',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: Text(saving ? 'Saving…' : 'Save appearance'),
            ),
          ],
        ),
      ],
    );
  }
}

class EditMeasurementsSheet extends ConsumerStatefulWidget {
  const EditMeasurementsSheet({super.key});
  @override
  ConsumerState<EditMeasurementsSheet> createState() =>
      _EditMeasurementsSheetState();
}

class _EditMeasurementsSheetState extends ConsumerState<EditMeasurementsSheet> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  final original = <String, double?>{};
  bool saving = false;
  String? error;
  bool get imperial =>
      ref.read(profileRepoProvider).profile.units == 'imperial';
  @override
  void initState() {
    super.initState();
    final p = ref.read(profileRepoProvider).profile;
    final r = ref.read(progressRepoProvider);
    original.addAll({
      'weight': r.latest?.weightKg ?? p.startWeightKg,
      'height': p.heightCm,
      'waist': r.latestMeasure('waist'),
      'hips': r.latestMeasure('hips'),
      'chest': r.latestMeasure('chest'),
    });
    for (final k in original.keys) {
      final value = original[k];
      final display = value == null
          ? null
          : imperial
          ? (k == 'weight' ? Units.kgToLb(value) : Units.cmToIn(value))
          : value;
      fields[k] = TextEditingController(
        text: display?.toStringAsFixed(2) ?? '',
      );
    }
  }

  double? value(String k) {
    final n = double.tryParse(fields[k]!.text);
    if (n == null) return null;
    return imperial ? (k == 'weight' ? Units.lbToKg(n) : Units.inToCm(n)) : n;
  }

  @override
  void dispose() {
    for (final c in fields.values) c.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final repo = ref.read(progressRepoProvider);
      for (final k in fields.keys) {
        final n = value(k);
        if (n == null || ((n - (original[k] ?? 0)).abs() < .03)) continue;
        if (k == 'weight') {
          await repo.addWeight(
            WeightEntry(
              id: newId(),
              dateKey: Dates.todayKey(),
              weightKg: n,
              note: 'Measurement update',
            ),
          );
        } else if (k == 'height') {
          await ref.read(profileRepoProvider).update((p) {
            p.heightCm = n;
            return p;
          });
        } else {
          await repo.addMeasure(
            BodyMeasure(
              id: newId(),
              dateKey: Dates.todayKey(),
              type: k,
              valueCm: n,
            ),
          );
        }
        original[k] = n;
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(() {
          saving = false;
          error = 'Could not save all measurements. Retry to finish saving.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileRepoProvider).profile;
    final a = ref.watch(avatarRepoProvider).config;
    return Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your measurements',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const Text(
            'Save updates to your records. Optional circumferences refine the illustration; BMI cannot describe body composition.',
          ),
          HumanVisualizer(
            stageHeight: 270,
            heightCm: value('height') ?? p.heightCm ?? 170,
            weightKg: value('weight') ?? 65,
            reducedMotion: ref
                .watch(settingsRepoProvider)
                .settings
                .reducedMotion,
            config: a.copyWith(
              waistCm: value('waist'),
              hipCm: value('hips'),
              chestCm: value('chest'),
            ),
          ),
          for (final k in fields.keys)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextFormField(
                controller: fields[k],
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      '${k[0].toUpperCase()}${k.substring(1)} (${k == 'weight' ? (imperial ? 'lb' : 'kg') : (imperial ? 'in' : 'cm')})',
                  helperText: ['waist', 'hips', 'chest'].contains(k)
                      ? 'Optional • clear to leave the saved record unchanged'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (text) {
                  if ((text ?? '').trim().isEmpty)
                    return ['weight', 'height'].contains(k)
                        ? 'Enter a value'
                        : null;
                  final n = value(k);
                  if (n == null || !n.isFinite || n <= 0)
                    return 'Enter a positive number';
                  if (k == 'height' && (n < 80 || n > 250))
                    return 'Enter height from 80 to 250 cm (or equivalent)';
                  if (k == 'weight' && (n < 15 || n > 400))
                    return 'Enter weight from 15 to 400 kg (or equivalent)';
                  if (!['height', 'weight'].contains(k) && (n < 10 || n > 300))
                    return 'Enter a circumference from 10 to 300 cm';
                  return null;
                },
              ),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save measurements'),
          ),
        ],
      ),
    );
  }
}
