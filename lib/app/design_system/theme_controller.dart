import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_palettes.dart';

class ThemeState {
  final ThemeMode themeMode;
  final AppPalette palette;

  const ThemeState({required this.themeMode, required this.palette});

  ThemeState copyWith({ThemeMode? themeMode, AppPalette? palette}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      palette: palette ?? this.palette,
    );
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeState> {
  static const String _prefThemeModeKey = 'pref_theme_mode';
  static const String _prefAppPaletteKey = 'pref_app_palette';

  @override
  ThemeState build() {
    // Initial default state before async load
    _loadFromPrefs();
    return const ThemeState(
      themeMode: ThemeMode.system,
      palette: AppPalette.physicsBlue,
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_prefThemeModeKey);
      final paletteStr = prefs.getString(_prefAppPaletteKey);

      ThemeMode mode = ThemeMode.system;
      if (modeStr == 'light') mode = ThemeMode.light;
      if (modeStr == 'dark') mode = ThemeMode.dark;

      AppPalette palette = AppPalette.physicsBlue;
      if (paletteStr != null) {
        palette = AppPalette.values.firstWhere(
          (p) => p.name == paletteStr,
          orElse: () => AppPalette.physicsBlue,
        );
      }

      state = ThemeState(themeMode: mode, palette: palette);
    } catch (_) {
      // Fallback silently on default state
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeModeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setPalette(AppPalette palette) async {
    state = state.copyWith(palette: palette);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAppPaletteKey, palette.name);
    } catch (_) {}
  }
}
