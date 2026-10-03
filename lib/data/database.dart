import 'package:hive_flutter/hive_flutter.dart';

/// Structured local storage with a versioned migration strategy.
///
/// Each domain gets a typed box of plain maps. [schemaVersion] is stored in
/// the `meta` box; [migrate] runs on startup and upgrades older layouts.
/// Nothing here touches the network — core logging works fully offline.
class Database {
  Database._();
  static const int schemaVersion = 3;
  static bool _ready = false;

  static late Box meta;
  static late Box profile;
  static late Box settings;
  static late Box foodEntries;
  static late Box customFoods;
  static late Box favorites;
  static late Box recipes;
  static late Box mealPlans;
  static late Box grocery;
  static late Box pantry;
  static late Box weights;
  static late Box measures;
  static late Box photos;
  static late Box templates;
  static late Box sessions;
  static late Box walks;
  static late Box stepDays;
  static late Box water;
  static late Box sleep;
  static late Box mood;
  static late Box journal;
  static late Box breathing;
  static late Box checkins;
  static late Box healthNotes;
  static late Box meds;
  static late Box medLogs;
  static late Box appointments;
  static late Box metrics;
  static late Box challenges;
  static late Box achievements;
  static late Box chat;
  static late Box reminders;
  static late Box misc;

  static Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter('bloom');
    meta = await Hive.openBox('meta');
    profile = await Hive.openBox('profile');
    settings = await Hive.openBox('settings');
    foodEntries = await Hive.openBox('foodEntries');
    customFoods = await Hive.openBox('customFoods');
    favorites = await Hive.openBox('favorites');
    recipes = await Hive.openBox('recipes');
    mealPlans = await Hive.openBox('mealPlans');
    grocery = await Hive.openBox('grocery');
    pantry = await Hive.openBox('pantry');
    weights = await Hive.openBox('weights');
    measures = await Hive.openBox('measures');
    photos = await Hive.openBox('photos');
    templates = await Hive.openBox('templates');
    sessions = await Hive.openBox('sessions');
    walks = await Hive.openBox('walks');
    stepDays = await Hive.openBox('stepDays');
    water = await Hive.openBox('water');
    sleep = await Hive.openBox('sleep');
    mood = await Hive.openBox('mood');
    journal = await Hive.openBox('journal');
    breathing = await Hive.openBox('breathing');
    checkins = await Hive.openBox('checkins');
    healthNotes = await Hive.openBox('healthNotes');
    meds = await Hive.openBox('meds');
    medLogs = await Hive.openBox('medLogs');
    appointments = await Hive.openBox('appointments');
    metrics = await Hive.openBox('metrics');
    challenges = await Hive.openBox('challenges');
    achievements = await Hive.openBox('achievements');
    chat = await Hive.openBox('chat');
    reminders = await Hive.openBox('reminders');
    misc = await Hive.openBox('misc');
    await _migrate();
    _ready = true;
  }

  static Future<void> _migrate() async {
    final current = (meta.get('schemaVersion') as num?)?.toInt() ?? 0;
    if (current >= schemaVersion) return;

    // v1 -> v2: stepDays keys normalized to yyyy-MM-dd; drop legacy demo keys.
    if (current < 2) {
      final bad = stepDays.keys.where((k) => k is! String || !(k).contains('-')).toList();
      for (final k in bad) {
        await stepDays.delete(k);
      }
    }
    // v2 -> v3: ensure single-doc boxes hold maps; seed misc defaults.
    if (current < 3) {
      if (!misc.containsKey('accessories')) {
        await misc.put('accessories', <String>['sprout']);
      }
      if (!misc.containsKey('streakFreezes')) {
        await misc.put('streakFreezes', 0);
      }
    }

    await meta.put('schemaVersion', schemaVersion);
  }

  /// Export every box as a JSON-serializable map (used for backup/export).
  static Map<String, dynamic> exportAll() {
    Map<String, dynamic> box(Box b) => {for (final k in b.keys) k.toString(): b.get(k)};
    return {
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': box(profile),
      'settings': box(settings),
      'foodEntries': box(foodEntries),
      'customFoods': box(customFoods),
      'favorites': box(favorites),
      'recipes': box(recipes),
      'mealPlans': box(mealPlans),
      'grocery': box(grocery),
      'pantry': box(pantry),
      'weights': box(weights),
      'measures': box(measures),
      'photos': box(photos),
      'templates': box(templates),
      'sessions': box(sessions),
      'walks': box(walks),
      'stepDays': box(stepDays),
      'water': box(water),
      'sleep': box(sleep),
      'mood': box(mood),
      'journal': box(journal),
      'breathing': box(breathing),
      'checkins': box(checkins),
      'healthNotes': box(healthNotes),
      'meds': box(meds),
      'medLogs': box(medLogs),
      'appointments': box(appointments),
      'metrics': box(metrics),
      'challenges': box(challenges),
      'achievements': box(achievements),
      'chat': box(chat),
      'reminders': box(reminders),
      'misc': box(misc),
    };
  }

  /// Delete all personal records. Photos referenced on disk are left for the
  /// caller to remove; settings/profile are cleared too.
  static Future<void> deleteAll() async {
    for (final b in [
      profile, settings, foodEntries, customFoods, favorites, recipes,
      mealPlans, grocery, pantry, weights, measures, photos, templates,
      sessions, walks, stepDays, water, sleep, mood, journal, breathing,
      checkins, healthNotes, meds, medLogs, appointments, metrics,
      challenges, achievements, chat, reminders, misc,
    ]) {
      await b.clear();
    }
    await meta.put('schemaVersion', schemaVersion);
  }
}
