// lib/features/membership/presentation/qr_fullscreen_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/member.dart';

class QrFullscreenPage extends StatefulWidget {
  const QrFullscreenPage({
    super.key,
    required this.member,
    required this.qrToken,
    required this.remainingSeconds,
  });

  final Member member;
  final String qrToken;
  final int remainingSeconds;

  @override
  State<QrFullscreenPage> createState() => _QrFullscreenPageState();
}

class _QrFullscreenPageState extends State<QrFullscreenPage> {
  @override
  void initState() {
    super.initState();
    // 화면 최대 밝기 + 가로세로 잠금 해제
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.softBlue,
                      foregroundColor: AppColors.koreanBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.shieldGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'QR 스캔용',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 회원 정보
            Text(
              widget.member.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.member.grade.label} · ${widget.member.branch}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // QR 코드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.koreanBlue.withValues(alpha: 0.10),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: QrImageView(
                data: widget.qrToken,
                version: QrVersions.auto,
                size: 240,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.darkNavy,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.darkNavy,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 남은 시간 표시
            _CountdownBar(remainingSeconds: widget.remainingSeconds),

            const SizedBox(height: 16),

            // 회원번호
            Text(
              widget.member.memberNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),

            const Spacer(),

            // 하단 국기 스트라이프
            Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: AppColors.flagAccentGradient,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownBar extends StatefulWidget {
  const _CountdownBar({required this.remainingSeconds});
  final int remainingSeconds;

  @override
  State<_CountdownBar> createState() => _CountdownBarState();
}

class _CountdownBarState extends State<_CountdownBar> {
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.remainingSeconds;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 300));
      if (_seconds > 0) _tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _seconds / 300.0;
    final isLow = _seconds <= 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QR 유효 시간',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLow ? AppColors.koreanRed : AppColors.textSecondary,
                ),
              ),
              Text(
                '${_seconds ~/ 60}:${(_seconds % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isLow ? AppColors.koreanRed : AppColors.koreanBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                isLow ? AppColors.koreanRed : AppColors.koreanBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
