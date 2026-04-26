// lib/features/auth/presentation/login_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_store.dart';
import 'signup_complete_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const heroLogoTag = 'app_main_logo';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _contentController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _cardSlideAnim;

  bool get _showDebugPreviewButton => kDebugMode;

  // Apple은 iOS 네이티브에서만 지원. (kIsWeb은 false 가정 후 플랫폼 분기.)
  bool get _showAppleButton =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnim = CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );

    _cardSlideAnim = Tween<double>(begin: 56, end: 0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    Future<void>.delayed(const Duration(milliseconds: 130), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSocialLogin(
    Future<SocialSignupDraft?> Function() signIn,
  ) async {
    final draft = await signIn();
    if (!mounted) return;

    final state = AuthStore.state;

    if (state.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(showIntroPopup: true),
        ),
      );
      return;
    }

    if (draft != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SignupCompletePage(draft: draft)),
      );
      return;
    }

    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  Future<void> _handleDebugPreviewLogin() async {
    await AuthStore.debugSignInForDesignPreview();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(showIntroPopup: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthStore.notifier,
      builder: (context, state, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: Stack(
              children: [
                // Star field
                const Positioned.fill(child: _StarFieldBackground()),
                // Top flag stripe bar
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: const BoxDecoration(
                      gradient: AppColors.flagAccentGradient,
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero section
                      Expanded(
                        flex: 52,
                        child: AnimatedBuilder(
                          animation: _fadeAnim,
                          builder: (context, child) => Opacity(
                            opacity: _fadeAnim.value,
                            child: child,
                          ),
                          child: _HeroSection(),
                        ),
                      ),
                      // Login card
                      AnimatedBuilder(
                        animation: _contentController,
                        builder: (context, child) => Opacity(
                          opacity: _fadeAnim.value,
                          child: Transform.translate(
                            offset: Offset(0, _cardSlideAnim.value),
                            child: child,
                          ),
                        ),
                        child: _LoginCard(
                          state: state,
                          showAppleButton: _showAppleButton,
                          showDebugButton: _showDebugPreviewButton,
                          onAppleLogin: () =>
                              _handleSocialLogin(AuthStore.signInWithApple),
                          onKakaoLogin: () =>
                              _handleSocialLogin(AuthStore.signInWithKakao),
                          onNaverLogin: () =>
                              _handleSocialLogin(AuthStore.signInWithNaver),
                          onGoogleLogin: () =>
                              _handleSocialLogin(AuthStore.signInWithGoogle),
                          onDebugLogin: _handleDebugPreviewLogin,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Hero section ────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo flanked by flag thumbnails
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _FlagBadge(assetPath: 'assets/images/korea_flag.png'),
                const SizedBox(width: 22),
                Hero(
                  tag: LoginPage.heroLogoTag,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.shieldGradient,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.32),
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.koreanRed.withValues(alpha: 0.38),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppColors.koreanBlue.withValues(alpha: 0.38),
                            blurRadius: 30,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                _FlagBadge(assetPath: 'assets/images/usa_flag.png'),
              ],
            ),
            const SizedBox(height: 28),
            // English small caps
            Text(
              'ROK-US ALLIANCE',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.5,
              ),
            ),
            const SizedBox(height: 10),
            // Korean title
            const Text(
              '한미동맹단',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            // Flag stripe accent
            Container(
              width: 160,
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AppColors.flagAccentGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.18),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tagline
            Text(
              '자유를 지키는 연결 · 행동하는 플랫폼',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.62),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagBadge extends StatelessWidget {
  const _FlagBadge({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}

// ─── Login card ──────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.state,
    required this.showAppleButton,
    required this.showDebugButton,
    required this.onAppleLogin,
    required this.onKakaoLogin,
    required this.onNaverLogin,
    required this.onGoogleLogin,
    required this.onDebugLogin,
  });

  final AuthState state;
  final bool showAppleButton;
  final bool showDebugButton;
  final VoidCallback onAppleLogin;
  final VoidCallback onKakaoLogin;
  final VoidCallback onNaverLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onDebugLogin;

  @override
  Widget build(BuildContext context) {
    final disabled = state.isLoading;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 36,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section label
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: AppColors.shieldGradient,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '소셜 계정으로 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (showAppleButton) ...[
              _SocialButton(
                label: 'Apple로 시작하기',
                icon: Icons.apple,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                onPressed: disabled ? null : onAppleLogin,
                isLoading: disabled,
              ),
              const SizedBox(height: 12),
            ],
            _SocialButton(
              label: '카카오로 시작하기',
              icon: Icons.chat_bubble,
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: const Color(0xFF181600),
              onPressed: disabled ? null : onKakaoLogin,
              isLoading: disabled,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              label: '네이버로 시작하기',
              icon: Icons.login,
              backgroundColor: const Color(0xFF03C75A),
              foregroundColor: Colors.white,
              onPressed: disabled ? null : onNaverLogin,
              isLoading: disabled,
            ),
            const SizedBox(height: 12),
            _SocialButton(
              label: 'Google로 시작하기',
              icon: Icons.g_mobiledata,
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              borderColor: AppColors.border,
              onPressed: disabled ? null : onGoogleLogin,
              isLoading: disabled,
            ),
            const SizedBox(height: 14),
            // 약관 안내
            Text(
              '시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showDebugButton) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.navy.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: disabled ? null : onDebugLogin,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.navy,
                    size: 16,
                  ),
                  label: const Text(
                    '디자인 확인용 임시 로그인',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.koreanRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    required this.isLoading,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1)
                : BorderSide.none,
          ),
          elevation: 1,
        ),
        onPressed: onPressed,
        child: isLoading && onPressed == null
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foregroundColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: foregroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Background star field ────────────────────────────────────────────────────

class _StarFieldBackground extends StatelessWidget {
  const _StarFieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarPainter());
  }
}

class _StarPainter extends CustomPainter {
  static final _positions = List.generate(
    70,
    (i) => Offset(
      (i * 137.508) % 1.0,
      (i * 73.137) % 1.0,
    ),
  );

  static final _sizes = List.generate(70, (i) => 0.4 + (i * 0.317) % 1.6);

  static final _alphas = List.generate(
    70,
    (i) => 0.12 + (i * 0.211) % 0.38,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (int i = 0; i < _positions.length; i++) {
      paint.color = (i % 7 == 0
              ? AppColors.koreanRed
              : i % 5 == 0
                  ? AppColors.koreanBlue
                  : Colors.white)
          .withValues(alpha: _alphas[i]);

      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );

      // Larger star cross sparkle for some
      if (i % 9 == 0) {
        paint.strokeWidth = 0.8;
        paint.style = PaintingStyle.stroke;
        final cx = _positions[i].dx * size.width;
        final cy = _positions[i].dy * size.height;
        final r = _sizes[i] * 2.5;
        canvas.drawLine(Offset(cx - r, cy), Offset(cx + r, cy), paint);
        canvas.drawLine(Offset(cx, cy - r), Offset(cx, cy + r), paint);
        paint.style = PaintingStyle.fill;
      }
    }

    // Subtle diagonal stripe lines (Stars & Stripes feel)
    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.022)
      ..strokeWidth = size.width * 0.40;

    for (int i = 0; i < 8; i++) {
      final y = size.height * (i / 8.0);
      canvas.drawLine(
        Offset(-size.width * 0.5, y),
        Offset(size.width * 1.5, y + size.width * 0.3),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
