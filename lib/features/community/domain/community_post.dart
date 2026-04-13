// 파일경로: lib/features/community/domain/community_post.dart
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

class CommunityComment {
  final String id;
  final String author;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final bool isAuthor;
  final bool isFirstComment;
  final String? parentCommentId;

  const CommunityComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.isAuthor = false,
    this.isFirstComment = false,
    this.parentCommentId,
  });

  bool get isReply => parentCommentId != null;

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
    String? author,
    String? content,
    DateTime? createdAt,
    int? likeCount,
    bool? isAuthor,
    bool? isFirstComment,
    String? parentCommentId,
  }) {
    return CommunityComment(
      id: id ?? this.id,
      author: author ?? this.author,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      likeCount: likeCount ?? this.likeCount,
      isAuthor: isAuthor ?? this.isAuthor,
      isFirstComment: isFirstComment ?? this.isFirstComment,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}

class CommunityPost {
  final String id;
  final CommunityBoardType boardType;
  final String title;
  final String content;
  final String author;
  final String region;
  final DateTime createdAt;
  final int commentCount;
  final int likeCount;
  final bool isPinned;
  final bool isLiked;
  final List<CommunityComment> comments;

  final CommunityResourceType resourceType;
  final String resourceLabel;
  final String resourceUrl;
  final String thumbnailUrl;

  final int viewCount;
  final int saveCount;
  final bool isSaved;
  final bool isPopular;
  final List<String> tags;
  final String authorBadge;
  final String authorDescription;

  const CommunityPost({
    required this.id,
    required this.boardType,
    required this.title,
    required this.content,
    required this.author,
    required this.region,
    required this.createdAt,
    required this.commentCount,
    required this.likeCount,
    this.isPinned = false,
    this.isLiked = false,
    this.comments = const [],
    this.resourceType = CommunityResourceType.none,
    this.resourceLabel = '',
    this.resourceUrl = '',
    this.thumbnailUrl = '',
    this.viewCount = 0,
    this.saveCount = 0,
    this.isSaved = false,
    this.isPopular = false,
    this.tags = const [],
    this.authorBadge = '',
    this.authorDescription = '',
  });

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
    CommunityBoardType? boardType,
    String? title,
    String? content,
    String? author,
    String? region,
    DateTime? createdAt,
    int? commentCount,
    int? likeCount,
    bool? isPinned,
    bool? isLiked,
    List<CommunityComment>? comments,
    CommunityResourceType? resourceType,
    String? resourceLabel,
    String? resourceUrl,
    String? thumbnailUrl,
    int? viewCount,
    int? saveCount,
    bool? isSaved,
    bool? isPopular,
    List<String>? tags,
    String? authorBadge,
    String? authorDescription,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      boardType: boardType ?? this.boardType,
      title: title ?? this.title,
      content: content ?? this.content,
      author: author ?? this.author,
      region: region ?? this.region,
      createdAt: createdAt ?? this.createdAt,
      commentCount: commentCount ?? this.commentCount,
      likeCount: likeCount ?? this.likeCount,
      isPinned: isPinned ?? this.isPinned,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
      resourceType: resourceType ?? this.resourceType,
      resourceLabel: resourceLabel ?? this.resourceLabel,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
      isSaved: isSaved ?? this.isSaved,
      isPopular: isPopular ?? this.isPopular,
      tags: tags ?? this.tags,
      authorBadge: authorBadge ?? this.authorBadge,
      authorDescription: authorDescription ?? this.authorDescription,
    );
  }
}