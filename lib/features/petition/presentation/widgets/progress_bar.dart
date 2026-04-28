// lib/features/petition/presentation/widgets/progress_bar.dart
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PetitionProgressBar extends StatelessWidget {
  const PetitionProgressBar({
    super.key,
    required this.percent,
    this.height = 10,
    this.showLabel = true,
  });

  final int percent; // 0~100
  final double height;
  final bool showLabel;

  Color get _color {
    if (percent >= 80) return AppColors.koreanRed; // 80%+
    if (percent >= 50) return AppColors.gold; // 50%+
    return AppColors.koreanBlue;
  }

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: clamped / 100),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: height,
              backgroundColor: AppColors.softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          Text(
            '$clamped %',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: _color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ],
    );
  }
}
