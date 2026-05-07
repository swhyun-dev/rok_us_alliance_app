// lib/shared/widgets/daily_check_in_button.dart
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../features/auth/data/auth_store.dart';
import '../../features/profile/data/daily_check_in_store.dart';
import 'app_toast.dart';

/// 홈에 노출되는 일일 체크인 카드 버튼.
/// 오늘 체크인 여부를 1회 조회 후 상태에 따라 활성/비활성 표시.
class DailyCheckInButton extends StatefulWidget {
  const DailyCheckInButton({super.key});

  @override
  State<DailyCheckInButton> createState() => _DailyCheckInButtonState();
}

class _DailyCheckInButtonState extends State<DailyCheckInButton> {
  bool _checking = false;
  bool _busy = false;
  bool _alreadyChecked = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final uid = AuthStore.firebaseUid;
    if (uid == null) return;
    setState(() => _checking = true);
    try {
      final done = await DailyCheckInStore.hasCheckedInToday(uid);
      if (!mounted) return;
      setState(() => _alreadyChecked = done);
    } catch (_) {
      // 무시 — 버튼은 활성으로 두고 시도 시 CF가 정확한 상태 반환.
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _run() async {
    if (_busy || _alreadyChecked) return;
    setState(() => _busy = true);
    try {
      final result = await DailyCheckInStore.run();
      if (!mounted) return;
      setState(() => _alreadyChecked = true);
      final msg = result.isFresh
          ? (result.bonusAwarded > 0
              ? '+${result.total}P 연속 ${result.consecutiveDays}일 보너스!'
              : '+${result.pointsAwarded}P 출석 적립')
          : '오늘 이미 체크인했습니다.';
      AppToast.show(context, message: msg);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: '체크인 실패: $e',
        backgroundColor: AppColors.red,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _busy || _alreadyChecked || _checking;
    final color = _alreadyChecked ? AppColors.softBlue : AppColors.koreanBlue;
    final fg = _alreadyChecked ? AppColors.koreanBlue : Colors.white;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color,
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: disabled ? null : _run,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                _alreadyChecked
                    ? Icons.check_circle
                    : Icons.calendar_today_outlined,
                color: fg,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alreadyChecked ? '오늘 출석 완료' : '출석 체크 +10P',
                      style: TextStyle(
                        color: fg,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _alreadyChecked
                          ? '내일 다시 만나요'
                          : '하루 한 번 +10P · 연속 3·7일 보너스',
                      style: TextStyle(
                        color: fg.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_busy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.chevron_right, color: fg, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
