// lib/features/action_board/presentation/action_notice_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../auth/presentation/admin_login_page.dart';
import '../data/action_event_store.dart';
import '../domain/action_event.dart';
import 'action_event_form_page.dart';

class ActionNoticeDetailPage extends StatefulWidget {
  const ActionNoticeDetailPage({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<ActionNoticeDetailPage> createState() => _ActionNoticeDetailPageState();
}

class _ActionNoticeDetailPageState extends State<ActionNoticeDetailPage> {
  bool _isJoined = false;

  String get _joinKey => 'joined_event_${widget.eventId}';

  @override
  void initState() {
    super.initState();
    _loadJoinState();
    AdminAuthStore.startListening();
  }

  Future<void> _loadJoinState() async {
    final prefs = await SharedPreferences.getInstance();
    final joined = prefs.getBool(_joinKey) ?? false;
    if (!mounted) return;
    setState(() {
      _isJoined = joined;
    });
  }

  Future<void> _toggleJoin() async {
    final prefs = await SharedPreferences.getInstance();
    final next = !_isJoined;
    await prefs.setBool(_joinKey, next);
    if (!mounted) return;
    setState(() {
      _isJoined = next;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? '참여 상태로 저장했습니다.' : '참여 상태를 해제했습니다.'),
      ),
    );
  }

  Future<void> _openGoogleMap(ActionEvent event) async {
    final query = Uri.encodeComponent(event.locationQuery);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구글맵을 열지 못했습니다.')),
      );
    }
  }

  Future<void> _openNaverMap(ActionEvent event) async {
    final query = Uri.encodeComponent(event.locationQuery);
    // 운영 시 appname은 실제 Android applicationId / iOS bundle id로 맞추는 것이 좋습니다.
    final naverUri = Uri.parse(
      'nmap://search?query=$query&appname=rok_us_alliance_app',
    );

    final launched = await launchUrl(
      naverUri,
      mode: LaunchMode.externalApplication,
    );

    if (launched) return;

    final fallbackUri = Uri.parse(
      'https://map.naver.com/v5/search/$query',
    );

    final fallbackLaunched = await launchUrl(
      fallbackUri,
      mode: LaunchMode.externalApplication,
    );

    if (!fallbackLaunched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('네이버지도를 열지 못했습니다.')),
      );
    }
  }

  Future<void> _copyAddress(ActionEvent event) async {
    await Clipboard.setData(
      ClipboardData(text: event.locationName),
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('주소를 복사했습니다.')),
    );
  }

  Future<void> _shareEvent(ActionEvent event) async {
    await Share.share(
      event.buildShareText(),
      subject: event.title,
    );
  }

  Future<void> _deleteEvent(ActionEvent event) async {
    final authState = AdminAuthStore.notifier.value;
    if (authState.user == null || !authState.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
        ),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('공지 삭제'),
          content: const Text('이 공지를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    await ActionEventStore.remove(event.id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActionEvent>>(
      valueListenable: ActionEventStore.notifier,
      builder: (context, _, __) {
        final event = ActionEventStore.findById(widget.eventId);

        if (event == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('행동 공지 상세')),
            body: const Center(
              child: Text('삭제되었거나 존재하지 않는 공지입니다.'),
            ),
          );
        }

        final accentColor = event.type == '모임' ? AppColors.navy : AppColors.red;

        return Scaffold(
          appBar: AppBar(
            title: const Text('행동 공지 상세'),
            actions: [
              ValueListenableBuilder<AdminAuthState>(
                valueListenable: AdminAuthStore.notifier,
                builder: (context, authState, _) {
                  if (authState.user == null) {
                    return IconButton(
                      icon: const Icon(Icons.lock_outline),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginPage(),
                          ),
                        );
                      },
                    );
                  }

                  if (authState.isChecking) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }

                  if (!authState.isAdmin) {
                    return const SizedBox.shrink();
                  }

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ActionEventFormPage(initialEvent: event),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEvent(event),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [AppColors.red, AppColors.navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        event.status,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      event.type,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.schedule,
                        label: '일시',
                        value: event.dateTimeText,
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.location_on,
                        label: '위치',
                        value: event.locationName,
                      ),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.checkroom,
                        label: '준비물',
                        value: event.items.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '슬로건',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: event.slogans
                            .map((e) => _SloganChip(text: e, color: accentColor))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '상세 안내',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openGoogleMap(event),
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('구글지도'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openNaverMap(event),
                      icon: const Icon(Icons.near_me_outlined),
                      label: const Text('네이버지도'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _copyAddress(event),
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('주소 복사'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _shareEvent(event),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('공유하기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _toggleJoin,
                  icon: Icon(
                    _isJoined ? Icons.check_circle : Icons.how_to_reg,
                  ),
                  label: Text(_isJoined ? '참여중' : '참여하기'),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    _isJoined ? AppColors.red : AppColors.royalBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SloganChip extends StatelessWidget {
  const _SloganChip({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}