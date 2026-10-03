import 'package:flutter/material.dart';

/// Centralized design tokens for Bloom.
/// Palette: warm white, charcoal ink, lavender, mint, soft peach.
/// Restrained color use; pastels are tints, actions use the deep variants.
class BloomColors {
  BloomColors._();

  // ---- Reference Color Palette ----
  static const Color heroPeach =
      Color(0xFFFBE7CF); // Warm apricot/peach hero background
  static const Color bg = Color(0xFFFFFCF8); // Clean warm canvas
  static const Color surface = Color(0xFFFFFFFF); // Clean white content surface
  static const Color surface2 =
      Color(0xFFF8F5F0); // Soft neutral secondary surface
  static const Color primaryViolet = Color(
      0xFF7560D5); // Violet primary buttons, selected tabs, links, active icons
  static const Color paleLavender =
      Color(0xFFECE7FA); // Pale lavender selected-state backgrounds
  static const Color powderBlue =
      Color(0xFFE5F0FF); // Powder blue featured activity panels
  static const Color ink = Color(0xFF292929); // Charcoal headings & main text
  static const Color inkSoft =
      Color(0xFF757575); // Readable muted-gray secondary text
  static const Color line = Color(0xFFEBE6DF); // Subtle neutral border

  // Supporting category accents (used with restraint, not rainbow tiles)
  static const Color mint = Color(0xFFE2F4E9);
  static const Color mintDeep = Color(0xFF2E8A5E);
  static const Color peach = heroPeach;
  static const Color peachDeep = Color(0xFFD6732B);
  static const Color lavender = paleLavender;
  static const Color lavenderDeep = primaryViolet;
  static const Color sky = powderBlue;
  static const Color skyDeep = Color(0xFF3B7FC4);
  static const Color rose = Color(0xFFFDE8EC);
  static const Color roseDeep = Color(0xFFD04D6A);

  // ---- Dark Mode Counterparts ----
  static const Color heroPeachD = Color(0xFF2E241C);
  static const Color bgD = Color(0xFF141316);
  static const Color surfaceD = Color(0xFF1F1E24);
  static const Color surface2D = Color(0xFF292830);
  static const Color primaryVioletD = Color(0xFF9887F0);
  static const Color paleLavenderD = Color(0xFF2F2947);
  static const Color powderBlueD = Color(0xFF1E2838);
  static const Color inkD = Color(0xFFF5F3FA);
  static const Color inkSoftD = Color(0xFFA6A0B3);
  static const Color lineD = Color(0xFF33303D);

  static const Color lavenderD = Color(0xFF2F2947);
  static const Color mintD = Color(0xFF1B382B);
  static const Color peachD = Color(0xFF3D2719);
  static const Color roseD = Color(0xFF3E1E26);
  static const Color skyD = Color(0xFF1E2838);

  static const List<Color> stages = [
    heroPeach,
    paleLavender,
    mint,
    rose,
    powderBlue,
  ];
  static const List<Color> stagesD = [
    heroPeachD,
    lavenderD,
    mintD,
    roseD,
    skyD,
  ];
}

class BloomRadii {
  BloomRadii._();
  static const double card = 28;
  static const double sheet = 32;
  static const double bubble = 22;
  static const double pill = 100;
  static const double chip = 16;
}

class BloomSpacing {
  BloomSpacing._();
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class BloomShadows {
  BloomShadows._();
  static List<BoxShadow> soft(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (dark ? Colors.black : const Color(0xFF2C251C))
            .withOpacity(dark ? 0.22 : 0.04),
        blurRadius: 14,
        offset: const Offset(0, 3),
      ),
    ];
  }

  static List<BoxShadow> lift(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: (dark ? Colors.black : const Color(0xFF2C251C))
            .withOpacity(dark ? 0.32 : 0.07),
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ];
  }
}

class BloomTheme {
  BloomTheme._();

  static const _fontFamily = 'Nunito'; // bundled rounded font, works offline

  static ThemeData light() {
    final scheme = const ColorScheme.light(
      primary: BloomColors.primaryViolet,
      onPrimary: Colors.white,
      secondary: BloomColors.powderBlue,
      onSecondary: BloomColors.ink,
      tertiary: BloomColors.peachDeep,
      surface: BloomColors.surface,
      onSurface: BloomColors.ink,
      surfaceContainerHighest: BloomColors.paleLavender,
      error: BloomColors.roseDeep,
      outline: BloomColors.line,
    );
    return _build(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = const ColorScheme.dark(
      primary: BloomColors.primaryVioletD,
      onPrimary: Color(0xFF141316),
      secondary: BloomColors.powderBlueD,
      onSecondary: Color(0xFFF5F3FA),
      tertiary: Color(0xFFE8B07E),
      surface: BloomColors.surfaceD,
      onSurface: BloomColors.inkD,
      surfaceContainerHighest: BloomColors.paleLavenderD,
      error: Color(0xFFE58AA0),
      outline: BloomColors.lineD,
    );
    return _build(scheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? BloomColors.inkD : BloomColors.ink;
    final inkSoft = dark ? BloomColors.inkSoftD : BloomColors.inkSoft;
    final textTheme = TextTheme(
      displaySmall: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.15,
          fontFamily: _fontFamily),
      headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ink,
          height: 1.2,
          fontFamily: _fontFamily),
      titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ink,
          fontFamily: _fontFamily),
      titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: ink,
          fontFamily: _fontFamily),
      titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
          fontFamily: _fontFamily),
      bodyLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: ink,
          height: 1.45,
          fontFamily: _fontFamily),
      bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: ink,
          height: 1.45,
          fontFamily: _fontFamily),
      bodySmall: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
          color: inkSoft,
          height: 1.4,
          fontFamily: _fontFamily),
      labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: ink,
          fontFamily: _fontFamily),
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: inkSoft,
          fontFamily: _fontFamily),
      labelMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: inkSoft,
          fontFamily: _fontFamily),
    );
    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: dark ? BloomColors.bgD : BloomColors.bg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: ink),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          side: BorderSide(color: scheme.outline),
          textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: _fontFamily),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? BloomColors.surface2D : BloomColors.surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BloomRadii.bubble),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        hintStyle: TextStyle(color: inkSoft),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.chip)),
        labelStyle: TextStyle(
            color: ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            fontFamily: _fontFamily),
        backgroundColor: dark ? BloomColors.surface2D : BloomColors.surface2,
        selectedColor: scheme.primary.withOpacity(0.18),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(BloomRadii.sheet)),
        ),
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.card)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.bubble)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? BloomColors.surfaceD : BloomColors.surface,
        indicatorColor:
            dark ? BloomColors.paleLavenderD : BloomColors.paleLavender,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color:
                  dark ? BloomColors.primaryVioletD : BloomColors.primaryViolet,
            );
          }
          return TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: inkSoft,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color:
                  dark ? BloomColors.primaryVioletD : BloomColors.primaryViolet,
              size: 24,
            );
          }
          return IconThemeData(color: inkSoft, size: 22);
        }),
      ),
      dividerTheme:
          DividerThemeData(color: scheme.outline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BloomRadii.bubble)),
      ),
    );
  }

  /// Pastel tint for category accents, adapting to brightness.
  static Color tint(BuildContext context, Color light, Color darkTint) {
    return Theme.of(context).brightness == Brightness.dark ? darkTint : light;
  }
}
