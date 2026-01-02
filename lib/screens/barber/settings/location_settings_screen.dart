import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme.dart';
import '../../../models/barber.dart';
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
  LocationType? _selectedLocationType;

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
    _selectedLocationType = barber.locationType;
    _isInitialized = true;
  }

  Future<void> _useCurrentLocation() async {
    // Only prompt for type if not already set
    LocationType? locationType = _selectedLocationType;
    if (locationType == null) {
      locationType = await _showLocationTypeWarningDialog();
      if (locationType == null) return;
    }

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateLocationFromGPS(
      locationType: locationType,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _selectedLocationType = locationType;
        });
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

    // Only prompt for type if not already set
    LocationType? locationType = _selectedLocationType;
    if (locationType == null) {
      locationType = await _showLocationTypeWarningDialog();
      if (locationType == null) return;
    }

    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateLocationFromAddress(
      address,
      locationType: locationType,
    );

    if (mounted) {
      if (success) {
        setState(() {
          _selectedLocationType = locationType;
        });
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
      setState(() {
        _selectedLocationType = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location cleared'),
          backgroundColor: DCTheme.success,
        ),
      );
    }
  }

  /// Show location type selection dialog with privacy warning
  /// Returns the selected LocationType or null if cancelled
  Future<LocationType?> _showLocationTypeWarningDialog() async {
    // Default to current selection or shop
    LocationType selectedType = _selectedLocationType ?? LocationType.shop;

    return showDialog<LocationType>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DCTheme.surface,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: DCTheme.warning, size: 24),
              SizedBox(width: 12),
              Text('Confirm Location Type',
                  style: TextStyle(color: DCTheme.text, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DCTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DCTheme.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'This location will be visible to customers searching for barbers nearby. '
                  'Do NOT enter a home address unless you provide home services.',
                  style: TextStyle(color: DCTheme.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'What type of location is this?',
                style: TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Shop option
              _buildLocationTypeOption(
                title: 'Business Location',
                subtitle: 'Shop, salon, or studio address',
                icon: Icons.store,
                isSelected: selectedType == LocationType.shop,
                onTap: () => setDialogState(() {
                  selectedType = LocationType.shop;
                }),
              ),
              const SizedBox(height: 8),
              // Service area option
              _buildLocationTypeOption(
                title: 'Service Area Center',
                subtitle: 'Central point for mobile/traveling barbers',
                icon: Icons.radar,
                isSelected: selectedType == LocationType.serviceArea,
                onTap: () => setDialogState(() {
                  selectedType = LocationType.serviceArea;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedType),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTypeOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? DCTheme.primary.withValues(alpha: 0.15)
              : DCTheme.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? DCTheme.primary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? DCTheme.primary : DCTheme.textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? DCTheme.primary : DCTheme.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
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
            if (isSelected)
              const Icon(Icons.check_circle, color: DCTheme.primary, size: 20),
          ],
        ),
      ),
    );
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

                  // Location Type Section (only if location exists but no type)
                  if (barber?.hasLocation == true &&
                      barber?.locationType == null) ...[
                    _buildSectionHeader('Location Type Required'),
                    const SizedBox(height: 12),
                    _buildLocationTypeSection(),
                    const SizedBox(height: 24),
                  ],

                  // Address Section
                  _buildSectionHeader('Business Address'),
                  const SizedBox(height: 12),
                  _buildAddressSection(),
                  const SizedBox(height: 24),

                  // Current Location Type (if set)
                  if (barber?.locationType != null) ...[
                    _buildSectionHeader('Location Type'),
                    const SizedBox(height: 12),
                    _buildCurrentLocationTypeCard(barber),
                    const SizedBox(height: 24),
                  ],

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
    final hasConfirmedLocation = barber?.hasConfirmedLocation ?? false;
    final locationType = barber?.locationType;
    final isActive = barber?.isActive ?? true;

    // Determine status: Green if visible, Yellow if has coords but not visible, Red if no coords
    // IMPORTANT: Must match public_barbers view logic (is_active + coords + location_type)
    final isVisible = hasConfirmedLocation && isActive;
    final hasCoords = hasLocation;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSubtitle;

    if (!isActive) {
      // Account is deactivated - takes precedence
      statusColor = DCTheme.error;
      statusIcon = Icons.block;
      statusTitle = 'Account Inactive';
      statusSubtitle = 'Your profile is hidden from customers';
    } else if (isVisible) {
      statusColor = DCTheme.success;
      statusIcon = Icons.visibility;
      statusTitle = 'Visible in Marketplace';
      statusSubtitle = locationType == LocationType.shop
          ? 'Showing as business location'
          : 'Showing as service area center';
    } else if (hasCoords) {
      statusColor = DCTheme.warning;
      statusIcon = Icons.visibility_off;
      statusTitle = 'Not Visible';
      statusSubtitle = 'Set location type to appear in search';
    } else {
      statusColor = DCTheme.textMuted;
      statusIcon = Icons.location_off;
      statusTitle = 'No Location Set';
      statusSubtitle = 'Add your business location to be discovered';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusSubtitle,
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

  /// Section shown when location exists but type is not set
  /// This is critical for marketplace visibility
  Widget _buildLocationTypeSection() {
    final crmState = ref.watch(barberCrmProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DCTheme.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: DCTheme.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your location is not visible to customers',
                  style: TextStyle(
                    color: DCTheme.warning,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Customers can\'t see you until you confirm whether this is a '
            'Business Location or Service Area Center.',
            style: TextStyle(color: DCTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: crmState.isSaving
                      ? null
                      : () => _setLocationType(LocationType.shop),
                  icon: const Icon(Icons.store, size: 18),
                  label: const Text('Business'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DCTheme.primary,
                    side: const BorderSide(color: DCTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: crmState.isSaving
                      ? null
                      : () => _setLocationType(LocationType.serviceArea),
                  icon: const Icon(Icons.radar, size: 18),
                  label: const Text('Service Area'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DCTheme.info,
                    side: const BorderSide(color: DCTheme.info),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setLocationType(LocationType type) async {
    final notifier = ref.read(barberCrmProvider.notifier);
    final success = await notifier.updateLocationType(type);

    if (mounted) {
      if (success) {
        setState(() {
          _selectedLocationType = type;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location type set - now visible in marketplace'),
            backgroundColor: DCTheme.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update location type'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    }
  }

  /// Card showing current location type with option to change
  Widget _buildCurrentLocationTypeCard(barber) {
    final locationType = barber?.locationType;
    final isShop = locationType == LocationType.shop;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: DCTheme.success.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isShop ? Icons.store : Icons.radar,
              color: DCTheme.success,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isShop ? 'Business Location' : 'Service Area Center',
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isShop
                      ? 'Shop, salon, or studio'
                      : 'Central point for mobile services',
                  style: const TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final newType = await _showLocationTypeWarningDialog();
              if (newType != null && newType != locationType) {
                await _setLocationType(newType);
              }
            },
            child: const Text('Change'),
          ),
        ],
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
