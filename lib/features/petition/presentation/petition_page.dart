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
  PetitionFilter _filter = PetitionFilter.active;

  static const _segments = <(PetitionFilter, String)>[
    (PetitionFilter.active, '진행중'),
    (PetitionFilter.popular, '인기'),
    (PetitionFilter.newest, '신규'),
    (PetitionFilter.completed, '완료'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('청원',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          ValueListenableBuilder<AdminAuthState>(
            valueListenable: AdminAuthStore.notifier,
            builder: (context, authState, _) {
              if (!authState.isAdmin) return const SizedBox.shrink();
              return IconButton(
                tooltip: '청원 등록',
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PetitionFormPage(),
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
          _SegmentBar(
            current: _filter,
            segments: _segments,
            onSelect: (f) => setState(() => _filter = f),
          ),
          Expanded(
            child: StreamBuilder<List<Petition>>(
              stream: PetitionStore.watchAll(_filter),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        '청원을 불러오지 못했습니다.\n${snapshot.error}',
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
                      padding: EdgeInsets.all(36),
                      child: Text(
                        '해당 상태의 청원이 없습니다.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
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

class _SegmentBar extends StatelessWidget {
  const _SegmentBar({
    required this.current,
    required this.segments,
    required this.onSelect,
  });

  final PetitionFilter current;
  final List<(PetitionFilter, String)> segments;
  final ValueChanged<PetitionFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: segments.map((entry) {
            final selected = entry.$1 == current;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onSelect(entry.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.koreanBlue : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          selected ? AppColors.koreanBlue : AppColors.border,
                    ),
                  ),
                  child: Text(
                    entry.$2,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
