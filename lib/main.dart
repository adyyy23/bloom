import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/database.dart';
import 'data/repositories.dart';
import 'data/seed_recipes.dart';
import 'core/notifications.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Database.init();
  RecipeRepo.registerSeed(buildSeedRecipes());
  await NotificationService.init();
  runApp(const ProviderScope(child: BloomApp()));
}
