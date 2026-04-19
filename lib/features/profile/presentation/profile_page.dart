// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_loading_indicator.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';
import '../../membership/data/member_store.dart';
import '../../membership/domain/member.dart';
import '../../membership/presentation/membership_card_modal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('정말 로그아웃하시겠습니까?',
            style: TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.koreanBlue),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;
    await AuthStore.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(showIntroPopup: false, initialIndex: 0),
      ),
      (route) => false,
    );
  }

  _MemberGrade _resolveGrade(AuthState state) {
    final user = state.user;
    if (user == null) return _MemberGrade.guest;
    if (user.cafeMatched) return _MemberGrade.regular;
    if (user.cafeNickname.trim().isNotEmpty) return _MemberGrade.associate;
    return _MemberGrade.notJoined;
  }

  int _calcScore(AuthState state) {
    final user = state.user;
    if (user == null) return 0;
    var s = 20;
    if (user.cafeNickname.trim().isNotEmpty) s += 20;
    if (user.phoneNumber.trim().isNotEmpty) s += 20;
    if (user.phoneVerified) s += 20;
    if (user.cafeMatched) s += 20;
    return s.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthStore.notifier,
      builder: (context, state, _) {
        if (!state.isInitialized) {
          return const Center(child: AllianceLoadingIndicator(size: 56));
        }

        final user = state.user;
        if (user == null) {
          return _GuestView(onGoLogin: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          });
        }

        final grade = _resolveGrade(state);
        final score = _calcScore(state);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // Profile hero card
            _ProfileHeroCard(user: user, grade: grade, score: score),
            const SizedBox(height: 14),
            // 한미동맹단증 카드
            _MembershipCardBanner(onTap: () => showMembershipCardModal(context)),
            const SizedBox(height: 14),
            // Stats row
            Row(children: [
              Expanded(child: _StatTile(label: '참여 일정', value: '12', icon: Icons.event_available_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: '작성 글', value: '8', icon: Icons.edit_note_outlined)),
              const SizedBox(width: 10),
              Expanded(child: _StatTile(label: '댓글', value: '21', icon: Icons.chat_bubble_outline)),
            ]),
            const SizedBox(height: 20),
            // Activity score bar
            _ActivityScoreCard(score: score),
            const SizedBox(height: 20),
            // Info section
            _SectionHeader(title: '내 정보', icon: Icons.person_outline),
            const SizedBox(height: 10),
            _InfoCard(children: [
              _ProfileInfoRow(label: '이름', value: user.name),
              const _RowDivider(),
              _ProfileInfoRow(label: '전화번호', value: user.phoneNumber),
              const _RowDivider(),
              _ProfileInfoRow(label: '카페 닉네임', value: user.cafeNickname),
              const _RowDivider(),
              _ProfileInfoRow(
                  label: '식별값', value: user.providerUserId, isMonospace: true),
            ]),
            const SizedBox(height: 20),
            // Certification
            _SectionHeader(title: '인증 현황', icon: Icons.verified_user_outlined),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: _CertCard(
                  title: '전화번호 인증',
                  isDone: user.phoneVerified,
                  doneIcon: Icons.verified_user,
                  pendingIcon: Icons.phone_iphone_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CertCard(
                  title: '카페 회원 매칭',
                  isDone: user.cafeMatched,
                  doneIcon: Icons.how_to_reg,
                  pendingIcon: Icons.sync_problem_outlined,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            // Settings
            _SectionHeader(title: '설정 및 메뉴', icon: Icons.settings_outlined),
            const SizedBox(height: 10),
            _MenuCard(
              items: [
                _MenuItem(Icons.person_outline, '회원정보 수정', subtitle: '이름 · 닉네임 · 전화번호'),
                _MenuItem(Icons.notifications_outlined, '알림 설정', subtitle: '공지 · 커뮤니티 알림'),
                _MenuItem(Icons.shield_outlined, '보안 설정', subtitle: '로그인 · 인증 관리'),
                _MenuItem(Icons.help_outline, '고객센터 · FAQ', subtitle: '문의 및 도움말'),
                _MenuItem(Icons.home_outlined, '홈으로 이동'),
                _MenuItem(Icons.logout, '로그아웃', isDestructive: true),
              ],
              onTap: (title) {
                if (title == '홈으로 이동') _goToHome(context);
                if (title == '로그아웃') _handleLogout(context);
              },
            ),
          ],
        );
      },
    );
  }
}

// ─── Guest view ───────────────────────────────────────────────────────────────

class _GuestView extends StatelessWidget {
  const _GuestView({required this.onGoLogin});
  final VoidCallback onGoLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.darkNavy, AppColors.koreanBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: AppColors.flagAccentGradient,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '로그인이 필요합니다',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '네이버 로그인 후 카페 닉네임을 등록하면\n회원 연동 기반 기능을 모두 사용할 수 있습니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF03C75A),
            ),
            onPressed: onGoLogin,
            child: const Text('네이버 로그인 하러가기'),
          ),
        ),
      ],
    );
  }
}

// ─── Profile hero card ────────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.grade,
    required this.score,
  });
  final dynamic user;
  final _MemberGrade grade;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.koreanBlue.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.shieldGradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isNotEmpty ? user.name : '이름 미입력',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      user.naverNickname.isNotEmpty
                          ? '@${user.naverNickname}'
                          : '네이버 닉네임 없음',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _GradeBadge(label: grade.label, grade: grade),
                        _GradeBadge(label: '활동 $score점'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Flag stripe divider
          Container(
            height: 3,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: AppColors.flagAccentGradient,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.label, this.grade});
  final String label;
  final _MemberGrade? grade;

  Color get _color {
    if (grade == _MemberGrade.regular) return AppColors.gold;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Activity score card ──────────────────────────────────────────────────────

class _ActivityScoreCard extends StatelessWidget {
  const _ActivityScoreCard({required this.score});
  final int score;

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
                '활동 점수',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$score / 100',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 10,
              backgroundColor: AppColors.softBlue,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.koreanBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _scoreMessage(score),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _scoreMessage(int score) {
    if (score >= 100) return '🎖 모든 인증을 완료한 완전 회원입니다.';
    if (score >= 80) return '전화번호 또는 카페 매칭 인증 완료 시 정회원으로 승급됩니다.';
    if (score >= 60) return '카페 닉네임 등록 후 추가 인증을 완료해보세요.';
    return '로그인 후 기본 정보를 입력하면 점수가 올라갑니다.';
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.koreanBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.koreanBlue,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.shieldGradient,
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: AppColors.koreanBlue),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ─── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.isMonospace = false,
  });
  final String label;
  final String value;
  final bool isMonospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.koreanBlue,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SelectableText(
                value.isNotEmpty ? value : '-',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.border);
  }
}

// ─── Cert card ────────────────────────────────────────────────────────────────

class _CertCard extends StatelessWidget {
  const _CertCard({
    required this.title,
    required this.isDone,
    required this.doneIcon,
    required this.pendingIcon,
  });
  final String title;
  final bool isDone;
  final IconData doneIcon;
  final IconData pendingIcon;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? AppColors.koreanBlue : AppColors.koreanRed;
    final bgColor = isDone ? AppColors.softBlue : AppColors.softRed;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(isDone ? doneIcon : pendingIcon,
                color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isDone ? '완료' : '미완료',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Menu card ────────────────────────────────────────────────────────────────

class _MenuItem {
  const _MenuItem(this.icon, this.title,
      {this.subtitle, this.isDestructive = false});
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.onTap});
  final List<_MenuItem> items;
  final void Function(String title) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          final color = item.isDestructive ? AppColors.koreanRed : AppColors.textPrimary;
          final iconColor = item.isDestructive ? AppColors.koreanRed : AppColors.koreanBlue;
          final iconBg = item.isDestructive ? AppColors.softRed : AppColors.softBlue;

          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: iconColor, size: 18),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                subtitle: item.subtitle != null
                    ? Text(
                        item.subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 18,
                ),
                onTap: () => onTap(item.title),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 16, endIndent: 16,
                    color: AppColors.border),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Membership card banner ───────────────────────────────────────────────────

class _MembershipCardBanner extends StatelessWidget {
  const _MembershipCardBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Member?>(
      valueListenable: MemberStore.notifier,
      builder: (context, member, _) {
        final hasCard = member != null && member.grade.canIssueCard;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkNavy, Color(0xFF0D1E50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.darkNavy.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.shieldGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25), width: 1),
                  ),
                  child: const Icon(Icons.badge_outlined,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '한미동맹단증',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasCard
                            ? '${member.grade.label} · ${member.points}P · QR 코드 포함'
                            : member != null
                                ? '운영자 승인 후 발급됩니다'
                                : '회원 정보를 불러오는 중…',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Row(
                  children: [
                    Text('🇰🇷', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 4),
                    Text('🇺🇸', style: TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.white54, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Member grade ─────────────────────────────────────────────────────────────

enum _MemberGrade { guest, notJoined, associate, regular }

extension _MemberGradeExt on _MemberGrade {
  String get label {
    switch (this) {
      case _MemberGrade.guest:
        return '비회원';
      case _MemberGrade.notJoined:
        return '미가입';
      case _MemberGrade.associate:
        return '준회원';
      case _MemberGrade.regular:
        return '정회원';
    }
  }
}
