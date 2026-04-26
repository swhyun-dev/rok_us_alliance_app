// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app/app.dart';
import 'firebase_options.dart';

// Kakao Native App Key는 빌드 시 --dart-define으로 주입.
//   flutter run --dart-define=KAKAO_NATIVE_APP_KEY=xxx
// 미주입 시 SDK는 초기화되지 않고 Kakao 로그인 시도가 명확히 실패한다.
const String _kakaoNativeAppKey = String.fromEnvironment(
  'KAKAO_NATIVE_APP_KEY',
  defaultValue: '',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_kakaoNativeAppKey.isNotEmpty) {
    KakaoSdk.init(nativeAppKey: _kakaoNativeAppKey);
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ROKUSAllianceApp());
}
