// Models
export 'models/profile.dart';
export 'models/barber.dart';
export 'models/booking.dart';
export 'models/service.dart';
export 'models/review.dart';
export 'models/availability.dart'; // Contains Availability, TimeSlot, DaySchedule
export 'models/message.dart';

// Config
export 'config/theme.dart';
export 'config/supabase_config.dart';
export 'config/router.dart';

// Services
export 'services/barber_service.dart';
export 'services/booking_service.dart';
export 'services/availability_service.dart';
export 'services/review_service.dart';
export 'services/favorites_service.dart';
export 'services/location_service.dart';
export 'services/message_service.dart'
    hide TypingStatus; // TypingStatus is internal, use TypingIndicator widget
export 'services/service_service.dart';
export 'services/payment_service.dart'
    hide PaymentResultStatus; // Internal enum, use PaymentResult.isSuccess etc.
export 'services/profile_service.dart';
export 'services/notification_service.dart';

// Providers
export 'providers/auth_provider.dart';
export 'providers/barber_provider.dart';
export 'providers/booking_provider.dart';
export 'providers/message_provider.dart';
export 'providers/data_providers.dart';
export 'providers/barber_dashboard_provider.dart';
export 'providers/payment_provider.dart';
export 'providers/profile_provider.dart';

// Note: barberAvailabilityProvider exists in both booking_provider.dart
// and availability_screen.dart - use the specific import when needed.

// Screens - Auth
export 'screens/auth/splash_screen.dart';
export 'screens/auth/login_screen.dart';
export 'screens/auth/register_screen.dart';

// Screens - Customer
export 'screens/customer/customer_home_screen.dart';
export 'screens/customer/barber_list_screen.dart';
export 'screens/customer/barber_profile_screen.dart';
export 'screens/customer/bookings_tab.dart';
export 'screens/customer/messages_tab.dart';
export 'screens/customer/write_review_screen.dart';
export 'screens/customer/booking/select_service_screen.dart';
export 'screens/customer/booking/select_datetime_screen.dart';
export 'screens/customer/booking/booking_confirm_screen.dart';
export 'screens/customer/booking/booking_success_screen.dart';

// Screens - Barber (hide internal types from availability_screen)
export 'screens/barber/barber_dashboard_screen.dart';
export 'screens/barber/dashboard_tab.dart';
export 'screens/barber/clients_tab.dart';
export 'screens/barber/messages_tab.dart';
export 'screens/barber/barber_profile_tab.dart';
export 'screens/barber/availability_screen.dart'
    hide barberAvailabilityProvider, BarberDaySchedule;
export 'screens/barber/earnings_screen.dart';
export 'screens/barber/schedule/schedule_tab.dart';
export 'screens/barber/services/services_screen.dart';
export 'screens/barber/services/add_service_screen.dart';
export 'screens/barber/services/edit_service_screen.dart';

// Screens - Chat
export 'screens/chat/chat_screen.dart';
export 'screens/chat/conversations_screen.dart';

// Screens - Profile & Settings
export 'screens/profile/settings_screen.dart';
export 'screens/profile/edit_profile_screen.dart';
export 'screens/profile/change_password_screen.dart';
export 'screens/profile/payment_methods_screen.dart';
export 'screens/profile/notification_settings_screen.dart';
export 'screens/profile/delete_account_screen.dart';

// Screens - Notifications
export 'screens/notifications/notifications_screen.dart';

// Screens - Legal
export 'screens/legal/privacy_policy_screen.dart';
export 'screens/legal/terms_of_service_screen.dart';
export 'screens/legal/help_center_screen.dart';

// Widgets - Common
export 'widgets/common/dc_button.dart';
export 'widgets/common/loading_widgets.dart';
export 'widgets/forms/dc_text_field.dart';

// Widgets - Chat
export 'widgets/chat/chat_widgets.dart';

// Widgets - Barber (theCut-inspired components)
export 'widgets/barber/barber.dart';
export 'widgets/booking/booking.dart';

// Utils
export 'utils/error_handler.dart';
export 'utils/validators.dart';
export 'utils/formatters.dart';
export 'utils/constants.dart';
export 'utils/deep_link_handler.dart';
