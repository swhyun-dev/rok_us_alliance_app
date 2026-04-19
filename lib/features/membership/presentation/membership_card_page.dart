// lib/features/membership/presentation/membership_card_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_loading_indicator.dart';
import '../data/member_store.dart';
import '../data/qr_service.dart';
import '../domain/member.dart';
import 'qr_fullscreen_page.dart';

class MembershipCardPage extends StatefulWidget {
  const MembershipCardPage({super.key});

  @override
  State<MembershipCardPage> createState() => _MembershipCardPageState();
}

class _MembershipCardPageState extends State<MembershipCardPage> {
  String? _qrToken;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initMember();
  }

  Future<void> _initMember() async {
    await MemberStore.initialize();
    // 개발용: 회원 데이터 없으면 목업 로드
    if (MemberStore.current == null) {
      await MemberStore.loadMock();
    }
    _generateQr();
  }

  void _generateQr() {
    final member = MemberStore.current;
    if (member == null || !member.grade.canIssueCard) return;

    setState(() {
      _qrToken = QrService.generate(member);
    });

    // 4분 30초마다 자동 갱신 (5분 만료 전에 미리 갱신)
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(seconds: 270), _generateQr);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _openQrFullscreen(Member member, String token) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrFullscreenPage(
          member: member,
          qrToken: token,
          remainingSeconds: QrService.remainingSeconds(token),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        ValueListenableBuilder<Member?>(
          valueListenable: MemberStore.notifier,
          builder: (context, member, _) {
            if (member == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: AllianceLoadingIndicator(size: 56),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MembershipCard(
                  member: member,
                  qrToken: _qrToken,
                  onQrTap: _qrToken != null
                      ? () => _openQrFullscreen(member, _qrToken!)
                      : null,
                ),
                const SizedBox(height: 20),
                _StatsRow(member: member),
                const SizedBox(height: 20),
                _PointsCard(member: member),
                const SizedBox(height: 20),
                _GradeInfoCard(member: member),
                if (!member.grade.canIssueCard) ...[
                  const SizedBox(height: 16),
                  _PendingVerifyCard(),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── 멤버십 카드 ───────────────────────────────────────────────────────────────

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({
    required this.member,
    required this.qrToken,
    this.onQrTap,
  });

  final Member member;
  final String? qrToken;
  final VoidCallback? onQrTap;

  Color get _gradeColor {
    switch (member.grade) {
      case MemberGrade.gold:
        return AppColors.gold;
      case MemberGrade.vip:
        return const Color(0xFF7F77DD);
      case MemberGrade.honorary:
        return AppColors.gold;
      default:
        return AppColors.koreanBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, Color(0xFF0D1E50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 헤더
          Row(
            children: [
              const Text(
                '🇰🇷',
                style: TextStyle(fontSize: 22),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: AppColors.shieldGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                '🇺🇸',
                style: TextStyle(fontSize: 22),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: _gradeColor.withValues(alpha: 0.50)),
                ),
                child: Text(
                  member.grade.label.toUpperCase(),
                  style: TextStyle(
                    color: _gradeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 이름 + QR
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      member.branch,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '가입일 ${member.joinedDateLabel}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // QR 코드 박스
              GestureDetector(
                onTap: onQrTap,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: member.grade.canIssueCard && qrToken != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: QrImageView(
                                data: qrToken!,
                                version: QrVersions.auto,
                                size: 88,
                                padding: const EdgeInsets.all(6),
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
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.koreanBlue
                                      .withValues(alpha: 0.85),
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(14)),
                                ),
                                child: const Center(
                                  child: Text(
                                    '크게 보기',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Icon(Icons.lock_outline,
                              color: AppColors.textSecondary, size: 28),
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 플래그 스트라이프
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: AppColors.flagAccentGradient,
            ),
          ),
          const SizedBox(height: 14),

          // 회원번호 + 점수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                member.memberNumber,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      color: AppColors.gold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${member.points}P',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 통계 행 ──────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.event_available_outlined,
            label: '참여 행사',
            value: '0',
            color: AppColors.koreanBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.stars_rounded,
            label: '활동 점수',
            value: '${member.points}P',
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events_outlined,
            label: '등급',
            value: member.grade.label,
            color: AppColors.koreanRed,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 포인트 카드 ──────────────────────────────────────────────────────────────

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    final isMax = member.grade == MemberGrade.vip ||
        member.grade == MemberGrade.honorary;
    final nextGrade = member.grade == MemberGrade.regular
        ? MemberGrade.gold
        : member.grade == MemberGrade.gold
            ? MemberGrade.vip
            : null;
    final targetPoints = member.grade == MemberGrade.regular ? 2000 : 5000;
    final progress = isMax
        ? 1.0
        : (member.points / targetPoints).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.shieldGradient,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '활동 점수',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${member.points}P',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(
                isMax ? AppColors.gold : AppColors.koreanBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isMax
                ? '최고 등급입니다. 감사합니다!'
                : nextGrade != null
                    ? '${nextGrade.label} 달성까지 ${member.pointsToNextGrade}P 남았습니다.'
                    : '',
            style: TextStyle(
              fontSize: 12,
              color: isMax ? AppColors.gold : AppColors.textSecondary,
              fontWeight: isMax ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 등급 안내 ────────────────────────────────────────────────────────────────

class _GradeInfoCard extends StatelessWidget {
  const _GradeInfoCard({required this.member});
  final Member member;

  static const _grades = [
    (MemberGrade.regular, '정회원', '한미동맹단증 발급 · QR 생성 · 행사 참여', 0),
    (MemberGrade.gold, 'Gold', '사은품 우선 수령 · Gold 전용 배지', 2000),
    (MemberGrade.vip, 'VIP', '굿즈 우선 · VIP 라운지 입장', 5000),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.shieldGradient,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '등급 안내',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._grades.map((g) {
            final isCurrent = member.grade == g.$1;
            final isAchieved = member.points >= g.$4;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.koreanBlue.withValues(alpha: 0.10)
                          : AppColors.softBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isAchieved
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      color: isCurrent
                          ? AppColors.koreanBlue
                          : isAchieved
                              ? AppColors.koreanBlue
                              : AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              g.$2,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: isCurrent
                                    ? AppColors.koreanBlue
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (g.$4 > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '${g.$4}P~',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.koreanBlue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '현재',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          g.$3,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── 인증 대기 카드 ───────────────────────────────────────────────────────────

class _PendingVerifyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.softRed,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.koreanRed.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.koreanRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.pending_outlined,
                color: AppColors.koreanRed, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정회원 인증 필요',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.koreanRed,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '운영자 승인 후 한미동맹단증이 발급됩니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
