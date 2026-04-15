// lib/features/splash/presentation/splash_page.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _heroLogoTag = 'app_main_logo';

  late final AnimationController _controller;

  late final Animation<double> _leftFlagSlide;
  late final Animation<double> _rightFlagSlide;
  late final Animation<double> _leftFlagRotation;
  late final Animation<double> _rightFlagRotation;
  late final Animation<double> _flagScale;
  late final Animation<double> _flagIntroOpacity;
  late final Animation<double> _flagMergeFade;
  late final Animation<double> _flagBlurProgress;

  late final Animation<double> _swirlProgress;
  late final Animation<double> _swirlRadius;
  late final Animation<double> _swirlSpin;

  late final Animation<double> _coreGlowOpacity;
  late final Animation<double> _coreGlowScale;
  late final Animation<double> _flashOpacity;
  late final Animation<double> _flashScale;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _titleOffset;

  bool _navigated = false;

  final List<_ParticleSeed> _particles = List.generate(
    32,
        (index) => _ParticleSeed(index: index),
  );

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    _leftFlagSlide = Tween<double>(begin: -1.24, end: -0.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.56, curve: Curves.easeOutCubic),
      ),
    );

    _rightFlagSlide = Tween<double>(begin: 1.24, end: 0.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.56, curve: Curves.easeOutCubic),
      ),
    );

    _leftFlagRotation = Tween<double>(begin: -0.20, end: -0.01).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.58, curve: Curves.easeOut),
      ),
    );

    _rightFlagRotation = Tween<double>(begin: 0.20, end: 0.01).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.58, curve: Curves.easeOut),
      ),
    );

    _flagScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.82, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 45,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.76),
      ),
    );

    _flagIntroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.00, 0.22, curve: Curves.easeIn),
      ),
    );

    _flagMergeFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.54, 0.82, curve: Curves.easeInOutCubic),
      ),
    );

    _flagBlurProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.82, curve: Curves.easeInOut),
      ),
    );

    _swirlProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    _swirlRadius = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.80, curve: Curves.easeInOutCubic),
      ),
    );

    _swirlSpin = Tween<double>(begin: 0.0, end: math.pi * 1.35).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.80, curve: Curves.easeInOutQuart),
      ),
    );

    _coreGlowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.70, curve: Curves.easeInOut),
      ),
    );

    _coreGlowScale = Tween<double>(begin: 0.4, end: 1.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.38, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 34,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 66,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.86),
      ),
    );

    _flashScale = Tween<double>(begin: 0.3, end: 3.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.56, 0.82, curve: Curves.easeOutQuart),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.88, curve: Curves.easeIn),
      ),
    );

    _logoScale = Tween<double>(begin: 0.70, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.92, curve: Curves.easeOutBack),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.00, curve: Curves.easeIn),
      ),
    );

    _titleOffset = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.78, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      AuthStore.initialize(),
      Future<void>.delayed(const Duration(milliseconds: 3900)),
    ]);

    if (!mounted || _navigated) return;
    _navigated = true;

    final nextPage = AuthStore.isSignedIn
        ? const HomePage(showIntroPopup: true)
        : const LoginPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 850),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
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

  double get _flagOpacityValue =>
      (_flagIntroOpacity.value * _flagMergeFade.value).clamp(0.0, 1.0);

  Widget _buildFlagCard({
    required String assetPath,
    required double width,
    required double height,
  }) {
    final opacity = 0.94 * _flagOpacityValue;
    final sigma = 11 * _flagBlurProgress.value;

    return Opacity(
      opacity: opacity,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Transform.scale(
          scale: 1.0 - (0.10 * _flagBlurProgress.value),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22 * opacity),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.06 * opacity),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18 * opacity),
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.10 * opacity),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10 * opacity),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundGlow({
    required double width,
    required double height,
  }) {
    return Stack(
      children: [
        Positioned(
          top: -height * 0.10,
          left: -width * 0.20,
          child: _softOrb(
            size: width * 0.55,
            color: AppColors.royalBlue.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          bottom: -height * 0.08,
          right: -width * 0.18,
          child: _softOrb(
            size: width * 0.52,
            color: AppColors.red.withValues(alpha: 0.22),
          ),
        ),
        Positioned(
          top: height * 0.14,
          right: width * 0.05,
          child: _softOrb(
            size: width * 0.22,
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _softOrb({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: color.a * 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterEffects(double shortestSide) {
    final glowBase = shortestSide * 0.34;
    final flashBase = shortestSide * 0.42;
    final swirlGlow = shortestSide * (0.20 + (_swirlProgress.value * 0.18));

    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: (_swirlProgress.value * 0.7).clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: _swirlSpin.value * 0.55,
              child: Container(
                width: swirlGlow,
                height: swirlGlow,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      AppColors.red.withValues(alpha: 0.00),
                      AppColors.red.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.25),
                      AppColors.royalBlue.withValues(alpha: 0.28),
                      AppColors.royalBlue.withValues(alpha: 0.00),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: _coreGlowOpacity.value * 0.9,
            child: Transform.scale(
              scale: _coreGlowScale.value,
              child: Container(
                width: glowBase,
                height: glowBase,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.40),
                      AppColors.red.withValues(alpha: 0.18),
                      AppColors.royalBlue.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.62, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: _flashOpacity.value,
            child: Transform.scale(
              scale: _flashScale.value,
              child: Container(
                width: flashBase,
                height: flashBase,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.84),
                      Colors.white.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.14, 0.38, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Opacity(
            opacity: (_coreGlowOpacity.value * 0.70).clamp(0.0, 1.0),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: shortestSide * 0.24,
                height: shortestSide * 0.24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLogo(double shortestSide) {
    final size = shortestSide * 0.22;

    return Hero(
      tag: _heroLogoTag,
      flightShuttleBuilder: (
          flightContext,
          animation,
          flightDirection,
          fromHeroContext,
          toHeroContext,
          ) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: toHeroContext.widget,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.royalBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.red.withValues(alpha: 0.30),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppColors.royalBlue.withValues(alpha: 0.30),
                    blurRadius: 26,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1.6,
                ),
              ),
              child: const Icon(
                Icons.how_to_vote_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTexts() {
    return Opacity(
      opacity: _titleOpacity.value,
      child: Transform.translate(
        offset: Offset(0, _titleOffset.value),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '한미동맹단',
              style: TextStyle(
                color: Colors.white,
                fontSize: 31,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '자유를 지키는 연결 / 행동하는 플랫폼',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: 168,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AppColors.flagAccentGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.10),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = math.min(size.width, size.height);
    final flagWidth = shortestSide * 0.30;
    final flagHeight = flagWidth * 0.66;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.heroGradient,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final baseLeftX = size.width * 0.5 * _leftFlagSlide.value;
            final baseRightX = size.width * 0.5 * _rightFlagSlide.value;

            final swirlOrbit = shortestSide * 0.055 * _swirlRadius.value;
            final swirlAngle = _swirlSpin.value;
            final swirlVertical =
                math.sin(_swirlProgress.value * math.pi) * shortestSide * 0.012;

            final leftSwirlOffset = Offset(
              math.cos(swirlAngle) * swirlOrbit,
              math.sin(swirlAngle) * swirlOrbit - swirlVertical,
            );

            final rightSwirlOffset = Offset(
              math.cos(swirlAngle + math.pi) * swirlOrbit,
              math.sin(swirlAngle + math.pi) * swirlOrbit + swirlVertical,
            );

            final leftTotalOffset =
                Offset(baseLeftX, -shortestSide * 0.03) + leftSwirlOffset;
            final rightTotalOffset =
                Offset(baseRightX, shortestSide * 0.03) + rightSwirlOffset;

            final leftAngle = _leftFlagRotation.value + (_swirlSpin.value * 0.55);
            final rightAngle =
                _rightFlagRotation.value - (_swirlSpin.value * 0.55);

            return Stack(
              children: [
                _buildBackgroundGlow(width: size.width, height: size.height),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      progress: _controller.value,
                      particles: _particles,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: _buildCenterEffects(shortestSide),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: leftTotalOffset,
                    child: Transform.rotate(
                      angle: leftAngle,
                      child: Transform.scale(
                        scale: _flagScale.value,
                        child: _buildFlagCard(
                          assetPath: 'assets/images/korea_flag.png',
                          width: flagWidth,
                          height: flagHeight,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: rightTotalOffset,
                    child: Transform.rotate(
                      angle: rightAngle,
                      child: Transform.scale(
                        scale: _flagScale.value,
                        child: _buildFlagCard(
                          assetPath: 'assets/images/usa_flag.png',
                          width: flagWidth,
                          height: flagHeight,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: _buildHeroLogo(shortestSide),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: size.height * 0.16,
                  child: _buildTexts(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ParticleSeed {
  const _ParticleSeed({required this.index});

  final int index;

  double get angle => (index * 23.0) * math.pi / 180.0;
  double get radiusFactor => 0.42 + ((index * 17) % 40) / 100.0;
  double get sizeFactor => 0.9 + ((index * 11) % 7) / 10.0;
  double get speedOffset => ((index * 13) % 100) / 100.0;
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({
    required this.progress,
    required this.particles,
  });

  final double progress;
  final List<_ParticleSeed> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      final localT =
      ((progress - (particle.speedOffset * 0.18)) / 0.82).clamp(0.0, 1.0);

      if (localT <= 0) continue;

      final eased = Curves.easeOut.transform(localT);
      final orbit = size.shortestSide * particle.radiusFactor;
      final start = Offset(
        center.dx + math.cos(particle.angle) * orbit,
        center.dy + math.sin(particle.angle) * orbit,
      );

      final driftAngle =
          particle.angle + (math.sin(progress * math.pi * 2) * 0.1);
      final current = Offset.lerp(
        start,
        center,
        Curves.easeInOutCubic.transform(localT),
      )!;

      final shimmer =
          0.5 + 0.5 * math.sin((progress * 10) + particle.index.toDouble());
      final radius = (size.shortestSide * 0.0065) * particle.sizeFactor;
      final alpha = ((1.0 - eased) * 0.70 + 0.18) * (0.6 + shimmer * 0.4);

      final paint = Paint()
        ..color = (particle.index.isEven
            ? Colors.white
            : (particle.index % 3 == 0
            ? AppColors.red
            : AppColors.royalBlue))
            .withValues(alpha: alpha.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(current, radius, paint);

      final tailPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            paint.color.withValues(alpha: 0.0),
            paint.color.withValues(alpha: paint.color.a * 0.7),
          ],
        ).createShader(
          Rect.fromPoints(
            current,
            Offset(
              current.dx - math.cos(driftAngle) * 18,
              current.dy - math.sin(driftAngle) * 18,
            ),
          ),
        )
        ..strokeWidth = radius * 1.1
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(
          current.dx - math.cos(driftAngle) * 14,
          current.dy - math.sin(driftAngle) * 14,
        ),
        current,
        tailPaint,
      );
    }

    final ringProgress = ((progress - 0.50) / 0.30).clamp(0.0, 1.0);
    if (ringProgress > 0) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lerpDouble(1.0, 3.0, ringProgress)!
        ..color = Colors.white.withValues(
          alpha: (0.28 * (1.0 - ringProgress)).clamp(0.0, 1.0),
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawCircle(
        center,
        lerpDouble(
          size.shortestSide * 0.08,
          size.shortestSide * 0.28,
          ringProgress,
        )!,
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}