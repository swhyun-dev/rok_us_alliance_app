// lib/features/admin/presentation/admin_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AdminAuthState>(
      valueListenable: AdminAuthStore.notifier,
      builder: (context, authState, _) {
        if (!authState.isAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('관리자 대시보드')),
            body: const Center(
              child: Text('관리자 권한이 없는 계정입니다.'),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('관리자 대시보드',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            children: const [
              _PendingReportsSection(),
              SizedBox(height: 20),
              _AdminQuickActions(),
            ],
          ),
        );
      },
    );
  }
}

class _PendingReportsSection extends StatelessWidget {
  const _PendingReportsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.flag_outlined, color: AppColors.koreanRed),
            SizedBox(width: 8),
            Text(
              '대기 중인 신고',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('reports')
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true)
              .limit(20)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('불러오기 실패: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.koreanRed));
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '대기 중인 신고가 없습니다.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: List.generate(docs.length, (i) {
                  final d = docs[i].data();
                  return Column(
                    children: [
                      _ReportTile(reportId: docs[i].id, data: d),
                      if (i != docs.length - 1)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.reportId, required this.data});
  final String reportId;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final targetType = data['targetType'] ?? '';
    final targetId = data['targetId'] ?? '';
    final reason = data['reason'] ?? '';
    final reporter = data['reporterNickname'] ?? '익명';
    final description = data['description'] as String?;
    final createdAt = data['createdAt'];
    final createdLabel = createdAt is Timestamp
        ? _shortDate(createdAt.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.softRed,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$targetType · $reason',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.koreanRed,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                createdLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            '$targetType: $targetId',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '신고자: $reporter',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _resolve(reportId, 'dismissed'),
                  child: const Text('기각'),
                ),
              ),
              const SizedBox(width: 8),
              if (targetType == 'post')
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.koreanRed,
                    ),
                    onPressed: () => _hidePost(context, targetId, reportId),
                    child: const Text('게시글 삭제'),
                  ),
                )
              else
                Expanded(
                  child: FilledButton(
                    onPressed: () => _resolve(reportId, 'resolved'),
                    child: const Text('처리 완료'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resolve(String id, String status) async {
    await FirebaseFirestore.instance.collection('reports').doc(id).update({
      'status': status,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolution': status == 'dismissed' ? '기각' : '처리 완료',
    });
  }

  Future<void> _hidePost(
    BuildContext context,
    String postId,
    String reportId,
  ) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deletePost');
      await callable.call<Map<String, dynamic>>({'postId': postId});
      await _resolve(reportId, 'resolved');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 숨김 처리됐습니다.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e')),
      );
    }
  }
}

class _AdminQuickActions extends StatelessWidget {
  const _AdminQuickActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.tune, color: AppColors.koreanBlue),
            SizedBox(width: 8),
            Text(
              '빠른 액션',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _AdminActionTile(
                icon: Icons.adjust,
                title: '점수 조정',
                subtitle: '특정 사용자 점수 가감',
                onTap: () => _showAdjustPointsDialog(context),
              ),
              const Divider(height: 1, color: AppColors.border),
              _AdminActionTile(
                icon: Icons.block,
                title: '사용자 차단',
                subtitle: 'isBanned=true 설정',
                onTap: () => _showBanUserDialog(context),
              ),
              const Divider(height: 1, color: AppColors.border),
              _AdminActionTile(
                icon: Icons.delete_outline,
                title: '게시글 삭제',
                subtitle: 'postId 로 강제 숨김',
                onTap: () => _showDeletePostDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAdjustPointsDialog(BuildContext context) async {
    final uid = TextEditingController();
    final amount = TextEditingController();
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('점수 조정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uid,
              decoration: const InputDecoration(labelText: '대상 uid'),
            ),
            TextField(
              controller: amount,
              decoration: const InputDecoration(
                labelText: '가감 점수 (음수 가능)',
              ),
              keyboardType: TextInputType.numberWithOptions(signed: true),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: '사유'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('실행'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('adjustPoints');
      await callable.call<Map<String, dynamic>>({
        'uid': uid.text.trim(),
        'amount': int.tryParse(amount.text.trim()) ?? 0,
        'reason': reason.text.trim(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('점수 조정 완료')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e')),
      );
    }
  }

  Future<void> _showBanUserDialog(BuildContext context) async {
    final uid = TextEditingController();
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('사용자 차단'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: uid,
              decoration: const InputDecoration(labelText: '대상 uid'),
            ),
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: '사유'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.koreanRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('차단'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('banUser');
      await callable.call<Map<String, dynamic>>({
        'uid': uid.text.trim(),
        'reason': reason.text.trim(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 차단 완료')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e')),
      );
    }
  }

  Future<void> _showDeletePostDialog(BuildContext context) async {
    final postId = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('게시글 강제 삭제'),
        content: TextField(
          controller: postId,
          decoration: const InputDecoration(labelText: 'postId'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.koreanRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('deletePost');
      await callable.call<Map<String, dynamic>>({
        'postId': postId.text.trim(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 삭제 완료')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('실패: $e')),
      );
    }
  }
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.koreanBlue),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
        size: 18,
      ),
    );
  }
}

String _shortDate(DateTime d) =>
    '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
