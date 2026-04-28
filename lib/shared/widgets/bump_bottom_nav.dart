// lib/shared/widgets/bump_bottom_nav.dart
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'bump_bottom_nav_painter.dart';

/// 탭바 높이(SafeArea bottom 제외).
const double _tabBarHeight = 60;

/// 중앙 홈 버튼.
const double _centerSize = 58;
const double _centerElevation = 20;
const double _cutoutRadius = 36;

class BumpNavTab {
  const BumpNavTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.hasBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool hasBadge;
}

/// 5탭 + 중앙 범프(돌출) 탭바.
/// CLAUDE.md Section 5 명세 기반.
class BumpBottomNav extends StatelessWidget {
  const BumpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  /// 0~4 (중앙은 인덱스 2).
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BumpNavTab> tabs;

  @override
  Widget build(BuildContext context) {
    assert(tabs.length == 5, 'BumpBottomNav 는 정확히 5탭을 요구합니다.');

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: _tabBarHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 컷아웃이 그려진 배경
          Positioned.fill(
            child: CustomPaint(
              painter: BumpBottomNavPainter(
                cutoutRadius: _cutoutRadius,
                backgroundColor: Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.10),
              ),
            ),
          ),
          // 5탭 행
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Row(
              children: List.generate(5, (i) {
                if (i == 2) {
                  // 중앙은 빈 공간 — 실제 버튼은 Stack 위에서 그림.
                  return const Expanded(child: SizedBox.shrink());
                }
                return Expanded(
                  child: _SideTab(
                    tab: tabs[i],
                    selected: currentIndex == i,
                    onTap: () => onTap(i),
                  ),
                );
              }),
            ),
          ),
          // 중앙 범프 버튼 — 컷아웃 위로 돌출.
          Positioned(
            top: -(_centerElevation),
            left: 0,
            right: 0,
            child: Center(
              child: _CenterButton(
                tab: tabs[2],
                onTap: () => onTap(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideTab extends StatelessWidget {
  const _SideTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BumpNavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.koreanRed : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? tab.activeIcon : tab.icon,
                  size: 22, color: color),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 10.5,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (tab.hasBadge)
            Positioned(
              top: 6,
              right: 16,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.koreanRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({required this.tab, required this.onTap});

  final BumpNavTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: _centerSize,
          height: _centerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.koreanRed,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.koreanRed.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.home_filled, size: 26, color: Colors.white),
        ),
      ),
    );
  }
}
