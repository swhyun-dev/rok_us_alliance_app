// lib/features/mission/presentation/mission_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MissionPage extends StatelessWidget {
  const MissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _MissionHeroCard(),
        SizedBox(height: 16),
        _MissionProgressCard(),
        SizedBox(height: 16),
        _MissionListSection(),
      ],
    );
  }
}

class _MissionHeroCard extends StatelessWidget {
  const _MissionHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.heroGradient,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '오늘의 행동 미션',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '한 명의 참여가 / 한 개의 공유가 / 한 번의 행동이 흐름을 만듭니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 16),
          _MissionPill(text: '포스터 공유'),
          SizedBox(height: 8),
          _MissionPill(text: '댓글 참여'),
          SizedBox(height: 8),
          _MissionPill(text: '지인 알림'),
        ],
      ),
    );
  }
}

class _MissionPill extends StatelessWidget {
  const _MissionPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MissionProgressCard extends StatelessWidget {
  const _MissionProgressCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '오늘의 진행률',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: const LinearProgressIndicator(
                value: 0.45,
                minHeight: 10,
                backgroundColor: AppColors.softBlue,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '3개 중 1개 완료 / 오늘의 행동을 이어가보세요.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionListSection extends StatelessWidget {
  const _MissionListSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _MissionTaskCard(
          number: '01',
          title: '행사 포스터 공유',
          description: '지인 단톡방 / 커뮤니티 / SNS에 행사 이미지를 1회 이상 공유하세요.',
          badgeText: '중요',
          badgeColor: AppColors.red,
        ),
        SizedBox(height: 12),
        _MissionTaskCard(
          number: '02',
          title: '댓글 참여',
          description: '관련 게시물에 응원의 댓글 또는 행사 참여 독려 댓글을 남겨주세요.',
          badgeText: '참여',
          badgeColor: AppColors.navy,
        ),
        SizedBox(height: 12),
        _MissionTaskCard(
          number: '03',
          title: '지인 초대',
          description: '토요일 일정 비워달라고 주변 사람 1명 이상에게 직접 알리세요.',
          badgeText: '확산',
          badgeColor: AppColors.red,
        ),
      ],
    );
  }
}

class _MissionTaskCard extends StatelessWidget {
  const _MissionTaskCard({
    required this.number,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
  });

  final String number;
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('미션 완료 체크'),
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