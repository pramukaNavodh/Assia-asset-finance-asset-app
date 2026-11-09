import 'package:flutter/material.dart';

// Counts up from 0 on first show, then glides to new values when they change.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
  });

  final double value;
  final String Function(double) formatter;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(formatter(v), style: style),
    );
  }
}