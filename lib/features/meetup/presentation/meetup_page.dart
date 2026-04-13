// lib/features/meetup/presentation/meetup_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MeetupPage extends StatelessWidget {
  const MeetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: const [
        _MeetupHeroCard(),
        SizedBox(height: 16),
        _RegionCard(
          title: '평택',
          subtitle: '캠프 험프리스 인근 / 이번 주 핵심 집결 지역',
          members: '126명 활동 중',
          icon: Icons.location_on,
          accent: AppColors.red,
        ),
        SizedBox(height: 12),
        _RegionCard(
          title: '서울',
          subtitle: '콘텐츠 확산 / 사전 모임 / 차량 공유 논의',
          members: '248명 활동 중',
          icon: Icons.groups,
          accent: AppColors.navy,
        ),
        SizedBox(height: 12),
        _RegionCard(
          title: '부산',
          subtitle: '지역 네트워크 정비 / 참여 인원 모집',
          members: '84명 활동 중',
          icon: Icons.people,
          accent: AppColors.red,
        ),
        SizedBox(height: 12),
        _RegionCard(
          title: '미국',
          subtitle: '해외 지지 메시지 / 온라인 확산 / 실시간 응원',
          members: '61명 활동 중',
          icon: Icons.public,
          accent: AppColors.navy,
        ),
      ],
    );
  }
}

class _MeetupHeroCard extends StatelessWidget {
  const _MeetupHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.red, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '지역 모임 / 네트워크',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '서울 / 부산 / 대구 / 평택 / 미국 등 지역별 연결로 실제 행동력을 높입니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.title,
    required this.subtitle,
    required this.members,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String members;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    members,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}