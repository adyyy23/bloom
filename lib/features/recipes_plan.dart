import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../core/widgets.dart';
import '../data/catalog.dart';
import '../data/models.dart';
import '../data/repositories.dart';

// ------------------------------------------------------------ recipe list

class RecipeListView extends ConsumerStatefulWidget {
  const RecipeListView({super.key});
  @override
  ConsumerState<RecipeListView> createState() => _RecipeListViewState();
}

class _RecipeListViewState extends ConsumerState<RecipeListView> {
  String _query = '';
  String? _diet;
  int? _maxMin;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(recipeRepoProvider);
    final profile = ref.watch(profileRepoProvider).profile;
    var list = repo.filtered(
      diet: _diet,
      maxMinutes: _maxMin,
      ingredient: _query,
      avoidAllergens: const [],
    );
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((r) =>
              r.name.toLowerCase().contains(q) ||
              r.ingredients.any(
                  (i) => i.foodName.toLowerCase().contains(q)))
          .toList();
    }
    final userAllergies =
        profile.allergies.map((e) => e.toLowerCase()).toSet();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, 0, BloomSpacing.md, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search recipes or ingredients',
              prefixIcon: Icon(Icons.search),
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
              _filterChip('All', _diet == null && _maxMin == null,
                  () => setState(() {
                        _diet = null;
                        _maxMin = null;
                      })),
              _filterChip('Vegetarian', _diet == 'vegetarian',
                  () => setState(() => _diet = 'vegetarian')),
              _filterChip('High-protein', _diet == 'high-protein',
                  () => setState(() => _diet = 'high-protein')),
              _filterChip('Filipino', _diet == 'filipino',
                  () => setState(() => _diet = 'filipino')),
              _filterChip('Quick (<30 min)', _maxMin == 30,
                  () => setState(() => _maxMin = _maxMin == 30 ? null : 30)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(BloomSpacing.lg),
                  child: EmptyState(
                    icon: Icons.soup_kitchen_outlined,
                    title: 'No recipes match',
                    body: 'Try different filters, or create your own recipe.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(BloomSpacing.md, 0,
                      BloomSpacing.md, 120),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) =>
                      _RecipeCard(recipe: list[i], userAllergies: userAllergies),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final Set<String> userAllergies;
  const _RecipeCard({required this.recipe, required this.userAllergies});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(recipeRepoProvider);
    final n = repo.perServing(recipe, catalogFoods);
    final clash = recipe.allergens
        .where((a) => userAllergies.contains(a.toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BubbleCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => RecipeDetailScreen(recipeId: recipe.id))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(recipe.name,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (recipe.isSeed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BloomColors.mint.withOpacity(0.5),
                      borderRadius:
                          BorderRadius.circular(BloomRadii.pill),
                    ),
                    child: Text('Bloom',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${recipe.prepMin + recipe.cookMin} min · ${recipe.servings} servings · ${n.kcal.round()} kcal/serving (est.)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (recipe.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [
                  for (final t in recipe.tags.take(4))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .inputDecorationTheme
                            .fillColor,
                        borderRadius:
                            BorderRadius.circular(BloomRadii.pill),
                      ),
                      child: Text(t,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 12)),
                    ),
                ],
              ),
            ],
            if (clash.isNotEmpty) ...[
              const SizedBox(height: 8),
              InfoNote(
                icon: Icons.warning_amber_outlined,
                text:
                    'Contains ${clash.join(', ')} — this matches one of your allergies.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------- recipe detail

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final String recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() =>
      _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  double _servings = 1;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(recipeRepoProvider);
    final recipe = repo.byId(widget.recipeId);
    if (recipe == null) {
      return Scaffold(
          appBar: AppBar(), body: const Center(child: Text('Recipe not found')));
    }
    final profile = ref.watch(profileRepoProvider).profile;
    final n = repo.perServing(recipe, catalogFoods);
    final userAllergies =
        profile.allergies.map((e) => e.toLowerCase()).toSet();
    final clash = recipe.allergens
        .where((a) => userAllergies.contains(a.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        actions: [
          if (!recipe.isSeed)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        RecipeEditorScreen(existing: recipe)),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 120),
          children: [
            if (recipe.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: BloomSpacing.sm),
                child: Text(recipe.description,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            BubbleCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _meta(context, '${recipe.prepMin}', 'prep min'),
                  _meta(context, '${recipe.cookMin}', 'cook min'),
                  _meta(context, '${recipe.servings}', 'servings'),
                  _meta(context, '${n.kcal.round()}',
                      'kcal / serving'),
                ],
              ),
            ),
            const SizedBox(height: BloomSpacing.md),
            if (clash.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: BloomSpacing.sm),
                child: InfoNote(
                  icon: Icons.warning_amber_outlined,
                  text:
                      'This recipe contains an ingredient matching your allergies. Flags come from ingredient data and cannot guarantee safety — always check labels.',
                ),
              )
            else if (recipe.allergens.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: BloomSpacing.sm),
                child: InfoNote(
                  text:
                      'Allergens in this recipe: ${recipe.allergens.join(', ')}.',
                ),
              ),
            const SectionHeader(title: 'Nutrition per serving'),
            BubbleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MacroBar(
                      protein: n.protein, carbs: n.carbs, fat: n.fat),
                  const SizedBox(height: 8),
                  Text(
                    'Fiber ${Fmt.grams(n.fiber)}${n.sodiumMg != null ? ' · Sodium ${n.sodiumMg!.round()} mg' : ''}${n.sugarG != null ? ' · Sugar ${Fmt.grams(n.sugarG!)}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text('Recipe estimate from ingredient data.',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            SectionHeader(
                title: 'Ingredients',
                subtitle: 'for ${recipe.servings} servings'),
            BubbleCard(
              child: Column(
                children: [
                  for (final ing in recipe.ingredients)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(ing.foodName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium),
                          ),
                          Text(
                            '${Fmt.num(ing.qty, 1)} ${ing.unit} · ${ing.grams.round()} g',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SectionHeader(title: 'Steps'),
            BubbleCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < recipe.steps.length; i++)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(recipe.steps[i],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: BloomSpacing.lg),
            Row(
              children: [
                _StepperBtn2(
                    icon: Icons.remove,
                    onTap: () => setState(
                        () => _servings = (_servings - 0.5).clamp(0.5, 12))),
                Expanded(
                  child: Text(
                    '${Fmt.num(_servings, 1)} serving${_servings == 1 ? '' : 's'}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _StepperBtn2(
                    icon: Icons.add,
                    onTap: () => setState(
                        () => _servings = (_servings + 0.5).clamp(0.5, 12))),
              ],
            ),
            const SizedBox(height: BloomSpacing.sm),
            PillButton(
              label: 'Log as meal',
              icon: Icons.restaurant_outlined,
              expanded: true,
              onPressed: () => _logAsMeal(context, ref, recipe, n),
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Add to meal plan',
              icon: Icons.calendar_month_outlined,
              secondary: true,
              expanded: true,
              onPressed: () => _addToPlan(context, ref, recipe),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _logAsMeal(BuildContext context, WidgetRef ref, Recipe recipe,
      Nutrition perServing) async {
    final meal = await showBubbleSheet<String>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Log to which meal?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
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
    if (meal == null) return;
    final entry = FoodEntry(
      id: newId(),
      dateKey: Dates.todayKey(),
      meal: meal,
      name: recipe.name,
      recipeId: recipe.id,
      servingQty: _servings,
      servingUnit: 'serving',
      grams: _servings * 250,
      nutrition: perServing.scaled(_servings),
    );
    await ref.read(foodRepoProvider).addEntry(entry);
    await ref.read(motivationRepoProvider).recordActivity(
          food: ref.read(foodRepoProvider),
          move: ref.read(moveRepoProvider),
          wellness: ref.read(wellnessRepoProvider),
        );
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Logged ${recipe.name}')));
    }
  }

  Future<void> _addToPlan(
      BuildContext context, WidgetRef ref, Recipe recipe) async {
    final now = DateTime.now();
    final days = List.generate(
        7, (i) => now.add(Duration(days: i)));
    final picked = await showBubbleSheet<(String, String)>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Plan for which day & meal?',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.md),
          SizedBox(
            height: 380,
            child: ListView(
              children: [
                for (final d in days)
                  for (final m in ['breakfast', 'lunch', 'dinner'])
                    ListTile(
                      title: Text(
                          '${Dates.pretty(d)} · ${m[0].toUpperCase()}${m.substring(1)}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context)
                          .pop((Dates.key(d), m)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    await ref.read(planRepoProvider).setPlannedMeal(
          picked.$1,
          PlannedMeal(
              meal: picked.$2,
              kind: 'recipe',
              refId: recipe.id,
              name: recipe.name,
              servings: _servings),
        );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Added to your meal plan. Planned meals are never auto-counted as eaten.')),
      );
    }
  }
}

class _StepperBtn2 extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperBtn2({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .primary
              .withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child:
            Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

// ---------------------------------------------------------- recipe editor

class RecipeEditorScreen extends ConsumerStatefulWidget {
  final Recipe? existing;
  const RecipeEditorScreen({super.key, this.existing});

  @override
  ConsumerState<RecipeEditorScreen> createState() =>
      _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends ConsumerState<RecipeEditorScreen> {
  late TextEditingController _name, _desc, _prep, _cook, _servings, _steps;
  final _ingredients = <RecipeIngredient>[];
  final _tags = <String>{};
  final _allergens = <String>{};

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _prep = TextEditingController(text: '${e?.prepMin ?? 10}');
    _cook = TextEditingController(text: '${e?.cookMin ?? 15}');
    _servings = TextEditingController(text: '${e?.servings ?? 2}');
    _steps = TextEditingController(text: e?.steps.join('\n') ?? '');
    if (e != null) {
      _ingredients.addAll(e.ingredients);
      _tags.addAll(e.tags);
      _allergens.addAll(e.allergens);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _prep.dispose();
    _cook.dispose();
    _servings.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              widget.existing == null ? 'New recipe' : 'Edit recipe')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 120),
          children: [
            TextField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Recipe name')),
            const SizedBox(height: 10),
            TextField(
                controller: _desc,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)'),
                maxLines: 2),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: _prep,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Prep min'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _cook,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Cook min'))),
                const SizedBox(width: 8),
                Expanded(
                    child: TextField(
                        controller: _servings,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Servings'))),
              ],
            ),
            const SectionHeader(title: 'Ingredients'),
            for (var i = 0; i < _ingredients.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          '${_ingredients[i].foodName} — ${Fmt.num(_ingredients[i].qty, 1)} ${_ingredients[i].unit} (${_ingredients[i].grams.round()} g)'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () =>
                          setState(() => _ingredients.removeAt(i)),
                    ),
                  ],
                ),
              ),
            PillButton(
              label: 'Add ingredient',
              icon: Icons.add,
              secondary: true,
              onPressed: _pickIngredient,
            ),
            const SectionHeader(title: 'Steps'),
            TextField(
              controller: _steps,
              decoration: const InputDecoration(
                hintText: 'One step per line',
              ),
              maxLines: 6,
            ),
            const SectionHeader(title: 'Tags'),
            ChoiceChips(
              options: const [
                'vegetarian',
                'vegan',
                'high-protein',
                'quick',
                'filipino',
                'breakfast',
                'lunch',
                'dinner',
                'snack'
              ],
              selected: _tags,
              onToggle: (v) => setState(() =>
                  _tags.contains(v) ? _tags.remove(v) : _tags.add(v)),
            ),
            const SectionHeader(title: 'Allergens'),
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
              selected: _allergens,
              onToggle: (v) => setState(() => _allergens.contains(v)
                  ? _allergens.remove(v)
                  : _allergens.add(v)),
            ),
            const SizedBox(height: BloomSpacing.lg),
            PillButton(
              label: 'Save recipe',
              expanded: true,
              onPressed: _save,
            ),
            if (widget.existing != null && !widget.existing!.isSeed) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  final ok = await askConfirm(context,
                      title: 'Delete recipe?',
                      body:
                          'This personal recipe will be removed. Logged meals using it stay in your diary.',
                      confirmLabel: 'Delete');
                  if (ok && context.mounted) {
                    await ref
                        .read(recipeRepoProvider)
                        .deleteRecipe(widget.existing!.id);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Delete recipe'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickIngredient() async {
    final query = TextEditingController();
    final picked = await showBubbleSheet<CatalogFood>(
      context,
      StatefulBuilder(
        builder: (ctx, setS) {
          final q = query.text.toLowerCase();
          final list = catalogFoods
              .where((f) =>
                  q.isEmpty || f.name.toLowerCase().contains(q))
              .take(30)
              .toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick an ingredient',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 8),
              TextField(
                controller: query,
                decoration: const InputDecoration(
                    hintText: 'Search', prefixIcon: Icon(Icons.search)),
                onChanged: (_) => setS(() {}),
              ),
              SizedBox(
                height: 300,
                child: ListView(
                  children: [
                    for (final f in list)
                      ListTile(
                        title: Text(f.name),
                        subtitle: Text(
                            '${f.per100g.kcal.round()} kcal / 100 g'),
                        onTap: () => Navigator.of(ctx).pop(f),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    query.dispose();
    if (picked == null || !mounted) return;
    // qty + unit
    String unit = picked.units.isNotEmpty
        ? picked.units.first.name
        : 'g';
    double qty = 1;
    final gramsCtrl = TextEditingController(
        text: picked.units.isNotEmpty
            ? '${picked.units.first.grams.round()}'
            : '100');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(picked.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true),
                      decoration:
                          const InputDecoration(labelText: 'Quantity'),
                      onChanged: (v) => qty = double.tryParse(v) ?? 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: unit,
                      items: [
                        const DropdownMenuItem(
                            value: 'g', child: Text('g')),
                        for (final u in picked.units)
                          DropdownMenuItem(
                              value: u.name, child: Text(u.name)),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setD(() {
                          unit = v;
                          final su = picked.units
                              .where((u) => u.name == v)
                              .firstOrNull;
                          gramsCtrl.text =
                              '${((su?.grams ?? 1) * qty).round()}';
                        });
                      },
                    ),
                  ),
                ],
              ),
              TextField(
                controller: gramsCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Total grams (editable)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    gramsCtrl.dispose();
    if (ok != true) return;
    final grams = double.tryParse(gramsCtrl.text) ?? 100;
    setState(() => _ingredients.add(RecipeIngredient(
          foodId: picked.id,
          foodName: picked.name,
          qty: qty,
          unit: unit,
          grams: grams,
        )));
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name your recipe first.')));
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add at least one ingredient.')));
      return;
    }
    final r = Recipe(
      id: widget.existing?.id ?? newId(),
      name: _name.text.trim(),
      description: _desc.text.trim(),
      prepMin: int.tryParse(_prep.text) ?? 0,
      cookMin: int.tryParse(_cook.text) ?? 0,
      servings: (int.tryParse(_servings.text) ?? 2).clamp(1, 24),
      ingredients: List.of(_ingredients),
      steps: _steps.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      tags: _tags.toList(),
      allergens: _allergens.toList(),
    );
    if (widget.existing == null) {
      await ref.read(recipeRepoProvider).addRecipe(r);
    } else {
      await ref.read(recipeRepoProvider).updateRecipe(r);
    }
    if (mounted) Navigator.of(context).pop();
  }
}

// --------------------------------------------------------------- meal plan

class PlanView extends ConsumerStatefulWidget {
  const PlanView({super.key});
  @override
  ConsumerState<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends ConsumerState<PlanView> {
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(planRepoProvider);
    final weekKeys = List.generate(
        7, (i) => Dates.key(_weekStart.add(Duration(days: i))));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, 0, BloomSpacing.md, BloomSpacing.sm),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _weekStart =
                    _weekStart.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Text(
                  '${Dates.pretty(_weekStart)} – ${Dates.pretty(_weekStart.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _weekStart =
                    _weekStart.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                BloomSpacing.md, 0, BloomSpacing.md, 16),
            itemCount: 7,
            itemBuilder: (ctx, i) {
              final key = weekKeys[i];
              final d = Dates.parseKey(key);
              final meals = plan.planFor(key);
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
                            child: Text(
                              Dates.isToday(key)
                                  ? 'Today'
                                  : Dates.pretty(d),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall,
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _assignMeal(context, ref, key),
                            child: const Text('+ Plan meal'),
                          ),
                        ],
                      ),
                      if (meals.isEmpty)
                        Text('Nothing planned.',
                            style:
                                Theme.of(context).textTheme.bodySmall),
                      for (final m in meals)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(
                                      BloomRadii.pill),
                                ),
                                child: Text(m.meal,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(m.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => plan.removePlannedMeal(
                                    key, m.meal),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, 0, BloomSpacing.md, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PillButton(
                label: 'Generate grocery list from this week',
                icon: Icons.shopping_cart_outlined,
                expanded: true,
                onPressed: () async {
                  await ref
                      .read(planRepoProvider)
                      .generateFromPlan(
                          weekKeys,
                          ref.read(recipeRepoProvider),
                          catalogFoods);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Grocery list built from planned recipes.')),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              PillButton(
                label: 'Pantry & expiry reminders',
                icon: Icons.kitchen_outlined,
                secondary: true,
                expanded: true,
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PantryScreen())),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _assignMeal(
      BuildContext context, WidgetRef ref, String dateKey) async {
    final recipes = ref.read(recipeRepoProvider).all;
    final picked = await showBubbleSheet<(String, String, String)>(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Plan a meal for ${Dates.pretty(Dates.parseKey(dateKey))}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: BloomSpacing.md),
          SizedBox(
            height: 340,
            child: ListView(
              children: [
                for (final m in ['breakfast', 'lunch', 'dinner', 'snack'])
                  for (final r in recipes)
                    ListTile(
                      title: Text(r.name),
                      subtitle: Text(
                          '${m[0].toUpperCase()}${m.substring(1)} · ${r.prepMin + r.cookMin} min'),
                      trailing: const Icon(Icons.add),
                      onTap: () => Navigator.of(context)
                          .pop(('recipe', r.id, m)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    final recipe = ref.read(recipeRepoProvider).byId(picked.$2);
    if (recipe == null) return;
    await ref.read(planRepoProvider).setPlannedMeal(
          dateKey,
          PlannedMeal(
              meal: picked.$3,
              kind: 'recipe',
              refId: recipe.id,
              name: recipe.name,
              servings: 1),
        );
  }
}

// --------------------------------------------------------------- groceries

class GroceryView extends ConsumerWidget {
  const GroceryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planRepoProvider);
    final items = plan.grocery;
    final groups = <String, List<GroceryItem>>{};
    for (final i in items) {
      groups.putIfAbsent(i.category, () => []).add(i);
    }
    final done = items.where((i) => i.checked).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, 0, BloomSpacing.md, BloomSpacing.sm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  items.isEmpty
                      ? 'Your grocery list is empty.'
                      : '$done of ${items.length} gathered',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                  onPressed: () => _addItem(context, ref),
                  child: const Text('+ Add item')),
              if (done > 0)
                TextButton(
                    onPressed: () => plan.clearCheckedGrocery(),
                    child: const Text('Clear checked')),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(BloomSpacing.lg),
                  child: EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'No groceries yet',
                    body:
                        'Plan some meals for the week, then generate a grocery list from them.',
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(BloomSpacing.md, 0,
                      BloomSpacing.md, 120),
                  children: [
                    for (final cat in groups.keys)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: BloomSpacing.md),
                        child: BubbleCard(
                          radius: BloomRadii.bubble,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(cat,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                              const SizedBox(height: 4),
                              for (final item in groups[cat]!)
                                CheckboxListTile(
                                  value: item.checked,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  title: Text(
                                    '${item.name}${item.qty > 0 ? ' · ${Fmt.num(item.qty, 1)} ${item.unit}' : ''}',
                                    style: TextStyle(
                                      decoration: item.checked
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  onChanged: (_) =>
                                      plan.toggleGrocery(item.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _addItem(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add grocery item'),
        content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration:
                const InputDecoration(hintText: 'e.g. Bananas')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add')),
        ],
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok == true && name.isNotEmpty) {
      await ref.read(planRepoProvider).addGroceryItem(GroceryItem(
            id: newId(),
            name: name,
          ));
    }
  }
}

// ------------------------------------------------------------------ pantry

class PantryScreen extends ConsumerWidget {
  const PantryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planRepoProvider);
    final items = plan.pantry;
    final soon = plan.expiringSoon();
    final expired = plan.expired();

    return Scaffold(
      appBar: AppBar(title: const Text('Pantry')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              BloomSpacing.md, BloomSpacing.sm, BloomSpacing.md, 120),
          children: [
            if (expired.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: BloomSpacing.sm),
                child: InfoNote(
                  icon: Icons.warning_amber_outlined,
                  text:
                      '${expired.length} item${expired.length == 1 ? ' is' : 's are'} past expiry: ${expired.map((e) => e.name).join(', ')}. When in doubt, throw it out.',
                ),
              ),
            if (soon.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: BloomSpacing.sm),
                child: InfoNote(
                  text:
                      'Use soon (within 3 days): ${soon.map((e) => e.name).join(', ')}.',
                ),
              ),
            if (items.isEmpty)
              const EmptyState(
                icon: Icons.kitchen_outlined,
                title: 'Pantry is empty',
                body:
                    'Track what you have at home and get expiry reminders.',
              ),
            for (final p in items)
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
                            Text(p.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall),
                            Text(
                              '${Fmt.num(p.qty, 1)} ${p.unit}${p.expiryKey != null ? ' · expires ${p.expiryKey}' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (p.expiryKey != null)
                        _expiryBadge(context, p.expiryKey!),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () =>
                            plan.removePantry(p.id),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPantry(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
    );
  }

  Widget _expiryBadge(BuildContext context, String expiryKey) {
    final now = Dates.todayKey();
    final days =
        Dates.parseKey(expiryKey).difference(Dates.parseKey(now)).inDays;
    final (label, color) = days < 0
        ? ('Expired', BloomColors.roseDeep)
        : days <= 3
            ? ('$days d left', BloomColors.peachDeep)
            : ('$days d', BloomColors.mintDeep);
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(BloomRadii.pill),
      ),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: color, fontSize: 12)),
    );
  }

  Future<void> _addPantry(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    DateTime? expiry;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Add pantry item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration:
                      const InputDecoration(labelText: 'Item name')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(expiry == null
                        ? 'No expiry set'
                        : 'Expires ${Dates.pretty(expiry!)}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365)),
                        lastDate: DateTime.now()
                            .add(const Duration(days: 365 * 3)),
                      );
                      if (p != null) setD(() => expiry = p);
                    },
                    child: const Text('Pick date'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Add')),
          ],
        ),
      ),
    );
    final name = nameCtrl.text.trim();
    nameCtrl.dispose();
    if (ok == true && name.isNotEmpty) {
      await ref.read(planRepoProvider).addPantry(PantryItem(
            id: newId(),
            name: name,
            expiryKey: expiry == null ? null : Dates.key(expiry!),
          ));
    }
  }
}
