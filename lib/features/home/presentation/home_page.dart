// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../action_board/data/action_event_store.dart';
import '../../action_board/domain/action_event.dart';
import '../../action_board/presentation/action_board_page.dart';
import '../../action_board/presentation/action_notice_detail_page.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../community/presentation/community_page.dart';
import '../../profile/presentation/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showIntroPopup = false,
    this.initialIndex = 0,
  });

  final bool showIntroPopup;
  final int initialIndex;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _hidePopupDateKey = 'hide_intro_popup_until_date';

  late int _selectedIndex;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    ActionEventStore.startListening();
    AdminAuthStore.startListening();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!widget.showIntroPopup || _popupShown) return;
      if (_selectedIndex != 0) return;

      final shouldHide = await _shouldHidePopupToday();
      if (!mounted) return;

      if (!shouldHide) {
        _popupShown = true;
        _showIntroImagePopup();
      }
    });
  }

  Future<bool> _shouldHidePopupToday() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_hidePopupDateKey);
    if (saved == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    return saved == today;
  }

  Future<void> _hidePopupForToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    await prefs.setString(_hidePopupDateKey, today);
  }

  Future<void> _showIntroImagePopup() async {
    bool dontShowToday = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 720 / 1280,
                                      child: Image.asset(
                                        'assets/images/maga_with_rok_popup.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        14,
                                        16,
                                        18,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Center(
                                            child: Text(
                                              '한미동맹단 주요 행사 안내',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            '어떤 당이든 함께 모여 주세요. 우리에겐 한미동맹이 필요합니다.',
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.55,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: AppColors.softSky,
                                              borderRadius:
                                              BorderRadius.circular(16),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: const Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                _PopupBullet(
                                                  '준비물 / 반투명 우산(흰우산)',
                                                ),
                                                _PopupBullet('매주 토요일 참여 독려'),
                                                _PopupBullet('질서 / 배려 / 논쟁 금지'),
                                                _PopupBullet('정확한 주소는 추후 재공지'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: dontShowToday,
                                                activeColor: AppColors.navy,
                                                onChanged: (value) {
                                                  setDialogState(() {
                                                    dontShowToday =
                                                        value ?? false;
                                                  });
                                                },
                                              ),
                                              const Expanded(
                                                child: Text(
                                                  '오늘 하루 보지 않기',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                    AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppColors.navy,
                                                padding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 14,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(14),
                                                ),
                                              ),
                                              onPressed: () async {
                                                if (dontShowToday) {
                                                  await _hidePopupForToday();
                                                }
                                                if (dialogContext.mounted) {
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                }
                                              },
                                              child: const Text('확인'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -4,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (dontShowToday) {
                              await _hidePopupForToday();
                            }
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onTap(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 1:
        return const ActionBoardPage();
      case 2:
        return const CalendarPage();
      case 3:
        return const CommunityPage();
      case 4:
        return const ProfilePage();
      case 0:
      default:
        return _HomeDashboard(
          onMoveToActionBoard: () => _onTap(1),
          onMoveToCalendar: () => _onTap(2),
        );
    }
  }

  String _appBarTitle() {
    switch (_selectedIndex) {
      case 1:
        return '행동 공지';
      case 2:
        return '캘린더';
      case 3:
        return '커뮤니티';
      case 4:
        return '내 정보';
      default:
        return '한미동맹단';
    }
  }

  String _appBarSubtitle() {
    switch (_selectedIndex) {
      case 1:
        return '집회 / 모임 / 중요 행동 일정을 확인하세요';
      case 2:
        return '한눈에 보는 집회 / 모임 / 중요 일정';
      case 3:
        return '자유 소통 / 지역모임 / 정보 공유 공간';
      case 4:
        return '내 활동 현황과 등급을 확인하세요';
      default:
        return 'ROK / US Alliance Action Platform';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _appBarTitle(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              _appBarSubtitle(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            label: '공지',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            label: '커뮤니티',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: '내정보',
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.onMoveToActionBoard,
    required this.onMoveToCalendar,
  });

  final VoidCallback onMoveToActionBoard;
  final VoidCallback onMoveToCalendar;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActionEvent>>(
      valueListenable: ActionEventStore.notifier,
      builder: (context, events, _) {
        final mainEvent = events.isNotEmpty ? events.first : null;
        final upcoming = events.take(3).toList();
        final urgentEvent = _findNearestUpcoming(events);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const _HeroSection(),
            const SizedBox(height: 16),
            if (urgentEvent != null) ...[
              _UrgentBannerCard(event: urgentEvent),
              const SizedBox(height: 16),
            ],
            _QuickActionRow(
              onMoveToActionBoard: onMoveToActionBoard,
              onMoveToCalendar: onMoveToCalendar,
            ),
            const SizedBox(height: 16),
            if (mainEvent != null) _NoticeHighlightCard(event: mainEvent),
            if (mainEvent != null) const SizedBox(height: 16),
            const _SloganStrip(),
            const SizedBox(height: 16),
            _CalendarPreviewCard(events: upcoming),
          ],
        );
      },
    );
  }

  ActionEvent? _findNearestUpcoming(List<ActionEvent> events) {
    if (events.isEmpty) return null;
    final now = DateTime.now();

    final upcoming = events.where((e) => !e.startAt.isBefore(now)).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));

    if (upcoming.isNotEmpty) return upcoming.first;

    final sorted = [...events]..sort((a, b) => b.startAt.compareTo(a.startAt));
    return sorted.first;
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: AppColors.heroGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlagAccentBar(),
              SizedBox(height: 14),
              Text(
                '자유를 지키는 연결',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '한미동맹의 힘을\n하나로 모으는 플랫폼',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '단순 커뮤니티가 아니라 / 사람을 연결하고 / 행동으로 이어지게 합니다.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrgentBannerCard extends StatelessWidget {
  const _UrgentBannerCard({required this.event});

  final ActionEvent event;

  String _buildDDayText() {
    final now = DateTime.now();
    final baseNow = DateTime(now.year, now.month, now.day);
    final baseEvent = DateTime(event.startAt.year, event.startAt.month, event.startAt.day);
    final diff = baseEvent.difference(baseNow).inDays;

    if (diff == 0) return 'D-DAY';
    if (diff > 0) return 'D-$diff';
    return '종료';
  }

  String _buildSubText() {
    final dday = _buildDDayText();
    if (dday == 'D-DAY') {
      return '오늘 일정입니다 / 지금 바로 공지를 확인하고 참여 준비를 해주세요.';
    }
    if (dday == '종료') {
      return '가장 최근 일정입니다 / 관련 공지를 다시 확인할 수 있습니다.';
    }
    return '$dday 일정입니다 / 미리 위치와 준비물을 확인해두세요.';
  }

  @override
  Widget build(BuildContext context) {
    final dday = _buildDDayText();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.red, Color(0xFF8B1E2D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: 0.22),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  dday,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '긴급 행동 공지',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      height: 1.35,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSubText(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.dateTimeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _FlagAccentBar extends StatelessWidget {
  const _FlagAccentBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: AppColors.flagAccentGradient,
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({
    required this.onMoveToActionBoard,
    required this.onMoveToCalendar,
  });

  final VoidCallback onMoveToActionBoard;
  final VoidCallback onMoveToCalendar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickMenuCard(
            title: '행동 공지',
            subtitle: '집회 / 일정',
            icon: Icons.campaign,
            color: AppColors.red,
            onTap: onMoveToActionBoard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickMenuCard(
            title: '캘린더',
            subtitle: '한눈 일정',
            icon: Icons.calendar_month,
            color: AppColors.navy,
            onTap: onMoveToCalendar,
          ),
        ),
      ],
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  const _QuickMenuCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoticeHighlightCard extends StatelessWidget {
  const _NoticeHighlightCard({required this.event});

  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
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
              const Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.softRed,
                    child: Icon(Icons.location_on, color: AppColors.red),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '이번 주 대표 행동 공지',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 14),
              _InfoLine(label: '일시', value: event.dateTimeText),
              const SizedBox(height: 8),
              _InfoLine(label: '위치', value: event.locationName),
              const SizedBox(height: 8),
              _InfoLine(label: '준비물', value: event.items.join(', ')),
              const SizedBox(height: 12),
              Text(
                '슬로건 / ${event.slogans.join(' / ')}',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
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
                  child: const Text('상세 공지 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SloganStrip extends StatelessWidget {
  const _SloganStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SloganText('WE GO TOGETHER', AppColors.red),
            SizedBox(width: 18),
            _SloganText('SAVE KOREA', AppColors.navy),
            SizedBox(width: 18),
            _SloganText('MAGA WITH ROK', AppColors.red),
          ],
        ),
      ),
    );
  }
}

class _SloganText extends StatelessWidget {
  const _SloganText(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _CalendarPreviewCard extends StatelessWidget {
  const _CalendarPreviewCard({required this.events});

  final List<ActionEvent> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '다가오는 일정',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            if (events.isEmpty)
              const Text(
                '등록된 일정이 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ...events.map(
                  (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ScheduleRow(event: event),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.event});

  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.monthLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.red,
                    ),
                  ),
                  Text(
                    event.dayLabel,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.locationName,
                    style: const TextStyle(
                      fontSize: 13,
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
    );
  }
}

class _PopupBullet extends StatelessWidget {
  const _PopupBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.circle,
              size: 6,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}