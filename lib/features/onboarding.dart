import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../companion/pip.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/models.dart';
import '../data/repositories.dart';

/// Multi-step onboarding. Collects only what's relevant and explains that
/// nutrition targets are estimates. Users can edit or hide weight/calorie
/// features later in Profile.
class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = PageController();
  int _step = 0;
  final _pip = PipController();

  // draft
  String _name = '';
  String _units = 'metric';
  String _goal = 'habits';
  String _birthYear = '';
  bool _isFemale = true;
  bool _pregnancy = false;
  bool _specialized = false;
  String _height = '';
  String _weight = '';
  String _goalWeight = '';
  String _activity = 'moderate';
  String _experience = 'beginner';
  final _equipment = <String>{};
  final _dietary = <String>{};
  final _allergies = <String>{};
  String _avoidFoods = '';
  String _steps = '8000';
  String _water = '2000';
  String _sleep = '8';
  // targets
  String _kcal = '', _protein = '', _carbs = '', _fat = '', _fiber = '';
  bool _targetsTouched = false;

  static const _totalSteps = 8;

  @override
  void dispose() {
    _page.dispose();
    _pip.dispose();
    super.dispose();
  }

  UserProfile get _draft {
    final p = UserProfile(
      name: _name.trim(),
      units: _units,
      goal: _goal,
      birthYear: int.tryParse(_birthYear),
      isFemale: _isFemale,
      pregnancyOrNursing: _pregnancy,
      specializedGuidance: _specialized,
      heightCm: _toCm(double.tryParse(_height)),
      startWeightKg: _toKg(double.tryParse(_weight)),
      goalWeightKg: _toKg(double.tryParse(_goalWeight)),
      activityLevel: _activity,
      experience: _experience,
      equipment: _equipment.toList(),
      dietary: _dietary.toList(),
      allergies: _allergies.toList(),
      avoidFoods: _avoidFoods.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      walkGoalSteps: int.tryParse(_steps) ?? 8000,
      waterGoalMl: _waterGoalMl(),
      sleepGoalH: double.tryParse(_sleep) ?? 8,
    );
    return p;
  }

  double _waterGoalMl() {
    final v = double.tryParse(_water) ?? 0;
    if (v <= 0) return 2000;
    return _units == 'imperial' ? v * 8 * Units.mlPerFloz : v * 1000;
  }

  double? _toKg(double? v) {
    if (v == null) return null;
    return _units == 'imperial' ? Units.lbToKg(v) : v;
  }

  double? _toCm(double? v) {
    if (v == null) return null;
    return _units == 'imperial' ? Units.inToCm(v) : v;
  }

  bool get _allowEstimate => _draft.allowEstimatedTargets;

  void _maybeEstimate() {
    if (_targetsTouched || !_allowEstimate) return;
    final d = _draft;
    if (d.startWeightKg == null || d.heightCm == null || d.ageYears == null) return;
    final kcal = Calc.mifflinKcal(
      weightKg: d.startWeightKg!,
      heightCm: d.heightCm!,
      ageYears: d.ageYears!,
      isFemale: d.isFemale,
      activityLevel: d.activityLevel,
      goal: d.goal,
      allowEstimate: true,
    );
    if (kcal == null) return;
    final macros = Calc.macroTargets(kcal, d.startWeightKg!, d.goal);
    setState(() {
      _kcal = kcal.round().toString();
      _protein = macros['protein']!.round().toString();
      _carbs = macros['carbs']!.round().toString();
      _fat = macros['fat']!.round().toString();
      _fiber = macros['fiber']!.round().toString();
    });
  }

  void _next() {
    if (_step >= _totalSteps - 1) {
      _finish();
      return;
    }
    if (_step == 5) _maybeEstimate();
    _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _back() {
    if (_step > 0) {
      _page.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _finish() async {
    final d = _draft;
    if (_allowEstimate && _kcal.isNotEmpty) {
      d.targetKcal = double.tryParse(_kcal);
      d.targetProtein = double.tryParse(_protein);
      d.targetCarbs = double.tryParse(_carbs);
      d.targetFat = double.tryParse(_fat);
      d.targetFiber = double.tryParse(_fiber);
      d.targetsEstimated = true;
    }
    await ref.read(profileRepoProvider).save(d);
    final settings = ref.read(settingsRepoProvider).settings;
    settings.onboardingDone = true;
    await ref.read(settingsRepoProvider).save(settings);
    // Log a starting weight entry if provided.
    if (d.startWeightKg != null) {
      await ref.read(progressRepoProvider).addWeight(WeightEntry(
            id: newId(),
            dateKey: Dates.todayKey(),
            weightKg: d.startWeightKg!,
            note: 'Starting weight',
          ));
    }
    if (mounted) {
      _pip.play(PipAction.celebrate);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsRepoProvider).settings;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressDots(step: _step, total: _totalSteps),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _welcomeStep(settings),
                  _basicsStep(),
                  _goalStep(),
                  _bodyStep(),
                  _trainingStep(),
                  _foodPrefsStep(),
                  _rhythmStep(),
                  _targetsStep(),
                ],
              ),
            ),
            _NavBar(
              step: _step,
              total: _totalSteps,
              onBack: _back,
              onNext: _next,
              canNext: _canNext(),
            ),
          ],
        ),
      ),
    );
  }

  bool _canNext() {
    switch (_step) {
      case 3:
        // body step: height/weight optional but validated if entered
        if (_height.isNotEmpty && double.tryParse(_height) == null) return false;
        if (_weight.isNotEmpty && double.tryParse(_weight) == null) return false;
        return true;
      default:
        return true;
    }
  }

  // ------------------------------------------------------------- steps

  Widget _welcomeStep(AppSettings settings) => _StepShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PipCompanion(
                size: 170, controller: _pip, reducedMotion: settings.reducedMotion),
            const SizedBox(height: BloomSpacing.lg),
            Text('Meet Pip, your wellness buddy',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: BloomSpacing.sm),
            Text(
              'Bloom helps you eat well, move more, rest deeply, and build habits that stick — at your own pace, with zero judgment.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: BloomSpacing.md),
            const InfoNote(
              text: 'Pip is a hand-drawn 2D animated character. Your data stays on this device.',
              icon: Icons.privacy_tip_outlined,
            ),
          ],
        ),
      );

  Widget _basicsStep() => _StepShell(
        title: 'First, the basics',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What should Pip call you?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BloomSpacing.sm),
            TextField(
              decoration: const InputDecoration(hintText: 'Your name (optional)'),
              onChanged: (v) => setState(() => _name = v),
            ),
            const SizedBox(height: BloomSpacing.lg),
            Text('Preferred units', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: BloomSpacing.sm),
            SegmentedPills<String>(
              values: const ['metric', 'imperial'],
              labels: const ['Metric (kg, cm)', 'Imperial (lb, in)'],
              selected: _units,
              onChanged: (v) => setState(() => _units = v),
            ),
          ],
        ),
      );

  Widget _goalStep() {
    final goals = [
      ('lose', 'Lose weight', 'Gentle, sustainable changes', Icons.trending_down),
      ('gain', 'Gain weight', 'Build up steadily and healthily', Icons.trending_up),
      ('maintain', 'Maintain', 'Stay where you feel your best', Icons.balance),
      ('fitness', 'Strength & fitness', 'Get stronger and more capable', Icons.fitness_center),
      ('habits', 'Everyday habits', 'No calorie or weight tracking', Icons.spa),
    ];
    return _StepShell(
      title: 'What are you working toward?',
      child: Column(
        children: [
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _GoalCard(
                selected: _goal == g.$1,
                icon: g.$4,
                title: g.$2,
                subtitle: g.$3,
                onTap: () => setState(() => _goal = g.$1),
              ),
            ),
          const SizedBox(height: 4),
          const InfoNote(
              text: 'You can change your goal or hide weight and calorie features anytime in Profile.'),
        ],
      ),
    );
  }

  Widget _bodyStep() {
    final wUnit = _units == 'imperial' ? 'lb' : 'kg';
    final hUnit = _units == 'imperial' ? 'in' : 'cm';
    return _StepShell(
      title: 'About your body',
      subtitle: 'Only used to personalize estimates. Everything is optional.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _NumField(
                    label: 'Height ($hUnit)',
                    value: _height,
                    onChanged: (v) => setState(() => _height = v)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NumField(
                    label: 'Weight ($wUnit)',
                    value: _weight,
                    onChanged: (v) => setState(() => _weight = v)),
              ),
            ],
          ),
          if (_goal == 'lose' || _goal == 'gain') ...[
            const SizedBox(height: 12),
            _NumField(
                label: 'Goal weight ($wUnit, optional)',
                value: _goalWeight,
                onChanged: (v) => setState(() => _goalWeight = v)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NumField(
                    label: 'Birth year (optional)',
                    value: _birthYear,
                    onChanged: (v) => setState(() => _birthYear = v)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sex (for estimates)',
                        style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    SegmentedPills<bool>(
                      values: const [true, false],
                      labels: const ['Female', 'Male'],
                      selected: _isFemale,
                      onChanged: (v) => setState(() => _isFemale = v),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: BloomSpacing.md),
          Text('Activity level', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ChoiceChips(
            options: const ['low', 'moderate', 'active', 'very'],
            labels: const ['Mostly sitting', 'Lightly active', 'Active', 'Very active'],
            selected: {_activity},
            onToggle: (v) => setState(() => _activity = v),
          ),
          const SizedBox(height: BloomSpacing.md),
          SwitchListTile(
            value: _pregnancy,
            onChanged: (v) => setState(() => _pregnancy = v),
            title: const Text('I am pregnant or nursing'),
            subtitle: const Text('We will skip automatic calorie targets for you.'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BloomRadii.bubble)),
          ),
          SwitchListTile(
            value: _specialized,
            onChanged: (v) => setState(() => _specialized = v),
            title: const Text('I need specialized nutrition guidance'),
            subtitle: const Text(
                'For medical conditions, eating disorder recovery, or being under 18 — we will not auto-generate targets.'),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BloomRadii.bubble)),
          ),
        ],
      ),
    );
  }

  Widget _trainingStep() => _StepShell(
        title: 'Movement background',
        subtitle: 'Helps Pip suggest the right starting point.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Exercise experience',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ChoiceChips(
              options: const ['beginner', 'intermediate', 'advanced'],
              labels: const ['New to it', 'Some experience', 'Experienced'],
              selected: {_experience},
              onToggle: (v) => setState(() => _experience = v),
            ),
            const SizedBox(height: BloomSpacing.md),
            Text('Equipment you have',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ChoiceChips(
              options: const [
                'bodyweight',
                'dumbbell',
                'resistance band',
                'kettlebell',
                'bench',
                'pull-up bar'
              ],
              selected: _equipment,
              onToggle: (v) => setState(() {
                _equipment.contains(v)
                    ? _equipment.remove(v)
                    : _equipment.add(v);
              }),
            ),
          ],
        ),
      );

  Widget _foodPrefsStep() => _StepShell(
        title: 'Food preferences',
        subtitle: 'Used to filter recipes and flag allergens.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dietary preferences',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ChoiceChips(
              options: const [
                'vegetarian',
                'vegan',
                'halal',
                'lactose-free',
                'gluten-free'
              ],
              selected: _dietary,
              onToggle: (v) => setState(() {
                _dietary.contains(v) ? _dietary.remove(v) : _dietary.add(v);
              }),
            ),
            const SizedBox(height: BloomSpacing.md),
            Text('Allergies', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ChoiceChips(
              options: const [
                'peanut',
                'tree nut',
                'milk',
                'egg',
                'fish',
                'shellfish',
                'soy',
                'wheat',
                'gluten',
                'sesame'
              ],
              selected: _allergies,
              onToggle: (v) => setState(() {
                _allergies.contains(v)
                    ? _allergies.remove(v)
                    : _allergies.add(v);
              }),
            ),
            const SizedBox(height: 12),
            Text('Foods to avoid (comma-separated, optional)',
                style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            TextField(
              decoration:
                  const InputDecoration(hintText: 'e.g. pork, cilantro'),
              onChanged: (v) => setState(() => _avoidFoods = v),
            ),
            const SizedBox(height: 8),
            const InfoNote(
                text:
                    'Recipe allergen flags come from ingredient data and cannot guarantee safety — always check labels.'),
          ],
        ),
      );

  Widget _rhythmStep() {
    final wUnit = _units == 'imperial' ? 'fl oz' : 'L';
    return _StepShell(
      title: 'Daily rhythms',
      subtitle: 'Gentle defaults — Pip never scolds you for missing them.',
      child: Column(
        children: [
          _NumField(
              label: 'Daily step goal',
              value: _steps,
              onChanged: (v) => setState(() => _steps = v)),
          const SizedBox(height: 12),
          _NumField(
              label: 'Water goal ($wUnit)',
              value: _water,
              onChanged: (v) => setState(() => _water = v)),
          const SizedBox(height: 12),
          _NumField(
              label: 'Sleep goal (hours)',
              value: _sleep,
              onChanged: (v) => setState(() => _sleep = v)),
        ],
      ),
    );
  }

  Widget _targetsStep() {
    if (!_allowEstimate) {
      return _StepShell(
        title: 'Nutrition targets',
        child: Column(
          children: [
            const InfoNote(
              icon: Icons.favorite_outline,
              text:
                  'Because of your selections (age, pregnancy/nursing, or specialized guidance), Bloom will not auto-generate calorie targets. You can set your own numbers with a professional, or simply use Bloom without calorie tracking.',
            ),
            const SizedBox(height: BloomSpacing.md),
            _TargetField(
                label: 'Daily calories (optional)',
                value: _kcal,
                onChanged: (v) {
                  _targetsTouched = true;
                  setState(() => _kcal = v);
                }),
          ],
        ),
      );
    }
    return _StepShell(
      title: 'Your estimated targets',
      subtitle:
          'Estimated from your details with the Mifflin-St Jeor equation. Estimates, not prescriptions — adjust freely.',
      child: Column(
        children: [
          _TargetField(
              label: 'Daily calories (kcal)',
              value: _kcal,
              onChanged: (v) {
                _targetsTouched = true;
                setState(() => _kcal = v);
              }),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _TargetField(
                      label: 'Protein (g)',
                      value: _protein,
                      onChanged: (v) {
                        _targetsTouched = true;
                        setState(() => _protein = v);
                      })),
              const SizedBox(width: 10),
              Expanded(
                  child: _TargetField(
                      label: 'Carbs (g)',
                      value: _carbs,
                      onChanged: (v) {
                        _targetsTouched = true;
                        setState(() => _carbs = v);
                      })),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _TargetField(
                      label: 'Fat (g)',
                      value: _fat,
                      onChanged: (v) {
                        _targetsTouched = true;
                        setState(() => _fat = v);
                      })),
              const SizedBox(width: 10),
              Expanded(
                  child: _TargetField(
                      label: 'Fiber (g)',
                      value: _fiber,
                      onChanged: (v) {
                        _targetsTouched = true;
                        setState(() => _fiber = v);
                      })),
            ],
          ),
          const SizedBox(height: 12),
          const InfoNote(
              text:
                  'Exercise calorie estimates stay separate and never auto-increase your food budget.'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- pieces

class _StepShell extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  const _StepShell({this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.lg, BloomSpacing.sm, BloomSpacing.lg, BloomSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: BloomSpacing.lg),
          ],
          child,
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BloomSpacing.md, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          total,
          (i) => Container(
            width: i == step ? 26 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= step
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int step;
  final int total;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final bool canNext;
  const _NavBar({
    required this.step,
    required this.total,
    required this.onBack,
    required this.onNext,
    required this.canNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.lg, BloomSpacing.sm, BloomSpacing.lg, BloomSpacing.lg),
      child: Row(
        children: [
          if (step > 0)
            TextButton(onPressed: onBack, child: const Text('Back')),
          const Spacer(),
          FilledButton(
            onPressed: canNext ? onNext : null,
            style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 34, vertical: 15)),
            child: Text(step == total - 1 ? 'Start Blooming' : 'Continue'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _GoalCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(BloomRadii.bubble),
      child: Container(
        padding: const EdgeInsets.all(BloomSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withOpacity(0.12)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _NumField(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(hintText: '—'),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TargetField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _TargetField(
      {required this.label, required this.value, required this.onChanged});

  @override
  State<_TargetField> createState() => _TargetFieldState();
}

class _TargetFieldState extends State<_TargetField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_TargetField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update when the parent recomputes (e.g. re-estimate), but don't fight
    // the user's in-progress typing.
    if (widget.value != oldWidget.value &&
        widget.value != _ctrl.text) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: _ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
