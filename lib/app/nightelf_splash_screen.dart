import 'dart:async';

import 'package:flutter/widgets.dart';

class NightelfSplashScreen extends StatefulWidget {
  const NightelfSplashScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<NightelfSplashScreen> createState() => _NightelfSplashScreenState();
}

class _NightelfSplashScreenState extends State<NightelfSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Timer _finishTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: 1), weight: 22),
      TweenSequenceItem(tween: ConstantTween<double>(1), weight: 56),
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0), weight: 22),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
    _finishTimer = Timer(const Duration(milliseconds: 900), _finish);
  }

  void _finish() {
    if (mounted) {
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _finishTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('nightelf-splash-screen'),
      color: const Color(0xFF030B09),
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: Image.asset(
            'assets/nightelf-logo.png',
            key: const ValueKey('nightelf-splash-logo'),
            width: 128,
            height: 128,
            fit: BoxFit.contain,
            semanticLabel: 'Nightelf Logo',
          ),
        ),
      ),
    );
  }
}
