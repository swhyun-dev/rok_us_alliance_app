// lib/features/reports/presentation/report_dialog.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../data/report_store.dart';
import '../domain/report_reason.dart';

/// 사유 선택 + 추가 설명을 입력받아 신고를 등록한다.
/// 호출 측은 await showReportDialog(...) 후 결과 SnackBar 표시.
Future<bool> showReportDialog(
  BuildContext context, {
  required ReportTargetType targetType,
  required String targetId,
  Map<String, dynamic>? targetSnapshot,
}) async {
  final user = AuthStore.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('로그인이 필요합니다.')),
    );
    return false;
  }

  // 중복 신고 사전 점검
  final already = await ReportStore.hasReported(
    reporterId: AuthStore.firebaseUid ?? user.providerUserId,
    targetType: targetType,
    targetId: targetId,
  );
  if (!context.mounted) return false;
  if (already) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미 신고한 항목입니다.')),
    );
    return false;
  }

  final result = await showModalBottomSheet<_ReportFormResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: const _ReportForm(),
    ),
  );
  if (result == null) return false;
  if (!context.mounted) return false;

  try {
    await ReportStore.create(
      reporterId: AuthStore.firebaseUid ?? user.providerUserId,
      reporterNickname: user.nickname,
      targetType: targetType,
      targetId: targetId,
      reason: result.reason,
      description: result.description,
      targetSnapshot: targetSnapshot,
    );
    if (!context.mounted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고가 접수되었습니다. 검토 후 조치합니다.')),
    );
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('신고 접수 실패: $e')),
    );
    return false;
  }
}

class _ReportFormResult {
  const _ReportFormResult({required this.reason, this.description});
  final ReportReason reason;
  final String? description;
}

class _ReportForm extends StatefulWidget {
  const _ReportForm();

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  ReportReason? _selected;
  final TextEditingController _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '신고 사유 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '동일 대상에 신고가 누적되면 자동 숨김 처리됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            RadioGroup<ReportReason>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                children: ReportReason.values
                    .map(
                      (r) => RadioListTile<ReportReason>(
                        title: Text(r.label),
                        value: r,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: '상세 설명 (선택)',
                hintText: '맥락이나 위치 등을 자유롭게 적어주세요.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.koreanRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(
                          context,
                          _ReportFormResult(
                            reason: _selected!,
                            description: _description.text,
                          ),
                        ),
                child: const Text(
                  '신고 접수',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
