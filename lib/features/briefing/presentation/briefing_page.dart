// lib/features/briefing/presentation/briefing_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class BriefingPage extends StatelessWidget {
  const BriefingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: const [
        _BriefingHeroCard(),
        SizedBox(height: 14),
        _SummaryCard(),
        SizedBox(height: 18),
        _SectionHeader(title: '이번 주 브리핑', icon: Icons.article_outlined),
        SizedBox(height: 10),
        _IssueCard(
          title: '이번 주 핵심 공지',
          body: '이번 주 토요일 평택 미군기지 앞 행사 참여 독려가 핵심입니다. '
              '정확한 주소는 추후 재공지 예정이며, 우산 준비 안내가 포함됩니다.',
          tag: '현장 공지',
          isRed: true,
        ),
        SizedBox(height: 10),
        _IssueCard(
          title: '참여 시 유의사항',
          body: '질서와 배려를 지키고, 시비와 논쟁은 피해야 합니다. '
              '현장에서 감정적 대응보다 질서 있는 참여가 중요합니다.',
          tag: '행동 가이드',
          isRed: false,
        ),
        SizedBox(height: 10),
        _IssueCard(
          title: '확산 포인트',
          body: 'MAGA WITH ROK / WE GO TOGETHER / SAVE KOREA 등 핵심 슬로건을 '
              '중심으로 공유하면 메시지 통일감을 줄 수 있습니다.',
          tag: '확산',
          isRed: true,
        ),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _BriefingHeroCard extends StatelessWidget {
  const _BriefingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.koreanBlue.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
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
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'BRIEFING',
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
                '오늘의 이슈 브리핑',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '현장 공지 · 행동 가이드 · 확산 포인트를\n앱 안에서 바로 확인하세요.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              // Flag stripe
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

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.shieldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.campaign, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '핵심 한 줄 요약',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '행사 참여 · 메시지 확산 · 질서 있는 행동 유지를\n중심으로 이번 주 흐름을 만듭니다.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
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

// ─── Issue card ───────────────────────────────────────────────────────────────

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.body,
    required this.tag,
    required this.isRed,
  });
  final String title;
  final String body;
  final String tag;
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
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.65,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
