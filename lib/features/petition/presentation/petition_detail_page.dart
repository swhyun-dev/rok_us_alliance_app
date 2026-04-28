// lib/features/petition/presentation/petition_detail_page.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../../auth/domain/app_user.dart';
import '../data/petition_store.dart';
import '../domain/petition.dart';
import 'widgets/progress_bar.dart';

class PetitionDetailPage extends StatefulWidget {
  const PetitionDetailPage({super.key, required this.petitionId});

  final String petitionId;

  @override
  State<PetitionDetailPage> createState() => _PetitionDetailPageState();
}

class _PetitionDetailPageState extends State<PetitionDetailPage> {
  bool _signing = false;
  bool _localSigned = false;
  int? _localCountOverride;

  Future<void> _checkSignedOnce(String uid) async {
    if (_localSigned) return;
    final signed = await PetitionStore.hasSigned(
      petitionId: widget.petitionId,
      uid: uid,
    );
    if (!mounted || !signed) return;
    setState(() => _localSigned = true);
  }

  Future<void> _sign(Petition petition) async {
    if (_signing || _localSigned) return;
    final user = AuthStore.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    // Optimistic UI: 즉시 반영.
    setState(() {
      _signing = true;
      _localSigned = true;
      _localCountOverride = petition.currentCount + 1;
    });

    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('signPetition');
      final result = await callable.call<Map<String, dynamic>>({
        'petitionId': petition.id,
      });
      final pointsAwarded = (result.data['pointsAwarded'] ?? 50) as int;
      final milestone = result.data['milestoneReached'] as int?;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(milestone != null
              ? '+${pointsAwarded}P 적립! 청원이 $milestone% 에 도달했습니다.'
              : '+${pointsAwarded}P 적립! 서명 완료'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // 롤백.
      setState(() {
        _localSigned = false;
        _localCountOverride = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('서명 실패: $e')),
      );
    } finally {
      if (mounted) setState(() => _signing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthStore.currentUser;
    if (user != null) {
      _checkSignedOnce(user.providerUserId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('청원 상세',
            style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: StreamBuilder<Petition?>(
        stream: PetitionStore.watchById(widget.petitionId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('불러오기 실패: ${snapshot.error}'));
          }
          final petition = snapshot.data;
          if (petition == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final displayCount =
              _localCountOverride ?? petition.currentCount;
          final percent = petition.targetCount > 0
              ? ((displayCount / petition.targetCount) * 100)
                  .clamp(0, 100)
                  .toInt()
              : 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _HeroCard(
                petition: petition,
                displayCount: displayCount,
                percent: percent,
              ),
              const SizedBox(height: 18),
              _SectionTitle('청원 내용'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
              _buildSignButton(petition, user),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSignButton(Petition petition, AppUser? user) {
    final disabled = !petition.isActive;
    final loggedIn = user != null;

    if (!loggedIn) {
      return _BigButton(
        label: '로그인 후 서명',
        color: AppColors.border,
        textColor: AppColors.textSecondary,
        onPressed: null,
      );
    }
    if (disabled) {
      return _BigButton(
        label: '종료된 청원',
        color: AppColors.border,
        textColor: AppColors.textSecondary,
        onPressed: null,
      );
    }
    if (_localSigned) {
      return _BigButton(
        label: '서명 완료 ✓',
        color: AppColors.koreanBlue,
        textColor: Colors.white,
        onPressed: null,
      );
    }
    return _BigButton(
      label: _signing ? '처리 중...' : '서명하기 (+50P)',
      color: AppColors.koreanRed,
      textColor: Colors.white,
      onPressed: _signing ? null : () => _sign(petition),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.petition,
    required this.displayCount,
    required this.percent,
  });
  final Petition petition;
  final int displayCount;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  petition.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.koreanBlue,
                  ),
                ),
              ),
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
          const SizedBox(height: 16),
          PetitionProgressBar(percent: percent),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$displayCount',
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

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color,
          disabledForegroundColor: textColor.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
