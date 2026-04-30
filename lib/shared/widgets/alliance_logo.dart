// lib/shared/widgets/alliance_logo.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 한미동맹단 브랜드 로고 — 원형 메달 형태.
/// 외곽 골드 링 + 안쪽에 빨강/파랑 호 + 중앙 흰 별 + 둘레 작은 별 6개.
///
/// CustomPainter 로 그려 모든 사이즈에서 선명. 별도 자산 파일 불필요.
///
/// [progress] 1.0 = 완성된 메달. 0.0 부근 = 외곽 링이 부분만 그려진 상태로
/// splash 시퀀스의 결합 단계에서 점진 완성을 표현 가능.
class AllianceLogo extends StatelessWidget {
  const AllianceLogo({
    super.key,
    required this.size,
    this.glow = true,
    this.progress = 1.0,
  });

  final double size;
  final bool glow;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AllianceLogoPainter(progress: progress),
        isComplex: true,
      ),
    );
    if (!glow) return logo;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.22),
            blurRadius: size * 0.30,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: logo,
    );
  }
}

class _AllianceLogoPainter extends CustomPainter {
  _AllianceLogoPainter({required this.progress});

  final double progress;

  static const _navy = AppColors.darkNavy;
  static const _navyDeep = Color(0xFF0A1830);
  static const _gold = AppColors.gold;
  static const _red = AppColors.koreanRed;
  static const _blue = AppColors.koreanBlue;
  static const _white = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.5);
    final radius = math.min(w, h) * 0.46;

    // 1) 메달 그림자
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2) 메달 면 — 딥 네이비 그라디언트
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [_navyDeep, _navy],
          radius: 0.85,
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );

    // 3) 빨강·파랑 호 (별 둘레)
    final arcRect = Rect.fromCircle(
      center: center,
      radius: radius * 0.78,
    );
    final arcStroke = radius * 0.13;
    // 좌측 빨강 (위 9시 ~ 6시 방향, 약 120도)
    canvas.drawArc(
      arcRect,
      math.pi * 0.78,
      math.pi * 0.66,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcStroke
        ..strokeCap = StrokeCap.round
        ..color = _red.withValues(alpha: 0.92),
    );
    // 우측 파랑 (3시 ~ 6시 방향)
    canvas.drawArc(
      arcRect,
      math.pi * 1.56,
      math.pi * 0.66,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcStroke
        ..strokeCap = StrokeCap.round
        ..color = _blue.withValues(alpha: 0.92),
    );

    // 4) 중앙 큰 흰 별
    final starOuter = radius * 0.42;
    final starInner = starOuter * 0.42;
    final starPath = _buildStarPath(center, starOuter, starInner, 5);
    // 글로우
    canvas.drawPath(
      starPath,
      Paint()
        ..color = _white.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(starPath, Paint()..color = _white);

    // 5) 둘레 작은 골드 별 6개 — 외곽 링 안쪽에 배치
    final smallStarOuter = radius * 0.07;
    final smallStarInner = smallStarOuter * 0.45;
    for (var i = 0; i < 6; i++) {
      final angle = (math.pi / 3.0) * i - math.pi / 2.0;
      final dotPos = Offset(
        center.dx + math.cos(angle) * radius * 0.74,
        center.dy + math.sin(angle) * radius * 0.74,
      );
      // 별과 호가 겹치는 영역(좌·우 측면)은 별 생략
      final isSide = (i == 1 || i == 2 || i == 4 || i == 5);
      if (isSide) continue;
      final dotPath =
          _buildStarPath(dotPos, smallStarOuter, smallStarInner, 5);
      canvas.drawPath(
        dotPath,
        Paint()..color = _gold.withValues(alpha: 0.85),
      );
    }

    // 6) 외곽 골드 링 (progress 따라 부분 또는 전체)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.07
      ..strokeCap = StrokeCap.round
      ..color = _gold;
    if (progress >= 1.0) {
      canvas.drawCircle(center, radius, ringPaint);
    } else {
      // 위 12시 부터 시계방향으로 progress 비율만큼 그리기
      final sweep = math.pi * 2 * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweep,
        false,
        ringPaint,
      );
    }

    // 7) 외곽 안쪽 가는 흰 라인 (광택)
    canvas.drawCircle(
      center,
      radius - radius * 0.085,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.012
        ..color = _white.withValues(alpha: 0.20),
    );
  }

  Path _buildStarPath(Offset center, double outer, double inner, int points) {
    final p = Path();
    final step = math.pi / points;
    final start = -math.pi / 2;
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? outer : inner;
      final a = start + step * i;
      final x = center.dx + math.cos(a) * r;
      final y = center.dy + math.sin(a) * r;
      if (i == 0) {
        p.moveTo(x, y);
      } else {
        p.lineTo(x, y);
      }
    }
    p.close();
    return p;
  }

  @override
  bool shouldRepaint(covariant _AllianceLogoPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
