// lib/features/settings/presentation/security_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';

/// 보안 설정 — 연결된 소셜 계정·마지막 로그인·기기 토큰 등을 보여주는 정보 페이지.
/// 1차 출시에서는 read-only. 2차에서 디바이스 관리·세션 강제 종료 추가 예정.
class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  String _providerLabel(String provider) {
    switch (provider) {
      case 'apple':
        return 'Apple';
      case 'google':
        return 'Google';
      case 'kakao':
        return '카카오';
      case 'naver':
        return '네이버';
      default:
        return provider;
    }
  }

  IconData _providerIcon(String provider) {
    switch (provider) {
      case 'apple':
        return Icons.apple;
      case 'google':
        return Icons.g_mobiledata;
      case 'kakao':
      case 'naver':
        return Icons.chat_bubble;
      default:
        return Icons.account_circle_outlined;
    }
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '기록 없음';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.year}.$m.$day $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text(
          '보안 설정',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: AuthStore.notifier,
        builder: (context, state, _) {
          final user = state.user;
          if (user == null) {
            return const Center(child: Text('로그인 정보가 없습니다.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _SectionHeader('연결된 계정'),
              const SizedBox(height: 8),
              _Card(
                children: [
                  _Row(
                    icon: _providerIcon(user.provider),
                    label: '로그인 방식',
                    value: _providerLabel(user.provider),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.email_outlined,
                    label: '이메일',
                    value: user.email ?? '비공개',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader('세션 정보'),
              const SizedBox(height: 8),
              _Card(
                children: [
                  _Row(
                    icon: Icons.login,
                    label: '마지막 로그인',
                    value: _formatDate(user.lastSignedInAt),
                  ),
                  const _Divider(),
                  _Row(
                    icon: Icons.fingerprint,
                    label: '식별값',
                    value: user.providerUserId,
                    monospace: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionHeader('안전 안내'),
              const SizedBox(height: 8),
              _Card(
                children: [
                  _BulletText(
                    '한미동맹단은 비밀번호를 직접 보관하지 않습니다. 모든 로그인은 위에 표시된 소셜 계정 인증을 통해 이뤄집니다.',
                  ),
                  SizedBox(height: 10),
                  _BulletText(
                    '의심스러운 활동이 발견되면 즉시 로그아웃 후 해당 소셜 계정의 보안 설정에서 비밀번호 변경 및 2단계 인증을 활성화해주세요.',
                  ),
                  SizedBox(height: 10),
                  _BulletText(
                    '계정 탈퇴는 마이페이지 하단 "계정 탈퇴" 메뉴에서 진행할 수 있으며, 탈퇴 시 회원 정보는 즉시 삭제되고 복구되지 않습니다.',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: monospace ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 0, color: AppColors.border);
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
