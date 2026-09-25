import 'package:flutter/material.dart';
import 'app_palettes.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData createTheme({
    required AppPalette palette,
    required Brightness brightness,
  }) {
    final info = AppPaletteInfo.fromPalette(palette);
    final isDark = brightness == Brightness.dark;

    ColorScheme colorScheme;
    if (palette == AppPalette.highContrast) {
      if (isDark) {
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFFFFD600),
          onPrimary: Color(0xFF000000),
          primaryContainer: Color(0xFF333300),
          onPrimaryContainer: Color(0xFFFFD600),
          secondary: Color(0xFF00E5FF),
          onSecondary: Color(0xFF000000),
          surface: Color(0xFF121212),
          onSurface: Color(0xFFFFFFFF),
          surfaceContainerHigh: Color(0xFF242424),
          error: Color(0xFFFF5252),
          onError: Color(0xFF000000),
        );
      } else {
        colorScheme = const ColorScheme.light(
          primary: Color(0xFF000000),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFE0E0E0),
          onPrimaryContainer: Color(0xFF000000),
          secondary: Color(0xFF006064),
          onSecondary: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          onSurface: Color(0xFF000000),
          surfaceContainerHigh: Color(0xFFF0F0F0),
          error: Color(0xFFB00020),
          onError: Color(0xFFFFFFFF),
        );
      }
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: info.primaryColor,
        brightness: brightness,
      );
    }

    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: AppTypography.createTextTheme(colorScheme),
      extensions: [semanticColors],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48), // Touch target recommendation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 3,
        height: 64,
        indicatorColor: colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        elevation: 2,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  // Legacy compatibility getters if needed
  static ThemeData get lightTheme => createTheme(
    palette: AppPalette.physicsBlue,
    brightness: Brightness.light,
  );

  static ThemeData get darkTheme =>
      createTheme(palette: AppPalette.physicsBlue, brightness: Brightness.dark);
}
