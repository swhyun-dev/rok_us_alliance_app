// lib/features/community/data/community_comment_store.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/community_post.dart';

/// posts/{postId}/comments 서브컬렉션 접근.
class CommunityCommentStore {
  CommunityCommentStore._();

  static CollectionReference<Map<String, dynamic>> _col(String postId) =>
      FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments');

  static Stream<List<CommunityComment>> watchByPost(String postId) {
    return _col(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityComment.fromFirestore(postId, d)).toList());
  }

  /// 새 댓글. 카운트 갱신은 Cloud Function(onCommentCreated)이 처리.
  static Future<String> add({
    required String postId,
    required String authorId,
    required String authorNickname,
    int authorLevel = 1,
    required String content,
    String? parentCommentId,
  }) async {
    final ref = _col(postId).doc();
    await ref.set({
      'id': ref.id,
      'postId': postId,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'authorLevel': authorLevel,
      'content': content,
      'parentCommentId': parentCommentId,
      'isDeleted': false,
      'likeCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  static Future<void> softDelete({
    required String postId,
    required String commentId,
  }) async {
    await _col(postId).doc(commentId).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
