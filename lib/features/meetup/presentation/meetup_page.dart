// lib/features/meetup/presentation/meetup_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MeetupPage extends StatelessWidget {
  const MeetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: const [
        _MeetupHeroCard(),
        SizedBox(height: 18),
        _SectionHeader(title: '지역별 모임 현황', icon: Icons.pin_drop_outlined),
        SizedBox(height: 10),
        _RegionCard(
          flag: '🇰🇷',
          title: '평택',
          subtitle: '캠프 험프리스 인근 · 이번 주 핵심 집결 지역',
          members: 126,
          isActive: true,
          isRed: true,
        ),
        SizedBox(height: 10),
        _RegionCard(
          flag: '🇰🇷',
          title: '서울',
          subtitle: '콘텐츠 확산 · 사전 모임 · 차량 공유 논의',
          members: 248,
          isActive: true,
          isRed: false,
        ),
        SizedBox(height: 10),
        _RegionCard(
          flag: '🇰🇷',
          title: '부산',
          subtitle: '지역 네트워크 정비 · 참여 인원 모집',
          members: 84,
          isActive: false,
          isRed: true,
        ),
        SizedBox(height: 10),
        _RegionCard(
          flag: '🇺🇸',
          title: '미국',
          subtitle: '해외 지지 메시지 · 온라인 확산 · 실시간 응원',
          members: 61,
          isActive: false,
          isRed: false,
        ),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _MeetupHeroCard extends StatelessWidget {
  const _MeetupHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.koreanRed, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.koreanRed.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -16,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'NETWORK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '지역 모임 / 네트워크',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '서울 · 부산 · 대구 · 평택 · 미국 등\n지역별 연결로 실제 행동력을 높입니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: AppColors.flagAccentGradient,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.shieldGradient,
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: AppColors.koreanBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Region card ──────────────────────────────────────────────────────────────

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.members,
    required this.isActive,
    required this.isRed,
  });
  final String flag;
  final String title;
  final String subtitle;
  final int members;
  final bool isActive;
  final bool isRed;

  @override
  Widget build(BuildContext context) {
    final color = isRed ? AppColors.koreanRed : AppColors.koreanBlue;
    final bgColor = isRed ? AppColors.softRed : AppColors.softBlue;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (isActive)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, isActive ? 14 : 18, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(flag, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '활성',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 14, color: color),
                          const SizedBox(width: 4),
                          Text(
                            '$members명 활동 중',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
