// lib/features/auth/presentation/edit_profile_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../data/auth_store.dart';

/// 회원정보(이름·닉네임) 수정 페이지.
/// 닉네임은 NicknameSetupPage 와 동일 규칙(2~12, 한/영/숫자) + 중복 검사.
/// 변경된 필드만 Firestore 에 patch.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const int _nameMin = 2;
  static const int _nameMax = 20;
  static const int _nickMin = 2;
  static const int _nickMax = 12;
  static final RegExp _nickAllowed = RegExp(r'^[가-힣a-zA-Z0-9]+$');
  static const Duration _debounce = Duration(milliseconds: 500);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _nickCtrl;
  Timer? _nickTimer;

  String _initialName = '';
  String _initialNick = '';

  String? _nameError;
  String? _nickError;
  bool _checkingNick = false;
  bool _nickConfirmed = true; // 변경 없으면 사용 가능 상태로 시작
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final user = AuthStore.currentUser;
    _initialName = user?.name ?? '';
    _initialNick = user?.nickname ?? '';
    _nameCtrl = TextEditingController(text: _initialName);
    _nickCtrl = TextEditingController(text: _initialNick);
    _nameCtrl.addListener(_validateName);
  }

  @override
  void dispose() {
    _nickTimer?.cancel();
    _nameCtrl.dispose();
    _nickCtrl.dispose();
    super.dispose();
  }

  bool get _hasNameChange => _nameCtrl.text.trim() != _initialName;
  bool get _hasNickChange => _nickCtrl.text.trim() != _initialNick;
  bool get _hasAnyChange => _hasNameChange || _hasNickChange;

  bool get _canSubmit =>
      _hasAnyChange &&
      !_submitting &&
      !_checkingNick &&
      _nameError == null &&
      _nickError == null &&
      _nickConfirmed;

  void _validateName() {
    final v = _nameCtrl.text.trim();
    String? err;
    if (v.isEmpty) {
      err = '이름을 입력해주세요.';
    } else if (v.length < _nameMin) {
      err = '$_nameMin자 이상 입력해주세요.';
    } else if (v.length > _nameMax) {
      err = '$_nameMax자 이하로 입력해주세요.';
    }
    if (err != _nameError) {
      setState(() => _nameError = err);
    }
  }

  void _onNickInput(String value) {
    final trimmed = value.trim();
    _nickTimer?.cancel();

    if (trimmed == _initialNick) {
      // 변경 없으면 검사 생략, 사용 가능 상태로 처리
      setState(() {
        _nickError = null;
        _checkingNick = false;
        _nickConfirmed = true;
      });
      return;
    }

    final localError = _validateNickLocally(trimmed);
    if (localError != null) {
      setState(() {
        _nickError = localError;
        _checkingNick = false;
        _nickConfirmed = false;
      });
      return;
    }

    setState(() {
      _nickError = null;
      _checkingNick = true;
      _nickConfirmed = false;
    });

    _nickTimer = Timer(_debounce, () async {
      try {
        final available = await AuthStore.isNicknameAvailable(trimmed);
        if (!mounted) return;
        if (_nickCtrl.text.trim() != trimmed) return;
        setState(() {
          _checkingNick = false;
          _nickConfirmed = available;
          _nickError = available ? null : '이미 사용 중인 닉네임입니다.';
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _checkingNick = false;
          _nickConfirmed = false;
          _nickError = '닉네임 확인 중 문제가 발생했습니다.';
        });
      }
    });
  }

  String? _validateNickLocally(String v) {
    if (v.isEmpty) return '닉네임을 입력해주세요.';
    if (v.length < _nickMin) return '$_nickMin자 이상 입력해주세요.';
    if (v.length > _nickMax) return '$_nickMax자 이하로 입력해주세요.';
    if (!_nickAllowed.hasMatch(v)) return '한글·영문·숫자만 사용할 수 있습니다.';
    return null;
  }

  Future<void> _save() async {
    if (!_canSubmit) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthStore.updateProfile(
        name: _hasNameChange ? _nameCtrl.text.trim() : null,
        nickname: _hasNickChange ? _nickCtrl.text.trim() : null,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('회원정보가 저장되었습니다.')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(content: Text('저장 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '회원정보 수정',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _Label('이름'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              maxLength: _nameMax,
              decoration: _decoration(
                hint: '이름을 입력해주세요',
                error: _nameError,
              ),
            ),
            const SizedBox(height: 18),
            const _Label('닉네임'),
            const SizedBox(height: 6),
            TextField(
              controller: _nickCtrl,
              maxLength: _nickMax,
              inputFormatters: [
                FilteringTextInputFormatter.allow(_nickAllowed),
              ],
              onChanged: _onNickInput,
              decoration: _decoration(
                hint: '한글·영문·숫자 ($_nickMin~$_nickMax자)',
                error: _nickError,
                suffix: _checkingNick
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : (_hasNickChange && _nickConfirmed)
                        ? const Icon(Icons.check_circle,
                            color: Color(0xFF2E7D32), size: 20)
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '※ 닉네임은 다른 사용자에게 노출됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.koreanBlue,
                  disabledBackgroundColor:
                      AppColors.koreanBlue.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _canSubmit ? _save : null,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '저장',
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
    );
  }

  InputDecoration _decoration({
    required String hint,
    String? error,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: error,
      counterText: '',
      filled: true,
      fillColor: Colors.white,
      suffixIcon: suffix == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.koreanBlue, width: 1.4),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}
