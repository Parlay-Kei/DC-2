import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/customer/customer_home_screen.dart';
import '../screens/customer/barber_list_screen.dart';
import '../screens/customer/barber_profile_screen.dart';
import '../screens/customer/booking/select_service_screen.dart';
import '../screens/customer/booking/select_datetime_screen.dart';
import '../screens/customer/booking/booking_confirm_screen.dart';
import '../screens/customer/booking/booking_success_screen.dart';
import '../screens/customer/write_review_screen.dart';
import '../screens/barber/barber_dashboard_screen.dart';
import '../screens/barber/services/services_screen.dart';
import '../screens/barber/services/add_service_screen.dart';
import '../screens/barber/services/edit_service_screen.dart';
import '../screens/barber/availability_screen.dart';
import '../screens/barber/earnings_screen.dart';
import '../screens/barber/settings/location_settings_screen.dart';
import '../screens/barber/settings/business_settings_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/chat/conversations_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/payment_methods_screen.dart';
import '../screens/profile/notification_settings_screen.dart';
import '../screens/profile/delete_account_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_of_service_screen.dart';
import '../screens/legal/help_center_screen.dart';
import '../models/booking.dart';
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

      if (authState.isLoading) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/customer';
      }

      return null;
    },
    routes: [
      // ===== AUTH ROUTES =====
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

      // ===== CUSTOMER ROUTES =====
      GoRoute(
        path: '/customer',
        name: 'customerHome',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        path: '/barbers',
        name: 'barberList',
        builder: (context, state) => const BarberListScreen(),
      ),
      GoRoute(
        path: '/barber/:id',
        name: 'barberProfile',
        builder: (context, state) {
          final barberId = state.pathParameters['id']!;
          return BarberProfileScreen(barberId: barberId);
        },
      ),

      // ===== BOOKING FLOW =====
      GoRoute(
        path: '/book/:barberId',
        name: 'selectService',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId']!;
          return SelectServiceScreen(barberId: barberId);
        },
      ),
      GoRoute(
        path: '/book/:barberId/datetime',
        name: 'selectDateTime',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId']!;
          return SelectDateTimeScreen(barberId: barberId);
        },
      ),
      GoRoute(
        path: '/book/:barberId/confirm',
        name: 'bookingConfirm',
        builder: (context, state) {
          final barberId = state.pathParameters['barberId']!;
          return BookingConfirmScreen(barberId: barberId);
        },
      ),
      GoRoute(
        path: '/book/success',
        name: 'bookingSuccess',
        builder: (context, state) {
          final booking = state.extra as Booking;
          return BookingSuccessScreen(booking: booking);
        },
      ),

      // ===== REVIEW ROUTE =====
      GoRoute(
        path: '/review/:bookingId/:barberId',
        name: 'writeReview',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          final barberId = state.pathParameters['barberId']!;
          final barberName = state.uri.queryParameters['barberName'];
          return WriteReviewScreen(
            bookingId: bookingId,
            barberId: barberId,
            barberName: barberName,
          );
        },
      ),

      // ===== CHAT ROUTES =====
      GoRoute(
        path: '/conversations',
        name: 'conversations',
        builder: (context, state) => const ConversationsScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        name: 'chat',
        builder: (context, state) {
          final conversationId = state.pathParameters['conversationId']!;
          final recipientName = state.extra as String?;
          return ChatScreen(
            conversationId: conversationId,
            recipientName: recipientName,
          );
        },
      ),

      // ===== NOTIFICATIONS ROUTE =====
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ===== SETTINGS & PROFILE ROUTES =====
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/settings/change-password',
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/settings/payment-methods',
        name: 'paymentMethods',
        builder: (context, state) => const PaymentMethodsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/delete-account',
        name: 'deleteAccount',
        builder: (context, state) => const DeleteAccountScreen(),
      ),

      // ===== LEGAL ROUTES =====
      GoRoute(
        path: '/privacy-policy',
        name: 'privacyPolicy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/terms-of-service',
        name: 'termsOfService',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      GoRoute(
        path: '/help',
        name: 'helpCenter',
        builder: (context, state) => const HelpCenterScreen(),
      ),

      // ===== BARBER ROUTES =====
      GoRoute(
        path: '/barber-dashboard',
        name: 'barberDashboard',
        builder: (context, state) => const BarberDashboardScreen(),
      ),
      GoRoute(
        path: '/barber/services',
        name: 'barberServices',
        builder: (context, state) => const ServicesScreen(),
      ),
      GoRoute(
        path: '/barber/services/add',
        name: 'addService',
        builder: (context, state) => const AddServiceScreen(),
      ),
      GoRoute(
        path: '/barber/services/edit/:serviceId',
        name: 'editService',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId']!;
          return EditServiceScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: '/barber/availability',
        name: 'barberAvailability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/barber/earnings',
        name: 'barberEarnings',
        builder: (context, state) => const EarningsScreen(),
      ),
      GoRoute(
        path: '/barber/edit-profile',
        name: 'barberEditProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/barber/location-settings',
        name: 'barberLocationSettings',
        builder: (context, state) => const LocationSettingsScreen(),
      ),
      GoRoute(
        path: '/barber/business-settings',
        name: 'barberBusinessSettings',
        builder: (context, state) => const BusinessSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/customer'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
