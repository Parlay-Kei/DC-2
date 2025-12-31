import '../config/supabase_config.dart';
import '../models/service.dart';

class ServiceService {
  final _client = SupabaseConfig.client;

  /// Get all services for a barber
  Future<List<Service>> getBarberServices(String barberId) async {
    try {
      final response = await _client
          .from('barber_services')
          .select()
          .eq('barber_id', barberId)
          .eq('is_active', true)
          .order('price', ascending: true);

      return (response as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get a single service by ID
  Future<Service?> getService(String serviceId) async {
    try {
      final response = await _client
          .from('barber_services')
          .select()
          .eq('id', serviceId)
          .single();

      return Service.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new service (barber action)
  Future<Service?> createService({
    required String barberId,
    required String name,
    String? description,
    required double price,
    required int duration,
    String? category,
  }) async {
    try {
      final response = await _client
          .from('barber_services')
          .insert({
            'barber_id': barberId,
            'name': name,
            'description': description,
            'price': price,
            'duration': duration,
            'category': category,
            'is_active': true,
          })
          .select()
          .single();

      return Service.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Update a service (barber action)
  Future<bool> updateService({
    required String serviceId,
    String? name,
    String? description,
    double? price,
    int? duration,
    String? category,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (price != null) updates['price'] = price;
      if (duration != null) updates['duration'] = duration;
      if (category != null) updates['category'] = category;
      if (isActive != null) updates['is_active'] = isActive;

      await _client.from('barber_services').update(updates).eq('id', serviceId);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a service (soft delete)
  Future<bool> deleteService(String serviceId) async {
    try {
      await _client
          .from('barber_services')
          .update({'is_active': false}).eq('id', serviceId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reactivate a service
  Future<bool> activateService(String serviceId) async {
    return updateService(serviceId: serviceId, isActive: true);
  }

  /// Get all services for current barber (including inactive)
  Future<List<Service>> getMyServices({bool includeInactive = false}) async {
    final barberId = SupabaseConfig.currentUserId;
    if (barberId == null) return [];

    try {
      var query =
          _client.from('barber_services').select().eq('barber_id', barberId);

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      final response = await query.order('price', ascending: true);

      return (response as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get services by category
  Future<List<Service>> getServicesByCategory(
    String barberId,
    String category,
  ) async {
    try {
      final response = await _client
          .from('barber_services')
          .select()
          .eq('barber_id', barberId)
          .eq('category', category)
          .eq('is_active', true)
          .order('price', ascending: true);

      return (response as List).map((s) => Service.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get service categories for a barber
  Future<List<String>> getServiceCategories(String barberId) async {
    try {
      final response = await _client
          .from('barber_services')
          .select('category')
          .eq('barber_id', barberId)
          .eq('is_active', true)
          .not('category', 'is', null);

      final categories = (response as List)
          .map((s) => s['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      return [];
    }
  }

  /// Get default service templates
  List<ServiceTemplate> getDefaultTemplates() {
    return [
      ServiceTemplate(
        name: 'Regular Haircut',
        description: 'Classic haircut with clippers and scissors',
        price: 25.00,
        duration: 30,
        category: 'Haircuts',
      ),
      ServiceTemplate(
        name: 'Fade',
        description: 'Precision fade with clean lines',
        price: 30.00,
        duration: 45,
        category: 'Haircuts',
      ),
      ServiceTemplate(
        name: 'Beard Trim',
        description: 'Beard shaping and trimming',
        price: 15.00,
        duration: 20,
        category: 'Beard',
      ),
      ServiceTemplate(
        name: 'Hot Towel Shave',
        description: 'Traditional straight razor shave with hot towel',
        price: 35.00,
        duration: 40,
        category: 'Shaves',
      ),
      ServiceTemplate(
        name: 'Haircut + Beard',
        description: 'Full haircut with beard trim combo',
        price: 40.00,
        duration: 50,
        category: 'Combos',
      ),
      ServiceTemplate(
        name: 'Kids Haircut',
        description: 'Haircut for children under 12',
        price: 20.00,
        duration: 25,
        category: 'Kids',
      ),
      ServiceTemplate(
        name: 'Line Up',
        description: 'Edge up and line work only',
        price: 15.00,
        duration: 15,
        category: 'Haircuts',
      ),
    ];
  }

  /// Create service from template
  Future<Service?> createFromTemplate(
      String barberId, ServiceTemplate template) async {
    return createService(
      barberId: barberId,
      name: template.name,
      description: template.description,
      price: template.price,
      duration: template.duration,
      category: template.category,
    );
  }
}

class ServiceTemplate {
  final String name;
  final String? description;
  final double price;
  final int duration;
  final String? category;

  ServiceTemplate({
    required this.name,
    this.description,
    required this.price,
    required this.duration,
    this.category,
  });
}
