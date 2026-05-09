// lib/screens/splash_screen.dart
import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/colors.dart';
import 'splash/ember_particles.dart';
import 'splash/energy_beams.dart';
import 'splash/magic_circle_painter.dart';
import 'splash/rpg_text_frame.dart';
import 'splash/rune_markers.dart';
import 'splash/shield_summon_widget.dart';
import 'splash/summon_flash.dart';

/// ROK_US Alliance 스플래시 — RPG 소환 의식 컨셉.
///
/// 시퀀스 (총 4.6s, onComplete 5.0s):
///   0.0 ~ 1.0  반투명 국기 좌·우 슬라이드 인 (opacity 0 → 0.18, blur 2)
///   0.5 ~ 1.5  마법진 외곽·중간(점선)·내부 링 등장
///   1.0 ~ 1.85 8방향 룬 마커 0.05s 시차 등장
///   1.6 ~ 2.35 4방향 에너지 광선 발사
///   1.8 ~ 3.0  방패 Y축 360° 회전하며 소환
///   2.0 ~ 3.0  방패 후광 펼쳐짐
///   2.2 ~ 2.9  소환 완료 폭발 플래시
///   2.2 ~ 3.7  배경 국기 더 흐려짐 (opacity 0.18 → 0.05, blur 2 → 8)
///   3.0 ~ 3.8  RPG 카드 프레임 등장
///   3.3 ~ 4.45 텍스트 시퀀스 (ROK·US → ALLIANCE → 데코 → 한미동맹단)
///   4.1 ~       하단 진행바 등장·채워짐
///   5.0       onComplete 콜백 → 다음 화면 진입
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const SplashScreen({super.key, this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const double _masterDurationSec = 4.6;

  late final AnimationController _master;
  // 마법진 3 링 회전용 — 24s = LCM(12,8,6) 이라 매 cycle 끝에서 모든 링이
  // 정수배 회전을 마치고 0으로 돌아가므로 boundary 점프가 시각적으로 보이지 않는다.
  late final AnimationController _spin;
  // 펄스·다이아 회전·호버 모션용 (3s)
  late final AnimationController _loop;

  Timer? _completeTimer;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      duration: const Duration(milliseconds: 4600),
      vsync: this,
    );
    _spin = AnimationController(
      duration: const Duration(seconds: 24),
      vsync: this,
    )..repeat();
    _loop = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _master.forward();

    _completeTimer = Timer(const Duration(milliseconds: 5000), () {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _master.dispose();
    _spin.dispose();
    _loop.dispose();
    super.dispose();
  }

  /// _master.value 기반으로 [start, start+duration] 윈도우의 0~1 진행도 반환.
  double _windowProgress(double startSec, double durationSec) {
    final t = _master.value * _masterDurationSec;
    return ((t - startSec) / durationSec).clamp(0.0, 1.0);
  }

  /// 절대 master 시간 (초)
  double get _masterTime => _master.value * _masterDurationSec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, _spin, _loop]),
        builder: (context, _) {
          final bgFlagInL = _windowProgress(0.0, 1.0);
          final bgFlagInR = _windowProgress(0.2, 1.0);
          final bgFlagFade = _windowProgress(2.2, 1.5);
          final magicAppear = _windowProgress(0.5, 1.0);
          final masterTime = _masterTime;
          final shieldSummon = _windowProgress(1.8, 1.2);
          final auraExpand = _windowProgress(2.0, 1.0);
          final summonFlash = _windowProgress(2.2, 0.7);
          final frameAppear = _windowProgress(3.0, 0.8);
          final rokUsProgress = _windowProgress(3.3, 0.8);
          final allianceProgress = _windowProgress(3.5, 0.7);
          final decoProgress = _windowProgress(3.7, 0.6);
          final krProgress = _windowProgress(3.85, 0.6);
          final statusBarAppear = _windowProgress(4.1, 0.4);
          final statusBarFill = _windowProgress(4.3, 1.5);

          return Stack(
            fit: StackFit.expand,
            children: [
              // ─── L0: 배경 그라디언트 (어두운 자홍 → 검정)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.24), // 화면 38% 지점
                    radius: 1.0,
                    colors: [
                      AppColors.bgUrgent,
                      AppColors.bgIconDark,
                      Colors.black,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // ─── L0: 반투명 국기 (좌:US, 우:KR)
              _BackgroundFlag(
                asset: 'assets/svg/us_flag_waving.svg',
                isLeft: true,
                inProgress: bgFlagInL,
                fadeProgress: bgFlagFade,
              ),
              _BackgroundFlag(
                asset: 'assets/svg/kr_flag_waving.svg',
                isLeft: false,
                inProgress: bgFlagInR,
                fadeProgress: bgFlagFade,
              ),

              // ─── L1: 비네트
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.24),
                        radius: 1.0,
                        colors: [Colors.transparent, Color(0xB3000000)],
                        stops: [0.3, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── L3: 입자
              const Positioned.fill(child: EmberParticles()),

              // ─── L3: 마법진 + 룬 마커
              Align(
                alignment: const Alignment(0, -0.24),
                child: SizedBox(
                  width: 320,
                  height: 320,
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          size: const Size(320, 320),
                          painter: MagicCirclePainter(
                            appearProgress: magicAppear,
                            spinValue: _spin.value,
                            pulseValue: _loop.value,
                          ),
                        ),
                        RuneMarkers(masterTime: masterTime),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── L4: 에너지 광선
              Align(
                alignment: const Alignment(0, -0.24),
                child: EnergyBeams(masterTime: masterTime),
              ),

              // ─── L4-5: 방패 + 후광
              Align(
                alignment: const Alignment(0, -0.24),
                child: ShieldSummonWidget(
                  summonProgress: shieldSummon,
                  auraProgress: auraExpand,
                  loopValue: _loop.value,
                ),
              ),

              // ─── L6: 소환 플래시
              Align(
                alignment: const Alignment(0, -0.24),
                child: SummonFlash(progress: summonFlash),
              ),

              // ─── L7: RPG 텍스트 프레임
              Align(
                alignment: const Alignment(0, 0.65),
                child: RpgTextFrame(
                  frameProgress: frameAppear,
                  rokUsProgress: rokUsProgress,
                  allianceProgress: allianceProgress,
                  decoProgress: decoProgress,
                  krProgress: krProgress,
                  loopValue: _loop.value,
                ),
              ),

              // ─── L7: 진행바
              Align(
                alignment: const Alignment(0, 0.92),
                child: _StatusBar(
                  appearProgress: statusBarAppear,
                  fillProgress: statusBarFill,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── 배경 국기 (반투명·블러·페이드) ─────────────────────────────

class _BackgroundFlag extends StatelessWidget {
  const _BackgroundFlag({
    required this.asset,
    required this.isLeft,
    required this.inProgress,
    required this.fadeProgress,
  });

  final String asset;
  final bool isLeft;

  /// 0~1 — 좌·우에서 슬라이드 인
  final double inProgress;

  /// 0~1 — 더 흐려지는 페이드
  final double fadeProgress;

  @override
  Widget build(BuildContext context) {
    if (inProgress <= 0) return const SizedBox.shrink();

    final slideFraction = (1 - inProgress) * 0.30;
    final dx = isLeft ? -slideFraction : slideFraction;

    const maxOpacity = 0.18;
    const minOpacity = 0.05;
    final opacity = inProgress *
        (maxOpacity - (maxOpacity - minOpacity) * fadeProgress);

    final blurSigma = 2.0 + 6.0 * fadeProgress;

    return LayoutBuilder(
      builder: (context, constraints) {
        final halfWidth = constraints.maxWidth / 2;
        return Positioned(
          left: isLeft ? dx * halfWidth : null,
          right: isLeft ? null : dx * halfWidth,
          top: 0,
          bottom: 0,
          width: halfWidth,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: SvgPicture.asset(
                asset,
                fit: BoxFit.cover,
                alignment:
                    isLeft ? Alignment.centerLeft : Alignment.centerRight,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── 진행바 ────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.appearProgress,
    required this.fillProgress,
  });

  final double appearProgress;
  final double fillProgress;

  @override
  Widget build(BuildContext context) {
    if (appearProgress <= 0) return const SizedBox.shrink();
    return Opacity(
      opacity: appearProgress,
      child: Container(
        width: 200,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: AppColors.accentRed.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Stack(
            children: [
              Positioned(
                left: -200 * (1 - fillProgress),
                top: 0,
                bottom: 0,
                width: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accentRed,
                        AppColors.accentRed.withValues(alpha: 0.6),
                        AppColors.accentRed,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentRed.withValues(alpha: 0.7),
                        blurRadius: 8,
                      ),
                    ],
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
