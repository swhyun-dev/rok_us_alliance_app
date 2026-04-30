// lib/features/community/presentation/community_post_form_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../data/community_post_store.dart';
import '../domain/community_post.dart';

/// 트위터(X) 스타일의 짧은 글 작성 화면.
/// - 본문 280자 + 카테고리 칩 1개 선택
/// - 제목은 본문 첫 줄에서 자동 추출 (모델의 title 필드 채우기용)
/// - 옛 게시판 필드(boardType/region/resourceUrl/thumbnail) 는 기본값 고정
class CommunityPostFormPage extends StatefulWidget {
  const CommunityPostFormPage({super.key, this.initialPost});

  final CommunityPost? initialPost;

  @override
  State<CommunityPostFormPage> createState() => _CommunityPostFormPageState();
}

class _CommunityPostFormPageState extends State<CommunityPostFormPage> {
  static const int _maxLength = 280;

  late final TextEditingController _contentController;

  String _category = 'general';
  bool _submitting = false;

  bool get _isEdit => widget.initialPost != null;

  static const List<({String code, String label, Color color})> _categories = [
    (code: 'urgent', label: '긴급', color: AppColors.koreanRed),
    (code: 'policy', label: '정책', color: AppColors.koreanBlue),
    (code: 'network', label: '네트워크', color: AppColors.brightRed),
    (code: 'event', label: '행사', color: AppColors.gold),
    (code: 'general', label: '일반', color: AppColors.darkNavy),
  ];

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;
    _contentController = TextEditingController(text: post?.content ?? '');
    if (post != null) {
      _category = post.category.isNotEmpty ? post.category : 'general';
    }
    _contentController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  int get _currentLength => _contentController.text.characters.length;
  int get _remaining => _maxLength - _currentLength;

  bool get _canSubmit {
    final trimmed = _contentController.text.trim();
    return trimmed.isNotEmpty &&
        _currentLength <= _maxLength &&
        !_submitting;
  }

  /// 본문 첫 줄(또는 첫 30자)을 제목으로 추출.
  String _deriveTitle(String content) {
    final firstLine = content.split('\n').first.trim();
    if (firstLine.isEmpty) return content.trim();
    if (firstLine.characters.length <= 30) return firstLine;
    return '${firstLine.characters.take(30).toString()}…';
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final user = AuthStore.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final content = _contentController.text.trim();
      final title = _deriveTitle(content);
      final isUrgent = _category == 'urgent';

      if (_isEdit) {
        await CommunityPostStore.update(widget.initialPost!.id, {
          'title': title,
          'content': content,
          'category': _category,
          'isUrgent': isUrgent,
        });
      } else {
        final draft = CommunityPost(
          id: '',
          authorId: user.providerUserId,
          authorNickname:
              user.nickname.isNotEmpty ? user.nickname : user.name,
          authorLevel: user.level,
          boardType: CommunityBoardType.free,
          category: _category,
          title: title,
          content: content,
          region: '전국',
          createdAt: DateTime(0), // serverTimestamp 사용
          isUrgent: isUrgent,
        );
        await CommunityPostStore.add(draft);
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_isEdit ? '글을 수정했습니다.' : '+30P 적립! 글이 게시되었습니다.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('등록 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEdit ? '글 수정' : '새 글',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.koreanBlue,
                disabledBackgroundColor:
                    AppColors.koreanBlue.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              ),
              onPressed: _canSubmit ? _submit : null,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEdit ? '저장' : '게시',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  autofocus: true,
                  decoration: const InputDecoration.collapsed(
                    hintText: '지금 어떤 일이 있나요?',
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const Divider(height: 0, color: AppColors.border),
            _CategoryChips(
              current: _category,
              categories: _categories,
              onSelect: (c) => setState(() => _category = c),
            ),
            _Footer(remaining: _remaining, max: _maxLength),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.current,
    required this.categories,
    required this.onSelect,
  });

  final String current;
  final List<({String code, String label, Color color})> categories;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final selected = c.code == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelect(c.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? c.color : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected ? c.color : AppColors.border,
                    ),
                  ),
                  child: Text(
                    c.label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

class _Footer extends StatelessWidget {
  const _Footer({required this.remaining, required this.max});
  final int remaining;
  final int max;

  @override
  Widget build(BuildContext context) {
    final overflow = remaining < 0;
    final warn = remaining <= 20 && !overflow;
    final color = overflow
        ? AppColors.koreanRed
        : (warn ? AppColors.gold : AppColors.textSecondary);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              value: ((max - remaining) / max).clamp(0.0, 1.0),
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(color),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$remaining',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
