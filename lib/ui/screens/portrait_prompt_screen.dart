import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Portrait Prompt Screen (FR3)
/// Displays animated instruction to rotate device to landscape
class PortraitPromptScreen extends StatefulWidget {
  const PortraitPromptScreen({super.key});

  @override
  State<PortraitPromptScreen> createState() => _PortraitPromptScreenState();
}

class _PortraitPromptScreenState extends State<PortraitPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: math.pi / 2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Icon(
                      Icons.phone_iphone,
                      size: 120,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),
            Text(
              'Rotate Device',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Switch to Landscape Mode',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 16,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
