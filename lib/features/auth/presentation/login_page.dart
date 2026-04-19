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

  Future<void> _handleNaverLogin() async {
    final needsSignup = await AuthStore.signInWithNaver();
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

    if (needsSignup && state.pendingProfile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SignupCompletePage()),
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
                          onNaverLogin: _handleNaverLogin,
                          onDebugLogin: _handleDebugPreviewLogin,
                          showDebugButton: _showDebugPreviewButton,
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
    required this.onNaverLogin,
    required this.onDebugLogin,
    required this.showDebugButton,
  });

  final AuthState state;
  final VoidCallback onNaverLogin;
  final VoidCallback onDebugLogin;
  final bool showDebugButton;

  @override
  Widget build(BuildContext context) {
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
            // Feature list
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
                  '가입 후 가능한 것',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _FeatureRow(
              icon: Icons.campaign_outlined,
              text: '행동 공지 / 집회 일정 빠르게 확인',
            ),
            _FeatureRow(
              icon: Icons.groups_outlined,
              text: '커뮤니티 참여 / 지역 네트워크 확장',
            ),
            _FeatureRow(
              icon: Icons.verified_user_outlined,
              text: '카페 닉네임 기반 회원 매칭 대비',
            ),
            const SizedBox(height: 16),
            // Section label divider
            Row(
              children: [
                const Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '로그인 / 가입',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 16),
            // Naver login button
            SizedBox(
              height: 54,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF03C75A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: state.isLoading ? null : onNaverLogin,
                child: state.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            '네이버로 계속하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (showDebugButton) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.navy.withValues(alpha: 0.30),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: state.isLoading ? null : onDebugLogin,
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.navy,
                    size: 18,
                  ),
                  label: const Text(
                    '디자인 확인용 임시 로그인',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '디버그 모드에서만 보이는 임시 버튼입니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
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

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: AppColors.royalBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

