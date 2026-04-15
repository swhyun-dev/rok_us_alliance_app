// lib/features/auth/data/auth_store.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_user.dart';
import 'naver_auth_service.dart';

class NaverProfileDraft {
  const NaverProfileDraft({
    required this.providerUserId,
    required this.naverNickname,
    required this.name,
    required this.phoneNumber,
    this.email,
  });

  final String providerUserId;
  final String naverNickname;
  final String name;
  final String phoneNumber;
  final String? email;

  Map<String, dynamic> toMap() {
    return {
      'providerUserId': providerUserId,
      'naverNickname': naverNickname,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
    };
  }

  factory NaverProfileDraft.fromMap(Map<String, dynamic> map) {
    return NaverProfileDraft(
      providerUserId: (map['providerUserId'] ?? '') as String,
      naverNickname: (map['naverNickname'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      phoneNumber: (map['phoneNumber'] ?? '') as String,
      email: map['email'] as String?,
    );
  }
}

class AuthState {
  const AuthState({
    required this.isInitialized,
    required this.isLoading,
    required this.user,
    required this.pendingProfile,
    required this.errorMessage,
  });

  final bool isInitialized;
  final bool isLoading;
  final AppUser? user;
  final NaverProfileDraft? pendingProfile;
  final String? errorMessage;

  bool get isSignedIn => user != null;

  factory AuthState.initial() {
    return const AuthState(
      isInitialized: false,
      isLoading: false,
      user: null,
      pendingProfile: null,
      errorMessage: null,
    );
  }

  AuthState copyWith({
    bool? isInitialized,
    bool? isLoading,
    AppUser? user,
    bool clearUser = false,
    NaverProfileDraft? pendingProfile,
    bool clearPendingProfile = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      pendingProfile: clearPendingProfile
          ? null
          : (pendingProfile ?? this.pendingProfile),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthStore {
  AuthStore._();

  static const String _userKey = 'app_auth_user_v1';
  static const String _draftKey = 'app_auth_pending_naver_profile_v1';

  static final ValueNotifier<AuthState> notifier =
  ValueNotifier<AuthState>(AuthState.initial());

  static AuthState get state => notifier.value;
  static AppUser? get currentUser => notifier.value.user;
  static bool get isSignedIn => notifier.value.user != null;

  static Future<void> initialize() async {
    if (notifier.value.isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    final draftJson = prefs.getString(_draftKey);

    AppUser? user;
    NaverProfileDraft? draft;

    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        user = AppUser.fromMap(decoded);
      } catch (_) {
        await prefs.remove(_userKey);
      }
    }

    if (draftJson != null && draftJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(draftJson) as Map<String, dynamic>;
        draft = NaverProfileDraft.fromMap(decoded);
      } catch (_) {
        await prefs.remove(_draftKey);
      }
    }

    notifier.value = notifier.value.copyWith(
      isInitialized: true,
      user: user,
      pendingProfile: draft,
      clearError: true,
    );
  }

  static Future<bool> signInWithNaver() async {
    notifier.value = notifier.value.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final profile = await NaverAuthService.signIn();

      final existingUser = currentUser;
      if (existingUser != null &&
          existingUser.provider == 'naver' &&
          existingUser.providerUserId == profile.providerUserId) {
        notifier.value = notifier.value.copyWith(
          isLoading: false,
          user: existingUser,
          clearPendingProfile: true,
          clearError: true,
        );
        await _persistUser(existingUser);
        await _clearDraft();
        return false;
      }

      final draft = NaverProfileDraft(
        providerUserId: profile.providerUserId,
        naverNickname: profile.naverNickname,
        name: profile.name,
        phoneNumber: profile.phoneNumber,
        email: profile.email,
      );

      await _persistDraft(draft);

      notifier.value = notifier.value.copyWith(
        isLoading: false,
        pendingProfile: draft,
        clearUser: true,
        clearError: true,
      );

      return true;
    } catch (e) {
      notifier.value = notifier.value.copyWith(
        isLoading: false,
        errorMessage: '네이버 로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.',
      );
      return false;
    }
  }

  static Future<void> completeSignup({
    required String name,
    required String phoneNumber,
    required String cafeNickname,
    bool phoneVerified = false,
  }) async {
    final pending = notifier.value.pendingProfile;
    if (pending == null) {
      throw Exception('가입 대기 중인 네이버 프로필이 없습니다.');
    }

    final now = DateTime.now();

    final user = AppUser(
      provider: 'naver',
      providerUserId: pending.providerUserId,
      naverNickname: pending.naverNickname,
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      cafeNickname: cafeNickname.trim(),
      phoneVerified: phoneVerified,
      cafeMatched: false,
      createdAt: now,
      updatedAt: now,
    );

    await _persistUser(user);
    await _clearDraft();

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      user: user,
      clearPendingProfile: true,
      clearError: true,
    );
  }

  static Future<void> signOut() async {
    try {
      await NaverAuthService.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_draftKey);

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      clearUser: true,
      clearPendingProfile: true,
      clearError: true,
    );
  }

  static Future<void> clearPendingSignup() async {
    await _clearDraft();
    notifier.value = notifier.value.copyWith(
      clearPendingProfile: true,
      clearError: true,
    );
  }

  static Future<void> _persistUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }

  static Future<void> _persistDraft(NaverProfileDraft profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(profile.toMap()));
  }

  static Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}