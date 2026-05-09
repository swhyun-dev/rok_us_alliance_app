// lib/screens/splash/magic_circle_painter.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// RPG 소환진 (3겹 링)
///
/// - Ring 1: 외곽 실선 (12s/회전, 빨강)
/// - Ring 2: 중간 점선 (8s/역회전, 빨강)
/// - Ring 3: 내부 실선 (6s/회전, 흰)
///
/// [appearProgress] 는 0→1 등장 스케일·페이드인.
/// [spinValue] 는 24s 주기 [_spin] 컨트롤러 값(0→1) — 24=LCM(12,8,6)이라 매 사이클마다
/// 모든 링이 정수배 회전을 마치므로 boundary 점프가 시각적으로 보이지 않는다.
class MagicCirclePainter extends CustomPainter {
  MagicCirclePainter({
    required this.appearProgress,
    required this.spinValue,
    required this.pulseValue,
  });

  /// 0 → 1 등장 진행 (스케일·페이드인 공유)
  final double appearProgress;

  /// 24s repeat 컨트롤러 값 (0~1)
  final double spinValue;

  /// 0~1 펄스 진행 (외곽 링 펄스용)
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (appearProgress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // 등장 페이즈 분할: 외곽(0.5s~), 점선(0.7s~), 내부(0.9s~)
    // appearProgress 입력 범위가 master 의 전체 등장 윈도우(0.5~1.5s)
    final r1 = appearProgress; // 외곽
    final r2 = (appearProgress * 1.4 - 0.4).clamp(0.0, 1.0); // 0.7s 부터
    final r3 = (appearProgress * 1.7 - 0.7).clamp(0.0, 1.0); // 0.9s 부터

    final r1Scale = _easeOut(r1);
    final r2Scale = _easeOut(r2);
    final r3Scale = _easeOut(r3);

    // 12s/회전 = 24s 마스터 사이클의 2턴 → spin * 4π
    final ring1Angle = spinValue * 4 * math.pi;
    // 8s/회전 reverse = 3턴 → -spin * 6π
    final ring2Angle = -spinValue * 6 * math.pi;
    // 6s/회전 = 4턴 → spin * 8π
    final ring3Angle = spinValue * 8 * math.pi;

    // ─── Ring 1: 외곽 실선 (펄스 적용)
    if (r1Scale > 0) {
      final pulseAlpha = 0.45 + (math.sin(pulseValue * 2 * math.pi) + 1) / 2 * 0.4;
      final radius = maxRadius * r1Scale;
      _drawRingSpinning(
        canvas,
        center: center,
        radius: radius,
        rotation: ring1Angle,
        opacity: r1Scale,
        paint: Paint()
          ..color = AppColors.accentRed.withValues(alpha: 0.6 * r1Scale)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke,
      );
      // 외곽 글로우 (펄스)
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = AppColors.accentRed.withValues(alpha: pulseAlpha * r1Scale * 0.35)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // ─── Ring 2: 중간 점선 (역회전)
    if (r2Scale > 0) {
      final radius = (maxRadius - 30) * r2Scale + 30 * (1 - r2Scale);
      _drawDashedRing(
        canvas,
        center: center,
        radius: radius,
        rotation: ring2Angle,
        opacity: r2Scale,
        color: AppColors.accentRed.withValues(alpha: 0.8 * r2Scale),
        strokeWidth: 0.9,
        dashCount: 36,
        dashFill: 0.55,
      );
    }

    // ─── Ring 3: 내부 실선 (희미한 흰)
    if (r3Scale > 0) {
      final radius = (maxRadius - 60) * r3Scale + 60 * (1 - r3Scale);
      _drawRingSpinning(
        canvas,
        center: center,
        radius: radius,
        rotation: ring3Angle,
        opacity: r3Scale,
        paint: Paint()
          ..color = Colors.white.withValues(alpha: 0.4 * r3Scale)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawRingSpinning(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double opacity,
    required Paint paint,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawCircle(Offset.zero, radius, paint);
    canvas.restore();
  }

  void _drawDashedRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double opacity,
    required Color color,
    required double strokeWidth,
    required int dashCount,
    required double dashFill,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    final dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      canvas.drawArc(
        rect,
        i * dashAngle,
        dashAngle * dashFill,
        false,
        paint,
      );
    }

    canvas.restore();
  }

  double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

  @override
  bool shouldRepaint(covariant MagicCirclePainter old) {
    return old.appearProgress != appearProgress ||
        old.spinValue != spinValue ||
        old.pulseValue != pulseValue;
  }
}
