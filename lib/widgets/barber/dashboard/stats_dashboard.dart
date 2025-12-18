import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../config/theme.dart';

/// Daily bar chart showing 7 days of data with the current day highlighted
/// Inspired by theCut's stats dashboard charts
class DailyBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final int highlightIndex;
  final String? title;
  final String? subtitle;
  final Color barColor;

  const DailyBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.highlightIndex = 6,
    this.title,
    this.subtitle,
    this.barColor = DCTheme.primary,
  });

  /// Creates a chart for the last 7 days with earnings data
  factory DailyBarChart.weeklyEarnings({
    required List<double> dailyEarnings,
    Key? key,
  }) {
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return _getDayAbbreviation(date.weekday);
    });

    return DailyBarChart(
      key: key,
      values: dailyEarnings,
      labels: labels,
      highlightIndex: 6,
      title: 'Weekly Earnings',
    );
  }

  /// Creates a chart for the last 7 days with bookings count
  factory DailyBarChart.weeklyBookings({
    required List<int> dailyBookings,
    Key? key,
  }) {
    final now = DateTime.now();
    final labels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return _getDayAbbreviation(date.weekday);
    });

    return DailyBarChart(
      key: key,
      values: dailyBookings.map((e) => e.toDouble()).toList(),
      labels: labels,
      highlightIndex: 6,
      title: 'Weekly Bookings',
      barColor: Colors.purple,
    );
  }

  static String _getDayAbbreviation(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final maxValue = values.isNotEmpty
        ? values.reduce((a, b) => a > b ? a : b)
        : 100.0;
    final chartMax = maxValue > 0 ? maxValue * 1.2 : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DCTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DCTheme.text,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DCTheme.textMuted,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: chartMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => DCTheme.surfaceSecondary,
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '\$${rod.toY.toStringAsFixed(0)}',
                        const TextStyle(
                          color: DCTheme.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= labels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            labels[index],
                            style: TextStyle(
                              color: index == highlightIndex
                                  ? DCTheme.text
                                  : DCTheme.textMuted,
                              fontSize: 11,
                              fontWeight: index == highlightIndex
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: List.generate(values.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        color: index == highlightIndex
                            ? barColor
                            : barColor.withValues(alpha: 0.3),
                        width: 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Stats dashboard with toggle between Daily and Weekly views
class StatsDashboard extends StatefulWidget {
  final double todayBookings;
  final double weekBookings;
  final double todayRevenue;
  final double weekRevenue;
  final int todayTransactions;
  final int weekTransactions;
  final double todayTips;
  final double weekTips;
  final List<double> dailyEarnings;
  final List<int> dailyBookings;

  const StatsDashboard({
    super.key,
    required this.todayBookings,
    required this.weekBookings,
    required this.todayRevenue,
    required this.weekRevenue,
    required this.todayTransactions,
    required this.weekTransactions,
    required this.todayTips,
    required this.weekTips,
    required this.dailyEarnings,
    required this.dailyBookings,
  });

  @override
  State<StatsDashboard> createState() => _StatsDashboardState();
}

class _StatsDashboardState extends State<StatsDashboard> {
  bool _showWeekly = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToggle(),
        const SizedBox(height: 16),
        _buildStatsGrid(),
        const SizedBox(height: 16),
        if (_showWeekly)
          DailyBarChart.weeklyEarnings(dailyEarnings: widget.dailyEarnings),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DCTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleButton(
              label: 'Daily',
              isSelected: !_showWeekly,
              onTap: () => setState(() => _showWeekly = false),
            ),
          ),
          Expanded(
            child: _ToggleButton(
              label: 'Weekly',
              isSelected: _showWeekly,
              onTap: () => setState(() => _showWeekly = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MiniStatCard(
          label: 'Bookings',
          value: _showWeekly
              ? widget.weekBookings.toStringAsFixed(0)
              : widget.todayBookings.toStringAsFixed(0),
          subtitle: _showWeekly ? 'This week' : 'Today',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
        _MiniStatCard(
          label: 'Revenue',
          value: '\$${(_showWeekly ? widget.weekRevenue : widget.todayRevenue).toStringAsFixed(0)}',
          subtitle: _showWeekly ? 'This week' : 'Today',
          icon: Icons.attach_money,
          color: DCTheme.success,
        ),
        _MiniStatCard(
          label: 'Transactions',
          value: _showWeekly
              ? widget.weekTransactions.toString()
              : widget.todayTransactions.toString(),
          subtitle: _showWeekly ? 'This week' : 'Today',
          icon: Icons.receipt_long,
          color: Colors.purple,
        ),
        _MiniStatCard(
          label: 'Tips',
          value: '\$${(_showWeekly ? widget.weekTips : widget.todayTips).toStringAsFixed(0)}',
          subtitle: _showWeekly ? 'This week' : 'Today',
          icon: Icons.volunteer_activism,
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? DCTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? DCTheme.text : DCTheme.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DCTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DCTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: DCTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: DCTheme.text,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: DCTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
