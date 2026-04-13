// 파일경로: lib/features/search/presentation/search_page.dart
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
  List<CommunityPost> _results = [];

  void _search(String keyword) {
    final result = CommunityPostStore.search(keyword);

    setState(() {
      _results = result;
    });

    SearchHistoryStore.add(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        backgroundColor: AppColors.navy,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _results.isEmpty
                ? _buildHistory()
                : _buildResultList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: '공지 / 게시글 검색',
                filled: true,
                fillColor: const Color(0xFFF4F5F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          )
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return ValueListenableBuilder<List<String>>(
      valueListenable: SearchHistoryStore.notifier,
      builder: (_, history, __) {
        if (history.isEmpty) {
          return const Center(child: Text('검색 기록이 없습니다.'));
        }

        return ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '최근 검색어',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...history.map((e) => ListTile(
              title: Text(e),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => SearchHistoryStore.remove(e),
              ),
              onTap: () {
                _controller.text = e;
                _search(e);
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildResultList() {
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, index) {
        final post = _results[index];

        return ListTile(
          leading: post.hasThumbnail
              ? Image.network(
            post.coverImageUrl,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : const Icon(Icons.article),

          title: Text(post.title),
          subtitle: Text(
            post.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CommunityPostDetailPage(postId: post.id),
              ),
            );
          },
        );
      },
    );
  }
}