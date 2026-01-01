import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/barber_crm_provider.dart';
import '../../providers/barber_provider.dart';

/// Onboarding step definition
class OnboardingStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isComplete;
  final String? route;

  const OnboardingStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isComplete,
    this.route,
  });
}

/// Provider for current barber's services count
final currentBarberServicesProvider = FutureProvider<int>((ref) async {
  final barberAsync = ref.watch(currentBarberProvider);
  final barber = barberAsync.valueOrNull;
  if (barber == null) return 0;

  final services = await ref.watch(barberServicesProvider(barber.id).future);
  return services.length;
});

/// Provider for active services (with price and duration set)
final currentBarberActiveServicesProvider = FutureProvider<int>((ref) async {
  final barberAsync = ref.watch(currentBarberProvider);
  final barber = barberAsync.valueOrNull;
  if (barber == null) return 0;

  final services = await ref.watch(barberServicesProvider(barber.id).future);
  // Count only ACTIVE services with valid price and duration
  return services
      .where((s) => s.isActive && s.price > 0 && s.durationMinutes > 0)
      .length;
});

/// Provider that calculates onboarding completion status
/// NOTE: Steps MUST match public_barbers view visibility rules:
///   - is_active = true
///   - latitude/longitude NOT NULL
///   - location_type NOT NULL (enforced by DB constraint)
final barberOnboardingProvider = FutureProvider<List<OnboardingStep>>((ref) async {
  final barberAsync = ref.watch(currentBarberProvider);
  final activeServicesCount = await ref.watch(currentBarberActiveServicesProvider.future);

  return barberAsync.when(
    data: (barber) {
      if (barber == null) return [];

      // Location is complete when coords + location_type are set
      // This matches the DB constraint and public_barbers view rules
      final hasValidLocation = barber.hasLocation && barber.locationType != null;

      return [
        OnboardingStep(
          id: 'profile',
          title: 'Complete Profile',
          description: 'Add your name and photo',
          icon: Icons.person_outline,
          isComplete: barber.displayName.isNotEmpty &&
                      barber.profileImageUrl != null,
          route: '/barber/settings/profile',
        ),
        OnboardingStep(
          id: 'services',
          title: 'Add Services',
          description: 'List at least one active service',
          icon: Icons.content_cut,
          isComplete: activeServicesCount > 0,
          route: '/barber/services',
        ),
        OnboardingStep(
          id: 'location',
          title: 'Set Location',
          description: 'Add your shop or mobile service area',
          icon: Icons.location_on_outlined,
          isComplete: hasValidLocation,
          route: '/barber/settings/location',
        ),
        OnboardingStep(
          id: 'visibility',
          title: 'Go Live',
          description: 'Make your profile visible to customers',
          icon: Icons.visibility_outlined,
          isComplete: hasValidLocation && barber.isActive,
          route: '/barber/settings/location',
        ),
      ];
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Onboarding completion score calculated from steps
final onboardingScoreProvider = Provider<int>((ref) {
  final stepsAsync = ref.watch(barberOnboardingProvider);
  return stepsAsync.maybeWhen(
    data: (steps) {
      if (steps.isEmpty) return 0;
      final completed = steps.where((s) => s.isComplete).length;
      return ((completed / steps.length) * 100).round();
    },
    orElse: () => 0,
  );
});

/// Widget showing onboarding progress on barber dashboard
class OnboardingProgressCard extends ConsumerWidget {
  const OnboardingProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(barberOnboardingProvider);
    final score = ref.watch(onboardingScoreProvider);

    return stepsAsync.when(
      data: (steps) {
        if (steps.isEmpty) return const SizedBox.shrink();

        // Don't show if all complete
        final allComplete = steps.every((s) => s.isComplete);
        if (allComplete) {
          return _buildCompletedCard(context);
        }

        final completedCount = steps.where((s) => s.isComplete).length;
        final nextStep = steps.firstWhere(
          (s) => !s.isComplete,
          orElse: () => steps.last,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DCTheme.primary.withValues(alpha: 0.15),
                DCTheme.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DCTheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: DCTheme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.rocket_launch,
                      color: DCTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Go Live Checklist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: DCTheme.text,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$completedCount of ${steps.length} steps complete',
                          style: const TextStyle(
                            color: DCTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildScoreBadge(score),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: score / 100,
                  minHeight: 8,
                  backgroundColor: DCTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    score == 100 ? DCTheme.success : DCTheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Steps list
              ...steps.map((step) => _buildStepRow(context, step)),
              const SizedBox(height: 12),
              // Next action button
              if (!nextStep.isComplete)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (nextStep.route != null) {
                        context.push(nextStep.route!);
                      }
                    },
                    icon: Icon(nextStep.icon, size: 18),
                    label: Text(nextStep.title),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DCTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildScoreBadge(int score) {
    Color color;
    if (score == 100) {
      color = DCTheme.success;
    } else if (score >= 60) {
      color = DCTheme.warning;
    } else {
      color = DCTheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildStepRow(BuildContext context, OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: step.route != null ? () => context.push(step.route!) : null,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: step.isComplete
                    ? DCTheme.success
                    : DCTheme.surface,
                shape: BoxShape.circle,
                border: step.isComplete
                    ? null
                    : Border.all(color: DCTheme.border),
              ),
              child: Icon(
                step.isComplete ? Icons.check : step.icon,
                size: 16,
                color: step.isComplete ? Colors.white : DCTheme.textMuted,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step.title,
                style: TextStyle(
                  color: step.isComplete ? DCTheme.textMuted : DCTheme.text,
                  fontWeight: step.isComplete ? FontWeight.normal : FontWeight.w500,
                  decoration: step.isComplete ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (!step.isComplete && step.route != null)
              Icon(
                Icons.chevron_right,
                color: DCTheme.textMuted.withValues(alpha: 0.5),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DCTheme.success.withValues(alpha: 0.15),
            DCTheme.success.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DCTheme.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: DCTheme.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle,
              color: DCTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're Live!",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: DCTheme.success,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Customers can now find and book you',
                  style: TextStyle(
                    color: DCTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.celebration,
            color: DCTheme.success,
            size: 28,
          ),
        ],
      ),
    );
  }
}
