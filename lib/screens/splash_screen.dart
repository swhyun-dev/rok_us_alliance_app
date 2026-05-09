import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';

/// ROK_US Alliance 스플래시 화면
///
/// 애니메이션 시퀀스 (총 2.5초):
/// - 0.3~1.0s : 좌측에서 성조기 펄럭이며 진입
/// - 0.5~1.2s : 우측에서 태극기 펄럭이며 진입
/// - 1.0~1.8s : 중앙 엠블럼 회전 + 탄성 스케일 등장
/// - 1.3~2.1s : 텍스트 시퀀스 페이드인
/// - 1.7s~    : 깃발 부드럽게 펄럭임 (반복)
/// - 2.4s+    : 하단 로딩 인디케이터 표시
///
/// 사용:
/// ```dart
/// SplashScreen(
///   onComplete: () => Navigator.pushReplacement(
///     context,
///     MaterialPageRoute(builder: (_) => const HomeScreen()),
///   ),
/// )
/// ```
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _waveController;

  late final Animation<double> _usFlagSlide;
  late final Animation<double> _usFlagOpacity;
  late final Animation<double> _krFlagSlide;
  late final Animation<double> _krFlagOpacity;
  late final Animation<double> _emblemScale;
  late final Animation<double> _emblemOpacity;
  late final Animation<double> _emblemRotation;
  late final Animation<double> _brandTextSlide;
  late final Animation<double> _brandTextOpacity;
  late final Animation<double> _krTextOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    )..repeat(reverse: true);

    // 0.12~0.40 : US flag enters (300ms-1000ms)
    _usFlagSlide = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.12, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _usFlagOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.12, 0.40, curve: Curves.easeOut),
    );

    // 0.20~0.48 : KR flag enters
    _krFlagSlide = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.20, 0.48, curve: Curves.easeOutCubic),
      ),
    );
    _krFlagOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.20, 0.48, curve: Curves.easeOut),
    );

    // 0.40~0.72 : Emblem
    _emblemOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.40, 0.56, curve: Curves.easeOut),
    );
    _emblemScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.40, 0.72, curve: Curves.elasticOut),
      ),
    );
    _emblemRotation = Tween<double>(begin: -math.pi, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.40, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    // 0.52~0.72 : Brand text
    _brandTextOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.52, 0.72, curve: Curves.easeOut),
    );
    _brandTextSlide = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.52, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    // 0.76~0.92 : Korean text
    _krTextOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.76, 0.92, curve: Curves.easeOut),
    );

    // 0.84~1.0 : Tagline
    _taglineOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.84, 1.0, curve: Curves.easeOut),
    );

    // 0.96~1.0 : Loading dots
    _loadingOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.96, 1.0, curve: Curves.easeOut),
    );

    _entryController.forward();

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entryController, _waveController]),
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 배경 글로우
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.4),
                    radius: 1.0,
                    colors: [Color(0x40E63946), Color(0x00E63946)],
                  ),
                ),
              ),

              // US Flag
              Positioned(
                left: screenWidth * _usFlagSlide.value - 10,
                top: screenHeight * 0.18,
                child: Opacity(
                  opacity: _usFlagOpacity.value,
                  child: Transform.rotate(
                    angle: math.sin(_waveController.value * math.pi) * 0.04 - 0.05,
                    child: SizedBox(
                      width: 180,
                      height: 130,
                      child: SvgPicture.asset(
                        'assets/svg/us_flag_waving.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // KR Flag
              Positioned(
                right: screenWidth * _krFlagSlide.value - 10,
                top: screenHeight * 0.22,
                child: Opacity(
                  opacity: _krFlagOpacity.value,
                  child: Transform.rotate(
                    angle: -math.sin(_waveController.value * math.pi) * 0.04 + 0.05,
                    child: SizedBox(
                      width: 180,
                      height: 130,
                      child: SvgPicture.asset(
                        'assets/svg/kr_flag_waving.svg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              // 중앙 컨텐츠
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 엠블럼
                      Opacity(
                        opacity: _emblemOpacity.value,
                        child: Transform.rotate(
                          angle: _emblemRotation.value,
                          child: Transform.scale(
                            scale: _emblemScale.value,
                            child: const _CenterEmblem(size: 110),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 데코 라인
                      Opacity(
                        opacity: _brandTextOpacity.value,
                        child: const _DecorativeLine(),
                      ),

                      const SizedBox(height: 16),

                      // ROK · US
                      Opacity(
                        opacity: _brandTextOpacity.value,
                        child: Transform.translate(
                          offset: Offset(0, _brandTextSlide.value),
                          child: const Text(
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
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ALLIANCE
                      Opacity(
                        opacity: _brandTextOpacity.value,
                        child: const Text(
                          'ALLIANCE',
                          style: TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 24,
                            letterSpacing: 12,
                            color: AppColors.accentRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 디바이더
                      Opacity(
                        opacity: _krTextOpacity.value,
                        child: Container(
                          width: 100,
                          height: 0.5,
                          color: AppColors.textMuted.withValues(alpha: 0.5),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 한미동맹단
                      Opacity(
                        opacity: _krTextOpacity.value,
                        child: const Text(
                          '한 미 동 맹 단',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 8,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 태그라인
                      Opacity(
                        opacity: _taglineOpacity.value,
                        child: const Text(
                          'CIVIC · NETWORK · ALLIANCE',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 로딩 인디케이터
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _loadingOpacity.value,
                  child: _LoadingDots(controller: _waveController),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 분리된 위젯들 ──────────────────────────────────────────

class _CenterEmblem extends StatelessWidget {
  final double size;
  const _CenterEmblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accentRed, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentRed.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: CustomPaint(painter: _MonogramPainter()),
    );
  }
}

class _MonogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 100;

    final redPaint = Paint()..color = AppColors.accentRed;
    final whitePaint = Paint()..color = Colors.white;

    // 내부 링
    canvas.drawCircle(
      center,
      40 * scale,
      Paint()
        ..color = AppColors.accentRed.withValues(alpha: 0.4)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke,
    );

    // 좌측 막대
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 22 * scale, center.dy - 22 * scale,
          6 * scale, 44 * scale),
      redPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 22 * scale, center.dy - 22 * scale,
          6 * scale, 6 * scale),
      whitePaint,
    );

    // 우측 막대
    canvas.drawRect(
      Rect.fromLTWH(center.dx + 16 * scale, center.dy - 22 * scale,
          6 * scale, 44 * scale),
      redPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(center.dx + 16 * scale, center.dy - 22 * scale,
          6 * scale, 6 * scale),
      whitePaint,
    );

    // 가로 연결선
    canvas.drawRect(
      Rect.fromLTWH(center.dx - 22 * scale, center.dy - 3 * scale,
          44 * scale, 6 * scale),
      redPaint,
    );

    // 중앙 다이아몬드
    final diamond = Path()
      ..moveTo(center.dx, center.dy - 3 * scale)
      ..lineTo(center.dx + 4 * scale, center.dy)
      ..lineTo(center.dx, center.dy + 3 * scale)
      ..lineTo(center.dx - 4 * scale, center.dy)
      ..close();
    canvas.drawPath(diamond, whitePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

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

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final phase = (controller.value * 2 + i * 0.25) % 1.0;
            final opacity = (1.0 - (phase - 0.5).abs() * 2).clamp(0.3, 1.0);
            final scale = 0.8 +
                (1.0 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.3;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accentRed.withValues(alpha: opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
