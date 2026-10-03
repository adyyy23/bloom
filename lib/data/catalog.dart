import 'models.dart';
import '../core/utils.dart';
import 'seed_foods.dart';
import 'seed_exercises.dart';

/// Read-only reference catalogs (seed data), kept separate from personal records.
CatalogFood? findFood(String id) =>
    kCatalogFoods.where((f) => f.id == id).firstOrNull;

CatalogExercise? findExercise(String id) =>
    kCatalogExercises.where((e) => e.id == id).firstOrNull;

List<CatalogFood> get catalogFoods => kCatalogFoods;
List<CatalogExercise> get catalogExercises => kCatalogExercises;
