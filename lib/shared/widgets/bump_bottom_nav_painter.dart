// lib/shared/widgets/bump_bottom_nav_painter.dart
import 'package:flutter/material.dart';

/// 탭바 배경에 중앙 오목 컷아웃을 그리는 CustomPainter.
/// CLAUDE.md Section 5-2 의 Path 코드 기반.
class BumpBottomNavPainter extends CustomPainter {
  const BumpBottomNavPainter({
    required this.cutoutRadius,
    required this.backgroundColor,
    required this.shadowColor,
  });

  final double cutoutRadius;
  final Color backgroundColor;
  final Color shadowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final r = cutoutRadius;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(mid - r - 15, 0)
      ..quadraticBezierTo(
        mid - r,
        0,
        mid - r,
        r * 0.4,
      )
      ..quadraticBezierTo(
        mid,
        -r * 0.8,
        mid + r,
        r * 0.4,
      )
      ..quadraticBezierTo(
        mid + r,
        0,
        mid + r + 15,
        0,
      )
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, shadowColor, 8, false);
    canvas.drawPath(path, Paint()..color = backgroundColor);
  }

  @override
  bool shouldRepaint(covariant BumpBottomNavPainter oldDelegate) {
    return oldDelegate.cutoutRadius != cutoutRadius ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.shadowColor != shadowColor;
  }
}
