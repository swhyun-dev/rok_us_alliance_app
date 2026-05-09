// lib/features/membership/presentation/membership_card_page.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_loading_indicator.dart';
import '../../../widgets/membership_card.dart';
import '../data/member_store.dart';
import '../data/qr_service.dart';
import '../domain/member.dart';
import 'qr_fullscreen_page.dart';
import 'widgets/qr_countdown_pill.dart';

class MembershipCardPage extends StatefulWidget {
  const MembershipCardPage({super.key});

  @override
  State<MembershipCardPage> createState() => _MembershipCardPageState();
}

class _MembershipCardPageState extends State<MembershipCardPage> {
  String? _qrToken;
  Timer? _refreshTimer;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _sharing = false;

  Future<void> _shareCard(Member member) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _screenshotController.capture();
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카드 캡처에 실패했습니다.')),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/membership_${member.uid}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: '${member.name} 한미동맹단증',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('공유 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

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
                Screenshot(
                  controller: _screenshotController,
                  child: MembershipCard(
                    memberName: member.name,
                    memberNumber: member.memberNumber,
                    branch: member.branch,
                    joinDate: member.joinedAt,
                    grade: member.grade,
                    points: member.points,
                    canIssueCard: member.grade.canIssueCard,
                    qrToken: _qrToken,
                    qrOverlay: (member.grade.canIssueCard && _qrToken != null)
                        ? QrCountdownPill(qrToken: _qrToken!)
                        : null,
                    aspectFixed: true,
                    onTapQr: _qrToken != null
                        ? () => _openQrFullscreen(member, _qrToken!)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                if (member.grade.canIssueCard)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _sharing ? null : () => _shareCard(member),
                      icon: _sharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share),
                      label: Text(_sharing ? '준비 중...' : '카드 공유하기'),
                    ),
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
