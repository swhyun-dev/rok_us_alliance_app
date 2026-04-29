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
  final FocusNode _focus = FocusNode();
  List<CommunityPost> _results = const [];
  bool _searching = false;
  bool _hasSearched = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    SearchHistoryStore.load();
    _focus.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String raw) async {
    final keyword = raw.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _searching = true;
      _hasSearched = true;
      _error = null;
    });
    SearchHistoryStore.add(keyword);
    _focus.unfocus();
    try {
      final hits = await CommunityPostStore.search(keyword);
      if (!mounted) return;
      setState(() => _results = hits);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _useHistoryEntry(String keyword) {
    _controller.text = keyword;
    _runSearch(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '제목·내용·태그·작성자 검색',
            border: InputBorder.none,
          ),
          onSubmitted: _runSearch,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _controller.clear();
                  _results = const [];
                  _hasSearched = false;
                });
                _focus.requestFocus();
              },
            ),
        ],
      ),
      body: _hasSearched ? _buildResults() : _buildHistory(),
    );
  }

  Widget _buildHistory() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: SearchHistoryStore.notifier,
      builder: (context, history, _) {
        if (history.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(36),
              child: Text(
                '최근 검색어가 없습니다.\n키워드를 입력해 게시글을 찾아보세요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  const Text(
                    '최근 검색어',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: SearchHistoryStore.clear,
                    child: const Text('전체 삭제'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: history.length,
                itemBuilder: (context, i) {
                  final keyword = history[i];
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(keyword),
                    onTap: () => _useHistoryEntry(keyword),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => SearchHistoryStore.remove(keyword),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResults() {
    if (_searching) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '검색 중 오류가 발생했습니다.\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.koreanRed),
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(36),
          child: Text(
            '검색 결과가 없습니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _results.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.border),
      itemBuilder: (context, i) {
        final post = _results[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          title: Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
          trailing: Text(
            post.timeLabel,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPostDetailPage(postId: post.id),
            ),
          ),
        );
      },
    );
  }
}
