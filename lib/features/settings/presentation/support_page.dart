// lib/features/settings/presentation/support_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';

/// 고객센터 · FAQ — 자주 묻는 질문 + 문의처(이메일).
/// 이메일 주소는 OWNER_SETUP.md 와 약관 페이지에 기재된 값과 일치시킬 것.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  static const String _supportEmail = 'rokusallianceapp@gmail.com';

  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: '활동 점수는 어떻게 적립되나요?',
      answer:
          '게시글 작성(+30P), 댓글 작성(+5P), 좋아요 받음(+2P), 청원 서명(+50P), 행사 체크인(+100P), 일일 출석(+10P) 등 활동에 따라 자동 적립됩니다. 일일 한도가 있으며 자세한 내용은 마이페이지 > 등급 안내에서 확인할 수 있습니다.',
    ),
    _FaqItem(
      question: '등급은 언제 올라가나요?',
      answer:
          '누적 점수가 일정 수준에 도달하면 즉시 자동 승급됩니다. (Lv2 시민 100P, Lv3 활동가 500P, Lv4 핵심 2,000P, Lv5 동지 5,000P)',
    ),
    _FaqItem(
      question: '청원에 서명하려면 어떻게 하나요?',
      answer:
          '청원 탭 또는 홈에서 청원을 선택한 뒤 서명하기 버튼을 누르면 즉시 서명이 반영되고 +50P가 적립됩니다. 한 청원에는 한 번만 서명할 수 있습니다.',
    ),
    _FaqItem(
      question: '행사 체크인 코드는 어디서 받나요?',
      answer:
          '행사 현장에서 운영자가 발급하는 6자리 숫자 코드를 행사 상세 페이지의 "체크인 코드 입력"에 입력하시면 됩니다. 코드는 발급 후 약 10분 동안 유효합니다.',
    ),
    _FaqItem(
      question: '닉네임을 바꾸고 싶어요.',
      answer:
          '마이페이지 > 회원정보 수정에서 닉네임을 변경할 수 있습니다. 다른 회원이 사용 중인 닉네임은 사용할 수 없습니다.',
    ),
    _FaqItem(
      question: '신고한 게시글은 어떻게 처리되나요?',
      answer:
          '동일 게시글에 대한 신고가 5건 이상 누적되면 자동으로 비공개 처리되며, 운영진이 추후 검토합니다. 명백한 욕설·혐오·허위정보는 즉시 신고해주세요.',
    ),
    _FaqItem(
      question: '계정을 탈퇴하면 어떻게 되나요?',
      answer:
          '회원 정보·작성 글·서명 이력이 즉시 삭제되며 복구되지 않습니다. 동일 소셜 계정으로 다시 가입할 수는 있으나, 이전 점수·등급은 복구되지 않습니다.',
    ),
  ];

  Future<void> _sendEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {
        'subject': '[한미동맹단 앱] 문의',
      },
    );
    final messenger = ScaffoldMessenger.of(context);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('메일 앱을 열 수 없습니다. 이메일을 복사해 사용해주세요.')),
      );
    }
  }

  Future<void> _copyEmail(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _supportEmail));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의 이메일이 복사되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: const Text(
          '고객센터 · FAQ',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _ContactCard(
            email: _supportEmail,
            onSend: () => _sendEmail(context),
            onCopy: () => _copyEmail(context),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '자주 묻는 질문',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _faqs.length; i++) ...[
                  _FaqTile(item: _faqs[i]),
                  if (i < _faqs.length - 1)
                    const Divider(height: 0, color: AppColors.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});
  final String question;
  final String answer;
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.item});
  final _FaqItem item;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.4,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              item.answer,
              style: const TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.email,
    required this.onSend,
    required this.onCopy,
  });
  final String email;
  final VoidCallback onSend;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '직접 문의하기',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '이용 중 문제가 있거나 개선 의견이 있으시면 아래 이메일로 보내주세요.\n영업일 기준 1~3일 내에 답변드립니다.',
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.78),
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.mail_outline,
                    color: AppColors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    email,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '이메일 복사',
                  icon: const Icon(Icons.copy,
                      color: AppColors.white, size: 18),
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('메일 보내기'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.koreanBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
