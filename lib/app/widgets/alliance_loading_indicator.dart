// lib/app/widgets/alliance_loading_indicator.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 태극기(Taeguk) ↔ 성조기 별(Star) 교차 로딩 인디케이터.
class AllianceLoadingIndicator extends StatefulWidget {
  const AllianceLoadingIndicator({super.key, this.size = 52.0});

  final double size;

  @override
  State<AllianceLoadingIndicator> createState() =>
      _AllianceLoadingIndicatorState();
}

class _AllianceLoadingIndicatorState extends State<AllianceLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _AlliancePainter(t: _ctrl.value),
      ),
    );
  }
}

// Full-screen loading overlay
class AllianceLoadingOverlay extends StatelessWidget {
  const AllianceLoadingOverlay({super.key, this.message = '로딩 중...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkNavy.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AllianceLoadingIndicator(size: 68),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _AlliancePainter extends CustomPainter {
  const _AlliancePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final strokeW = (outerR * 0.17).clamp(4.0, 8.0);
    final innerR = (outerR - strokeW) * 0.50;

    // Background track
    canvas.drawCircle(
      center,
      outerR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = const Color(0xFFEAEFF7),
    );

    // Rotating flag-gradient arc
    _drawFlagArc(canvas, center, outerR, strokeW);

    // Symbol phase timing
    // 0.00–0.35 : Taeguk  (Korean flag)
    // 0.35–0.50 : fade out Taeguk, fade in Star
    // 0.50–0.85 : Star    (US flag)
    // 0.85–1.00 : fade out Star, fade in Taeguk
    final double taegukA, starA;
    if (t < 0.35) {
      taegukA = 1.0;
      starA = 0.0;
    } else if (t < 0.50) {
      final f = (t - 0.35) / 0.15;
      taegukA = 1.0 - f;
      starA = f;
    } else if (t < 0.85) {
      taegukA = 0.0;
      starA = 1.0;
    } else {
      final f = (t - 0.85) / 0.15;
      taegukA = f;
      starA = 1.0 - f;
    }

    if (taegukA > 0.01) {
      _drawTaeguk(canvas, center, innerR, t * 2 * math.pi, taegukA);
    }
    if (starA > 0.01) {
      _drawStar(canvas, center, innerR, t * math.pi * 0.6, starA);
    }
  }

  void _drawFlagArc(
      Canvas canvas, Offset center, double radius, double strokeW) {
    const sweepDeg = 280.0;
    const sweepRad = sweepDeg / 360.0 * 2 * math.pi;
    final startAngle = t * 2 * math.pi - math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      startAngle,
      sweepRad,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [
            AppColors.koreanRed,
            Colors.white,
            AppColors.koreanBlue,
            AppColors.koreanRed,
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
          transform: GradientRotation(startAngle),
        ).createShader(rect),
    );
  }

  // 태극 (yin-yang style Korean symbol)
  void _drawTaeguk(Canvas canvas, Offset center, double radius,
      double rotation, double alpha) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final red = AppColors.koreanRed.withValues(alpha: alpha);
    final blue = AppColors.koreanBlue.withValues(alpha: alpha);

    final redP = Paint()..color = red;
    final blueP = Paint()..color = blue;

    final r = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawArc(r, math.pi, math.pi, true, redP);   // top half red
    canvas.drawArc(r, 0, math.pi, true, blueP);         // bottom half blue

    // Small inner circles (completing the Taeguk)
    canvas.drawCircle(Offset(0, -radius / 2), radius / 2, blueP);
    canvas.drawCircle(Offset(0, radius / 2), radius / 2, redP);

    canvas.restore();
  }

  // 5-pointed star (US flag star)
  void _drawStar(Canvas canvas, Offset center, double outerR,
      double rotation, double alpha) {
    final innerR = outerR * 0.40;
    final startAngle = -math.pi / 2 + rotation;
    final path = Path();

    for (int i = 0; i < 10; i++) {
      final angle = startAngle + (i * math.pi / 5);
      final r = i.isEven ? outerR : innerR;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.koreanBlue.withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _AlliancePainter old) => old.t != t;
}
