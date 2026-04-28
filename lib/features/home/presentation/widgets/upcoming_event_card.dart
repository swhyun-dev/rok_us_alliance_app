// lib/features/home/presentation/widgets/upcoming_event_card.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../action_board/data/action_event_store.dart';
import '../../../action_board/domain/action_event.dart';
import '../../../action_board/presentation/action_notice_detail_page.dart';

class UpcomingEventCard extends StatelessWidget {
  const UpcomingEventCard({super.key});

  static String _ddayLabel(DateTime startAt) {
    final diff = startAt.difference(DateTime.now()).inDays;
    if (diff == 0) return 'D-DAY';
    if (diff < 0) return '종료';
    return 'D-$diff';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActionEvent>>(
      stream: ActionEventStore.watchUpcoming(limit: 1),
      builder: (context, snapshot) {
        final list = snapshot.data ?? const <ActionEvent>[];
        if (list.isEmpty) return const SizedBox.shrink();
        final event = list.first;
        final dday = _ddayLabel(event.startAt);
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActionNoticeDetailPage(eventId: event.id),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.darkNavy, AppColors.koreanBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dday,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.startAt.month}/${event.startAt.day}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '다음 행사',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.locationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
