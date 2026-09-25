import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocaleMode { system, vi, en }

final localeControllerProvider =
    NotifierProvider<LocaleController, AppLocaleMode>(LocaleController.new);

class LocaleController extends Notifier<AppLocaleMode> {
  static const String _prefLocaleKey = 'pref_locale_mode';

  @override
  AppLocaleMode build() {
    _loadFromPrefs();
    return AppLocaleMode.system;
  }

  Locale? get locale {
    switch (state) {
      case AppLocaleMode.vi:
        return const Locale('vi');
      case AppLocaleMode.en:
        return const Locale('en');
      case AppLocaleMode.system:
        return null; // System default
    }
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeStr = prefs.getString(_prefLocaleKey);

      if (localeStr == 'vi') state = AppLocaleMode.vi;
      if (localeStr == 'en') state = AppLocaleMode.en;
      if (localeStr == 'system') state = AppLocaleMode.system;
    } catch (_) {}
  }

  Future<void> setLocaleMode(AppLocaleMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLocaleKey, mode.name);
    } catch (_) {}
  }
}
