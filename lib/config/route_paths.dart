/// Centralized route path definitions
/// This ensures route names are consistent across the app and prevents typos
class RoutePaths {
  // Auth routes
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelect = '/role-select';

  // Customer routes
  static const String customer = '/customer';
  static const String customerBookings = '/customer/bookings';
  static const String barbers = '/barbers';

  // Booking flow
  static String barberProfile(String barberId) => '/barber/$barberId';
  static String selectService(String barberId) => '/book/$barberId';
  static String selectDateTime(String barberId) => '/book/$barberId/datetime';
  static String bookingConfirm(String barberId) => '/book/$barberId/confirm';
  static const String bookingSuccess = '/book/success';

  // Review
  static String writeReview(String bookingId, String barberId) =>
      '/review/$bookingId/$barberId';

  // Chat routes
  static const String conversations = '/conversations';
  static String chat(String conversationId) => '/chat/$conversationId';

  // Notifications
  static const String notifications = '/notifications';

  // Settings & Profile routes
  static const String settings = '/settings';
  static const String editProfile = '/settings/edit-profile';
  static const String changePassword = '/settings/change-password';
  static const String paymentMethods = '/settings/payment-methods';
  static const String notificationSettings = '/settings/notifications';
  static const String deleteAccount = '/settings/delete-account';
  static const String buildInfo = '/settings/build-info';
  static const String bookingHistory = '/settings/booking-history';
  static const String favorites = '/settings/favorites';
  static const String contactSupport = '/settings/contact-support';

  // Legal routes
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String help = '/help';

  // Common routes
  static const String comingSoon = '/coming-soon';

  // Barber routes
  static const String barberDashboard = '/barber-dashboard';
  static const String barberServices = '/barber/services';
  static const String barberServicesAdd = '/barber/services/add';
  static String barberServicesEdit(String serviceId) =>
      '/barber/services/edit/$serviceId';
  static const String barberAvailability = '/barber/availability';
  static const String barberEarnings = '/barber/earnings';
  static const String barberEditProfile = '/barber/edit-profile';
  static const String barberLocationSettings = '/barber/location-settings';
  static const String barberBusinessSettings = '/barber/business-settings';
}
