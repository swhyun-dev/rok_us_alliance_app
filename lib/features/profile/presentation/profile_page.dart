// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/presentation/login_page.dart';
import '../../home/presentation/home_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            '로그아웃',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?',
            style: TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
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

  Future<void> _showEditCafeNicknameDialog(
      BuildContext context,
      String currentNickname,
      ) async {
    final controller = TextEditingController(text: currentNickname);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '카페 닉네임 수정',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: '네이버 카페 닉네임',
                      hintText: '카페에서 사용하는 닉네임 입력',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '카페 닉네임은 향후 카페 회원 데이터와 매칭하는 기준값으로 사용됩니다.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                    final nickname = controller.text.trim();
                    if (nickname.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('카페 닉네임을 2자 이상 입력해주세요.'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      isSaving = true;
                    });

                    try {
                      await AuthStore.updateProfile(
                        cafeNickname: nickname,
                        cafeMatched: false,
                      );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('카페 닉네임 저장에 실패했습니다.'),
                          ),
                        );
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setState(() {
                          isSaving = false;
                        });
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카페 닉네임이 수정되었습니다.')),
      );
    }
  }

  Future<void> _showPhoneVerifyDialog(
      BuildContext context,
      String phoneNumber,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '전화번호 인증',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phoneNumber.isNotEmpty
                        ? '현재 등록된 번호\n$phoneNumber'
                        : '등록된 전화번호가 없습니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재는 MVP 단계이므로 문자 인증 대신 더미 인증 완료 처리만 진행합니다.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  onPressed: isSubmitting || phoneNumber.trim().isEmpty
                      ? null
                      : () async {
                    setState(() {
                      isSubmitting = true;
                    });

                    try {
                      await AuthStore.updateProfile(
                        phoneVerified: true,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('전화번호 인증 처리에 실패했습니다.'),
                          ),
                        );
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setState(() {
                          isSubmitting = false;
                        });
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('인증 완료 처리'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전화번호 인증이 완료되었습니다.')),
      );
    }
  }

  Future<void> _showCafeMatchDialog(
      BuildContext context,
      String cafeNickname,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                '카페 매칭',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cafeNickname.isNotEmpty
                        ? '현재 등록된 카페 닉네임\n$cafeNickname'
                        : '등록된 카페 닉네임이 없습니다.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '현재는 MVP 단계이므로 실제 카페 데이터 비교 대신 더미 매칭 완료 처리만 진행합니다.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                  ),
                  onPressed: isSubmitting || cafeNickname.trim().isEmpty
                      ? null
                      : () async {
                    setState(() {
                      isSubmitting = true;
                    });

                    try {
                      await AuthStore.updateProfile(
                        cafeMatched: true,
                      );

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext, true);
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('카페 매칭 처리에 실패했습니다.'),
                          ),
                        );
                      }
                    } finally {
                      if (dialogContext.mounted) {
                        setState(() {
                          isSubmitting = false;
                        });
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('매칭 완료 처리'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카페 매칭이 완료되었습니다.')),
      );
    }
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(
          showIntroPopup: false,
          initialIndex: 0,
        ),
      ),
          (route) => false,
    );
  }

  _MemberGrade _resolveGrade(AuthState state) {
    final user = state.user;
    if (user == null) return _MemberGrade.guest;

    if (user.cafeMatched) {
      return _MemberGrade.regular;
    }

    if (user.cafeNickname.trim().isNotEmpty) {
      return _MemberGrade.associate;
    }

    return _MemberGrade.notJoined;
  }

  int _calculateActivityScore(AuthState state) {
    final user = state.user;
    if (user == null) return 0;

    var score = 20;

    if (user.cafeNickname.trim().isNotEmpty) score += 20;
    if (user.phoneNumber.trim().isNotEmpty) score += 20;
    if (user.phoneVerified) score += 20;
    if (user.cafeMatched) score += 20;

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AuthState>(
      valueListenable: AuthStore.notifier,
      builder: (context, state, _) {
        final user = state.user;
        final grade = _resolveGrade(state);
        final activityScore = _calculateActivityScore(state);

        if (!state.isInitialized) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (user == null) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.navy, AppColors.royalBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '회원 정보',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '로그인이 필요합니다',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '네이버 로그인 후 카페 닉네임을 등록하면\n회원 연동 기반 기능을 사용할 수 있습니다.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '로그인 후 가능한 기능',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _BulletText('행동 공지 참여 이력 확인'),
                      const _BulletText('카페 닉네임 기반 회원 매칭 대비'),
                      const _BulletText('추후 알림 / 인증 / 미션 기능 확장'),
                      const SizedBox(height: 18),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF03C75A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text(
                          '네이버 로그인 하러가기',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.navy, AppColors.royalBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.14),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '내 정보',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user.name.isNotEmpty ? user.name : '이름 미입력',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _GradeBadge(grade: grade),
                            _MiniScoreBadge(score: activityScore),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '네이버 닉네임 / ${user.naverNickname.isNotEmpty ? user.naverNickname : '-'}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '카페 닉네임 / ${user.cafeNickname.isNotEmpty ? user.cafeNickname : '-'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActivityScoreCard(score: activityScore),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _GradeSummaryCard(grade: grade),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _ProfileInfoRow(
                      label: '이름',
                      value: user.name.isNotEmpty ? user.name : '-',
                    ),
                    const SizedBox(height: 12),
                    _ProfileInfoRow(
                      label: '전화번호',
                      value: user.phoneNumber.isNotEmpty ? user.phoneNumber : '-',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: user.phoneVerified
                          ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified_user,
                              color: AppColors.navy,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '전화번호 인증 완료',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      )
                          : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => _showPhoneVerifyDialog(
                          context,
                          user.phoneNumber,
                        ),
                        icon: const Icon(Icons.sms_outlined),
                        label: const Text(
                          '전화번호 인증하기',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileInfoRow(
                      label: '네이버 닉네임',
                      value:
                      user.naverNickname.isNotEmpty ? user.naverNickname : '-',
                    ),
                    const SizedBox(height: 12),
                    _ProfileInfoRow(
                      label: '카페 닉네임',
                      value:
                      user.cafeNickname.isNotEmpty ? user.cafeNickname : '-',
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: user.cafeMatched
                          ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.how_to_reg,
                              color: AppColors.navy,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '카페 매칭 완료',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                              ),
                            ),
                          ],
                        ),
                      )
                          : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.red,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: state.isLoading ||
                            user.cafeNickname.trim().isEmpty
                            ? null
                            : () => _showCafeMatchDialog(
                          context,
                          user.cafeNickname,
                        ),
                        icon: const Icon(Icons.sync_alt_outlined),
                        label: const Text(
                          '카페 매칭하기',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: state.isLoading
                            ? null
                            : () => _showEditCafeNicknameDialog(
                          context,
                          user.cafeNickname,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text(
                          '카페 닉네임 수정',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ProfileInfoRow(
                      label: '회원 식별값',
                      value: user.providerUserId.isNotEmpty
                          ? user.providerUserId
                          : '-',
                      isMonospace: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatusCard(
                    title: '전화번호 인증',
                    value: user.phoneVerified ? '완료' : '대기',
                    icon: user.phoneVerified
                        ? Icons.verified_user
                        : Icons.phone_iphone_outlined,
                    accentColor:
                    user.phoneVerified ? AppColors.navy : AppColors.red,
                    description: user.phoneVerified
                        ? '문자 인증이 완료된 상태입니다.'
                        : '현재는 더미 인증 버튼으로 상태를 변경할 수 있습니다.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(
                    title: '카페 매칭',
                    value: user.cafeMatched ? '완료' : '대기',
                    icon: user.cafeMatched
                        ? Icons.how_to_reg
                        : Icons.sync_problem_outlined,
                    accentColor:
                    user.cafeMatched ? AppColors.navy : AppColors.red,
                    description: user.cafeMatched
                        ? '카페 회원 데이터와 매칭되었습니다.'
                        : '현재는 더미 매칭 버튼으로 상태를 변경할 수 있습니다.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '등급/점수 안내',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _BulletText('미가입 / 카페 닉네임 미등록 상태'),
                    const _BulletText('준회원 / 카페 닉네임 등록 완료, 실제 카페 매칭 대기 상태'),
                    const _BulletText('정회원 / 카페 회원 데이터와 실제 매칭 완료 상태'),
                    const _BulletText(
                      '활동점수는 현재 MVP용 더미 점수이며, 추후 일정 참여/댓글/공유/출석 등으로 확장할 수 있습니다.',
                    ),
                    const _BulletText(
                      '전화번호 인증은 현재 더미 UI이며, 이후 실제 문자 인증으로 교체할 수 있습니다.',
                    ),
                    const _BulletText(
                      '카페 매칭은 현재 더미 UI이며, 이후 실제 카페 데이터 비교로 교체할 수 있습니다.',
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _goToHome(context),
                            child: const Text(
                              '홈으로 이동',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.red,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed:
                            state.isLoading ? null : () => _handleLogout(context),
                            child: state.isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              '로그아웃',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

enum _MemberGrade {
  guest,
  notJoined,
  associate,
  regular,
}

extension on _MemberGrade {
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

  String get description {
    switch (this) {
      case _MemberGrade.guest:
        return '로그인이 필요합니다';
      case _MemberGrade.notJoined:
        return '카페 닉네임 미등록';
      case _MemberGrade.associate:
        return '카페 닉네임 등록 완료';
      case _MemberGrade.regular:
        return '카페 매칭 완료';
    }
  }

  Color get color {
    switch (this) {
      case _MemberGrade.guest:
        return AppColors.textSecondary;
      case _MemberGrade.notJoined:
        return AppColors.red;
      case _MemberGrade.associate:
        return AppColors.royalBlue;
      case _MemberGrade.regular:
        return AppColors.navy;
    }
  }

  IconData get icon {
    switch (this) {
      case _MemberGrade.guest:
        return Icons.person_outline;
      case _MemberGrade.notJoined:
        return Icons.hourglass_empty;
      case _MemberGrade.associate:
        return Icons.emoji_events_outlined;
      case _MemberGrade.regular:
        return Icons.workspace_premium;
    }
  }
}

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});

  final _MemberGrade grade;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(grade.icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            grade.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniScoreBadge extends StatelessWidget {
  const _MiniScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        '활동점수 $score점',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActivityScoreCard extends StatelessWidget {
  const _ActivityScoreCard({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '활동점수',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score점',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.red,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.softBlue,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.red),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '프로필 완성도와 연동 상태를 기준으로 계산한 임시 점수입니다.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeSummaryCard extends StatelessWidget {
  const _GradeSummaryCard({required this.grade});

  final _MemberGrade grade;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원 등급',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 20,
              backgroundColor: grade.color.withValues(alpha: 0.12),
              child: Icon(
                grade.icon,
                color: grade.color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              grade.label,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: grade.color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              grade.description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 88,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SelectableText(
              value,
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
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accentColor,
    required this.description,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}