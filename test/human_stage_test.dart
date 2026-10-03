import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:bloom/companion/sculpted_human.dart';
import 'package:bloom/companion/human_body_mesh.dart';
import 'package:bloom/companion/human_visualizer.dart';
import 'package:bloom/companion/edit_measurements_sheet.dart';
import 'package:bloom/core/theme.dart';
import 'package:bloom/core/utils.dart';
import 'package:bloom/data/database.dart';
import 'package:bloom/data/models.dart';
import 'package:bloom/data/repositories.dart';
import 'package:bloom/features/shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temp;
  setUpAll(() async {
    for (final weight in [400, 600, 700, 800]) {
      final loader = FontLoader('Nunito')
        ..addFont(rootBundle.load('assets/fonts/nunito-$weight.ttf'));
      await loader.load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    temp = await Directory.systemTemp.createTemp('bloom-stage-test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => temp.path);
    await Database.init();
    await Database.profile.put(
        'profile',
        UserProfile(
                name: 'Alex',
                heightCm: 170,
                startWeightKg: 65,
                goalWeightKg: 60,
                birthYear: 1990)
            .toJson());
    await Database.settings.put('settings',
        AppSettings(onboardingDone: true, reducedMotion: true).toJson());
  });
  tearDownAll(() async {
    await TestWidgetsFlutterBinding.instance.runAsync(() async {
      await Hive.close();
      await temp.delete(recursive: true);
    });
  });
  test('Adult BMI boundaries, missing age and nonfinite values', () {
    for (final pair in [
      (18.49, 'Underweight'),
      (18.5, 'Standard range'),
      (24.99, 'Standard range'),
      (25.0, 'Overweight'),
      (29.99, 'Overweight'),
      (30.0, 'Obesity')
    ]) {
      expect(
          Calc.calculateBmi(
                  weightKg: pair.$1 * 4, heightCm: 200, birthYear: 1990)!
              .category,
          pair.$2);
    }
    expect(Calc.calculateBmi(weightKg: 60, heightCm: 170)!.isApplicable, false);
    expect(
        Calc.calculateBmi(
                weightKg: 60,
                heightCm: 170,
                birthYear: DateTime.now().year - 19)!
            .isApplicable,
        false);
    expect(Calc.calculateBmi(weightKg: double.nan, heightCm: 170), isNull);
  });
  test('Each hair and accessory has valid geometry; bounded morph keeps head',
      () async {
    final model = await SculptedHuman.load();
    for (final hair in HairStyle.values) {
      for (final accessory in AvatarAccessory.values) {
        final g =
            model.geometry(AvatarConfig(hairStyle: hair, accessory: accessory));
        expect(g.faces.length, greaterThan(11000));
        for (final config in [
          const AvatarConfig(),
          const AvatarConfig(
              frame: BodyFrame.broad,
              waistCm: 120,
              clothingStyle: ClothingStyle.relaxedSet)
        ]) {
          final d = g.deform(heightCm: 215, weightKg: 185, config: config);
          expect(d.every((v) => v.x.isFinite && v.y.isFinite && v.z.isFinite),
              true);
          expect(d.map((v) => v.x.abs()).reduce((a, b) => a > b ? a : b),
              lessThan(50));
        }
      }
    }
  });
  testWidgets(
      '3D front, side, back and customized stage renders without exceptions',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      if (Platform.environment['BLOOM_CAPTURE'] != '1') return;
      await tester.runAsync(() async {
        final image = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('docs/review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(MaterialApp(
        theme: BloomTheme.light(),
        home: Scaffold(
            body: RepaintBoundary(
                key: boundary,
                child: Container(
                    color: BloomColors.heroPeach,
                    child: const HumanVisualizer(
                        heightCm: 170,
                        weightKg: 65,
                        config: AvatarConfig(),
                        reducedMotion: true,
                        stageHeight: 390))))));
    await tester.runAsync(() => SculptedHuman.load());
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await capture('front');
    for (final v in ['Side', 'Back']) {
      await tester.tap(find.text(v));
      await tester.pump();
      await capture(v.toLowerCase());
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(MaterialApp(
        theme: BloomTheme.light(),
        home: Scaffold(
            body: RepaintBoundary(
                key: boundary,
                child: Container(
                    color: BloomColors.heroPeach,
                    child: const HumanVisualizer(
                        heightCm: 170,
                        weightKg: 65,
                        reducedMotion: true,
                        config: AvatarConfig(
                            hairStyle: HairStyle.softCurls,
                            skinTone: SkinTone.deepBronze,
                            clothingStyle: ClothingStyle.fullBodyFit,
                            accessory: AvatarAccessory.glasses),
                        stageHeight: 390))))));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Front'));
    await tester.pump();
    await capture('customized');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Appearance save/reload and cancel leave all measurements untouched',
      (tester) async {
    final before = Database.weights.length;
    final measures = Database.measures.length;
    final profile = Database.profile.get('profile');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(profileRepoProvider).load();
    container.read(settingsRepoProvider).load();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: BloomTheme.light(),
            home: Scaffold(
                body: Builder(
                    builder: (ctx) => TextButton(
                        onPressed: () => showModalBottomSheet(
                            context: ctx,
                            isScrollControlled: true,
                            builder: (_) => const SingleChildScrollView(
                                child: AppearanceSheet())),
                        child: const Text('Open')))))));
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Glasses'));
    await tester.pump();
    await tester.tap(find.text('Glasses'));
    await tester.pump();
    await tester.ensureVisible(find.text('Save appearance'));
    await tester.pump();
    await tester.runAsync(() => tester.tap(find.text('Save appearance')));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    final reloaded = AvatarRepo()..load();
    expect(reloaded.config.accessory, AvatarAccessory.glasses);
    expect(Database.weights.length, before);
    expect(Database.measures.length, measures);
    expect(Database.profile.get('profile'), profile);
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.ensureVisible(find.text('Reset appearance'));
    await tester.pump();
    await tester.tap(find.text('Reset appearance'));
    await tester.pump();
    await tester.ensureVisible(find.text('Cancel'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect((AvatarRepo()..load()).config.accessory, AvatarAccessory.glasses);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Shell Today and Wellness fit mobile width and preserve goal isolation',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(profileRepoProvider).load();
    container.read(settingsRepoProvider).load();
    final boundary = GlobalKey();
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
            theme: BloomTheme.light(),
            home: RepaintBoundary(key: boundary, child: const Shell()))));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    if (Platform.environment['BLOOM_CAPTURE'] == '1') {
      await tester.runAsync(() async {
        final im = await (boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
        final bytes = await im.toByteData(format: ui.ImageByteFormat.png);
        await File('docs/review/after.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        im.dispose();
      });
    }
    final count = Database.weights.length;
    await tester.tap(find.text('Illustrative goal'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(Database.weights.length, count);
    await tester.tap(find.text('Wellness'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Last night'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Mood'));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() => Hive.close());
  });
}
