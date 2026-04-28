// lib/features/settings/presentation/terms_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../app/theme/app_colors.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalDocPage(
      title: '이용약관',
      assetPath: 'assets/legal/terms_v1.md',
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _LegalDocPage(
      title: '개인정보처리방침',
      assetPath: 'assets/legal/privacy_v1.md',
    );
  }
}

class _LegalDocPage extends StatelessWidget {
  const _LegalDocPage({required this.title, required this.assetPath});

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '문서를 불러오지 못했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.koreanRed),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Markdown(
            data: snapshot.data!,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              h2: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
              p: const TextStyle(
                fontSize: 14,
                height: 1.65,
                color: AppColors.textPrimary,
              ),
              blockquote: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                backgroundColor: AppColors.softBlue.withValues(alpha: 0.4),
              ),
              tableHead: const TextStyle(fontWeight: FontWeight.w800),
              tableBody: const TextStyle(fontSize: 13),
              tableBorder: TableBorder.all(color: AppColors.border),
            ),
          );
        },
      ),
    );
  }
}
