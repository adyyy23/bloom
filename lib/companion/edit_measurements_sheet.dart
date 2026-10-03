import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'human_body_mesh.dart';
import 'human_visualizer.dart';

/// Bubble-style bottom sheet for editing user body measurements and 3D avatar appearance.
class EditMeasurementsSheet extends ConsumerStatefulWidget {
  const EditMeasurementsSheet({super.key});

  @override
  ConsumerState<EditMeasurementsSheet> createState() =>
      _EditMeasurementsSheetState();
}

class _EditMeasurementsSheetState
    extends ConsumerState<EditMeasurementsSheet> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _waistCtrl;
  late final TextEditingController _hipCtrl;
  late final TextEditingController _chestCtrl;

  late BodyFrame _frame;
  late SkinTone _skinTone;
  late HairStyle _hairStyle;
  late HairColor _hairColor;
  late ClothingColor _clothingColor;
  late FacePreset _facePreset;
  late ClothingStyle _clothingStyle;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileRepoProvider).profile;
    final progress = ref.read(progressRepoProvider);
    final avatar = ref.read(avatarRepoProvider).config;

    final latestWeight = progress.latest?.weightKg ?? profile.startWeightKg ?? 65.0;
    final weightDisplay = profile.units == 'imperial'
        ? Units.kgToLb(latestWeight)
        : latestWeight;
    _weightCtrl = TextEditingController(text: weightDisplay.toStringAsFixed(1));

    final heightVal = profile.heightCm ?? 170.0;
    final heightDisplay = profile.units == 'imperial'
        ? Units.cmToIn(heightVal)
        : heightVal;
    _heightCtrl = TextEditingController(text: heightDisplay.toStringAsFixed(0));

    final waistVal = avatar.waistCm ?? progress.latestMeasure('waist');
    _waistCtrl = TextEditingController(
      text: waistVal != null
          ? (profile.units == 'imperial'
                  ? Units.cmToIn(waistVal)
                  : waistVal)
              .toStringAsFixed(1)
          : '',
    );

    final hipVal = avatar.hipCm ?? progress.latestMeasure('hips');
    _hipCtrl = TextEditingController(
      text: hipVal != null
          ? (profile.units == 'imperial' ? Units.cmToIn(hipVal) : hipVal)
              .toStringAsFixed(1)
          : '',
    );

    final chestVal = avatar.chestCm ?? progress.latestMeasure('chest');
    _chestCtrl = TextEditingController(
      text: chestVal != null
          ? (profile.units == 'imperial' ? Units.cmToIn(chestVal) : chestVal)
              .toStringAsFixed(1)
          : '',
    );

    _frame = avatar.frame;
    _skinTone = avatar.skinTone;
    _hairStyle = avatar.hairStyle;
    _hairColor = avatar.hairColor;
    _clothingColor = avatar.clothingColor;
    _facePreset = avatar.facePreset;
    _clothingStyle = avatar.clothingStyle;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _chestCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = ref.read(profileRepoProvider).profile;
    final isImperial = profile.units == 'imperial';

    // Parse weight
    final wVal = double.tryParse(_weightCtrl.text.trim());
    if (wVal != null && wVal > 0) {
      final wKg = isImperial ? Units.lbToKg(wVal) : wVal;
      await ref.read(progressRepoProvider).addWeight(
            WeightEntry(
              id: newId(),
              dateKey: Dates.todayKey(),
              weightKg: wKg,
              note: 'Updated from 3D Body Visualizer',
            ),
          );
    }

    // Parse height
    final hVal = double.tryParse(_heightCtrl.text.trim());
    if (hVal != null && hVal > 0) {
      final hCm = isImperial ? Units.inToCm(hVal) : hVal;
      await ref.read(profileRepoProvider).update((p) {
        p.heightCm = hCm;
        return p;
      });
    }

    // Parse optional circumference measurements
    final waistRaw = double.tryParse(_waistCtrl.text.trim());
    final waistCm = waistRaw != null && waistRaw > 0
        ? (isImperial ? Units.inToCm(waistRaw) : waistRaw)
        : null;
    if (waistCm != null) {
      await ref.read(progressRepoProvider).addMeasure(BodyMeasure(
            id: newId(),
            dateKey: Dates.todayKey(),
            type: 'waist',
            valueCm: waistCm,
          ));
    }

    final hipRaw = double.tryParse(_hipCtrl.text.trim());
    final hipCm = hipRaw != null && hipRaw > 0
        ? (isImperial ? Units.inToCm(hipRaw) : hipRaw)
        : null;
    if (hipCm != null) {
      await ref.read(progressRepoProvider).addMeasure(BodyMeasure(
            id: newId(),
            dateKey: Dates.todayKey(),
            type: 'hips',
            valueCm: hipCm,
          ));
    }

    final chestRaw = double.tryParse(_chestCtrl.text.trim());
    final chestCm = chestRaw != null && chestRaw > 0
        ? (isImperial ? Units.inToCm(chestRaw) : chestRaw)
        : null;
    if (chestCm != null) {
      await ref.read(progressRepoProvider).addMeasure(BodyMeasure(
            id: newId(),
            dateKey: Dates.todayKey(),
            type: 'chest',
            valueCm: chestCm,
          ));
    }

    // Save avatar configuration
    final newConfig = AvatarConfig(
      frame: _frame,
      skinTone: _skinTone,
      hairStyle: _hairStyle,
      hairColor: _hairColor,
      clothingColor: _clothingColor,
      facePreset: _facePreset,
      clothingStyle: _clothingStyle,
      waistCm: waistCm,
      hipCm: hipCm,
      chestCm: chestCm,
    );
    await ref.read(avatarRepoProvider).save(newConfig);

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurements and avatar updated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    final isImperial = profile.units == 'imperial';
    final weightUnit = isImperial ? 'lb' : 'kg';
    final lengthUnit = isImperial ? 'in' : 'cm';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          BloomSpacing.lg,
          BloomSpacing.sm,
          BloomSpacing.lg,
          BloomSpacing.xl,
        ),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Body & Avatar Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const InfoNote(
            icon: Icons.info_outline,
            text:
                'Approximate visualization — not a body scan. Values guide a bounded illustrative model and preserve your saved personal health records.',
          ),
          const SizedBox(height: BloomSpacing.md),

          // Live Mini 3D Visualizer Preview
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E24)
                  : BloomColors.heroPeach.withOpacity(0.50),
              borderRadius: BorderRadius.circular(BloomRadii.bubble),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white12
                    : BloomColors.line,
                width: 0.8,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                HumanVisualizer(
                  heightCm: double.tryParse(_heightCtrl.text) ?? 170.0,
                  weightKg: double.tryParse(_weightCtrl.text) ?? 65.0,
                  stageHeight: 190,
                  config: AvatarConfig(
                    frame: _frame,
                    skinTone: _skinTone,
                    hairStyle: _hairStyle,
                    hairColor: _hairColor,
                    clothingColor: _clothingColor,
                    facePreset: _facePreset,
                    clothingStyle: _clothingStyle,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white)
                          .withOpacity(0.70),
                      borderRadius: BorderRadius.circular(BloomRadii.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 12,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white70
                              : BloomColors.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Avatar Preview',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : BloomColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BloomSpacing.md),

          // Primary Metrics (Weight & Height)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Current Weight ($weightUnit)',
                    hintText: 'e.g. ${isImperial ? "145" : "65"}',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: BloomSpacing.md),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Height ($lengthUnit)',
                    hintText: 'e.g. ${isImperial ? "67" : "170"}',
                    prefixIcon: const Icon(Icons.height_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),

          // Optional circumferences
          Text(
            'Refining Measurements (Optional)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _waistCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Waist ($lengthUnit)',
                    hintText: 'Optional',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _hipCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Hips ($lengthUnit)',
                    hintText: 'Optional',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _chestCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Chest ($lengthUnit)',
                    hintText: 'Optional',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.lg),

          // Body Frame Selection
          Text(
            'Body Frame Width',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<BodyFrame>(
            segments: const [
              ButtonSegment(
                value: BodyFrame.narrow,
                label: Text('Narrow'),
                icon: Icon(Icons.view_column_outlined, size: 16),
              ),
              ButtonSegment(
                value: BodyFrame.medium,
                label: Text('Medium'),
                icon: Icon(Icons.grid_view_rounded, size: 16),
              ),
              ButtonSegment(
                value: BodyFrame.broad,
                label: Text('Broad'),
                icon: Icon(Icons.table_rows_outlined, size: 16),
              ),
            ],
            selected: {_frame},
            onSelectionChanged: (set) => setState(() => _frame = set.first),
          ),
          const SizedBox(height: BloomSpacing.lg),

          // Facial Profile Presets
          Text(
            'Facial Profile',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in FacePreset.values)
                ChoiceChip(
                  label: Text(_formatEnum(preset.name)),
                  selected: _facePreset == preset,
                  onSelected: (val) {
                    if (val) setState(() => _facePreset = preset);
                  },
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.lg),

          // Skin Tone Swatches
          Text(
            'Skin Tone',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final tone in SkinTone.values)
                GestureDetector(
                  onTap: () => setState(() => _skinTone = tone),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _skinToneColor(tone),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _skinTone == tone
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black12,
                        width: _skinTone == tone ? 3.0 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _skinTone == tone
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.lg),

          // Hairstyle Selection
          Text(
            'Hairstyle',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in HairStyle.values)
                ChoiceChip(
                  label: Text(_formatEnum(style.name)),
                  selected: _hairStyle == style,
                  onSelected: (val) {
                    if (val) setState(() => _hairStyle = style);
                  },
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),

          // Hair Color Swatches
          Text(
            'Hair Color',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final col in HairColor.values)
                GestureDetector(
                  onTap: () => setState(() => _hairColor = col),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _hairColorColor(col),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _hairColor == col
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black12,
                        width: _hairColor == col ? 3.0 : 1.0,
                      ),
                    ),
                    child: _hairColor == col
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.lg),

          // Clothing Style Selection
          Text(
            'Clothing Style',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in ClothingStyle.values)
                ChoiceChip(
                  label: Text(_formatEnum(style.name)),
                  selected: _clothingStyle == style,
                  onSelected: (val) {
                    if (val) setState(() => _clothingStyle = style);
                  },
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),

          // Sportswear Color Swatches
          Text(
            'Athletic Wear Color',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final col in ClothingColor.values)
                GestureDetector(
                  onTap: () => setState(() => _clothingColor = col),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _clothingColorColor(col),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _clothingColor == col
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black12,
                        width: _clothingColor == col ? 3.0 : 1.0,
                      ),
                    ),
                    child: _clothingColor == col
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: BloomSpacing.xl),

          // Dual Action Buttons: Cancel and Save & Update
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(BloomRadii.pill),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: BloomSpacing.md),
              Expanded(
                flex: 2,
                child: PillButton(
                  label: 'Save & Update',
                  icon: Icons.check_circle_outline_rounded,
                  expanded: true,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _skinToneColor(SkinTone tone) => switch (tone) {
        SkinTone.fair => const Color(0xFFFBE3D5),
        SkinTone.warmSand => const Color(0xFFF2D1B3),
        SkinTone.honey => const Color(0xFFE2B28B),
        SkinTone.goldenAmber => const Color(0xFFC78B5E),
        SkinTone.deepBronze => const Color(0xFF945F3B),
        SkinTone.richEspresso => const Color(0xFF5A3926),
      };

  Color _hairColorColor(HairColor color) => switch (color) {
        HairColor.espresso => const Color(0xFF35261E),
        HairColor.chestnut => const Color(0xFF5D3A29),
        HairColor.blonde => const Color(0xFFD4B478),
        HairColor.silver => const Color(0xFFB5BAC0),
        HairColor.raven => const Color(0xFF18181A),
      };

  Color _clothingColorColor(ClothingColor color) => switch (color) {
        ClothingColor.sage => const Color(0xFF6FAF8E),
        ClothingColor.lavender => const Color(0xFF9B8AC4),
        ClothingColor.ocean => const Color(0xFF5A94C7),
        ClothingColor.coral => const Color(0xFFE57B6C),
        ClothingColor.slate => const Color(0xFF4A5568),
      };

  String _formatEnum(String name) {
    // converts camelCase to Title Case
    final reg = RegExp(r'(?<=[a-z])[A-Z]');
    final split = name.replaceAllMapped(reg, (m) => ' ${m.group(0)}');
    return split[0].toUpperCase() + split.substring(1);
  }
}
