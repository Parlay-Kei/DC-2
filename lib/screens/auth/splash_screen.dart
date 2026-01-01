import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/startup_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _checkAuthAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Load startup state
      final startupState = await ref.read(appStartupProvider.future);

      if (!mounted) return;

      final hasSeenWelcome = startupState.hasSeenWelcome;
      final hasSession = startupState.hasSession;
      final role = startupState.role;

      // Debug log as requested
      print('Startup: seenWelcome=$hasSeenWelcome, hasSession=$hasSession, role=$role');

      // Routing rules:
      // 1. If hasn't seen welcome -> Welcome screen
      // 2. Else if no session -> Login
      // 3. Else -> Home (role-aware: /customer or /barber-dashboard)

      if (!hasSeenWelcome) {
        context.go('/welcome');
      } else if (!hasSession) {
        context.go('/login');
      } else {
        // User is authenticated, navigate based on role
        if (role == 'barber') {
          context.go('/barber-dashboard');
        } else {
          context.go('/customer');
        }
      }
    } catch (e) {
      // On error, default to welcome screen for new users
      if (!mounted) return;
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DCTheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo - DC SVG with explicit white color for visibility on dark background
                    SvgPicture.asset(
                      'assets/images/dc_logo.svg',
                      width: 140,
                      height: 140,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App name
                    const Text(
                      'Direct Cuts',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.text,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tagline
                    Text(
                      'Book your barber',
                      style: TextStyle(
                        fontSize: 16,
                        color: DCTheme.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading indicator
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DCTheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
