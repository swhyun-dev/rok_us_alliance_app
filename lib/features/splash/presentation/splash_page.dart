// lib/features/splash/presentation/splash_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/alliance_logo.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';

/// 단순한 fade-in splash.
/// - 깊은 네이비 배경 + 미세한 그라디언트 글로우
/// - 중앙 [AllianceLogo] (방패 + 별)
/// - 한미동맹단 한글 + ROK·US ALLIANCE 영문 캡션
/// - 전체 약 1.8초 후 다음 화면으로 fade transition
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _heroLogoTag = 'app_main_logo';

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleOffset;
  late final Animation<double> _captionOpacity;
  late final Animation<double> _stripeWidth;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.45, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.86, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.40, 0.75, curve: Curves.easeOut),
    );
    _titleOffset = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _stripeWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _captionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 1.00, curve: Curves.easeOut),
    );

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      AuthStore.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 1900)),
    ]);

    if (!mounted || _navigated) return;
    _navigated = true;

    final nextPage = AuthStore.isSignedIn
        ? const HomePage(showIntroPopup: true)
        : const LoginPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.10, 1.0, curve: Curves.easeOut),
            ),
            child: nextPage,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortest =
        size.shortestSide.clamp(320.0, double.infinity).toDouble();
    final logoSize = shortest * 0.32;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            // 부드러운 양쪽 글로우
            _BackgroundGlow(width: size.width, height: size.height),
            // 본문
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoOpacity.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Hero(
                      tag: _heroLogoTag,
                      child: Material(
                        color: Colors.transparent,
                        child: AllianceLogo(size: logoSize),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _titleOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleOffset.value),
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      '한미동맹단',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _stripeWidth,
                    builder: (context, _) {
                      return Container(
                        width: 140 * _stripeWidth.value,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: AppColors.flagAccentGradient,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  AnimatedBuilder(
                    animation: _captionOpacity,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _captionOpacity.value,
                        child: child,
                      );
                    },
                    child: Text(
                      'ROK · US ALLIANCE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 하단 푸터
            Positioned(
              left: 0,
              right: 0,
              bottom: 36,
              child: Center(
                child: AnimatedBuilder(
                  animation: _captionOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _captionOpacity.value * 0.6,
                      child: child,
                    );
                  },
                  child: Text(
                    '대한민국 · 미국 동맹의 가치를 잇는 시민 플랫폼',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
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

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -height * 0.08,
            left: -width * 0.18,
            child: _orb(
              size: width * 0.55,
              color: AppColors.koreanBlue.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            bottom: -height * 0.06,
            right: -width * 0.15,
            child: _orb(
              size: width * 0.52,
              color: AppColors.koreanRed.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: height * 0.18,
            right: width * 0.05,
            child: _orb(
              size: width * 0.18,
              color: AppColors.gold.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orb({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
