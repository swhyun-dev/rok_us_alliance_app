import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// ROK_US Alliance 메인 로고 위젯
///
/// 사용 예:
/// ```dart
/// AllianceEmblem(size: 120) // 기본
/// AllianceEmblem(size: 200, heroTag: 'app-emblem')
/// ```
class AllianceEmblem extends StatelessWidget {
  /// 가로/세로 동일 사이즈 (정사각으로 그려짐)
  final double size;

  /// Hero 애니메이션 태그 (선택)
  final Object? heroTag;

  const AllianceEmblem({
    super.key,
    this.size = 120,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final svg = SvgPicture.asset(
      'assets/svg/logo_dual_flag.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    final wrapped = SizedBox(
      width: size,
      height: size,
      child: svg,
    );

    if (heroTag != null) {
      return Hero(tag: heroTag!, child: wrapped);
    }
    return wrapped;
  }
}
