import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date helpers. All personal records are keyed by local calendar date
/// strings ("yyyy-MM-dd") so day boundaries follow the user's timezone.
class Dates {
  Dates._();

  static final _keyFmt = DateFormat('yyyy-MM-dd');
  static final _prettyFmt = DateFormat('EEE, MMM d');
  static final _longFmt = DateFormat('EEEE, MMMM d');
  static final _timeFmt = DateFormat('h:mm a');
  static final _monthFmt = DateFormat('MMMM yyyy');

  static String key(DateTime d) => _keyFmt.format(d);
  static String todayKey() => key(DateTime.now());
  static String pretty(DateTime d) => _prettyFmt.format(d);
  static String long(DateTime d) => _longFmt.format(d);
  static String clock(DateTime d) => _timeFmt.format(d);
  static String monthTitle(DateTime d) => _monthFmt.format(d);
  static DateTime parseKey(String k) => _keyFmt.parse(k);

  static bool isToday(String k) => k == todayKey();
  static bool isYesterday(String k) =>
      k == key(DateTime.now().subtract(const Duration(days: 1)));

  static String relativeDay(String k) {
    if (isToday(k)) return 'Today';
    if (isYesterday(k)) return 'Yesterday';
    return pretty(parseKey(k));
  }

  /// Monday-first list of the 7 date keys containing [date].
  static List<String> weekKeys(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return List.generate(7, (i) => key(monday.add(Duration(days: i))));
  }

  static List<DateTime> lastNDays(int n) {
    final now = DateTime.now();
    return List.generate(n, (i) => now.subtract(Duration(days: n - 1 - i)));
  }

  /// Duration between bedtime and wake, correctly crossing midnight.
  /// Times are "HH:mm" strings on the date the user woke.
  static Duration sleepDuration(
    String bedtimeHHmm,
    String wakeHHmm,
    String wakeDateKey,
  ) {
    final wake = parseKey(wakeDateKey);
    final bp = bedtimeHHmm.split(':').map(int.parse).toList();
    final wp = wakeHHmm.split(':').map(int.parse).toList();
    var bed = DateTime(wake.year, wake.month, wake.day, bp[0], bp[1]);
    final up = DateTime(wake.year, wake.month, wake.day, wp[0], wp[1]);
    if (!bed.isBefore(up)) bed = bed.subtract(const Duration(days: 1));
    return up.difference(bed);
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }

  static String formatHm(double hours) {
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '${h}h ${m}m';
  }
}

/// Unit conversions. Internal storage is always metric.
class Units {
  Units._();

  static const double kgPerLb = 0.45359237;
  static const double cmPerIn = 2.54;
  static const double mlPerFloz = 29.5735;

  static double kgToLb(double kg) => kg / kgPerLb;
  static double lbToKg(double lb) => lb * kgPerLb;
  static double cmToIn(double cm) => cm / cmPerIn;
  static double inToCm(double inch) => inch * cmPerIn;
  static double mlToFloz(double ml) => ml / mlPerFloz;
  static double flozToMl(double floz) => floz * mlPerFloz;

  static String weight(double kg, String units) => units == 'imperial'
      ? '${kgToLb(kg).toStringAsFixed(1)} lb'
      : '${kg.toStringAsFixed(1)} kg';

  static String weightShort(double kg, String units) => units == 'imperial'
      ? kgToLb(kg).toStringAsFixed(1)
      : kg.toStringAsFixed(1);

  static String weightUnit(String units) => units == 'imperial' ? 'lb' : 'kg';

  static String length(double cm, String units) => units == 'imperial'
      ? '${cmToIn(cm).toStringAsFixed(1)} in'
      : '${cm.toStringAsFixed(1)} cm';

  static String volume(double ml, String units) => units == 'imperial'
      ? '${mlToFloz(ml).toStringAsFixed(0)} fl oz'
      : '${ml.toStringAsFixed(0)} ml';

  static String distance(double meters, String units) {
    if (units == 'imperial') {
      final mi = meters / 1609.344;
      return '${mi.toStringAsFixed(2)} mi';
    }
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
    return '${meters.toStringAsFixed(0)} m';
  }

  static String pace(double meters, int seconds, String units) {
    if (meters <= 0 || seconds <= 0) return '—';
    if (units == 'imperial') {
      final minPerMile = seconds / 60 / (meters / 1609.344);
      return '${minPerMile.toStringAsFixed(1)} min/mi';
    }
    final minPerKm = seconds / 60 / (meters / 1000);
    return '${minPerKm.toStringAsFixed(1)} min/km';
  }
}

class Fmt {
  Fmt._();
  static String num(double v, [int digits = 0]) =>
      v.toStringAsFixed(digits).replaceAll(RegExp(r'\.0+\$'), '');
  static String kcal(double v) => '${v.round()} kcal';
  static String grams(double v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)} g';
  static final _intFmt = NumberFormat('#,###');
  static String intFmt(int v) => _intFmt.format(v);
}

/// Nutrition math. Targets are estimates; UI must say so.
class Calc {
  Calc._();

  /// Mifflin-St Jeor, returns null when inputs are missing or the user
  /// opted out of estimated targets (minor / pregnancy / specialized care).
  static double? mifflinKcal({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required bool isFemale,
    required String activityLevel,
    required String goal,
    required bool allowEstimate,
  }) {
    if (!allowEstimate) return null;
    final double bmr =
        10 * weightKg + 6.25 * heightCm - 5 * ageYears + (isFemale ? -161 : 5);
    final factor = switch (activityLevel) {
      'low' => 1.2,
      'moderate' => 1.375,
      'active' => 1.55,
      'very' => 1.725,
      _ => 1.375,
    };
    double tdee = bmr * factor;
    tdee += switch (goal) {
      'lose' => -400, // gentle default; user can edit
      'gain' => 300,
      _ => 0,
    };
    return (tdee / 10).round() * 10;
  }

  /// Protein-forward macro split from a kcal target.
  static Map<String, double> macroTargets(
    double kcal,
    double weightKg,
    String goal,
  ) {
    final proteinPerKg = switch (goal) {
      'gain' => 1.8,
      'lose' => 1.8,
      'fitness' => 1.7,
      _ => 1.4,
    };
    final protein = (proteinPerKg * weightKg).clamp(40, 220).toDouble();
    final fat = (kcal * 0.28 / 9).clamp(30, 120).toDouble();
    final carbs =
        ((kcal - protein * 4 - fat * 9) / 4).clamp(60, 500).toDouble();
    final fiber = (kcal / 1000 * 14).clamp(15, 40).toDouble();
    return {'protein': protein, 'fat': fat, 'carbs': carbs, 'fiber': fiber};
  }

  /// Trailing moving average over ordered values; explains smoothing.
  static List<double?> movingAverage(List<double> values, int window) {
    return List.generate(values.length, (i) {
      final from = (i - window + 1).clamp(0, values.length);
      if (i - from + 1 < (window / 2).ceil() && values.length >= window) {
        // require at least half a window once enough data exists
      }
      final slice = values.sublist(from, i + 1);
      if (slice.isEmpty) return null;
      return slice.reduce((a, b) => a + b) / slice.length;
    });
  }

  static double weeklyChange(List<double> orderedValues) {
    if (orderedValues.length < 2) return 0;
    return orderedValues.last - orderedValues.first;
  }

  /// Verified Adult BMI Classification (WHO / CDC standard guidelines).
  ///
  /// Reference:
  /// - World Health Organization (WHO) Technical Report Series 854: Physical Status.
  /// - CDC Body Mass Index: Considerations for Practitioners.
  ///
  /// Note:
  /// BMI is a screening measure and does not describe body composition or overall health.
  /// Standard categories do not apply to minors (<20y) or during pregnancy/nursing.
  static BmiResult? calculateBmi({
    required double? weightKg,
    required double? heightCm,
    int? birthYear,
    bool pregnancyOrNursing = false,
    bool specializedGuidance = false,
  }) {
    if (weightKg == null ||
        heightCm == null ||
        !weightKg.isFinite ||
        !heightCm.isFinite ||
        weightKg <= 0 ||
        heightCm <= 0) return null;
    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    if (!bmi.isFinite) return null;

    final currentYear = DateTime.now().year;
    // Only a birth year is stored: use the youngest possible age this year.
    final age = birthYear != null ? currentYear - birthYear - 1 : 0;

    // Pregnancy / Nursing check
    if (pregnancyOrNursing) {
      return BmiResult(
        bmi: bmi,
        category: 'Pregnancy/Nursing',
        color: const Color(0xFFFFB74D),
        isApplicable: false,
        note:
            'Standard BMI categories are not applicable during pregnancy or nursing.',
      );
    }

    // Specialized medical care check
    if (specializedGuidance) {
      return BmiResult(
        bmi: bmi,
        category: 'Specialized care',
        color: const Color(0xFFBA68C8),
        isApplicable: false,
        note:
            'Clinical provider guidance supersedes population screening metrics.',
      );
    }

    // Pediatric check
    if (birthYear == null || age < 20) {
      return BmiResult(
        bmi: bmi,
        category: birthYear == null ? 'Age needed' : 'Age <20',
        color: const Color(0xFF64B5F6),
        isApplicable: false,
        note: birthYear == null
            ? 'Add your age to check whether adult screening categories apply.'
            : 'CDC adult categories apply at age 20 and older. Growth assessment uses age-specific guidance.',
      );
    }

    // Standard WHO/CDC Adult Cutoffs
    if (bmi < 18.5) {
      return BmiResult(
        bmi: bmi,
        category: 'Underweight',
        color: const Color(0xFF64B5F6), // soft sky blue
        note:
            'BMI is a screening measure and does not describe body composition or overall health.',
      );
    } else if (bmi < 25.0) {
      return BmiResult(
        bmi: bmi,
        category: 'Standard range',
        color: const Color(0xFF7560D5), // category, not a health verdict
        note:
            'BMI is a screening measure and does not describe body composition or overall health.',
      );
    } else if (bmi < 30.0) {
      return BmiResult(
        bmi: bmi,
        category: 'Overweight',
        color: const Color(0xFFFFB74D), // soft warm amber
        note:
            'BMI is a screening measure and does not describe body composition or overall health.',
      );
    } else {
      return BmiResult(
        bmi: bmi,
        category: 'Obesity',
        color: const Color(0xFFE57373), // soft coral
        note:
            'BMI is a screening measure and does not describe body composition or overall health.',
      );
    }
  }
}

/// Clinical BMI calculation result with category classification.
class BmiResult {
  final double bmi;
  final String category;
  final Color color;
  final bool isApplicable;
  final String note;

  const BmiResult({
    required this.bmi,
    required this.category,
    required this.color,
    this.isApplicable = true,
    required this.note,
  });
}

/// Simple uuid helper (uuid package is used at call sites).
String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
