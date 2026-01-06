import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/status_distribution_chart.dart';
import '../widgets/peak_hours_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(
      context,
      listen: false,
    );
    await analyticsProvider.fetchAllAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('analytics_dashboard')),
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (context, provider, child) {
              if (provider.isExporting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              return PopupMenuButton<String>(
                icon: const Icon(Icons.download),
                tooltip: l10n.translate('export'),
                onSelected: (value) => _handleExport(value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(l10n.translate('export_pdf')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'csv',
                    child: Row(
                      children: [
                        const Icon(Icons.table_chart, color: AppColors.success),
                        const SizedBox(width: 12),
                        Text(l10n.translate('export_csv')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range Selector
              _buildTimeRangeSelector(),
              const SizedBox(height: 20),

              // Analytics Content
              Consumer<AnalyticsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.overview == null) {
                    return const SizedBox(
                      height: 300,
                      child: Center(child: LoadingIndicator()),
                    );
                  }

                  if (provider.errorMessage != null && provider.overview == null) {
                    return _buildErrorState(provider.errorMessage!);
                  }

                  if (provider.overview == null) {
                    return _buildEmptyState(l10n);
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Cards
                      _buildOverviewCards(provider.overview!),
                      const SizedBox(height: 20),

                      // Revenue Chart
                      RevenueChart(
                        trends: provider.revenueTrends,
                        title: l10n.translate('revenue_trend'),
                      ),
                      const SizedBox(height: 20),

                      // Status Distribution
                      StatusDistributionChart(
                        distribution: provider.statusDistribution,
                        title: l10n.translate('order_status_distribution'),
                      ),
                      const SizedBox(height: 20),

                      // Peak Hours
                      PeakHoursChart(
                        peakHours: provider.peakHours,
                        title: l10n.translate('peak_hours'),
                      ),
                      const SizedBox(height: 20),

                      // Top Customers
                      if (provider.topCustomers.isNotEmpty)
                        _buildTopCustomersSection(provider, l10n),

                      // Staff Performance
                      if (provider.staffPerformance.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildStaffPerformanceSection(provider, l10n),
                      ],

                      // Laundromat Comparison (Admin only)
                      if (authProvider.isAdmin && provider.laundromatComparison.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildLaundromatComparisonSection(provider, l10n),
                      ],

                      const SizedBox(height: 20),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    final l10n = AppLocalizations.of(context)!;

    return Consumer<AnalyticsProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: AnalyticsProvider.timeRangeOptions.map((option) {
              return _buildTimeRangeButton(
                l10n.translate('time_range_${option['value']}'),
                option['value']!,
                provider,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTimeRangeButton(
    String label,
    String value,
    AnalyticsProvider provider,
  ) {
    final isSelected = provider.currentTimeRange == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setTimeRange(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(overview) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.translate('total_revenue'),
                '\$${overview.totalRevenue.toStringAsFixed(2)}',
                Icons.attach_money,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.translate('total_orders'),
                overview.totalOrders.toString(),
                Icons.shopping_bag,
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.translate('active_orders'),
                overview.activeOrders.toString(),
                Icons.pending_actions,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.translate('total_customers'),
                overview.totalCustomers.toString(),
                Icons.people,
                AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.translate('completed_orders'),
                overview.completedOrders.toString(),
                Icons.check_circle,
                AppColors.statusReady,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.translate('average_order_value'),
                '\$${overview.averageOrderValue.toStringAsFixed(2)}',
                Icons.trending_up,
                AppColors.info,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomersSection(AnalyticsProvider provider, AppLocalizations l10n) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('top_customers'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(Icons.star, color: AppColors.warning, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...provider.topCustomers.take(5).map((customer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      customer.customerName.isNotEmpty
                          ? customer.customerName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.customerName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${customer.orderCount} ${l10n.orders.toLowerCase()}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${customer.totalSpent.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStaffPerformanceSection(AnalyticsProvider provider, AppLocalizations l10n) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('staff_performance'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(Icons.badge, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...provider.staffPerformance.map((staff) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                    child: Text(
                      staff.staffName.isNotEmpty
                          ? staff.staffName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          staff.staffName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${staff.orderCount} ${l10n.orders.toLowerCase()} • ${staff.formattedProcessingTime} avg',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${staff.totalRevenue.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        '${staff.completedOrders} completed',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLaundromatComparisonSection(AnalyticsProvider provider, AppLocalizations l10n) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.translate('laundromat_comparison'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Icon(Icons.store, color: AppColors.info, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          ...provider.laundromatComparison.map((laundromat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      laundromat.laundromatName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildComparisonStat(
                          l10n.translate('revenue'),
                          '\$${laundromat.revenue.toStringAsFixed(0)}',
                          AppColors.success,
                        ),
                        _buildComparisonStat(
                          l10n.orders,
                          laundromat.orderCount.toString(),
                          AppColors.primary,
                        ),
                        _buildComparisonStat(
                          l10n.translate('customers'),
                          laundromat.customerCount.toString(),
                          AppColors.secondary,
                        ),
                        _buildComparisonStat(
                          l10n.active,
                          laundromat.activeOrders.toString(),
                          AppColors.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComparisonStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
              ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.translate('no_analytics_data'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).disabledColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExport(String type) async {
    final l10n = AppLocalizations.of(context)!;
    final provider = Provider.of<AnalyticsProvider>(context, listen: false);

    Map<String, dynamic> result;
    if (type == 'pdf') {
      result = await provider.exportPDF();
    } else {
      result = await provider.exportCSV();
    }

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('export_success')),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? l10n.translate('export_failed')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
