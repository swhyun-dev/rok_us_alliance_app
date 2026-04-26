// lib/features/auth/data/google_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  const GoogleAuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// 구글 OAuth → Firebase Auth 로그인.
  /// 사용자가 시트를 닫으면 null. 그 외 실패는 Exception.
  static Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) return null;

    final GoogleSignInAuthentication googleAuth = await account.authentication;

    if (googleAuth.idToken == null) {
      throw Exception('Google ID 토큰을 받지 못했습니다.');
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
