// lib/features/auth/data/auth_store.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_user.dart';
import 'apple_auth_service.dart';
import 'google_auth_service.dart';
import 'kakao_auth_service.dart';
import 'naver_auth_service.dart';

const String _kTermsVersion = 'v1.0';
const String _kPrivacyVersion = 'v1.0';

/// 4가지 소셜 OAuth가 모두 공유하는 가입 임시 데이터.
class SocialSignupDraft {
  const SocialSignupDraft({
    required this.provider,
    required this.providerUserId,
    required this.nickname,
    required this.name,
    this.email,
    this.profileImageUrl,
  });

  /// 'apple' | 'kakao' | 'naver' | 'google'
  final String provider;
  final String providerUserId;
  final String nickname;
  final String name;
  final String? email;
  final String? profileImageUrl;
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

  static const String _userKey = 'app_auth_user_v1';

  static final ValueNotifier<AuthState> notifier =
      ValueNotifier<AuthState>(AuthState.initial());

  static AuthState get state => notifier.value;
  static AppUser? get currentUser => notifier.value.user;
  static bool get isSignedIn => notifier.value.user != null;

  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userDocSub;

  /// users/{firebaseUid} 실시간 구독 시작. 점수/등급/상태 변경 시 AppUser
  /// 캐시와 SharedPreferences 양쪽을 갱신한다.
  static void _attachFirestoreSubscription(String firebaseUid) {
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUid)
        .snapshots()
        .listen(_handleUserDocChange);
  }

  static void _detachFirestoreSubscription() {
    _userDocSub?.cancel();
    _userDocSub = null;
  }

  static Future<void> _handleUserDocChange(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) async {
    if (!snap.exists) return;
    final cached = currentUser;
    if (cached == null) return;
    final data = snap.data() ?? const <String, dynamic>{};

    final lastSignedInTs = data['lastSignedInAt'];
    final updated = cached.copyWith(
      level: (data['level'] as int?) ?? cached.level,
      points: (data['points'] as int?) ?? cached.points,
      nickname: (data['nickname'] as String?) ?? cached.nickname,
      profileImageUrl: data['profileImageUrl'] as String?,
      email: (data['email'] as String?) ?? cached.email,
      isAdmin: (data['isAdmin'] as bool?) ?? cached.isAdmin,
      isBanned: (data['isBanned'] as bool?) ?? cached.isBanned,
      lastSignedInAt: lastSignedInTs is Timestamp
          ? lastSignedInTs.toDate()
          : cached.lastSignedInAt,
      updatedAt: DateTime.now(),
    );

    notifier.value = notifier.value.copyWith(
      user: updated,
      clearError: true,
    );
    await _persistUser(updated);
  }

  static Future<void> debugSignInForDesignPreview() async {
    final now = DateTime.now();

    final user = AppUser(
      provider: 'debug',
      providerUserId: 'debug_preview_user',
      nickname: '자유대한_샘플회원',
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

    // 앱 재시작 후에도 Firebase Auth 세션이 살아 있으면 user doc 구독 재개.
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (user != null && firebaseUid != null) {
      _attachFirestoreSubscription(firebaseUid);
    }
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Provider entry points
  // 모두 동일 계약: 사용자 취소·기존 사용자면 null,
  // 신규 사용자면 SocialSignupDraft 반환 (호출자가 가입 페이지로 전달).
  // 실패 시 errorMessage 세팅 후 null.
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<SocialSignupDraft?> signInWithNaver() async {
    return _runSignIn('네이버', () async {
      final profile = await NaverAuthService.signIn();
      return _resolvePostSignIn(
        provider: 'naver',
        providerUserId: profile.providerUserId,
        nickname: profile.nickname,
        name: profile.name,
        email: profile.email.isEmpty ? null : profile.email,
      );
    });
  }

  static Future<SocialSignupDraft?> signInWithGoogle() async {
    return _runSignIn('Google', () async {
      final user = await GoogleAuthService.signInWithGoogle();
      if (user == null) return null;
      return _resolvePostSignIn(
        provider: 'google',
        providerUserId: _providerDataUid(user, 'google.com') ?? user.uid,
        nickname: user.displayName ?? '',
        name: user.displayName ?? '',
        email: user.email,
        profileImageUrl: user.photoURL,
      );
    });
  }

  static Future<SocialSignupDraft?> signInWithKakao() async {
    return _runSignIn('카카오', () async {
      final user = await KakaoAuthService.signInWithKakao();
      if (user == null) return null;
      // Custom Token UID 형식: 'kakao:{providerUserId}'
      final providerUserId = user.uid.startsWith('kakao:')
          ? user.uid.substring('kakao:'.length)
          : user.uid;
      return _resolvePostSignIn(
        provider: 'kakao',
        providerUserId: providerUserId,
        nickname: user.displayName ?? '',
        name: user.displayName ?? '',
        email: user.email,
        profileImageUrl: user.photoURL,
      );
    });
  }

  static Future<SocialSignupDraft?> signInWithApple() async {
    return _runSignIn('Apple', () async {
      final user = await AppleAuthService.signInWithApple();
      if (user == null) return null;
      return _resolvePostSignIn(
        provider: 'apple',
        providerUserId: _providerDataUid(user, 'apple.com') ?? user.uid,
        nickname: user.displayName ?? '',
        name: user.displayName ?? '',
        email: user.email,
        profileImageUrl: user.photoURL,
      );
    });
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Common signup tail
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// 사용자가 닉네임을 확정한 시점에 호출.
  /// SharedPreferences AppUser 캐시(현 UI 소스) + Firestore users/{uid}
  /// (W2 마이그레이션 대비) 양쪽에 기록한다.
  static Future<void> completeSignup({
    required SocialSignupDraft draft,
    required String nickname,
    required bool agreedTerms,
    required bool agreedPrivacy,
    bool agreedMarketing = false,
  }) async {
    final now = DateTime.now();
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final referralCode = _generateReferralCode();

    final user = AppUser(
      provider: draft.provider,
      providerUserId: draft.providerUserId,
      nickname: nickname,
      name: draft.name,
      email: draft.email,
      profileImageUrl: draft.profileImageUrl,
      createdAt: now,
      updatedAt: now,
      lastSignedInAt: now,
      consentedTerms: agreedTerms,
      consentedPrivacy: agreedPrivacy,
      consentedAt: now,
    );

    await _persistUser(user);

    if (firebaseUid != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .set({
        'uid': firebaseUid,
        'provider': draft.provider,
        'providerUserId': draft.providerUserId,
        'email': draft.email,
        'nickname': nickname,
        'profileImageUrl': draft.profileImageUrl,
        'level': 1,
        'points': 0,
        'consentedTerms': agreedTerms,
        'consentedPrivacy': agreedPrivacy,
        'consentedMarketing': agreedMarketing,
        'consentedAt': FieldValue.serverTimestamp(),
        'termsVersion': _kTermsVersion,
        'privacyVersion': _kPrivacyVersion,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignedInAt': FieldValue.serverTimestamp(),
        'consecutiveCheckInDays': 0,
        'isAdmin': false,
        'isBanned': false,
        'stats': {
          'postsCount': 0,
          'commentsCount': 0,
          'likesReceivedCount': 0,
          'petitionsSignedCount': 0,
          'eventsAttendedCount': 0,
        },
        'referralCode': referralCode,
        'referredBy': null,
      });
      _attachFirestoreSubscription(firebaseUid);
    }

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      user: user,
      clearError: true,
    );
  }

  /// users/{uid}.nickname 으로 중복 검사. 사용 가능하면 true.
  /// (개발 단계 임시 방식 — 추후 nickname → uid 매핑 컬렉션으로 교체.)
  static Future<bool> isNicknameAvailable(String nickname) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  static String _generateReferralCode() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
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
    final provider = currentUser?.provider;

    try {
      switch (provider) {
        case 'naver':
          await NaverAuthService.signOut();
          break;
        case 'kakao':
          await KakaoAuthService.signOut();
          break;
        case 'google':
          await GoogleAuthService.signOut();
          break;
        case 'apple':
        default:
          await FirebaseAuth.instance.signOut();
      }
    } catch (_) {
      // 외부 SDK 로그아웃 실패해도 로컬 세션은 정리.
    }

    _detachFirestoreSubscription();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      clearUser: true,
      clearError: true,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Internal
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static Future<SocialSignupDraft?> _runSignIn(
    String label,
    Future<SocialSignupDraft?> Function() body,
  ) async {
    notifier.value = notifier.value.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      return await body();
    } catch (_) {
      notifier.value = notifier.value.copyWith(
        isLoading: false,
        errorMessage: '$label 로그인 처리 중 오류가 발생했습니다. 다시 시도해주세요.',
      );
      return null;
    }
  }

  /// 기존 사용자면 [AppUser]를 갱신·캐시하고 null. 신규 사용자면 draft 반환.
  static Future<SocialSignupDraft?> _resolvePostSignIn({
    required String provider,
    required String providerUserId,
    required String nickname,
    required String name,
    String? email,
    String? profileImageUrl,
  }) async {
    final existing = currentUser;
    if (existing != null &&
        existing.provider == provider &&
        existing.providerUserId == providerUserId) {
      final updated = existing.copyWith(
        lastSignedInAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _persistUser(updated);
      notifier.value = notifier.value.copyWith(
        isLoading: false,
        user: updated,
        clearError: true,
      );
      final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUid != null) {
        _attachFirestoreSubscription(firebaseUid);
      }
      return null;
    }

    notifier.value = notifier.value.copyWith(
      isLoading: false,
      clearUser: true,
      clearError: true,
    );

    return SocialSignupDraft(
      provider: provider,
      providerUserId: providerUserId,
      nickname: nickname,
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
    );
  }

  static String? _providerDataUid(User user, String providerId) {
    for (final info in user.providerData) {
      if (info.providerId == providerId) return info.uid;
    }
    return null;
  }

  static Future<void> _persistUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
  }
}
