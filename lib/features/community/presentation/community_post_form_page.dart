// lib/features/community/presentation/community_post_form_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/community_post_store.dart';
import '../domain/community_post.dart';

class CommunityPostFormPage extends StatefulWidget {
  const CommunityPostFormPage({
    super.key,
    this.initialPost,
    this.initialBoardType,
    this.initialRegion,
  });

  final CommunityPost? initialPost;
  final CommunityBoardType? initialBoardType;
  final String? initialRegion;

  @override
  State<CommunityPostFormPage> createState() => _CommunityPostFormPageState();
}

class _CommunityPostFormPageState extends State<CommunityPostFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _authorController;
  late final TextEditingController _regionController;
  late final TextEditingController _resourceLabelController;
  late final TextEditingController _resourceUrlController;
  late final TextEditingController _thumbnailUrlController;

  late CommunityBoardType _boardType;
  late CommunityResourceType _resourceType;
  bool _isSaving = false;

  bool get _isEdit => widget.initialPost != null;
  bool get _isResourceBoard => _boardType == CommunityBoardType.resource;

  @override
  void initState() {
    super.initState();
    final post = widget.initialPost;

    _titleController = TextEditingController(text: post?.title ?? '');
    _contentController = TextEditingController(text: post?.content ?? '');
    _authorController = TextEditingController(text: post?.author ?? '');
    _regionController = TextEditingController(
      text: post?.region ??
          widget.initialRegion ??
          (_resolveDefaultRegion(widget.initialBoardType) ?? '전국'),
    );
    _resourceLabelController =
        TextEditingController(text: post?.resourceLabel ?? '');
    _resourceUrlController = TextEditingController(text: post?.resourceUrl ?? '');
    _thumbnailUrlController =
        TextEditingController(text: post?.thumbnailUrl ?? '');

    _boardType = post?.boardType ?? widget.initialBoardType ?? CommunityBoardType.free;
    _resourceType = post?.resourceType == CommunityResourceType.none
        ? CommunityResourceType.url
        : (post?.resourceType ?? CommunityResourceType.url);
  }

  String? _resolveDefaultRegion(CommunityBoardType? boardType) {
    if (boardType == CommunityBoardType.meetup) {
      return widget.initialRegion == '전체' ? '' : widget.initialRegion;
    }
    if (boardType == CommunityBoardType.resource) {
      return '온라인';
    }
    return '전국';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _authorController.dispose();
    _regionController.dispose();
    _resourceLabelController.dispose();
    _resourceUrlController.dispose();
    _thumbnailUrlController.dispose();
    super.dispose();
  }

  void _save() {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final previous = widget.initialPost;

    final post = CommunityPost(
      id: previous?.id ?? 'post-${DateTime.now().millisecondsSinceEpoch}',
      boardType: _boardType,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      author: _authorController.text.trim(),
      region: _regionController.text.trim(),
      createdAt: previous?.createdAt ?? DateTime.now(),
      commentCount: previous?.commentCount ?? 0,
      likeCount: previous?.likeCount ?? 0,
      isPinned: previous?.isPinned ?? false,
      isLiked: previous?.isLiked ?? false,
      comments: previous?.comments ?? const [],
      resourceType: _isResourceBoard ? _resourceType : CommunityResourceType.none,
      resourceLabel: _isResourceBoard ? _resourceLabelController.text.trim() : '',
      resourceUrl: _isResourceBoard ? _resourceUrlController.text.trim() : '',
      thumbnailUrl: _thumbnailUrlController.text.trim(),
    );

    if (_isEdit) {
      CommunityPostStore.update(post);
    } else {
      CommunityPostStore.add(post);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '게시글 수정' : '게시글 작성'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                _SectionCard(
                  title: '기본 정보',
                  child: Column(
                    children: [
                      _LabeledField(
                        label: '게시판',
                        child: DropdownButtonFormField<CommunityBoardType>(
                          initialValue: _boardType,
                          items: const [
                            DropdownMenuItem(
                              value: CommunityBoardType.free,
                              child: Text('자유게시판'),
                            ),
                            DropdownMenuItem(
                              value: CommunityBoardType.meetup,
                              child: Text('지역모임'),
                            ),
                            DropdownMenuItem(
                              value: CommunityBoardType.resource,
                              child: Text('자료공유'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _boardType = value;
                              if (_boardType == CommunityBoardType.resource &&
                                  _regionController.text.trim().isEmpty) {
                                _regionController.text = '온라인';
                              }
                              if (_boardType == CommunityBoardType.free &&
                                  _regionController.text.trim().isEmpty) {
                                _regionController.text = '전국';
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '작성자',
                        child: TextFormField(
                          controller: _authorController,
                          decoration: const InputDecoration(
                            hintText: '예: 자유수호',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '작성자를 입력해주세요.';
                            }
                            if (value.trim().length < 2) {
                              return '작성자는 최소 2자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: _boardType == CommunityBoardType.meetup ? '지역' : '표시 지역',
                        child: TextFormField(
                          controller: _regionController,
                          decoration: InputDecoration(
                            hintText: _boardType == CommunityBoardType.meetup
                                ? '예: 서울 / 경기/평택 / 부산'
                                : '예: 전국 / 온라인',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '지역을 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '썸네일 이미지 URL',
                        child: TextFormField(
                          controller: _thumbnailUrlController,
                          decoration: const InputDecoration(
                            hintText: '예: https://.../thumbnail.jpg',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: '게시글 내용',
                  child: Column(
                    children: [
                      _LabeledField(
                        label: '제목',
                        child: TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: '게시글 제목을 입력해주세요.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '제목을 입력해주세요.';
                            }
                            if (value.trim().length < 5) {
                              return '제목은 최소 5자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: '본문',
                        child: TextFormField(
                          controller: _contentController,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            hintText: '자유롭게 내용을 작성해주세요.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '본문을 입력해주세요.';
                            }
                            if (value.trim().length < 10) {
                              return '본문은 최소 10자 이상 입력해주세요.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isResourceBoard) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: '자료 정보',
                    child: Column(
                      children: [
                        _LabeledField(
                          label: '자료 유형',
                          child: DropdownButtonFormField<CommunityResourceType>(
                            initialValue: _resourceType,
                            items: const [
                              DropdownMenuItem(
                                value: CommunityResourceType.youtube,
                                child: Text('유튜브'),
                              ),
                              DropdownMenuItem(
                                value: CommunityResourceType.image,
                                child: Text('이미지'),
                              ),
                              DropdownMenuItem(
                                value: CommunityResourceType.file,
                                child: Text('파일'),
                              ),
                              DropdownMenuItem(
                                value: CommunityResourceType.url,
                                child: Text('URL'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _resourceType = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LabeledField(
                          label: '자료 이름',
                          child: TextFormField(
                            controller: _resourceLabelController,
                            decoration: const InputDecoration(
                              hintText: '예: 추천 영상 / 문구파일 / 참고 링크',
                            ),
                            validator: (value) {
                              if (!_isResourceBoard) return null;
                              if (value == null || value.trim().isEmpty) {
                                return '자료 이름을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        _LabeledField(
                          label: '자료 링크 / 경로',
                          child: TextFormField(
                            controller: _resourceUrlController,
                            decoration: InputDecoration(
                              hintText: switch (_resourceType) {
                                CommunityResourceType.youtube =>
                                '예: https://www.youtube.com/watch?v=...',
                                CommunityResourceType.image =>
                                '예: https://.../image.jpg',
                                CommunityResourceType.file =>
                                '예: https://.../file.pdf',
                                CommunityResourceType.url =>
                                '예: https://example.com',
                                CommunityResourceType.none => '예: https://example.com',
                              },
                            ),
                            validator: (value) {
                              if (!_isResourceBoard) return null;
                              if (value == null || value.trim().isEmpty) {
                                return '자료 링크나 경로를 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      _isSaving
                          ? '저장 중...'
                          : (_isEdit ? '수정 저장' : '게시글 등록'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}