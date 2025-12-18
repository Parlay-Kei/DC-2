import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/theme.dart';
import '../../config/supabase_config.dart';

final earningsDataProvider = FutureProvider<EarningsData>((ref) async {
  final barberId = SupabaseConfig.currentUserId;
  if (barberId == null) return EarningsData.empty();

  try {
    final client = Supabase.instance.client;
    final today = DateTime.now();
    
    // Today
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final todayData = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .eq('date', todayStr)
        .eq('status', 'completed');

    double todayEarnings = 0;
    for (final apt in todayData) {
      todayEarnings += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
    }

    // This week
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekStartStr = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
    final weekData = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .gte('date', weekStartStr)
        .eq('status', 'completed');

    double weekEarnings = 0;
    int weekBookings = 0;
    for (final apt in weekData) {
      weekEarnings += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
      weekBookings++;
    }

    // This month
    final monthStartStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-01';
    final monthData = await client
        .from('appointments')
        .select('total_price, platform_fee, date')
        .eq('barber_id', barberId)
        .gte('date', monthStartStr)
        .eq('status', 'completed')
        .order('date', ascending: true);

    double monthEarnings = 0;
    int monthBookings = 0;
    double totalFees = 0;
    final List<DailyEarning> dailyEarnings = [];
    final Map<String, double> dailyMap = {};

    for (final apt in monthData) {
      final earnings = (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
      monthEarnings += earnings;
      totalFees += (apt['platform_fee'] ?? 0).toDouble();
      monthBookings++;
      
      final date = apt['date'] as String;
      dailyMap[date] = (dailyMap[date] ?? 0) + earnings;
    }

    dailyMap.forEach((date, amount) {
      dailyEarnings.add(DailyEarning(date: DateTime.parse(date), amount: amount));
    });

    // Last month for comparison
    final lastMonth = DateTime(today.year, today.month - 1, 1);
    final lastMonthStartStr = '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}-01';
    final lastMonthEndStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-01';
    final lastMonthData = await client
        .from('appointments')
        .select('total_price, platform_fee')
        .eq('barber_id', barberId)
        .gte('date', lastMonthStartStr)
        .lt('date', lastMonthEndStr)
        .eq('status', 'completed');

    double lastMonthEarnings = 0;
    for (final apt in lastMonthData) {
      lastMonthEarnings += (apt['total_price'] ?? 0) - (apt['platform_fee'] ?? 0);
    }

    return EarningsData(
      todayEarnings: todayEarnings,
      weekEarnings: weekEarnings,
      weekBookings: weekBookings,
      monthEarnings: monthEarnings,
      monthBookings: monthBookings,
      lastMonthEarnings: lastMonthEarnings,
      totalFees: totalFees,
      dailyEarnings: dailyEarnings,
    );
  } catch (e) {
    return EarningsData.empty();
  }
});

class EarningsData {
  final double todayEarnings;
  final double weekEarnings;
  final int weekBookings;
  final double monthEarnings;
  final int monthBookings;
  final double lastMonthEarnings;
  final double totalFees;
  final List<DailyEarning> dailyEarnings;

  EarningsData({
    required this.todayEarnings,
    required this.weekEarnings,
    required this.weekBookings,
    required this.monthEarnings,
    required this.monthBookings,
    required this.lastMonthEarnings,
    required this.totalFees,
    required this.dailyEarnings,
  });

  factory EarningsData.empty() => EarningsData(
    todayEarnings: 0,
    weekEarnings: 0,
    weekBookings: 0,
    monthEarnings: 0,
    monthBookings: 0,
    lastMonthEarnings: 0,
    totalFees: 0,
    dailyEarnings: [],
  );

  double get monthChange {
    if (lastMonthEarnings == 0) return 0;
    return ((monthEarnings - lastMonthEarnings) / lastMonthEarnings) * 100;
  }
}

class DailyEarning {
  final DateTime date;
  final double amount;

  DailyEarning({required this.date, required this.amount});
}

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsDataProvider);

    return Scaffold(
      backgroundColor: DCTheme.background,
      appBar: AppBar(
        title: const Text('Earnings'),
      ),
      body: earningsAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(earningsDataProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMainEarningsCard(data),
                const SizedBox(height: 16),
                _buildStatsRow(data),
                const SizedBox(height: 24),
                _buildEarningsChart(data),
                const SizedBox(height: 24),
                _buildPayoutInfo(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: DCTheme.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: DCTheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Error: $e', style: const TextStyle(color: DCTheme.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainEarningsCard(EarningsData data) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [DCTheme.primary, Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${data.monthEarnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (data.monthChange != 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.monthChange > 0 ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.monthChange > 0 ? Icons.trending_up : Icons.trending_down,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${data.monthChange.abs().toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _EarningsStat(
                label: 'Bookings',
                value: '${data.monthBookings}',
              ),
              const SizedBox(width: 32),
              _EarningsStat(
                label: 'Platform Fees',
                value: '\$${data.totalFees.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(EarningsData data) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Today',
            value: '\$${data.todayEarnings.toStringAsFixed(0)}',
            icon: Icons.today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'This Week',
            value: '\$${data.weekEarnings.toStringAsFixed(0)}',
            subtitle: '${data.weekBookings} bookings',
            icon: Icons.date_range,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart(EarningsData data) {
    if (data.dailyEarnings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: DCTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart, size: 48, color: DCTheme.textMuted.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text(
                'No earnings data this month',
                style: TextStyle(color: DCTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final maxAmount = data.dailyEarnings.map((e) => e.amount).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Earnings',
            style: TextStyle(
              color: DCTheme.text,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.dailyEarnings.take(14).map((daily) {
                final heightPercent = maxAmount > 0 ? daily.amount / maxAmount : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Container(
                            width: double.infinity,
                            height: (100 * heightPercent).clamp(4, 100),
                            decoration: BoxDecoration(
                              color: DCTheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${daily.date.day}',
                          style: const TextStyle(color: DCTheme.textMuted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet, color: DCTheme.primary),
              SizedBox(width: 12),
              Text(
                'Payouts',
                style: TextStyle(
                  color: DCTheme.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Payouts are processed automatically via Stripe Connect every Monday.',
            style: TextStyle(color: DCTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Open Stripe dashboard
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('View Payout History'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningsStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: DCTheme.textMuted, fontSize: 12)),
              Icon(icon, color: DCTheme.primary, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: const TextStyle(color: DCTheme.textMuted, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
