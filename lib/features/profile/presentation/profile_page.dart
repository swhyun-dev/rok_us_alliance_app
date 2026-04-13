// lib/features/profile/presentation/profile_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../action_board/data/action_event_store.dart';
import '../../action_board/domain/action_event.dart';
import '../../action_board/presentation/action_notice_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Set<String> _joinedEventIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJoinedEvents();
  }

  Future<void> _loadJoinedEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final events = ActionEventStore.notifier.value;

    final joinedIds = <String>{};
    for (final event in events) {
      final joined = prefs.getBool('joined_event_${event.id}') ?? false;
      if (joined) {
        joinedIds.add(event.id);
      }
    }

    if (!mounted) return;
    setState(() {
      _joinedEventIds = joinedIds;
      _isLoading = false;
    });
  }

  List<ActionEvent> _joinedEvents(List<ActionEvent> events) {
    final joined = events.where((e) => _joinedEventIds.contains(e.id)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return joined;
  }

  int _pastJoinedCount(List<ActionEvent> events) {
    final now = DateTime.now();
    return events.where((e) => e.startAt.isBefore(now)).length;
  }

  int _upcomingJoinedCount(List<ActionEvent> events) {
    final now = DateTime.now();
    return events.where((e) => !e.startAt.isBefore(now)).length;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActionEvent>>(
      valueListenable: ActionEventStore.notifier,
      builder: (context, events, _) {
        final joinedEvents = _joinedEvents(events);
        final upcomingCount = _upcomingJoinedCount(joinedEvents);
        final pastCount = _pastJoinedCount(joinedEvents);

        return RefreshIndicator(
          onRefresh: _loadJoinedEvents,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ProfileHeroCard(
                joinedCount: joinedEvents.length,
                upcomingCount: upcomingCount,
                pastCount: pastCount,
              ),
              const SizedBox(height: 16),
              _ActivityScoreCard(
                joinedCount: joinedEvents.length,
                upcomingCount: upcomingCount,
              ),
              const SizedBox(height: 16),
              _JoinedEventsCard(
                isLoading: _isLoading,
                events: joinedEvents,
                onTapEvent: (event) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActionNoticeDetailPage(eventId: event.id),
                    ),
                  );
                  _loadJoinedEvents();
                },
              ),
              const SizedBox(height: 16),
              const _ProfileGuideCard(),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.joinedCount,
    required this.upcomingCount,
    required this.pastCount,
  });

  final int joinedCount;
  final int upcomingCount;
  final int pastCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.red, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alliance Member',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '참여 일정 $joinedCount건 / 예정 $upcomingCount건 / 지난 일정 $pastCount건',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    '참여하기 버튼으로 저장한 일정이 이곳에 표시됩니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityScoreCard extends StatelessWidget {
  const _ActivityScoreCard({
    required this.joinedCount,
    required this.upcomingCount,
  });

  final int joinedCount;
  final int upcomingCount;

  int get _score => (joinedCount * 100) + (upcomingCount * 40);

  String get _level {
    if (_score >= 1000) return 'Patriots Lv.5';
    if (_score >= 700) return 'Patriots Lv.4';
    if (_score >= 400) return 'Patriots Lv.3';
    if (_score >= 200) return 'Patriots Lv.2';
    return 'Patriots Lv.1';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '내 활동 점수',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$_score PTS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '현재 등급 / $_level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '참여 일정과 예정 일정 기준으로 점수를 표시합니다.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinedEventsCard extends StatelessWidget {
  const _JoinedEventsCard({
    required this.isLoading,
    required this.events,
    required this.onTapEvent,
  });

  final bool isLoading;
  final List<ActionEvent> events;
  final ValueChanged<ActionEvent> onTapEvent;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '참여한 일정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '아래 목록은 참여하기 버튼을 누른 일정입니다.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  '아직 참여한 일정이 없습니다.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              )
            else
              ...events.map(
                    (event) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _JoinedEventRow(
                    event: event,
                    onTap: () => onTapEvent(event),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JoinedEventRow extends StatelessWidget {
  const _JoinedEventRow({
    required this.event,
    required this.onTap,
  });

  final ActionEvent event;
  final VoidCallback onTap;

  Color get _accent => event.type == '모임' ? AppColors.navy : AppColors.red;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.monthLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                  Text(
                    event.dayLabel,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.dateTimeText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.locationName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ProfileGuideCard extends StatelessWidget {
  const _ProfileGuideCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: const [
          _MenuItem(
            icon: Icons.how_to_reg,
            title: '참여 상태 저장',
            subtitle: '행동 공지 상세에서 참여하기 버튼을 누르면 저장됩니다.',
          ),
          Divider(height: 1),
          _MenuItem(
            icon: Icons.refresh,
            title: '목록 새로고침',
            subtitle: '이 화면을 아래로 당기면 참여 목록을 다시 불러옵니다.',
          ),
          Divider(height: 1),
          _MenuItem(
            icon: Icons.info_outline,
            title: '안내',
            subtitle: '현재 참여 상태는 기기 로컬에 저장됩니다.',
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: AppColors.softBlue,
        child: Icon(icon, color: AppColors.navy),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}