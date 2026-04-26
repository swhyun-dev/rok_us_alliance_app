// lib/features/auth/presentation/signup_complete_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_store.dart';

class SignupCompletePage extends StatefulWidget {
  const SignupCompletePage({super.key, required this.draft});

  final NaverProfileDraft draft;

  @override
  State<SignupCompletePage> createState() => _SignupCompletePageState();
}

class _SignupCompletePageState extends State<SignupCompletePage> {
  bool _isSubmitting = false;

  Future<void> _start() async {
    setState(() => _isSubmitting = true);

    try {
      await AuthStore.completeSignup(draft: widget.draft);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.shieldGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.koreanBlue.withValues(alpha: 0.32),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                '환영합니다',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.draft.naverNickname.isNotEmpty
                    ? '${widget.draft.naverNickname}님,\n한미동맹단에 합류하셨습니다.'
                    : '한미동맹단에 합류하셨습니다.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _start,
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
