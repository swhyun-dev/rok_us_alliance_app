// lib/features/membership/presentation/membership_card_modal.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../data/member_store.dart';
import '../data/qr_service.dart';
import '../domain/member.dart';
import 'qr_scan_page.dart';

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

// ─── ID 카드 본체 ─────────────────────────────────────────────────────────────

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
          // ── 카드 본체
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 헤더 — 다크 그라디언트 + 국기
                _CardHeader(),
                // 회원 정보
                _CardBody(member: member, qrToken: qrToken),
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

          const SizedBox(height: 20),

          // 하단 버튼 행
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // QR 참여 인증 버튼
              Builder(builder: (ctx) {
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute(builder: (_) => const QrScanPage()),
                  ),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.shieldGradient,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner,
                              color: Colors.white, size: 18),
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
              // 닫기 버튼
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
                        width: 1.5),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D1E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // 로고
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.shieldGradient,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '한미동맹단증',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'ROK-US Alliance Member ID',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Text('🇰🇷', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          const Text('🇺🇸', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.member, required this.qrToken});
  final Member? member;
  final String? qrToken;

  @override
  Widget build(BuildContext context) {
    if (member == null) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Text(
            '회원 정보를 불러올 수 없습니다.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final m = member!;
    final canIssue = m.grade.canIssueCard;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 + 기본 정보
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 사진 자리
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  gradient: AppColors.shieldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 36),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        m.grade.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoLine(label: '소속', value: m.branch),
                    const SizedBox(height: 5),
                    _InfoLine(label: '등급', value: m.grade.label),
                    const SizedBox(height: 5),
                    _InfoLine(label: '점수', value: '${m.points}P'),
                    const SizedBox(height: 5),
                    _InfoLine(label: '가입일', value: m.joinedDateLabel),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 회원번호 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.badge_outlined,
                    size: 14, color: AppColors.koreanBlue),
                const SizedBox(width: 8),
                Text(
                  m.memberNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.koreanBlue,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // QR 코드 영역
          if (canIssue && qrToken != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.qr_code_2_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      const Text(
                        'QR 인증 코드',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      _QrCountdownBadge(qrToken: qrToken!),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: QrImageView(
                      data: qrToken!,
                      version: QrVersions.auto,
                      size: 180,
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
                  const SizedBox(height: 8),
                  const Text(
                    '행사 현장에서 이 QR을 스캔해 참여를 확인합니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!canIssue) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softRed,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.koreanRed.withValues(alpha: 0.20)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline,
                      color: AppColors.koreanRed, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '운영자 승인 후 QR 코드가 발급됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.koreanRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 36,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── QR 카운트다운 뱃지 ───────────────────────────────────────────────────────

class _QrCountdownBadge extends StatefulWidget {
  const _QrCountdownBadge({required this.qrToken});
  final String qrToken;

  @override
  State<_QrCountdownBadge> createState() => _QrCountdownBadgeState();
}

class _QrCountdownBadgeState extends State<_QrCountdownBadge> {
  late int _seconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _seconds = QrService.remainingSeconds(widget.qrToken);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds = (_seconds - 1).clamp(0, 300));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLow = _seconds <= 60;
    final mm = _seconds ~/ 60;
    final ss = (_seconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLow
            ? AppColors.koreanRed.withValues(alpha: 0.10)
            : AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: isLow ? AppColors.koreanRed : AppColors.koreanBlue,
          ),
          const SizedBox(width: 4),
          Text(
            '$mm:$ss',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isLow ? AppColors.koreanRed : AppColors.koreanBlue,
            ),
          ),
        ],
      ),
    );
  }
}
