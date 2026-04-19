// lib/features/search/presentation/search_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../community/data/community_post_store.dart';
import '../../community/domain/community_post.dart';
import '../../community/presentation/community_post_detail_page.dart';
import '../data/search_history_store.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<CommunityPost> _results = [];
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    final result = CommunityPostStore.search(trimmed);
    setState(() {
      _results = result;
      _hasSearched = true;
    });
    SearchHistoryStore.add(trimmed);
    _focusNode.unfocus();
  }

  void _clear() {
    setState(() {
      _results = [];
      _hasSearched = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FB),
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _SearchBar(
            controller: _controller,
            focusNode: _focusNode,
            onSearch: _search,
            onClear: _hasSearched ? _clear : null,
          ),
          Expanded(
            child: _hasSearched ? _buildResults() : _buildHistory(),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => Navigator.maybePop(context),
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkNavy, Color(0xFF0D1E50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: AppColors.shieldGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.search, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '검색',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                '게시글 · 공지 · 키워드',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(
          height: 3,
          decoration: const BoxDecoration(
            gradient: AppColors.flagAccentGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: SearchHistoryStore.notifier,
      builder: (_, history, __) {
        if (history.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.softBlue,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.manage_search_outlined,
                    size: 36,
                    color: AppColors.koreanBlue,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '검색 기록이 없습니다',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  '검색어를 입력해 게시글을 찾아보세요.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            _SectionHeader(
              title: '최근 검색어',
              icon: Icons.history_rounded,
              trailing: TextButton(
                onPressed: () {
                  SearchHistoryStore.clear();
                },
                child: const Text(
                  '전체 삭제',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: history
                  .map((e) => _HistoryChip(
                        label: e,
                        onTap: () {
                          _controller.text = e;
                          _search(e);
                        },
                        onRemove: () => SearchHistoryStore.remove(e),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: '추천 키워드',
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SuggestChip('평택'),
                _SuggestChip('집회'),
                _SuggestChip('한미동맹'),
                _SuggestChip('미군'),
                _SuggestChip('WE GO TOGETHER'),
                _SuggestChip('SAVE KOREA'),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.softRed,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.koreanRed,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '검색 결과가 없습니다',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '다른 키워드로 다시 시도해보세요.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: _results.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SectionHeader(
              title: '검색 결과 ${_results.length}건',
              icon: Icons.format_list_bulleted_rounded,
            ),
          );
        }
        final post = _results[index - 1];
        return _SearchResultCard(
          post: post,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CommunityPostDetailPage(postId: post.id)),
          ),
        );
      },
    );
  }
}

// ─── Search bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    this.onClear,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkNavy,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onSubmitted: onSearch,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '공지 · 게시글 · 키워드 검색',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.white.withValues(alpha: 0.60),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClear ?? () => onSearch(controller.text),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: onClear != null
                    ? const LinearGradient(
                        colors: [AppColors.koreanRed, Color(0xFF7A1320)],
                      )
                    : const LinearGradient(
                        colors: [AppColors.koreanBlue, Color(0xFF0D1E50)],
                      ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                onClear != null ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final Widget? trailing;

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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ─── History chip ─────────────────────────────────────────────────────────────

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onRemove,
  });
  final String label;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 6, top: 8, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.close,
                    size: 11, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Suggest chip ─────────────────────────────────────────────────────────────

class _SuggestChip extends StatelessWidget {
  const _SuggestChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: AppColors.koreanBlue.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.koreanBlue,
        ),
      ),
    );
  }
}

// ─── Search result card ───────────────────────────────────────────────────────

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.post, required this.onTap});
  final CommunityPost post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.koreanBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.softBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: post.hasThumbnail
                        ? Image.network(
                            post.coverImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported_outlined,
                              color: AppColors.koreanBlue,
                              size: 22,
                            ),
                          )
                        : const Icon(
                            Icons.article_outlined,
                            color: AppColors.koreanBlue,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          post.content,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
