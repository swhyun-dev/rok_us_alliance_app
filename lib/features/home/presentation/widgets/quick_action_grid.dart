// lib/features/home/presentation/widgets/quick_action_grid.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({
    super.key,
    required this.onActionFeed,
    required this.onCalendar,
    required this.onPetition,
  });

  final VoidCallback onActionFeed;
  final VoidCallback onCalendar;
  final VoidCallback onPetition;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.campaign,
            title: '행동 동원',
            cta: '참여하기',
            iconColor: AppColors.koreanRed,
            iconBg: AppColors.softRed,
            onTap: onActionFeed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.calendar_today,
            title: '일정 관리',
            cta: '확인하기',
            iconColor: AppColors.koreanBlue,
            iconBg: AppColors.softBlue,
            onTap: onCalendar,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            icon: Icons.edit,
            title: '청원 서명',
            cta: '서명하기',
            iconColor: AppColors.gold,
            iconBg: AppColors.softSky,
            onTap: onPetition,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.cta,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String cta;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$cta →',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
