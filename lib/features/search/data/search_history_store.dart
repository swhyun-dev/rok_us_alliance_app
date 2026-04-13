// 파일경로: lib/features/search/data/search_history_store.dart
import 'package:flutter/material.dart';

class SearchHistoryStore {
  SearchHistoryStore._();

  static final ValueNotifier<List<String>> notifier =
  ValueNotifier<List<String>>([]);

  static List<String> get items => notifier.value;

  static void add(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final updated = [...notifier.value];
    updated.remove(trimmed);
    updated.insert(0, trimmed);

    if (updated.length > 10) {
      updated.removeLast();
    }

    notifier.value = updated;
  }

  static void remove(String keyword) {
    notifier.value =
        notifier.value.where((e) => e != keyword).toList();
  }

  static void clear() {
    notifier.value = [];
  }
}