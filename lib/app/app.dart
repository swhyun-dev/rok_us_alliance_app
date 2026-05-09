import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// SplashScreen 자체는 onComplete 콜백만 제공한다. 인증 초기화·SharedPreferences
/// 조회는 애니메이션과 병렬로 시작해 splash 가 끝났을 때 둘 다 준비된 상태에서 분기.
///
/// 첫 진입(또는 앱 데이터 초기화 후 첫 진입)에서는 풀 4.6s RPG 시퀀스, 이후
/// 재진입에서는 1.5s 짧은 fade-in 시퀀스를 표시한다.
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  static const _splashFullSeenKey = 'splash_full_seen';

  late final Future<void> _authReady;
  SplashMode? _resolvedMode;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _authReady = AuthStore.initialize();
    _resolveMode();
  }

  Future<void> _resolveMode() async {
    SplashMode mode = SplashMode.full;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_splashFullSeenKey) ?? false;
      if (seen) mode = SplashMode.short;
    } catch (_) {
      // prefs 접근 실패 시 안전하게 full 유지.
    }
    if (mounted) {
      setState(() => _resolvedMode = mode);
    }
  }

  Future<void> _handleSplashComplete() async {
    if (_navigated) return;
    await _authReady;
    if (!mounted || _navigated) return;
    _navigated = true;

    // Full 시퀀스가 끝까지 재생됐을 때만 "본 적 있음" 으로 표시. 사용자가 도중
    // 종료한 경우 다음 진입에서도 full 을 다시 보여주는 게 자연스럽다.
    if (_resolvedMode == SplashMode.full) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_splashFullSeenKey, true);
      } catch (_) {
        // 저장 실패는 분기 동작에 영향 없도록 무시.
      }
    }

    if (!mounted) return;

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
    final mode = _resolvedMode;
    if (mode == null) {
      // SharedPreferences 로드 동안 다크 placeholder. 실제 splash 배경 그라디언트
      // 첫 색상과 동일 톤이라 사용자가 인지하지 않는 한순간.
      return const Scaffold(backgroundColor: Colors.black);
    }
    return SplashScreen(
      mode: mode,
      onComplete: _handleSplashComplete,
    );
  }
}
