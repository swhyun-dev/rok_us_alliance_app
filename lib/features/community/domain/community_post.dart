// lib/features/community/domain/community_post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum CommunityBoardType {
  free,
  meetup,
  resource,
}

enum CommunityResourceType {
  none,
  youtube,
  file,
  url,
  image,
}

/// posts/{postId}/comments/{commentId} 서브컬렉션 문서.
class CommunityComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorNickname;
  final int authorLevel;
  final String content;
  final String? parentCommentId;
  final bool isDeleted;
  final int likeCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  // UI 보조 (서버 저장 X)
  final bool isAuthor;
  final bool isFirstComment;

  const CommunityComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorNickname,
    required this.content,
    required this.createdAt,
    this.authorLevel = 1,
    this.parentCommentId,
    this.isDeleted = false,
    this.likeCount = 0,
    this.updatedAt,
    this.isAuthor = false,
    this.isFirstComment = false,
  });

  bool get isReply => parentCommentId != null;

  String get author => authorNickname;

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  CommunityComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorNickname,
    int? authorLevel,
    String? content,
    String? parentCommentId,
    bool? isDeleted,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAuthor,
    bool? isFirstComment,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorLevel: authorLevel ?? this.authorLevel,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isDeleted: isDeleted ?? this.isDeleted,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAuthor: isAuthor ?? this.isAuthor,
      isFirstComment: isFirstComment ?? this.isFirstComment,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'authorLevel': authorLevel,
      'content': content,
      'parentCommentId': parentCommentId,
      'isDeleted': isDeleted,
      'likeCount': likeCount,
      'createdAt': createdAt.isAtSameMomentAs(DateTime(0))
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CommunityComment.fromFirestore(
    String postId,
    DocumentSnapshot doc,
  ) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};
    final ts = map['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final upd = map['updatedAt'];
    return CommunityComment(
      id: doc.id,
      postId: (map['postId'] as String?) ?? postId,
      authorId: (map['authorId'] ?? '') as String,
      authorNickname: (map['authorNickname'] ?? '') as String,
      authorLevel: (map['authorLevel'] ?? 1) as int,
      content: (map['content'] ?? '') as String,
      parentCommentId: map['parentCommentId'] as String?,
      isDeleted: (map['isDeleted'] ?? false) as bool,
      likeCount: (map['likeCount'] ?? 0) as int,
      createdAt: createdAt,
      updatedAt: upd is Timestamp ? upd.toDate() : null,
    );
  }
}

class CommunityPost {
  // ━━━ 식별자·작성자 ━━━
  final String id;
  final String authorId;
  final String authorNickname;
  final int authorLevel;

  // ━━━ 콘텐츠 ━━━
  final CommunityBoardType boardType;
  final String category; // v3: urgent / policy / network / event / general
  final String title;
  final String content;
  final String region;
  final List<String> imageUrls;

  // ━━━ 플래그 ━━━
  final bool isPinned;
  final bool isUrgent;
  final bool isDeleted;

  // ━━━ 카운트 (CF가 갱신) ━━━
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int shareCount;

  // ━━━ 시간 ━━━
  final DateTime createdAt;
  final DateTime? updatedAt;

  // ━━━ 리소스 (UI 보조) ━━━
  final CommunityResourceType resourceType;
  final String resourceLabel;
  final String resourceUrl;
  final String thumbnailUrl;

  // ━━━ UI 추가 메타 ━━━
  final int saveCount;
  final bool isPopular;
  final List<String> tags;
  final String authorBadge;
  final String authorDescription;

  // ━━━ 사용자별 상태 (서버 저장 X, 화면 단위 스냅샷) ━━━
  final bool isLiked;
  final bool isSaved;
  final List<CommunityComment> comments;

  /// 사용자별 좋아요/저장 상태와 댓글은 별도 구독으로 채움.
  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorNickname,
    required this.boardType,
    required this.title,
    required this.content,
    required this.region,
    required this.createdAt,
    this.authorLevel = 1,
    this.category = 'general',
    this.imageUrls = const [],
    this.isPinned = false,
    this.isUrgent = false,
    this.isDeleted = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.updatedAt,
    this.resourceType = CommunityResourceType.none,
    this.resourceLabel = '',
    this.resourceUrl = '',
    this.thumbnailUrl = '',
    this.saveCount = 0,
    this.isPopular = false,
    this.tags = const [],
    this.authorBadge = '',
    this.authorDescription = '',
    this.isLiked = false,
    this.isSaved = false,
    this.comments = const [],
  });

  /// 작성자 표시명 (UI 호환).
  String get author => authorNickname;

  String get boardLabel {
    switch (boardType) {
      case CommunityBoardType.free:
        return '자유게시판';
      case CommunityBoardType.meetup:
        return '지역모임';
      case CommunityBoardType.resource:
        return '자료공유';
    }
  }

  bool get hasResource => resourceType != CommunityResourceType.none;
  bool get isYoutube => resourceType == CommunityResourceType.youtube;
  bool get isImage => resourceType == CommunityResourceType.image;
  bool get hasThumbnail => coverImageUrl.isNotEmpty;

  String get resourceTypeLabel {
    switch (resourceType) {
      case CommunityResourceType.youtube:
        return '유튜브';
      case CommunityResourceType.file:
        return '파일';
      case CommunityResourceType.url:
        return 'URL';
      case CommunityResourceType.image:
        return '이미지';
      case CommunityResourceType.none:
        return '없음';
    }
  }

  String get timeLabel {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 1) return '방금 전';
    if (diff.inHours < 1) return '${diff.inMinutes}분 전';
    if (diff.inDays < 1) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  String? get youtubeVideoId {
    if (!isYoutube || resourceUrl.trim().isEmpty) return null;

    final url = resourceUrl.trim();

    final short = RegExp(r'youtu\.be/([a-zA-Z0-9_-]{6,})').firstMatch(url);
    if (short != null) return short.group(1);

    final watch = RegExp(r'[?&]v=([a-zA-Z0-9_-]{6,})').firstMatch(url);
    if (watch != null) return watch.group(1);

    final embed = RegExp(r'embed/([a-zA-Z0-9_-]{6,})').firstMatch(url);
    if (embed != null) return embed.group(1);

    return null;
  }

  String? get youtubeThumbnailUrl {
    final id = youtubeVideoId;
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/0.jpg';
  }

  String get listThumbnailUrl {
    if (isImage && resourceUrl.trim().isNotEmpty) return resourceUrl.trim();
    if (isYoutube && youtubeThumbnailUrl != null) return youtubeThumbnailUrl!;
    return thumbnailUrl.trim();
  }

  String get coverImageUrl {
    if (thumbnailUrl.trim().isNotEmpty) return thumbnailUrl.trim();
    if (isImage && resourceUrl.trim().isNotEmpty) return resourceUrl.trim();
    if (isYoutube && youtubeThumbnailUrl != null) return youtubeThumbnailUrl!;
    return '';
  }

  List<CommunityComment> get rootComments =>
      comments.where((e) => e.parentCommentId == null).toList();

  List<CommunityComment> repliesOf(String commentId) =>
      comments.where((e) => e.parentCommentId == commentId).toList();

  CommunityPost copyWith({
    String? id,
    String? authorId,
    String? authorNickname,
    int? authorLevel,
    CommunityBoardType? boardType,
    String? category,
    String? title,
    String? content,
    String? region,
    List<String>? imageUrls,
    bool? isPinned,
    bool? isUrgent,
    bool? isDeleted,
    int? viewCount,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    CommunityResourceType? resourceType,
    String? resourceLabel,
    String? resourceUrl,
    String? thumbnailUrl,
    int? saveCount,
    bool? isPopular,
    List<String>? tags,
    String? authorBadge,
    String? authorDescription,
    bool? isLiked,
    bool? isSaved,
    List<CommunityComment>? comments,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorNickname: authorNickname ?? this.authorNickname,
      authorLevel: authorLevel ?? this.authorLevel,
      boardType: boardType ?? this.boardType,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      region: region ?? this.region,
      imageUrls: imageUrls ?? this.imageUrls,
      isPinned: isPinned ?? this.isPinned,
      isUrgent: isUrgent ?? this.isUrgent,
      isDeleted: isDeleted ?? this.isDeleted,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resourceType: resourceType ?? this.resourceType,
      resourceLabel: resourceLabel ?? this.resourceLabel,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      saveCount: saveCount ?? this.saveCount,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      authorBadge: authorBadge ?? this.authorBadge,
      authorDescription: authorDescription ?? this.authorDescription,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      comments: comments ?? this.comments,
    );
  }

  /// Firestore 쓰기용. 화면 단위 상태(isLiked/isSaved/comments)는 제외.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorNickname': authorNickname,
      'authorLevel': authorLevel,
      'boardType': boardType.name,
      'category': category,
      'title': title,
      'content': content,
      'region': region,
      'imageUrls': imageUrls,
      'isPinned': isPinned,
      'isUrgent': isUrgent,
      'isDeleted': isDeleted,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'shareCount': shareCount,
      'createdAt': createdAt.isAtSameMomentAs(DateTime(0))
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'resourceType': resourceType.name,
      'resourceLabel': resourceLabel,
      'resourceUrl': resourceUrl,
      'thumbnailUrl': thumbnailUrl,
      'saveCount': saveCount,
      'isPopular': isPopular,
      'tags': tags,
      'authorBadge': authorBadge,
      'authorDescription': authorDescription,
    };
  }

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>?) ?? const {};

    final ts = map['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    final upd = map['updatedAt'];

    final boardName = (map['boardType'] ?? 'free') as String;
    final board = CommunityBoardType.values.firstWhere(
      (e) => e.name == boardName,
      orElse: () => CommunityBoardType.free,
    );
    final resourceName = (map['resourceType'] ?? 'none') as String;
    final resource = CommunityResourceType.values.firstWhere(
      (e) => e.name == resourceName,
      orElse: () => CommunityResourceType.none,
    );

    return CommunityPost(
      id: doc.id,
      authorId: (map['authorId'] ?? '') as String,
      authorNickname: (map['authorNickname'] ?? '') as String,
      authorLevel: (map['authorLevel'] ?? 1) as int,
      boardType: board,
      category: (map['category'] ?? 'general') as String,
      title: (map['title'] ?? '') as String,
      content: (map['content'] ?? '') as String,
      region: (map['region'] ?? '전국') as String,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      isPinned: (map['isPinned'] ?? false) as bool,
      isUrgent: (map['isUrgent'] ?? false) as bool,
      isDeleted: (map['isDeleted'] ?? false) as bool,
      viewCount: (map['viewCount'] ?? 0) as int,
      likeCount: (map['likeCount'] ?? 0) as int,
      commentCount: (map['commentCount'] ?? 0) as int,
      shareCount: (map['shareCount'] ?? 0) as int,
      createdAt: createdAt,
      updatedAt: upd is Timestamp ? upd.toDate() : null,
      resourceType: resource,
      resourceLabel: (map['resourceLabel'] ?? '') as String,
      resourceUrl: (map['resourceUrl'] ?? '') as String,
      thumbnailUrl: (map['thumbnailUrl'] ?? '') as String,
      saveCount: (map['saveCount'] ?? 0) as int,
      isPopular: (map['isPopular'] ?? false) as bool,
      tags: List<String>.from(map['tags'] ?? const []),
      authorBadge: (map['authorBadge'] ?? '') as String,
      authorDescription: (map['authorDescription'] ?? '') as String,
    );
  }
}
