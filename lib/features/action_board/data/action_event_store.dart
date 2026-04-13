// lib/features/action_board/data/action_event_store.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../domain/action_event.dart';
import 'action_event_seed.dart';

class ActionEventStore {
  ActionEventStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference<Map<String, dynamic>> _collection =
  _firestore.collection('action_events');

  static final ValueNotifier<List<ActionEvent>> notifier =
  ValueNotifier<List<ActionEvent>>([]);

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static bool _started = false;

  static List<ActionEvent> get events => notifier.value;

  static Future<void> startListening() async {
    if (_started) return;
    _started = true;

    final existing = await _collection.limit(1).get();
    if (existing.docs.isEmpty) {
      await seedIfEmpty();
    }

    _subscription = _collection.orderBy('startAt').snapshots().listen(
          (snapshot) {
        final items = snapshot.docs
            .map((doc) => ActionEvent.fromFirestore(doc.id, doc.data()))
            .toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt));

        notifier.value = items;
      },
    );
  }

  static Future<void> seedIfEmpty() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    for (final event in ActionEventSeed.events) {
      await _collection.doc(event.id).set(event.toMap());
    }
  }

  static Future<void> add(ActionEvent event) async {
    await _collection.doc(event.id).set(event.toMap());
  }

  static Future<void> update(ActionEvent updatedEvent) async {
    await _collection.doc(updatedEvent.id).update(updatedEvent.toMap());
  }

  static Future<void> remove(String id) async {
    await _collection.doc(id).delete();
  }

  static ActionEvent? findById(String id) {
    try {
      return notifier.value.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _started = false;
  }
}