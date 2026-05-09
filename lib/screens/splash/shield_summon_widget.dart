// lib/screens/splash/shield_summon_widget.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/colors.dart';

/// 방패 소환 위젯 — Y축 360° 회전과 함께 등장 + 후광 + 호버.
///
/// CSS 기반 키프레임:
///   shieldSummon (1.2s, cubic-bezier(.34,1.56,.64,1)):
///     0%  scale 0,    rotateY 0,  opacity 0
///     30% scale 0.4,  rotateY 180, opacity 0.5
///     60% scale 1.15, rotateY 360, opacity 1
///     100% scale 1.0, rotateY 360, opacity 1
///
///   shieldGlow (3s, infinite): drop-shadow 펄스 — 본 구현에선 후광 위젯이 대신.
class ShieldSummonWidget extends StatelessWidget {
  const ShieldSummonWidget({
    super.key,
    required this.summonProgress,
    required this.auraProgress,
    required this.loopValue,
  });

  /// 소환 진행 (0~1) — _master 의 1.8s ~ 3.0s 윈도우
  final double summonProgress;

  /// 후광 등장 진행 (0~1) — _master 의 2.0s ~ 3.0s 윈도우
  final double auraProgress;

  /// 0~1 반복 — 호버·펄스 모션용 (3s 주기)
  final double loopValue;

  static const double _shieldWidth = 200;
  // shield_final.svg viewBox 220×280 비율 유지
  static const double _shieldHeight = _shieldWidth * 280 / 220;

  @override
  Widget build(BuildContext context) {
    if (summonProgress <= 0 && auraProgress <= 0) {
      return const SizedBox.shrink();
    }

    final scale = _scaleAt(summonProgress);
    final rotation = _rotationAt(summonProgress);
    final opacity = _opacityAt(summonProgress);

    // 호버 (소환 완료 후) — y 방향 ±4px
    final hoverY = summonProgress >= 1.0
        ? math.sin(loopValue * 2 * math.pi) * 4
        : 0.0;

    return SizedBox(
      width: 320,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (auraProgress > 0) _Aura(progress: auraProgress, loopValue: loopValue),
          if (opacity > 0)
            Transform.translate(
              offset: Offset(0, hoverY),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(rotation)
                  ..scaleByDouble(scale, scale, 1, 1),
                child: Opacity(
                  opacity: opacity,
                  child: SvgPicture.asset(
                    'assets/svg/shield_final.svg',
                    width: _shieldWidth,
                    height: _shieldHeight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Keyframe 보간 helpers ──────────────────────────────────

  static double _scaleAt(double t) {
    if (t <= 0) return 0;
    if (t < 0.30) return (t / 0.30) * 0.40; // 0 → 0.4
    if (t < 0.60) return 0.40 + ((t - 0.30) / 0.30) * 0.75; // 0.4 → 1.15
    if (t < 1.0) return 1.15 - ((t - 0.60) / 0.40) * 0.15; // 1.15 → 1.0
    return 1.0;
  }

  static double _rotationAt(double t) {
    if (t <= 0) return 0;
    if (t < 0.60) return (t / 0.60) * 2 * math.pi; // 0 → 360°
    return 2 * math.pi;
  }

  static double _opacityAt(double t) {
    if (t <= 0) return 0;
    if (t < 0.30) return (t / 0.30) * 0.5; // 0 → 0.5
    if (t < 0.60) return 0.5 + ((t - 0.30) / 0.30) * 0.5; // 0.5 → 1
    return 1.0;
  }
}

/// 방패 후광 (radial red glow) — 등장 후 펄스 반복
class _Aura extends StatelessWidget {
  const _Aura({required this.progress, required this.loopValue});
  final double progress;
  final double loopValue;

  @override
  Widget build(BuildContext context) {
    final baseScale = progress; // 0 → 1
    final pulse = 1.0 + math.sin(loopValue * 2 * math.pi) * 0.15 * progress;
    final pulseAlpha = 0.7 + math.sin(loopValue * 2 * math.pi) * 0.3 * progress;
    final size = 280.0 * baseScale * pulse;
    if (size <= 0) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accentRed.withValues(alpha: 0.40 * pulseAlpha),
            AppColors.accentRed.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.6],
        ),
      ),
    );
  }
}
