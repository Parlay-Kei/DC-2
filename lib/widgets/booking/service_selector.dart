import 'package:flutter/material.dart';

import '../../config/theme.dart';

/// Data model for a service
class ServiceData {
  final String id;
  final String name;
  final int durationMinutes;
  final double price;
  final String? description;
  final String? category;
  final bool isPopular;

  const ServiceData({
    required this.id,
    required this.name,
    required this.durationMinutes,
    required this.price,
    this.description,
    this.category,
    this.isPopular = false,
  });
}

/// Individual service card showing name, duration, description, and price
/// Inspired by theCut's services list
class ServiceCard extends StatelessWidget {
  final ServiceData service;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  const ServiceCard({
    super.key,
    required this.service,
    this.isSelected = false,
    this.onTap,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? onAdd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? DCTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: DCTheme.border.withValues(alpha: 0.5),
            ),
            left: isSelected
                ? const BorderSide(color: DCTheme.primary, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          color: DCTheme.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (service.isPopular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DCTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Popular',
                            style: TextStyle(
                              color: DCTheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(service.durationMinutes),
                    style: const TextStyle(
                      color: DCTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  if (service.description != null &&
                      service.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      service.description!,
                      style: const TextStyle(
                        color: DCTheme.textMuted,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${service.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.check_circle,
                      color: DCTheme.primary,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else if (minutes == 60) {
      return '1 hour';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
      return '$hours hour${hours > 1 ? 's' : ''} $mins min';
    }
  }
}

/// Service list grouped by category with collapsible sections
class ServiceList extends StatefulWidget {
  final List<ServiceData> services;
  final Set<String> selectedIds;
  final ValueChanged<ServiceData>? onServiceTap;
  final bool allowMultiSelect;

  const ServiceList({
    super.key,
    required this.services,
    this.selectedIds = const {},
    this.onServiceTap,
    this.allowMultiSelect = true,
  });

  @override
  State<ServiceList> createState() => _ServiceListState();
}

class _ServiceListState extends State<ServiceList> {
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Expand all categories by default
    for (final service in widget.services) {
      _expandedCategories.add(service.category ?? 'Services');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group services by category
    final grouped = <String, List<ServiceData>>{};
    for (final service in widget.services) {
      final category = service.category ?? 'Services';
      grouped.putIfAbsent(category, () => []).add(service);
    }

    return ListView(
      children: grouped.entries.expand((entry) {
        final isExpanded = _expandedCategories.contains(entry.key);
        return [
          _CategoryHeader(
            title: entry.key,
            isExpanded: isExpanded,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCategories.remove(entry.key);
                } else {
                  _expandedCategories.add(entry.key);
                }
              });
            },
          ),
          if (isExpanded)
            ...entry.value.map((service) => ServiceCard(
                  service: service,
                  isSelected: widget.selectedIds.contains(service.id),
                  onTap: widget.onServiceTap != null
                      ? () => widget.onServiceTap!(service)
                      : null,
                ),),
        ];
      }).toList(),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;

  const _CategoryHeader({
    required this.title,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: DCTheme.surfaceSecondary,
        child: Row(
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: DCTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: DCTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select service selector with running total
class ServiceSelector extends StatefulWidget {
  final List<ServiceData> services;
  final ValueChanged<List<ServiceData>>? onSelectionChanged;
  final VoidCallback? onProceed;

  const ServiceSelector({
    super.key,
    required this.services,
    this.onSelectionChanged,
    this.onProceed,
  });

  @override
  State<ServiceSelector> createState() => _ServiceSelectorState();
}

class _ServiceSelectorState extends State<ServiceSelector> {
  final Set<String> _selectedIds = {};

  List<ServiceData> get _selectedServices =>
      widget.services.where((s) => _selectedIds.contains(s.id)).toList();

  double get _totalPrice =>
      _selectedServices.fold(0, (sum, s) => sum + s.price);

  int get _totalDuration =>
      _selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

  void _toggleService(ServiceData service) {
    setState(() {
      if (_selectedIds.contains(service.id)) {
        _selectedIds.remove(service.id);
      } else {
        _selectedIds.add(service.id);
      }
    });
    widget.onSelectionChanged?.call(_selectedServices);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'SERVICES',
                style: TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Spacer(),
              Text(
                'ADD',
                style: TextStyle(
                  color: DCTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ServiceList(
            services: widget.services,
            selectedIds: _selectedIds,
            onServiceTap: _toggleService,
          ),
        ),
        if (_selectedIds.isNotEmpty)
          SelectedServicesBar(
            selectedCount: _selectedIds.length,
            totalPrice: _totalPrice,
            totalDuration: _totalDuration,
            onProceed: widget.onProceed,
            onClear: () {
              setState(() => _selectedIds.clear());
              widget.onSelectionChanged?.call([]);
            },
          ),
      ],
    );
  }
}

/// Bottom bar showing selected services summary
class SelectedServicesBar extends StatelessWidget {
  final int selectedCount;
  final double totalPrice;
  final int totalDuration;
  final VoidCallback? onProceed;
  final VoidCallback? onClear;

  const SelectedServicesBar({
    super.key,
    required this.selectedCount,
    required this.totalPrice,
    required this.totalDuration,
    this.onProceed,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        border: const Border(
          top: BorderSide(color: DCTheme.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$selectedCount service${selectedCount > 1 ? 's' : ''} selected',
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDuration(totalDuration)} • \$${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: const Text(
                'Clear',
                style: TextStyle(color: DCTheme.textMuted),
              ),
            ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onProceed,
            style: ElevatedButton.styleFrom(
              backgroundColor: DCTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '${hours}h';
      }
      return '${hours}h ${mins}m';
    }
  }
}
