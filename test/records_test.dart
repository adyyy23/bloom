import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bloom/companion/edit_measurements_sheet.dart';
import 'package:bloom/companion/human_visualizer.dart';
import 'package:bloom/companion/human_body_mesh.dart';
import 'package:bloom/core/theme.dart';
import 'package:bloom/core/widgets.dart';
import 'package:bloom/data/database.dart';
import 'package:bloom/data/models.dart';
import 'package:bloom/data/repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('bloom-records');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path);
    await Database.init();
  });
  tearDownAll(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
      await temp.delete(recursive: true);
    });
  });
  test(
      'Meals, calories, weight, workouts, walks, sleep and journal survive reload',
      () async {
    const day = '2026-09-30';
    final food = FoodRepo()..load();
    await food.addEntry(FoodEntry(
        id: 'qa-meal',
        dateKey: day,
        meal: 'breakfast',
        name: 'Test meal',
        servingQty: 1,
        servingUnit: 'g',
        grams: 100,
        nutrition: const Nutrition(kcal: 220, protein: 12)));
    final move = MoveRepo()..load();
    await move.addSession(WorkoutSession(
        id: 'qa-workout',
        dateKey: day,
        name: 'Test workout',
        durationSec: 600));
    await move.addManualWalk(WalkSession(
        id: 'qa-walk',
        dateKey: day,
        startedAt: DateTime(2026, 9, 30),
        endedAt: DateTime(2026, 9, 30, 0, 10),
        durationSec: 600,
        steps: 1000,
        distanceM: 700,
        source: 'manual'));
    final wellness = WellnessRepo()..load();
    await wellness.addWater(250, dateKey: day);
    await wellness.saveSleep(SleepLog(
        id: 'qa-sleep', dateKey: day, bedtime: '23:00', wakeTime: '07:00'));
    await wellness.saveJournal(
        JournalEntry(id: 'qa-journal', dateKey: day, text: 'A steady day.'));
    await (ProgressRepo()..load())
        .addWeight(WeightEntry(id: 'qa-weight', dateKey: day, weightKg: 65));
    expect((FoodRepo()..load()).dayNutrition(day).kcal, 220);
    expect((MoveRepo()..load()).sessionsFor(day).single.durationSec, 600);
    expect((MoveRepo()..load()).displaySteps(day).value, 1000);
    expect((WellnessRepo()..load()).waterTotal(day), 250);
    expect((WellnessRepo()..load()).sleepFor(day)!.wakeTime, '07:00');
    expect(
        (WellnessRepo()..load()).journalEntries.single.text, 'A steady day.');
    expect((ProgressRepo()..load()).latest!.weightKg, 65);
  });
  testWidgets(
      'Imperial measurements convert correctly and unchanged saves do not duplicate logs',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    c.read(profileRepoProvider).load();
    c.read(progressRepoProvider).load();
    await tester.runAsync(() => c.read(profileRepoProvider).save(
        UserProfile(heightCm: 170, startWeightKg: 65, units: 'imperial')));
    await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
            theme: BloomTheme.light(),
            home: Scaffold(
                body: Builder(
                    builder: (ctx) => TextButton(
                        onPressed: () =>
                            showBubbleSheet(ctx, const EditMeasurementsSheet()),
                        child: const Text('Open')))))));
    Future<void> advance() async {
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump();
    }

    await tester.tap(find.text('Open'));
    await advance();
    final count = Database.weights.length;
    await tester.ensureVisible(find.text('Save measurements'));
    await tester.pump();
    await tester.runAsync(() => tester.tap(find.text('Save measurements')));
    await advance();
    expect(Database.weights.length, count);
    await tester.tap(find.text('Open'));
    await advance();
    await tester.enterText(find.byType(TextFormField).at(0), '154.32');
    await tester.enterText(find.byType(TextFormField).at(1), '66.93');
    await tester.ensureVisible(find.text('Save measurements'));
    await tester.pump();
    await tester.runAsync(() => tester.tap(find.text('Save measurements')));
    await advance();
    expect(c.read(progressRepoProvider).latest!.weightKg, closeTo(70, .01));
    expect(c.read(profileRepoProvider).profile.heightCm, closeTo(170, .03));
    expect(Database.weights.length, count + 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('320px dark and 768px stage fit extreme supported morphs',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    for (final width in [320.0, 768.0]) {
      tester.view.physicalSize = Size(width, 844);
      await tester.pumpWidget(MaterialApp(
          theme: BloomTheme.dark(),
          home: const Scaffold(
              body: HumanVisualizer(
                  stageHeight: 390,
                  heightCm: 215,
                  weightKg: 185,
                  reducedMotion: true,
                  config: AvatarConfig(frame: BodyFrame.broad)))));
      await tester.pump();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Back'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
