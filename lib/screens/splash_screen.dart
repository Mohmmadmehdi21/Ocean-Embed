import 'dart:async';
import 'package:flutter/material.dart';
import '../dashboard_screen.dart';
import '../widgets/ocean_logo.dart';

class OceanEmbedSplashScreen extends StatefulWidget {
  const OceanEmbedSplashScreen({super.key});

  @override
  State<OceanEmbedSplashScreen> createState() => _OceanEmbedSplashScreenState();
}

class _OceanEmbedSplashScreenState extends State<OceanEmbedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _statusText = 'Harmonizing multi-source satellite datasets...';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _updateProgressSteps();

    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) =>
              const DashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  void _updateProgressSteps() {
    Timer(const Duration(milliseconds: 700), () {
      if (mounted) {
        setState(() {
          _statusText = 'Generating 128-D Satellite Embeddings (0.25° Grid)...';
        });
      }
    });
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _statusText = 'Validating 15-Depth Subsurface Profiles with ARGO Floats...';
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071426), // Deep ocean dark theme for splash
      body: SafeArea(
        child: Stack(
          children: [
            // Background ambient glow
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF147BEF).withValues(alpha: 0.18),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -100,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C6FF).withValues(alpha: 0.12),
                ),
              ),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const OceanEmbedLogo(size: 96, showGlow: true),
                        const SizedBox(height: 24),
                        const Text(
                          'OceanEmbed',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF147BEF).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF147BEF).withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Text(
                            'AI-POWERED OCEAN INTELLIGENCE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF38BDF8),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Satellite Embedding-Based Deep Learning Framework for Reconstruction of Subsurface Ocean Temperature',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 38),
                        // Loading indicator
                        SizedBox(
                          width: 180,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              backgroundColor: Color(0xFF1E293B),
                              color: Color(0xFF38BDF8),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _statusText,
                            key: ValueKey(_statusText),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom footer
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Text(
                'North Indian Ocean PoC (Arabian Sea & Bay of Bengal)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
