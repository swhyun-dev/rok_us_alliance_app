// lib/features/membership/presentation/membership_card_modal.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart' as light;
import '../../../theme/colors.dart' as brand;
import '../../../widgets/membership_card.dart';
import '../data/member_store.dart';
import '../data/qr_service.dart';
import '../domain/member.dart';
import 'qr_scan_page.dart';
import 'widgets/qr_countdown_pill.dart';

Future<void> showMembershipCardModal(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '신분증',
    barrierColor: Colors.black87,
    transitionDuration: const Duration(milliseconds: 320),
    transitionBuilder: (ctx, anim, _, child) {
      final curved =
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, _, __) => const _MembershipCardModalPage(),
  );
}

class _MembershipCardModalPage extends StatefulWidget {
  const _MembershipCardModalPage();

  @override
  State<_MembershipCardModalPage> createState() =>
      _MembershipCardModalPageState();
}

class _MembershipCardModalPageState extends State<_MembershipCardModalPage> {
  String? _qrToken;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _generateQr(); // ignore: discarded_futures
  }

  Future<void> _generateQr() async {
    final member = MemberStore.current;
    if (member == null || !member.grade.canIssueCard) return;
    try {
      final token = QrService.generate(member);
      if (mounted) setState(() => _qrToken = token);
    } catch (_) {
      // 오프라인: 24h 캐시 폴백
      final cached = await QrService.cachedToken();
      if (mounted && cached != null) setState(() => _qrToken = cached);
    }
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 270), _generateQr);
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<Member?>(
          valueListenable: MemberStore.notifier,
          builder: (context, member, _) {
            return _IDCard(
              member: member,
              qrToken: _qrToken,
              onClose: () => Navigator.of(context).pop(),
            );
          },
        ),
      ),
    );
  }
}

// ─── ID 카드 모달 본체 ────────────────────────────────────────────────────────

class _IDCard extends StatelessWidget {
  const _IDCard({
    required this.member,
    required this.qrToken,
    required this.onClose,
  });

  final Member? member;
  final String? qrToken;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final cardWidth = (size.width * 0.88).clamp(0.0, 380.0);

    return SizedBox(
      width: cardWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (member == null)
            const _MemberLoadFailedCard()
          else ...[
            MembershipCard(
              memberName: member!.name,
              memberNumber: member!.memberNumber,
              branch: member!.branch,
              joinDate: member!.joinedAt,
              grade: member!.grade,
              points: member!.points,
              canIssueCard: member!.grade.canIssueCard,
              qrToken: qrToken,
              qrOverlay: (member!.grade.canIssueCard && qrToken != null)
                  ? QrCountdownPill(qrToken: qrToken!)
                  : null,
              aspectFixed: false,
            ),
            if (!member!.grade.canIssueCard) ...[
              const SizedBox(height: 14),
              const _PendingApprovalBanner(),
            ],
          ],
          const SizedBox(height: 20),
          _BottomActions(onClose: onClose),
        ],
      ),
    );
  }
}

// ─── 외부 보조 위젯 ───────────────────────────────────────────────────────────

class _MemberLoadFailedCard extends StatelessWidget {
  const _MemberLoadFailedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: brand.AppColors.bgCard,
        border: Border.all(color: brand.AppColors.border),
      ),
      child: const Text(
        '회원 정보를 불러올 수 없습니다.',
        textAlign: TextAlign.center,
        style: TextStyle(color: brand.AppColors.textMuted),
      ),
    );
  }
}

class _PendingApprovalBanner extends StatelessWidget {
  const _PendingApprovalBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: brand.AppColors.bgUrgent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: brand.AppColors.accentRed.withValues(alpha: 0.35),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline,
              color: brand.AppColors.accentRed, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '운영자 승인 후 QR 코드가 발급됩니다.',
              style: TextStyle(
                fontSize: 12,
                color: brand.AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Builder(builder: (ctx) {
          return GestureDetector(
            onTap: () => Navigator.of(ctx).push(
              MaterialPageRoute(builder: (_) => const QrScanPage()),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: light.AppColors.shieldGradient,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'QR 참여 인증',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onClose,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: const Icon(Icons.close_rounded,
                color: Colors.white, size: 22),
          ),
        ),
      ],
    );
  }
}
