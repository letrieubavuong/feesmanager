import 'dart:async';

import 'package:flutter/material.dart';

/// Short visual handoff from the platform launch window to the application.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key, required this.child});

  final Widget child;

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  Timer? _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _ready
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : const _BrandedSplash(key: ValueKey('splash')),
    );
  }
}

class _BrandedSplash extends StatefulWidget {
  const _BrandedSplash({super.key});

  @override
  State<_BrandedSplash> createState() => _BrandedSplashState();
}

class _BrandedSplashState extends State<_BrandedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF061A2E),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF061A2E),
                    Color(0xFF0B2B47),
                    Color(0xFF061A2E),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -120,
              right: -110,
              child: Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF22B8F3).withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A84FF).withValues(alpha: 0.07),
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: Curves.easeOut.transform(_controller.value),
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _controller.value)),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: const Color(0xFF123651),
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: const Color(0xFF22B8F3).withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withValues(alpha: 0.18),
                            blurRadius: 36,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFF22B8F3),
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'TUITION 2027',
                      textAlign: TextAlign.center,
                      textScaler: textScale,
                      style: const TextStyle(
                        color: Color(0xFFF4F8FC),
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Quản lý lớp học & học phí',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA9C0D3),
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 24,
              right: 24,
              bottom: 28,
              child: Text(
                'GỌN GÀNG MỖI NGÀY DẠY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7095AD),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
