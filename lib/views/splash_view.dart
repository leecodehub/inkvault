import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mobile-only animated splash screen shown once at app startup.
///
/// Logo only, with a "big zoom" entrance. Never shown on web — `main.dart`
/// gates it behind `!kIsWeb`.
class SplashView extends StatefulWidget {
  const SplashView({super.key, required this.onFinished});

  /// Called once the splash has finished and the app should be revealed.
  final VoidCallback onFinished;

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  /// Brand background (matches the native launch screen + launcher icon).
  static const Color _background = Color(0xFFF0F2F5);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  Timer? _finishTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    // Big zoom: start small and pop up to full size.
    _scale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // Keep the splash up briefly so it reads as intentional, then hand off.
    _finishTimer = Timer(
      const Duration(milliseconds: 1800),
      widget.onFinished,
    );
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Big, but never wider than the screen allows.
    final double logoSize = MediaQuery.sizeOf(context).shortestSide * 0.62;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: _background,
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              // The logo asset is transparent, so it blends into the
              // background with no visible box.
              child: Image.asset(
                'lib/images/splash_logo.png',
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
