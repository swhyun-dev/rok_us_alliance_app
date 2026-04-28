// lib/features/auth/data/naver_auth_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

class NaverAuthProfile {
  const NaverAuthProfile({
    required this.providerUserId,
    required this.nickname,
    required this.name,
    required this.email,
  });

  final String providerUserId;
  final String nickname;
  final String name;
  final String email;
}

class NaverAuthService {
  const NaverAuthService._();

  /// 네이버 OAuth → Cloud Function Custom Token →
  /// FirebaseAuth.signInWithCustomToken 까지 일괄 처리 후 프로필을 반환한다.
  /// Firebase Auth 상태가 이 호출 이후 활성 상태로 유지됨.
  static Future<NaverAuthProfile> signIn() async {
    final NaverLoginResult result = await FlutterNaverLogin.logIn();

    if (result.status != NaverLoginStatus.loggedIn ||
        result.account == null ||
        result.accessToken == null ||
        result.accessToken!.accessToken.isEmpty) {
      throw Exception('네이버 로그인에 실패했습니다.');
    }

    final NaverAccountResult account = result.account!;
    final String accessToken = result.accessToken!.accessToken;

    final callable =
        FirebaseFunctions.instance.httpsCallable('createCustomTokenFromNaver');
    final cfResult = await callable.call<Map<String, dynamic>>({
      'naverAccessToken': accessToken,
    });

    final customToken = cfResult.data['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      throw Exception('Naver Custom Token을 받지 못했습니다.');
    }

    await FirebaseAuth.instance.signInWithCustomToken(customToken);

    return NaverAuthProfile(
      providerUserId: account.id ?? '',
      nickname: account.nickname ?? '',
      name: account.name ?? '',
      email: account.email ?? '',
    );
  }

  static Future<void> signOut() async {
    try {
      final NaverLoginResult result = await FlutterNaverLogin.logOut();
      if (result.status != NaverLoginStatus.loggedOut) {
        throw Exception('네이버 로그아웃에 실패했습니다.');
      }
    } finally {
      await FirebaseAuth.instance.signOut();
    }
  }
}
