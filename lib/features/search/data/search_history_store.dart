// lib/features/search/data/search_history_store.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStore {
  SearchHistoryStore._();

  static const String _key = 'search_history_v1';
  static const int _maxEntries = 12;

  static final ValueNotifier<List<String>> notifier =
      ValueNotifier<List<String>>(<String>[]);

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    notifier.value = prefs.getStringList(_key) ?? const <String>[];
  }

  static Future<void> add(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    final next = [
      trimmed,
      ...notifier.value.where((k) => k != trimmed),
    ].take(_maxEntries).toList();

    notifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  static Future<void> remove(String keyword) async {
    final next = notifier.value.where((k) => k != keyword).toList();
    notifier.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next);
  }

  static Future<void> clear() async {
    notifier.value = const <String>[];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
