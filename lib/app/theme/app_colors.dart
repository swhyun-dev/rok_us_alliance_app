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

  // ─── 회색 표면·칩·divider 보조 토큰 ─────────────────────
  /// 일반 태그·칩의 회색 배경 (#F4F5F7, #F2F3F5 도 여기로 통합)
  static const Color chipBg = Color(0xFFF4F5F7);

  /// 약간 어두운 순수 회색 칩·placeholder
  static const Color chipBgNeutral = Color(0xFFF2F2F2);

  /// 본문 박스 회색 표면 (#F7F8FA, #F8F9FB 통합)
  static const Color surfaceMuted = Color(0xFFF7F8FA);

  /// 이미지 errorBuilder 자리 — 약한 푸른 회색
  static const Color placeholderImg = Color(0xFFE9EEF8);

  /// 아바타 fallback 배경 — 중간 회색
  static const Color placeholderAvatar = Color(0xFFE1E3E8);

  /// "인기글" 등 hot 태그 배경 (분홍 계열)
  static const Color chipHotBg = Color(0xFFFDE9EA);

  /// "BEST" 등 warning/highlight 칩 배경 (크림)
  static const Color chipWarningBg = Color(0xFFFFEAD7);

  /// chipWarningBg 짝 텍스트 (오렌지)
  static const Color chipWarningText = Color(0xFFD57A1F);

  /// 미세 divider/border 라인 색
  static const Color divider = Color(0xFFEAECEF);

  /// 섹션 구분용 두꺼운 divider (8px 세로 회색 띠)
  static const Color dividerThick = Color(0xFFF5F6F8);

  /// 성공·확인 인디케이터 (체크마크 등) 다크 그린
  static const Color success = Color(0xFF2E7D32);

  // ─── 등급 색상 (CLAUDE.md Section 3-1) ──────────────────
  static const Color gradeLv1 = Color(0xFF8C93A8); // 새내기 — 회색
  static const Color gradeLv2 = Color(0xFF378ADD); // 시민   — 파랑
  static const Color gradeLv3 = Color(0xFF639922); // 활동가 — 녹색
  static const Color gradeLv4 = Color(0xFFC9A84C); // 핵심   — 골드 (legacy gold #C8A84B 와 imperceptible 차이)
  static const Color gradeLv5 = Color(0xFF7F77DD); // 동지   — 퍼플

  // ─── 카드 히어로 영역 그라디언트 (멤버십 카드 헤더, 프로필 영웅 카드 등) ─
  static const LinearGradient cardHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkNavy, Color(0xFF0D1E50)],
  );

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
