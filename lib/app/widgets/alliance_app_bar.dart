// lib/app/widgets/alliance_app_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// 앱 전체에서 사용하는 공통 다크 헤더.
/// [main] — 홈 탭들의 최상위 AppBar (방패 로고 + 알림 + 설정).
/// [sub]  — 하위 페이지용 (뒤로가기 + 제목).
abstract class AllianceAppBar {
  AllianceAppBar._();

  static const _bgGradient = LinearGradient(
    colors: [AppColors.darkNavy, Color(0xFF0D1E50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Main (tab root) ────────────────────────────────────────────────────────
  static AppBar main({
    required String title,
    String? subtitle,
    bool hasNotification = false,
    VoidCallback? onNotification,
    VoidCallback? onSettings,
    VoidCallback? onCard,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            // Shield brand mark
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: AppColors.shieldGradient,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onCard != null)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Tooltip(
              message: '한미동맹단증',
              child: InkWell(
                onTap: onCard,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.shieldGradient,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.badge_outlined, color: Colors.white, size: 16),
                      SizedBox(width: 5),
                      Text(
                        '단증',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Notification bell with optional dot
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 22,
              ),
              tooltip: '알림',
              onPressed: onNotification ??
                  (onNotification == null ? null : () {}),
            ),
            if (hasNotification)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.koreanRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white,
              size: 22,
            ),
            tooltip: '설정',
            onPressed: onSettings,
          ),
        ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(3),
        child: _FlagStripe(),
      ),
    );
  }

  // ── Sub-page ───────────────────────────────────────────────────────────────
  static AppBar sub({
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      foregroundColor: Colors.white,
      titleSpacing: 4,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: _bgGradient),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.52),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(3),
        child: _FlagStripe(),
      ),
    );
  }
}

class _FlagStripe extends StatelessWidget {
  const _FlagStripe();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: const BoxDecoration(gradient: AppColors.flagAccentGradient),
    );
  }
}
