// lib/features/auth/presentation/terms_agreement_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../data/auth_store.dart';
import 'nickname_setup_page.dart';

class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key, required this.draft});

  final SocialSignupDraft draft;

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool _agreeTerms = false;
  bool _agreePrivacy = false;
  bool _agreeMarketing = false;

  bool get _allRequiredChecked => _agreeTerms && _agreePrivacy;
  bool get _allChecked => _agreeTerms && _agreePrivacy && _agreeMarketing;

  void _setAll(bool value) {
    setState(() {
      _agreeTerms = value;
      _agreePrivacy = value;
      _agreeMarketing = value;
    });
  }

  Future<void> _showLegalDoc(String title, String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => _LegalDocSheet(
          title: title,
          content: content,
          scrollController: scrollController,
          onClose: () => Navigator.pop(sheetContext),
        ),
      ),
    );
  }

  void _goNext() {
    if (!_allRequiredChecked) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NicknameSetupPage(
          draft: widget.draft,
          agreedMarketing: _agreeMarketing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '약관 동의',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '한미동맹단 가입을\n환영합니다',
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '서비스 이용을 위해 약관에 동의해주세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _AllAgreeRow(
                      value: _allChecked,
                      onChanged: _setAll,
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: AppColors.border, height: 24),
                    _AgreeRow(
                      label: '이용약관 동의',
                      isRequired: true,
                      value: _agreeTerms,
                      onChanged: (v) => setState(() => _agreeTerms = v),
                      onView: () => _showLegalDoc(
                        '이용약관',
                        'assets/legal/terms_v1.md',
                      ),
                    ),
                    _AgreeRow(
                      label: '개인정보처리방침 동의',
                      isRequired: true,
                      value: _agreePrivacy,
                      onChanged: (v) => setState(() => _agreePrivacy = v),
                      onView: () => _showLegalDoc(
                        '개인정보처리방침',
                        'assets/legal/privacy_v1.md',
                      ),
                    ),
                    _AgreeRow(
                      label: '마케팅 정보 수신 동의',
                      isRequired: false,
                      value: _agreeMarketing,
                      onChanged: (v) => setState(() => _agreeMarketing = v),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    disabledBackgroundColor: AppColors.border,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _allRequiredChecked ? _goNext : null,
                  child: const Text(
                    '다음',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

class _AllAgreeRow extends StatelessWidget {
  const _AllAgreeRow({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            _CheckBox(value: value, size: 26),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '약관 전체 동의',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreeRow extends StatelessWidget {
  const _AgreeRow({
    required this.label,
    required this.isRequired,
    required this.value,
    required this.onChanged,
    this.onView,
  });

  final String label;
  final bool isRequired;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onView;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            _CheckBox(value: value, size: 22),
            const SizedBox(width: 12),
            Text(
              isRequired ? '[필수] ' : '[선택] ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isRequired
                    ? AppColors.koreanRed
                    : AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onView != null)
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  '보기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.koreanBlue,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.value, required this.size});

  final bool value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value ? AppColors.koreanBlue : Colors.white,
        border: Border.all(
          color: value ? AppColors.koreanBlue : AppColors.border,
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }
}

class _LegalDocSheet extends StatelessWidget {
  const _LegalDocSheet({
    required this.title,
    required this.content,
    required this.scrollController,
    required this.onClose,
  });

  final String title;
  final String content;
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.7,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
