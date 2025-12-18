import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/booking_service.dart';
import '../services/availability_service.dart';
import '../models/booking.dart';
import '../models/availability.dart';
import '../models/service.dart';

// Service providers
final bookingServiceProvider = Provider((ref) => BookingService());
final availabilityServiceProvider = Provider((ref) => AvailabilityService());

// Customer's upcoming bookings
final upcomingBookingsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(bookingServiceProvider).getCustomerBookings(upcoming: true);
});

// Customer's booking history
final bookingHistoryProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(bookingServiceProvider).getBookingHistory();
});

// Barber's today appointments
final todayAppointmentsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(bookingServiceProvider).getBarberBookings(todayOnly: true);
});

// Barber's all appointments
final barberAppointmentsProvider = FutureProvider<List<Booking>>((ref) {
  return ref.read(bookingServiceProvider).getBarberBookings();
});

// Single booking details
final bookingDetailsProvider =
    FutureProvider.family<BookingWithDetails?, String>((ref, bookingId) {
  return ref.read(bookingServiceProvider).getBookingDetails(bookingId);
});

// Barber availability
final barberAvailabilityProvider =
    FutureProvider.family<List<Availability>, String>((ref, barberId) {
  return ref.read(availabilityServiceProvider).getBarberAvailability(barberId);
});

// Available time slots for a date
final availableSlotsProvider =
    FutureProvider.family<DaySchedule, AvailabilityRequest>((ref, request) {
  return ref.read(availabilityServiceProvider).getAvailableSlots(
        request.barberId,
        request.date,
      );
});

class AvailabilityRequest {
  final String barberId;
  final DateTime date;

  AvailabilityRequest({required this.barberId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityRequest &&
          barberId == other.barberId &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day;

  @override
  int get hashCode => barberId.hashCode ^ date.hashCode;
}

// Week schedule
final weekScheduleProvider =
    FutureProvider.family<List<DaySchedule>, String>((ref, barberId) {
  final startDate = DateTime.now();
  return ref.read(availabilityServiceProvider).getWeekSchedule(
        barberId,
        startDate,
        days: 14, // Two weeks ahead
      );
});

// ===== BOOKING FLOW STATE =====

// Selected service for booking
final selectedServiceProvider = StateProvider<Service?>((ref) => null);

// Selected date for booking
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);

// Selected time for booking
final selectedTimeProvider = StateProvider<String?>((ref) => null);

// Selected payment method
final selectedPaymentMethodProvider = StateProvider<String>((ref) => 'card');

// Booking notes
final bookingNotesProvider = StateProvider<String>((ref) => '');

// Location type (shop vs mobile)
final locationTypeProvider = StateProvider<String>((ref) => 'shop');

// Mobile booking address
final mobileAddressProvider = StateProvider<String?>((ref) => null);

// Booking creation state
final createBookingProvider = FutureProvider.autoDispose<Booking?>((ref) async {
  // This provider shouldn't auto-run; it's triggered manually
  return null;
});

// Booking flow notifier
class BookingFlowNotifier extends StateNotifier<BookingFlowState> {
  final BookingService _bookingService;

  BookingFlowNotifier(this._bookingService) : super(BookingFlowState.initial());

  void selectService(Service service) {
    state = state.copyWith(selectedService: service);
  }

  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date, selectedTime: null);
  }

  void selectTime(String time) {
    state = state.copyWith(selectedTime: time);
  }

  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  void setLocationType(String type) {
    state = state.copyWith(locationType: type);
  }

  void setAddress(String? address) {
    state = state.copyWith(address: address);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void reset() {
    state = BookingFlowState.initial();
  }

  bool get canProceed {
    return state.selectedService != null &&
        state.selectedDate != null &&
        state.selectedTime != null;
  }

  Future<Booking?> createBooking(String barberId) async {
    if (!canProceed) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final booking = await _bookingService.createBooking(
        barberId: barberId,
        serviceId: state.selectedService!.id,
        date: state.selectedDate!,
        time: state.selectedTime!,
        paymentMethod: state.paymentMethod,
        locationType: state.locationType,
        address: state.address,
        notes: state.notes.isEmpty ? null : state.notes,
      );

      if (booking != null) {
        state = state.copyWith(isLoading: false, createdBooking: booking);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create booking',
        );
      }

      return booking;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

class BookingFlowState {
  final Service? selectedService;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String paymentMethod;
  final String locationType;
  final String? address;
  final String notes;
  final bool isLoading;
  final String? error;
  final Booking? createdBooking;

  BookingFlowState({
    this.selectedService,
    this.selectedDate,
    this.selectedTime,
    this.paymentMethod = 'card',
    this.locationType = 'shop',
    this.address,
    this.notes = '',
    this.isLoading = false,
    this.error,
    this.createdBooking,
  });

  factory BookingFlowState.initial() => BookingFlowState();

  BookingFlowState copyWith({
    Service? selectedService,
    DateTime? selectedDate,
    String? selectedTime,
    String? paymentMethod,
    String? locationType,
    String? address,
    String? notes,
    bool? isLoading,
    String? error,
    Booking? createdBooking,
  }) {
    return BookingFlowState(
      selectedService: selectedService ?? this.selectedService,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      locationType: locationType ?? this.locationType,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }
}

final bookingFlowProvider =
    StateNotifierProvider<BookingFlowNotifier, BookingFlowState>((ref) {
  return BookingFlowNotifier(ref.read(bookingServiceProvider));
});
