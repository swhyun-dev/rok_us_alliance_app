// lib/features/auth/presentation/nickname_setup_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_store.dart';

class NicknameSetupPage extends StatefulWidget {
  const NicknameSetupPage({
    super.key,
    required this.draft,
    required this.agreedMarketing,
  });

  final SocialSignupDraft draft;
  final bool agreedMarketing;

  @override
  State<NicknameSetupPage> createState() => _NicknameSetupPageState();
}

class _NicknameSetupPageState extends State<NicknameSetupPage> {
  static const int _minLen = 2;
  static const int _maxLen = 12;
  static final RegExp _allowedChars =
      RegExp(r'^[가-힣a-zA-Z0-9]+$');
  static const Duration _debounce = Duration(milliseconds: 500);

  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;

  String _input = '';
  String? _errorMessage;
  bool _checkingDuplicate = false;
  bool _availableConfirmed = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final seed = widget.draft.nickname.trim();
    if (seed.isNotEmpty && seed.length <= _maxLen) {
      _controller.text = seed;
      _onInput(seed);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _canSubmit =>
      _availableConfirmed && !_checkingDuplicate && !_isSubmitting;

  void _onInput(String value) {
    final trimmed = value.trim();
    setState(() {
      _input = trimmed;
      _availableConfirmed = false;
    });
    _debounceTimer?.cancel();

    final localError = _validateLocally(trimmed);
    if (localError != null) {
      setState(() {
        _errorMessage = localError;
        _checkingDuplicate = false;
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _checkingDuplicate = true;
    });

    _debounceTimer = Timer(_debounce, () => _checkDuplicate(trimmed));
  }

  String? _validateLocally(String value) {
    if (value.isEmpty) return null;
    if (value.length < _minLen) return '$_minLen자 이상 입력해주세요.';
    if (value.length > _maxLen) return '$_maxLen자 이하로 입력해주세요.';
    if (!_allowedChars.hasMatch(value)) {
      return '한글·영문·숫자만 사용할 수 있습니다.';
    }
    return null;
  }

  Future<void> _checkDuplicate(String value) async {
    try {
      final available = await AuthStore.isNicknameAvailable(value);
      if (!mounted || _input != value) return;
      setState(() {
        _checkingDuplicate = false;
        if (available) {
          _availableConfirmed = true;
          _errorMessage = null;
        } else {
          _availableConfirmed = false;
          _errorMessage = '이미 사용 중인 닉네임입니다.';
        }
      });
    } catch (_) {
      if (!mounted || _input != value) return;
      setState(() {
        _checkingDuplicate = false;
        _availableConfirmed = false;
        _errorMessage = '중복 확인에 실패했습니다. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _isSubmitting = true);

    try {
      await AuthStore.completeSignup(
        draft: widget.draft,
        nickname: _input,
        agreedTerms: true,
        agreedPrivacy: true,
        agreedMarketing: widget.agreedMarketing,
      );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(showIntroPopup: true),
        ),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입 처리 중 오류가 발생했습니다.')),
      );
      setState(() => _isSubmitting = false);
    }
  }

  Color _statusColor() {
    if (_errorMessage != null) return AppColors.koreanRed;
    if (_availableConfirmed) return AppColors.koreanBlue;
    return AppColors.textSecondary;
  }

  String _statusMessage() {
    if (_input.isEmpty) {
      return '$_minLen~$_maxLen자, 한글·영문·숫자만 사용 가능';
    }
    if (_errorMessage != null) return _errorMessage!;
    if (_checkingDuplicate) return '사용 가능 여부 확인 중...';
    if (_availableConfirmed) return '사용할 수 있는 닉네임입니다.';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final counterText = '${_input.length} / $_maxLen';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          '닉네임 설정',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '어떻게 불러드릴까요?',
                style: TextStyle(
                  fontSize: 26,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '커뮤니티·청원·행사에서 사용될 닉네임입니다.\n나중에 마이페이지에서 변경할 수 있습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _controller,
                onChanged: _onInput,
                maxLength: _maxLen,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_maxLen),
                ],
                decoration: InputDecoration(
                  hintText: '닉네임 입력',
                  counterText: counterText,
                  filled: true,
                  fillColor: AppColors.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.koreanBlue, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  suffixIcon: _checkingDuplicate
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _availableConfirmed
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.koreanBlue,
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusMessage(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _statusColor(),
                ),
              ),
              const Spacer(),
              SizedBox(
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
                  onPressed: _canSubmit ? _submit : null,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.white,
                          ),
                        )
                      : const Text(
                          '한미동맹단 시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
