import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2D4ADD);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF1A1C2E);
  static const Color secondary = Color(0xFF6B7280);
  static const Color primaryFixed = Color(0xFFE8ECFF);
  static const Color error = Color(0xFFE11D48);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2D4ADD), Color(0xFF4B65F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}
