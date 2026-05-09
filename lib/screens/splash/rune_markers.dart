// lib/screens/splash/rune_markers.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// 마법진 외곽 8방향에 배치되는 빨간 십자(+) 룬 마커.
///
/// 각 마커는 1.0s + i*0.05s 에 0.5s 페이드인. 최종 opacity 0.8 유지.
/// [masterTime] 은 master 컨트롤러의 절대 시간(초).
class RuneMarkers extends StatelessWidget {
  const RuneMarkers({super.key, required this.masterTime});

  final double masterTime;

  static const double _radius = 150;
  static const int _count = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _radius * 2 + 24,
      height: _radius * 2 + 24,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(_count, (i) {
          // 위쪽 12시 방향(=−π/2)부터 시계 방향으로 8등분
          final angle = (i / _count) * 2 * math.pi - math.pi / 2;
          final x = math.cos(angle) * _radius;
          final y = math.sin(angle) * _radius;

          final start = 1.0 + i * 0.05;
          final localProgress =
              ((masterTime - start) / 0.5).clamp(0.0, 1.0);
          final opacity = _runeOpacity(localProgress);

          if (opacity <= 0) return const SizedBox.shrink();

          return Transform.translate(
            offset: Offset(x, y),
            child: Opacity(
              opacity: opacity,
              child: const _CrossRune(),
            ),
          );
        }),
      ),
    );
  }

  /// CSS keyframe: 0% → 50% peak (1) → 100% (0.8)
  static double _runeOpacity(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 0.8;
    if (t < 0.5) return t * 2; // 0 → 1
    return 1 - (t - 0.5) * 0.4; // 1 → 0.8
  }
}

class _CrossRune extends StatelessWidget {
  const _CrossRune();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 12,
      height: 12,
      child: CustomPaint(painter: _CrossRunePainter()),
    );
  }
}

class _CrossRunePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // 글로우 (가벼운 마스크 블러)
    final glowPaint = Paint()
      ..color = AppColors.accentRed.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 12, height: 2),
      glowPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 2, height: 12),
      glowPaint,
    );
    // 본체
    final paint = Paint()..color = AppColors.accentRed;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 12, height: 2),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 2, height: 12),
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
