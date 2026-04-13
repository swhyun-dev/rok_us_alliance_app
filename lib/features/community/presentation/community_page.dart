// lib/features/community/presentation/community_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/community_post.dart';
import 'community_board_page.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const _CommunityHero(),
        const SizedBox(height: 16),
        _BoardEntryTile(
          title: '자유게시판',
          subtitle: '자유롭게 글을 쓰고 소통하는 일반 게시판',
          icon: Icons.forum_outlined,
          color: AppColors.navy,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityBoardPage(
                  boardType: CommunityBoardType.free,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _BoardEntryTile(
          title: '지역모임',
          subtitle: '전국 지역별 글과 모임 연결용 게시판',
          icon: Icons.groups_2_outlined,
          color: AppColors.red,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityBoardPage(
                  boardType: CommunityBoardType.meetup,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _BoardEntryTile(
          title: '자료공유',
          subtitle: '유튜브 / 이미지 / 파일 / URL 자료를 공유하는 게시판',
          icon: Icons.folder_open_outlined,
          color: AppColors.royalBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CommunityBoardPage(
                  boardType: CommunityBoardType.resource,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CommunityHero extends StatelessWidget {
  const _CommunityHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '커뮤니티',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '게시판별로 나누어 자유롭게 소통하고 / 지역별로 모이고 / 자료를 공유합니다.',
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

class _BoardEntryTile extends StatelessWidget {
  const _BoardEntryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
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
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}