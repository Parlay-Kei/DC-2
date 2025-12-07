import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/barber/barber_dashboard_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash';

      // Still loading auth state
      if (authState.isLoading) return null;

      // Not authenticated and not on auth route
      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      // Authenticated and on auth route (except splash for role detection)
      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        // TODO: Check user role and redirect appropriately
        return '/customer';
      }

      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer',
        name: 'customerHome',
        builder: (context, state) => const CustomerHomeScreen(),
      ),

      // Barber Routes
      GoRoute(
        path: '/barber',
        name: 'barberDashboard',
        builder: (context, state) => const BarberDashboardScreen(),
      ),

      // TODO: Add more routes as screens are built
      // GoRoute(
      //   path: '/barber/:id',
      //   name: 'barberProfile',
      //   builder: (context, state) => BarberProfileScreen(
      //     barberId: state.pathParameters['id']!,
      //   ),
      // ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
