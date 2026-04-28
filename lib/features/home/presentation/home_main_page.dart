// lib/features/home/presentation/home_main_page.dart
import 'package:flutter/material.dart';

import '../../../shared/widgets/daily_check_in_button.dart';
import 'widgets/breaking_alert_card.dart';
import 'widgets/hero_stats_section.dart';
import 'widgets/hot_petition_section.dart';
import 'widgets/live_feed_preview.dart';
import 'widgets/quick_action_grid.dart';
import 'widgets/upcoming_event_card.dart';

/// 5탭 중앙 홈 — v3 6 섹션 구성.
class HomeMainPage extends StatelessWidget {
  const HomeMainPage({
    super.key,
    required this.onMoveToFeed,
    required this.onMoveToCalendar,
    required this.onMoveToPetition,
  });

  final VoidCallback onMoveToFeed;
  final VoidCallback onMoveToCalendar;
  final VoidCallback onMoveToPetition;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
      children: [
        const HeroStatsSection(),
        const SizedBox(height: 14),
        const DailyCheckInButton(),
        const SizedBox(height: 14),
        QuickActionGrid(
          onActionFeed: onMoveToFeed,
          onCalendar: onMoveToCalendar,
          onPetition: onMoveToPetition,
        ),
        const SizedBox(height: 14),
        const BreakingAlertCard(),
        const SizedBox(height: 14),
        LiveFeedPreview(onMore: onMoveToFeed),
        const SizedBox(height: 14),
        HotPetitionSection(onMore: onMoveToPetition),
        const SizedBox(height: 14),
        const UpcomingEventCard(),
      ],
    );
  }
}
