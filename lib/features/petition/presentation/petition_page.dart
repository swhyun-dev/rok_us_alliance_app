// lib/features/petition/presentation/petition_page.dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../auth/data/admin_auth_store.dart';
import '../data/petition_store.dart';
import '../domain/petition.dart';
import 'petition_detail_page.dart';
import 'petition_form_page.dart';
import 'widgets/petition_card.dart';

class PetitionPage extends StatefulWidget {
  const PetitionPage({super.key});

  @override
  State<PetitionPage> createState() => _PetitionPageState();
}

class _PetitionPageState extends State<PetitionPage> {
  PetitionTab _tab = PetitionTab.nationalPetition;
  PetitionStatusFilter _status = PetitionStatusFilter.active;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('청원·법안',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          ValueListenableBuilder<AdminAuthState>(
            valueListenable: AdminAuthStore.notifier,
            builder: (context, authState, _) {
              if (!authState.isAdmin) return const SizedBox.shrink();
              return IconButton(
                tooltip: '청원·법안 등록',
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PetitionFormPage(initialTab: _tab),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _TopTabBar(
            current: _tab,
            onSelect: (t) => setState(() => _tab = t),
          ),
          _StatusSegmentBar(
            tab: _tab,
            current: _status,
            onSelect: (s) => setState(() => _status = s),
          ),
          Expanded(
            child: StreamBuilder<List<Petition>>(
              stream: PetitionStore.watchByTab(
                tab: _tab,
                status: _status,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '청원·법안을 불러오지 못했습니다.\n${snapshot.error}',
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
                  return _EmptyHint(tab: _tab, status: _status);
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = list[index];
                      return PetitionCard(
                        petition: p,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PetitionDetailPage(petitionId: p.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopTabBar extends StatelessWidget {
  const _TopTabBar({required this.current, required this.onSelect});
  final PetitionTab current;
  final ValueChanged<PetitionTab> onSelect;

  static const _items = <(PetitionTab, String, IconData)>[
    (PetitionTab.nationalPetition, '국민청원', Icons.how_to_vote_outlined),
    (PetitionTab.legislativeBill, '입법법안', Icons.gavel),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: _items.map((entry) {
          final selected = entry.$1 == current;
          return Expanded(
            child: InkWell(
              onTap: () => onSelect(entry.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? AppColors.koreanBlue
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      entry.$3,
                      size: 16,
                      color: selected
                          ? AppColors.koreanBlue
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: selected
                            ? AppColors.koreanBlue
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatusSegmentBar extends StatelessWidget {
  const _StatusSegmentBar({
    required this.tab,
    required this.current,
    required this.onSelect,
  });
  final PetitionTab tab;
  final PetitionStatusFilter current;
  final ValueChanged<PetitionStatusFilter> onSelect;

  static const _items = <(PetitionStatusFilter, String)>[
    (PetitionStatusFilter.active, '진행중'),
    (PetitionStatusFilter.completed, '완료'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: _items.map((entry) {
          final selected = entry.$1 == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => onSelect(entry.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppColors.koreanBlue : AppColors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color:
                        selected ? AppColors.koreanBlue : AppColors.border,
                  ),
                ),
                child: StreamBuilder<int>(
                  stream: PetitionStore.watchCount(
                    tab: tab,
                    status: entry.$1,
                  ),
                  builder: (context, snap) {
                    final count = snap.data;
                    final label = count == null
                        ? entry.$2
                        : '${entry.$2} $count';
                    return Text(
                      label,
                      style: TextStyle(
                        color:
                            selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.tab, required this.status});
  final PetitionTab tab;
  final PetitionStatusFilter status;

  String get _label {
    final tabLabel =
        tab == PetitionTab.legislativeBill ? '입법법안' : '국민청원';
    final statusLabel =
        status == PetitionStatusFilter.active ? '진행중인' : '완료된';
    return '$statusLabel $tabLabel 이 없습니다.';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab == PetitionTab.legislativeBill
                  ? Icons.gavel_outlined
                  : Icons.how_to_vote_outlined,
              size: 56,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
