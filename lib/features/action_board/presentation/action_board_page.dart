// lib/features/action_board/presentation/action_board_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../auth/presentation/admin_login_page.dart';
import '../../membership/presentation/admin_scanner_page.dart';
import '../data/action_event_store.dart';
import '../domain/action_event.dart';
import 'action_event_form_page.dart';
import 'action_notice_detail_page.dart';

enum ActionFilter { all, protest, meetup, important }

class ActionBoardPage extends StatefulWidget {
  const ActionBoardPage({super.key});

  @override
  State<ActionBoardPage> createState() => _ActionBoardPageState();
}

class _ActionBoardPageState extends State<ActionBoardPage> {
  ActionFilter _filter = ActionFilter.all;

  List<ActionEvent> _applyFilter(List<ActionEvent> events) {
    switch (_filter) {
      case ActionFilter.protest:
        return events.where((e) => e.type == '집회').toList();
      case ActionFilter.meetup:
        return events.where((e) => e.type == '모임').toList();
      case ActionFilter.important:
        return events.where((e) => e.type == '중요 일정').toList();
      case ActionFilter.all:
        return events;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<ActionEvent>>(
        valueListenable: ActionEventStore.notifier,
        builder: (context, events, _) {
          final filtered = _applyFilter(events);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
            itemCount: filtered.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BoardHeroCard(),
                    const SizedBox(height: 16),
                    _FilterBar(
                      current: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }
              return _ActionNoticeCard(event: filtered[index - 1]);
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<AdminAuthState>(
        valueListenable: AdminAuthStore.notifier,
        builder: (context, authState, _) {
          if (authState.user == null) {
            return FloatingActionButton.extended(
              backgroundColor: AppColors.koreanRed,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminLoginPage()),
              ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('관리자 로그인',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            );
          }
          if (authState.isChecking) {
            return FloatingActionButton.extended(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.koreanBlue,
              onPressed: null,
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('권한 확인 중'),
            );
          }
          if (!authState.isAdmin) {
            return FloatingActionButton.extended(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.koreanRed,
              onPressed: () async {
                await AdminAuthStore.signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('관리자 권한이 없는 계정입니다.')),
                );
              },
              icon: const Icon(Icons.block),
              label: const Text('관리자 아님'),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'logout-fab',
                backgroundColor: Colors.white,
                foregroundColor: AppColors.koreanBlue,
                onPressed: () async {
                  await AdminAuthStore.signOut();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('관리자 로그아웃 완료')),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'scan-fab',
                backgroundColor: AppColors.koreanRed,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScannerPage()),
                ),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('QR 스캔',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 10),
              FloatingActionButton.extended(
                heroTag: 'add-fab',
                backgroundColor: AppColors.koreanBlue,
                foregroundColor: Colors.white,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ActionEventFormPage()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('공지 등록',
                    style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _BoardHeroCard extends StatelessWidget {
  const _BoardHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.koreanRed, Color(0xFF7A1320)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.koreanRed.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            top: -14,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ACTION BOARD',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                '행동 공지 게시판',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '집회 · 오프라인 모임 · 중요 행동 일정을\n이 게시판에서 관리합니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
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

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.current, required this.onChanged});
  final ActionFilter current;
  final ValueChanged<ActionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (ActionFilter.all, '전체'),
      (ActionFilter.protest, '집회'),
      (ActionFilter.meetup, '모임'),
      (ActionFilter.important, '중요 일정'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final isSelected = current == entry.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onChanged(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.koreanBlue : Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.koreanBlue
                        : AppColors.border,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color:
                                AppColors.koreanBlue.withValues(alpha: 0.22),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  entry.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Action notice card ───────────────────────────────────────────────────────

class _ActionNoticeCard extends StatelessWidget {
  const _ActionNoticeCard({required this.event});
  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    final isProtest = event.type != '모임';
    final accentColor =
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20)),
                color: accentColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          event.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.softBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          event.type,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.koreanBlue,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right,
                          color: AppColors.textSecondary
                              .withValues(alpha: 0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    icon: Icons.schedule_outlined,
                    label: '일시',
                    value: event.dateTimeText,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: '위치',
                    value: event.locationName,
                  ),
                  if (event.slogans.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: event.slogans.take(3).map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: accentColor.withValues(alpha: 0.20)),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    event.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ActionNoticeDetailPage(eventId: event.id)),
                      ),
                      style: FilledButton.styleFrom(
                          backgroundColor: accentColor),
                      child: const Text('상세 보기'),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.koreanBlue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
