// lib/features/auth/data/admin_auth_store.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AdminAuthState {
  final User? user;
  final bool isAdmin;
  final bool isChecking;

  const AdminAuthState({
    required this.user,
    required this.isAdmin,
    required this.isChecking,
  });

  factory AdminAuthState.signedOut() {
    return const AdminAuthState(
      user: null,
      isAdmin: false,
      isChecking: false,
    );
  }

  factory AdminAuthState.checking(User user) {
    return AdminAuthState(
      user: user,
      isAdmin: false,
      isChecking: true,
    );
  }

  factory AdminAuthState.signedIn(User user, {required bool isAdmin}) {
    return AdminAuthState(
      user: user,
      isAdmin: isAdmin,
      isChecking: false,
    );
  }
}

class AdminAuthStore {
  AdminAuthStore._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ValueNotifier<AdminAuthState> notifier =
  ValueNotifier<AdminAuthState>(AdminAuthState.signedOut());

  static StreamSubscription<User?>? _authSubscription;
  static bool _started = false;

  static User? get currentUser => notifier.value.user;
  static bool get isLoggedIn => currentUser != null;
  static bool get isAdmin => notifier.value.isAdmin;
  static bool get isChecking => notifier.value.isChecking;

  static void startListening() {
    if (_started) return;
    _started = true;

    _authSubscription = _auth.authStateChanges().listen((user) async {
      if (user == null) {
        notifier.value = AdminAuthState.signedOut();
        return;
      }

      notifier.value = AdminAuthState.checking(user);

      final adminDoc =
      await _firestore.collection('admins').doc(user.uid).get();

      notifier.value = AdminAuthState.signedIn(
        user,
        isAdmin: adminDoc.exists,
      );
    });
  }

  static Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _started = false;
  }
}