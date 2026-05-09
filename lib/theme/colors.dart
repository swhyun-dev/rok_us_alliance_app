import 'package:flutter/material.dart';

import '../features/membership/domain/member.dart';

/// ROK_US Alliance 디자인 시스템 - 컬러 토큰
///
/// 모든 색상은 이 파일에서만 가져와야 합니다. 하드코딩된 색상 절대 금지.
/// CLAUDE.md Section 3-1 기반 단일 진실 소스 (SSOT).
class AppColors {
  AppColors._(); // private constructor - instantiation 금지

  // ─── Backgrounds ─────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF0D1117); // 앱 전체 배경
  static const Color bgCard = Color(0xFF1C2128); // 카드, 모달 배경
  static const Color bgCardHover = Color(0xFF21262D); // 카드 누름 상태
  static const Color bgUrgent = Color(0xFF1C0A0D); // 긴급 알림 카드 배경
  static const Color bgIconDark = Color(0xFF050709); // 아이콘 외곽 배경

  // ─── Accent ──────────────────────────────────────────────
  static const Color accentRed = Color(0xFFE63946); // 메인 액센트
  static const Color accentRedBg = Color(0x26E63946); // 약 15% 알파

  // ─── Text ────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F0);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF444444);

  // ─── Semantic ────────────────────────────────────────────
  static const Color infoBlue = Color(0xFF378ADD);
  static const Color infoBlueBg = Color(0x26378ADD);
  static const Color success = Color(0xFF639922);
  static const Color successBg = Color(0x26639922);
  static const Color warning = Color(0xFFBA7517);
  static const Color warningBg = Color(0x26BA7517);

  // ─── Border ──────────────────────────────────────────────
  static const Color border = Color(0x0FFFFFFF); // ~6% 알파
  static const Color borderStrong = Color(0x24FFFFFF); // ~14% 알파

  // ─── Grade colors ────────────────────────────────────────
  static const Color gradeGold = Color(0xFFC9A84C);
  static const Color gradeVip = Color(0xFF7F77DD);

  // ─── Flag colors (for emblem) ───────────────────────────
  static const Color flagUsBlue = Color(0xFF3C3B6E);
  static const Color flagUsRed = Color(0xFFB22234);
  static const Color flagKrRed = Color(0xFFCD2E3A);
  static const Color flagKrBlue = Color(0xFF003478);

  // ─── Membership card 보조 토큰 ───────────────────────────

  /// 한미동맹단증 카드 하단의 플래그 스트라이프 그라디언트.
  /// 좌측: 태극(red·blue) → 흰 → 우측: 성조기(red·blue)
  static const LinearGradient flagStripeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      flagKrRed,
      flagKrBlue,
      Color(0xFFFFFFFF),
      flagUsRed,
      flagUsBlue,
    ],
    stops: [0.0, 0.30, 0.50, 0.70, 1.0],
  );

  /// QR 카운트다운 pill 기본 배경 (다크).
  static const Color qrCountdownBg = Color(0xCC0D1117);

  /// QR 만료 임박 (5초 미만) 시 카운트다운 pill 강조 배경.
  static const Color qrCountdownUrgent = accentRed;
}

/// 회원 등급 → 카드·배지 강조 색상.
///
/// 도메인 enum은 색상 의존을 갖지 않도록 순수하게 유지하고,
/// 매핑은 이 헬퍼로 분리한다.
Color gradeColorOf(MemberGrade grade) {
  return switch (grade) {
    MemberGrade.general => AppColors.textMuted,
    MemberGrade.regular => AppColors.accentRed,
    MemberGrade.gold => AppColors.gradeGold,
    MemberGrade.vip => AppColors.gradeVip,
    MemberGrade.honorary => AppColors.accentRed,
  };
}
