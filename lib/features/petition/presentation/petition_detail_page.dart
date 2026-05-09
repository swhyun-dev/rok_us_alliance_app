// lib/features/petition/presentation/petition_detail_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../data/petition_store.dart';
import '../domain/petition.dart';
import 'widgets/progress_bar.dart';

/// 외부 큐레이션 모델 — 자체 서명 없음.
/// 카드의 메인 CTA 는 [petition.externalUrl] 외부 이동.
class PetitionDetailPage extends StatelessWidget {
  const PetitionDetailPage({super.key, required this.petitionId});

  final String petitionId;

  Future<void> _openExternal(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    if (url.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('외부 링크가 등록되지 않았습니다.')),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('잘못된 URL 형식입니다.')),
      );
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('브라우저를 열 수 없습니다.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('이동 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상세',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<Petition?>(
        stream: PetitionStore.watchById(petitionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('불러오기 실패: ${snapshot.error}'));
          }
          final petition = snapshot.data;
          if (petition == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeroCard(petition: petition),
              const SizedBox(height: 18),
              if (petition.isLegislativeBill &&
                  petition.progressStatus.isNotEmpty) ...[
                const _SectionTitle('현재 진행 현황'),
                const SizedBox(height: 10),
                _ProgressCard(petition: petition),
                const SizedBox(height: 18),
              ],
              const _SectionTitle('내용'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  petition.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.65,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ExternalActionButton(
                petition: petition,
                onPressed: () =>
                    _openExternal(context, petition.externalUrl),
              ),
              if (petition.sourceUrl.isNotEmpty) ...[
                const SizedBox(height: 10),
                _SourceLink(
                  url: petition.sourceUrl,
                  onTap: () => _openExternal(context, petition.sourceUrl),
                ),
              ],
              const SizedBox(height: 16),
              const _DisclaimerNote(),
            ],
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.petition});
  final Petition petition;

  static const Map<String, String> _categoryLabel = {
    'security': '안보',
    'economy': '경제',
    'education': '교육',
    'media': '언론',
    'judicial': '사법',
    'other': '기타',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _categoryLabel[petition.category] ?? petition.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.koreanBlue,
                  ),
                ),
              ),
              if (petition.stance != PetitionStance.neutral) ...[
                const SizedBox(width: 6),
                _StanceBadge(stance: petition.stance),
              ],
              const Spacer(),
              Text(
                petition.ddayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.koreanRed,
                ),
              ),
            ],
          ),
          if (petition.referenceNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                petition.isLegislativeBill
                    ? '의안번호 ${petition.referenceNumber}'
                    : '청원번호 ${petition.referenceNumber}',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            petition.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          if (petition.hasProgressBar) ...[
            const SizedBox(height: 16),
            PetitionProgressBar(percent: petition.progressPercent),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${petition.currentCount}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  ' / ${petition.targetCount} 명',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StanceBadge extends StatelessWidget {
  const _StanceBadge({required this.stance});
  final PetitionStance stance;

  Color get _color {
    switch (stance) {
      case PetitionStance.support:
        return AppColors.koreanBlue;
      case PetitionStance.oppose:
        return AppColors.koreanRed;
      case PetitionStance.neutral:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (stance) {
      case PetitionStance.support:
        return '지지 법안';
      case PetitionStance.oppose:
        return '주목 법안';
      case PetitionStance.neutral:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.45)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _color,
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.petition});
  final Petition petition;

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}.$m.$day';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, color: AppColors.koreanBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  petition.progressStatus,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.koreanBlue,
                  ),
                ),
                if (petition.progressUpdatedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${_formatDate(petition.progressUpdatedAt!)} 갱신',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
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

class _ExternalActionButton extends StatelessWidget {
  const _ExternalActionButton({
    required this.petition,
    required this.onPressed,
  });

  final Petition petition;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled =
        !petition.isActive || petition.externalUrl.trim().isEmpty;
    return SizedBox(
      height: 56,
      child: FilledButton.icon(
        onPressed: disabled ? null : onPressed,
        icon: const Icon(Icons.open_in_new),
        label: Text(
          disabled
              ? (petition.isActive ? '외부 링크 없음' : '종료됨')
              : petition.ctaLabel,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.koreanRed,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.url, required this.onTap});
  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.link, size: 14),
        label: Text(
          '큐레이터 출처: $url',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _DisclaimerNote extends StatelessWidget {
  const _DisclaimerNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 16, color: AppColors.textSecondary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '이 글은 외부 사이트의 청원·법안을 큐레이션해 안내합니다. '
              '실제 서명·의견 등록은 외부 공식 사이트에서 이뤄지며, '
              '본 앱은 진행 상황 갱신을 위해 노력하나 최신 상태가 다를 수 있습니다.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
