// lib/features/auth/data/naver_auth_service.dart
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:flutter_naver_login/interface/types/naver_account_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_result.dart';
import 'package:flutter_naver_login/interface/types/naver_login_status.dart';

class NaverAuthProfile {
  const NaverAuthProfile({
    required this.providerUserId,
    required this.naverNickname,
    required this.name,
    required this.phoneNumber,
    required this.email,
  });

  final String providerUserId;
  final String naverNickname;
  final String name;
  final String phoneNumber;
  final String email;
}

class NaverAuthService {
  const NaverAuthService._();

  static Future<NaverAuthProfile> signIn() async {
    final NaverLoginResult result = await FlutterNaverLogin.logIn();

    if (result.status != NaverLoginStatus.loggedIn || result.account == null) {
      throw Exception('네이버 로그인에 실패했습니다.');
    }

    final NaverAccountResult account = result.account!;

    return NaverAuthProfile(
      providerUserId: account.id ?? '',
      naverNickname: account.nickname ?? '',
      name: account.name ?? '',
      phoneNumber: _extractPhoneNumber(account),
      email: account.email ?? '',
    );
  }

  static Future<void> signOut() async {
    final NaverLoginResult result = await FlutterNaverLogin.logOut();

    if (result.status != NaverLoginStatus.loggedOut) {
      throw Exception('네이버 로그아웃에 실패했습니다.');
    }
  }

  static Future<NaverAuthProfile?> getCurrentProfile() async {
    try {
      final NaverAccountResult account =
      await FlutterNaverLogin.getCurrentAccount();

      return NaverAuthProfile(
        providerUserId: account.id ?? '',
        naverNickname: account.nickname ?? '',
        name: account.name ?? '',
        phoneNumber: _extractPhoneNumber(account),
        email: account.email ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  static String _extractPhoneNumber(NaverAccountResult account) {
    final mobile = (account.mobile ?? '').trim();
    final mobileE164 = (account.mobileE164 ?? '').trim();

    if (mobile.isNotEmpty) return mobile;
    if (mobileE164.isNotEmpty) return mobileE164;
    return '';
  }
}