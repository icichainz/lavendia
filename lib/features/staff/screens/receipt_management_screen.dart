import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../providers/receipt_provider.dart';
import '../../../models/receipt_model.dart';
import '../../shared/widgets/loading_indicator.dart';
import 'receipt_detail_staff_screen.dart';

class ReceiptManagementScreen extends StatefulWidget {
  const ReceiptManagementScreen({super.key});

  @override
  State<ReceiptManagementScreen> createState() => _ReceiptManagementScreenState();
}

class _ReceiptManagementScreenState extends State<ReceiptManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedStatus = 'all';

  // Define status values without translation (translations will be applied in build)
  final List<String> _statusValues = ['all', 'pending', 'washing', 'drying', 'ready', 'completed'];

  List<Map<String, dynamic>> _getStatusTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {'label': l10n.all, 'value': 'all'},
      {'label': l10n.translate('pending'), 'value': 'pending'},
      {'label': l10n.translate('washing'), 'value': 'washing'},
      {'label': l10n.translate('drying'), 'value': 'drying'},
      {'label': l10n.translate('ready'), 'value': 'ready'},
      {'label': l10n.completed, 'value': 'completed'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusValues.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadReceipts();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {
      _selectedStatus = _statusValues[_tabController.index];
    });
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    final receiptProvider = Provider.of<ReceiptProvider>(context, listen: false);
    if (_selectedStatus == 'all') {
      await receiptProvider.fetchActiveReceipts();
    } else {
      await receiptProvider.fetchReceipts(status: _selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusTabs = _getStatusTabs(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageOrders),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: statusTabs.map((tab) => Tab(text: tab['label'])).toList(),
        ),
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, receiptProvider, child) {
          if (receiptProvider.isLoading) {
            return const Center(child: LoadingIndicator());
          }

          final receipts = receiptProvider.receipts;

          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.translate('no_orders_found'),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReceipts,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                return _buildReceiptCard(receipts[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptCard(ReceiptModel receipt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReceiptDetailStaffScreen(receiptId: receipt.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      receipt.receiptNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(receipt.status, receipt.statusDisplay),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Text(
                    receipt.customerName ?? AppLocalizations.of(context)!.unknownCustomer,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${AppLocalizations.of(context)!.itemsCount(receipt.itemsCount)} - ${receipt.itemsDescription}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(receipt.expectedPickupDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${receipt.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String display) {
    final color = AppColors.getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        display,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
