import 'package:flutter/material.dart';

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
  final String viName;
  final String enName;
  final Color primaryColor;

  const AppPaletteInfo({
    required this.palette,
    required this.viName,
    required this.enName,
    required this.primaryColor,
  });

  static const List<AppPaletteInfo> all = [
    AppPaletteInfo(
      palette: AppPalette.physicsBlue,
      viName: 'Xanh Vật lý',
      enName: 'Physics Blue',
      primaryColor: Color(0xFF1976D2),
    ),
    AppPaletteInfo(
      palette: AppPalette.emerald,
      viName: 'Xanh Ngọc Emerald',
      enName: 'Emerald Green',
      primaryColor: Color(0xFF00875A),
    ),
    AppPaletteInfo(
      palette: AppPalette.indigo,
      viName: 'Xanh Chàm Indigo',
      enName: 'Indigo',
      primaryColor: Color(0xFF3F51B5),
    ),
    AppPaletteInfo(
      palette: AppPalette.amber,
      viName: 'Vàng Hổ Phách',
      enName: 'Amber',
      primaryColor: Color(0xFFFF8F00),
    ),
    AppPaletteInfo(
      palette: AppPalette.slate,
      viName: 'Xám Đá Slate',
      enName: 'Slate Grey',
      primaryColor: Color(0xFF455A64),
    ),
    AppPaletteInfo(
      palette: AppPalette.oceanCyan,
      viName: 'Xanh Lam Cyan',
      enName: 'Ocean Cyan',
      primaryColor: Color(0xFF00838F),
    ),
    AppPaletteInfo(
      palette: AppPalette.burgundy,
      viName: 'Đỏ Rượu Burgundy',
      enName: 'Burgundy Rose',
      primaryColor: Color(0xFF880E4F),
    ),
    AppPaletteInfo(
      palette: AppPalette.highContrast,
      viName: 'Tương Phản Cao',
      enName: 'High Contrast',
      primaryColor: Color(0xFF000000),
    ),
  ];

  static AppPaletteInfo fromPalette(AppPalette palette) {
    return all.firstWhere((p) => p.palette == palette, orElse: () => all.first);
  }
}
