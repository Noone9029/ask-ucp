import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ================================
/// ASK-UCP THEME SYSTEM
/// ================================

/// ---- BRAND COLORS ----
class AppColors {
  // Brand core
  static const primary = Color(0xFF5B7CFF); // UCP Blue
  static const secondary = Color(0xFF7B61FF); // Violet blend end
  static const accent = Color(0xFF00D1D6); // Neon teal accent

  // Neutrals
  static const background = Color(0xFFF7F8FB);
  static const surface = Colors.white;
  static const surfaceDark = Color(0xFF1A1A1A);
  static const ink = Color(0xFF0B1B3A);

  // Semantic
  static const success = Color(0xFF0F9D58);
  static const warning = Color(0xFFEA8600);
  static const error = Color(0xFFB00020);
}

/// ---- TEXT THEME BUILDER ----
/// Poppins → headlines, Inter → body and labels.
TextTheme _buildTextTheme(ColorScheme scheme) {
  final base = Typography.material2021().black;
  final poppins = GoogleFonts.poppinsTextTheme(base);
  final inter = GoogleFonts.interTextTheme(base);

  return TextTheme(
    displayLarge: poppins.displayLarge?.copyWith(color: scheme.onBackground),
    displayMedium: poppins.displayMedium?.copyWith(color: scheme.onBackground),
    displaySmall: poppins.displaySmall?.copyWith(color: scheme.onBackground),

    headlineLarge: poppins.headlineLarge?.copyWith(color: scheme.onBackground),
    headlineMedium: poppins.headlineMedium?.copyWith(color: scheme.onBackground),
    headlineSmall: poppins.headlineSmall?.copyWith(color: scheme.onBackground),

    titleLarge: poppins.titleLarge?.copyWith(color: scheme.onSurface),
    titleMedium: poppins.titleMedium?.copyWith(color: scheme.onSurface),
    titleSmall: poppins.titleSmall?.copyWith(color: scheme.onSurface),

    bodyLarge: inter.bodyLarge?.copyWith(color: scheme.onBackground, height: 1.4),
    bodyMedium: inter.bodyMedium?.copyWith(color: scheme.onBackground, height: 1.4),
    bodySmall: inter.bodySmall?.copyWith(color: scheme.onBackground.withOpacity(.85)),

    labelLarge: inter.labelLarge?.copyWith(color: scheme.onPrimary),
    labelMedium: inter.labelMedium?.copyWith(color: scheme.onSurface),
    labelSmall: inter.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
  );
}

/// ---- COLOR SCHEMES ----
final lightColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  primary: AppColors.primary,
  secondary: AppColors.secondary,
  surface: AppColors.surface,
  background: AppColors.background,
  onSurface: Colors.black87,
);

final darkColorScheme = ColorScheme.fromSeed(
  seedColor: AppColors.primary,
  brightness: Brightness.dark,
  primary: AppColors.primary,
  secondary: AppColors.secondary,
  surface: AppColors.surfaceDark,
  background: const Color(0xFF0E0E0E),
  onSurface: Colors.white,
);

/// ---- LIGHT THEME ----
final ThemeData lightTheme = (() {
  final scheme = lightColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: _buildTextTheme(scheme),
    scaffoldBackgroundColor: scheme.background,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onBackground,
      elevation: 0,
      titleTextStyle: _buildTextTheme(scheme)
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary, width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(0.85),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    chipTheme: ChipThemeData(
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      backgroundColor: scheme.surface,
      selectedColor: scheme.secondaryContainer,
      labelStyle: _buildTextTheme(scheme).labelMedium!,
    ),

    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1),

    iconTheme: IconThemeData(color: scheme.primary),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(scheme.outlineVariant),
      radius: const Radius.circular(999),
      thickness: const WidgetStatePropertyAll(4),
    ),

    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: _buildTextTheme(scheme)
          .bodyMedium
          ?.copyWith(color: scheme.onInverseSurface),
    ),
  );
})();

/// ---- DARK THEME ----
final ThemeData darkTheme = (() {
  final scheme = darkColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: _buildTextTheme(scheme),
    scaffoldBackgroundColor: scheme.background,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      titleTextStyle: _buildTextTheme(scheme)
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w700),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface.withOpacity(.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
    ),
  );
})();

/// ---- UTILITIES ----
/// Shared gradient for hero sections or buttons.
LinearGradient askUcpGradient() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.primary, AppColors.secondary],
    );
