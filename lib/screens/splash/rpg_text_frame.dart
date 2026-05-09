// lib/screens/splash/rpg_text_frame.dart
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../theme/colors.dart';

/// RPG 클래스 카드 스타일 텍스트 프레임.
///
/// 시퀀스 (master 시간 기준):
///   3.00~3.80s : frame 등장 (translateY 20→0, opacity 0→1)
///   3.30~4.10s : "ROK · US" letter-spacing 20→7, blur 8→0
///   3.50~4.20s : "ALLIANCE"
///   3.70~4.30s : 데코 (line + diamond + line)
///   3.85~4.45s : "한 미 동 맹 단"
///   loop      : 다이아몬드 무한 회전 (3s/turn), 텍스트 글로우 펄스
class RpgTextFrame extends StatelessWidget {
  const RpgTextFrame({
    super.key,
    required this.frameProgress,
    required this.rokUsProgress,
    required this.allianceProgress,
    required this.decoProgress,
    required this.krProgress,
    required this.loopValue,
  });

  final double frameProgress;
  final double rokUsProgress;
  final double allianceProgress;
  final double decoProgress;
  final double krProgress;

  /// 0~1 반복 (3s 주기) — 다이아몬드 회전, 텍스트 펄스
  final double loopValue;

  @override
  Widget build(BuildContext context) {
    if (frameProgress <= 0) return const SizedBox.shrink();

    final translateY = (1 - frameProgress) * 20;

    // 텍스트 펄스 — 등장 완료 후만 적용
    final pulse = (math.sin(loopValue * 2 * math.pi) + 1) / 2; // 0~1
    final pulseFactor = rokUsProgress >= 1.0 ? pulse : 0.0;

    return Opacity(
      opacity: frameProgress,
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 18, 30, 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentRed.withValues(alpha: 0.05),
                Colors.black.withValues(alpha: 0.40),
                AppColors.accentRed.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: AppColors.accentRed.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ..._cornerDecorations(),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildRokUs(rokUsProgress, pulseFactor),
                  const SizedBox(height: 6),
                  _buildAlliance(allianceProgress),
                  const SizedBox(height: 12),
                  _buildDecoRow(decoProgress, loopValue),
                  const SizedBox(height: 10),
                  _buildKr(krProgress),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 4 모서리 ┌ ┐ └ ┘ ───────────────────────────────────

  List<Widget> _cornerDecorations() {
    const corner = 12.0;
    const stroke = 2.0;
    return const [
      Positioned(
        top: -2 - 18,
        left: -2 - 30,
        child: _Corner(top: stroke, left: stroke, size: corner),
      ),
      Positioned(
        top: -2 - 18,
        right: -2 - 30,
        child: _Corner(top: stroke, right: stroke, size: corner),
      ),
      Positioned(
        bottom: -2 - 14,
        left: -2 - 30,
        child: _Corner(bottom: stroke, left: stroke, size: corner),
      ),
      Positioned(
        bottom: -2 - 14,
        right: -2 - 30,
        child: _Corner(bottom: stroke, right: stroke, size: corner),
      ),
    ];
  }

  // ─── 텍스트 line 들 ──────────────────────────────────────

  Widget _buildRokUs(double progress, double pulseFactor) {
    if (progress <= 0) {
      return const SizedBox(height: 38);
    }
    final letterSpacing = lerpDouble(20, 7, progress) ?? 7;
    final glowAlpha = 0.4 + 0.4 * pulseFactor;
    return Opacity(
      opacity: progress,
      child: Text(
        'ROK · US',
        style: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 38,
          letterSpacing: letterSpacing,
          color: AppColors.textPrimary,
          height: 1,
          shadows: [
            Shadow(color: AppColors.accentRed, blurRadius: 6),
            Shadow(
              color: AppColors.accentRed.withValues(alpha: 0.8),
              blurRadius: 12,
            ),
            Shadow(
              color: AppColors.accentRed.withValues(alpha: glowAlpha),
              blurRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlliance(double progress) {
    if (progress <= 0) return const SizedBox(height: 16);
    final letterSpacing = lerpDouble(24, 11, progress) ?? 11;
    return Opacity(
      opacity: progress,
      child: Text(
        'ALLIANCE',
        style: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 16,
          letterSpacing: letterSpacing,
          color: AppColors.accentRed,
          shadows: [
            Shadow(
              color: AppColors.accentRed.withValues(alpha: 0.8),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecoRow(double progress, double loopValue) {
    if (progress <= 0) return const SizedBox(height: 6);
    return Opacity(
      opacity: progress,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DecoLine(),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: math.pi / 4 + loopValue * 2 * math.pi,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                boxShadow: [
                  BoxShadow(color: AppColors.accentRed, blurRadius: 8),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _DecoLine(),
        ],
      ),
    );
  }

  Widget _buildKr(double progress) {
    if (progress <= 0) return const SizedBox(height: 13);
    final letterSpacing = lerpDouble(14, 6, progress) ?? 6;
    return Opacity(
      opacity: progress,
      child: Text(
        '한 미 동 맹 단',
        style: TextStyle(
          fontSize: 13,
          letterSpacing: letterSpacing,
          color: AppColors.textPrimary,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  });

  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.accentRed;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          top: top,
          bottom: bottom,
          left: left,
          right: right,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  _CornerPainter({
    required this.color,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  final Color color;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (top != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top!), paint);
    }
    if (bottom != null) {
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - bottom!, size.width, bottom!),
        paint,
      );
    }
    if (left != null) {
      canvas.drawRect(Rect.fromLTWH(0, 0, left!, size.height), paint);
    }
    if (right != null) {
      canvas.drawRect(
        Rect.fromLTWH(size.width - right!, 0, right!, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _DecoLine extends StatelessWidget {
  const _DecoLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.accentRed,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
