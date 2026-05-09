// lib/features/feed/presentation/feed_page.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../community/data/community_post_store.dart';
import '../../community/domain/community_post.dart';
import '../../community/presentation/community_post_detail_page.dart';
import '../../community/presentation/community_post_form_page.dart';
import '../../home/presentation/widgets/live_indicator.dart';
import '../../search/presentation/search_page.dart';

enum FeedFilter {
  all('전체', null),
  urgent('긴급', 'urgent'),
  policy('정책', 'policy'),
  network('네트워크', 'network'),
  event('행사', 'event');

  const FeedFilter(this.label, this.category);
  final String label;
  final String? category;
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  FeedFilter _filter = FeedFilter.all;

  static const Map<String, Color> _categoryColor = {
    'urgent': AppColors.koreanRed,
    'policy': AppColors.koreanBlue,
    'network': AppColors.brightRed,
    'event': AppColors.gold,
    'general': AppColors.darkNavy,
  };

  Stream<List<CommunityPost>> _stream() {
    if (_filter.category == null) {
      return CommunityPostStore.watchAll();
    }
    return CommunityPostStore.watchByCategory(_filter.category!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Header(),
          _SegmentBar(
            current: _filter,
            onSelect: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: StreamBuilder<List<CommunityPost>>(
              stream: _stream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '피드를 불러오지 못했습니다.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.koreanRed),
                      ),
                    ),
                  );
                }
                final list = snapshot.data;
                if (list == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(36),
                      child: Text(
                        '해당 카테고리에 글이 없습니다.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final post = list[i];
                      return _FeedItem(
                        post: post,
                        accent: _categoryColor[post.category] ??
                            AppColors.darkNavy,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CommunityPostDetailPage(postId: post.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.koreanBlue,
        foregroundColor: AppColors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CommunityPostFormPage(),
          ),
        ),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('글쓰기',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 4),
      child: Row(
        children: [
          const Text(
            '실시간 피드',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          const LiveIndicator(),
          const Spacer(),
          IconButton(
            tooltip: '검색',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.current, required this.onSelect});

  final FeedFilter current;
  final ValueChanged<FeedFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: FeedFilter.values.map((f) {
            final selected = f == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.koreanBlue : AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? AppColors.koreanBlue
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _FeedItem extends StatefulWidget {
  const _FeedItem({
    required this.post,
    required this.accent,
    required this.onTap,
  });

  final CommunityPost post;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // 1분마다 시간 라벨 갱신.
    _ticker = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: widget.accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 4),
                      Text(
                        post.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            post.timeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _MetricIcon(
                            icon: Icons.ios_share,
                            value: post.shareCount,
                          ),
                          const SizedBox(width: 12),
                          _MetricIcon(
                            icon: Icons.chat_bubble_outline,
                            value: post.commentCount,
                          ),
                          const SizedBox(width: 12),
                          _MetricIcon(
                            icon: Icons.favorite_outline,
                            value: post.likeCount,
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
      ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  const _MetricIcon({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 13,
            color: AppColors.textSecondary.withValues(alpha: 0.75)),
        const SizedBox(width: 3),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
