// lib/features/home/presentation/widgets/hero_stats_section.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/stats_store.dart';
import 'count_up_text.dart';

/// 홈 상단 헤로 섹션. 슬로건 + 부제 + 3개 통계 카운터.
class HeroStatsSection extends StatelessWidget {
  const HeroStatsSection({super.key});

  String _format(int value) {
    if (value >= 10000) return '${(value / 1000).round()}K';
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '우리의 목소리로\n대한민국을 바꾼다',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '보수 시민 네트워크의 새로운 플랫폼.\n일정·청원·커뮤니티를 한 곳에서 관리하세요.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          StreamBuilder<AppStats>(
            stream: StatsStore.watchStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? AppStats.empty();
              return _StatsRow(
                memberCount: stats.memberCount,
                activePetitions: stats.activePetitions,
                monthlyEvents: stats.monthlyEvents,
                format: _format,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.memberCount,
    required this.activePetitions,
    required this.monthlyEvents,
    required this.format,
  });

  final int memberCount;
  final int activePetitions;
  final int monthlyEvents;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: memberCount,
              label: '가입 회원',
              format: format,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatCell(
              value: activePetitions,
              label: '진행중 청원',
              format: format,
            ),
          ),
          _Divider(),
          Expanded(
            child: _StatCell(
              value: monthlyEvents,
              label: '이번달 행사',
              format: format,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.format,
  });

  final int value;
  final String label;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CountUpText(
          target: value,
          formatter: format,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.border,
    );
  }
}
