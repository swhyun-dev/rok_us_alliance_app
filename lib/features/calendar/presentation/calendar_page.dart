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
  DateTime _currentMonth =
      DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<ActionEvent> _eventsForDate(
      List<ActionEvent> events, DateTime date) {
    return events.where((e) => e.isSameDay(date)).toList();
  }

  void _onDateTap(DateTime date) => setState(() => _selectedDate = date);

  void _moveMonth(int diff) {
    setState(() {
      _currentMonth =
          DateTime(_currentMonth.year, _currentMonth.month + diff, 1);
      _selectedDate =
          DateTime(_currentMonth.year, _currentMonth.month + diff, 1);
    });
  }

  void _moveToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActionEvent>>(
      valueListenable: ActionEventStore.notifier,
      builder: (context, events, _) {
        final selectedEvents = _eventsForDate(events, _selectedDate);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const _CalendarHeroCard(),
            const SizedBox(height: 16),
            _MonthHeader(
              currentMonth: _currentMonth,
              onPrev: () => _moveMonth(-1),
              onNext: () => _moveMonth(1),
              onToday: _moveToToday,
            ),
            const SizedBox(height: 12),
            _CalendarGrid(
              currentMonth: _currentMonth,
              selectedDate: _selectedDate,
              events: events,
              onDateTap: _onDateTap,
            ),
            const SizedBox(height: 16),
            // Selected date header
            _SelectedDateHeader(
              date: _selectedDate,
              count: selectedEvents.length,
            ),
            const SizedBox(height: 10),
            if (selectedEvents.isEmpty)
              _EmptyDateCard(date: _selectedDate)
            else
              ...selectedEvents.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CalendarEventCard(event: e),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _CalendarHeroCard extends StatelessWidget {
  const _CalendarHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.darkNavy, AppColors.koreanBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.koreanBlue.withValues(alpha: 0.26),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -16,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CALENDAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '한눈에 보는 일정',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '집회 · 모임 · 중요 행동 일정들을\n달력과 리스트로 함께 확인합니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Month header ─────────────────────────────────────────────────────────────

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.currentMonth,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });
  final DateTime currentMonth;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left,
                color: AppColors.koreanBlue),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
        Expanded(
          child: Text(
            '${currentMonth.year}년 ${currentMonth.month}월',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right,
                color: AppColors.koreanBlue),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onToday,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.koreanBlue,
            side: BorderSide(
                color: AppColors.koreanBlue.withValues(alpha: 0.4)),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('오늘',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      ],
    );
  }
}

// ─── Calendar grid ────────────────────────────────────────────────────────────

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
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
    final firstDay =
        DateTime(currentMonth.year, currentMonth.month, 1);
    final lastDay =
        DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final startWeekday = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final now = DateTime.now();
    final today =
        DateTime(now.year, now.month, now.day);

    final cells = <DateTime?>[];
    for (int i = 0; i < startWeekday; i++) cells.add(null);
    for (int d = 1; d <= totalDays; d++) {
      cells.add(DateTime(currentMonth.year, currentMonth.month, d));
    }
    while (cells.length % 7 != 0) cells.add(null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day header
          Row(
            children: days.map((d) {
              final isSun = d == '일';
              final isSat = d == '토';
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSun
                          ? AppColors.koreanRed
                          : isSat
                              ? AppColors.koreanBlue
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final date = cells[index];
              if (date == null) return const SizedBox.shrink();

              final isSelected = selectedDate.year == date.year &&
                  selectedDate.month == date.month &&
                  selectedDate.day == date.day;
              final isToday = today == date;
              final hasEvent = events.any((e) => e.isSameDay(date));
              final eventCount =
                  events.where((e) => e.isSameDay(date)).length;
              final isSunday = date.weekday == 7;
              final isSaturday = date.weekday == 6;

              Color textColor = AppColors.textPrimary;
              if (isSelected) textColor = Colors.white;
              else if (isSunday) textColor = AppColors.koreanRed;
              else if (isSaturday) textColor = AppColors.koreanBlue;

              return InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onDateTap(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.koreanBlue
                        : isToday
                            ? AppColors.softBlue
                            : hasEvent
                                ? AppColors.softRed.withValues(alpha: 0.5)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: AppColors.koreanBlue.withValues(
                                alpha: 0.40),
                            width: 1.5)
                        : null,
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (hasEvent && !isSelected)
                        Positioned(
                          right: 3,
                          top: 3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: AppColors.koreanRed,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 1),
                            ),
                            child: eventCount > 1
                                ? null
                                : null,
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
    );
  }
}

// ─── Selected date header ─────────────────────────────────────────────────────

class _SelectedDateHeader extends StatelessWidget {
  const _SelectedDateHeader({required this.date, required this.count});
  final DateTime date;
  final int count;

  @override
  Widget build(BuildContext context) {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdays[date.weekday - 1];

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: AppColors.shieldGradient,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${date.month}월 ${date.day}일 ($weekday)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.koreanRed,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Empty date card ──────────────────────────────────────────────────────────

class _EmptyDateCard extends StatelessWidget {
  const _EmptyDateCard({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.softBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_available_outlined,
                color: AppColors.koreanBlue, size: 18),
          ),
          const SizedBox(width: 12),
          const Text(
            '선택한 날짜에 등록된 일정이 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Event card ───────────────────────────────────────────────────────────────

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.event});
  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    final isProtest = event.type != '모임';
    final color =
        isProtest ? AppColors.koreanRed : AppColors.koreanBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 68,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: color.withValues(alpha: 0.20)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          event.monthLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        Text(
                          event.dayLabel,
                          style: TextStyle(
                            fontSize: 26,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            event.type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${event.dateTimeText} · ${event.locationName}',
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: AppColors.textSecondary
                          .withValues(alpha: 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
