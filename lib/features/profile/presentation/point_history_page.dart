// lib/features/profile/presentation/point_history_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../data/point_log_store.dart';
import '../domain/point_log.dart';

class PointHistoryPage extends StatefulWidget {
  const PointHistoryPage({super.key});

  @override
  State<PointHistoryPage> createState() => _PointHistoryPageState();
}

class _PointHistoryPageState extends State<PointHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final List<PointLog> _logs = [];
  DocumentSnapshot? _cursor;
  bool _loading = false;
  bool _hasMore = true;
  Object? _error;

  String? get _uid => AuthStore.firebaseUid;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    final uid = _uid;
    if (uid == null) return;

    setState(() => _loading = true);
    try {
      final page = await PointLogStore.fetchPage(uid, cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _logs.addAll(page.logs);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('활동 점수 이력')),
      body: ValueListenableBuilder<AuthState>(
        valueListenable: AuthStore.notifier,
        builder: (context, state, _) {
          final user = state.user;
          if (user == null) {
            return const Center(child: Text('로그인이 필요합니다.'));
          }
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _SummaryCard(user: user)),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '이력을 불러오지 못했습니다.\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.koreanRed),
                    ),
                  ),
                )
              else if (_logs.isEmpty && !_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        '아직 적립 이력이 없습니다.\n글을 쓰거나 청원에 서명해보세요.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              SliverList.separated(
                itemCount: _logs.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) =>
                    _LogTile(log: _logs[index]),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lv ${user.level}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${user.points} P',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${user.nickname}님의 누적 활동 점수',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});
  final PointLog log;

  IconData get _icon {
    switch (log.type) {
      case 'welcome':
        return Icons.emoji_events_outlined;
      case 'daily_check_in':
        return Icons.calendar_today_outlined;
      case 'post_create':
        return Icons.edit_outlined;
      case 'comment_create':
        return Icons.chat_bubble_outline;
      case 'like_received':
        return Icons.favorite_outline;
      case 'share':
        return Icons.ios_share_outlined;
      case 'petition_sign':
        return Icons.how_to_vote_outlined;
      case 'event_check_in':
        return Icons.location_on_outlined;
      case 'referral_complete':
        return Icons.person_add_outlined;
      case 'admin_adjust':
        return Icons.tune_outlined;
      case 'consecutive_bonus':
        return Icons.local_fire_department_outlined;
      default:
        return Icons.adjust;
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor =
        log.isPositive ? AppColors.koreanBlue : AppColors.koreanRed;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: AppColors.koreanBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  log.timeLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            log.amountLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
