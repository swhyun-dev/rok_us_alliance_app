// lib/features/home/presentation/widgets/count_up_text.dart
import 'package:flutter/material.dart';

/// 0 → target 정수 카운트업 텍스트.
/// target 변경 시 직전 값에서 새 target 으로 부드럽게 이동.
class CountUpText extends StatefulWidget {
  const CountUpText({
    super.key,
    required this.target,
    this.duration = const Duration(milliseconds: 1500),
    this.style,
    this.suffix = '',
    this.formatter,
  });

  final int target;
  final Duration duration;
  final TextStyle? style;
  final String suffix;
  final String Function(int)? formatter;

  @override
  State<CountUpText> createState() => _CountUpTextState();
}

class _CountUpTextState extends State<CountUpText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<int> _animation;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(begin: 0, end: widget.target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CountUpText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _from = _animation.value;
      _animation = IntTween(begin: _from, end: widget.target).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(int value) {
    if (widget.formatter != null) return widget.formatter!(value);
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Text(
          '${_format(_animation.value)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}
