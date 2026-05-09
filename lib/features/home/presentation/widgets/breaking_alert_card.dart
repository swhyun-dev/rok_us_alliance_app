// lib/features/home/presentation/widgets/breaking_alert_card.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../community/domain/community_post.dart';
import '../../../community/presentation/community_post_detail_page.dart';

/// posts where isUrgent=true 1건 구독. 없으면 SizedBox.shrink.
class BreakingAlertCard extends StatelessWidget {
  const BreakingAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityPost>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('isUrgent', isEqualTo: true)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snap) =>
              snap.docs.map(CommunityPost.fromFirestore).toList()),
      builder: (context, snapshot) {
        final list = snapshot.data;
        if (list == null || list.isEmpty) return const SizedBox.shrink();
        final post = list.first;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPostDetailPage(postId: post.id),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.softRed,
              borderRadius: BorderRadius.circular(18),
              border: const Border(
                left: BorderSide(color: AppColors.koreanRed, width: 4),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.koreanRed,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        '긴급',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      post.timeLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  post.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
