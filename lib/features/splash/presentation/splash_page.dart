// lib/features/splash/presentation/splash_page.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/alliance_logo.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';

/// 게임 인트로 스타일 합체 splash:
/// 1) 좌측에서 붉은 호(韓), 우측에서 푸른 호(美)가 회전하며 슬라이드인
/// 2) 화면 중앙에서 충돌 → 흰 flash burst
/// 3) flash 잦아들며 둘이 합쳐진 골드 메달(AllianceLogo) 가 점진적으로 완성
/// 4) 한미동맹단 텍스트 + flag stripe + ROK·US ALLIANCE caption 순차
/// 총 ~2.4초.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _heroLogoTag = 'app_main_logo';

  late final AnimationController _controller;

  // Incoming arcs
  late final Animation<double> _leftArcSlide; // -1 → 0
  late final Animation<double> _rightArcSlide; // 1 → 0
  late final Animation<double> _arcsRotation; // -π/3 → 0
  late final Animation<double> _arcsFadeIn;
  late final Animation<double> _arcsFadeOut;
  late final Animation<double> _arcsScale;

  // Flash burst
  late final Animation<double> _flashOpacity;
  late final Animation<double> _flashScale;

  // Medal
  late final Animation<double> _medalProgress; // 0 → 1, 외곽 링이 그려지는 진행
  late final Animation<double> _medalOpacity;
  late final Animation<double> _medalScale;

  // Texts
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleOffset;
  late final Animation<double> _stripeWidth;
  late final Animation<double> _captionOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // ━━━ 좌·우 호 슬라이드인 (0.00 ~ 0.32) ━━━
    _leftArcSlide = Tween<double>(begin: -1.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _rightArcSlide = Tween<double>(begin: 1.05, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _arcsRotation = Tween<double>(begin: -math.pi / 3, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.34, curve: Curves.easeOutCubic),
      ),
    );
    _arcsScale = Tween<double>(begin: 0.7, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.34, curve: Curves.easeOutBack),
      ),
    );
    _arcsFadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.18, curve: Curves.easeIn),
    );
    _arcsFadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.34, 0.46, curve: Curves.easeIn),
      ),
    );

    // ━━━ Flash burst (0.30 ~ 0.50) ━━━
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 70,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.52),
      ),
    );
    _flashScale = Tween<double>(begin: 0.4, end: 2.6).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.52, curve: Curves.easeOutQuart),
      ),
    );

    // ━━━ Medal 등장 (0.36 ~ 0.78) ━━━
    _medalOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.58, curve: Curves.easeOut),
    );
    _medalScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.36, 0.66, curve: Curves.easeOutBack),
      ),
    );
    _medalProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.46, 0.78, curve: Curves.easeOutCubic),
    );

    // ━━━ 텍스트 시퀀스 (0.66 ~ 1.00) ━━━
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.85, curve: Curves.easeOut),
    );
    _titleOffset = Tween<double>(begin: 14, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _stripeWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 0.92, curve: Curves.easeOutCubic),
      ),
    );
    _captionOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.84, 1.00, curve: Curves.easeOut),
    );

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      AuthStore.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 2500)),
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
    final logoSize = shortest * 0.34;
    final arcSize = shortest * 0.42;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: Stack(
          children: [
            _BackgroundGlow(width: size.width, height: size.height),
            // 합체 시퀀스
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final arcsOpacity =
                    (_arcsFadeIn.value * _arcsFadeOut.value).clamp(0.0, 1.0);
                final leftDx = size.width * 0.55 * _leftArcSlide.value;
                final rightDx = size.width * 0.55 * _rightArcSlide.value;
                final scale = _arcsScale.value;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // 좌측 빨강 호
                    if (arcsOpacity > 0.01)
                      Transform.translate(
                        offset: Offset(leftDx, 0),
                        child: Transform.rotate(
                          angle: _arcsRotation.value,
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: arcsOpacity,
                              child: SizedBox(
                                width: arcSize,
                                height: arcSize,
                                child: CustomPaint(
                                  painter: _IncomingArcPainter(
                                    color: AppColors.koreanRed,
                                    isLeft: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 우측 파랑 호
                    if (arcsOpacity > 0.01)
                      Transform.translate(
                        offset: Offset(rightDx, 0),
                        child: Transform.rotate(
                          angle: -_arcsRotation.value,
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: arcsOpacity,
                              child: SizedBox(
                                width: arcSize,
                                height: arcSize,
                                child: CustomPaint(
                                  painter: _IncomingArcPainter(
                                    color: AppColors.koreanBlue,
                                    isLeft: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Flash burst
                    if (_flashOpacity.value > 0.01)
                      Opacity(
                        opacity: _flashOpacity.value,
                        child: Transform.scale(
                          scale: _flashScale.value,
                          child: Container(
                            width: shortest * 0.45,
                            height: shortest * 0.45,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white,
                                  Color(0x80FFFFFF),
                                  Color(0x00FFFFFF),
                                ],
                                stops: [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // 메달 (합체 결과)
                    if (_medalOpacity.value > 0.0)
                      Opacity(
                        opacity: _medalOpacity.value,
                        child: Transform.scale(
                          scale: _medalScale.value,
                          child: Hero(
                            tag: _heroLogoTag,
                            child: Material(
                              color: Colors.transparent,
                              child: AllianceLogo(
                                size: logoSize,
                                progress: _medalProgress.value,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            // 텍스트 영역
            Align(
              alignment: const Alignment(0, 0.55),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: _titleOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleOffset.value),
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
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 140 * _stripeWidth.value,
                        height: 2,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: AppColors.flagAccentGradient,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: _captionOpacity.value,
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
                  );
                },
              ),
            ),
            // 하단 카피
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

/// 좌·우에서 슬라이드인하는 큰 곡선 호. [isLeft] 면 9시→6시 방향, 우측은 거울상.
class _IncomingArcPainter extends CustomPainter {
  _IncomingArcPainter({required this.color, required this.isLeft});
  final Color color;
  final bool isLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * 0.42;
    final center = Offset(size.width * 0.5, size.height * 0.5);
    final rect = Rect.fromCircle(center: center, radius: r);
    final stroke = r * 0.22;

    // 호 자체
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.92);
    if (isLeft) {
      // 좌측: 위 11시 ~ 아래 5시 약 180도
      canvas.drawArc(rect, math.pi * 0.62, math.pi * 0.95, false, paint);
    } else {
      canvas.drawArc(rect, math.pi * 1.43, math.pi * 0.95, false, paint);
    }

    // 호 끝에서 살짝 빛나는 trail
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 8
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    if (isLeft) {
      canvas.drawArc(rect, math.pi * 0.62, math.pi * 0.95, false, glowPaint);
    } else {
      canvas.drawArc(rect, math.pi * 1.43, math.pi * 0.95, false, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IncomingArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isLeft != isLeft;
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
