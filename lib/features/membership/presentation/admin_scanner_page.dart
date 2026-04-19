// lib/features/membership/presentation/admin_scanner_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_app_bar.dart';
import '../data/qr_service.dart';

class AdminScannerPage extends StatefulWidget {
  const AdminScannerPage({super.key});

  @override
  State<AdminScannerPage> createState() => _AdminScannerPageState();
}

class _AdminScannerPageState extends State<AdminScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  _ScanResult? _lastResult;
  Timer? _resetTimer;

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    final payload = QrService.verify(raw);

    if (payload == null) {
      setState(() => _lastResult = _ScanResult.invalid());
    } else {
      setState(() => _lastResult = _ScanResult.valid(
            memberId: payload.memberId,
            grade: payload.grade,
          ));
    }

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _lastResult = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AllianceAppBar.sub(title: 'QR 스캐너', subtitle: '회원 단증 QR 인증'),
      body: Stack(
        children: [
          // 카메라 뷰
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // 스캔 오버레이
          _ScanOverlay(isProcessing: _isProcessing),

          // 결과 패널
          if (_lastResult != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ResultPanel(result: _lastResult!),
            ),

          // 상단 안내
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '회원증 QR 코드를 프레임 안에 맞춰주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // 하단 토치 버튼
          Positioned(
            bottom: _lastResult != null ? 200 : 40,
            left: 0,
            right: 0,
            child: Center(
              child: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (ctx, state, _) {
                  return IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(14),
                    ),
                    icon: Icon(
                      state.torchState == TorchState.on
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                    tooltip: '플래시',
                    onPressed: _controller.toggleTorch,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 스캔 결과 모델 ───────────────────────────────────────────────────────────

class _ScanResult {
  _ScanResult._({
    required this.isValid,
    this.memberId,
    this.grade,
  });

  factory _ScanResult.valid({
    required String memberId,
    required String grade,
  }) =>
      _ScanResult._(isValid: true, memberId: memberId, grade: grade);

  factory _ScanResult.invalid() => _ScanResult._(isValid: false);

  final bool isValid;
  final String? memberId;
  final String? grade;

  String get gradeLabel {
    switch (grade) {
      case 'regular':
        return '정회원';
      case 'gold':
        return 'Gold';
      case 'vip':
        return 'VIP';
      case 'honorary':
        return '명예회원';
      default:
        return grade ?? '-';
    }
  }
}

// ─── 스캔 오버레이 ────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.isProcessing});
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.70;
    final top = (size.height - frameSize) / 2 - 40;

    return Stack(
      children: [
        // 반투명 어두운 배경 (4면)
        Positioned(top: 0, left: 0, right: 0, height: top,
            child: _darkLayer()),
        Positioned(top: top, left: 0, width: (size.width - frameSize) / 2, height: frameSize,
            child: _darkLayer()),
        Positioned(top: top, right: 0, width: (size.width - frameSize) / 2, height: frameSize,
            child: _darkLayer()),
        Positioned(top: top + frameSize, left: 0, right: 0, bottom: 0,
            child: _darkLayer()),

        // 프레임 코너
        Positioned(
          top: top,
          left: (size.width - frameSize) / 2,
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: CustomPaint(
              painter: _FramePainter(
                color: isProcessing ? AppColors.koreanBlue : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _darkLayer() => Container(color: Colors.black.withValues(alpha: 0.55));
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 28.0;
    const r = 10.0;

    // 네 모서리 L자 선
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    for (final c in corners) {
      final dx = c.dx == 0 ? 1.0 : -1.0;
      final dy = c.dy == 0 ? 1.0 : -1.0;
      canvas.drawLine(
          c + Offset(dx * r, 0), c + Offset(dx * (len + r), 0), paint);
      canvas.drawLine(
          c + Offset(0, dy * r), c + Offset(0, dy * (len + r)), paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}

// ─── 결과 패널 ────────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result});
  final _ScanResult result;

  @override
  Widget build(BuildContext context) {
    final isValid = result.isValid;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: isValid ? _ValidResult(result: result) : _InvalidResult(),
    );
  }
}

class _ValidResult extends StatelessWidget {
  const _ValidResult({required this.result});
  final _ScanResult result;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.verified_user_rounded,
              color: AppColors.koreanBlue, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '인증 성공',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '회원 ID: ${result.memberId ?? '-'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '등급: ${result.gradeLabel}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.koreanBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '참여 확인',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _InvalidResult extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.softRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.error_outline_rounded,
              color: AppColors.koreanRed, size: 28),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '인증 실패',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanRed,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'QR 코드가 유효하지 않거나 만료되었습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
