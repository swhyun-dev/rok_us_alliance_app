// 파일경로: lib/features/community/presentation/community_post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../app/theme/app_colors.dart';
import '../data/community_post_store.dart';
import '../domain/community_post.dart';
import 'community_post_form_page.dart';

class CommunityPostDetailPage extends StatefulWidget {
  const CommunityPostDetailPage({
    super.key,
    required this.postId,
  });

  final String postId;

  @override
  State<CommunityPostDetailPage> createState() => _CommunityPostDetailPageState();
}

class _CommunityPostDetailPageState extends State<CommunityPostDetailPage> {
  final TextEditingController _commentAuthorController =
  TextEditingController(text: '익명');
  final TextEditingController _commentController = TextEditingController();

  final Map<String, TextEditingController> _replyControllers = {};
  final Map<String, bool> _replyOpenMap = {};

  YoutubePlayerController? _youtubeController;
  String? _lastYoutubeId;
  bool _viewCounted = false;

  @override
  void dispose() {
    _commentAuthorController.dispose();
    _commentController.dispose();
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    _youtubeController?.close();
    super.dispose();
  }

  void _syncYoutubeController(CommunityPost post) {
    final id = post.youtubeVideoId;
    if (id == _lastYoutubeId) return;

    _youtubeController?.close();
    _youtubeController = null;
    _lastYoutubeId = id;

    if (id != null) {
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  void _ensureViewCount(CommunityPost post) {
    if (_viewCounted) return;
    _viewCounted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      CommunityPostStore.incrementView(post.id);
    });
  }

  TextEditingController _replyControllerOf(String commentId) {
    return _replyControllers.putIfAbsent(commentId, () => TextEditingController());
  }

  Future<void> _sharePost(CommunityPost post) async {
    await Share.share(
      '${post.title}\n\n${post.content}\n\n#${post.boardLabel}',
      subject: post.title,
    );
  }

  void _showReportSnack(String target) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$target 신고가 접수되었습니다.')),
    );
  }

  Future<void> _openResource(CommunityPost post) async {
    if (!post.hasResource || post.resourceUrl.trim().isEmpty) return;

    final uri = Uri.tryParse(post.resourceUrl.trim());
    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자료 링크 형식이 올바르지 않습니다.')),
      );
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자료를 열지 못했습니다.')),
      );
    }
  }

  Future<void> _deletePost(CommunityPost post) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 삭제'),
          content: const Text('이 게시글을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    CommunityPostStore.remove(post.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _addComment(CommunityPost post) {
    final author = _commentAuthorController.text.trim();
    final content = _commentController.text.trim();

    if (author.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('작성자와 댓글 내용을 입력해주세요.')),
      );
      return;
    }

    CommunityPostStore.addComment(
      postId: post.id,
      author: author,
      content: content,
    );

    _commentController.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글이 등록되었습니다.')),
    );
  }

  void _addReply({
    required CommunityPost post,
    required CommunityComment parent,
  }) {
    final content = _replyControllerOf(parent.id).text.trim();
    final author = _commentAuthorController.text.trim().isEmpty
        ? '익명'
        : _commentAuthorController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('답글 내용을 입력해주세요.')),
      );
      return;
    }

    CommunityPostStore.addComment(
      postId: post.id,
      author: author,
      content: content,
      parentCommentId: parent.id,
    );

    _replyControllerOf(parent.id).clear();
    setState(() {
      _replyOpenMap[parent.id] = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('답글이 등록되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<CommunityPost>>(
      valueListenable: CommunityPostStore.notifier,
      builder: (context, _, __) {
        final post = CommunityPostStore.findById(widget.postId);

        if (post == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('게시글 상세')),
            body: const Center(
              child: Text('삭제되었거나 존재하지 않는 게시글입니다.'),
            ),
          );
        }

        _ensureViewCount(post);
        _syncYoutubeController(post);

        final accent = switch (post.boardType) {
          CommunityBoardType.free => AppColors.navy,
          CommunityBoardType.meetup => AppColors.red,
          CommunityBoardType.resource => AppColors.royalBlue,
        };

        final rootComments = post.rootComments;

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: post.hasThumbnail ? 280 : 110,
                      leading: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      backgroundColor: AppColors.navy,
                      actions: [
                        IconButton(
                          onPressed: () => CommunityPostStore.toggleSave(post.id),
                          icon: Icon(
                            post.isSaved ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _sharePost(post),
                          icon: const Icon(Icons.share_outlined, color: Colors.white),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          onSelected: (value) async {
                            if (value == 'edit') {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CommunityPostFormPage(initialPost: post),
                                ),
                              );
                            } else if (value == 'delete') {
                              await _deletePost(post);
                            } else if (value == 'report') {
                              _showReportSnack('게시글');
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('수정')),
                            PopupMenuItem(value: 'delete', child: Text('삭제')),
                            PopupMenuItem(value: 'report', child: Text('신고')),
                          ],
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        background: post.hasThumbnail
                            ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              post.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFE9EEF8),
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.12),
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                            : Container(color: AppColors.navy),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _MetaChip(
                                  text: post.boardLabel,
                                  background: accent.withValues(alpha: 0.12),
                                  textColor: accent,
                                ),
                                if (post.isPopular)
                                  const _MetaChip(
                                    text: '인기글',
                                    background: Color(0xFFFDE9EA),
                                    textColor: AppColors.red,
                                  ),
                                if (post.region.isNotEmpty)
                                  _MetaChip(
                                    text: post.region,
                                    background: AppColors.softBlue,
                                    textColor: AppColors.navy,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.28,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Color(0xFFE1E3E8),
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          Text(
                                            post.author,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (post.authorBadge.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEAD7),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                post.authorBadge,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFD57A1F),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        post.authorDescription.isEmpty
                                            ? '${post.region} / ${post.timeLabel}'
                                            : post.authorDescription,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: const Color(0xFFF7F8FA),
                              ),
                              child: Row(
                                children: [
                                  _StatText(
                                    icon: Icons.remove_red_eye_outlined,
                                    text: '${post.viewCount}명이 봤어요',
                                  ),
                                  const SizedBox(width: 14),
                                  _StatText(
                                    icon: Icons.favorite_border,
                                    text: '좋아요 ${post.likeCount}',
                                  ),
                                  const SizedBox(width: 14),
                                  _StatText(
                                    icon: Icons.chat_bubble_outline,
                                    text: '댓글 ${post.commentCount}',
                                  ),
                                ],
                              ),
                            ),
                            if (post.tags.isNotEmpty) ...[
                              const SizedBox(height: 18),
                              const Text(
                                '추천 태그',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: post.tags
                                    .map(
                                      (tag) => Text(
                                    '#$tag',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.royalBlue,
                                    ),
                                  ),
                                )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: _ActionOutlinedButton(
                                    icon: post.isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    label: '좋아요 ${post.likeCount}',
                                    color: post.isLiked
                                        ? AppColors.red
                                        : AppColors.textPrimary,
                                    onTap: () => CommunityPostStore.toggleLike(post.id),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _ActionOutlinedButton(
                                    icon: post.isSaved
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    label: '저장 ${post.saveCount}',
                                    color: post.isSaved
                                        ? AppColors.navy
                                        : AppColors.textPrimary,
                                    onTap: () => CommunityPostStore.toggleSave(post.id),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              post.content,
                              style: const TextStyle(
                                fontSize: 18,
                                height: 1.8,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (post.boardType == CommunityBoardType.resource &&
                                post.hasResource) ...[
                              const SizedBox(height: 24),
                              if (post.isYoutube && _youtubeController != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: YoutubePlayer(
                                    controller: _youtubeController!,
                                    aspectRatio: 16 / 9,
                                  ),
                                ),
                              if (post.isImage && post.resourceUrl.trim().isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    post.resourceUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      color: const Color(0xFFF2F2F2),
                                      alignment: Alignment.center,
                                      child: const Text('이미지를 불러오지 못했습니다.'),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.attach_file, color: accent),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${post.resourceTypeLabel} 자료',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: accent,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            post.resourceLabel.isEmpty
                                                ? post.resourceUrl
                                                : post.resourceLabel,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FilledButton(
                                      onPressed: () => _openResource(post),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: accent,
                                      ),
                                      child: const Text('열기'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(
                      child: Divider(height: 1, thickness: 8, color: Color(0xFFF5F6F8)),
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                        child: Row(
                          children: [
                            Text(
                              '댓글 ${post.commentCount}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '등록순',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              '최신순',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (rootComments.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            '아직 댓글이 없습니다.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            final comment = rootComments[index];
                            final replies = post.repliesOf(comment.id);
                            final isReplyOpen = _replyOpenMap[comment.id] ?? false;
                            final replyController = _replyControllerOf(comment.id);

                            return _DetailCommentBlock(
                              comment: comment,
                              replies: replies,
                              isReplyOpen: isReplyOpen,
                              replyController: replyController,
                              onToggleReply: () {
                                setState(() {
                                  _replyOpenMap[comment.id] = !isReplyOpen;
                                });
                              },
                              onSubmitReply: () {
                                _addReply(post: post, parent: comment);
                              },
                              onReportComment: () => _showReportSnack('댓글'),
                            );
                          },
                          childCount: rootComments.length,
                        ),
                      ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 96),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Color(0xFFEAECEF)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.image_outlined),
                        color: AppColors.textSecondary,
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F5F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: TextField(
                            controller: _commentController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: '댓글을 입력해주세요.',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _addComment(post),
                        icon: const Icon(Icons.send_rounded),
                        color: AppColors.navy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.background,
    required this.textColor,
  });

  final String text;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  const _StatText({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ActionOutlinedButton extends StatelessWidget {
  const _ActionOutlinedButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _DetailCommentBlock extends StatelessWidget {
  const _DetailCommentBlock({
    required this.comment,
    required this.replies,
    required this.isReplyOpen,
    required this.replyController,
    required this.onToggleReply,
    required this.onSubmitReply,
    required this.onReportComment,
  });

  final CommunityComment comment;
  final List<CommunityComment> replies;
  final bool isReplyOpen;
  final TextEditingController replyController;
  final VoidCallback onToggleReply;
  final VoidCallback onSubmitReply;
  final VoidCallback onReportComment;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          _DetailCommentCard(
            comment: comment,
            onReply: onToggleReply,
            onReport: onReportComment,
          ),
          if (isReplyOpen)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F5F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: replyController,
                        decoration: const InputDecoration(
                          hintText: '답글을 입력해주세요.',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onSubmitReply,
                    icon: const Icon(Icons.subdirectory_arrow_right),
                    color: AppColors.navy,
                  ),
                ],
              ),
            ),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 52, top: 10),
              child: Column(
                children: replies
                    .map(
                      (reply) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ReplyCommentCard(
                      comment: reply,
                      onReport: onReportComment,
                    ),
                  ),
                )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailCommentCard extends StatelessWidget {
  const _DetailCommentCard({
    required this.comment,
    required this.onReply,
    required this.onReport,
  });

  final CommunityComment comment;
  final VoidCallback onReply;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE1E3E8),
          child: Icon(Icons.person, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    comment.author,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (comment.isFirstComment)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '첫 댓글',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (comment.isAuthor)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEAD7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '작성자',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD57A1F),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '지정면 / ${comment.timeLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                comment.content,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '좋아요 ${comment.likeCount}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: onReply,
                    child: const Row(
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          '답글',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
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
        IconButton(
          onPressed: onReport,
          icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ReplyCommentCard extends StatelessWidget {
  const _ReplyCommentCard({
    required this.comment,
    required this.onReport,
  });

  final CommunityComment comment;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.subdirectory_arrow_right,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${comment.author} / ${comment.timeLabel}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onReport,
            icon: const Icon(Icons.more_vert, size: 18),
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}