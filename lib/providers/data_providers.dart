import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/favorites_service.dart';
import '../services/review_service.dart';
import '../services/service_service.dart';
import '../models/barber.dart';
import '../models/service.dart';
import '../models/review.dart';

// Service providers
final favoritesServiceProvider = Provider((ref) => FavoritesService());
final reviewServiceProvider = Provider((ref) => ReviewService());
final serviceServiceProvider = Provider((ref) => ServiceService());

// ===== FAVORITES =====

// User's favorite barbers
final favoriteBarbersProvider = FutureProvider<List<Barber>>((ref) {
  return ref.read(favoritesServiceProvider).getFavorites();
});

// Set of favorite barber IDs for quick lookup
final favoriteIdsProvider = FutureProvider<Set<String>>((ref) {
  return ref.read(favoritesServiceProvider).getFavoriteIds();
});

// Check if specific barber is favorited
final isFavoriteProvider = FutureProvider.family<bool, String>((ref, barberId) {
  return ref.read(favoritesServiceProvider).isFavorite(barberId);
});

// ===== REVIEWS =====

// Reviews for a barber
final reviewsProvider =
    FutureProvider.family<List<Review>, String>((ref, barberId) {
  return ref.read(reviewServiceProvider).getBarberReviews(barberId);
});

// Rating stats for a barber
final ratingStatsProvider =
    FutureProvider.family<RatingStats, String>((ref, barberId) {
  return ref.read(reviewServiceProvider).getBarberRatingStats(barberId);
});

// Check if user can review a booking
final canReviewProvider = FutureProvider.family<bool, String>((ref, bookingId) {
  return ref.read(reviewServiceProvider).canReview(bookingId);
});

// User's own reviews
final myReviewsProvider = FutureProvider<List<Review>>((ref) {
  return ref.read(reviewServiceProvider).getMyReviews();
});

// ===== SERVICES =====

// Services for a barber
final servicesProvider =
    FutureProvider.family<List<Service>, String>((ref, barberId) {
  return ref.read(serviceServiceProvider).getBarberServices(barberId);
});

// Current barber's services (for barber dashboard)
final myServicesProvider = FutureProvider<List<Service>>((ref) {
  return ref.read(serviceServiceProvider).getMyServices();
});

// Service categories for a barber
final serviceCategoriesProvider =
    FutureProvider.family<List<String>, String>((ref, barberId) {
  return ref.read(serviceServiceProvider).getServiceCategories(barberId);
});

// Default service templates
final serviceTemplatesProvider = Provider<List<ServiceTemplate>>((ref) {
  return ref.read(serviceServiceProvider).getDefaultTemplates();
});
