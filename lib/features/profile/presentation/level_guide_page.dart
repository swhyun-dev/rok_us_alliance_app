// lib/features/profile/presentation/level_guide_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';

class _LevelTier {
  const _LevelTier({
    required this.level,
    required this.name,
    required this.minPoints,
    required this.color,
    required this.benefits,
  });

  final int level;
  final String name;
  final int minPoints;
  final Color color;
  final List<String> benefits;
}

const _tiers = <_LevelTier>[
  _LevelTier(
    level: 1,
    name: '새내기',
    minPoints: 0,
    color: AppColors.gradeLv1,
    benefits: ['커뮤니티 둘러보기', '청원·행사 일정 열람'],
  ),
  _LevelTier(
    level: 2,
    name: '시민',
    minPoints: 100,
    color: AppColors.gradeLv2,
    benefits: ['청원 서명 +50P 적립', '커뮤니티 게시글 작성'],
  ),
  _LevelTier(
    level: 3,
    name: '활동가',
    minPoints: 500,
    color: AppColors.gradeLv3,
    benefits: ['행사 체크인 +100P', '한미동맹단증 발급'],
  ),
  _LevelTier(
    level: 4,
    name: '핵심',
    minPoints: 2000,
    color: AppColors.gradeLv4,
    benefits: ['카드 골드 등급', '관리자 추천인 우선 검토'],
  ),
  _LevelTier(
    level: 5,
    name: '동지',
    minPoints: 5000,
    color: AppColors.gradeLv5,
    benefits: ['VIP 등급 표시', '특별 행사 우선 초대'],
  ),
];

class LevelGuidePage extends StatelessWidget {
  const LevelGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('등급 안내')),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: AuthStore.notifier,
        builder: (context, state, _) {
          final user = state.user;
          final points = user?.points ?? 0;
          final currentLevel = user?.level ?? 1;
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            itemCount: _tiers.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ProgressCard(points: points, currentLevel: currentLevel);
              }
              final tier = _tiers[index - 1];
              return _TierCard(
                tier: tier,
                isCurrent: tier.level == currentLevel,
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.points, required this.currentLevel});
  final int points;
  final int currentLevel;

  @override
  Widget build(BuildContext context) {
    final next = _tiers.firstWhere(
      (t) => t.level > currentLevel,
      orElse: () => _tiers.last,
    );
    final base = _tiers
        .where((t) => t.level == currentLevel)
        .map((t) => t.minPoints)
        .firstOrNull ??
        0;
    final span = (next.minPoints - base).clamp(1, 100000);
    final progress = ((points - base) / span).clamp(0, 1).toDouble();
    final remaining =
        currentLevel >= 5 ? 0 : (next.minPoints - points).clamp(0, 100000);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentLevel >= 5 ? '최고 등급 달성' : '다음 등급까지 ${remaining}P',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${points}P · Lv $currentLevel',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.tier, required this.isCurrent});
  final _LevelTier tier;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCurrent ? tier.color : AppColors.border,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Lv${tier.level}',
                style: TextStyle(
                  color: tier.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
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
                    Text(
                      tier.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tier.color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '현재',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${tier.minPoints}P 이상',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...tier.benefits.map((b) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, size: 14, color: tier.color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
