// lib/features/petition/presentation/widgets/petition_card.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/petition.dart';
import 'progress_bar.dart';

class PetitionCard extends StatelessWidget {
  const PetitionCard({
    super.key,
    required this.petition,
    required this.onTap,
  });

  final Petition petition;
  final VoidCallback onTap;

  static const Map<String, String> _categoryLabel = {
    'security': '안보',
    'economy': '경제',
    'education': '교육',
    'media': '언론',
    'judicial': '사법',
    'other': '기타',
  };

  Color get _ddayColor {
    if (petition.status == 'completed' || petition.status == 'expired') {
      return AppColors.textSecondary;
    }
    final diff = petition.deadline.difference(DateTime.now()).inDays;
    if (diff <= 1) return AppColors.koreanRed;
    if (diff <= 7) return AppColors.gold;
    return AppColors.koreanBlue;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _categoryLabel[petition.category] ?? petition.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.koreanBlue,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _ddayColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _ddayColor.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    petition.ddayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _ddayColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              petition.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              petition.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 14),
            PetitionProgressBar(percent: petition.progressPercent),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${petition.currentCount}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  ' / ${petition.targetCount} 명',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
