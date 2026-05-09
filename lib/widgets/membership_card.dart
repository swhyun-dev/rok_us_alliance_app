import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/colors.dart';

/// 회원 등급 (CLAUDE.md Section 5-3 기준)
enum MemberGrade {
  general('일반회원', 'GENERAL', AppColors.textMuted),
  regular('정회원', 'REGULAR', AppColors.accentRed),
  gold('골드', 'GOLD', AppColors.gradeGold),
  vip('VIP', 'VIP', AppColors.gradeVip),
  honorary('명예회원', 'HONORARY', AppColors.accentRed);

  final String labelKr;
  final String labelEn;
  final Color color;
  const MemberGrade(this.labelKr, this.labelEn, this.color);
}

/// 디지털 한미동맹단증 (Membership Card)
///
/// 사용:
/// ```dart
/// MembershipCard(
///   memberName: '홍길동',
///   memberNumber: 'ROK-2024-00847',
///   branch: '서울지부',
///   joinDate: DateTime(2024, 1, 15),
///   grade: MemberGrade.regular,
///   points: 1240,
///   qrToken: jwtToken, // CLAUDE.md Section 5-1의 QR JWT
/// )
/// ```
class MembershipCard extends StatelessWidget {
  final String memberName;
  final String memberNumber;
  final String branch;
  final DateTime joinDate;
  final MemberGrade grade;
  final int points;
  final String qrToken;
  final VoidCallback? onTapQr;

  const MembershipCard({
    super.key,
    required this.memberName,
    required this.memberNumber,
    required this.branch,
    required this.joinDate,
    required this.grade,
    required this.points,
    required this.qrToken,
    this.onTapQr,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 600 / 380,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: grade.color, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgCard, AppColors.bgPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: grade.color.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // 배경 워터마크
              Positioned(
                right: -30,
                top: -30,
                child: Opacity(
                  opacity: 0.04,
                  child: Icon(Icons.star, size: 180, color: grade.color),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 12),
                    Container(
                      height: 0.5,
                      color: grade.color.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    _buildMemberInfo(),
                    const Spacer(),
                    _buildBottomRow(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            color: grade.color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            grade.labelEn,
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
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 5,
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

  Widget _buildBottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // QR 코드
        GestureDetector(
          onTap: onTapQr,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: QrImageView(
              data: qrToken,
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
            ),
          ),
        ),

        const Spacer(),

        // 활동 점수
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
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
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: grade.color,
                height: 1,
              ),
            ),
            Text(
              'POINTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
                color: grade.color,
              ),
            ),
          ],
        ),
      ],
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
