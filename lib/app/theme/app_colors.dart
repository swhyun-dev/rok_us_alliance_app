// lib/app/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — Taegukgi + Stars & Stripes
  static const Color darkNavy = Color(0xFF050D1F);
  static const Color navy = Color(0xFF0B1F5C);
  static const Color royalBlue = Color(0xFF2346A0);
  static const Color koreanRed = Color(0xFFCD2E3A);
  static const Color koreanBlue = Color(0xFF003478);
  static const Color red = Color(0xFFC62828);
  static const Color brightRed = Color(0xFFD93A3A);
  static const Color gold = Color(0xFFC8A84B);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color background = Color(0xFFF4F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF5F6773);
  static const Color border = Color(0xFFE3E8F2);

  static const Color softBlue = Color(0xFFEAF0FF);
  static const Color softRed = Color(0xFFFFEEEE);
  static const Color softSky = Color(0xFFF0F7FF);

  // Gradients
  static const LinearGradient heroGradient = LinearGradient(
    colors: [darkNavy, Color(0xFF0A1830)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient flagAccentGradient = LinearGradient(
    colors: [koreanRed, white, koreanBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient shieldGradient = LinearGradient(
    colors: [koreanRed, koreanBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
