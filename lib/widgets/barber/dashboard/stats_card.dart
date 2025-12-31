import 'package:flutter/material.dart';

import '../../../config/theme.dart';

/// Reusable stats card with value, label, and optional trend indicator
/// Inspired by theCut's stats dashboard cards
class StatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final double? trend;
  final String? trendLabel;
  final VoidCallback? onTap;

  const StatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.trend,
    this.trendLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DCTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        (iconColor ?? DCTheme.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? DCTheme.primary,
                  ),
                ),
                const Spacer(),
                if (trend != null) _buildTrend(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: DCTheme.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: DCTheme.textMuted,
              ),
            ),
            if (trendLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                trendLabel!,
                style: TextStyle(
                  fontSize: 11,
                  color: _getTrendColor(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrend() {
    final isPositive = trend! >= 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          size: 14,
          color: _getTrendColor(),
        ),
        const SizedBox(width: 2),
        Text(
          '${isPositive ? '+' : ''}${trend!.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getTrendColor(),
          ),
        ),
      ],
    );
  }

  Color _getTrendColor() {
    if (trend == null) return DCTheme.textMuted;
    if (trend! > 0) return DCTheme.success;
    if (trend! < 0) return DCTheme.error;
    return DCTheme.textMuted;
  }
}

/// Grid of 4 stats cards for the dashboard
class StatsDashboardGrid extends StatelessWidget {
  final double todayEarnings;
  final double weekEarnings;
  final double pendingPayout;
  final int todayAppointments;
  final int weekAppointments;
  final double rating;
  final double? earningsTrend;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onPayoutTap;
  final VoidCallback? onAppointmentsTap;

  const StatsDashboardGrid({
    super.key,
    required this.todayEarnings,
    required this.weekEarnings,
    required this.pendingPayout,
    required this.todayAppointments,
    required this.weekAppointments,
    required this.rating,
    this.earningsTrend,
    this.onEarningsTap,
    this.onPayoutTap,
    this.onAppointmentsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                label: 'Today\'s Earnings',
                value: '\$${todayEarnings.toStringAsFixed(0)}',
                icon: Icons.attach_money,
                iconColor: DCTheme.success,
                trend: earningsTrend,
                trendLabel: '+\$${weekEarnings.toStringAsFixed(0)} this week',
                onTap: onEarningsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                label: 'Pending Payout',
                value: '\$${pendingPayout.toStringAsFixed(2)}',
                icon: Icons.account_balance_wallet,
                iconColor: Colors.blue,
                trendLabel: 'Available for withdrawal',
                onTap: onPayoutTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                label: 'Today\'s Appointments',
                value: '$todayAppointments',
                icon: Icons.calendar_today,
                iconColor: Colors.purple,
                trendLabel: '$weekAppointments this week',
                onTap: onAppointmentsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                label: 'Rating',
                value: rating.toStringAsFixed(1),
                icon: Icons.star,
                iconColor: Colors.amber,
                trendLabel: 'Based on reviews',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
