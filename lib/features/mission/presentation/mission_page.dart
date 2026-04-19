// lib/features/mission/presentation/mission_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';

class MissionPage extends StatefulWidget {
  const MissionPage({super.key});

  @override
  State<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends State<MissionPage> {
  final Set<int> _completed = {};

  void _toggleComplete(int index) {
    setState(() {
      if (_completed.contains(index)) {
        _completed.remove(index);
      } else {
        _completed.add(index);
      }
    });
  }

  static const _missions = [
    (
      '01',
      '행사 포스터 공유',
      '지인 단톡방 / 커뮤니티 / SNS에 행사 이미지를 1회 이상 공유하세요.',
      '중요',
      true,
    ),
    (
      '02',
      '댓글 참여',
      '관련 게시물에 응원의 댓글 또는 행사 참여 독려 댓글을 남겨주세요.',
      '참여',
      false,
    ),
    (
      '03',
      '지인 초대',
      '토요일 일정 비워달라고 주변 사람 1명 이상에게 직접 알리세요.',
      '확산',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed.length;
    final total = _missions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        _MissionHeroCard(completedCount: completedCount, total: total),
        const SizedBox(height: 14),
        _ProgressCard(completedCount: completedCount, total: total),
        const SizedBox(height: 18),
        const _SectionHeader(title: '오늘의 미션', icon: Icons.rocket_launch_outlined),
        const SizedBox(height: 10),
        ...List.generate(_missions.length, (i) {
          final m = _missions[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _MissionTaskCard(
              number: m.$1,
              title: m.$2,
              description: m.$3,
              badgeText: m.$4,
              isRed: m.$5,
              isCompleted: _completed.contains(i),
              onToggle: () => _toggleComplete(i),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _MissionHeroCard extends StatelessWidget {
  const _MissionHeroCard({
    required this.completedCount,
    required this.total,
  });
  final int completedCount;
  final int total;

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
            right: -12,
            top: -12,
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
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'DAILY MISSION',
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
                '오늘의 행동 미션',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '한 명의 참여가 · 한 개의 공유가 · 한 번의 행동이\n흐름을 만듭니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _MiniMissionChip('포스터 공유'),
                  const SizedBox(width: 8),
                  _MiniMissionChip('댓글 참여'),
                  const SizedBox(width: 8),
                  _MiniMissionChip('지인 알림'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMissionChip extends StatelessWidget {
  const _MiniMissionChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Progress card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completedCount, required this.total});
  final int completedCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completedCount / total;
    final isAllDone = completedCount == total;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.shieldGradient,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '오늘의 진행률',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$completedCount / $total',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                isAllDone ? AppColors.gold : AppColors.koreanBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isAllDone
                ? '🎖 오늘의 모든 미션을 완료했습니다!'
                : '$total개 중 $completedCount개 완료 · 오늘의 행동을 이어가보세요.',
            style: TextStyle(
              fontSize: 12,
              color: isAllDone
                  ? AppColors.gold
                  : AppColors.textSecondary,
              fontWeight: isAllDone ? FontWeight.w700 : FontWeight.normal,
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

// ─── Mission task card ────────────────────────────────────────────────────────

class _MissionTaskCard extends StatelessWidget {
  const _MissionTaskCard({
    required this.number,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.isRed,
    required this.isCompleted,
    required this.onToggle,
  });
  final String number;
  final String title;
  final String description;
  final String badgeText;
  final bool isRed;
  final bool isCompleted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = isRed ? AppColors.koreanRed : AppColors.koreanBlue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppColors.softBlue.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? AppColors.koreanBlue.withValues(alpha: 0.30)
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.koreanBlue : color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: isCompleted
                        ? const LinearGradient(
                            colors: [AppColors.koreanBlue, AppColors.navy])
                        : AppColors.shieldGradient,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 24)
                      : Center(
                          child: Text(
                            number,
                            style: const TextStyle(
                              fontSize: 15,
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isCompleted
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: isCompleted
                            ? OutlinedButton.icon(
                                onPressed: onToggle,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.koreanBlue,
                                  side: BorderSide(
                                    color: AppColors.koreanBlue
                                        .withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                icon: const Icon(Icons.check_rounded,
                                    size: 16),
                                label: const Text('완료됨 · 취소하기',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                              )
                            : FilledButton(
                                onPressed: onToggle,
                                style: FilledButton.styleFrom(
                                  backgroundColor: color,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                                child: const Text('미션 완료 체크',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                              ),
                      ),
                    ],
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
