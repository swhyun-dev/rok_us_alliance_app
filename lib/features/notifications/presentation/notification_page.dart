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

  Future<void> _confirmDeleteAll(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('전체 삭제', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          '받은 알림을 모두 삭제하시겠습니까?\n삭제된 알림은 복구할 수 없습니다.',
          style: TextStyle(height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.koreanRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('전체 삭제'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final n = await NotificationStore.deleteAll(uid);
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('알림 $n건이 삭제되었습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthStore.firebaseUid;
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
          if (uid != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'delete_all') _confirmDeleteAll(context, uid);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined,
                          size: 18, color: AppColors.koreanRed),
                      SizedBox(width: 8),
                      Text('전체 삭제',
                          style: TextStyle(color: AppColors.koreanRed)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: uid == null
          ? const _EmptyState(
              icon: Icons.lock_outline,
              title: '로그인이 필요합니다',
              subtitle: '로그인 후 받은 알림을 확인할 수 있습니다.',
            )
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
                  return const _EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: '아직 받은 알림이 없어요',
                    subtitle:
                        '활동을 시작하면 점수 적립·승급·답글 등의 알림이 여기에 쌓입니다.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = list[i];
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: AppColors.koreanRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline,
                            color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          await NotificationStore.delete(n.id);
                        } catch (e) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('삭제 실패: $e')),
                          );
                        }
                      },
                      child: _NotificationTile(
                        notification: n,
                        icon: _iconForType(n.type),
                        color: _colorForType(n.type),
                        onTap: () async {
                          if (!n.isRead) {
                            await NotificationStore.markAsRead(n.id);
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
