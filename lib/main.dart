import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/design_system/app_theme.dart';
import 'app/design_system/theme_controller.dart';
import 'app/localization/locale_controller.dart';
import 'app/navigation/app_shell.dart';
import 'dev/demo_seed_bootstrap.dart';
import 'features/settings/presentation/app_lock_gate.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  await runDemoSeedIfEnabled(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const TuitionApp()),
  );
}

class TuitionApp extends ConsumerWidget {
  const TuitionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final localeMode = ref.watch(localeControllerProvider);

    Locale? activeLocale;
    switch (localeMode) {
      case AppLocaleMode.vi:
        activeLocale = const Locale('vi');
        break;
      case AppLocaleMode.en:
        activeLocale = const Locale('en');
        break;
      case AppLocaleMode.system:
        activeLocale = null;
        break;
    }

    return MaterialApp(
      title: 'Tuition2027',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.createTheme(
        palette: themeState.palette,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.createTheme(
        palette: themeState.palette,
        brightness: Brightness.dark,
      ),
      themeMode: themeState.themeMode,
      locale: activeLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppLockGate(child: AppShell()),
    );
  }
}
