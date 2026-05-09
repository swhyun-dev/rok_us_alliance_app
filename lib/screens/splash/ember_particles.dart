// lib/screens/splash/ember_particles.dart
import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// 12개의 떠다니는 빛 입자 (RPG 포털 분위기).
///
/// 단일 [_emberLoop] 컨트롤러(4s repeat)를 공유하고, 각 입자는 delayFraction
/// 만큼 위상을 어긋나서 같은 keyframe 을 다른 시점에 반복한다.
///
/// 키프레임 (4s 주기):
///   0%   y=120%, opacity 0,  scale 1
///   10%             opacity 1
///   50%  y=0%, x=+20, scale 1.2, opacity 1
///   90%             opacity 0.7
///   100% y=-30%, x=-10, scale 0.5, opacity 0
class EmberParticles extends StatefulWidget {
  const EmberParticles({super.key});

  @override
  State<EmberParticles> createState() => _EmberParticlesState();
}

class _EmberParticlesState extends State<EmberParticles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _emberLoop;

  // (leftPercent, color, delaySeconds) — HTML CSS 와 동일한 12개 입자
  static const List<_EmberSeed> _seeds = [
    _EmberSeed(0.08, _EmberColor.red, 0.0),
    _EmberSeed(0.18, _EmberColor.gold, 1.2),
    _EmberSeed(0.28, _EmberColor.red, 0.5),
    _EmberSeed(0.38, _EmberColor.white, 2.0),
    _EmberSeed(0.48, _EmberColor.red, 0.8),
    _EmberSeed(0.58, _EmberColor.gold, 2.5),
    _EmberSeed(0.68, _EmberColor.red, 1.5),
    _EmberSeed(0.78, _EmberColor.white, 0.3),
    _EmberSeed(0.88, _EmberColor.red, 1.8),
    _EmberSeed(0.13, _EmberColor.gold, 3.0),
    _EmberSeed(0.53, _EmberColor.white, 3.5),
    _EmberSeed(0.73, _EmberColor.red, 2.8),
  ];

  @override
  void initState() {
    super.initState();
    _emberLoop = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _emberLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _emberLoop,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: _seeds.map((seed) {
                final phase = (_emberLoop.value + seed.delay / 4.0) % 1.0;
                return _Ember(
                  phase: phase,
                  width: width,
                  height: height,
                  leftPercent: seed.leftPercent,
                  color: seed.color,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _Ember extends StatelessWidget {
  const _Ember({
    required this.phase,
    required this.width,
    required this.height,
    required this.leftPercent,
    required this.color,
  });

  final double phase; // 0 ~ 1
  final double width;
  final double height;
  final double leftPercent;
  final _EmberColor color;

  @override
  Widget build(BuildContext context) {
    final opacity = _opacityAt(phase);
    if (opacity <= 0) return const SizedBox.shrink();

    final yPercent = _yAt(phase); // 1.20 → -0.30
    final xOffset = _xAt(phase);
    final scale = _scaleAt(phase);

    final left = leftPercent * width;
    final top = yPercent * height;

    final emberColor = switch (color) {
      _EmberColor.red => AppColors.accentRed,
      _EmberColor.gold => AppColors.gradeGold,
      _EmberColor.white => Colors.white,
    };
    final glowColor = switch (color) {
      _EmberColor.red => AppColors.accentRed.withValues(alpha: 0.6),
      _EmberColor.gold => AppColors.gradeGold.withValues(alpha: 0.6),
      _EmberColor.white => Colors.white.withValues(alpha: 0.6),
    };

    return Positioned(
      left: left + xOffset - 1.5,
      top: top - 1.5,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: emberColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: emberColor, blurRadius: 6),
                BoxShadow(color: glowColor, blurRadius: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _yAt(double t) {
    // 1.20 → 0 → -0.30
    if (t < 0.5) {
      return 1.20 - (1.20 / 0.5) * t; // 1.20 → 0
    }
    return -((t - 0.5) / 0.5) * 0.30; // 0 → -0.30
  }

  static double _xAt(double t) {
    // 0 → +20 → -10 (px)
    if (t < 0.5) {
      return (t / 0.5) * 20.0;
    }
    return 20.0 - ((t - 0.5) / 0.5) * 30.0; // 20 → -10
  }

  static double _scaleAt(double t) {
    // 1 → 1.2 → 0.5
    if (t < 0.5) return 1.0 + (t / 0.5) * 0.2;
    return 1.2 - ((t - 0.5) / 0.5) * 0.7;
  }

  static double _opacityAt(double t) {
    if (t < 0.10) return t / 0.10; // 0 → 1
    if (t < 0.50) return 1;
    if (t < 0.90) return 1 - (t - 0.5) / 0.4 * 0.3; // 1 → 0.7
    return 0.7 - (t - 0.9) / 0.1 * 0.7; // 0.7 → 0
  }
}

enum _EmberColor { red, gold, white }

class _EmberSeed {
  const _EmberSeed(this.leftPercent, this.color, this.delay);
  final double leftPercent;
  final _EmberColor color;
  final double delay;
}
