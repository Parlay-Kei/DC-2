import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/service.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/data_providers.dart';

class SelectServiceScreen extends ConsumerWidget {
  final String barberId;

  const SelectServiceScreen({super.key, required this.barberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider(barberId));
    final selectedService = ref.watch(bookingFlowProvider).selectedService;

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Select Service'),
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return const Center(
              child: Text(
                'No services available',
                style: TextStyle(color: DCTheme.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final isSelected = selectedService?.id == service.id;
              return _ServiceCard(
                service: service,
                isSelected: isSelected,
                onTap: () {
                  ref.read(bookingFlowProvider.notifier).selectService(service);
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref, selectedService),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    Service? selectedService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedService != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedService.name,
                    style: const TextStyle(
                      color: DCTheme.text,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    selectedService.formattedPrice,
                    style: const TextStyle(
                      color: DCTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedService != null
                    ? () => context.push('/book/$barberId/datetime')
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: DCTheme.surfaceSecondary,
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? DCTheme.primary.withValues(alpha: 0.1) : DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? DCTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DCTheme.text,
                        ),
                      ),
                      if (service.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          service.description!,
                          style: const TextStyle(
                            color: DCTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: DCTheme.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            service.formattedDuration,
                            style: const TextStyle(
                              color: DCTheme.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      service.formattedPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: DCTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? DCTheme.primary : DCTheme.textMuted,
                          width: 2,
                        ),
                        color: isSelected ? DCTheme.primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
