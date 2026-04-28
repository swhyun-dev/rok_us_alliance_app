// lib/features/action_board/presentation/event_checkin_section.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';

/// 행사 상세 화면에 끼워넣는 체크인 섹션.
/// - 관리자: '체크인 코드 발급' 버튼 + 발급된 코드 카드 (10분 카운트다운)
/// - 일반 사용자: '6자리 코드 입력' 버튼 → 다이얼로그
class EventCheckInSection extends StatefulWidget {
  const EventCheckInSection({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventCheckInSection> createState() => _EventCheckInSectionState();
}

class _EventCheckInSectionState extends State<EventCheckInSection> {
  String? _issuedCode;
  DateTime? _issuedExpiresAt;
  bool _generating = false;
  bool _submitting = false;

  Future<void> _generateCode() async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('generateEventCode');
      final result = await callable.call<Map<String, dynamic>>({
        'eventId': widget.eventId,
      });
      final code = result.data['code'] as String?;
      final expiresAtMs = (result.data['expiresAt'] as num?)?.toInt();
      if (!mounted) return;
      if (code == null || expiresAtMs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('코드 발급 응답이 비어 있습니다.')),
        );
        return;
      }
      setState(() {
        _issuedCode = code;
        _issuedExpiresAt =
            DateTime.fromMillisecondsSinceEpoch(expiresAtMs);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('코드 발급 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _submitCode() async {
    final entered = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeInputDialog(),
    );
    if (entered == null || entered.isEmpty) return;
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('eventCheckIn');
      final result = await callable.call<Map<String, dynamic>>({
        'code': entered,
      });
      final pts = (result.data['pointsAwarded'] ?? 100) as int;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+${pts}P 행사 체크인 완료')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('체크인 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminAuthState>(
      valueListenable: AdminAuthStore.notifier,
      builder: (context, authState, _) {
        if (authState.isAdmin) {
          return _AdminBlock(
            generating: _generating,
            issuedCode: _issuedCode,
            issuedExpiresAt: _issuedExpiresAt,
            onGenerate: _generateCode,
          );
        }
        return _UserBlock(
          submitting: _submitting,
          onSubmit: _submitCode,
        );
      },
    );
  }
}

class _AdminBlock extends StatelessWidget {
  const _AdminBlock({
    required this.generating,
    required this.issuedCode,
    required this.issuedExpiresAt,
    required this.onGenerate,
  });

  final bool generating;
  final String? issuedCode;
  final DateTime? issuedExpiresAt;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '관리자 — 행사 체크인 코드',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '6자리 코드를 발급해 현장 참여자에게 공유하세요. 10분간 유효.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (issuedCode != null) ...[
            const SizedBox(height: 12),
            _CodeChip(code: issuedCode!, expiresAt: issuedExpiresAt!),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.koreanBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: generating ? null : onGenerate,
              icon: generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.qr_code_2),
              label:
                  Text(issuedCode == null ? '코드 발급' : '새 코드 발급', maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBlock extends StatelessWidget {
  const _UserBlock({required this.submitting, required this.onSubmit});

  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.koreanBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.location_on, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현장 체크인 +100P',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '운영자가 알려준 6자리 코드 입력',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.koreanBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('입력'),
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.expiresAt});

  final String code;
  final DateTime expiresAt;

  String _ttlLabel() {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) return '만료됨';
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s 남음';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.koreanBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
          ),
          Text(
            _ttlLabel(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeInputDialog extends StatefulWidget {
  const _CodeInputDialog();

  @override
  State<_CodeInputDialog> createState() => _CodeInputDialogState();
}

class _CodeInputDialogState extends State<_CodeInputDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final v = _controller.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
      setState(() => _error = '6자리 숫자를 입력해주세요.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('체크인 코드 입력'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(
          hintText: '######',
          counterText: '',
          errorText: _error,
        ),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: 8,
        ),
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('확인'),
        ),
      ],
    );
  }
}
