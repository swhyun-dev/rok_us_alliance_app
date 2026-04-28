// lib/features/community/data/community_post_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/community_post.dart';

class CommunityPostPage {
  const CommunityPostPage({
    required this.posts,
    required this.cursor,
    required this.hasMore,
  });
  final List<CommunityPost> posts;
  final DocumentSnapshot? cursor;
  final bool hasMore;
}

class CommunityPostStore {
  CommunityPostStore._();

  static const int _pageSize = 20;
  static final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('posts');

  /// 모든 게시글을 createdAt 내림차순 + 핀 우선으로 구독.
  static Stream<List<CommunityPost>> watchAll({int limit = _pageSize}) {
    return _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(CommunityPost.fromFirestore).toList();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// 게시판 종류별 구독.
  static Stream<List<CommunityPost>> watchByBoard(
    CommunityBoardType boardType, {
    String region = '전체',
    int limit = _pageSize,
  }) {
    Query<Map<String, dynamic>> q = _col
        .where('isDeleted', isEqualTo: false)
        .where('boardType', isEqualTo: boardType.name);
    if (region != '전체') {
      q = q.where('region', isEqualTo: region);
    }
    return q
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(CommunityPost.fromFirestore).toList();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  /// 단일 게시글 실시간 구독.
  static Stream<CommunityPost?> watchById(String id) {
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CommunityPost.fromFirestore(doc);
    });
  }

  /// 페이지네이션. cursor=null 이면 첫 페이지.
  static Future<CommunityPostPage> fetchPage({
    DocumentSnapshot? cursor,
    int limit = _pageSize,
  }) async {
    Query<Map<String, dynamic>> q = _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (cursor != null) q = q.startAfterDocument(cursor);

    final snap = await q.get();
    final posts = snap.docs.map(CommunityPost.fromFirestore).toList();
    return CommunityPostPage(
      posts: posts,
      cursor: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length == limit,
    );
  }

  /// 키워드 단발 검색. Firestore는 full-text 미지원이라 클라이언트에서 필터.
  /// 작은 데이터셋 대상. 추후 Algolia 등으로 대체.
  static Future<List<CommunityPost>> search(String keyword) async {
    final k = keyword.trim().toLowerCase();
    if (k.isEmpty) return const [];
    final snap = await _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    final all = snap.docs.map(CommunityPost.fromFirestore);
    return all.where((p) {
      if (p.title.toLowerCase().contains(k)) return true;
      if (p.content.toLowerCase().contains(k)) return true;
      if (p.authorNickname.toLowerCase().contains(k)) return true;
      if (p.region.toLowerCase().contains(k)) return true;
      if (p.tags.any((t) => t.toLowerCase().contains(k))) return true;
      if (p.resourceLabel.toLowerCase().contains(k)) return true;
      return false;
    }).toList();
  }

  /// 새 게시글. 작성자 정보(authorId/Nickname/Level)는 호출자 책임.
  /// rules: 본인 글 + isDeleted=false + 카운트 0 + 일반 사용자는 isUrgent/Pinned=false.
  static Future<String> add(CommunityPost post) async {
    final ref = _col.doc();
    final draft = post.copyWith(
      id: ref.id,
      isDeleted: false,
      viewCount: 0,
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
    );
    await ref.set(draft.toMap());
    return ref.id;
  }

  /// 본인 글 수정. 카운트·플래그는 변경 금지(rules).
  static Future<void> update(String id, Map<String, dynamic> changes) async {
    await _col.doc(id).update({
      ...changes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 본인 글 soft delete. hard delete 는 admin Cloud Function 만.
  static Future<void> softDelete(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 조회수 +1.
  static Future<void> incrementView(String id) async {
    await _col.doc(id).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  /// 좋아요 토글. 서브컬렉션 posts/{id}/likes/{uid} 의 doc 을 만들거나
  /// 지운다. likeCount 와 작성자 점수 갱신은 onLikeReceived/onLikeRemoved
  /// Cloud Function 이 처리.
  static Future<void> setLike({
    required String postId,
    required String uid,
    required bool liked,
  }) async {
    final ref = _col.doc(postId).collection('likes').doc(uid);
    if (liked) {
      await ref.set({
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.delete();
    }
  }

  /// 본인이 해당 게시글에 좋아요 눌렀는지 1회 확인.
  static Future<bool> hasLiked({
    required String postId,
    required String uid,
  }) async {
    final doc = await _col.doc(postId).collection('likes').doc(uid).get();
    return doc.exists;
  }

  /// shareCount +1.
  static Future<void> bumpShareCount(String id) async {
    await _col.doc(id).update({
      'shareCount': FieldValue.increment(1),
    });
  }

  /// saveCount +1 / -1.
  static Future<void> bumpSaveCount(String id, {required bool saved}) async {
    await _col.doc(id).update({
      'saveCount': FieldValue.increment(saved ? 1 : -1),
    });
  }
}
