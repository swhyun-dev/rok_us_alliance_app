import 'package:flutter/material.dart';
import '../features/splash/presentation/splash_page.dart';
import 'theme/app_theme.dart';

class ROKUSAllianceApp extends StatelessWidget {
  const ROKUSAllianceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '한미동맹단',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}