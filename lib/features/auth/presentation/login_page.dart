// lib/features/auth/presentation/login_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../widgets/alliance_emblem.dart';
import '../../home/presentation/home_page.dart';
import '../data/auth_store.dart';
import 'terms_agreement_page.dart';

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
        MaterialPageRoute(builder: (_) => TermsAgreementPage(draft: draft)),
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
          backgroundColor: AppColors.bgPrimary,
          body: Stack(
            children: [
              // 스플래시 종료 시점과 동일한 라디얼 글로우 (자연스러운 fade 연결)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0, -0.4),
                      radius: 1.0,
                      colors: [Color(0x40E63946), Color(0x00E63946)],
                    ),
                  ),
                ),
              ),
              // Star field
              const Positioned.fill(child: _StarFieldBackground()),
              // Top flag stripe
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.flagStripeGradient,
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _fadeAnim,
                        builder: (context, child) => Opacity(
                          opacity: _fadeAnim.value,
                          child: child,
                        ),
                        child: const _HeroSection(),
                      ),
                    ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // 통합 SVG 로고 (양쪽 깃발 + 중앙 모노그램)
            Hero(
              tag: LoginPage.heroLogoTag,
              child: Material(
                color: Colors.transparent,
                child: AllianceEmblem(size: 200),
              ),
            ),
            const SizedBox(height: 24),
            // 데코 라인 (스플래시와 동일)
            const _DecorativeLine(),
            const SizedBox(height: 16),
            // ROK · US
            const Text(
              'ROK · US',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 56,
                fontWeight: FontWeight.w400,
                letterSpacing: 6,
                color: Color(0xFFFFFFFF),
                height: 1,
                shadows: [
                  Shadow(
                    color: Color(0x66E63946),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ALLIANCE
            const Text(
              'ALLIANCE',
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 24,
                letterSpacing: 12,
                color: AppColors.accentRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              width: 100,
              height: 0.5,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            // 한 미 동 맹 단
            const Text(
              '한 미 동 맹 단',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            // Tagline
            const Text(
              '자유를 지키는 연결 · 행동하는 플랫폼',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 스플래시의 _DecorativeLine 과 동일한 시각 요소 — 스플래시와 톤 일치를 위해 재현
class _DecorativeLine extends StatelessWidget {
  const _DecorativeLine();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 60, height: 1, color: AppColors.accentRed),
        const SizedBox(width: 8),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accentRed,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(width: 60, height: 1, color: AppColors.accentRed),
      ],
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderStrong, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
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
                    color: AppColors.accentRed,
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
              foregroundColor: Colors.black87,
              onPressed: disabled ? null : onGoogleLogin,
              isLoading: disabled,
            ),
            const SizedBox(height: 14),
            // 약관 안내
            const Text(
              '시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textMuted,
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
                      color: AppColors.borderStrong,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: disabled ? null : onDebugLogin,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  label: const Text(
                    '디자인 확인용 임시 로그인',
                    style: TextStyle(
                      color: AppColors.textMuted,
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
                  color: AppColors.accentRed,
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
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
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

// ─── Background star field (브랜드 다크 톤) ──────────────────────────────────

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
              ? AppColors.accentRed
              : i % 5 == 0
                  ? AppColors.infoBlue
                  : Colors.white)
          .withValues(alpha: _alphas[i]);

      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );

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

    // 미세한 대각선 stripe (Stars & Stripes 분위기)
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
