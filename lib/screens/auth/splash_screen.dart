import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';

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
      final authState = ref.read(authStateProvider);

      authState.when(
        data: (user) async {
          if (user != null) {
            // User is logged in, check their role
            try {
              final profile = await ref.read(currentProfileProvider.future);
              if (!mounted) return;

              if (profile?.isBarber == true) {
                context.go('/barber-dashboard');
              } else {
                context.go('/customer');
              }
            } catch (e) {
              // Profile fetch failed, default to customer
              if (!mounted) return;
              context.go('/customer');
            }
          } else {
            // Not logged in
            if (!mounted) return;
            context.go('/login');
          }
        },
        loading: () {
          // Still loading, retry after a short delay
          Future.delayed(const Duration(milliseconds: 500), _checkAuthAndNavigate);
        },
        error: (_, __) {
          if (!mounted) return;
          context.go('/login');
        },
      );
    } catch (e) {
      if (!mounted) return;
      context.go('/login');
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
                    // Logo - DC SVG
                    SvgPicture.asset(
                      'assets/images/dc_logo.svg',
                      width: 140,
                      height: 140,
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
