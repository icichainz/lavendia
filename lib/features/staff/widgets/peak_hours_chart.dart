import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/analytics_model.dart';

class PeakHoursChart extends StatelessWidget {
  final List<PeakHours> peakHours;
  final String title;

  const PeakHoursChart({
    super.key,
    required this.peakHours,
    this.title = 'Peak Hours',
  });

  @override
  Widget build(BuildContext context) {
    if (peakHours.isEmpty) {
      return _buildEmptyState(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Busiest hour: ${_findPeakHour()}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = peakHours[group.x.toInt()];
                      return BarTooltipItem(
                        '${hour.formattedHour}\n${hour.orderCount} orders\n\$${hour.revenue.toStringAsFixed(2)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= peakHours.length) {
                          return const SizedBox.shrink();
                        }
                        // Show every other label for readability
                        if (peakHours.length > 12 && index % 2 != 0) {
                          return const SizedBox.shrink();
                        }
                        final hour = peakHours[index].hour;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${hour}h',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateMaxY() / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _createBarGroups(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 48,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'No data available',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).disabledColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    final maxCount = peakHours.map((h) => h.orderCount).reduce((a, b) => a > b ? a : b);

    return peakHours.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final double intensity = maxCount > 0 ? data.orderCount / maxCount : 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data.orderCount.toDouble(),
            color: _getBarColor(intensity),
            width: peakHours.length > 12 ? 8 : 12,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getBarColor(double intensity) {
    if (intensity > 0.8) return AppColors.error;
    if (intensity > 0.6) return AppColors.warning;
    if (intensity > 0.4) return AppColors.primary;
    return AppColors.primary.withValues(alpha: 0.6);
  }

  double _calculateMaxY() {
    if (peakHours.isEmpty) return 10;
    final maxCount = peakHours.map((h) => h.orderCount).reduce((a, b) => a > b ? a : b);
    return (maxCount * 1.2).ceil().toDouble();
  }

  String _findPeakHour() {
    if (peakHours.isEmpty) return 'N/A';
    final peak = peakHours.reduce((a, b) => a.orderCount > b.orderCount ? a : b);
    return peak.formattedHour;
  }
}
