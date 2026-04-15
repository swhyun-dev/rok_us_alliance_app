// lib/features/auth/presentation/signup_complete_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_store.dart';

class SignupCompletePage extends StatefulWidget {
  const SignupCompletePage({super.key});

  @override
  State<SignupCompletePage> createState() => _SignupCompletePageState();
}

class _SignupCompletePageState extends State<SignupCompletePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cafeNicknameController;

  bool _agreeTerms = true;
  bool _agreePrivacy = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final draft = AuthStore.state.pendingProfile;

    _nameController = TextEditingController(text: draft?.name ?? '');
    _phoneController = TextEditingController(text: draft?.phoneNumber ?? '');
    _cafeNicknameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cafeNicknameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '이름을 입력해주세요.';
    if (text.length < 2) return '이름을 2자 이상 입력해주세요.';
    return null;
  }

  String? _validatePhone(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '전화번호를 입력해주세요.';
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 10 || digits.length > 11) {
      return '전화번호 형식이 올바르지 않습니다.';
    }
    return null;
  }

  String? _validateCafeNickname(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return '네이버 카페 닉네임을 입력해주세요.';
    if (text.length < 2) return '카페 닉네임을 2자 이상 입력해주세요.';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreeTerms || !_agreePrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('약관 및 개인정보 동의가 필요합니다.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthStore.completeSignup(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        cafeNickname: _cafeNicknameController.text,
        phoneVerified: false,
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
        const SnackBar(content: Text('가입 완료 처리 중 오류가 발생했습니다.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = AuthStore.state.pendingProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '가입 정보 확인',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.royalBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '가입 마지막 단계',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '네이버 카페 연동을 위해\n회원 정보를 확인해주세요.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              height: 1.3,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '네이버 닉네임 / ${draft?.naverNickname ?? '-'}\n'
                                  '네이버 고유 식별값 / ${draft?.providerUserId ?? '-'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            validator: _validateName,
                            decoration: const InputDecoration(
                              labelText: '이름',
                              hintText: '실명을 입력해주세요',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            validator: _validatePhone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: '전화번호',
                              hintText: '010-1234-5678',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _cafeNicknameController,
                            validator: _validateCafeNickname,
                            decoration: const InputDecoration(
                              labelText: '네이버 카페 닉네임',
                              hintText: '카페에서 사용하는 닉네임',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.softRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              '카페 닉네임은 향후 카페 회원 데이터와 매칭하는 기준값으로 사용될 수 있습니다.\n가입 후 변경되면 다시 동기화 기능을 붙이는 것을 권장합니다.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CheckboxListTile(
                            value: _agreeTerms,
                            onChanged: (value) {
                              setState(() {
                                _agreeTerms = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '서비스 이용에 동의합니다.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          CheckboxListTile(
                            value: _agreePrivacy,
                            onChanged: (value) {
                              setState(() {
                                _agreePrivacy = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              '개인정보 수집 및 활용에 동의합니다.',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: const Text(
                              '이름 / 전화번호 / 카페 닉네임 저장',
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: _isSubmitting ? null : _submit,
                              child: _isSubmitting
                                  ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text(
                                '가입 완료',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}