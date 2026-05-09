// lib/features/membership/presentation/widgets/qr_countdown_pill.dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../theme/colors.dart';
import '../../data/qr_service.dart';

/// QR 토큰의 잔여 만료 시간을 보여주는 작은 pill.
///
/// - 매 초 setState 로 카운트 갱신
/// - [qrToken] 이 회전(부모 setState)되면 자동으로 카운트가 리셋됨
/// - 잔여 5초 미만일 때 [AppColors.qrCountdownUrgent] 로 빨강 강조
class QrCountdownPill extends StatefulWidget {
  const QrCountdownPill({super.key, required this.qrToken});

  final String qrToken;

  @override
  State<QrCountdownPill> createState() => _QrCountdownPillState();
}

class _QrCountdownPillState extends State<QrCountdownPill> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = QrService.remainingSeconds(widget.qrToken);
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 600));
    });
  }

  @override
  void didUpdateWidget(covariant QrCountdownPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qrToken != widget.qrToken) {
      setState(() {
        _seconds = QrService.remainingSeconds(widget.qrToken);
      });
      _startTicker();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = _seconds < 5;
    final mm = _seconds ~/ 60;
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isUrgent ? AppColors.qrCountdownUrgent : AppColors.qrCountdownBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$mm:$ss',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
