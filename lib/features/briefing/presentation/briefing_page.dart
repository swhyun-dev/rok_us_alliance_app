// lib/features/briefing/presentation/briefing_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class BriefingPage extends StatelessWidget {
  const BriefingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _BriefingHeroCard(),
        SizedBox(height: 16),
        _BriefingSummaryCard(),
        SizedBox(height: 16),
        _IssueCard(
          title: '이번 주 핵심 공지',
          body:
          '이번 주 토요일 평택 미군기지 앞 행사 참여 독려가 핵심입니다. 정확한 주소는 추후 재공지 예정이며, 우산 준비 안내가 포함됩니다.',
          tag: '현장 공지',
          tagColor: AppColors.red,
        ),
        SizedBox(height: 12),
        _IssueCard(
          title: '참여 시 유의사항',
          body:
          '질서와 배려를 지키고, 시비와 논쟁은 피해야 합니다. 현장에서 감정적 대응보다 질서 있는 참여가 중요합니다.',
          tag: '행동 가이드',
          tagColor: AppColors.navy,
        ),
        SizedBox(height: 12),
        _IssueCard(
          title: '확산 포인트',
          body:
          'MAGA WITH ROK / WE GO TOGETHER / SAVE KOREA 등 핵심 슬로건을 중심으로 공유하면 메시지 통일감을 줄 수 있습니다.',
          tag: '확산',
          tagColor: AppColors.red,
        ),
      ],
    );
  }
}

class _BriefingHeroCard extends StatelessWidget {
  const _BriefingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopFlagLine(),
          SizedBox(height: 14),
          Text(
            '오늘의 이슈 브리핑',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '현장 공지 / 행동 가이드 / 확산 포인트를 앱 안에서 바로 확인할 수 있게 구성합니다.',
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopFlagLine extends StatelessWidget {
  const _TopFlagLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 28, height: 6, color: AppColors.red),
        Container(width: 28, height: 6, color: AppColors.white),
        Container(width: 28, height: 6, color: AppColors.navy),
      ],
    );
  }
}

class _BriefingSummaryCard extends StatelessWidget {
  const _BriefingSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.campaign,
                color: AppColors.navy,
                size: 28,
              ),
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
                    '행사 참여 / 메시지 확산 / 질서 있는 행동 유지를 중심으로 이번 주 흐름을 만듭니다.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({
    required this.title,
    required this.body,
    required this.tag,
    required this.tagColor,
  });

  final String title;
  final String body;
  final String tag;
  final Color tagColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: tagColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
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
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}