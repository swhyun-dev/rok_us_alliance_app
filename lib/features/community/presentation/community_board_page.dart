// lib/features/community/presentation/community_board_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/community_post_store.dart';
import '../domain/community_post.dart';
import 'community_post_detail_page.dart';
import 'community_post_form_page.dart';

class CommunityBoardPage extends StatefulWidget {
  const CommunityBoardPage({
    super.key,
    required this.boardType,
  });

  final CommunityBoardType boardType;

  @override
  State<CommunityBoardPage> createState() => _CommunityBoardPageState();
}

class _CommunityBoardPageState extends State<CommunityBoardPage> {
  String _selectedRegion = '전체';

  String get _title {
    switch (widget.boardType) {
      case CommunityBoardType.free:
        return '자유게시판';
      case CommunityBoardType.meetup:
        return '지역모임';
      case CommunityBoardType.resource:
        return '자료공유';
    }
  }

  Color get _accent {
    switch (widget.boardType) {
      case CommunityBoardType.free:
        return AppColors.navy;
      case CommunityBoardType.meetup:
        return AppColors.red;
      case CommunityBoardType.resource:
        return AppColors.royalBlue;
    }
  }

  List<String> get _regions {
    if (widget.boardType != CommunityBoardType.meetup) {
      return const ['전체'];
    }

    final regions = CommunityPostStore.getByBoard(CommunityBoardType.meetup)
        .map((e) => e.region)
        .toSet()
        .toList()
      ..sort();

    return ['전체', ...regions];
  }

  List<CommunityPost> _posts() {
    if (widget.boardType == CommunityBoardType.meetup) {
      return CommunityPostStore.getByBoardAndRegion(
        boardType: widget.boardType,
        region: _selectedRegion,
      );
    }
    return CommunityPostStore.getByBoard(widget.boardType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: ValueListenableBuilder<List<CommunityPost>>(
        valueListenable: CommunityPostStore.notifier,
        builder: (context, _, __) {
          final posts = _posts();

          return Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            posts.isEmpty ? '글 0' : '글 ${posts.length}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.boardType == CommunityBoardType.meetup) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: _regions
                              .map(
                                (region) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _RegionChip(
                                label: region,
                                selected: _selectedRegion == region,
                                onTap: () {
                                  setState(() {
                                    _selectedRegion = region;
                                  });
                                },
                              ),
                            ),
                          )
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: posts.isEmpty
                    ? const Center(
                  child: Text(
                    '표시할 게시글이 없습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
                    : ListView.separated(
                  itemCount: posts.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEDEDED)),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    return _BoardListItem(
                      post: post,
                      accent: _accent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostDetailPage(postId: post.id),
                          ),
                        );
                      },
                      onLike: () {
                        CommunityPostStore.toggleLike(post.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPostFormPage(
                initialBoardType: widget.boardType,
                initialRegion:
                widget.boardType == CommunityBoardType.meetup ? _selectedRegion : null,
              ),
            ),
          );
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text('글쓰기'),
      ),
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.red : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _BoardListItem extends StatelessWidget {
  const _BoardListItem({
    required this.post,
    required this.accent,
    required this.onTap,
    required this.onLike,
  });

  final CommunityPost post;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    final trailingThumb = _buildTrailingThumb();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isPinned)
              Container(
                margin: const EdgeInsets.only(top: 4, right: 8),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (post.boardType == CommunityBoardType.resource && post.hasResource)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.resourceTypeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      if (post.boardType == CommunityBoardType.resource && post.hasResource)
                        const SizedBox(width: 8),
                      if (post.boardType == CommunityBoardType.meetup)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            post.region,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if ((post.boardType == CommunityBoardType.resource && post.hasResource) ||
                      post.boardType == CommunityBoardType.meetup)
                    const SizedBox(height: 8),
                  Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    post.content,
                    maxLines: trailingThumb == null ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        post.author,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('·',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(width: 8),
                      Text(
                        post.timeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('·',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          )),
                      const SizedBox(width: 8),
                      Text(
                        '댓글 ${post.commentCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: onLike,
                        child: Row(
                          children: [
                            Icon(
                              post.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: post.isLiked ? AppColors.red : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: post.isLiked ? AppColors.red : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingThumb != null) ...[
              const SizedBox(width: 12),
              trailingThumb,
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildTrailingThumb() {
    final thumbUrl = post.listThumbnailUrl;
    if (thumbUrl.isEmpty) return null;

    final isYoutubeThumb = post.isYoutube;

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            thumbUrl,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _thumbPlaceholder(
              isYoutubeThumb ? 'YT' : 'IMG',
            ),
          ),
        ),
        if (isYoutubeThumb)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white),
          ),
      ],
    );
  }

  Widget _thumbPlaceholder(String label) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}