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
      if (isDark) {
        colorScheme = const ColorScheme.dark(
          primary: Color(0xFF0A84FF),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF153F60),
          onPrimaryContainer: Color(0xFF22B8F3),
          secondary: Color(0xFF22B8F3),
          onSecondary: Color(0xFF061A2E),
          surface: Color(0xFF061A2E),
          onSurface: Color(0xFFF4F8FC),
          surfaceContainer: Color(0xFF0B2740),
          surfaceContainerHigh: Color(0xFF123651),
          surfaceContainerHighest: Color(0xFF153F60),
          outline: Color(0xFF24506D),
          onSurfaceVariant: Color(0xFFA9C0D3),
          error: Color(0xFFFF5964),
          onError: Color(0xFFFFFFFF),
        );
      } else {
        colorScheme = const ColorScheme.light(
          primary: Color(0xFF0A84FF),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFFE2F1FF),
          onPrimaryContainer: Color(0xFF003870),
          secondary: Color(0xFF0082B8),
          onSecondary: Color(0xFFFFFFFF),
          surface: Color(0xFFF4F8FC),
          onSurface: Color(0xFF061A2E),
          surfaceContainer: Color(0xFFEAF2FA),
          surfaceContainerHigh: Color(0xFFDBE8F5),
          surfaceContainerHighest: Color(0xFFCDDEF0),
          outline: Color(0xFF90ACC4),
          onSurfaceVariant: Color(0xFF385873),
          error: Color(0xFFFF5964),
          onError: Color(0xFFFFFFFF),
        );
      }
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
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surface : colorScheme.surface,
        modalBackgroundColor: isDark ? AppColors.surface : colorScheme.surface,
        dragHandleColor: isDark ? AppColors.textMuted : colorScheme.outline,
        surfaceTintColor: Colors.transparent,
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

class AppColors {
  AppColors._();

  static const background = Color(0xFF061A2E);
  static const surface = Color(0xFF0B2740);
  static const surfaceHigh = Color(0xFF123651);
  static const surfaceSelected = Color(0xFF153F60);
  static const border = Color(0xFF24506D);
  static const primary = Color(0xFF0A84FF);
  static const cyanAccent = Color(0xFF22B8F3);
  static const success = Color(0xFF20C67A);
  static const warning = Color(0xFFF2B63D);
  static const error = Color(0xFFFF5964);
  static const textPrimary = Color(0xFFF4F8FC);
  static const textSecondary = Color(0xFFA9C0D3);
  static const textMuted = Color(0xFF728DA4);
  static const editingBottomSheet = Color(0xFFF7FAFF);
  static const editingSheetText = Color(0xFF0B2340);
}
