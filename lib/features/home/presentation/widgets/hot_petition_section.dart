// lib/features/home/presentation/widgets/hot_petition_section.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../petition/data/petition_store.dart';
import '../../../petition/domain/petition.dart';
import '../../../petition/presentation/petition_detail_page.dart';
import '../../../petition/presentation/widgets/progress_bar.dart';

class HotPetitionSection extends StatelessWidget {
  const HotPetitionSection({super.key, required this.onMore});

  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              '인기 청원',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton(onPressed: onMore, child: const Text('전체보기 →')),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Petition>>(
          stream: PetitionStore.watchFeatured(limit: 3),
          builder: (context, snapshot) {
            final list = snapshot.data ?? const <Petition>[];
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '진행 중인 청원이 없습니다.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: List.generate(list.length, (i) {
                  final p = list[i];
                  return Column(
                    children: [
                      _Row(
                        petition: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PetitionDetailPage(petitionId: p.id),
                          ),
                        ),
                      ),
                      if (i != list.length - 1)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.petition, required this.onTap});
  final Petition petition;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final stanceColor = petition.stance == PetitionStance.support
        ? AppColors.koreanBlue
        : AppColors.koreanRed;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  petition.isLegislativeBill
                      ? Icons.gavel
                      : Icons.how_to_vote_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    petition.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  petition.ddayLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.koreanRed,
                  ),
                ),
              ],
            ),
            if (petition.hasProgressBar) ...[
              const SizedBox(height: 8),
              PetitionProgressBar(
                percent: petition.progressPercent,
                height: 6,
                showLabel: false,
              ),
            ] else if (petition.stance != PetitionStance.neutral) ...[
              const SizedBox(height: 6),
              Text(
                petition.stanceLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: stanceColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
