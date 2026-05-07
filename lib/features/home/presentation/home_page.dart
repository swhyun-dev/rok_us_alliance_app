// lib/features/home/presentation/home_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/widgets/alliance_app_bar.dart';
import '../../auth/data/admin_auth_store.dart';
import '../../auth/data/auth_store.dart';
import '../../calendar/presentation/calendar_page.dart';
import '../../feed/presentation/feed_page.dart';
import '../../membership/data/member_store.dart';
import '../../membership/presentation/membership_card_modal.dart';
import '../../notifications/data/notification_store.dart';
import '../../notifications/presentation/notification_page.dart';
import '../../petition/presentation/petition_page.dart';
import '../../profile/presentation/profile_page.dart';
import '../../../shared/widgets/bump_bottom_nav.dart';
import 'home_main_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.showIntroPopup = false,
    this.initialIndex = 2,
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
  StreamSubscription<int>? _unreadSub;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    AdminAuthStore.startListening();
    MemberStore.loadMock();
    AuthStore.notifier.addListener(_attachUnreadStream);
    _attachUnreadStream();

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

  void _attachUnreadStream() {
    _unreadSub?.cancel();
    final uid = AuthStore.firebaseUid;
    if (uid == null) {
      if (_unreadCount != 0 && mounted) {
        setState(() => _unreadCount = 0);
      }
      return;
    }
    _unreadSub = NotificationStore.watchUnreadCount(uid).listen((c) {
      if (!mounted) return;
      setState(() => _unreadCount = c);
    });
  }

  @override
  void dispose() {
    AuthStore.notifier.removeListener(_attachUnreadStream);
    _unreadSub?.cancel();
    super.dispose();
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationPage()),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SettingsSheet(),
    );
  }

  /// 5탭: 0 피드 / 1 청원 / 2 홈(중앙 범프) / 3 일정 / 4 마이
  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return const FeedPage();
      case 1:
        return const PetitionPage();
      case 3:
        return const CalendarPage();
      case 4:
        return const ProfilePage();
      case 2:
      default:
        return HomeMainPage(
          onMoveToFeed: () => _onTap(0),
          onMoveToCalendar: () => _onTap(3),
          onMoveToPetition: () => _onTap(1),
        );
    }
  }

  String _appBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return '실시간 피드';
      case 1:
        return '청원';
      case 3:
        return '일정 캘린더';
      case 4:
        return '내 정보';
      case 2:
      default:
        return '한미동맹단';
    }
  }

  String _appBarSubtitle() {
    switch (_selectedIndex) {
      case 0:
        return '긴급 · 정책 · 네트워크 · 행사 소식';
      case 1:
        return '진행중 · 인기 · 신규 · 완료된 청원';
      case 3:
        return '행사 · 집회 · 모임 일정을 한눈에';
      case 4:
        return '내 활동 현황과 등급을 확인하세요';
      case 2:
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
        hasNotification: _unreadCount > 0,
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
      bottomNavigationBar: BumpBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onTap,
        tabs: const [
          BumpNavTab(
            label: '피드',
            icon: Icons.article_outlined,
            activeIcon: Icons.article,
          ),
          BumpNavTab(
            label: '청원',
            icon: Icons.edit_outlined,
            activeIcon: Icons.edit,
          ),
          BumpNavTab(
            label: '',
            icon: Icons.home_filled,
            activeIcon: Icons.home_filled,
          ),
          BumpNavTab(
            label: '일정',
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
          ),
          BumpNavTab(
            label: '마이',
            icon: Icons.person_outline,
            activeIcon: Icons.person,
          ),
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
