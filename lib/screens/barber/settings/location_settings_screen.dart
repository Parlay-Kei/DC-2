import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../providers/barber_crm_provider.dart';

class LocationSettingsScreen extends ConsumerStatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  ConsumerState<LocationSettingsScreen> createState() =>
      _LocationSettingsScreenState();
}

class _LocationSettingsScreenState
    extends ConsumerState<LocationSettingsScreen> {
  final _addressController = TextEditingController();
  final _radiusController = TextEditingController();
  final _travelFeeController = TextEditingController();

  bool _isMobile = false;
  bool _offersHomeService = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _addressController.dispose();
    _radiusController.dispose();
    _travelFeeController.dispose();
    super.dispose();
  }

  void _initializeForm(barber) {
    if (_isInitialized || barber == null) return;

    _addressController.text = barber.shopAddress ?? '';
    _radiusController.text = barber.serviceRadiusMiles.toString();
    _travelFeeController.text =
        barber.travelFeePerMile?.toStringAsFixed(2) ?? '2.00';
    _isMobile = barber.isMobile;
    _offersHomeService = barber.offersHomeService;
    _isInitialized = true;
  }

  Future<void> _useCurrentLocation() async {
    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateLocationFromGPS();

    if (mounted) {
      if (success) {
        // Refresh to get updated address
        final barber = ref.read(barberCrmProvider).barber;
        if (barber?.shopAddress != null) {
          _addressController.text = barber!.shopAddress!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated from GPS'),
            backgroundColor: DCTheme.success,
          ),
        );
      } else {
        final error = ref.read(barberCrmProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to get location'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an address'),
          backgroundColor: DCTheme.error,
        ),
      );
      return;
    }

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateLocationFromAddress(address);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully'),
            backgroundColor: DCTheme.success,
          ),
        );
      } else {
        final error = ref.read(barberCrmProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to save address'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveServiceSettings() async {
    final radius = int.tryParse(_radiusController.text) ?? 10;
    final travelFee = double.tryParse(_travelFeeController.text) ?? 2.0;

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateServiceSettings(
      isMobile: _isMobile,
      offersHomeService: _offersHomeService,
      serviceRadiusMiles: radius,
      travelFeePerMile: travelFee,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service settings saved'),
            backgroundColor: DCTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save settings'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DCTheme.surface,
        title: const Text('Clear Location?',
            style: TextStyle(color: DCTheme.text)),
        content: const Text(
          'This will remove your saved location. Customers won\'t be able to find you by location until you set a new one.',
          style: TextStyle(color: DCTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: DCTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.clearLocation();

    if (mounted && success) {
      _addressController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location cleared'),
          backgroundColor: DCTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crmState = ref.watch(barberCrmProvider);
    final barber = crmState.barber;

    _initializeForm(barber);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Location Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: crmState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: DCTheme.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Status Card
                  _buildLocationStatusCard(barber),
                  const SizedBox(height: 24),

                  // Address Section
                  _buildSectionHeader('Business Address'),
                  const SizedBox(height: 12),
                  _buildAddressSection(),
                  const SizedBox(height: 24),

                  // Service Type Section
                  _buildSectionHeader('Service Type'),
                  const SizedBox(height: 12),
                  _buildServiceTypeSection(),
                  const SizedBox(height: 24),

                  // Travel Settings (visible when mobile/home service)
                  if (_isMobile || _offersHomeService) ...[
                    _buildSectionHeader('Travel Settings'),
                    const SizedBox(height: 12),
                    _buildTravelSettingsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          crmState.isSaving ? null : _saveServiceSettings,
                      child: crmState.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationStatusCard(barber) {
    final hasLocation = barber?.hasLocation ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasLocation
            ? DCTheme.success.withValues(alpha: 0.1)
            : DCTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLocation
              ? DCTheme.success.withValues(alpha: 0.3)
              : DCTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasLocation ? Icons.check_circle : Icons.warning_amber_rounded,
            color: hasLocation ? DCTheme.success : DCTheme.warning,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation ? 'Location Set' : 'Location Not Set',
                  style: TextStyle(
                    color: hasLocation ? DCTheme.success : DCTheme.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasLocation
                      ? 'Customers can find you by location'
                      : 'Set your location so customers can find you',
                  style: const TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: DCTheme.text,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAddressSection() {
    final crmState = ref.watch(barberCrmProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _addressController,
            style: const TextStyle(color: DCTheme.text),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Business Address',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: '123 Main St, City, State ZIP',
              hintStyle:
                  TextStyle(color: DCTheme.textMuted.withValues(alpha: 0.5)),
              prefixIcon:
                  const Icon(Icons.location_on, color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: crmState.isSaving ? null : _useCurrentLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Use GPS'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DCTheme.info,
                    side: const BorderSide(color: DCTheme.info),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: crmState.isSaving ? null : _saveAddress,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save Address'),
                ),
              ),
            ],
          ),
          if (ref.watch(barberCrmProvider).barber?.hasLocation == true) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearLocation,
              icon: const Icon(Icons.clear, size: 18, color: DCTheme.error),
              label: const Text(
                'Clear Location',
                style: TextStyle(color: DCTheme.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.store,
            title: 'Shop-Based',
            subtitle: 'I have a fixed location where clients come to me',
            value: !_isMobile,
            onChanged: (value) {
              setState(() {
                _isMobile = !value;
              });
            },
          ),
          const Divider(color: DCTheme.border, height: 24),
          _buildSwitchTile(
            icon: Icons.directions_car,
            title: 'Mobile Barber',
            subtitle: 'I travel to my clients\' locations',
            value: _isMobile,
            onChanged: (value) {
              setState(() {
                _isMobile = value;
              });
            },
          ),
          const Divider(color: DCTheme.border, height: 24),
          _buildSwitchTile(
            icon: Icons.home,
            title: 'Offers Home Service',
            subtitle: 'I can provide services at customer\'s home',
            value: _offersHomeService,
            onChanged: (value) {
              setState(() {
                _offersHomeService = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: value
                ? DCTheme.primary.withValues(alpha: 0.15)
                : DCTheme.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: value ? DCTheme.primary : DCTheme.textMuted,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DCTheme.primary;
            }
            return null;
          }),
        ),
      ],
    );
  }

  Widget _buildTravelSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _radiusController,
            style: const TextStyle(color: DCTheme.text),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Service Radius (miles)',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: '10',
              prefixIcon: const Icon(Icons.radar, color: DCTheme.textMuted),
              suffixText: 'miles',
              suffixStyle: const TextStyle(color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _travelFeeController,
            style: const TextStyle(color: DCTheme.text),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Travel Fee Per Mile',
              labelStyle: const TextStyle(color: DCTheme.textMuted),
              hintText: '2.00',
              prefixIcon:
                  const Icon(Icons.attach_money, color: DCTheme.textMuted),
              prefixText: '\$',
              prefixStyle: const TextStyle(color: DCTheme.text),
              suffixText: '/mile',
              suffixStyle: const TextStyle(color: DCTheme.textMuted),
              filled: true,
              fillColor: DCTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DCTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: DCTheme.info.withValues(alpha: 0.8),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Travel fees are automatically calculated based on distance from your base location.',
                    style: TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
