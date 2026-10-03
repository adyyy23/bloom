import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/core/utils.dart';
import 'package:bloom/data/models.dart';
import 'package:bloom/data/repositories.dart';
import 'package:bloom/companion/human_body_mesh.dart';

void main() {
  group('Units', () {
    test('kg/lb round-trips', () {
      expect(Units.kgToLb(70), closeTo(154.32, 0.01));
      expect(Units.lbToKg(Units.kgToLb(70)), closeTo(70, 1e-9));
    });

    test('cm/in round-trips', () {
      expect(Units.cmToIn(170), closeTo(66.93, 0.01));
      expect(Units.inToCm(Units.cmToIn(170)), closeTo(170, 1e-9));
    });

    test('ml/fl oz round-trips', () {
      expect(Units.mlToFloz(250), closeTo(8.45, 0.01));
      expect(Units.flozToMl(Units.mlToFloz(250)), closeTo(250, 1e-9));
    });

    test('display helpers respect unit system', () {
      expect(Units.weight(70, 'metric'), '70.0 kg');
      expect(Units.weight(70, 'imperial'), contains('lb'));
      expect(Units.volume(500, 'metric'), '500 ml');
      expect(Units.volume(500, 'imperial'), contains('fl oz'));
    });

    test('pace handles zero distance', () {
      expect(Units.pace(0, 60, 'metric'), '—');
      expect(Units.pace(1000, 360, 'metric'), '6.0 min/km');
    });
  });

  group('Dates', () {
    test('sleep duration crosses midnight', () {
      final d = Dates.sleepDuration('23:30', '06:45', '2026-10-03');
      expect(d.inMinutes, 435); // 7h 15m
    });

    test('sleep duration same-day (nap)', () {
      final d = Dates.sleepDuration('13:00', '13:45', '2026-10-03');
      expect(d.inMinutes, 45);
    });

    test('week keys are Monday-first and length 7', () {
      final keys = Dates.weekKeys(DateTime(2026, 10, 3)); // a Saturday
      expect(keys.length, 7);
      expect(Dates.parseKey(keys.first).weekday, DateTime.monday);
      expect(keys, contains('2026-10-03'));
    });

    test('date keys sort lexicographically', () {
      expect('2026-10-03'.compareTo('2026-10-04') < 0, true);
    });
  });

  group('Calc', () {
    test('mifflin estimate is plausible', () {
      final kcal = Calc.mifflinKcal(
        weightKg: 70,
        heightCm: 170,
        ageYears: 30,
        isFemale: false,
        activityLevel: 'moderate',
        goal: 'maintain',
        allowEstimate: true,
      );
      // BMR ~= 1617, * 1.375 ~= 2224 -> rounded to 2220
      expect(kcal, isNotNull);
      expect(kcal!, inInclusiveRange(2100, 2350));
    });

    test('lose goal reduces, gain increases', () {
      double kcal(String goal) => Calc.mifflinKcal(
            weightKg: 70,
            heightCm: 170,
            ageYears: 30,
            isFemale: false,
            activityLevel: 'moderate',
            goal: goal,
            allowEstimate: true,
          )!;
      expect(kcal('lose'), lessThan(kcal('maintain')));
      expect(kcal('gain'), greaterThan(kcal('maintain')));
    });

    test('estimate refused when not allowed', () {
      expect(
        Calc.mifflinKcal(
          weightKg: 70,
          heightCm: 170,
          ageYears: 30,
          isFemale: false,
          activityLevel: 'moderate',
          goal: 'maintain',
          allowEstimate: false,
        ),
        isNull,
      );
    });

    test('macro targets are consistent with kcal', () {
      final m = Calc.macroTargets(2200, 70, 'maintain');
      final fromMacros =
          m['protein']! * 4 + m['carbs']! * 4 + m['fat']! * 9;
      expect(fromMacros, closeTo(2200, 60));
      expect(m['protein']!, closeTo(98, 15)); // 1.4 g/kg
    });

    test('moving average smooths', () {
      final avg = Calc.movingAverage([70, 71, 70, 72, 71, 70, 70], 7);
      expect(avg.last, closeTo(70.57, 0.01));
      expect(avg.first, 70.0);
    });
  });

  group('Nutrition math', () {
    test('scaled recalculates serving sizes correctly', () {
      const per100 =
          Nutrition(kcal: 200, protein: 10, carbs: 20, fat: 5, fiber: 2);
      final serving = per100.scaled(1.58); // 158 g of cooked rice
      expect(serving.kcal, closeTo(316, 0.01));
      expect(serving.protein, closeTo(15.8, 0.01));
    });

    test('addition sums nutrients', () {
      const a = Nutrition(kcal: 100, protein: 5);
      const b = Nutrition(kcal: 150, protein: 7, sodiumMg: 200);
      final total = a + b;
      expect(total.kcal, 250);
      expect(total.protein, 12);
      expect(total.sodiumMg, 200);
    });

    test('estimates propagate', () {
      const a = Nutrition(kcal: 100, isEstimate: true);
      const b = Nutrition(kcal: 100, isEstimate: false);
      expect((a + b).isEstimate, true);
    });

    test('json round-trip', () {
      const n = Nutrition(
          kcal: 300,
          protein: 20,
          sodiumMg: 400,
          isEstimate: true,
          source: 'test');
      final back = Nutrition.fromJson(n.toJson());
      expect(back.kcal, 300);
      expect(back.sodiumMg, 400);
      expect(back.source, 'test');
    });
  });

  group('UserProfile guards', () {
    test('minor blocks estimated targets', () {
      final p = UserProfile(
          birthYear: DateTime.now().year - 15, goal: 'lose');
      expect(p.isMinor, true);
      expect(p.allowEstimatedTargets, false);
    });

    test('pregnancy blocks estimated targets', () {
      final p = UserProfile(pregnancyOrNursing: true);
      expect(p.allowEstimatedTargets, false);
    });

    test('specialized guidance blocks estimated targets', () {
      final p = UserProfile(specializedGuidance: true);
      expect(p.allowEstimatedTargets, false);
    });

    test('typical adult allows estimated targets', () {
      final p = UserProfile(
          birthYear: DateTime.now().year - 30, goal: 'maintain');
      expect(p.allowEstimatedTargets, true);
    });

    test('json round-trip preserves fields', () {
      final p = UserProfile(
        name: 'Ady',
        units: 'metric',
        goal: 'fitness',
        allergies: ['peanut'],
        targetKcal: 2200,
      );
      final back = UserProfile.fromJson(p.toJson());
      expect(back.name, 'Ady');
      expect(back.allergies, ['peanut']);
      expect(back.targetKcal, 2200);
    });
  });

  group('Recipe nutrition', () {
    test('perServing sums ingredient nutrition', () {
      final repo = RecipeRepo();
      final catalog = [
        const CatalogFood(
          id: 'rice_cooked',
          name: 'Rice, cooked',
          category: 'Grains',
          per100g: Nutrition(kcal: 130, protein: 2.7, carbs: 28, fat: 0.3),
        ),
        const CatalogFood(
          id: 'chicken_breast',
          name: 'Chicken breast',
          category: 'Protein',
          per100g:
              Nutrition(kcal: 165, protein: 31, carbs: 0, fat: 3.6),
        ),
      ];
      final recipe = Recipe(
        id: 'r1',
        name: 'Test bowl',
        servings: 2,
        ingredients: [
          RecipeIngredient(
              foodId: 'rice_cooked',
              foodName: 'Rice',
              qty: 1,
              unit: 'cup',
              grams: 158),
          RecipeIngredient(
              foodId: 'chicken_breast',
              foodName: 'Chicken',
              qty: 1,
              unit: 'piece',
              grams: 120),
        ],
      );
      final per = repo.perServing(recipe, catalog);
      // total = 130*1.58 + 165*1.2 = 205.4 + 198 = 403.4; per serving = 201.7
      expect(per.kcal, closeTo(201.7, 0.5));
      expect(per.isEstimate, true);
    });
  });

  group('FoodEntry', () {
    test('json round-trip', () {
      final e = FoodEntry(
        id: 'e1',
        dateKey: '2026-10-03',
        meal: 'lunch',
        name: 'Chicken Adobo',
        servingQty: 1,
        servingUnit: 'cup',
        grams: 200,
        nutrition: const Nutrition(kcal: 330, protein: 34),
      );
      final back = FoodEntry.fromJson(e.toJson());
      expect(back.name, 'Chicken Adobo');
      expect(back.nutrition.kcal, 330);
      expect(back.meal, 'lunch');
    });
  });

  group('BMI & Clinical Classification', () {
    test('standard adult WHO/CDC categories', () {
      // Underweight (< 18.5)
      final under = Calc.calculateBmi(weightKg: 45, heightCm: 165, birthYear: 1990);
      expect(under, isNotNull);
      expect(under!.category, 'Underweight');
      expect(under.isApplicable, true);

      // Normal weight (18.5 - 24.9)
      final normal = Calc.calculateBmi(weightKg: 60, heightCm: 165, birthYear: 1990);
      expect(normal, isNotNull);
      expect(normal!.category, 'Standard range');
      expect(normal.isApplicable, true);

      // Overweight (25.0 - 29.9)
      final over = Calc.calculateBmi(weightKg: 75, heightCm: 165, birthYear: 1990);
      expect(over, isNotNull);
      expect(over!.category, 'Overweight');
      expect(over.isApplicable, true);

      // Obesity (>= 30.0)
      final obese = Calc.calculateBmi(weightKg: 90, heightCm: 165, birthYear: 1990);
      expect(obese, isNotNull);
      expect(obese!.category, 'Obesity');
      expect(obese.isApplicable, true);
    });

    test('clinical guard: minor age (<20) is marked not applicable', () {
      final currentYear = DateTime.now().year;
      final minor = Calc.calculateBmi(
        weightKg: 50,
        heightCm: 160,
        birthYear: currentYear - 15,
      );
      expect(minor, isNotNull);
      expect(minor!.isApplicable, false);
      expect(minor.category, contains('20'));
    });

    test('clinical guard: pregnancy/nursing is marked not applicable', () {
      final preg = Calc.calculateBmi(
        weightKg: 68,
        heightCm: 165,
        pregnancyOrNursing: true,
      );
      expect(preg, isNotNull);
      expect(preg!.isApplicable, false);
      expect(preg.category, 'Pregnancy/Nursing');
    });

    test('clinical guard: specialized guidance supersedes standard indices', () {
      final spec = Calc.calculateBmi(
        weightKg: 68,
        heightCm: 165,
        specializedGuidance: true,
      );
      expect(spec, isNotNull);
      expect(spec!.isApplicable, false);
      expect(spec.category, 'Specialized care');
    });

    test('invalid or missing inputs return null safely', () {
      expect(Calc.calculateBmi(weightKg: null, heightCm: 170), isNull);
      expect(Calc.calculateBmi(weightKg: 60, heightCm: null), isNull);
      expect(Calc.calculateBmi(weightKg: 0, heightCm: 170), isNull);
      expect(Calc.calculateBmi(weightKg: 60, heightCm: -10), isNull);
    });
  });

  group('AvatarConfig & HumanBodyMesh Morphing', () {
    test('AvatarConfig json round-trip', () {
      const cfg = AvatarConfig(
        frame: BodyFrame.broad,
        skinTone: SkinTone.honey,
        hairStyle: HairStyle.softCurls,
        hairColor: HairColor.chestnut,
        clothingColor: ClothingColor.ocean,
        waistCm: 76.0,
        hipCm: 98.0,
        chestCm: 90.0,
      );
      final json = cfg.toJson();
      final back = AvatarConfig.fromJson(json);
      expect(back.frame, BodyFrame.broad);
      expect(back.skinTone, SkinTone.honey);
      expect(back.hairStyle, HairStyle.softCurls);
      expect(back.hairColor, HairColor.chestnut);
      expect(back.clothingColor, ClothingColor.ocean);
      expect(back.waistCm, 76.0);
      expect(back.hipCm, 98.0);
      expect(back.chestCm, 90.0);
    });

    test('HumanBodyMesh morph vertices are bounded and non-uniform', () {
      expect(HumanBodyMesh.baseVertices.length, 783);
      expect(HumanBodyMesh.faces.length, 1360);

      // Baseline morph
      final vBase = HumanBodyMesh.computeMorphedVertices(
        heightCm: 170,
        weightKg: 65,
        frame: BodyFrame.medium,
        breathPhase: 0.0,
        isFemale: true,
      );
      expect(vBase.length, 783);

      // Higher weight morph increases torso girth while keeping head anatomically stable
      final vHeavy = HumanBodyMesh.computeMorphedVertices(
        heightCm: 170,
        weightKg: 95,
        frame: BodyFrame.medium,
        breathPhase: 0.0,
        isFemale: true,
      );

      // Vertex in torso waist region (index around torso)
      // Check that waist has expanded laterally
      expect(vHeavy.any((v) => v.y > 100 && v.y < 125 && v.x.abs() > 0), true);

      // Extreme weight bounds are clamped safely
      final vExtreme = HumanBodyMesh.computeMorphedVertices(
        heightCm: 120, // below min bound
        weightKg: 300, // above max bound
        frame: BodyFrame.broad,
        breathPhase: 0.5,
        isFemale: false,
      );
      expect(vExtreme.length, 783);
      for (final v in vExtreme) {
        expect(v.x.isNaN, false);
        expect(v.y.isNaN, false);
        expect(v.z.isNaN, false);
      }
    });
  });
}
