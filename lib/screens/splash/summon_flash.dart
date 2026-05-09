// lib/screens/splash/summon_flash.dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// 소환 완료 폭발 플래시 — 2.2s 시작, 0.7s 동안.
///
/// CSS keyframe `summonFlash`:
///   0%  scale 0, opacity 0
///   30% scale 4, opacity 1
///   100% scale 8, opacity 0
class SummonFlash extends StatelessWidget {
  const SummonFlash({super.key, required this.progress});

  /// 0~1 — _master 의 2.2s ~ 2.9s 윈도우
  final double progress;

  @override
  Widget build(BuildContext context) {
    if (progress <= 0 || progress >= 1) return const SizedBox.shrink();

    final scale = _scaleAt(progress);
    final opacity = _opacityAt(progress);
    if (opacity <= 0) return const SizedBox.shrink();

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 100,
          height: 100,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white,
                AppColors.gradeGold,
                AppColors.accentRed,
                Colors.transparent,
              ],
              stops: [0.0, 0.3, 0.6, 0.8],
            ),
          ),
        ),
      ),
    );
  }

  static double _scaleAt(double t) {
    if (t < 0.30) return (t / 0.30) * 4.0; // 0 → 4
    return 4.0 + ((t - 0.30) / 0.70) * 4.0; // 4 → 8
  }

  static double _opacityAt(double t) {
    if (t < 0.30) return t / 0.30; // 0 → 1
    return 1 - (t - 0.30) / 0.70; // 1 → 0
  }
}
