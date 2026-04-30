// lib/shared/widgets/alliance_logo.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// 한미동맹단 브랜드 로고 — 방패 형태 안에 흰 별 + 골드 stripe.
/// CustomPainter 로 그려 모든 사이즈에서 선명. 별도 자산 파일 불필요.
///
/// 사용 예:
///   AllianceLogo(size: 100)
///   AllianceLogo(size: 64, glow: false)
class AllianceLogo extends StatelessWidget {
  const AllianceLogo({
    super.key,
    required this.size,
    this.glow = true,
  });

  final double size;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final logo = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AllianceLogoPainter(),
        isComplex: true,
      ),
    );
    if (!glow) return logo;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: size * 0.28,
            spreadRadius: size * 0.04,
          ),
        ],
      ),
      child: logo,
    );
  }
}

class _AllianceLogoPainter extends CustomPainter {
  static const _navy = AppColors.darkNavy;
  static const _navyDeep = Color(0xFF0A1830);
  static const _gold = AppColors.gold;
  static const _white = Colors.white;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final shieldPath = _buildShieldPath(w, h);

    // 1) 방패 면 (그림자)
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2) 방패 면 — 딥 네이비 그라디언트
    canvas.drawPath(
      shieldPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_navyDeep, _navy],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // 3) 가로 골드 stripe (별 위·아래)
    final stripePaint = Paint()
      ..color = _gold.withValues(alpha: 0.85)
      ..strokeWidth = h * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipPath(shieldPath);
    canvas.drawLine(
      Offset(w * 0.18, h * 0.32),
      Offset(w * 0.82, h * 0.32),
      stripePaint,
    );
    canvas.drawLine(
      Offset(w * 0.18, h * 0.62),
      Offset(w * 0.82, h * 0.62),
      stripePaint,
    );
    canvas.restore();

    // 4) 중앙 흰 5각별
    final starCenter = Offset(w * 0.5, h * 0.47);
    final starOuter = w * 0.20;
    final starInner = starOuter * 0.42;
    final starPath = _buildStarPath(starCenter, starOuter, starInner, 5);
    canvas.drawPath(
      starPath,
      Paint()
        ..color = _white.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    canvas.drawPath(
      starPath,
      Paint()..color = _white,
    );

    // 5) 외곽 골드 테두리
    canvas.drawPath(
      shieldPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.022
        ..color = _gold,
    );

    // 6) 외곽 안쪽 가는 흰 라인 (광택)
    canvas.drawPath(
      shieldPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.006
        ..color = _white.withValues(alpha: 0.28),
    );
  }

  /// 방패 외곽 — 위는 둥근 사각형 어깨, 아래는 부드러운 V.
  Path _buildShieldPath(double w, double h) {
    final p = Path();
    final shoulderRadius = w * 0.18;
    final topY = h * 0.06;
    final shoulderY = h * 0.28;
    final tipY = h * 0.96;
    final leftX = w * 0.10;
    final rightX = w * 0.90;
    final centerX = w * 0.5;

    p.moveTo(leftX + shoulderRadius, topY);
    p.lineTo(rightX - shoulderRadius, topY);
    // 우측 어깨 라운딩
    p.quadraticBezierTo(rightX, topY, rightX, topY + shoulderRadius);
    p.lineTo(rightX, shoulderY);
    // 우측 → 아래 팁: 곡선
    p.cubicTo(
      rightX, h * 0.55,
      w * 0.78, h * 0.85,
      centerX, tipY,
    );
    // 좌측 팁 → 위로 곡선
    p.cubicTo(
      w * 0.22, h * 0.85,
      leftX, h * 0.55,
      leftX, shoulderY,
    );
    p.lineTo(leftX, topY + shoulderRadius);
    // 좌측 어깨 라운딩
    p.quadraticBezierTo(leftX, topY, leftX + shoulderRadius, topY);
    p.close();
    return p;
  }

  /// 정n각 별 (n=5 → 5점 별).
  Path _buildStarPath(Offset center, double outer, double inner, int points) {
    final p = Path();
    final step = math.pi / points;
    final start = -math.pi / 2; // 위쪽이 첫 꼭지점
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
