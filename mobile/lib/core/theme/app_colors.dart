import 'package:flutter/material.dart';

class AppColors {
  // Light mode
  static const Color primary = Color(0xFF2A9D90);
  static const Color primaryForeground = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFF59F0A);
  static const Color accentForeground = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9FAFB);
  static const Color foreground = Color(0xFF0F1729);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardForeground = Color(0xFF0F1729);
  static const Color secondary = Color(0xFFEEF2F7);
  static const Color secondaryForeground = Color(0xFF0F1729);
  static const Color muted = Color(0xFFEEF2F7);
  static const Color mutedForeground = Color(0xFF65758B);
  static const Color border = Color(0xFFE1E7EF);
  static const Color input = Color(0xFFE1E7EF);
  static const Color success = Color(0xFF16A249);
  static const Color successForeground = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFF59F0A);
  static const Color warningForeground = Color(0xFFFFFFFF);
  static const Color destructive = Color(0xFFEF4343);
  static const Color destructiveForeground = Color(0xFFFFFFFF);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color sidebarForeground = Color(0xFF0F1729);
  static const Color sidebarAccent = Color(0xFFEEF2F7);

  // Dark mode
  static const Color primaryDark = Color(0xFF30B5A6);
  static const Color backgroundDark = Color(0xFF0B111E);
  static const Color foregroundDark = Color(0xFFF8FAFC);
  static const Color cardDark = Color(0xFF0F1729);
  static const Color cardForegroundDark = Color(0xFFF8FAFC);
  static const Color secondaryDark = Color(0xFF1D283A);
  static const Color secondaryForegroundDark = Color(0xFFF8FAFC);
  static const Color mutedDark = Color(0xFF1D283A);
  static const Color mutedForegroundDark = Color(0xFF8A9DB8);
  static const Color borderDark = Color(0xFF253045);
  static const Color accentDark = Color(0xFFF5A623);
  static const Color sidebarBgDark = Color(0xFF0F1729);
  static const Color sidebarForegroundDark = Color(0xFFF8FAFC);
  static const Color sidebarAccentDark = Color(0xFF1D283A);

  // Member colors
  static const List<Color> memberColors = [
    Color(0xFF0D9488), // teal
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // violet
    Color(0xFFEF4444), // red
    Color(0xFF3B82F6), // blue
    Color(0xFF10B981), // emerald
    Color(0xFFF97316), // orange
    Color(0xFFEC4899), // pink
  ];

  static Color memberColorFromHex(String hex) {
    try {
      return Color(int.parse(hex.replaceAll('#', '0xFF')));
    } catch (_) {
      return memberColors[0];
    }
  }
}
