/// All personal-record models. Stored in Hive as plain maps (toJson/fromJson)
/// so no code generation is required. Internal storage is always metric.
library;

Map<String, dynamic> _m(Map<String, dynamic> m) => Map<String, dynamic>.from(m);
List<String> _sl(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? [];
double _d(dynamic v, [double fb = 0]) => (v as num?)?.toDouble() ?? fb;
int _i(dynamic v, [int fb = 0]) => (v as num?)?.toInt() ?? fb;
bool _b(dynamic v, [bool fb = false]) => v is bool ? v : fb;

// ---------------------------------------------------------------- profile

class UserProfile {
  String name;
  String units; // metric | imperial
  String goal; // lose | gain | maintain | fitness | habits
  int? birthYear;
  bool isFemale;
  bool pregnancyOrNursing;
  bool specializedGuidance; // needs professional nutrition guidance
  double? heightCm;
  double? startWeightKg;
  double? goalWeightKg;
  String activityLevel; // low | moderate | active | very
  String experience; // beginner | intermediate | advanced
  List<String> equipment;
  List<String> dietary; // vegetarian, vegan, halal, lactose-free, gluten-free
  List<String> allergies;
  List<String> avoidFoods;
  int walkGoalSteps;
  double waterGoalMl;
  double sleepGoalH;
  double? targetKcal, targetProtein, targetCarbs, targetFat, targetFiber;
  bool targetsEstimated;
  bool showWeight;
  bool showCalories;

  UserProfile({
    this.name = '',
    this.units = 'metric',
    this.goal = 'habits',
    this.birthYear,
    this.isFemale = true,
    this.pregnancyOrNursing = false,
    this.specializedGuidance = false,
    this.heightCm,
    this.startWeightKg,
    this.goalWeightKg,
    this.activityLevel = 'moderate',
    this.experience = 'beginner',
    List<String>? equipment,
    List<String>? dietary,
    List<String>? allergies,
    List<String>? avoidFoods,
    this.walkGoalSteps = 8000,
    this.waterGoalMl = 2000,
    this.sleepGoalH = 8,
    this.targetKcal,
    this.targetProtein,
    this.targetCarbs,
    this.targetFat,
    this.targetFiber,
    this.targetsEstimated = false,
    this.showWeight = true,
    this.showCalories = true,
  })  : equipment = equipment ?? [],
        dietary = dietary ?? [],
        allergies = allergies ?? [],
        avoidFoods = avoidFoods ?? [];

  int? get ageYears => birthYear == null ? null : DateTime.now().year - birthYear!;
  bool get isMinor => ageYears != null && ageYears! < 18;
  bool get allowEstimatedTargets =>
      !isMinor && !pregnancyOrNursing && !specializedGuidance;

  Map<String, dynamic> toJson() => {
        'name': name,
        'units': units,
        'goal': goal,
        'birthYear': birthYear,
        'isFemale': isFemale,
        'pregnancyOrNursing': pregnancyOrNursing,
        'specializedGuidance': specializedGuidance,
        'heightCm': heightCm,
        'startWeightKg': startWeightKg,
        'goalWeightKg': goalWeightKg,
        'activityLevel': activityLevel,
        'experience': experience,
        'equipment': equipment,
        'dietary': dietary,
        'allergies': allergies,
        'avoidFoods': avoidFoods,
        'walkGoalSteps': walkGoalSteps,
        'waterGoalMl': waterGoalMl,
        'sleepGoalH': sleepGoalH,
        'targetKcal': targetKcal,
        'targetProtein': targetProtein,
        'targetCarbs': targetCarbs,
        'targetFat': targetFat,
        'targetFiber': targetFiber,
        'targetsEstimated': targetsEstimated,
        'showWeight': showWeight,
        'showCalories': showCalories,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        name: j['name']?.toString() ?? '',
        units: j['units']?.toString() ?? 'metric',
        goal: j['goal']?.toString() ?? 'habits',
        birthYear: (j['birthYear'] as num?)?.toInt(),
        isFemale: _b(j['isFemale'], true),
        pregnancyOrNursing: _b(j['pregnancyOrNursing']),
        specializedGuidance: _b(j['specializedGuidance']),
        heightCm: (j['heightCm'] as num?)?.toDouble(),
        startWeightKg: (j['startWeightKg'] as num?)?.toDouble(),
        goalWeightKg: (j['goalWeightKg'] as num?)?.toDouble(),
        activityLevel: j['activityLevel']?.toString() ?? 'moderate',
        experience: j['experience']?.toString() ?? 'beginner',
        equipment: _sl(j['equipment']),
        dietary: _sl(j['dietary']),
        allergies: _sl(j['allergies']),
        avoidFoods: _sl(j['avoidFoods']),
        walkGoalSteps: _i(j['walkGoalSteps'], 8000),
        waterGoalMl: _d(j['waterGoalMl'], 2000),
        sleepGoalH: _d(j['sleepGoalH'], 8),
        targetKcal: (j['targetKcal'] as num?)?.toDouble(),
        targetProtein: (j['targetProtein'] as num?)?.toDouble(),
        targetCarbs: (j['targetCarbs'] as num?)?.toDouble(),
        targetFat: (j['targetFat'] as num?)?.toDouble(),
        targetFiber: (j['targetFiber'] as num?)?.toDouble(),
        targetsEstimated: _b(j['targetsEstimated']),
        showWeight: _b(j['showWeight'], true),
        showCalories: _b(j['showCalories'], true),
      );
}

class AppSettings {
  String themeMode; // system | light | dark
  bool reducedMotion;
  bool companionVisible;
  bool biometricLock;
  bool notifPreview; // show notification content on lock screen
  List<String> todayWidgets; // customizable Today summaries
  bool onboardingDone;

  AppSettings({
    this.themeMode = 'system',
    this.reducedMotion = false,
    this.companionVisible = true,
    this.biometricLock = false,
    this.notifPreview = true,
    List<String>? todayWidgets,
    this.onboardingDone = false,
  }) : todayWidgets = todayWidgets ??
            ['habits', 'nutrition', 'steps', 'water', 'sleep', 'timeline'];

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'reducedMotion': reducedMotion,
        'companionVisible': companionVisible,
        'biometricLock': biometricLock,
        'notifPreview': notifPreview,
        'todayWidgets': todayWidgets,
        'onboardingDone': onboardingDone,
      };
  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        themeMode: j['themeMode']?.toString() ?? 'system',
        reducedMotion: _b(j['reducedMotion']),
        companionVisible: _b(j['companionVisible'], true),
        biometricLock: _b(j['biometricLock']),
        notifPreview: _b(j['notifPreview'], true),
        todayWidgets: _sl(j['todayWidgets']).isEmpty
            ? ['habits', 'nutrition', 'steps', 'water', 'sleep', 'timeline']
            : _sl(j['todayWidgets']),
        onboardingDone: _b(j['onboardingDone']),
      );
}

// ------------------------------------------------------------ nutrition

/// Nutrition values, always per the stated grams.
class Nutrition {
  final double kcal, protein, carbs, fat, fiber;
  final double? sodiumMg, sugarG;
  final bool isEstimate;
  final String source; // e.g. 'USDA SR Legacy (approx.)', 'Label', 'Custom'

  const Nutrition({
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sodiumMg,
    this.sugarG,
    this.isEstimate = true,
    this.source = '',
  });

  Nutrition operator +(Nutrition o) => Nutrition(
        kcal: kcal + o.kcal,
        protein: protein + o.protein,
        carbs: carbs + o.carbs,
        fat: fat + o.fat,
        fiber: fiber + o.fiber,
        sodiumMg: (sodiumMg ?? 0) + (o.sodiumMg ?? 0),
        sugarG: (sugarG ?? 0) + (o.sugarG ?? 0),
        isEstimate: isEstimate || o.isEstimate,
        source: source,
      );

  Nutrition scaled(double f) => Nutrition(
        kcal: kcal * f,
        protein: protein * f,
        carbs: carbs * f,
        fat: fat * f,
        fiber: fiber * f,
        sodiumMg: sodiumMg == null ? null : sodiumMg! * f,
        sugarG: sugarG == null ? null : sugarG! * f,
        isEstimate: isEstimate,
        source: source,
      );

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodiumMg': sodiumMg,
        'sugarG': sugarG,
        'isEstimate': isEstimate,
        'source': source,
      };
  factory Nutrition.fromJson(Map<String, dynamic> j) => Nutrition(
        kcal: _d(j['kcal']),
        protein: _d(j['protein']),
        carbs: _d(j['carbs']),
        fat: _d(j['fat']),
        fiber: _d(j['fiber']),
        sodiumMg: (j['sodiumMg'] as num?)?.toDouble(),
        sugarG: (j['sugarG'] as num?)?.toDouble(),
        isEstimate: _b(j['isEstimate'], true),
        source: j['source']?.toString() ?? '',
      );
}

class ServingUnit {
  final String name; // 'cup', 'piece', 'tbsp'
  final double grams;
  const ServingUnit(this.name, this.grams);
  Map<String, dynamic> toJson() => {'name': name, 'grams': grams};
  factory ServingUnit.fromJson(Map<String, dynamic> j) =>
      ServingUnit(j['name'].toString(), _d(j['grams']));
}

/// Reference catalog entry (read-only seed data).
class CatalogFood {
  final String id;
  final String name;
  final String category;
  final bool filipino;
  final Nutrition per100g;
  final List<ServingUnit> units;

  const CatalogFood({
    required this.id,
    required this.name,
    required this.category,
    this.filipino = false,
    required this.per100g,
    this.units = const [],
  });
}

class FoodEntry {
  String id;
  String dateKey; // yyyy-MM-dd
  String meal; // breakfast | lunch | dinner | snack
  String name;
  String? catalogId;
  String? recipeId;
  double servingQty;
  String servingUnit; // unit name or 'g'
  double grams;
  Nutrition nutrition; // for [grams]
  DateTime loggedAt;

  FoodEntry({
    required this.id,
    required this.dateKey,
    required this.meal,
    required this.name,
    this.catalogId,
    this.recipeId,
    required this.servingQty,
    required this.servingUnit,
    required this.grams,
    required this.nutrition,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'meal': meal,
        'name': name,
        'catalogId': catalogId,
        'recipeId': recipeId,
        'servingQty': servingQty,
        'servingUnit': servingUnit,
        'grams': grams,
        'nutrition': nutrition.toJson(),
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory FoodEntry.fromJson(Map<String, dynamic> j) => FoodEntry(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        meal: j['meal'].toString(),
        name: j['name'].toString(),
        catalogId: j['catalogId']?.toString(),
        recipeId: j['recipeId']?.toString(),
        servingQty: _d(j['servingQty'], 1),
        servingUnit: j['servingUnit']?.toString() ?? 'g',
        grams: _d(j['grams']),
        nutrition: Nutrition.fromJson(_m(j['nutrition'] ?? {})),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class CustomFood {
  String id;
  String name;
  Nutrition per100g;
  List<ServingUnit> units;
  DateTime createdAt;

  CustomFood({
    required this.id,
    required this.name,
    required this.per100g,
    List<ServingUnit>? units,
    DateTime? createdAt,
  })  : units = units ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'per100g': per100g.toJson(),
        'units': units.map((u) => u.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };
  factory CustomFood.fromJson(Map<String, dynamic> j) => CustomFood(
        id: j['id'].toString(),
        name: j['name'].toString(),
        per100g: Nutrition.fromJson(_m(j['per100g'] ?? {})),
        units: ((j['units'] as List?) ?? []).map((e) => ServingUnit.fromJson(_m(e))).toList(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class RecipeIngredient {
  String foodId; // catalog id
  String foodName;
  double qty;
  String unit; // serving unit name or 'g'
  double grams;

  RecipeIngredient({
    required this.foodId,
    required this.foodName,
    required this.qty,
    required this.unit,
    required this.grams,
  });
  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'foodName': foodName,
        'qty': qty,
        'unit': unit,
        'grams': grams,
      };
  factory RecipeIngredient.fromJson(Map<String, dynamic> j) => RecipeIngredient(
        foodId: j['foodId'].toString(),
        foodName: j['foodName']?.toString() ?? '',
        qty: _d(j['qty'], 1),
        unit: j['unit']?.toString() ?? 'g',
        grams: _d(j['grams']),
      );
}

class Recipe {
  String id;
  String name;
  String description;
  int prepMin;
  int cookMin;
  int servings;
  List<RecipeIngredient> ingredients;
  List<String> steps;
  List<String> tags;
  List<String> allergens;
  bool isSeed;

  Recipe({
    required this.id,
    required this.name,
    this.description = '',
    this.prepMin = 0,
    this.cookMin = 0,
    this.servings = 2,
    List<RecipeIngredient>? ingredients,
    List<String>? steps,
    List<String>? tags,
    List<String>? allergens,
    this.isSeed = false,
  })  : ingredients = ingredients ?? [],
        steps = steps ?? [],
        tags = tags ?? [],
        allergens = allergens ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'prepMin': prepMin,
        'cookMin': cookMin,
        'servings': servings,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'tags': tags,
        'allergens': allergens,
        'isSeed': isSeed,
      };
  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
        id: j['id'].toString(),
        name: j['name'].toString(),
        description: j['description']?.toString() ?? '',
        prepMin: _i(j['prepMin']),
        cookMin: _i(j['cookMin']),
        servings: _i(j['servings'], 2),
        ingredients: ((j['ingredients'] as List?) ?? [])
            .map((e) => RecipeIngredient.fromJson(_m(e)))
            .toList(),
        steps: _sl(j['steps']),
        tags: _sl(j['tags']),
        allergens: _sl(j['allergens']),
        isSeed: _b(j['isSeed']),
      );
}

// ------------------------------------------------------- meal planning

class PlannedMeal {
  String meal; // breakfast | lunch | dinner | snack
  String kind; // recipe | food
  String refId;
  String name;
  double servings;

  PlannedMeal({
    required this.meal,
    required this.kind,
    required this.refId,
    required this.name,
    this.servings = 1,
  });
  Map<String, dynamic> toJson() => {
        'meal': meal,
        'kind': kind,
        'refId': refId,
        'name': name,
        'servings': servings,
      };
  factory PlannedMeal.fromJson(Map<String, dynamic> j) => PlannedMeal(
        meal: j['meal'].toString(),
        kind: j['kind'].toString(),
        refId: j['refId'].toString(),
        name: j['name'].toString(),
        servings: _d(j['servings'], 1),
      );
}

class GroceryItem {
  String id;
  String name;
  double qty;
  String unit;
  String category;
  bool checked;
  String? recipeId;

  GroceryItem({
    required this.id,
    required this.name,
    this.qty = 1,
    this.unit = '',
    this.category = 'Other',
    this.checked = false,
    this.recipeId,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'unit': unit,
        'category': category,
        'checked': checked,
        'recipeId': recipeId,
      };
  factory GroceryItem.fromJson(Map<String, dynamic> j) => GroceryItem(
        id: j['id'].toString(),
        name: j['name'].toString(),
        qty: _d(j['qty'], 1),
        unit: j['unit']?.toString() ?? '',
        category: j['category']?.toString() ?? 'Other',
        checked: _b(j['checked']),
        recipeId: j['recipeId']?.toString(),
      );
}

class PantryItem {
  String id;
  String name;
  double qty;
  String unit;
  String? expiryKey; // yyyy-MM-dd
  DateTime addedAt;

  PantryItem({
    required this.id,
    required this.name,
    this.qty = 1,
    this.unit = '',
    this.expiryKey,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'unit': unit,
        'expiryKey': expiryKey,
        'addedAt': addedAt.toIso8601String(),
      };
  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: j['id'].toString(),
        name: j['name'].toString(),
        qty: _d(j['qty'], 1),
        unit: j['unit']?.toString() ?? '',
        expiryKey: j['expiryKey']?.toString(),
        addedAt: DateTime.tryParse(j['addedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ------------------------------------------------------------ progress

class WeightEntry {
  String id;
  String dateKey;
  double weightKg;
  String note;
  DateTime loggedAt;

  WeightEntry({
    required this.id,
    required this.dateKey,
    required this.weightKg,
    this.note = '',
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'weightKg': weightKg,
        'note': note,
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory WeightEntry.fromJson(Map<String, dynamic> j) => WeightEntry(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        weightKg: _d(j['weightKg']),
        note: j['note']?.toString() ?? '',
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class BodyMeasure {
  String id;
  String dateKey;
  String type; // waist | hips | chest | arm | thigh | neck
  double valueCm;
  String note;

  BodyMeasure({
    required this.id,
    required this.dateKey,
    required this.type,
    required this.valueCm,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'type': type,
        'valueCm': valueCm,
        'note': note,
      };
  factory BodyMeasure.fromJson(Map<String, dynamic> j) => BodyMeasure(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        type: j['type'].toString(),
        valueCm: _d(j['valueCm']),
        note: j['note']?.toString() ?? '',
      );
}

class ProgressPhoto {
  String id;
  String dateKey;
  String path; // local file path
  String note;
  DateTime takenAt;

  ProgressPhoto({
    required this.id,
    required this.dateKey,
    required this.path,
    this.note = '',
    DateTime? takenAt,
  }) : takenAt = takenAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'path': path,
        'note': note,
        'takenAt': takenAt.toIso8601String(),
      };
  factory ProgressPhoto.fromJson(Map<String, dynamic> j) => ProgressPhoto(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        path: j['path'].toString(),
        note: j['note']?.toString() ?? '',
        takenAt: DateTime.tryParse(j['takenAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ----------------------------------------------------------------- move

class CatalogExercise {
  final String id;
  final String name;
  final List<String> muscles;
  final List<String> equipment;
  final String difficulty; // beginner | intermediate | advanced
  final String type; // strength | cardio | mobility | stretch
  final String instructions;
  final String tips;

  const CatalogExercise({
    required this.id,
    required this.name,
    required this.muscles,
    required this.equipment,
    required this.difficulty,
    required this.type,
    required this.instructions,
    this.tips = '',
  });
}

class WorkoutSet {
  double? reps;
  double? weightKg;
  int? durationSec;
  int? rpe; // 1..10 optional effort

  WorkoutSet({this.reps, this.weightKg, this.durationSec, this.rpe});
  Map<String, dynamic> toJson() => {
        'reps': reps,
        'weightKg': weightKg,
        'durationSec': durationSec,
        'rpe': rpe,
      };
  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
        reps: (j['reps'] as num?)?.toDouble(),
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        durationSec: (j['durationSec'] as num?)?.toInt(),
        rpe: (j['rpe'] as num?)?.toInt(),
      );
}

class WorkoutBlock {
  String exerciseId;
  String exerciseName;
  List<WorkoutSet> sets;
  int restSec;

  WorkoutBlock({
    required this.exerciseId,
    required this.exerciseName,
    List<WorkoutSet>? sets,
    this.restSec = 60,
  }) : sets = sets ?? [];

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets.map((s) => s.toJson()).toList(),
        'restSec': restSec,
      };
  factory WorkoutBlock.fromJson(Map<String, dynamic> j) => WorkoutBlock(
        exerciseId: j['exerciseId'].toString(),
        exerciseName: j['exerciseName']?.toString() ?? '',
        sets: ((j['sets'] as List?) ?? []).map((e) => WorkoutSet.fromJson(_m(e))).toList(),
        restSec: _i(j['restSec'], 60),
      );
}

class WorkoutTemplate {
  String id;
  String name;
  String level; // beginner | intermediate | advanced
  int estMinutes;
  List<WorkoutBlock> blocks;
  List<String> scheduledWeekdays; // 1..7 (Mon..Sun)

  WorkoutTemplate({
    required this.id,
    required this.name,
    this.level = 'beginner',
    this.estMinutes = 30,
    List<WorkoutBlock>? blocks,
    List<String>? scheduledWeekdays,
  })  : blocks = blocks ?? [],
        scheduledWeekdays = scheduledWeekdays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'estMinutes': estMinutes,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'scheduledWeekdays': scheduledWeekdays,
      };
  factory WorkoutTemplate.fromJson(Map<String, dynamic> j) => WorkoutTemplate(
        id: j['id'].toString(),
        name: j['name'].toString(),
        level: j['level']?.toString() ?? 'beginner',
        estMinutes: _i(j['estMinutes'], 30),
        blocks: ((j['blocks'] as List?) ?? []).map((e) => WorkoutBlock.fromJson(_m(e))).toList(),
        scheduledWeekdays: _sl(j['scheduledWeekdays']),
      );
}

class WorkoutSession {
  String id;
  String dateKey;
  String name;
  String? templateId;
  List<WorkoutBlock> blocks;
  int durationSec;
  double? kcalEstimate; // approximate, kept separate from food
  String notes;
  DateTime completedAt;

  WorkoutSession({
    required this.id,
    required this.dateKey,
    required this.name,
    this.templateId,
    List<WorkoutBlock>? blocks,
    this.durationSec = 0,
    this.kcalEstimate,
    this.notes = '',
    DateTime? completedAt,
  })  : blocks = blocks ?? [],
        completedAt = completedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'name': name,
        'templateId': templateId,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'durationSec': durationSec,
        'kcalEstimate': kcalEstimate,
        'notes': notes,
        'completedAt': completedAt.toIso8601String(),
      };
  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        name: j['name'].toString(),
        templateId: j['templateId']?.toString(),
        blocks: ((j['blocks'] as List?) ?? []).map((e) => WorkoutBlock.fromJson(_m(e))).toList(),
        durationSec: _i(j['durationSec']),
        kcalEstimate: (j['kcalEstimate'] as num?)?.toDouble(),
        notes: j['note']?.toString() ?? j['notes']?.toString() ?? '',
        completedAt: DateTime.tryParse(j['completedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class WalkSession {
  String id;
  String dateKey;
  DateTime startedAt;
  DateTime? endedAt;
  int durationSec;
  int steps;
  double distanceM;
  String source; // timer | manual | device
  bool indoor;
  String note;

  WalkSession({
    required this.id,
    required this.dateKey,
    required this.startedAt,
    this.endedAt,
    this.durationSec = 0,
    this.steps = 0,
    this.distanceM = 0,
    this.source = 'timer',
    this.indoor = false,
    this.note = '',
  });

  bool get finished => endedAt != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'durationSec': durationSec,
        'steps': steps,
        'distanceM': distanceM,
        'source': source,
        'indoor': indoor,
        'note': note,
      };
  factory WalkSession.fromJson(Map<String, dynamic> j) => WalkSession(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        startedAt: DateTime.tryParse(j['startedAt']?.toString() ?? '') ?? DateTime.now(),
        endedAt: j['endedAt'] == null ? null : DateTime.tryParse(j['endedAt'].toString()),
        durationSec: _i(j['durationSec']),
        steps: _i(j['steps']),
        distanceM: _d(j['distanceM']),
        source: j['source']?.toString() ?? 'timer',
        indoor: _b(j['indoor']),
        note: j['note']?.toString() ?? '',
      );
}

// -------------------------------------------------------------- wellness

class WaterLog {
  String id;
  String dateKey;
  double ml;
  DateTime loggedAt;
  WaterLog({required this.id, required this.dateKey, required this.ml, DateTime? loggedAt})
      : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'ml': ml,
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory WaterLog.fromJson(Map<String, dynamic> j) => WaterLog(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        ml: _d(j['ml']),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class SleepLog {
  String id;
  String dateKey; // the morning the user woke
  String bedtime; // HH:mm
  String wakeTime; // HH:mm
  int quality; // 1..5
  String note;
  SleepLog({
    required this.id,
    required this.dateKey,
    required this.bedtime,
    required this.wakeTime,
    this.quality = 3,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'bedtime': bedtime,
        'wakeTime': wakeTime,
        'quality': quality,
        'note': note,
      };
  factory SleepLog.fromJson(Map<String, dynamic> j) => SleepLog(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        bedtime: j['bedtime'].toString(),
        wakeTime: j['wakeTime'].toString(),
        quality: _i(j['quality'], 3),
        note: j['note']?.toString() ?? '',
      );
}

class MoodLog {
  String id;
  String dateKey;
  DateTime loggedAt;
  int mood; // 1..5
  int energy; // 1..5
  List<String> tags;
  String note;
  MoodLog({
    required this.id,
    required this.dateKey,
    DateTime? loggedAt,
    this.mood = 3,
    this.energy = 3,
    List<String>? tags,
    this.note = '',
  })  : loggedAt = loggedAt ?? DateTime.now(),
        tags = tags ?? [];
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'loggedAt': loggedAt.toIso8601String(),
        'mood': mood,
        'energy': energy,
        'tags': tags,
        'note': note,
      };
  factory MoodLog.fromJson(Map<String, dynamic> j) => MoodLog(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
        mood: _i(j['mood'], 3),
        energy: _i(j['energy'], 3),
        tags: _sl(j['tags']),
        note: j['note']?.toString() ?? '',
      );
}

class JournalEntry {
  String id;
  String dateKey;
  DateTime loggedAt;
  String text;
  String? gratitude;
  JournalEntry({
    required this.id,
    required this.dateKey,
    DateTime? loggedAt,
    this.text = '',
    this.gratitude,
  }) : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'loggedAt': loggedAt.toIso8601String(),
        'text': text,
        'gratitude': gratitude,
      };
  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
        text: j['text']?.toString() ?? '',
        gratitude: j['gratitude']?.toString(),
      );
}

class BreathingSession {
  String id;
  String dateKey;
  String pattern; // e.g. '4-4-6'
  int cycles;
  int durationSec;
  DateTime loggedAt;
  BreathingSession({
    required this.id,
    required this.dateKey,
    required this.pattern,
    required this.cycles,
    required this.durationSec,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'pattern': pattern,
        'cycles': cycles,
        'durationSec': durationSec,
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory BreathingSession.fromJson(Map<String, dynamic> j) => BreathingSession(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        pattern: j['pattern'].toString(),
        cycles: _i(j['cycles']),
        durationSec: _i(j['durationSec']),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class CheckIn {
  String id;
  String dateKey;
  int energy; // 1..5
  int soreness; // 1..5
  String note;
  CheckIn({
    required this.id,
    required this.dateKey,
    this.energy = 3,
    this.soreness = 1,
    this.note = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'energy': energy,
        'soreness': soreness,
        'note': note,
      };
  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        energy: _i(j['energy'], 3),
        soreness: _i(j['soreness'], 1),
        note: j['note']?.toString() ?? '',
      );
}

// ---------------------------------------------------------- health log

class HealthNote {
  String id;
  String dateKey;
  String kind; // symptom | note
  String text;
  int? severity; // 1..5 for symptoms
  DateTime loggedAt;
  HealthNote({
    required this.id,
    required this.dateKey,
    this.kind = 'note',
    this.text = '',
    this.severity,
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'kind': kind,
        'text': text,
        'severity': severity,
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory HealthNote.fromJson(Map<String, dynamic> j) => HealthNote(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        kind: j['kind']?.toString() ?? 'note',
        text: j['text']?.toString() ?? '',
        severity: (j['severity'] as num?)?.toInt(),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

class Medication {
  String id;
  String name;
  String dose;
  String schedule; // e.g. 'Morning, Evening'
  String notes;
  bool active;
  Medication({
    required this.id,
    required this.name,
    this.dose = '',
    this.schedule = '',
    this.notes = '',
    this.active = true,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dose': dose,
        'schedule': schedule,
        'notes': notes,
        'active': active,
      };
  factory Medication.fromJson(Map<String, dynamic> j) => Medication(
        id: j['id'].toString(),
        name: j['name'].toString(),
        dose: j['dose']?.toString() ?? '',
        schedule: j['schedule']?.toString() ?? '',
        notes: j['notes']?.toString() ?? '',
        active: _b(j['active'], true),
      );
}

class MedLog {
  String id;
  String medId;
  String dateKey;
  DateTime loggedAt;
  bool taken;
  MedLog({
    required this.id,
    required this.medId,
    required this.dateKey,
    DateTime? loggedAt,
    required this.taken,
  }) : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'medId': medId,
        'dateKey': dateKey,
        'loggedAt': loggedAt.toIso8601String(),
        'taken': taken,
      };
  factory MedLog.fromJson(Map<String, dynamic> j) => MedLog(
        id: j['id'].toString(),
        medId: j['medId'].toString(),
        dateKey: j['dateKey'].toString(),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
        taken: _b(j['taken']),
      );
}

class Appointment {
  String id;
  String title;
  String dateKey;
  String time; // HH:mm
  String location;
  String notes;
  Appointment({
    required this.id,
    required this.title,
    required this.dateKey,
    this.time = '',
    this.location = '',
    this.notes = '',
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateKey': dateKey,
        'time': time,
        'location': location,
        'notes': notes,
      };
  factory Appointment.fromJson(Map<String, dynamic> j) => Appointment(
        id: j['id'].toString(),
        title: j['title'].toString(),
        dateKey: j['dateKey'].toString(),
        time: j['time']?.toString() ?? '',
        location: j['location']?.toString() ?? '',
        notes: j['notes']?.toString() ?? '',
      );
}

class HealthMetric {
  String id;
  String dateKey;
  String kind; // bp | glucose | other
  double value1;
  double? value2;
  String unit;
  String note;
  DateTime loggedAt;
  HealthMetric({
    required this.id,
    required this.dateKey,
    required this.kind,
    required this.value1,
    this.value2,
    this.unit = '',
    this.note = '',
    DateTime? loggedAt,
  }) : loggedAt = loggedAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'kind': kind,
        'value1': value1,
        'value2': value2,
        'unit': unit,
        'note': note,
        'loggedAt': loggedAt.toIso8601String(),
      };
  factory HealthMetric.fromJson(Map<String, dynamic> j) => HealthMetric(
        id: j['id'].toString(),
        dateKey: j['dateKey'].toString(),
        kind: j['kind']?.toString() ?? 'other',
        value1: _d(j['value1']),
        value2: (j['value2'] as num?)?.toDouble(),
        unit: j['unit']?.toString() ?? '',
        note: j['note']?.toString() ?? '',
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ----------------------------------------------------- motivation/chat

class Challenge {
  String id;
  String name;
  String type; // walk | water | workout | sleep | mood | custom
  double target;
  String unit;
  String startKey;
  String endKey;
  bool active;
  Challenge({
    required this.id,
    required this.name,
    required this.type,
    required this.target,
    this.unit = '',
    required this.startKey,
    required this.endKey,
    this.active = true,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'target': target,
        'unit': unit,
        'startKey': startKey,
        'endKey': endKey,
        'active': active,
      };
  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
        id: j['id'].toString(),
        name: j['name'].toString(),
        type: j['type'].toString(),
        target: _d(j['target']),
        unit: j['unit']?.toString() ?? '',
        startKey: j['startKey'].toString(),
        endKey: j['endKey'].toString(),
        active: _b(j['active'], true),
      );
}

class ChatMessage {
  String id;
  String role; // user | pip
  String text;
  DateTime at;
  String? actionKind; // water | meal | walk | workout | breathing | reminder
  String? actionLabel;
  Map<String, dynamic>? actionData;
  bool actionDone;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    DateTime? at,
    this.actionKind,
    this.actionLabel,
    this.actionData,
    this.actionDone = false,
  }) : at = at ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'text': text,
        'at': at.toIso8601String(),
        'actionKind': actionKind,
        'actionLabel': actionLabel,
        'actionData': actionData,
        'actionDone': actionDone,
      };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'].toString(),
        role: j['role'].toString(),
        text: j['text'].toString(),
        at: DateTime.tryParse(j['at']?.toString() ?? '') ?? DateTime.now(),
        actionKind: j['actionKind']?.toString(),
        actionLabel: j['actionLabel']?.toString(),
        actionData: j['actionData'] == null ? null : _m(j['actionData']),
        actionDone: _b(j['actionDone']),
      );
}

class ReminderItem {
  String id;
  String title;
  String body;
  String time; // HH:mm
  List<int> weekdays; // 1..7, empty = daily
  bool enabled;
  String kind; // water | sleep | med | walk | custom
  String? payload; // medId etc.

  ReminderItem({
    required this.id,
    required this.title,
    this.body = '',
    required this.time,
    List<int>? weekdays,
    this.enabled = true,
    this.kind = 'custom',
    this.payload,
  }) : weekdays = weekdays ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'time': time,
        'weekdays': weekdays,
        'enabled': enabled,
        'kind': kind,
        'payload': payload,
      };
  factory ReminderItem.fromJson(Map<String, dynamic> j) => ReminderItem(
        id: j['id'].toString(),
        title: j['title'].toString(),
        body: j['body']?.toString() ?? '',
        time: j['time'].toString(),
        weekdays: ((j['weekdays'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
        enabled: _b(j['enabled'], true),
        kind: j['kind']?.toString() ?? 'custom',
        payload: j['payload']?.toString(),
      );
}

/// Companion accessory unlock.
class Accessory {
  final String id;
  final String name;
  final String requirement;
  const Accessory(this.id, this.name, this.requirement);
}

const kAccessories = [
  Accessory('sprout', 'Sprout', 'Worn from day one'),
  Accessory('flower', 'Flower crown', 'Log something 3 days in a row'),
  Accessory('star', 'Star badge', 'Complete 5 workouts or walks'),
  Accessory('scarf', 'Cozy scarf', 'Reach a 14-day logging streak'),
];
