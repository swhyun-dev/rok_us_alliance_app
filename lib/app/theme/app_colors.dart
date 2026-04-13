// lib/app/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color navy = Color(0xFF0B1F5C);
  static const Color royalBlue = Color(0xFF2346A0);
  static const Color red = Color(0xFFC62828);
  static const Color brightRed = Color(0xFFD93A3A);
  static const Color white = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF5F6773);
  static const Color border = Color(0xFFE3E8F2);

  static const Color softBlue = Color(0xFFEAF0FF);
  static const Color softRed = Color(0xFFFFEEEE);
  static const Color softSky = Color(0xFFF0F7FF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [navy, royalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient flagAccentGradient = LinearGradient(
    colors: [red, white, royalBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}