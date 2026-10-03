import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import 'recipes_plan.dart';

const _meals = ['breakfast', 'lunch', 'dinner', 'snack'];

/// Nutrition tab: diary, recipes, meal plan, groceries.
class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  int _seg = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: BloomSpacing.md, vertical: BloomSpacing.sm),
              child: SegmentedPills<int>(
                values: const [0, 1, 2, 3],
                labels: const ['Diary', 'Recipes', 'Plan', 'Groceries'],
                selected: _seg,
                onChanged: (v) => setState(() => _seg = v),
              ),
            ),
            Expanded(
              child: switch (_seg) {
                0 => const _DiaryView(),
                1 => const RecipeListView(),
                2 => const PlanView(),
                _ => const GroceryView(),
              },
            ),
            if (!profile.showCalories && _seg == 0)
              const Padding(
                padding: EdgeInsets.all(BloomSpacing.md),
                child: InfoNote(
                    text:
                        'Calorie summaries are hidden. You can show them again in Profile > Goals.'),
              ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- diary

class _DiaryView extends ConsumerStatefulWidget {
  const _DiaryView();
  @override
  ConsumerState<_DiaryView> createState() => _DiaryViewState();
}

class _DiaryViewState extends ConsumerState<_DiaryView> {
  String _dateKey = Dates.todayKey();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileRepoProvider).profile;
    final food = ref.watch(foodRepoProvider);
    final n = food.dayNutrition(_dateKey);
    final target = profile.targetKcal;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          BloomSpacing.md, 0, BloomSpacing.md, 120),
      children: [
        _DatePager(
          dateKey: _dateKey,
          onChanged: (k) => setState(() => _dateKey = k),
        ),
        if (profile.showCalories) _DaySummary(nutrition: n, target: target, profile: profile),
        for (final meal in _meals) _MealCard(meal: meal, dateKey: _dateKey),
        const SizedBox(height: BloomSpacing.md),
        _WeekStrip(
          onTapDay: (k) => setState(() => _dateKey = k),
          selected: _dateKey,
        ),
      ],
    );
  }
}

class _DatePager extends StatelessWidget {
  final String dateKey;
  final ValueChanged<String> onChanged;
  const _DatePager({required this.dateKey, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final d = Dates.parseKey(dateKey);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BloomSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(
                Dates.key(d.subtract(const Duration(days: 1)))),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: d,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 1)),
              );
              if (picked != null) onChanged(Dates.key(picked));
            },
            borderRadius: BorderRadius.circular(BloomRadii.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(Dates.relativeDay(dateKey),
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: Dates.isToday(dateKey)
                ? null
                : () => onChanged(
                    Dates.key(d.add(const Duration(days: 1)))),
          ),
        ],
      ),
    );
  }
}

class _DaySummary extends StatelessWidget {
  final Nutrition nutrition;
  final double? target;
  final UserProfile profile;
  const _DaySummary(
      {required this.nutrition, required this.target, required this.profile});

  @override
  Widget build(BuildContext context) {
    final n = nutrition;
    final remaining = target != null ? (target! - n.kcal).round() : null;
    final pct = target != null && target! > 0
        ? (n.kcal / target!).clamp(0.0, 1.0)
        : 0.0;

    return BubbleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // One prominent calorie ring
              ProgressRing(
                progress: pct,
                size: 82,
                color: Theme.of(context).colorScheme.primary,
                center: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${n.kcal.round()}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                    ),
                    Text(
                      'kcal',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: BloomSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            remaining == null
                                ? 'No calorie target set'
                                : remaining >= 0
                                    ? '$remaining kcal left'
                                    : '${-remaining} kcal over target',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Target explanation',
                          onPressed: () => _showTargetExplanation(context),
                        ),
                      ],
                    ),
                    Text(
                      target == null
                          ? 'Set a daily goal in Profile > Goals'
                          : 'Daily target: ${target!.round()} kcal',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    MacroBar(protein: n.protein, carbs: n.carbs, fat: n.fat),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MacroTargetsRow(nutrition: n, profile: profile),
          if (n.isEstimate && n.kcal > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      size: 13, color: BloomColors.inkSoft),
                  const SizedBox(width: 4),
                  Text(
                    'Includes approximate entries (marked est.).',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTargetExplanation(BuildContext context) {
    showBubbleSheet(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Calorie & Macro Targets',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.md),
          Text(
            profile.targetsEstimated
                ? 'Your targets are estimated using the Mifflin-St Jeor formula based on your profile inputs (age, height, weight, activity). These are starting reference numbers, not strict rules.'
                : 'Your targets were customized in your profile goals.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          const Text(
            '• Protein: supports muscle recovery and satiety.\n'
            '• Carbs: primary fuel for brain and daily movement.\n'
            '• Fat: essential for hormone synthesis and nutrient absorption.\n'
            '• Fiber: promotes steady digestion and gut health.',
            style: TextStyle(height: 1.5, fontSize: 13.5),
          ),
          const SizedBox(height: BloomSpacing.lg),
          PillButton(
            label: 'Got it',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      scrollable: false,
    );
  }
}

class _MacroTargetsRow extends StatelessWidget {
  final Nutrition nutrition;
  final UserProfile profile;
  const _MacroTargetsRow({required this.nutrition, required this.profile});

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, double eaten, double? goal, Color c) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              goal == null
                  ? Fmt.grams(eaten)
                  : '${Fmt.grams(eaten)} / ${Fmt.grams(goal)}',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: c, fontSize: 13),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: goal == null || goal <= 0
                    ? 0
                    : (eaten / goal).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: c.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(c),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        cell('Protein', nutrition.protein, profile.targetProtein,
            BloomColors.lavenderDeep),
        const SizedBox(width: 10),
        cell('Carbs', nutrition.carbs, profile.targetCarbs,
            BloomColors.peachDeep),
        const SizedBox(width: 10),
        cell('Fat', nutrition.fat, profile.targetFat, BloomColors.mintDeep),
        const SizedBox(width: 10),
        cell('Fiber', nutrition.fiber, profile.targetFiber,
            BloomColors.skyDeep),
      ],
    );
  }
}

class _MealCard extends ConsumerWidget {
  final String meal;
  final String dateKey;
  const _MealCard({required this.meal, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(foodRepoProvider);
    final entries = food.entriesForMeal(dateKey, meal);
    final kcal = entries.fold<double>(0, (a, e) => a + e.nutrition.kcal);
    final title = meal[0].toUpperCase() + meal.substring(1);
    final dark = Theme.of(context).brightness == Brightness.dark;

    final (icon, tint, deep) = switch (meal) {
      'breakfast' => (
          Icons.wb_twilight,
          BloomColors.peach,
          BloomColors.peachDeep
        ),
      'lunch' => (Icons.wb_sunny_outlined, BloomColors.mint, BloomColors.mintDeep),
      'dinner' => (
          Icons.nights_stay_outlined,
          BloomColors.lavender,
          BloomColors.lavenderDeep
        ),
      _ => (Icons.cookie_outlined, BloomColors.sky, BloomColors.skyDeep),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: BubbleCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: dark ? _darkTint(tint) : tint.withOpacity(0.65),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: deep),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        kcal > 0
                            ? '${kcal.round()} kcal'
                            : '0 kcal logged',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: kcal > 0 ? deep : BloomColors.inkSoft,
                              fontWeight: kcal > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FoodSearchScreen(
                          initialMeal: meal, initialDateKey: dateKey),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(BloomRadii.pill),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withOpacity(0.08)
                          : BloomColors.surface2,
                      borderRadius: BorderRadius.circular(BloomRadii.pill),
                      border: Border.all(
                        color: dark
                            ? Colors.white.withOpacity(0.06)
                            : BloomColors.line,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (entries.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              for (final e in entries) _EntryTile(entry: e, dateKey: dateKey),
            ],
          ],
        ),
      ),
    );
  }

  Color _darkTint(Color c) {
    if (c == BloomColors.peach) return BloomColors.peachD;
    if (c == BloomColors.sky) return BloomColors.skyD;
    if (c == BloomColors.mint) return BloomColors.mintD;
    return BloomColors.lavenderD;
  }
}

class _EntryTile extends ConsumerWidget {
  final FoodEntry entry;
  final String dateKey;
  const _EntryTile({required this.entry, required this.dateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entry;
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: BloomColors.rose,
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
        ),
        child: const Icon(Icons.delete_outline, color: BloomColors.roseDeep),
      ),
      confirmDismiss: (_) => askConfirm(context,
          title: 'Delete entry?',
          body: '"${e.name}" will be removed from ${Dates.relativeDay(dateKey)}.',
          confirmLabel: 'Delete'),
      onDismissed: (_) => ref.read(foodRepoProvider).deleteEntry(e.id),
      child: ListTile(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.bubble)),
        title: Text(e.name,
            style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          '${Fmt.num(e.servingQty, e.servingQty < 10 ? 1 : 0)} ${e.servingUnit} · ${e.nutrition.source.isEmpty ? '' : e.nutrition.source}${e.nutrition.isEstimate ? ' (est.)' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
        ),
        trailing: Text(Fmt.kcal(e.nutrition.kcal),
            style: Theme.of(context).textTheme.labelLarge),
        onTap: () => _editEntry(context, ref),
      ),
    );
  }

  Future<void> _editEntry(BuildContext context, WidgetRef ref) async {
    final updated = await showBubbleSheet<FoodEntry>(
      context,
      _ServingEditor(entry: entry),
    );
    if (updated != null) {
      await ref.read(foodRepoProvider).updateEntry(updated);
    }
  }
}

class _WeekStrip extends ConsumerWidget {
  final String selected;
  final ValueChanged<String> onTapDay;
  const _WeekStrip({required this.selected, required this.onTapDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = Dates.weekKeys(DateTime.now());
    final food = ref.watch(foodRepoProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text('This week',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: keys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) {
              final k = keys[i];
              final d = Dates.parseKey(k);
              final kcal = food.dayNutrition(k).kcal;
              final sel = k == selected;
              return InkWell(
                onTap: () => onTapDay(k),
                borderRadius: BorderRadius.circular(BloomRadii.bubble),
                child: Container(
                  width: 64,
                  decoration: BoxDecoration(
                    color: sel
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).cardTheme.color,
                    borderRadius:
                        BorderRadius.circular(BloomRadii.bubble),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(['M','T','W','T','F','S','S'][i],
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: sel
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : null)),
                      Text('${d.day}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                  color: sel
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : null)),
                      Text(kcal > 0 ? '${kcal.round()}' : '·',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  fontSize: 11,
                                  color: sel
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : null)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ food search

class FoodSearchScreen extends ConsumerStatefulWidget {
  final String initialMeal;
  final String? initialDateKey;
  const FoodSearchScreen(
      {super.key, required this.initialMeal, this.initialDateKey});

  @override
  ConsumerState<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends ConsumerState<FoodSearchScreen> {
  final _ctrl = TextEditingController();
  String _filter = 'all';
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final food = ref.watch(foodRepoProvider);
    final recipes = ref.watch(recipeRepoProvider);
    var results = food.search(_query, catalogFoods, recipes);
    results = switch (_filter) {
      'filipino' => results
          .where((r) =>
              r.kind == 'catalog' &&
              (findFood(r.key)?.filipino ?? false))
          .toList(),
      'favorites' => results.where((r) => food.isFavorite(r.key)).toList(),
      'custom' => results.where((r) => r.kind == 'custom').toList(),
      'recipes' => results.where((r) => r.kind == 'recipe').toList(),
      _ => results,
    };

    return Scaffold(
      appBar: AppBar(
          title: Text(
              'Log ${widget.initialMeal[0].toUpperCase()}${widget.initialMeal.substring(1)}')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 0),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search foods — try "adobo", "rice", "oats"',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() {
                            _ctrl.clear();
                            _query = '';
                          }),
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: BloomSpacing.md),
              child: Row(
                children: [
                  for (final f in [
                    ('all', 'All'),
                    ('filipino', 'Filipino'),
                    ('favorites', 'Favorites'),
                    ('custom', 'My foods'),
                    ('recipes', 'Recipes'),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) =>
                            setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(BloomSpacing.lg),
                      child: EmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'No matches',
                        body:
                            'Try a different search, or create a custom food with its nutrition values.',
                        actionLabel: 'Create custom food',
                        onAction: () => _editCustomFood(context, ref, null),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(BloomSpacing.md, 0,
                          BloomSpacing.md, 120),
                      itemCount: results.length,
                      itemBuilder: (ctx, i) =>
                          _ChoiceTile(choice: results[i]),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCustomFood(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Custom food'),
      ),
    );
  }

  Future<void> _editCustomFood(
      BuildContext context, WidgetRef ref, CustomFood? existing) async {
    final saved = await showBubbleSheet<CustomFood>(
      context,
      _CustomFoodEditor(existing: existing),
    );
    if (saved == null) return;
    if (existing == null) {
      await ref.read(foodRepoProvider).addCustomFood(saved);
    } else {
      await ref.read(foodRepoProvider).updateCustomFood(saved);
    }
  }
}

class _ChoiceTile extends ConsumerWidget {
  final FoodChoice choice;
  const _ChoiceTile({required this.choice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final food = ref.watch(foodRepoProvider);
    final fav = food.isFavorite(choice.key);
    final per = choice.kind == 'recipe' && choice.recipe != null
        ? 'per serving'
        : 'per 100 g';
    return BubbleCard(
      radius: BloomRadii.bubble,
      onTap: () => _openEditor(context),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(choice.name,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${choice.per100g.kcal.round()} kcal $per · ${choice.source}${choice.per100g.isEstimate ? ' (est.)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? BloomColors.roseDeep : null),
            tooltip: fav ? 'Remove favorite' : 'Save as favorite',
            onPressed: () => food.toggleFavorite(choice.key),
          ),
          const Icon(Icons.add_circle_outline),
        ],
      ),
    );
  }

  Future<void> _openEditor(BuildContext context) async {
    final screen =
        context.findAncestorStateOfType<_FoodSearchScreenState>();
    final entry = await showBubbleSheet<FoodEntry>(
      context,
      _ServingEditor.forChoice(
        choice: choice,
        meal: screen?.widget.initialMeal ?? 'snack',
        dateKey:
            screen?.widget.initialDateKey ?? Dates.todayKey(),
      ),
    );
    if (entry != null && context.mounted) {
      final ref = ProviderScope.containerOf(context);
      await ref.read(foodRepoProvider).addEntry(entry);
      await ref.read(motivationRepoProvider).recordActivity(
            food: ref.read(foodRepoProvider),
            move: ref.read(moveRepoProvider),
            wellness: ref.read(wellnessRepoProvider),
          );
      if (context.mounted) {
        Navigator.of(context).pop(); // back to diary
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged ${entry.name}')),
        );
      }
    }
  }
}

/// Serving-size editor: works for new choices and existing entries.
class _ServingEditor extends StatefulWidget {
  final FoodChoice? choice;
  final FoodEntry? entry;
  final String meal;
  final String dateKey;

  const _ServingEditor({this.entry})
      : choice = null,
        meal = '',
        dateKey = '';
  const _ServingEditor.forChoice(
      {required this.choice, required this.meal, required this.dateKey})
      : entry = null;

  @override
  State<_ServingEditor> createState() => _ServingEditorState();
}

class _ServingEditorState extends State<_ServingEditor> {
  double _qty = 1;
  String _unit = 'g';
  String _meal = 'snack';
  late List<ServingUnit> _units;
  late Nutrition _per100g;
  late String _name;
  String? _catalogId;
  String? _recipeId;
  Recipe? _recipe;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      final e = widget.entry!;
      _name = e.name;
      _qty = e.servingQty;
      _unit = e.servingUnit;
      _meal = e.meal;
      _catalogId = e.catalogId;
      _recipeId = e.recipeId;
      // recover per-100g from stored nutrition
      final g = e.grams <= 0 ? 100 : e.grams;
      _per100g = Nutrition(
        kcal: e.nutrition.kcal / g * 100,
        protein: e.nutrition.protein / g * 100,
        carbs: e.nutrition.carbs / g * 100,
        fat: e.nutrition.fat / g * 100,
        fiber: e.nutrition.fiber / g * 100,
        sodiumMg: e.nutrition.sodiumMg == null
            ? null
            : e.nutrition.sodiumMg! / g * 100,
        sugarG: e.nutrition.sugarG == null
            ? null
            : e.nutrition.sugarG! / g * 100,
        isEstimate: e.nutrition.isEstimate,
        source: e.nutrition.source,
      );
      _units = [const ServingUnit('g', 1)];
    } else {
      final c = widget.choice!;
      _name = c.name;
      _meal = widget.meal;
      _catalogId = c.kind == 'catalog' ? c.key : null;
      _recipeId = c.kind == 'recipe' ? c.key.substring(7) : null;
      _recipe = c.recipe;
      _per100g = c.per100g;
      _units = [const ServingUnit('g', 1), ...c.units];
      final first = _units.length > 1 ? _units[1].name : 'g';
      _unit = first;
      if (c.kind == 'recipe') {
        _units = [const ServingUnit('serving', 250)];
        _unit = 'serving';
      }
    }
  }

  double get _grams {
    final u = _units.where((x) => x.name == _unit).firstOrNull;
    return (u?.grams ?? 1) * _qty;
  }

  Nutrition get _nutrition {
    if (_recipe != null) {
      final repo = ProviderScope.containerOf(context)
          .read(recipeRepoProvider);
      return repo.perServing(_recipe!, catalogFoods).scaled(_qty);
    }
    return _per100g.scaled(_grams / 100);
  }

  @override
  Widget build(BuildContext context) {
    final n = _nutrition;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text(
          '${_per100g.source}${_per100g.isEstimate ? ' · approximate' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BloomSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StepperBtn(
                icon: Icons.remove,
                onTap: () => setState(
                    () => _qty = (_qty - _step()).clamp(0.25, 999))),
            Container(
              width: 110,
              alignment: Alignment.center,
              child: Text(
                Fmt.num(_qty, _qty < 10 ? 1 : 0),
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            _StepperBtn(
                icon: Icons.add,
                onTap: () =>
                    setState(() => _qty = (_qty + _step()).clamp(0.25, 999))),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            for (final u in _units)
              ChoiceChip(
                label: Text(u.name),
                selected: _unit == u.name,
                onSelected: (_) => setState(() => _unit = u.name),
              ),
          ],
        ),
        const SizedBox(height: BloomSpacing.sm),
        Text('≈ ${_grams.round()} g',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: BloomSpacing.md),
        BubbleCard(
          radius: BloomRadii.bubble,
          color: Theme.of(context).brightness == Brightness.dark
              ? BloomColors.surface2D
              : BloomColors.surface2,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calories',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(Fmt.kcal(n.kcal),
                      style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
              const SizedBox(height: 8),
              MacroBar(protein: n.protein, carbs: n.carbs, fat: n.fat),
              if (n.fiber > 0 || n.sodiumMg != null || n.sugarG != null) ...[
                const SizedBox(height: 8),
                Text(
                  [
                    if (n.fiber > 0) 'Fiber ${Fmt.grams(n.fiber)}',
                    if (n.sodiumMg != null)
                      'Sodium ${n.sodiumMg!.round()} mg',
                    if (n.sugarG != null)
                      'Sugar ${Fmt.grams(n.sugarG!)}',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: BloomSpacing.md),
        if (widget.entry == null) ...[
          Text('Meal', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          SegmentedPills<String>(
            values: _meals,
            labels: const ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
            selected: _meal,
            onChanged: (v) => setState(() => _meal = v),
          ),
          const SizedBox(height: BloomSpacing.md),
        ],
        PillButton(
          label: widget.entry == null ? 'Log food' : 'Save changes',
          expanded: true,
          onPressed: () {
            final entry = FoodEntry(
              id: widget.entry?.id ?? newId(),
              dateKey: widget.entry?.dateKey ?? widget.dateKey,
              meal: _meal,
              name: _name,
              catalogId: _catalogId,
              recipeId: _recipeId,
              servingQty: _qty,
              servingUnit: _unit,
              grams: _grams,
              nutrition: n,
              loggedAt: widget.entry?.loggedAt,
            );
            Navigator.of(context).pop(entry);
          },
        ),
      ],
    );
  }

  double _step() => _unit == 'g' ? 10 : 0.5;
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

// --------------------------------------------------------- custom foods

class _CustomFoodEditor extends StatefulWidget {
  final CustomFood? existing;
  const _CustomFoodEditor({this.existing});

  @override
  State<_CustomFoodEditor> createState() => _CustomFoodEditorState();
}

class _CustomFoodEditorState extends State<_CustomFoodEditor> {
  late TextEditingController _name;
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _fiber = TextEditingController();
  final _units = <ServingUnit>[];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    if (e != null) {
      _kcal.text = e.per100g.kcal.toStringAsFixed(0);
      _protein.text = e.per100g.protein.toStringAsFixed(1);
      _carbs.text = e.per100g.carbs.toStringAsFixed(1);
      _fat.text = e.per100g.fat.toStringAsFixed(1);
      _fiber.text = e.per100g.fiber.toStringAsFixed(1);
      _units.addAll(e.units);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _kcal.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _fiber.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.existing == null ? 'New custom food' : 'Edit custom food',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center),
        const SizedBox(height: 4),
        Text('Nutrition per 100 g, from the label or your best estimate.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center),
        const SizedBox(height: BloomSpacing.md),
        TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Food name')),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _num(_kcal, 'kcal')),
            const SizedBox(width: 8),
            Expanded(child: _num(_protein, 'protein g')),
            const SizedBox(width: 8),
            Expanded(child: _num(_carbs, 'carbs g')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _num(_fat, 'fat g')),
            const SizedBox(width: 8),
            Expanded(child: _num(_fiber, 'fiber g')),
            const SizedBox(width: 8),
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: BloomSpacing.md),
        Row(
          children: [
            Expanded(
                child: Text('Serving units',
                    style: Theme.of(context).textTheme.titleSmall)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              onPressed: _addUnit,
            ),
          ],
        ),
        for (var i = 0; i < _units.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                    child: Text(
                        '${_units[i].name} = ${_units[i].grams.toStringAsFixed(0)} g')),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      setState(() => _units.removeAt(i)),
                ),
              ],
            ),
          ),
        const SizedBox(height: BloomSpacing.md),
        PillButton(
          label: 'Save food',
          expanded: true,
          onPressed: () {
            if (_name.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Give your food a name first.')));
              return;
            }
            final f = CustomFood(
              id: widget.existing?.id ?? newId(),
              name: _name.text.trim(),
              per100g: Nutrition(
                kcal: double.tryParse(_kcal.text) ?? 0,
                protein: double.tryParse(_protein.text) ?? 0,
                carbs: double.tryParse(_carbs.text) ?? 0,
                fat: double.tryParse(_fat.text) ?? 0,
                fiber: double.tryParse(_fiber.text) ?? 0,
                isEstimate: true,
                source: 'Custom entry',
              ),
              units: List.of(_units),
            );
            Navigator.of(context).pop(f);
          },
        ),
      ],
    );
  }

  Widget _num(TextEditingController c, String label) => TextField(
        controller: c,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
      );

  Future<void> _addUnit() async {
    final nameCtrl = TextEditingController();
    final gramsCtrl = TextEditingController();
    final res = await showDialog<(String, double)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Serving unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Unit name (e.g. cup)')),
            TextField(
                controller: gramsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    const InputDecoration(labelText: 'Grams per unit')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final g = double.tryParse(gramsCtrl.text) ?? 0;
              if (nameCtrl.text.trim().isEmpty || g <= 0) return;
              Navigator.of(ctx).pop((nameCtrl.text.trim(), g));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    gramsCtrl.dispose();
    if (res != null) {
      setState(() => _units.add(ServingUnit(res.$1, res.$2)));
    }
  }
}
