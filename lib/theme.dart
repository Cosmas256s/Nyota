// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ──────────────────────────────────────────────
  //   Core Seed Color – defines the entire harmonious palette
  // ──────────────────────────────────────────────
  static const Color seedColor = Color(0xFFE0A78A); // your beautiful muted peach/terracotta

  // ──────────────────────────────────────────────
  //   Custom fixed colors (when needed outside scheme)
  // ──────────────────────────────────────────────
  static const Color success = Color(0xFFA8BFA8);
  static const Color error = Color(0xFFE89A9A);
  static const Color warning = Color(0xFFE8C39A);

  // Activity-specific accent colors (soft & muted)
  static const Map<String, Color> activityColors = {
    'Shapes': Color(0xFFF4A3A3),        // muted coral rose
    'Counting': Color(0xFFC2D4C2),      // pale olive/sage
    'Basic Math': Color(0xFFD9A78F),    // soft dusty orange
    'Advanced Math': Color(0xFFD9C9B8), // warm taupe/beige
  };

  // ──────────────────────────────────────────────
  //   Light Theme – Material 3 with seed-based scheme
  // ──────────────────────────────────────────────
  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      // Optional: customize tones if needed (higher contrast, etc.)
      // dynamicSchemeVariant: DynamicSchemeVariant.content, // or fidelity, etc.
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFDF8F2), // your warm sand
      cardColor: colorScheme.surface,
      dialogBackgroundColor: colorScheme.surface,

      // Apply Fredoka font + correct colors
      textTheme: GoogleFonts.fredokaTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
      ),

      // Optional: customize specific components
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
      
    );
  }

  // ──────────────────────────────────────────────
  //   Dark Theme – soft, eye-friendly dark mode
  // ──────────────────────────────────────────────
  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      // Ensures harmonious dark variants from the same seed
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF1A1612), // soft dark warm brown-black
      cardColor: colorScheme.surfaceContainerLowest,
      dialogBackgroundColor: colorScheme.surfaceContainerLowest,

      // Fredoka font + dark mode text colors
      textTheme: GoogleFonts.fredokaTextTheme(
        ThemeData.dark().textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
      ),

      // Component overrides for dark mode
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
     
    );
  }

  // ──────────────────────────────────────────────
  //   Helpers (unchanged)
  // ──────────────────────────────────────────────
  static Color getActivityColor(String activityName) {
    return activityColors[activityName] ?? seedColor;
  }

  static IconData getActivityIcon(String name) {
    switch (name) {
      case 'Shapes':
        return Icons.category;
      case 'Counting':
        return Icons.calculate;
      case 'Basic Math':
        return Icons.add_circle;
      case 'Advanced Math':
        return Icons.grid_view;
      default:
        return Icons.star;
    }
  }
}