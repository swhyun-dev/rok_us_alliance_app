// lib/features/calendar/presentation/calendar_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../action_board/data/action_event_store.dart';
import '../../action_board/domain/action_event.dart';
import '../../action_board/presentation/action_notice_detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<ActionEvent> _eventsForDate(List<ActionEvent> events, DateTime date) {
    return events.where((e) => e.isSameDay(date)).toList();
  }

  void _onDateTap(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _moveMonth(int diff) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + diff, 1);
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month + diff, 1);
    });
  }

  void _moveToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  String _monthLabel() {
    return '${_currentMonth.year}년 ${_currentMonth.month}월';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActionEvent>>(
      valueListenable: ActionEventStore.notifier,
      builder: (context, events, _) {
        final selectedEvents = _eventsForDate(events, _selectedDate);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _CalendarHeroCard(),
            const SizedBox(height: 16),
            _MonthHeader(
              label: _monthLabel(),
              onPrev: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
              onToday: _moveToToday,
            ),
            const SizedBox(height: 12),
            _MiniCalendarGrid(
              currentMonth: _currentMonth,
              selectedDate: _selectedDate,
              events: events,
              onDateTap: _onDateTap,
            ),
            const SizedBox(height: 16),
            ...selectedEvents.map(
                  (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CalendarEventCard(event: event),
              ),
            ),
            if (selectedEvents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    '선택한 날짜에는 등록된 일정이 없습니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CalendarHeroCard extends StatelessWidget {
  const _CalendarHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.heroGradient,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '한눈에 보는 일정',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '집회 / 모임 / 중요 행동 일정들을 달력과 리스트로 함께 확인합니다.',
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.label,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
        const SizedBox(width: 4),
        OutlinedButton(
          onPressed: onToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
          ),
          child: const Text('오늘'),
        ),
      ],
    );
  }
}

class _MiniCalendarGrid extends StatelessWidget {
  const _MiniCalendarGrid({
    required this.currentMonth,
    required this.selectedDate,
    required this.events,
    required this.onDateTap,
  });

  final DateTime currentMonth;
  final DateTime selectedDate;
  final List<ActionEvent> events;
  final ValueChanged<DateTime> onDateTap;

  @override
  Widget build(BuildContext context) {
    const days = ['일', '월', '화', '수', '목', '금', '토'];
    final firstDay = DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = lastDay.day;

    final cells = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) {
      cells.add(null);
    }
    for (int day = 1; day <= totalDays; day++) {
      cells.add(DateTime(currentMonth.year, currentMonth.month, day));
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                for (final d in days)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          d,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cells.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final date = cells[index];
                if (date == null) {
                  return const SizedBox.shrink();
                }

                final isSelected = selectedDate.year == date.year &&
                    selectedDate.month == date.month &&
                    selectedDate.day == date.day;
                final hasEvent = events.any((e) => e.isSameDay(date));
                final eventCount = events.where((e) => e.isSameDay(date)).length;

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onDateTap(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.red
                          : hasEvent
                          ? AppColors.softBlue
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.red : AppColors.border,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : hasEvent
                                  ? AppColors.navy
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (hasEvent && !isSelected)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$eventCount',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});

  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.type == '모임' ? AppColors.navy : AppColors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id),
          ),
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.monthLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                    Text(
                      event.dayLabel,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: color,
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
                    Container(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        event.type,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${event.dateTimeText} / ${event.locationName}',
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
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
      ),
    );
  }
}