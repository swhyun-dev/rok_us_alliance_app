// lib/features/community/data/community_post_store.dart
import 'package:flutter/foundation.dart';

import '../domain/community_post.dart';
import 'community_post_seed.dart';

class CommunityPostStore {
  CommunityPostStore._();

  static final ValueNotifier<List<CommunityPost>> notifier =
  ValueNotifier<List<CommunityPost>>([...CommunityPostSeed.posts]);

  static List<CommunityPost> get posts => notifier.value;

  static void add(CommunityPost post) {
    final updated = [post, ...notifier.value];
    notifier.value = _sorted(updated);
  }

  static void update(CommunityPost post) {
    final updated = notifier.value
        .map((e) => e.id == post.id ? post : e)
        .toList();
    notifier.value = _sorted(updated);
  }

  static void remove(String id) {
    notifier.value = notifier.value.where((e) => e.id != id).toList();
  }

  static CommunityPost? findById(String id) {
    try {
      return notifier.value.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static void toggleLike(String id) {
    final post = findById(id);
    if (post == null) return;

    final nextLiked = !post.isLiked;
    final nextLikeCount = nextLiked
        ? post.likeCount + 1
        : (post.likeCount > 0 ? post.likeCount - 1 : 0);

    update(
      post.copyWith(
        isLiked: nextLiked,
        likeCount: nextLikeCount,
      ),
    );
  }

  static void toggleSave(String id) {
    final post = findById(id);
    if (post == null) return;

    final nextSaved = !post.isSaved;
    final nextSaveCount = nextSaved
        ? post.saveCount + 1
        : (post.saveCount > 0 ? post.saveCount - 1 : 0);

    update(
      post.copyWith(
        isSaved: nextSaved,
        saveCount: nextSaveCount,
      ),
    );
  }

  static void addComment({
    required String postId,
    required String author,
    required String content,
    String? parentCommentId,
  }) {
    final post = findById(postId);
    if (post == null) return;

    final isFirstRoot =
        parentCommentId == null &&
            post.comments.where((e) => e.parentCommentId == null).isEmpty;

    final nextComments = [
      CommunityComment(
        id: 'cmt-${DateTime.now().millisecondsSinceEpoch}',
        author: author,
        content: content,
        createdAt: DateTime.now(),
        parentCommentId: parentCommentId,
        isFirstComment: isFirstRoot,
      ),
      ...post.comments,
    ];

    update(
      post.copyWith(
        comments: nextComments,
        commentCount: nextComments.length,
      ),
    );
  }

  static void incrementView(String id) {
    final post = findById(id);
    if (post == null) return;
    update(post.copyWith(viewCount: post.viewCount + 1));
  }

  static List<CommunityPost> getByBoard(CommunityBoardType boardType) {
    final filtered = notifier.value.where((e) => e.boardType == boardType).toList();
    return _sorted(filtered);
  }

  static List<CommunityPost> getByBoardAndRegion({
    required CommunityBoardType boardType,
    required String region,
  }) {
    final filtered = notifier.value.where((e) {
      if (e.boardType != boardType) return false;
      if (region == '전체') return true;
      return e.region == region;
    }).toList();

    return _sorted(filtered);
  }

  static List<CommunityPost> search(String keyword) {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return [];

    final filtered = notifier.value.where((post) {
      final inTitle = post.title.toLowerCase().contains(k);
      final inContent = post.content.toLowerCase().contains(k);
      final inAuthor = post.author.toLowerCase().contains(k);
      final inRegion = post.region.toLowerCase().contains(k);
      final inTags = post.tags.any((t) => t.toLowerCase().contains(k));
      final inResourceLabel = post.resourceLabel.toLowerCase().contains(k);

      return inTitle ||
          inContent ||
          inAuthor ||
          inRegion ||
          inTags ||
          inResourceLabel;
    }).toList();

    return _sorted(filtered);
  }

  static List<CommunityPost> _sorted(List<CommunityPost> list) {
    final copied = [...list];
    copied.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return copied;
  }
}