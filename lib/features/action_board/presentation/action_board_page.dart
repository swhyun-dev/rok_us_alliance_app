// lib/features/action_board/presentation/action_board_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../auth/presentation/admin_login_page.dart';
import '../data/action_event_store.dart';
import '../domain/action_event.dart';
import 'action_event_form_page.dart';
import 'action_notice_detail_page.dart';

enum ActionFilter {
  all,
  protest,
  meetup,
  important,
}

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
      default:
        return events;
    }
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip('전체', ActionFilter.all),
            const SizedBox(width: 8),
            _filterChip('집회', ActionFilter.protest),
            const SizedBox(width: 8),
            _filterChip('모임', ActionFilter.meetup),
            const SizedBox(width: 8),
            _filterChip('중요 일정', ActionFilter.important),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, ActionFilter filter) {
    final isSelected = _filter == filter;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _filter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<ActionEvent>>(
        valueListenable: ActionEventStore.notifier,
        builder: (context, events, _) {
          final filteredEvents = _applyFilter(events);

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: filteredEvents.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BoardHeroCard(),
                    _buildFilterBar(),
                  ],
                );
              }

              final event = filteredEvents[index - 1];
              return _ActionNoticeCard(event: event);
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<AdminAuthState>(
        valueListenable: AdminAuthStore.notifier,
        builder: (context, authState, _) {
          if (authState.user == null) {
            return FloatingActionButton.extended(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginPage(),
                  ),
                );
              },
              icon: const Icon(Icons.lock_outline),
              label: const Text('관리자 로그인'),
            );
          }

          if (authState.isChecking) {
            return FloatingActionButton.extended(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.navy,
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
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.red,
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
                backgroundColor: AppColors.white,
                foregroundColor: AppColors.navy,
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
                heroTag: 'add-fab',
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ActionEventFormPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('공지 등록'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BoardHeroCard extends StatelessWidget {
  const _BoardHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [AppColors.red, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '행동 공지 게시판',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '집회 / 오프라인 모임 / 중요 행동 일정은 이 게시판에서 관리합니다.',
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

class _ActionNoticeCard extends StatelessWidget {
  const _ActionNoticeCard({required this.event});

  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    final accentColor = event.type == '모임' ? AppColors.navy : AppColors.red;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      event.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              _ActionInfoRow(
                icon: Icons.schedule,
                label: '일시',
                value: event.dateTimeText,
              ),
              const SizedBox(height: 10),
              _ActionInfoRow(
                icon: Icons.location_on,
                label: '위치',
                value: event.locationName,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                event.slogans.take(3).map((e) => _BoardChip(e)).toList(),
              ),
              const SizedBox(height: 14),
              Text(
                event.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActionNoticeDetailPage(eventId: event.id),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('상세 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionInfoRow extends StatelessWidget {
  const _ActionInfoRow({
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
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.softBlue,
          child: Icon(icon, size: 18, color: AppColors.navy),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoardChip extends StatelessWidget {
  const _BoardChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.softBlue,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
    );
  }
}