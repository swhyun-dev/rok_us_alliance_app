// lib/features/notifications/presentation/notification_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/auth_store.dart';
import '../data/notification_store.dart';
import '../domain/app_notification.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'point_awarded':
        return Icons.adjust;
      case 'level_up':
        return Icons.workspace_premium_outlined;
      case 'comment_received':
        return Icons.chat_bubble_outline;
      case 'like_received':
        return Icons.favorite_outline;
      case 'event_reminder':
        return Icons.event_note;
      case 'petition_milestone':
        return Icons.how_to_vote_outlined;
      case 'urgent_alert':
        return Icons.campaign;
      case 'admin_message':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'urgent_alert':
        return AppColors.koreanRed;
      case 'level_up':
      case 'point_awarded':
        return AppColors.koreanBlue;
      case 'petition_milestone':
        return AppColors.gold;
      default:
        return AppColors.darkNavy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthStore.currentUser?.providerUserId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('알림',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          if (uid != null)
            StreamBuilder<List<AppNotification>>(
              stream: NotificationStore.watchMine(uid),
              builder: (context, snap) {
                final list = snap.data ?? const <AppNotification>[];
                final unreadIds =
                    list.where((n) => !n.isRead).map((n) => n.id).toList();
                if (unreadIds.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () =>
                      NotificationStore.markAllAsRead(unreadIds),
                  child: const Text('모두 읽음'),
                );
              },
            ),
        ],
      ),
      body: uid == null
          ? const Center(child: Text('로그인이 필요합니다.'))
          : StreamBuilder<List<AppNotification>>(
              stream: NotificationStore.watchMine(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '알림을 불러오지 못했습니다.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.koreanRed),
                      ),
                    ),
                  );
                }
                final list = snapshot.data;
                if (list == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        '아직 받은 알림이 없습니다.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = list[i];
                    return _NotificationTile(
                      notification: n,
                      icon: _iconForType(n.type),
                      color: _colorForType(n.type),
                      onTap: () async {
                        if (!n.isRead) {
                          await NotificationStore.markAsRead(n.id);
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final AppNotification notification;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: unread ? AppColors.softBlue : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread
                                ? FontWeight.w900
                                : FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.koreanRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.timeLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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
  }
}
