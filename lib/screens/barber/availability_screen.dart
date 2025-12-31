import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../config/supabase_config.dart';
import '../../models/availability.dart' show Availability;
import '../../services/availability_service.dart';

final barberAvailabilityProvider =
    FutureProvider<List<Availability>>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return [];

  final service = AvailabilityService();
  return service.getBarberAvailability(barberId);
});

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<int, BarberDaySchedule> _schedule = {};
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(barberAvailabilityProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Availability'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: availabilityAsync.when(
        data: (availability) {
          _initializeSchedule(availability);
          return _buildScheduleList();
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: DCTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e',
                  style: const TextStyle(color: DCTheme.textMuted)),
              TextButton(
                onPressed: () => ref.invalidate(barberAvailabilityProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeSchedule(List<Availability> availability) {
    if (_schedule.isEmpty) {
      for (int i = 0; i < 7; i++) {
        final dayAvail =
            availability.where((a) => a.dayOfWeek == i).firstOrNull;
        if (dayAvail != null) {
          _schedule[i] = BarberDaySchedule(
            isOpen: dayAvail.isActive,
            openTime: dayAvail.startTime,
            closeTime: dayAvail.endTime,
          );
        } else {
          _schedule[i] = BarberDaySchedule(
            isOpen: i >= 1 && i <= 5, // Open Mon-Fri by default (1-5)
            openTime: '09:00',
            closeTime: '17:00',
          );
        }
      }
    }
  }

  Widget _buildScheduleList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          ...List.generate(7, (index) => _buildDayCard(index)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: DCTheme.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Set your working hours for each day. Customers can only book during these times.',
              style: TextStyle(
                  color: DCTheme.info.withValues(alpha: 0.9), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(int dayIndex) {
    final schedule = _schedule[dayIndex] ??
        BarberDaySchedule(isOpen: false, openTime: '09:00', closeTime: '17:00');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _days[dayIndex],
                  style: const TextStyle(
                    color: DCTheme.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Switch(
                value: schedule.isOpen,
                onChanged: (value) {
                  setState(() {
                    _schedule[dayIndex] = schedule.copyWith(isOpen: value);
                    _hasChanges = true;
                  });
                },
                thumbColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return DCTheme.primary;
                  }
                  return null;
                }),
              ),
            ],
          ),
          if (schedule.isOpen) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _TimeSelector(
                    label: 'Open',
                    time: schedule.openTime,
                    onChanged: (time) {
                      setState(() {
                        _schedule[dayIndex] = schedule.copyWith(openTime: time);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward,
                    color: DCTheme.textMuted, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimeSelector(
                    label: 'Close',
                    time: schedule.closeTime,
                    onChanged: (time) {
                      setState(() {
                        _schedule[dayIndex] =
                            schedule.copyWith(closeTime: time);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Closed',
                style: TextStyle(color: DCTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      final barberId = SupabaseConfig.currentUserId;
      if (barberId == null) throw Exception('Not authenticated');

      final service = AvailabilityService();

      for (final entry in _schedule.entries) {
        final schedule = entry.value;
        await service.setAvailability(
          barberId: barberId,
          dayOfWeek: entry.key,
          startTime: schedule.openTime,
          endTime: schedule.closeTime,
          isClosed: !schedule.isOpen,
        );
      }

      ref.invalidate(barberAvailabilityProvider);

      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully!'),
            backgroundColor: DCTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: DCTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Local schedule model for the availability screen UI
class BarberDaySchedule {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  BarberDaySchedule({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  BarberDaySchedule copyWith(
      {bool? isOpen, String? openTime, String? closeTime}) {
    return BarberDaySchedule(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class _TimeSelector extends StatelessWidget {
  final String label;
  final String time;
  final Function(String) onChanged;

  const _TimeSelector({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTimePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DCTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: DCTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(time),
              style: const TextStyle(
                color: DCTheme.text,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DCTheme.primary,
              surface: DCTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final newTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      onChanged(newTime);
    }
  }

  String _formatTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
