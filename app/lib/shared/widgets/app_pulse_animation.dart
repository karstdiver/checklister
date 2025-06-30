import 'package:flutter/material.dart';

class AppPulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AppPulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AppPulseAnimation> createState() => _AppPulseAnimationState();
}

class _AppPulseAnimationState extends State<AppPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(scale: _animation.value, child: widget.child);
      },
    );
  }
}
