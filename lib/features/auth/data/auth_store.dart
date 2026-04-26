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
    this.email,
  });

  final String providerUserId;
  final String naverNickname;
  final String name;
  final String? email;
}

class AuthState {
  const AuthState({
    required this.isInitialized,
    required this.isLoading,
    required this.user,
    required this.errorMessage,
  });

  final bool isInitialized;
  final bool isLoading;
  final AppUser? user;
  final String? errorMessage;

  bool get isSignedIn => user != null;

  factory AuthState.initial() {
    return const AuthState(
      isInitialized: false,
      isLoading: false,
      user: null,
      errorMessage: null,
    );
  }

  AuthState copyWith({
    bool? isInitialized,
    bool? isLoading,
    AppUser? user,
    bool clearUser = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthStore {
  AuthStore._();

  static Future<void> debugSignInForDesignPreview() async {
    final now = DateTime.now();

    final user = AppUser(
      provider: 'debug',
      providerUserId: 'debug_preview_user',
      naverNickname: '자유대한_샘플회원',
      name: '홍길동',
      createdAt: now,
      updatedAt: now,
      lastSignedInAt: now,
      consentedTerms: true,
      consentedPrivacy: true,
      consentedAt: now,
    );

    await _persistUser(user);

    notifier.value = notifier.value.copyWith(
      isInitialized: true,
      isLoading: false,
      user: user,
      clearError: true,
    );
  }

  static const String _userKey = 'app_auth_user_v1';

  static final ValueNotifier<AuthState> notifier =
  ValueNotifier<AuthState>(AuthState.initial());

  static AuthState get state => notifier.value;
  static AppUser? get currentUser => notifier.value.user;
  static bool get isSignedIn => notifier.value.user != null;

  static Future<void> initialize() async {
    if (notifier.value.isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);

    AppUser? user;

    if (userJson != null && userJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        user = AppUser.fromMap(decoded);
      } catch (_) {
        await prefs.remove(_userKey);
      }
    }

    notifier.value = notifier.value.copyWith(
      isInitialized: true,
      user: user,
      clearError: true,
    );
  }

  /// 기존 사용자면 [user]를 갱신하고 null을, 신규 사용자면
  /// [NaverProfileDraft]를 반환한다 (호출자가 가입 페이지로 전달).
  static Future<NaverProfileDraft?> signInWithNaver() async {
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
          clearError: true,
        );
        await _persistUser(existingUser);
        return null;
      }

      notifier.value = notifier.value.copyWith(
        isLoading: false,
        clearUser: true,
        clearError: true,
      );

      return NaverProfileDraft(
        providerUserId: profile.providerUserId,
        naverNickname: profile.naverNickname,
        name: profile.name,
        email: profile.email.isEmpty ? null : profile.email,
      );
    } catch (_) {
      notifier.value = notifier.value.copyWith(
        isLoading: false,
        errorMessage: '네이버 로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.',
      );
      return null;
    }
  }

  static Future<void> completeSignup({
    required NaverProfileDraft draft,
  }) async {
    final now = DateTime.now();

    final user = AppUser(
      provider: 'naver',
      providerUserId: draft.providerUserId,
      naverNickname: draft.naverNickname,
      name: draft.name,
      email: draft.email,
      createdAt: now,
      updatedAt: now,
      lastSignedInAt: now,
      consentedTerms: true,
      consentedPrivacy: true,
      consentedAt: now,
    );

    await _persistUser(user);

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      user: user,
      clearError: true,
    );
  }

  static Future<void> updateProfile({
    String? name,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('로그인된 사용자가 없습니다.');
    }

    notifier.value = notifier.value.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final updatedUser = user.copyWith(
        name: name?.trim(),
        updatedAt: DateTime.now(),
      );

      await _persistUser(updatedUser);

      notifier.value = notifier.value.copyWith(
        isLoading: false,
        user: updatedUser,
        clearError: true,
      );
    } catch (_) {
      notifier.value = notifier.value.copyWith(
        isLoading: false,
        errorMessage: '회원 정보를 저장하지 못했습니다. 다시 시도해주세요.',
      );
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await NaverAuthService.signOut();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      clearUser: true,
      clearError: true,
    );
  }

  static Future<void> _persistUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }
}
