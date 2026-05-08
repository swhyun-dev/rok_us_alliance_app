// lib/shared/widgets/app_toast.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// ScaffoldMessenger.SnackBar 가 일부 환경에서 자동 dismiss 가 안 되는 문제로
/// 만든 OverlayEntry 기반 토스트. 호출 시 이전 토스트가 떠 있으면 즉시 닫고
/// 새로 띄움. duration 끝나면 페이드아웃 후 제거.
class AppToast {
  AppToast._();

  static OverlayEntry? _current;
  static Timer? _timer;

  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      debugPrint('[AppToast] overlay null — toast skipped');
      return;
    }

    _dismiss();

    final entry = OverlayEntry(
      builder: (ctx) => _ToastView(
        message: message,
        backgroundColor: backgroundColor ?? AppColors.textPrimary,
      ),
    );
    overlay.insert(entry);
    _current = entry;
    debugPrint('[AppToast] inserted, will dismiss in ${duration.inMilliseconds}ms');

    _timer = Timer(duration, () {
      debugPrint('[AppToast] timer fired → dismissing');
      _dismiss();
    });
  }

  static void _dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _current;
    _current = null;
    if (entry != null) {
      try {
        entry.remove();
        debugPrint('[AppToast] entry removed');
      } catch (e) {
        debugPrint('[AppToast] entry.remove() threw: $e');
      }
    }
  }
}

class _ToastView extends StatefulWidget {
  const _ToastView({required this.message, required this.backgroundColor});

  final String message;
  final Color backgroundColor;

  @override
  State<_ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<_ToastView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..forward();
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Positioned(
      left: 24,
      right: 24,
      bottom: mq.padding.bottom + 96,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offset,
          child: FadeTransition(
            opacity: _opacity,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 480),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.backgroundColor.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
