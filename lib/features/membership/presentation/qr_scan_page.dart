// lib/features/membership/presentation/qr_scan_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_app_bar.dart';
import '../data/member_store.dart';

// 이벤트 QR 포맷: "rok_event:{eventId}"
class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  _ScanState _state = _ScanState.scanning;
  String? _eventId;
  Timer? _resetTimer;

  static const _eventQrPrefix = 'rok_event:';
  static const _participationPoints = 150;

  @override
  void dispose() {
    _controller.dispose();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    if (!raw.startsWith(_eventQrPrefix)) return;

    setState(() => _isProcessing = true);
    HapticFeedback.heavyImpact();

    final eventId = raw.substring(_eventQrPrefix.length);
    final member = MemberStore.current;

    if (member == null) {
      setState(() {
        _state = _ScanState.noMember;
        _eventId = null;
      });
    } else {
      await MemberStore.addPoints(_participationPoints, reason: '행사 QR 참여: $eventId');
      setState(() {
        _state = _ScanState.success;
        _eventId = eventId;
      });
    }

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _state = _ScanState.scanning;
        _eventId = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AllianceAppBar.sub(
        title: 'QR 참여 인증',
        subtitle: '행사 현장 QR을 스캔해 참여를 확인합니다',
      ),
      body: Stack(
        children: [
          // 카메라 뷰
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 스캔 프레임 오버레이
          _ScanOverlay(state: _state),

          // 상단 안내
          if (_state == _ScanState.scanning)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.60),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '행사장 QR 코드를 프레임 안에 맞춰주세요',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // 결과 패널
          if (_state != _ScanState.scanning)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _ResultPanel(state: _state, eventId: _eventId),
            ),

          // 플래시 버튼
          if (_state == _ScanState.scanning)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (ctx, camState, _) {
                    return IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: Icon(
                        camState.torchState == TorchState.on
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

enum _ScanState { scanning, success, noMember }

// ─── 스캔 오버레이 ────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay({required this.state});
  final _ScanState state;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.70;
    final top = (size.height - frameSize) / 2 - 40;
    final frameLeft = (size.width - frameSize) / 2;

    Color frameColor;
    switch (state) {
      case _ScanState.success:
        frameColor = AppColors.koreanBlue;
      case _ScanState.noMember:
        frameColor = AppColors.koreanRed;
      case _ScanState.scanning:
        frameColor = Colors.white;
    }

    return Stack(
      children: [
        Positioned(top: 0, left: 0, right: 0, height: top,
            child: _dark()),
        Positioned(top: top, left: 0, width: frameLeft, height: frameSize,
            child: _dark()),
        Positioned(top: top, right: 0, width: frameLeft, height: frameSize,
            child: _dark()),
        Positioned(top: top + frameSize, left: 0, right: 0, bottom: 0,
            child: _dark()),
        Positioned(
          top: top,
          left: frameLeft,
          child: SizedBox(
            width: frameSize,
            height: frameSize,
            child: CustomPaint(painter: _FramePainter(color: frameColor)),
          ),
        ),
      ],
    );
  }

  Widget _dark() => Container(color: Colors.black.withValues(alpha: 0.55));
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

    for (final c in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ]) {
      final dx = c.dx == 0 ? 1.0 : -1.0;
      final dy = c.dy == 0 ? 1.0 : -1.0;
      canvas.drawLine(c + Offset(dx * r, 0), c + Offset(dx * (len + r), 0), paint);
      canvas.drawLine(c + Offset(0, dy * r), c + Offset(0, dy * (len + r)), paint);
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.color != color;
}

// ─── 결과 패널 ────────────────────────────────────────────────────────────────

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.state, required this.eventId});
  final _ScanState state;
  final String? eventId;

  @override
  Widget build(BuildContext context) {
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
      child: state == _ScanState.success
          ? _SuccessContent(eventId: eventId)
          : _FailContent(),
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.eventId});
  final String? eventId;

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
          child: const Icon(Icons.check_circle_rounded,
              color: AppColors.koreanBlue, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '참여 완료!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanBlue,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '행사 ID: ${eventId ?? '-'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: AppColors.shieldGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            children: [
              Text(
                '+150P',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '적립',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
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

class _FailContent extends StatelessWidget {
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
          child: const Icon(Icons.warning_amber_rounded,
              color: AppColors.koreanRed, size: 30),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '회원 정보 없음',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanRed,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '로그인 후 회원 정보를 불러온 뒤 다시 시도해주세요.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
