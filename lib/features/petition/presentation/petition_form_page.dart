// lib/features/petition/presentation/petition_form_page.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/petition_store.dart';
import '../domain/petition.dart';

/// 관리자 전용 — 외부 청원·입법법안 등록.
/// - 국민청원: 청원번호·제목·요약·외부URL·마감일 수동 입력
/// - 입법법안: 의안번호 입력 → fetchBillFromAssembly CF 가 pal.assembly.go.kr 에서
///   제목·진행현황 자동 조회. 관리자가 입장(주목/지지) 만 결정.
class PetitionFormPage extends StatefulWidget {
  const PetitionFormPage({
    super.key,
    this.initialTab = PetitionTab.nationalPetition,
  });

  final PetitionTab initialTab;

  @override
  State<PetitionFormPage> createState() => _PetitionFormPageState();
}

class _PetitionFormPageState extends State<PetitionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _externalUrlController = TextEditingController();
  final _sourceUrlController = TextEditingController();
  final _progressController = TextEditingController();

  late PetitionTab _tab;
  String _category = 'security';
  PetitionStance _stance = PetitionStance.oppose;
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _submitting = false;
  bool _fetching = false;
  String? _refError;

  static const List<({String code, String label})> _categories = [
    (code: 'security', label: '안보'),
    (code: 'economy', label: '경제'),
    (code: 'education', label: '교육'),
    (code: 'media', label: '언론'),
    (code: 'judicial', label: '사법'),
    (code: 'other', label: '기타'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void dispose() {
    _refController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _externalUrlController.dispose();
    _sourceUrlController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  bool get _isBill => _tab == PetitionTab.legislativeBill;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isAfter(now) ? _deadline : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  /// 입법법안: 의안번호 입력 → CF 가 pal.assembly.go.kr 에서 fetch.
  Future<void> _fetchBillInfo() async {
    final ref = _refController.text.trim();
    if (ref.isEmpty) {
      setState(() => _refError = '의안번호를 먼저 입력해주세요.');
      return;
    }
    setState(() {
      _fetching = true;
      _refError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('fetchBillFromAssembly');
      final result =
          await callable.call<Map<String, dynamic>>({'billNumber': ref});
      final data = result.data;
      final title = (data['title'] ?? '') as String;
      final progress = (data['progressStatus'] ?? '') as String;
      final externalUrl = (data['externalUrl'] ?? '') as String;
      if (!mounted) return;
      setState(() {
        if (title.isNotEmpty) _titleController.text = title;
        if (progress.isNotEmpty) _progressController.text = progress;
        if (externalUrl.isNotEmpty) _externalUrlController.text = externalUrl;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(title.isEmpty
              ? '국회 입법예고 사이트에서 해당 의안번호를 찾지 못했습니다. 직접 입력해주세요.'
              : '의안 정보를 가져왔습니다. 검토 후 등록해주세요.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refError = '의안 조회 실패: $e';
      });
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    final ref = _refController.text.trim();
    final type = _isBill
        ? PetitionType.legislativeBill
        : PetitionType.nationalPetition;

    setState(() {
      _submitting = true;
      _refError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 중복 등록 방지
      if (ref.isNotEmpty) {
        final taken = await PetitionStore.isReferenceTaken(
          type: type,
          referenceNumber: ref,
        );
        if (taken) {
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _refError = '이미 같은 번호로 등록된 항목이 있습니다.';
          });
          return;
        }
      }

      final petition = Petition(
        id: '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _category,
        type: type,
        stance: _isBill ? _stance : PetitionStance.neutral,
        externalUrl: _externalUrlController.text.trim(),
        sourceUrl: _sourceUrlController.text.trim(),
        referenceNumber: ref,
        progressStatus: _progressController.text.trim(),
        progressUpdatedAt:
            _progressController.text.trim().isNotEmpty ? DateTime.now() : null,
        startDate: DateTime.now(),
        deadline: _deadline,
        status: 'active',
      );
      await PetitionStore.add(petition);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(_isBill ? '입법법안을 등록했습니다.' : '국민청원을 등록했습니다.')),
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
      appBar: AppBar(title: const Text('청원·법안 등록')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _TypeToggle(
              current: _tab,
              onChanged: (v) {
                setState(() {
                  _tab = v;
                  // 청원으로 바꾸면 입장 초기화
                  if (v == PetitionTab.nationalPetition) {
                    _stance = PetitionStance.neutral;
                  } else if (_stance == PetitionStance.neutral) {
                    _stance = PetitionStance.oppose;
                  }
                });
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _refController,
              decoration: InputDecoration(
                labelText: _isBill ? '의안번호' : '청원번호',
                hintText: _isBill ? '예: 2210123' : '예: 2A0Z0G3PA1G',
                errorText: _refError,
                suffixIcon: _isBill
                    ? IconButton(
                        tooltip: '국회 입법예고에서 자동 조회',
                        icon: _fetching
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.4),
                              )
                            : const Icon(Icons.cloud_download_outlined),
                        onPressed: _fetching ? null : _fetchBillInfo,
                      )
                    : null,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) {
                  return _isBill ? '의안번호를 입력해주세요.' : '청원번호를 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목',
                hintText: '1~100자',
              ),
              maxLength: 100,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '제목을 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: '분야'),
              items: _categories
                  .map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(c.label),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            if (_isBill) ...[
              const SizedBox(height: 14),
              _StanceSelector(
                current: _stance,
                onChanged: (v) => setState(() => _stance = v),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _descController,
              maxLines: 6,
              maxLength: 1500,
              decoration: const InputDecoration(
                labelText: '요약·배경',
                hintText: '카드에 노출되는 짧은 설명. 자세한 내용은 외부 사이트에서.',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '요약을 입력해주세요.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _externalUrlController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: _isBill ? '국회 입법예고 URL' : '국회 청원 URL',
                hintText: _isBill
                    ? 'https://pal.assembly.go.kr/...'
                    : 'https://petitions.assembly.go.kr/...',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return '외부 URL은 필수입니다.';
                final uri = Uri.tryParse(t);
                if (uri == null || !uri.hasScheme) {
                  return '올바른 URL을 입력해주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sourceUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '큐레이터 출처 URL (선택)',
                hintText: 'https://vforkorea.com/...',
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final uri = Uri.tryParse(t);
                if (uri == null || !uri.hasScheme) {
                  return '올바른 URL을 입력해주세요.';
                }
                return null;
              },
            ),
            if (_isBill) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _progressController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: '진행 현황',
                  hintText: '예: 위원회 심사, 본회의 상정 대기',
                ),
              ),
            ],
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '마감일'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_deadline.year}.${_deadline.month.toString().padLeft(2, '0')}.${_deadline.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.koreanBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        _isBill ? '입법법안 등록' : '국민청원 등록',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.current, required this.onChanged});
  final PetitionTab current;
  final ValueChanged<PetitionTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleItem(
              label: '국민청원',
              icon: Icons.how_to_vote_outlined,
              selected: current == PetitionTab.nationalPetition,
              onTap: () => onChanged(PetitionTab.nationalPetition),
            ),
          ),
          Expanded(
            child: _ToggleItem(
              label: '입법법안',
              icon: Icons.gavel,
              selected: current == PetitionTab.legislativeBill,
              onTap: () => onChanged(PetitionTab.legislativeBill),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected
                    ? AppColors.koreanBlue
                    : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: selected
                    ? AppColors.koreanBlue
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StanceSelector extends StatelessWidget {
  const _StanceSelector({required this.current, required this.onChanged});
  final PetitionStance current;
  final ValueChanged<PetitionStance> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '입장 표기',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _StanceChip(
              label: '주목 법안 (반대 의견 권장)',
              color: AppColors.koreanRed,
              selected: current == PetitionStance.oppose,
              onTap: () => onChanged(PetitionStance.oppose),
            ),
            const SizedBox(width: 8),
            _StanceChip(
              label: '지지 법안 (찬성 의견 권장)',
              color: AppColors.koreanBlue,
              selected: current == PetitionStance.support,
              onTap: () => onChanged(PetitionStance.support),
            ),
          ],
        ),
      ],
    );
  }
}

class _StanceChip extends StatelessWidget {
  const _StanceChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : AppColors.white,
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: selected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
