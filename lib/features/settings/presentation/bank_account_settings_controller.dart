import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/bank_account_settings.dart';

final bankAccountSettingsProvider =
    NotifierProvider<BankAccountSettingsController, BankAccountSettings>(
      BankAccountSettingsController.new,
    );

class BankAccountSettingsController extends Notifier<BankAccountSettings> {
  static const String _prefKey = 'pref_bank_account_settings';

  @override
  BankAccountSettings build() {
    _loadFromPrefs();
    return BankAccountSettings.defaultSettings;
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_prefKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        state = BankAccountSettings.fromJson(jsonStr);
      }
    } catch (_) {}
  }

  Future<void> updateSettings(BankAccountSettings newSettings) async {
    state = newSettings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newSettings.toJson());
    } catch (_) {}
  }
}
