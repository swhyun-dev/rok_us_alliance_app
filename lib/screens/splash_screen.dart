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

/// 스플래시 시퀀스 모드.
///
/// - [full]  : 첫 진입에서 보여주는 4.6s RPG 소환 시퀀스
/// - [short] : 재진입에서 보여주는 1.2s 미니멀 fade-in (방패 + 브랜드 텍스트만)
enum SplashMode { full, short }

/// ROK_US Alliance 스플래시.
///
/// **Full 모드** (총 4.6s, onComplete 5.0s) — RPG 소환 의식 컨셉:
///   0.0 ~ 1.0  반투명 국기 좌·우 슬라이드 인 (opacity 0 → 0.18, blur 2)
///   0.5 ~ 1.5  마법진 외곽·중간(점선)·내부 링 등장
///   1.0 ~ 1.85 8방향 룬 마커 0.05s 시차 등장
///   1.6 ~ 2.35 4방향 에너지 광선 발사
///   1.8 ~ 3.0  방패 Y축 360° 회전하며 소환
///   2.0 ~ 3.0  방패 후광 펼쳐짐
///   2.2 ~ 2.9  소환 완료 폭발 플래시
///   2.2 ~ 3.7  배경 국기 더 흐려짐
///   3.0 ~ 3.8  RPG 카드 프레임 등장
///   3.3 ~ 4.45 텍스트 시퀀스 (ROK·US → ALLIANCE → 데코 → 한미동맹단)
///   4.1 ~       하단 진행바 등장·채워짐
///   5.0       onComplete
///
/// **Short 모드** (총 1.2s, onComplete 1.5s) — 재진입용 미니멀:
///   0.0 ~ 0.5  방패 fade-in + scale 0.9 → 1.0
///   0.3 ~ 0.8  "ROK · US" + "ALLIANCE" fade-in
///   0.5 ~ 1.0  "한 미 동 맹 단" fade-in
///   1.5       onComplete
class SplashScreen extends StatefulWidget {
  final VoidCallback? onComplete;
  final SplashMode mode;

  const SplashScreen({
    super.key,
    this.onComplete,
    this.mode = SplashMode.full,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const double _fullDurationSec = 4.6;
  static const double _shortDurationSec = 1.2;

  late final AnimationController _master;
  // 마법진 3 링 회전용 — 24s = LCM(12,8,6) 이라 매 cycle 끝에서 모든 링이
  // 정수배 회전을 마치고 0으로 돌아가므로 boundary 점프가 시각적으로 보이지 않는다.
  // Short 모드에선 미사용.
  AnimationController? _spin;
  // 펄스·다이아 회전·호버 모션용 (3s) — Short 모드에선 미사용.
  AnimationController? _loop;

  Timer? _completeTimer;

  bool get _isFull => widget.mode == SplashMode.full;

  double get _masterDurationSec =>
      _isFull ? _fullDurationSec : _shortDurationSec;

  @override
  void initState() {
    super.initState();

    final masterDuration = Duration(
      milliseconds: (_masterDurationSec * 1000).round(),
    );
    _master = AnimationController(duration: masterDuration, vsync: this);

    if (_isFull) {
      _spin = AnimationController(
        duration: const Duration(seconds: 24),
        vsync: this,
      )..repeat();
      _loop = AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      )..repeat();
    }

    _master.forward();

    final completeDelay = _isFull
        ? const Duration(milliseconds: 5000)
        : const Duration(milliseconds: 1500);
    _completeTimer = Timer(completeDelay, () {
      if (mounted) widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _completeTimer?.cancel();
    _master.dispose();
    _spin?.dispose();
    _loop?.dispose();
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
    if (!_isFull) return _buildShort();
    return _buildFull();
  }

  Widget _buildFull() {
    final spin = _spin!;
    final loop = _loop!;
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_master, spin, loop]),
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
                            spinValue: spin.value,
                            pulseValue: loop.value,
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
                  loopValue: loop.value,
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
                  loopValue: loop.value,
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

  // ─── Short 모드 ─────────────────────────────────────────────
  // 재진입 시 1.2s 미니멀 fade-in. RPG 시퀀스의 회전·입자·마법진 모두 생략.
  Widget _buildShort() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final shieldProgress = _windowProgress(0.0, 0.5);
          final brandProgress = _windowProgress(0.3, 0.5);
          final krProgress = _windowProgress(0.5, 0.5);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 배경 그라디언트 (full 과 동일)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.24),
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

              // 부드러운 빨간 글로우 (방패 등장과 함께 페이드인)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.24),
                      radius: 0.7,
                      colors: [
                        AppColors.accentRed
                            .withValues(alpha: 0.15 * shieldProgress),
                        const Color(0x00000000),
                      ],
                    ),
                  ),
                ),
              ),

              // 방패
              Align(
                alignment: const Alignment(0, -0.18),
                child: Opacity(
                  opacity: shieldProgress,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * shieldProgress,
                    child: SvgPicture.asset(
                      'assets/svg/shield_final.svg',
                      width: 160,
                      height: 160 * 255 / 240,
                    ),
                  ),
                ),
              ),

              // 브랜드 텍스트
              Align(
                alignment: const Alignment(0, 0.22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: brandProgress,
                      child: const Text(
                        'ROK · US',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 44,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 6,
                          color: Color(0xFFFFFFFF),
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Opacity(
                      opacity: brandProgress,
                      child: const Text(
                        'ALLIANCE',
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          fontSize: 18,
                          letterSpacing: 10,
                          color: AppColors.accentRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Opacity(
                      opacity: krProgress,
                      child: const Text(
                        '한 미 동 맹 단',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
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
