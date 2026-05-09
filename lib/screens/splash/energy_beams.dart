// lib/screens/splash/energy_beams.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// 4방향 에너지 광선 (위/오른/아래/왼). 마법진 중심에서 외곽으로 뻗어나가는 빛줄기.
///
/// CSS keyframe `beamShoot` (0.6s):
///   0%  → height 0,    opacity 0
///   50% → height 200,  opacity 1
///   100% → height 200, opacity 0
///
/// 각 광선 시작 시각: top=1.6s, right=1.65s, bottom=1.7s, left=1.75s
class EnergyBeams extends StatelessWidget {
  const EnergyBeams({super.key, required this.masterTime});

  final double masterTime;

  static const double _maxHeight = 200;
  static const double _duration = 0.6;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _beam(direction: _Dir.top, startAt: 1.60),
        _beam(direction: _Dir.right, startAt: 1.65),
        _beam(direction: _Dir.bottom, startAt: 1.70),
        _beam(direction: _Dir.left, startAt: 1.75),
      ],
    );
  }

  Widget _beam({required _Dir direction, required double startAt}) {
    final t = ((masterTime - startAt) / _duration).clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final height = t < 0.5 ? t * 2 * _maxHeight : _maxHeight;
    final opacity = t < 0.5 ? t * 2 : 1 - (t - 0.5) * 2;

    final dx = math.sin(direction.angle) * height / 2;
    final dy = -math.cos(direction.angle) * height / 2;

    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: direction.angle,
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Container(
            width: 4,
            height: height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.transparent,
                  AppColors.accentRed,
                  Colors.white,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentRed.withValues(alpha: 0.7),
                  blurRadius: 15,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _Dir {
  top(0),
  right(math.pi / 2),
  bottom(math.pi),
  left(-math.pi / 2);

  final double angle;
  const _Dir(this.angle);
}
