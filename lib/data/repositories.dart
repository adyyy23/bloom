import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database.dart';
import 'models.dart';
import '../core/utils.dart';
import '../companion/human_body_mesh.dart';

Map<String, dynamic> _asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

// ---------------------------------------------------------------- profile

class ProfileRepo extends ChangeNotifier {
  UserProfile _p = UserProfile();
  UserProfile get profile => _p;

  void load() {
    final raw = Database.profile.get('profile');
    if (raw != null) _p = UserProfile.fromJson(_asMap(raw));
  }

  Future<void> save(UserProfile p) async {
    _p = p;
    await Database.profile.put('profile', p.toJson());
    notifyListeners();
  }

  Future<void> update(UserProfile Function(UserProfile p) fn) async {
    final p = fn(_p);
    await save(p);
  }
}

// ---------------------------------------------------------------- settings

class SettingsRepo extends ChangeNotifier {
  AppSettings _s = AppSettings();
  AppSettings get settings => _s;

  void load() {
    final raw = Database.settings.get('settings');
    if (raw != null) _s = AppSettings.fromJson(_asMap(raw));
  }

  Future<void> save(AppSettings s) async {
    _s = s;
    await Database.settings.put('settings', s.toJson());
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings s) fn) async =>
      save(fn(_s));
}

// ------------------------------------------------------------------- food

/// A loggable food choice from any source.
class FoodChoice {
  final String key; // catalog id, 'custom:<id>', or 'recipe:<id>'
  final String name;
  final Nutrition per100g;
  final List<ServingUnit> units;
  final String source;
  final String kind; // catalog | custom | recipe
  final Recipe? recipe;

  FoodChoice({
    required this.key,
    required this.name,
    required this.per100g,
    required this.units,
    required this.source,
    required this.kind,
    this.recipe,
  });
}

class FoodRepo extends ChangeNotifier {
  List<FoodEntry> _entries = [];
  List<CustomFood> _custom = [];
  Set<String> _favorites = {};

  List<FoodEntry> get entries => _entries;
  List<CustomFood> get customFoods => _custom;

  void load() {
    _entries = Database.foodEntries.values
        .map((e) => FoodEntry.fromJson(_asMap(e)))
        .toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _custom = Database.customFoods.values
        .map((e) => CustomFood.fromJson(_asMap(e)))
        .toList();
    _favorites = Database.favorites.get('ids') is List
        ? Set<String>.from((Database.favorites.get('ids') as List).map((e) => e.toString()))
        : <String>{};
  }

  List<FoodEntry> entriesFor(String dateKey) =>
      _entries.where((e) => e.dateKey == dateKey).toList();

  List<FoodEntry> entriesForMeal(String dateKey, String meal) =>
      _entries.where((e) => e.dateKey == dateKey && e.meal == meal).toList();

  Nutrition dayNutrition(String dateKey) {
    var total = const Nutrition();
    for (final e in entriesFor(dateKey)) {
      total = total + e.nutrition;
    }
    return total;
  }

  Map<String, Nutrition> weekNutrition(List<String> keys) =>
      {for (final k in keys) k: dayNutrition(k)};

  Future<FoodEntry> addEntry(FoodEntry e) async {
    await Database.foodEntries.put(e.id, e.toJson());
    _entries.insert(0, e);
    notifyListeners();
    return e;
  }

  Future<void> updateEntry(FoodEntry e) async {
    await Database.foodEntries.put(e.id, e.toJson());
    final i = _entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) _entries[i] = e;
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await Database.foodEntries.delete(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  /// Copy an entry to another date (planned meal confirmed as eaten, or repeat).
  Future<FoodEntry> copyToDate(FoodEntry e, String dateKey, {String? meal}) async {
    final copy = FoodEntry(
      id: newId(),
      dateKey: dateKey,
      meal: meal ?? e.meal,
      name: e.name,
      catalogId: e.catalogId,
      recipeId: e.recipeId,
      servingQty: e.servingQty,
      servingUnit: e.servingUnit,
      grams: e.grams,
      nutrition: e.nutrition,
    );
    return addEntry(copy);
  }

  // -- custom foods --
  Future<void> addCustomFood(CustomFood f) async {
    await Database.customFoods.put(f.id, f.toJson());
    _custom.add(f);
    notifyListeners();
  }

  Future<void> updateCustomFood(CustomFood f) async {
    await Database.customFoods.put(f.id, f.toJson());
    final i = _custom.indexWhere((x) => x.id == f.id);
    if (i >= 0) _custom[i] = f;
    notifyListeners();
  }

  Future<void> deleteCustomFood(String id) async {
    await Database.customFoods.delete(id);
    _custom.removeWhere((f) => f.id == id);
    _favorites.remove('custom:$id');
    await _saveFavorites();
    notifyListeners();
  }

  // -- favorites / recents --
  bool isFavorite(String key) => _favorites.contains(key);
  List<String> get favoriteKeys => _favorites.toList();

  Future<void> toggleFavorite(String key) async {
    if (_favorites.contains(key)) {
      _favorites.remove(key);
    } else {
      _favorites.add(key);
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() =>
      Database.favorites.put('ids', _favorites.toList());

  List<FoodEntry> recents({int limit = 12}) => _entries.take(limit).toList();

  // -- catalog search (seed catalog injected by caller) --
  List<FoodChoice> search(
    String query,
    List<CatalogFood> catalog,
    RecipeRepo recipes,
  ) {
    final q = query.trim().toLowerCase();
    final out = <FoodChoice>[];
    bool match(String name) =>
        q.isEmpty || name.toLowerCase().contains(q);
    if (q.isEmpty) {
      // favorites + recents first
      for (final key in _favorites) {
        final c = _choiceForKey(key, catalog, recipes);
        if (c != null) out.add(c);
      }
      return out;
    }
    for (final f in catalog) {
      if (match(f.name) || (f.filipino && 'filipino pinoy'.contains(q))) {
        out.add(FoodChoice(
          key: f.id,
          name: f.name,
          per100g: f.per100g,
          units: f.units,
          source: f.per100g.source,
          kind: 'catalog',
        ));
      }
    }
    for (final f in _custom) {
      if (match(f.name)) {
        out.add(FoodChoice(
          key: 'custom:${f.id}',
          name: f.name,
          per100g: f.per100g,
          units: f.units,
          source: f.per100g.source.isEmpty ? 'Custom entry' : f.per100g.source,
          kind: 'custom',
        ));
      }
    }
    for (final r in recipes.all) {
      if (match(r.name)) {
        final per = recipes.perServing(r, catalog);
        out.add(FoodChoice(
          key: 'recipe:${r.id}',
          name: r.name,
          per100g: per,
          units: [const ServingUnit('serving', 0)],
          source: 'Recipe estimate',
          kind: 'recipe',
          recipe: r,
        ));
      }
    }
    // favorites float to top
    out.sort((a, b) {
      final fa = _favorites.contains(a.key) ? 0 : 1;
      final fb = _favorites.contains(b.key) ? 0 : 1;
      return fa.compareTo(fb);
    });
    return out.take(60).toList();
  }

  FoodChoice? _choiceForKey(String key, List<CatalogFood> catalog, RecipeRepo recipes) {
    if (key.startsWith('custom:')) {
      final id = key.substring(7);
      final f = _custom.where((e) => e.id == id).firstOrNull;
      if (f == null) return null;
      return FoodChoice(
          key: key, name: f.name, per100g: f.per100g, units: f.units,
          source: 'Custom entry', kind: 'custom');
    }
    if (key.startsWith('recipe:')) {
      final r = recipes.byId(key.substring(7));
      if (r == null) return null;
      return FoodChoice(
          key: key, name: r.name, per100g: recipes.perServing(r, catalog),
          units: const [ServingUnit('serving', 0)],
          source: 'Recipe estimate', kind: 'recipe', recipe: r);
    }
    final f = catalog.where((e) => e.id == key).firstOrNull;
    if (f == null) return null;
    return FoodChoice(
        key: key, name: f.name, per100g: f.per100g, units: f.units,
        source: f.per100g.source, kind: 'catalog');
  }

  FoodChoice? choiceForKey(String key, List<CatalogFood> catalog, RecipeRepo recipes) =>
      _choiceForKey(key, catalog, recipes);
}

// ----------------------------------------------------------------- recipes

class RecipeRepo extends ChangeNotifier {
  List<Recipe> _personal = [];
  List<Recipe> get personal => _personal;
  List<Recipe> get all => [..._seed, ..._personal];

  static final List<Recipe> _seed = [];

  static void registerSeed(List<Recipe> seeds) {
    _seed
      ..clear()
      ..addAll(seeds);
  }

  void load() {
    _personal = Database.recipes.values
        .map((e) => Recipe.fromJson(_asMap(e)))
        .toList();
  }

  Recipe? byId(String id) => all.where((r) => r.id == id).firstOrNull;

  /// Nutrition per serving, computed from current catalog data.
  Nutrition perServing(Recipe r, List<CatalogFood> catalog) {
    var total = const Nutrition();
    for (final ing in r.ingredients) {
      final f = catalog.where((e) => e.id == ing.foodId).firstOrNull;
      if (f == null) continue;
      total = total + f.per100g.scaled(ing.grams / 100);
    }
    final s = r.servings <= 0 ? 1 : r.servings;
    final per = total.scaled(1 / s);
    return Nutrition(
      kcal: per.kcal, protein: per.protein, carbs: per.carbs, fat: per.fat,
      fiber: per.fiber, sodiumMg: per.sodiumMg, sugarG: per.sugarG,
      isEstimate: true, source: 'Recipe estimate from ingredient data',
    );
  }

  Nutrition per100g(Recipe r) {
    // approximate: derive from perServing with assumed serving weight
    // callers needing accuracy use perServing with the catalog.
    return const Nutrition(isEstimate: true, source: 'Recipe estimate');
  }

  Future<void> addRecipe(Recipe r) async {
    await Database.recipes.put(r.id, r.toJson());
    _personal.add(r);
    notifyListeners();
  }

  Future<void> updateRecipe(Recipe r) async {
    await Database.recipes.put(r.id, r.toJson());
    final i = _personal.indexWhere((x) => x.id == r.id);
    if (i >= 0) _personal[i] = r;
    notifyListeners();
  }

  Future<void> deleteRecipe(String id) async {
    await Database.recipes.delete(id);
    _personal.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  List<Recipe> filtered({String? diet, int? maxMinutes, String? ingredient, List<String>? avoidAllergens}) {
    return all.where((r) {
      if (diet != null && diet.isNotEmpty && !r.tags.contains(diet)) return false;
      if (maxMinutes != null && (r.prepMin + r.cookMin) > maxMinutes) return false;
      if (ingredient != null && ingredient.isNotEmpty &&
          !r.ingredients.any((i) => i.foodName.toLowerCase().contains(ingredient.toLowerCase()))) {
        return false;
      }
      if (avoidAllergens != null &&
          r.allergens.any((a) => avoidAllergens.map((e) => e.toLowerCase()).contains(a.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
  }
}

// ------------------------------------------------------------ meal plans

class PlanRepo extends ChangeNotifier {
  // dateKey -> list of PlannedMeal
  Map<String, List<PlannedMeal>> _plans = {};
  List<GroceryItem> _grocery = [];
  List<PantryItem> _pantry = [];

  List<GroceryItem> get grocery => _grocery;
  List<PantryItem> get pantry => _pantry;

  void load() {
    _plans = {};
    for (final k in Database.mealPlans.keys) {
      final raw = Database.mealPlans.get(k) as List?;
      _plans[k.toString()] = (raw ?? []).map((e) => PlannedMeal.fromJson(_asMap(e))).toList();
    }
    _grocery = (Database.grocery.get('items') as List? ?? [])
        .map((e) => GroceryItem.fromJson(_asMap(e)))
        .toList();
    _pantry = Database.pantry.values.map((e) => PantryItem.fromJson(_asMap(e))).toList()
      ..sort((a, b) => (a.expiryKey ?? '9999').compareTo(b.expiryKey ?? '9999'));
  }

  List<PlannedMeal> planFor(String dateKey) => _plans[dateKey] ?? [];

  Future<void> setPlannedMeal(String dateKey, PlannedMeal m) async {
    final list = <PlannedMeal>[...(_plans[dateKey] ?? [])];
    list.removeWhere((e) => e.meal == m.meal);
    list.add(m);
    _plans[dateKey] = list;
    await Database.mealPlans.put(dateKey, list.map((e) => e.toJson()).toList());
    notifyListeners();
  }

  Future<void> removePlannedMeal(String dateKey, String meal) async {
    final list = <PlannedMeal>[...(_plans[dateKey] ?? [])]
      ..removeWhere((e) => e.meal == meal);
    if (list.isEmpty) {
      _plans.remove(dateKey);
      await Database.mealPlans.delete(dateKey);
    } else {
      _plans[dateKey] = list;
      await Database.mealPlans.put(dateKey, list.map((e) => e.toJson()).toList());
    }
    notifyListeners();
  }

  Future<void> _saveGrocery() async {
    await Database.grocery.put('items', _grocery.map((e) => e.toJson()).toList());
  }

  /// Build a grocery list from planned recipes over the given week.
  /// Planned meals are NEVER auto-counted as eaten.
  Future<void> generateFromPlan(
    List<String> weekKeys,
    RecipeRepo recipes,
    List<CatalogFood> catalog,
  ) async {
    final agg = <String, GroceryItem>{};
    for (final k in weekKeys) {
      for (final pm in planFor(k)) {
        if (pm.kind != 'recipe') continue;
        final r = recipes.byId(pm.refId);
        if (r == null) continue;
        final factor = pm.servings / (r.servings <= 0 ? 1 : r.servings);
        for (final ing in r.ingredients) {
          final key = ing.foodName.toLowerCase();
          final existing = agg[key];
          final qty = ing.qty * factor;
          if (existing == null) {
            agg[key] = GroceryItem(
              id: newId(),
              name: ing.foodName,
              qty: qty,
              unit: ing.unit,
              category: _categoryFor(ing.foodName, catalog),
              recipeId: r.id,
            );
          } else {
            existing.qty += qty;
          }
        }
      }
    }
    _grocery = agg.values.toList()
      ..sort((a, b) => a.category.compareTo(b.category));
    await _saveGrocery();
    notifyListeners();
  }

  String _categoryFor(String name, List<CatalogFood> catalog) {
    final f = catalog.where((e) => e.name.toLowerCase() == name.toLowerCase()).firstOrNull;
    final c = (f?.category ?? '').toLowerCase();
    if (c.contains('protein') || c.contains('meat') || c.contains('fish')) return 'Protein';
    if (c.contains('vegetable') || c.contains('fruit')) return 'Produce';
    if (c.contains('dairy')) return 'Dairy';
    if (c.contains('grain') || c.contains('bread') || c.contains('rice')) return 'Grains';
    if (c.contains('spice') || c.contains('condiment') || c.contains('oil')) return 'Pantry staples';
    return 'Other';
  }

  Future<void> toggleGrocery(String id) async {
    final i = _grocery.indexWhere((e) => e.id == id);
    if (i < 0) return;
    _grocery[i].checked = !_grocery[i].checked;
    await _saveGrocery();
    notifyListeners();
  }

  Future<void> addGroceryItem(GroceryItem item) async {
    _grocery.add(item);
    await _saveGrocery();
    notifyListeners();
  }

  Future<void> removeGroceryItem(String id) async {
    _grocery.removeWhere((e) => e.id == id);
    await _saveGrocery();
    notifyListeners();
  }

  Future<void> clearCheckedGrocery() async {
    _grocery.removeWhere((e) => e.checked);
    await _saveGrocery();
    notifyListeners();
  }

  // -- pantry --
  Future<void> addPantry(PantryItem p) async {
    await Database.pantry.put(p.id, p.toJson());
    _pantry.add(p);
    notifyListeners();
  }

  Future<void> removePantry(String id) async {
    await Database.pantry.delete(id);
    _pantry.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  List<PantryItem> expiringSoon({int days = 3}) {
    final now = Dates.todayKey();
    final limit = Dates.key(DateTime.now().add(Duration(days: days)));
    return _pantry
        .where((p) =>
            p.expiryKey != null && p.expiryKey!.compareTo(now) >= 0 && p.expiryKey!.compareTo(limit) <= 0)
        .toList();
  }

  List<PantryItem> expired() {
    final now = Dates.todayKey();
    return _pantry.where((p) => p.expiryKey != null && p.expiryKey!.compareTo(now) < 0).toList();
  }
}

// ---------------------------------------------------------------- progress

class ProgressRepo extends ChangeNotifier {
  List<WeightEntry> _weights = [];
  List<BodyMeasure> _measures = [];
  List<ProgressPhoto> _photos = [];

  List<WeightEntry> get weights => _weights;
  List<BodyMeasure> get measures => _measures;
  List<ProgressPhoto> get photos => _photos;

  void load() {
    _weights = Database.weights.values.map((e) => WeightEntry.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    _measures = Database.measures.values.map((e) => BodyMeasure.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    _photos = Database.photos.values.map((e) => ProgressPhoto.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
  }

  WeightEntry? get latest => _weights.isEmpty ? null : _weights.last;

  double? latestMeasure(String type) {
    final matches = _measures.where((m) => m.type == type).toList();
    return matches.isEmpty ? null : matches.last.valueCm;
  }

  Future<void> addWeight(WeightEntry w) async {
    await Database.weights.put(w.id, w.toJson());
    _weights.add(w);
    _weights.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    notifyListeners();
  }

  Future<void> updateWeight(WeightEntry w) async {
    await Database.weights.put(w.id, w.toJson());
    final i = _weights.indexWhere((x) => x.id == w.id);
    if (i >= 0) _weights[i] = w;
    _weights.sort((a, b) => a.dateKey.compareTo(b.dateKey));
    notifyListeners();
  }

  Future<void> deleteWeight(String id) async {
    await Database.weights.delete(id);
    _weights.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  /// 7-point trailing moving average explains smoothing in the UI.
  List<double?> trendSmoothed() =>
      Calc.movingAverage(_weights.map((w) => w.weightKg).toList(), 7);

  Future<void> addMeasure(BodyMeasure m) async {
    await Database.measures.put(m.id, m.toJson());
    _measures.add(m);
    notifyListeners();
  }

  Future<void> deleteMeasure(String id) async {
    await Database.measures.delete(id);
    _measures.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> addPhoto(ProgressPhoto p) async {
    await Database.photos.put(p.id, p.toJson());
    _photos.insert(0, p);
    notifyListeners();
  }

  Future<void> deletePhoto(String id) async {
    await Database.photos.delete(id);
    _photos.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}

// -------------------------------------------------------------------- move

class MoveRepo extends ChangeNotifier {
  List<WorkoutTemplate> _templates = [];
  List<WorkoutSession> _sessions = [];
  List<WalkSession> _walks = [];
  Map<String, Map<String, dynamic>> _stepDays = {};

  List<WorkoutTemplate> get templates => _templates;
  List<WorkoutSession> get sessions => _sessions;
  List<WalkSession> get walks => _walks;

  void load() {
    _templates = Database.templates.values.map((e) => WorkoutTemplate.fromJson(_asMap(e))).toList();
    _sessions = Database.sessions.values.map((e) => WorkoutSession.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    _walks = Database.walks.values.map((e) => WalkSession.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _stepDays = {
      for (final k in Database.stepDays.keys) k.toString(): _asMap(Database.stepDays.get(k))
    };
  }

  // -- templates --
  Future<void> saveTemplate(WorkoutTemplate t) async {
    await Database.templates.put(t.id, t.toJson());
    final i = _templates.indexWhere((x) => x.id == t.id);
    if (i >= 0) {
      _templates[i] = t;
    } else {
      _templates.add(t);
    }
    notifyListeners();
  }

  Future<void> deleteTemplate(String id) async {
    await Database.templates.delete(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // -- sessions --
  Future<void> addSession(WorkoutSession s) async {
    await Database.sessions.put(s.id, s.toJson());
    _sessions.insert(0, s);
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await Database.sessions.delete(id);
    _sessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  List<WorkoutSession> sessionsFor(String dateKey) =>
      _sessions.where((s) => s.dateKey == dateKey).toList();

  /// Best set per exercise: max weight×reps (strength) across history.
  Map<String, String> personalBests() {
    final best = <String, double>{};
    final label = <String, String>{};
    for (final s in _sessions) {
      for (final b in s.blocks) {
        for (final set in b.sets) {
          if (set.weightKg != null && set.reps != null) {
            final score = set.weightKg! * set.reps!;
            if (score > (best[b.exerciseId] ?? 0)) {
              best[b.exerciseId] = score;
              label[b.exerciseId] =
                  '${Fmt.num(set.weightKg!)} kg × ${Fmt.num(set.reps!)} — ${b.exerciseName}';
            }
          }
        }
      }
    }
    return label;
  }

  // -- walks --
  WalkSession? get activeWalk {
    // Recover a timer that was backgrounded: recompute from wall clock.
    for (final w in _walks) {
      if (!w.finished && w.source == 'timer') return w;
    }
    return null;
  }

  Future<WalkSession> startWalk({bool indoor = false}) async {
    final now = DateTime.now();
    final w = WalkSession(
      id: newId(),
      dateKey: Dates.key(now),
      startedAt: now,
      indoor: indoor,
    );
    await Database.walks.put(w.id, w.toJson());
    _walks.insert(0, w);
    notifyListeners();
    return w;
  }

  /// Elapsed seconds for an in-progress walk, from wall clock (survives backgrounding).
  int liveElapsed(WalkSession w) =>
      DateTime.now().difference(w.startedAt).inSeconds - _pausedAccum(w.id);

  final Map<String, int> _paused = {};
  int _pausedAccum(String id) => _paused[id] ?? 0;

  Future<void> pauseWalk(String id) async {
    final w = _walks.where((e) => e.id == id).firstOrNull;
    if (w == null || w.finished) return;
    _paused[id] = (_paused[id] ?? 0) + 0; // pause marker stored in misc
    await Database.misc.put('walkPause_$id', DateTime.now().toIso8601String());
    notifyListeners();
  }

  Future<void> resumeWalk(String id) async {
    final raw = Database.misc.get('walkPause_$id');
    if (raw is String) {
      final pausedAt = DateTime.tryParse(raw);
      if (pausedAt != null) {
        _paused[id] = (_paused[id] ?? 0) + DateTime.now().difference(pausedAt).inSeconds;
      }
      await Database.misc.delete('walkPause_$id');
    }
    notifyListeners();
  }

  Future<WalkSession?> finishWalk(String id, {int steps = 0, double distanceM = 0, String? note}) async {
    final w = _walks.where((e) => e.id == id).firstOrNull;
    if (w == null) return null;
    final elapsed = liveElapsed(w);
    w.endedAt = DateTime.now();
    w.durationSec = elapsed;
    w.steps = steps;
    w.distanceM = distanceM;
    if (note != null) w.note = note;
    _paused.remove(id);
    await Database.misc.delete('walkPause_$id');
    await Database.walks.put(w.id, w.toJson());
    notifyListeners();
    return w;
  }

  Future<void> addManualWalk(WalkSession w) async {
    await Database.walks.put(w.id, w.toJson());
    _walks.insert(0, w);
    _walks.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    notifyListeners();
  }

  Future<void> deleteWalk(String id) async {
    await Database.walks.delete(id);
    _walks.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  List<WalkSession> walksFor(String dateKey) =>
      _walks.where((w) => w.dateKey == dateKey && w.finished).toList();

  // -- step days (device/manual totals) --
  Future<void> setSteps(String dateKey, int steps, String source) async {
    _stepDays[dateKey] = {'steps': steps, 'source': source};
    await Database.stepDays.put(dateKey, {'steps': steps, 'source': source});
    notifyListeners();
  }

  /// Display steps without double counting: an explicit day total wins and is
  /// labeled; otherwise we fall back to finished logged walks, labeled.
  ({int value, String source}) displaySteps(String dateKey) {
    final rec = _stepDays[dateKey];
    if (rec != null) {
      final s = (rec['source'] as String? ?? 'manual');
      return (value: (rec['steps'] as num?)?.toInt() ?? 0, source: s == 'device' ? 'Device' : 'Manual entry');
    }
    final walkSteps = walksFor(dateKey).fold<int>(0, (a, w) => a + w.steps);
    if (walkSteps > 0) return (value: walkSteps, source: 'Logged walks');
    return (value: 0, source: 'No data');
  }

  int weekSteps(List<String> keys) {
    var total = 0;
    for (final k in keys) {
      total += displaySteps(k).value;
    }
    return total;
  }
}

// ----------------------------------------------------------------- wellness

class WellnessRepo extends ChangeNotifier {
  List<WaterLog> _water = [];
  List<SleepLog> _sleep = [];
  List<MoodLog> _mood = [];
  List<JournalEntry> _journal = [];
  List<BreathingSession> _breathing = [];
  List<CheckIn> _checkins = [];

  void load() {
    _water = Database.water.values.map((e) => WaterLog.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _sleep = Database.sleep.values.map((e) => SleepLog.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.dateKey.compareTo(a.dateKey));
    _mood = Database.mood.values.map((e) => MoodLog.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _journal = Database.journal.values.map((e) => JournalEntry.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _breathing = Database.breathing.values.map((e) => BreathingSession.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _checkins = Database.checkins.values.map((e) => CheckIn.fromJson(_asMap(e))).toList();
  }

  // water
  List<WaterLog> waterFor(String k) => _water.where((w) => w.dateKey == k).toList();
  double waterTotal(String k) => waterFor(k).fold(0.0, (a, w) => a + w.ml);
  Future<void> addWater(double ml, {String? dateKey}) async {
    final w = WaterLog(id: newId(), dateKey: dateKey ?? Dates.todayKey(), ml: ml);
    await Database.water.put(w.id, w.toJson());
    _water.insert(0, w);
    notifyListeners();
  }

  Future<void> deleteWater(String id) async {
    await Database.water.delete(id);
    _water.removeWhere((w) => w.id == id);
    notifyListeners();
  }

  // sleep
  List<SleepLog> get sleepLogs => _sleep;
  SleepLog? sleepFor(String dateKey) => _sleep.where((s) => s.dateKey == dateKey).firstOrNull;
  Future<void> saveSleep(SleepLog s) async {
    await Database.sleep.put(s.id, s.toJson());
    _sleep.removeWhere((x) => x.id == s.id);
    _sleep.add(s);
    _sleep.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    notifyListeners();
  }

  Future<void> deleteSleep(String id) async {
    await Database.sleep.delete(id);
    _sleep.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  double avgSleepHours(List<String> keys) {
    final ds = _sleep.where((s) => keys.contains(s.dateKey)).toList();
    if (ds.isEmpty) return 0;
    var total = 0.0;
    for (final s in ds) {
      total += Dates.sleepDuration(s.bedtime, s.wakeTime, s.dateKey).inMinutes / 60;
    }
    return total / ds.length;
  }

  // mood
  List<MoodLog> moodFor(String k) => _mood.where((m) => m.dateKey == k).toList();
  List<MoodLog> get moodHistory => _mood;
  Future<void> addMood(MoodLog m) async {
    await Database.mood.put(m.id, m.toJson());
    _mood.insert(0, m);
    notifyListeners();
  }

  Future<void> deleteMood(String id) async {
    await Database.mood.delete(id);
    _mood.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // journal
  List<JournalEntry> get journalEntries => _journal;
  Future<void> saveJournal(JournalEntry j) async {
    await Database.journal.put(j.id, j.toJson());
    _journal.removeWhere((x) => x.id == j.id);
    _journal.insert(0, j);
    notifyListeners();
  }

  Future<void> deleteJournal(String id) async {
    await Database.journal.delete(id);
    _journal.removeWhere((j) => j.id == id);
    notifyListeners();
  }

  // breathing
  Future<void> addBreathing(BreathingSession s) async {
    await Database.breathing.put(s.id, s.toJson());
    _breathing.insert(0, s);
    notifyListeners();
  }

  // check-ins
  CheckIn? checkInFor(String k) => _checkins.where((c) => c.dateKey == k).firstOrNull;
  Future<void> saveCheckIn(CheckIn c) async {
    await Database.checkins.put(c.id, c.toJson());
    _checkins.removeWhere((x) => x.id == c.id);
    _checkins.add(c);
    notifyListeners();
  }
}

// -------------------------------------------------------------- health log

class HealthRepo extends ChangeNotifier {
  List<HealthNote> _notes = [];
  List<Medication> _meds = [];
  List<MedLog> _medLogs = [];
  List<Appointment> _appointments = [];
  List<HealthMetric> _metrics = [];

  List<HealthNote> get notes => _notes;
  List<Medication> get meds => _meds;
  List<MedLog> get medLogs => _medLogs;
  List<Appointment> get appointments => _appointments;
  List<HealthMetric> get metrics => _metrics;

  void load() {
    _notes = Database.healthNotes.values.map((e) => HealthNote.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _meds = Database.meds.values.map((e) => Medication.fromJson(_asMap(e))).toList();
    _medLogs = Database.medLogs.values.map((e) => MedLog.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    _appointments = Database.appointments.values.map((e) => Appointment.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    _metrics = Database.metrics.values.map((e) => HealthMetric.fromJson(_asMap(e))).toList()
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
  }

  Future<void> saveNote(HealthNote n) async {
    await Database.healthNotes.put(n.id, n.toJson());
    _notes.removeWhere((x) => x.id == n.id);
    _notes.insert(0, n);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    await Database.healthNotes.delete(id);
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> saveMed(Medication m) async {
    await Database.meds.put(m.id, m.toJson());
    _meds.removeWhere((x) => x.id == m.id);
    _meds.add(m);
    notifyListeners();
  }

  Future<void> deleteMed(String id) async {
    await Database.meds.delete(id);
    _meds.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  Future<void> logMed(String medId, bool taken, {String? dateKey}) async {
    final l = MedLog(id: newId(), medId: medId, dateKey: dateKey ?? Dates.todayKey(), taken: taken);
    await Database.medLogs.put(l.id, l.toJson());
    _medLogs.insert(0, l);
    notifyListeners();
  }

  List<MedLog> medLogsFor(String medId, String dateKey) =>
      _medLogs.where((l) => l.medId == medId && l.dateKey == dateKey).toList();

  Future<void> saveAppointment(Appointment a) async {
    await Database.appointments.put(a.id, a.toJson());
    _appointments.removeWhere((x) => x.id == a.id);
    _appointments.add(a);
    _appointments.sort((x, y) => x.dateKey.compareTo(y.dateKey));
    notifyListeners();
  }

  Future<void> deleteAppointment(String id) async {
    await Database.appointments.delete(id);
    _appointments.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> saveMetric(HealthMetric m) async {
    await Database.metrics.put(m.id, m.toJson());
    _metrics.removeWhere((x) => x.id == m.id);
    _metrics.insert(0, m);
    notifyListeners();
  }

  Future<void> deleteMetric(String id) async {
    await Database.metrics.delete(id);
    _metrics.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  List<HealthMetric> metricsOfKind(String kind) => _metrics.where((m) => m.kind == kind).toList();
}

// -------------------------------------------------------------------- chat

class ChatRepo extends ChangeNotifier {
  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  void load() {
    _messages = Database.chat.values.map((e) => ChatMessage.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.at.compareTo(b.at));
  }

  Future<void> add(ChatMessage m) async {
    await Database.chat.put(m.id, m.toJson());
    _messages.add(m);
    notifyListeners();
  }

  Future<void> markActionDone(String id) async {
    final i = _messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    _messages[i].actionDone = true;
    await Database.chat.put(_messages[i].id, _messages[i].toJson());
    notifyListeners();
  }

  Future<void> clear() async {
    await Database.chat.clear();
    _messages.clear();
    notifyListeners();
  }
}

// --------------------------------------------------------------- reminders

class ReminderRepo extends ChangeNotifier {
  List<ReminderItem> _items = [];
  List<ReminderItem> get items => _items;

  void load() {
    _items = Database.reminders.values.map((e) => ReminderItem.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  Future<void> save(ReminderItem r) async {
    await Database.reminders.put(r.id, r.toJson());
    _items.removeWhere((x) => x.id == r.id);
    _items.add(r);
    _items.sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await Database.reminders.delete(id);
    _items.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}

// -------------------------------------------------------------- motivation

class MotivationRepo extends ChangeNotifier {
  List<Challenge> _challenges = [];
  Set<String> _achievements = {};
  List<String> _accessories = ['sprout'];
  String _activeAccessory = 'sprout';

  List<Challenge> get challenges => _challenges;
  Set<String> get achievements => _achievements;
  List<String> get unlockedAccessories => _accessories;
  String get activeAccessory => _activeAccessory;

  void load() {
    _challenges = Database.challenges.values.map((e) => Challenge.fromJson(_asMap(e))).toList();
    final a = Database.achievements.get('unlocked');
    _achievements = a is List ? Set<String>.from(a.map((e) => e.toString())) : <String>{};
    final acc = Database.misc.get('accessories');
    _accessories = acc is List && acc.isNotEmpty
        ? List<String>.from(acc.map((e) => e.toString()))
        : ['sprout'];
    _activeAccessory = Database.misc.get('activeAccessory')?.toString() ?? 'sprout';
  }

  Future<void> saveChallenge(Challenge c) async {
    await Database.challenges.put(c.id, c.toJson());
    _challenges.removeWhere((x) => x.id == c.id);
    _challenges.add(c);
    notifyListeners();
  }

  Future<void> deleteChallenge(String id) async {
    await Database.challenges.delete(id);
    _challenges.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  bool hasAchievement(String key) => _achievements.contains(key);

  Future<void> unlock(String key) async {
    if (_achievements.contains(key)) return;
    _achievements.add(key);
    await Database.achievements.put('unlocked', _achievements.toList());
    notifyListeners();
  }

  Future<void> unlockAccessory(String id) async {
    if (_accessories.contains(id)) return;
    _accessories.add(id);
    await Database.misc.put('accessories', _accessories);
    notifyListeners();
  }

  Future<void> setActiveAccessory(String id) async {
    _activeAccessory = id;
    await Database.misc.put('activeAccessory', id);
    notifyListeners();
  }

  /// Consecutive days (ending today/yesterday) with any logged activity.
  int streakDays({
    required FoodRepo food,
    required MoveRepo move,
    required WellnessRepo wellness,
  }) {
    int streak = 0;
    var day = DateTime.now();
    // allow today to be empty; streak counts back from yesterday if so
    if (!_hasActivity(Dates.key(day), food, move, wellness)) {
      day = day.subtract(const Duration(days: 1));
      if (!_hasActivity(Dates.key(day), food, move, wellness)) return 0;
    }
    while (_hasActivity(Dates.key(day), food, move, wellness)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
      if (streak > 365) break;
    }
    return streak;
  }

  bool _hasActivity(String k, FoodRepo food, MoveRepo move, WellnessRepo wellness) {
    return food.entriesFor(k).isNotEmpty ||
        move.sessionsFor(k).isNotEmpty ||
        move.walksFor(k).isNotEmpty ||
        wellness.waterFor(k).isNotEmpty ||
        wellness.moodFor(k).isNotEmpty ||
        wellness.sleepFor(k) != null;
  }

  /// Called after any meaningful log; unlocks accessories/achievements.
  /// Never punishes: missing days simply don't extend streaks.
  Future<List<String>> recordActivity({
    required FoodRepo food,
    required MoveRepo move,
    required WellnessRepo wellness,
  }) async {
    final newly = <String>[];
    final streak = streakDays(food: food, move: move, wellness: wellness);
    if (streak >= 3 && !_accessories.contains('flower')) {
      await unlockAccessory('flower');
      newly.add('Flower crown');
    }
    if (streak >= 14 && !_accessories.contains('scarf')) {
      await unlockAccessory('scarf');
      newly.add('Cozy scarf');
    }
    final workouts = move.sessions.length + move.walks.where((w) => w.finished).length;
    if (workouts >= 5 && !_accessories.contains('star')) {
      await unlockAccessory('star');
      newly.add('Star badge');
    }
    if (streak >= 7 && !hasAchievement('week_streak')) {
      await unlock('week_streak');
      newly.add('7-day streak');
    }
    if (food.entries.isNotEmpty && !hasAchievement('first_meal')) {
      await unlock('first_meal');
      newly.add('First meal logged');
    }
    return newly;
  }
}

// ---------------------------------------------------------------- avatar

class AvatarRepo extends ChangeNotifier {
  AvatarConfig _config = const AvatarConfig();
  AvatarConfig get config => _config;

  void load() {
    final raw = Database.misc.get('avatarConfig');
    if (raw != null) {
      _config = AvatarConfig.fromJson(_asMap(raw));
    }
  }

  Future<void> save(AvatarConfig c) async {
    _config = c;
    await Database.misc.put('avatarConfig', c.toJson());
    notifyListeners();
  }

  Future<void> update(AvatarConfig Function(AvatarConfig c) fn) async {
    final c = fn(_config);
    await save(c);
  }
}

// --------------------------------------------------------------- providers

final profileRepoProvider = ChangeNotifierProvider<ProfileRepo>((ref) => ProfileRepo());
final settingsRepoProvider = ChangeNotifierProvider<SettingsRepo>((ref) => SettingsRepo());
final foodRepoProvider = ChangeNotifierProvider<FoodRepo>((ref) => FoodRepo());
final recipeRepoProvider = ChangeNotifierProvider<RecipeRepo>((ref) => RecipeRepo());
final planRepoProvider = ChangeNotifierProvider<PlanRepo>((ref) => PlanRepo());
final progressRepoProvider = ChangeNotifierProvider<ProgressRepo>((ref) => ProgressRepo());
final moveRepoProvider = ChangeNotifierProvider<MoveRepo>((ref) => MoveRepo());
final wellnessRepoProvider = ChangeNotifierProvider<WellnessRepo>((ref) => WellnessRepo());
final healthRepoProvider = ChangeNotifierProvider<HealthRepo>((ref) => HealthRepo());
final chatRepoProvider = ChangeNotifierProvider<ChatRepo>((ref) => ChatRepo());
final reminderRepoProvider = ChangeNotifierProvider<ReminderRepo>((ref) => ReminderRepo());
final motivationRepoProvider = ChangeNotifierProvider<MotivationRepo>((ref) => MotivationRepo());
final avatarRepoProvider = ChangeNotifierProvider<AvatarRepo>((ref) => AvatarRepo()..load());
