import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../features/membership/domain/member.dart';
import '../theme/colors.dart';

/// 디지털 한미동맹단증 (Membership Card)
///
/// 브랜드 키트 디자인 — 모달과 풀화면 페이지 양쪽에서 공유한다.
///
/// QR 카운트다운, "QR 참여 인증" 스캐너, 카드 공유 같은 외부 기능은 호출 측에서
/// 카드 외부에 배치한다. 카드 자체는 시각 표현만 담당.
///
/// 사용 예:
/// ```dart
/// MembershipCard(
///   memberName: member.name,
///   memberNumber: member.memberNumber,
///   branch: member.branch,
///   joinDate: member.joinedAt,
///   grade: member.grade,
///   points: member.points,
///   canIssueCard: member.grade.canIssueCard,
///   qrToken: token,                        // null = 로딩 또는 락
///   qrOverlay: QrCountdownPill(qrToken: token),
///   aspectFixed: true,                     // 풀화면 600:380 / 모달 false
///   onTapQr: () => openFullscreen(),       // null이면 expand 힌트 숨김
/// )
/// ```
class MembershipCard extends StatelessWidget {
  final String memberName;
  final String memberNumber;
  final String branch;
  final DateTime joinDate;
  final MemberGrade grade;
  final int points;

  /// `MemberGrade.general`처럼 카드 발급이 안 되는 등급을 구분.
  /// false 면 QR 자리에 lock 아이콘이 표시된다.
  final bool canIssueCard;

  /// 발급된 QR 토큰. null·canIssueCard 조합:
  ///   - canIssueCard=true,  qrToken=null  → 로딩 (스피너)
  ///   - canIssueCard=true,  qrToken="..." → QR 표시
  ///   - canIssueCard=false                → lock 아이콘 (qrToken 무시)
  final String? qrToken;

  /// QR 우상단에 겹쳐 표시되는 작은 위젯 (카운트다운 pill 등).
  /// canIssueCard && qrToken 이 모두 정상일 때만 그려진다.
  final Widget? qrOverlay;

  /// true: AspectRatio 600/380 으로 고정 (스크린샷 일관성)
  /// false: 콘텐츠 기반 가변 높이
  final bool aspectFixed;

  final VoidCallback? onTapQr;

  const MembershipCard({
    super.key,
    required this.memberName,
    required this.memberNumber,
    required this.branch,
    required this.joinDate,
    required this.grade,
    required this.points,
    required this.canIssueCard,
    this.qrToken,
    this.qrOverlay,
    this.aspectFixed = false,
    this.onTapQr,
  });

  @override
  Widget build(BuildContext context) {
    final gradeColor = gradeColorOf(grade);

    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bgCard, AppColors.bgPrimary],
        ),
        border: Border.all(color: gradeColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: gradeColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 워터마크 별
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.04,
                child: Icon(Icons.star, size: 180, color: gradeColor),
              ),
            ),
            // 본문
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                mainAxisSize:
                    aspectFixed ? MainAxisSize.max : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(gradeColor),
                  const SizedBox(height: 12),
                  Container(
                    height: 0.5,
                    color: gradeColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 14),
                  _buildMemberInfo(),
                  if (aspectFixed)
                    const Spacer()
                  else
                    const SizedBox(height: 18),
                  _buildBottomRow(gradeColor),
                ],
              ),
            ),
            // 플래그 스트라이프
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 4,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: AppColors.flagStripeGradient),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (aspectFixed) {
      return AspectRatio(aspectRatio: 600 / 380, child: card);
    }
    return card;
  }

  Widget _buildHeader(Color gradeColor) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ROK · US ALLIANCE',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 18,
                  letterSpacing: 2.5,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '한 미 동 맹 단',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: gradeColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            grade.label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEMBER NAME',
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 2,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          memberName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: 4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'No. $memberNumber',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            letterSpacing: 0.5,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$branch  ·  가입일 ${_formatDate(joinDate)}',
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(Color gradeColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildQrSlot(),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ACTIVITY POINTS',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 2,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatPoints(points),
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 38,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: gradeColor,
                height: 1,
              ),
            ),
            Text(
              'POINTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: gradeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQrSlot() {
    final hasToken = qrToken != null && qrToken!.isNotEmpty;
    final showQr = canIssueCard && hasToken;
    final showLock = !canIssueCard;

    Widget content;
    if (showQr) {
      content = QrImageView(
        data: qrToken!,
        version: QrVersions.auto,
        size: 80,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      );
    } else if (showLock) {
      content = const Icon(Icons.lock_outline, color: Colors.black54, size: 28);
    } else {
      content = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return GestureDetector(
      onTap: onTapQr,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            alignment: Alignment.center,
            children: [
              content,
              if (showQr && qrOverlay != null)
                Positioned(top: 0, right: 0, child: qrOverlay!),
              if (showQr && onTapQr != null)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: Icon(
                    Icons.open_in_full,
                    size: 10,
                    color: Color(0x99000000),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    return '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
  }

  static String _formatPoints(int p) {
    return p.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
