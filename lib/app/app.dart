import 'package:flutter/material.dart';

import '../features/auth/data/auth_store.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/home/presentation/home_page.dart';
import '../screens/splash_screen.dart';
import 'theme/app_theme.dart';

class ROKUSAllianceApp extends StatelessWidget {
  const ROKUSAllianceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한미동맹단',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _SplashGate(),
    );
  }
}

/// 브랜드 SplashScreen 진입점 게이트.
///
/// SplashScreen 자체는 onComplete 콜백만 제공한다. 인증 초기화는 애니메이션과
/// 병렬로 시작해 splash가 끝났을 때 둘 다 준비된 상태에서 분기한다.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  late final Future<void> _authReady;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _authReady = AuthStore.initialize();
  }

  Future<void> _handleSplashComplete() async {
    if (_navigated) return;
    await _authReady;
    if (!mounted || _navigated) return;
    _navigated = true;

    final nextPage = AuthStore.isSignedIn
        ? const HomePage(showIntroPopup: true)
        : const LoginPage();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, __) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: const Interval(0.10, 1.0, curve: Curves.easeOut),
            ),
            child: nextPage,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SplashScreen(onComplete: _handleSplashComplete);
  }
}
