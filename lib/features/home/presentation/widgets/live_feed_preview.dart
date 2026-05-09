// lib/features/home/presentation/widgets/live_feed_preview.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../community/data/community_post_store.dart';
import '../../../community/domain/community_post.dart';
import '../../../community/presentation/community_post_detail_page.dart';
import 'live_indicator.dart';

/// 최신 게시글 3개 구독해서 미리보기. 헤더에 LiveIndicator + '더보기' 텍스트.
class LiveFeedPreview extends StatelessWidget {
  const LiveFeedPreview({super.key, required this.onMore});

  final VoidCallback onMore;

  static const Map<String, Color> _categoryColors = {
    'urgent': AppColors.koreanRed,
    'policy': AppColors.koreanBlue,
    'network': AppColors.brightRed,
    'event': AppColors.gold,
    'general': AppColors.darkNavy,
  };

  Color _categoryColor(String category) =>
      _categoryColors[category] ?? AppColors.darkNavy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              '실시간 피드',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            const LiveIndicator(),
            const Spacer(),
            TextButton(
              onPressed: onMore,
              child: const Text('더보기 →'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<CommunityPost>>(
          stream: CommunityPostStore.watchAll(limit: 3),
          builder: (context, snapshot) {
            final list = (snapshot.data ?? const <CommunityPost>[])
                .take(3)
                .toList();
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '아직 게시글이 없습니다.',
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
              child: Column(
                children: List.generate(list.length, (i) {
                  final post = list[i];
                  return Column(
                    children: [
                      _PreviewItem(
                        post: post,
                        accent: _categoryColor(post.category),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostDetailPage(postId: post.id),
                          ),
                        ),
                      ),
                      if (i != list.length - 1)
                        const Divider(
                          height: 1,
                          color: AppColors.border,
                        ),
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

class _PreviewItem extends StatelessWidget {
  const _PreviewItem({
    required this.post,
    required this.accent,
    required this.onTap,
  });

  final CommunityPost post;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          post.timeLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.chat_bubble_outline,
                            size: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          '${post.commentCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.favorite_outline,
                            size: 12,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          '${post.likeCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
