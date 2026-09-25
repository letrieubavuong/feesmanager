import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

enum AppPalette {
  physicsBlue,
  emerald,
  indigo,
  amber,
  slate,
  oceanCyan,
  burgundy,
  highContrast,
}

class AppPaletteInfo {
  final AppPalette palette;
  final Color primaryColor;

  const AppPaletteInfo({
    required this.palette,
    required this.primaryColor,
  });

  String name(AppLocalizations l10n) {
    switch (palette) {
      case AppPalette.physicsBlue:
        return l10n.palettePhysicsBlue;
      case AppPalette.emerald:
        return l10n.paletteEmerald;
      case AppPalette.indigo:
        return l10n.paletteIndigo;
      case AppPalette.amber:
        return l10n.paletteAmber;
      case AppPalette.slate:
        return l10n.paletteSlate;
      case AppPalette.oceanCyan:
        return l10n.paletteOceanCyan;
      case AppPalette.burgundy:
        return l10n.paletteBurgundy;
      case AppPalette.highContrast:
        return l10n.paletteHighContrast;
    }
  }

  static const List<AppPaletteInfo> all = [
    AppPaletteInfo(
      palette: AppPalette.physicsBlue,
      primaryColor: Color(0xFF1976D2),
    ),
    AppPaletteInfo(
      palette: AppPalette.emerald,
      primaryColor: Color(0xFF00875A),
    ),
    AppPaletteInfo(
      palette: AppPalette.indigo,
      primaryColor: Color(0xFF3F51B5),
    ),
    AppPaletteInfo(
      palette: AppPalette.amber,
      primaryColor: Color(0xFFFF8F00),
    ),
    AppPaletteInfo(
      palette: AppPalette.slate,
      primaryColor: Color(0xFF455A64),
    ),
    AppPaletteInfo(
      palette: AppPalette.oceanCyan,
      primaryColor: Color(0xFF00838F),
    ),
    AppPaletteInfo(
      palette: AppPalette.burgundy,
      primaryColor: Color(0xFF880E4F),
    ),
    AppPaletteInfo(
      palette: AppPalette.highContrast,
      primaryColor: Color(0xFF000000),
    ),
  ];

  static AppPaletteInfo fromPalette(AppPalette palette) {
    return all.firstWhere((p) => p.palette == palette, orElse: () => all.first);
  }
}
