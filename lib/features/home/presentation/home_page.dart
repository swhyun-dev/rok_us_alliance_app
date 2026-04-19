// lib/features/home/presentation/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_app_bar.dart';
import '../../action_board/data/action_event_store.dart';
import '../../action_board/domain/action_event.dart';
import '../../action_board/presentation/action_board_page.dart';
import '../../action_board/presentation/action_notice_detail_page.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../community/presentation/community_page.dart';
import '../../membership/data/member_store.dart';
import '../../membership/presentation/membership_card_modal.dart';
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
    MemberStore.loadMock();

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
                                          16, 14, 16, 18),
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
                                                  color: AppColors.border),
                                            ),
                                            child: const Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _PopupBullet(
                                                    '준비물 / 반투명 우산(흰우산)'),
                                                _PopupBullet('매주 토요일 참여 독려'),
                                                _PopupBullet(
                                                    '질서 / 배려 / 논쟁 금지'),
                                                _PopupBullet(
                                                    '정확한 주소는 추후 재공지'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: dontShowToday,
                                                activeColor:
                                                    AppColors.koreanBlue,
                                                onChanged: (v) {
                                                  setDialogState(() {
                                                    dontShowToday = v ?? false;
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
                                                backgroundColor:
                                                    AppColors.koreanBlue,
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
                            if (dontShowToday) await _hidePopupForToday();
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
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 20),
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
    setState(() => _selectedIndex = index);
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
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
        return '일정 캘린더';
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
        return '집회 · 모임 · 중요 행동 일정을 확인하세요';
      case 2:
        return '행사 · 집회 · 모임 일정을 한눈에';
      case 3:
        return '자유 소통 · 지역모임 · 정보 공유 공간';
      case 4:
        return '내 활동 현황과 등급을 확인하세요';
      default:
        return 'ROK-US Alliance Action Platform';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AllianceAppBar.main(
        title: _appBarTitle(),
        subtitle: _appBarSubtitle(),
        hasNotification: false,
        onNotification: _showNotificationsSheet,
        onSettings: _showSettingsSheet,
        onCard: () => showMembershipCardModal(context),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: _buildCurrentPage(),
        ),
      ),
      bottomNavigationBar: _AllianceNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTap,
      ),
    );
  }
}

// ─── Navigation Bar ───────────────────────────────────────────────────────────

class _AllianceNavBar extends StatelessWidget {
  const _AllianceNavBar({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: '공지',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: '커뮤니티',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '내정보',
          ),
        ],
      ),
    );
  }
}

// ─── Home Dashboard ───────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const _HomeHeroCard(),
            const SizedBox(height: 14),
            if (urgentEvent != null) ...[
              _UrgentBannerCard(event: urgentEvent),
              const SizedBox(height: 14),
            ],
            _QuickActionRow(
              onMoveToActionBoard: onMoveToActionBoard,
              onMoveToCalendar: onMoveToCalendar,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('슬로건', icon: Icons.flag_outlined),
            const SizedBox(height: 10),
            const _SloganStrip(),
            const SizedBox(height: 18),
            if (mainEvent != null) ...[
              _SectionTitle(
                '이번 주 대표 공지',
                icon: Icons.location_on_outlined,
                trailing: TextButton(
                  onPressed: onMoveToActionBoard,
                  child: const Text('전체 보기'),
                ),
              ),
              const SizedBox(height: 10),
              _NoticeHighlightCard(event: mainEvent),
              const SizedBox(height: 18),
            ],
            _SectionTitle(
              '다가오는 일정',
              icon: Icons.schedule_outlined,
              trailing: TextButton(
                onPressed: onMoveToCalendar,
                child: const Text('캘린더 보기'),
              ),
            ),
            const SizedBox(height: 10),
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
    return ([...events]..sort((a, b) => b.startAt.compareTo(a.startAt))).first;
  }
}

// ─── Hero card ────────────────────────────────────────────────────────────────

class _HomeHeroCard extends StatelessWidget {
  const _HomeHeroCard();

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
            color: AppColors.koreanBlue.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -24,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.koreanRed.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Flag stripe accent
              Container(
                width: 148,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: AppColors.flagAccentGradient,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ROK-US ALLIANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '한미동맹의 힘을\n하나로 모으는 플랫폼',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  height: 1.3,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '사람을 연결하고 / 행동으로 이어지게 합니다.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Urgent banner ────────────────────────────────────────────────────────────

class _UrgentBannerCard extends StatelessWidget {
  const _UrgentBannerCard({required this.event});

  final ActionEvent event;

  String _dday() {
    final now = DateTime.now();
    final baseNow = DateTime(now.year, now.month, now.day);
    final baseEvent = DateTime(
        event.startAt.year, event.startAt.month, event.startAt.day);
    final diff = baseEvent.difference(baseNow).inDays;
    if (diff == 0) return 'D-DAY';
    if (diff > 0) return 'D-$diff';
    return '종료';
  }

  @override
  Widget build(BuildContext context) {
    final dday = _dday();
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [AppColors.koreanRed, Color(0xFF8B1E2D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.koreanRed.withValues(alpha: 0.24),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Center(
                child: Text(
                  dday,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.white70),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          event.dateTimeText,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ─── Quick actions ────────────────────────────────────────────────────────────

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
          child: _QuickCard(
            title: '행동 공지',
            subtitle: '집회 · 일정 확인',
            icon: Icons.campaign,
            gradientColors: const [AppColors.koreanRed, Color(0xFF8B1E2D)],
            onTap: onMoveToActionBoard,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickCard(
            title: '캘린더',
            subtitle: '한눈에 일정 보기',
            icon: Icons.calendar_month,
            gradientColors: const [AppColors.koreanBlue, AppColors.navy],
            onTap: onMoveToCalendar,
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.icon, this.trailing});

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
        if (icon != null) ...[
          Icon(icon, size: 18, color: AppColors.koreanBlue),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

// ─── Slogan strip ─────────────────────────────────────────────────────────────

class _SloganStrip extends StatelessWidget {
  const _SloganStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _SloganChip('WE GO TOGETHER', AppColors.koreanRed),
            SizedBox(width: 16),
            _SloganChip('SAVE KOREA', AppColors.koreanBlue),
            SizedBox(width: 16),
            _SloganChip('MAGA WITH ROK', AppColors.koreanRed),
            SizedBox(width: 16),
            _SloganChip('한미동맹 필승', AppColors.koreanBlue),
          ],
        ),
      ),
    );
  }
}

class _SloganChip extends StatelessWidget {
  const _SloganChip(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Notice highlight card ────────────────────────────────────────────────────

class _NoticeHighlightCard extends StatelessWidget {
  const _NoticeHighlightCard({required this.event});

  final ActionEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id)),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(label: '일시', value: event.dateTimeText),
              const SizedBox(height: 10),
              _InfoLine(label: '위치', value: event.locationName),
              const SizedBox(height: 10),
              _InfoLine(label: '준비물', value: event.items.join(', ')),
              const SizedBox(height: 12),
              Text(
                event.slogans.map((s) => '"$s"').join('  ·  '),
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 14),
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
                    backgroundColor: AppColors.koreanBlue,
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
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.koreanBlue,
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

// ─── Calendar preview ─────────────────────────────────────────────────────────

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
            if (events.isEmpty)
              const Text(
                '등록된 일정이 없습니다.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ...events.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ScheduleRow(event: e),
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
    final isProtest = event.type != '모임';
    final accentColor = isProtest ? AppColors.koreanRed : AppColors.koreanBlue;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ActionNoticeDetailPage(eventId: event.id)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: 0.20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.monthLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                  Text(
                    event.dayLabel,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
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
                  const SizedBox(height: 3),
                  Text(
                    event.locationName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: AppColors.textSecondary.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

// ─── Bottom sheets (알림 / 설정) ─────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
                const Text(
                  '알림',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_off_outlined,
                      color: AppColors.koreanBlue),
                  SizedBox(width: 12),
                  Text(
                    '새로운 알림이 없습니다.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.notifications_outlined, '알림 설정', '행동 공지 · 커뮤니티 알림'),
      (Icons.palette_outlined, '테마 설정', '앱 색상 및 표시 방식'),
      (Icons.language_outlined, '언어 설정', '한국어 / English'),
      (Icons.privacy_tip_outlined, '개인정보 처리방침', ''),
      (Icons.info_outlined, '앱 정보', 'v1.0.0'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
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
                const Text(
                  '설정',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.softBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$1, color: AppColors.koreanBlue, size: 18),
              ),
              title: Text(
                item.$2,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary),
              ),
              subtitle: item.$3.isNotEmpty
                  ? Text(item.$3,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary))
                  : null,
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary, size: 18),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Popup bullet ─────────────────────────────────────────────────────────────

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
            padding: EdgeInsets.only(top: 7),
            child: Icon(Icons.circle, size: 5, color: AppColors.koreanBlue),
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
